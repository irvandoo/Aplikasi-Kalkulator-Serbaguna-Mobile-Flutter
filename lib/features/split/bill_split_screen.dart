import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/number_format.dart';
import '../../core/number_input.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../domain/bill_split_calculator.dart';
import '../../infrastructure/share_service.dart';
import '../history/history_view_model.dart';
import '../settings/settings_view_model.dart';
import 'bill_split_view_model.dart';

class BillSplitScreen extends StatelessWidget {
  const BillSplitScreen({super.key, this.restore});
  final HistoryEntry? restore;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        key: ObjectKey(restore),
        create: (_) => BillSplitViewModel(restore: restore),
        child: const _BillSplitBody(),
      );
}

class _BillSplitBody extends StatefulWidget {
  const _BillSplitBody();

  @override
  State<_BillSplitBody> createState() => _BillSplitBodyState();
}

class _BillSplitBodyState extends State<_BillSplitBody> {
  late final TextEditingController _bill;
  late final TextEditingController _tax;
  late final TextEditingController _tip;

  @override
  void initState() {
    super.initState();
    final vm = context.read<BillSplitViewModel>();
    final f = context.read<SettingsViewModel>().format;
    String text(Decimal? v) => v == null ? '' : f.inputText(v);
    _bill = TextEditingController(text: text(vm.bill));
    _tax = TextEditingController(text: text(vm.tax));
    _tip = TextEditingController(text: text(vm.tip));
  }

  @override
  void dispose() {
    _bill.dispose();
    _tax.dispose();
    _tip.dispose();
    super.dispose();
  }

  void _applyPreset(TextEditingController c, int percent,
      void Function(Decimal?) set, AppNumberFormat f) {
    final value = Decimal.fromInt(percent);
    c.text = percent == 0 ? '' : f.inputText(value);
    set(percent == 0 ? null : value);
  }

  void _reset(BillSplitViewModel vm) {
    _bill.clear();
    _tax.clear();
    _tip.clear();
    vm.reset();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BillSplitViewModel>();
    final f = context.watch<SettingsViewModel>().format;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final r = vm.result;

    bool presetSelected(Decimal? v, int p) =>
        p == 0 ? (v == null || v == Decimal.zero) : v == Decimal.fromInt(p);

    return ToolPage(
      title: 'Patungan',
      actions: [
        IconButton(
          key: const Key('splitReset'),
          tooltip: 'Reset',
          icon: const Icon(Icons.restart_alt),
          onPressed: () => _reset(vm),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Bagi tagihan rata ke semua orang, lengkap dengan pajak dan tip.',
              style: text.bodyMedium),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(children: [
              NumberField(
                controller: _bill,
                label: 'Total tagihan',
                prefix: 'Rp',
                allowDecimal: true,
                errorText: vm.error,
                onChanged: vm.setBill,
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: Text('Jumlah orang',
                      style: text.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                IconButton.filledTonal(
                  key: const Key('peopleMinus'),
                  tooltip: 'Kurangi orang',
                  icon: const Icon(Icons.remove),
                  onPressed: vm.people > 1 ? vm.decreasePeople : null,
                ),
                SizedBox(
                  width: 56,
                  child: Text('${vm.people}',
                      key: const Key('peopleCount'),
                      textAlign: TextAlign.center,
                      style: text.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                ),
                IconButton.filledTonal(
                  key: const Key('peoplePlus'),
                  tooltip: 'Tambah orang',
                  icon: const Icon(Icons.add),
                  onPressed: vm.people < BillSplitCalculator.maxPeople
                      ? vm.increasePeople
                      : null,
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PercentRow(
                  fieldKey: const Key('tipField'),
                  title: 'Tip / Service (%)',
                  controller: _tip,
                  presets: BillSplitViewModel.tipPresets,
                  isSelected: (p) => presetSelected(vm.tip, p),
                  onPreset: (p) => _applyPreset(_tip, p, vm.setTip, f),
                  onChanged: vm.setTip,
                ),
                const SizedBox(height: 16),
                _PercentRow(
                  fieldKey: const Key('taxField'),
                  title: 'Pajak (%)',
                  controller: _tax,
                  presets: BillSplitViewModel.taxPresets,
                  isSelected: (p) => presetSelected(vm.tax, p),
                  onPreset: (p) => _applyPreset(_tax, p, vm.setTax, f),
                  onChanged: vm.setTax,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bulatkan ke atas per orang',
                    style: text.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Memudahkan uang pas. Kelebihan dihitung otomatis.',
                    style: text.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  for (final option in SplitRounding.values)
                    ChoiceChip(
                      key: Key('round_${option.name}'),
                      label: Text(option.label),
                      selected: vm.rounding == option,
                      onSelected: (_) => vm.setRounding(option),
                    ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            child: r == null
                ? Text('Isi total tagihan untuk melihat pembagian.',
                    style: text.bodyMedium)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SETIAP ORANG BAYAR', style: text.labelSmall),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(f.rupiah(r.perPerson),
                            key: const Key('split_result'),
                            style: text.headlineLarge?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w800)),
                      ),
                      const Divider(height: 24),
                      KeyValueRow('Tagihan', f.rupiah(r.bill)),
                      if (r.tax > Decimal.zero)
                        KeyValueRow('Pajak', '+${f.rupiah(r.tax)}'),
                      if (r.tip > Decimal.zero)
                        KeyValueRow('Tip / Service', '+${f.rupiah(r.tip)}'),
                      KeyValueRow('Total', f.rupiah(r.total), bold: true),
                      KeyValueRow('Dibagi', '${r.people} orang'),
                      if (r.surplus > Decimal.zero)
                        KeyValueRow('Kelebihan (pembulatan)',
                            f.rupiah(r.surplus)),
                    ],
                  ),
          ),
          if (r != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Salin'),
                  onPressed: () async {
                    await context.read<ShareService>().copy(vm.detailText(f));
                    if (context.mounted) showMessage(context, 'Rincian disalin');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Bagikan'),
                  onPressed: () =>
                      context.read<ShareService>().share(vm.detailText(f)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                  label: const Text('Simpan'),
                  onPressed: () async {
                    final entry = vm.toHistoryEntry(f);
                    if (entry == null) return;
                    final ok =
                        await context.read<HistoryViewModel>().record(entry);
                    if (context.mounted) {
                      showMessage(context,
                          ok ? 'Disimpan ke riwayat' : 'Gagal menyimpan');
                    }
                  },
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _PercentRow extends StatelessWidget {
  const _PercentRow({
    required this.fieldKey,
    required this.title,
    required this.controller,
    required this.presets,
    required this.isSelected,
    required this.onPreset,
    required this.onChanged,
  });

  final Key fieldKey;
  final String title;
  final TextEditingController controller;
  final List<int> presets;
  final bool Function(int) isSelected;
  final ValueChanged<int> onPreset;
  final ValueChanged<Decimal?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(spacing: 8, runSpacing: 4, children: [
          for (final p in presets)
            ChoiceChip(
              label: Text('$p%'),
              selected: isSelected(p),
              onSelected: (_) => onPreset(p),
            ),
        ]),
        const SizedBox(height: 8),
        KeyedSubtree(
          key: fieldKey,
          child: NumberField(
            controller: controller,
            label: title,
            suffix: '%',
            allowDecimal: true,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
