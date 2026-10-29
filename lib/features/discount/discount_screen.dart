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
import '../../domain/discount_calculator.dart';
import '../../domain/numeric.dart';
import '../../infrastructure/share_service.dart';
import '../history/history_view_model.dart';
import '../settings/settings_view_model.dart';
import 'discount_view_model.dart';

class DiscountScreen extends StatelessWidget {
  const DiscountScreen({super.key, this.restore});

  /// History entry to reopen ("Hitung Ulang").
  final HistoryEntry? restore;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        key: ObjectKey(restore),
        create: (_) => DiscountViewModel(restore: restore),
        child: const _DiscountBody(),
      );
}

/// Row of quick-select chips; the chip equal to [selected] is highlighted.
class QuickChips extends StatelessWidget {
  const QuickChips({
    super.key,
    required this.values,
    required this.labelFor,
    required this.selected,
    required this.onSelected,
  });

  final List<int> values;
  final String Function(int) labelFor;
  final Decimal? selected;
  final ValueChanged<Decimal> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        children: [
          for (final v in values)
            ChoiceChip(
              label: Text(labelFor(v)),
              selected: selected == Decimal.fromInt(v),
              onSelected: (_) => onSelected(Decimal.fromInt(v)),
            ),
        ],
      );
}

class _DiscountBody extends StatefulWidget {
  const _DiscountBody();

  @override
  State<_DiscountBody> createState() => _DiscountBodyState();
}

class _DiscountBodyState extends State<_DiscountBody> {
  late final TextEditingController _price;
  late final TextEditingController _fee;
  final List<TextEditingController> _stages = [];

  @override
  void initState() {
    super.initState();
    final vm = context.read<DiscountViewModel>();
    final f = context.read<SettingsViewModel>().format;
    String text(Decimal? v) => v == null ? '' : f.inputText(v);
    _price = TextEditingController(text: text(vm.price));
    _fee = TextEditingController(text: text(vm.fee));
    for (final s in vm.stages) {
      _stages.add(TextEditingController(text: text(s)));
    }
  }

  @override
  void dispose() {
    _price.dispose();
    _fee.dispose();
    for (final c in _stages) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncStageControllers(DiscountViewModel vm) {
    while (_stages.length < vm.stages.length) {
      _stages.add(TextEditingController());
    }
  }

  void _setPrice(Decimal? v) {
    final f = context.read<SettingsViewModel>().format;
    _price.text = v == null ? '' : f.inputText(v);
    context.read<DiscountViewModel>().setPrice(v);
  }

  void _setStage(int i, Decimal v) {
    final f = context.read<SettingsViewModel>().format;
    _stages[i].text = f.inputText(v);
    context.read<DiscountViewModel>().setStage(i, v);
  }

  void _removeStage(int i) {
    final vm = context.read<DiscountViewModel>();
    vm.removeStage(i);
    _stages.removeAt(i).dispose();
  }

  Future<void> _copy(String text) async {
    await context.read<ShareService>().copy(text);
    if (mounted) showMessage(context, 'Rincian disalin');
  }

  Future<void> _save(DiscountViewModel vm, AppNumberFormat f) async {
    final entry = vm.toHistoryEntry(f);
    if (entry == null) return;
    final ok = await context.read<HistoryViewModel>().record(entry);
    if (mounted) {
      showMessage(context, ok ? 'Catatan disimpan' : 'Catatan gagal disimpan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiscountViewModel>();
    final f = context.watch<SettingsViewModel>().format;
    final scheme = Theme.of(context).colorScheme;
    _syncStageControllers(vm);

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(section: 'Diskon'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _InfoBanner(
                  icon: Icons.percent,
                  title: 'Promo Mall & Flash Sale',
                  body: 'Hitung diskon tunggal, diskon ganda (misal 50%+20%), '
                      'serta pajak PPN langsung akurat.',
                ),
                const SizedBox(height: 12),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.sell_outlined, color: scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Harga Asli / Label Barang',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800)),
                        ),
                        Text('Rupiah (IDR)',
                            style: Theme.of(context).textTheme.labelSmall),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: NumberField(
                            controller: _price,
                            prefix: 'Rp',
                            hint: '0',
                            semanticLabel: 'Harga asli',
                            textStyle: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                            onChanged: vm.setPrice,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Hapus harga',
                          icon: const Icon(Icons.close),
                          onPressed: () => _setPrice(null),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      QuickChips(
                        values: const [50000, 100000, 250000, 500000],
                        labelFor: (v) => 'Rp${v ~/ 1000}rb',
                        selected: vm.price,
                        onSelected: _setPrice,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Diskon Tahap 1 (Utama)',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 12),
                      _percentField(0, 'Diskon tahap 1', vm),
                      const SizedBox(height: 8),
                      QuickChips(
                        values: const [10, 20, 30, 50, 70],
                        labelFor: (v) => '$v%',
                        selected: vm.stages.first,
                        onSelected: (v) => _setStage(0, v),
                      ),
                      const SizedBox(height: 12),
                      _extraCard(vm, scheme),
                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Tambah Pajak PPN (11%)'),
                        subtitle:
                            const Text('Dikenakan setelah total diskon'),
                        value: vm.taxEnabled,
                        onChanged: vm.setTaxEnabled,
                      ),
                      const SizedBox(height: 8),
                      NumberField(
                        controller: _fee,
                        label: 'Biaya Layanan / Parkir (flat)',
                        prefix: 'Rp',
                        hint: '0',
                        onChanged: vm.setFee,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ResultCard(
                  vm: vm,
                  format: f,
                  onCopy: () => _copy(vm.detailText(f)),
                  onSave: () => _save(vm, f),
                  onShare: () =>
                      context.read<ShareService>().share(vm.detailText(f)),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.push(Routes.discountCompare),
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('Bandingkan Penawaran'),
                ),
                const SizedBox(height: 12),
                const _InfoBanner(
                  icon: Icons.lightbulb_outline,
                  title: 'Tips Pintar Berbelanja',
                  body: 'Diskon bertingkat 50%+20% bukan 70%, melainkan hemat '
                      'riil 60%. Gunakan kalkulator ini agar tidak terkecoh '
                      'gimmick promo!',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _percentField(int i, String label, DiscountViewModel vm) => NumberField(
        controller: _stages[i],
        label: label,
        semanticLabel: label,
        suffix: '%',
        hint: '0',
        allowDecimal: true,
        onChanged: (v) => vm.setStage(i, v),
      );

  Widget _extraCard(DiscountViewModel vm, ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('Diskon Kedua (+Bertingkat)',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            Switch(
              value: vm.extraEnabled,
              onChanged: vm.setExtraEnabled,
            ),
          ]),
          Text(
            'Dihitung dari sisa harga setelah diskon sebelumnya '
            '(cth: Dept Store 30% +10%).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (vm.extraEnabled) ...[
            for (var i = 1; i < vm.stages.length; i++) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _percentField(i, 'Diskon tahap ${i + 1}', vm)),
                if (i >= 2)
                  IconButton(
                    tooltip: 'Hapus tahap ${i + 1}',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _removeStage(i),
                  ),
              ]),
              const SizedBox(height: 8),
              QuickChips(
                values: const [5, 10, 20],
                labelFor: (v) => '$v%',
                selected: vm.stages[i],
                onSelected: (v) => _setStage(i, v),
              ),
            ],
            if (vm.canAddStage)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => vm.addStage(),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah tahap'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner(
      {required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: scheme.primary,
            child: Icon(icon, size: 18, color: scheme.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.vm,
    required this.format,
    required this.onCopy,
    required this.onSave,
    required this.onShare,
  });

  final DiscountViewModel vm;
  final AppNumberFormat format;
  final VoidCallback onCopy;
  final VoidCallback onSave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final r = vm.result;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.receipt_long, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Rincian Penghematan',
                  style: textTheme.titleMedium?.copyWith(
                      color: Colors.white, fontWeight: FontWeight.w800)),
            ),
            if (r != null)
              Pill('Total Hemat ${format.percent(r.savingsPercent)}',
                  background: AppColors.tertiary, foreground: Colors.white),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: r == null ? _empty(context) : _details(context, r),
          ),
          if (r != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Salin Rincian'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      foregroundColor: Colors.white),
                  onPressed: onSave,
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Simpan Catatan'),
                ),
              ),
              IconButton(
                tooltip: 'Bagikan rincian',
                color: Colors.white,
                icon: const Icon(Icons.share),
                onPressed: onShare,
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final error = vm.error;
    return Text(
      error ?? 'Masukkan harga asli untuk melihat rincian penghematan.',
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: error == null ? null : Theme.of(context).colorScheme.error),
    );
  }

  Widget _details(BuildContext context, DiscountResult r) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final green = scheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('HARGA AKHIR YANG HARUS DIBAYAR',
            style: textTheme.labelSmall?.copyWith(letterSpacing: 0.6)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(format.rupiah(r.finalPrice),
                    key: const Key('discount_final_price'),
                    style: textTheme.headlineMedium?.copyWith(
                        color: green, fontWeight: FontWeight.w800)),
              ),
            ),
            Pill('-${format.rupiah(r.savings)}',
                background: scheme.primaryContainer),
          ],
        ),
        const SizedBox(height: 8),
        KeyValueRow('Harga Label Awal', format.rupiah(r.originalPrice)),
        for (var i = 0; i < r.steps.length; i++) ...[
          KeyValueRow('Potongan Diskon ${i + 1} (${format.percent(r.steps[i].percent)})',
              '-${format.rupiah(r.steps[i].amount)}',
              color: green),
          if (i < r.steps.length - 1)
            KeyValueRow('   ? Sisa Harga Antara',
                format.rupiah(r.steps[i].remaining)),
        ],
        if (r.taxAmount > decZero)
          KeyValueRow('PPN (${format.percent(r.taxPercent)})',
              '+${format.rupiah(r.taxAmount)}'),
        if (r.additionalFee > decZero)
          KeyValueRow('Biaya layanan', '+${format.rupiah(r.additionalFee)}'),
      ],
    );
  }
}
