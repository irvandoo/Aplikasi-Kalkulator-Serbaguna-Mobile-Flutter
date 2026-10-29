import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/number_format.dart';
import '../../core/number_input.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/shopping_repository.dart';
import '../../domain/numeric.dart';
import '../history/history_view_model.dart';
import '../settings/settings_view_model.dart';
import 'shopping_view_model.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key, this.restore});

  /// History entry to reopen; its `inputData['listId']` selects the list.
  final HistoryEntry? restore;

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  late final ShoppingViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = ShoppingViewModel(context.read<ShoppingRepository>());
    _vm.init(listId: widget.restore?.inputData['listId'] as String?);
  }

  @override
  void didUpdateWidget(ShoppingScreen old) {
    super.didUpdateWidget(old);
    final id = widget.restore?.inputData['listId'] as String?;
    if (widget.restore != null && widget.restore != old.restore && id != null) {
      _vm.init(listId: id);
    }
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
        value: _vm,
        child: const _ShoppingView(),
      );
}

class _ShoppingView extends StatelessWidget {
  const _ShoppingView();

  void _report(BuildContext context, String? error) {
    if (error != null) showMessage(context, error);
  }

  Future<void> _openLists(BuildContext context) async {
    final vm = context.read<ShoppingViewModel>();
    final id = await context.push<String>(Routes.shoppingLists);
    // The list may have been renamed or deleted; reload either way.
    await vm.init(listId: id ?? vm.current?.id);
  }

  Future<void> _editItem(BuildContext context, [ShoppingItem? item]) async {
    final vm = context.read<ShoppingViewModel>();
    final result = await showModalBottomSheet<_ItemFormResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ItemForm(item: item),
    );
    if (result == null || !context.mounted) return;
    if (result.delete && item != null) {
      final ok = await confirmDelete(context,
          title: 'Hapus barang?',
          message: '"${item.name}" akan dihapus dari daftar.');
      if (ok) {
        final error = await vm.deleteItem(item);
        if (context.mounted) _report(context, error);
      }
      return;
    }
    final error = item == null
        ? await vm.addItem(
            name: result.name,
            unitPrice: result.price,
            quantity: result.quantity,
            discountPercent: result.discount)
        : await vm.updateItem(item,
            name: result.name,
            unitPrice: result.price,
            quantity: result.quantity,
            discountPercent: result.discount);
    if (context.mounted) _report(context, error);
  }

  Future<void> _editBudget(BuildContext context) async {
    final vm = context.read<ShoppingViewModel>();
    final result = await showDialog<_BudgetResult>(
      context: context,
      builder: (_) => _BudgetDialog(initial: vm.current?.budget),
    );
    if (result == null || !context.mounted) return;
    final error = await vm.setBudget(result.budget);
    if (context.mounted) _report(context, error);
  }

  Future<void> _save(BuildContext context) async {
    final vm = context.read<ShoppingViewModel>();
    final list = vm.current;
    if (list == null) return;
    final format = context.read<SettingsViewModel>().format;
    final history = context.read<HistoryViewModel>();
    final totals = vm.totals;
    final ok = await history.record(HistoryEntry(
      type: HistoryType.shopping,
      title: '${list.name} • ${vm.items.length} barang',
      result: format.rupiah(totals.estimatedTotal),
      savings: totals.discountSavings > decZero ? totals.discountSavings : null,
      inputData: {'listId': list.id},
    ));
    if (context.mounted) {
      showMessage(context,
          ok ? 'Disimpan ke Riwayat' : 'Riwayat tidak dapat disimpan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShoppingViewModel>();
    final format = context.watch<SettingsViewModel>().format;
    return Scaffold(
      appBar: const AppHeader(section: 'Belanja'),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.loadError != null || vm.current == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(vm.loadError ?? 'Daftar tidak tersedia',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(
                            onPressed: vm.init, child: const Text('Coba lagi')),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        children: [
                          _HeaderCard(
                            onSwitch: () => _openLists(context),
                            onSave: () => _save(context),
                          ),
                          const SizedBox(height: 12),
                          _BudgetCard(onEdit: () => _editBudget(context)),
                          const SizedBox(height: 16),
                          _ItemsSection(
                            onEdit: (i) => _editItem(context, i),
                            onError: (e) => _report(context, e),
                            format: format,
                          ),
                        ],
                      ),
                    ),
                    _BottomBar(onAdd: () => _editItem(context)),
                  ],
                ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.onSwitch, required this.onSave});
  final VoidCallback onSwitch;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShoppingViewModel>();
    final scheme = Theme.of(context).colorScheme;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_cart, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(vm.current!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              Pill('${vm.items.length} Barang'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onSwitch,
                icon: const Icon(Icons.swap_horiz, size: 20),
                label: const Text('Ganti Daftar'),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onSave,
                icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                label: const Text('Simpan ke Riwayat'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.onEdit});
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShoppingViewModel>();
    final format = context.watch<SettingsViewModel>().format;
    final scheme = Theme.of(context).colorScheme;
    final t = vm.totals;
    final over = t.isOverBudget;
    final accent = over ? scheme.error : scheme.primary;
    final label = Theme.of(context).textTheme.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700);

    if (!t.hasBudget) {
      return SectionCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BATAS ANGGARAN', style: label),
                  const SizedBox(height: 4),
                  const Text('Belum ada anggaran'),
                ],
              ),
            ),
            FilledButton.tonal(
                onPressed: onEdit, child: const Text('Atur anggaran')),
          ],
        ),
      );
    }

    final progress =
        (t.usedPercent / decHundred).toDecimal(scaleOnInfinitePrecision: 4);
    final fraction = progress.toDouble().clamp(0.0, 1.0);
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BATAS ANGGARAN', style: label),
                    Row(children: [
                      Flexible(
                        child: Text(format.rupiah(t.budget),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800)),
                      ),
                      IconButton(
                        tooltip: 'Ubah anggaran',
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: onEdit,
                      ),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(over ? 'Melebihi' : 'Sisa Uang', style: label),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: over
                          ? scheme.errorContainer
                          : scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      over
                          ? format.rupiah(t.remainingBudget.abs())
                          : '${format.rupiah(t.remainingBudget)} (Aman)',
                      key: const Key('remaining-budget'),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: over
                              ? scheme.onErrorContainer
                              : scheme.onPrimaryContainer),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            label: 'Anggaran terpakai ${format.number(t.usedPercent, places: 1)} persen',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 10,
                color: accent,
                backgroundColor: scheme.surfaceContainerHigh,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text('Terpakai: ${format.rupiah(t.estimatedTotal)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              Text('${format.number(t.usedPercent, places: 1)}% Terpakai',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
            ],
          ),
          if (t.discountSavings > decZero) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Icon(Icons.savings_outlined, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('Penghematan diskon tercatat')),
                Text('+${format.rupiah(t.discountSavings)}',
                    style: TextStyle(
                        color: scheme.primary, fontWeight: FontWeight.w800)),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  const _ItemsSection(
      {required this.onEdit, required this.onError, required this.format});
  final ValueChanged<ShoppingItem> onEdit;
  final ValueChanged<String?> onError;
  final AppNumberFormat format;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShoppingViewModel>();
    final t = vm.totals;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: 'Daftar Belanjaan ',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800)),
                TextSpan(
                    text: '(${t.purchasedCount} dari ${t.itemCount} selesai)',
                    style: Theme.of(context).textTheme.bodySmall),
              ])),
            ),
            TextButton.icon(
              onPressed: t.purchasedCount == 0
                  ? null
                  : () async => onError(await vm.resetPurchased()),
              icon: const Icon(Icons.restart_alt, size: 18),
              label: const Text('Reset Cek'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (vm.items.isEmpty)
          SectionCard(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.shopping_basket_outlined,
                      size: 40, color: scheme.outline),
                  const SizedBox(height: 8),
                  const Text('Belum ada barang',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  const Text('Ketuk "Tambah Barang Belanja" untuk memulai.',
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          )
        else
          for (final item in vm.items) ...[
            _ItemTile(item: item, onEdit: () => onEdit(item), onError: onError),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 4),
        SectionCard(
          color: scheme.surfaceContainerHigh,
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: scheme.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                    'Centang barang yang sudah masuk keranjang agar total '
                    'belanja sebenarnya terlihat.'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile(
      {required this.item, required this.onEdit, required this.onError});
  final ShoppingItem item;
  final VoidCallback onEdit;
  final ValueChanged<String?> onError;

  @override
  Widget build(BuildContext context) {
    final vm = context.read<ShoppingViewModel>();
    final format = context.watch<SettingsViewModel>().format;
    final scheme = Theme.of(context).colorScheme;
    final done = item.isPurchased;
    final textColor = done ? scheme.outline : null;
    final qtyText = format.number(item.quantity, places: 3);
    final hasDiscount =
        item.discountPercent != null && item.discountPercent! > decZero;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
          child: Row(
            children: [
              Semantics(
                label: done
                    ? 'Tandai ${item.name} belum dibeli'
                    : 'Tandai ${item.name} sudah dibeli',
                child: Checkbox(
                  value: done,
                  onChanged: (_) async => onError(await vm.togglePurchased(item)),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            decoration:
                                done ? TextDecoration.lineThrough : null)),
                    Text(
                      '@${format.rupiah(item.unitPrice)}'
                      '${hasDiscount ? ' • diskon ${format.percent(item.discountPercent!)}' : ''}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(format.rupiah(item.data.lineTotal),
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: done ? scheme.outline : scheme.primary)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Kurangi jumlah ${item.name}',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: item.quantity > decOne
                            ? () async => onError(await vm.setQuantity(
                                item, item.quantity - decOne))
                            : null,
                      ),
                      Text(qtyText,
                          key: Key('qty-${item.id}'),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      IconButton(
                        tooltip: 'Tambah jumlah ${item.name}',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () async => onError(
                            await vm.setQuantity(item, item.quantity + decOne)),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ShoppingViewModel>();
    final format = context.watch<SettingsViewModel>().format;
    final scheme = Theme.of(context).colorScheme;
    final t = vm.totals;
    return Material(
      color: scheme.surface,
      elevation: 6,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Di Keranjang (Centang)',
                          style: Theme.of(context).textTheme.labelSmall),
                      Text(format.rupiah(t.purchasedTotal),
                          key: const Key('purchased-total'),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Estimasi Semua Barang',
                        style: Theme.of(context).textTheme.labelSmall),
                    Text(format.rupiah(t.estimatedTotal),
                        key: const Key('estimated-total'),
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: scheme.primary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Tambah Barang Belanja'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BudgetResult {
  const _BudgetResult(this.budget);
  final Decimal? budget;
}

class _BudgetDialog extends StatefulWidget {
  const _BudgetDialog({this.initial});
  final Decimal? initial;

  @override
  State<_BudgetDialog> createState() => _BudgetDialogState();
}

class _BudgetDialogState extends State<_BudgetDialog> {
  TextEditingController? _controller;
  Decimal? _value;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) {
      final format = context.read<SettingsViewModel>().format;
      _value = widget.initial;
      _controller = TextEditingController(
          text: widget.initial == null ? '' : format.inputText(widget.initial!));
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Anggaran Belanja'),
        content: NumberField(
          controller: _controller!,
          label: 'Anggaran',
          prefix: 'Rp',
          errorText: _error,
          onChanged: (v) => _value = v,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          if (widget.initial != null)
            TextButton(
              onPressed: () => Navigator.pop(context, const _BudgetResult(null)),
              child: const Text('Hapus anggaran'),
            ),
          FilledButton(
            onPressed: () {
              final v = _value;
              if (v == null) {
                setState(() => _error = 'Masukkan angka anggaran');
              } else if (isNegative(v)) {
                setState(() => _error = 'Anggaran tidak boleh negatif');
              } else {
                Navigator.pop(context, _BudgetResult(v));
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      );
}

class _ItemFormResult {
  _ItemFormResult({
    required this.name,
    required this.price,
    required this.quantity,
    this.discount,
  }) : delete = false;

  _ItemFormResult.delete()
      : name = '',
        price = decZero,
        quantity = decOne,
        discount = null,
        delete = true;

  final String name;
  final Decimal price;
  final Decimal quantity;
  final Decimal? discount;
  final bool delete;
}

class _ItemForm extends StatefulWidget {
  const _ItemForm({this.item});
  final ShoppingItem? item;

  @override
  State<_ItemForm> createState() => _ItemFormState();
}

class _ItemFormState extends State<_ItemForm> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _qty = TextEditingController();
  final _discount = TextEditingController();
  Decimal? _priceValue;
  Decimal? _qtyValue;
  Decimal? _discountValue;
  bool _initialized = false;
  bool _submitted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final format = context.read<SettingsViewModel>().format;
    final item = widget.item;
    if (item != null) {
      _name.text = item.name;
      _priceValue = item.unitPrice;
      _qtyValue = item.quantity;
      _discountValue = item.discountPercent;
      _price.text = format.inputText(item.unitPrice);
      _qty.text = format.inputText(item.quantity);
      if (item.discountPercent != null) {
        _discount.text = format.inputText(item.discountPercent!);
      }
    } else {
      _qtyValue = decOne;
      _qty.text = '1';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _qty.dispose();
    _discount.dispose();
    super.dispose();
  }

  // Per-field errors, all derived from ShoppingItem.validate.
  String? get _nameError => ShoppingItem.validate(
      name: _name.text, unitPrice: decOne, quantity: decOne);
  String? get _priceError =>
      ShoppingItem.validate(name: 'x', unitPrice: _priceValue, quantity: decOne);
  String? get _qtyError =>
      ShoppingItem.validate(name: 'x', unitPrice: decOne, quantity: _qtyValue);
  String? get _discountError => ShoppingItem.validate(
      name: 'x',
      unitPrice: decOne,
      quantity: decOne,
      discountPercent: _discountValue);

  void _submit() {
    setState(() => _submitted = true);
    if (_nameError != null ||
        _priceError != null ||
        _qtyError != null ||
        _discountError != null) {
      return;
    }
    Navigator.pop(
      context,
      _ItemFormResult(
        name: _name.text,
        price: _priceValue!,
        quantity: _qtyValue!,
        discount: _discountValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.item != null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(editing ? 'Ubah Barang' : 'Tambah Barang',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Nama barang',
                counterText: '',
                errorText: _submitted ? _nameError : null,
              ),
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: _price,
              label: 'Harga satuan',
              prefix: 'Rp',
              errorText: _submitted ? _priceError : null,
              onChanged: (v) => setState(() => _priceValue = v),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NumberField(
                    controller: _qty,
                    label: 'Jumlah',
                    allowDecimal: true,
                    errorText: _submitted ? _qtyError : null,
                    onChanged: (v) => setState(() => _qtyValue = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NumberField(
                    controller: _discount,
                    label: 'Diskon (opsional)',
                    suffix: '%',
                    allowDecimal: true,
                    errorText: _submitted ? _discountError : null,
                    onChanged: (v) => setState(() => _discountValue = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
                onPressed: _submit,
                child: Text(editing ? 'Simpan Perubahan' : 'Tambahkan')),
            if (editing) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                style:
                    TextButton.styleFrom(foregroundColor: AppColors.danger),
                onPressed: () =>
                    Navigator.pop(context, _ItemFormResult.delete()),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Hapus Barang'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
