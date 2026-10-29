import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/number_input.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/shopping_repository.dart';
import '../../domain/shopping_calculator.dart';
import '../settings/settings_view_model.dart';

/// Saved shopping lists: open, create, rename and delete. Pops with the id of
/// the list the user opened (or null).
class ShoppingListsScreen extends StatefulWidget {
  const ShoppingListsScreen({super.key});

  @override
  State<ShoppingListsScreen> createState() => _ShoppingListsScreenState();
}

class _ShoppingListsScreenState extends State<ShoppingListsScreen> {
  List<ShoppingList>? _lists;
  String? _error;

  ShoppingRepository get _repo => context.read<ShoppingRepository>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final lists = await _repo.lists();
      if (mounted) setState(() => _lists = lists);
    } catch (e, st) {
      debugPrint('Shopping lists failed: $e\n$st');
      if (mounted) setState(() => _error = 'Daftar tidak dapat dimuat');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } on ValidationException catch (e) {
      if (mounted) showMessage(context, e.message);
    } catch (_) {
      if (mounted) showMessage(context, 'Perubahan tidak dapat disimpan');
    }
    await _load();
  }

  Future<void> _edit([ShoppingList? list]) async {
    final result = await showDialog<({String name, Decimal? budget})>(
      context: context,
      builder: (_) => _ListDialog(list: list),
    );
    if (result == null) return;
    await _run(() => _repo.saveList(list == null
        ? ShoppingList(name: result.name.trim(), budget: result.budget)
        : list.copyWith(
            name: result.name.trim(),
            budget: result.budget,
            clearBudget: result.budget == null)));
  }

  Future<void> _delete(ShoppingList list) async {
    final ok = await confirmDelete(
      context,
      title: 'Hapus daftar?',
      message: 'Daftar "${list.name}" beserta ${list.items.length} barang '
          'di dalamnya akan dihapus permanen.',
    );
    if (ok) await _run(() => _repo.deleteList(list.id));
  }

  @override
  Widget build(BuildContext context) {
    final format = context.watch<SettingsViewModel>().format;
    final lists = _lists;
    return ToolPage(
      title: 'Daftar Belanja',
      navIndex: 3,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add),
        label: const Text('Daftar Baru'),
      ),
      child: _error != null
          ? Center(child: Text(_error!))
          : lists == null
              ? const Center(child: CircularProgressIndicator())
              : lists.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'Belum ada daftar belanja. Buat daftar baru untuk memulai.',
                            textAlign: TextAlign.center),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: lists.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final list = lists[i];
                        final totals = const ShoppingCalculator().totals(
                            list.items.map((e) => e.data).toList(),
                            budget: list.budget);
                        return Card(
                          child: ListTile(
                            minTileHeight: 64,
                            onTap: () => context.pop(list.id),
                            title: Text(list.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700)),
                            subtitle: Text(
                                '${list.items.length} barang • '
                                '${format.rupiah(totals.estimatedTotal)}'
                                '${totals.hasBudget ? ' dari ${format.rupiah(totals.budget)}' : ''}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Ubah daftar ${list.name}',
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () => _edit(list),
                                ),
                                IconButton(
                                  tooltip: 'Hapus daftar ${list.name}',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _delete(list),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _ListDialog extends StatefulWidget {
  const _ListDialog({this.list});
  final ShoppingList? list;

  @override
  State<_ListDialog> createState() => _ListDialogState();
}

class _ListDialogState extends State<_ListDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.list?.name ?? '');
  TextEditingController? _budget;
  Decimal? _budgetValue;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_budget == null) {
      final format = context.read<SettingsViewModel>().format;
      final b = widget.list?.budget;
      _budgetValue = b;
      _budget = TextEditingController(text: b == null ? '' : format.inputText(b));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _budget?.dispose();
    super.dispose();
  }

  void _submit() {
    final error = ShoppingList.validate(name: _name.text, budget: _budgetValue);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, (name: _name.text, budget: _budgetValue));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.list == null ? 'Daftar Baru' : 'Ubah Daftar'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                  labelText: 'Nama daftar',
                  errorText: _error,
                  counterText: ''),
            ),
            const SizedBox(height: 12),
            NumberField(
              controller: _budget!,
              label: 'Anggaran (opsional)',
              prefix: 'Rp',
              onChanged: (v) => _budgetValue = v,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
