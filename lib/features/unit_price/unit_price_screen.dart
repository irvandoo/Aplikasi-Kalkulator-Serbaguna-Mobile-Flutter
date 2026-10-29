import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/number_format.dart';
import '../../core/number_input.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../domain/unit_price_calculator.dart';
import '../../infrastructure/share_service.dart';
import '../history/history_view_model.dart';
import '../settings/settings_view_model.dart';
import 'unit_price_view_model.dart';

class UnitPriceScreen extends StatelessWidget {
  const UnitPriceScreen({super.key, this.restore});
  final HistoryEntry? restore;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        key: ObjectKey(restore),
        create: (_) => UnitPriceViewModel(restore: restore),
        child: const _UnitPriceBody(),
      );
}

class _UnitPriceBody extends StatelessWidget {
  const _UnitPriceBody();

  IconData _icon(UnitDimension d) => switch (d) {
        UnitDimension.weight => Icons.scale_outlined,
        UnitDimension.volume => Icons.water_drop_outlined,
        UnitDimension.count => Icons.category_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UnitPriceViewModel>();
    final f = context.watch<SettingsViewModel>().format;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          const AppHeader(section: 'Banding'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                Container(
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
                        backgroundColor: scheme.primaryContainer,
                        child: Icon(Icons.balance,
                            size: 18, color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cerdas Belanja Harian',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w800)),
                            Text(
                              'Bandingkan ukuran kemasan atau merek untuk tahu '
                              'mana yang sebenarnya lebih murah per gram, ml, '
                              'atau butir.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<UnitDimension>(
                    showSelectedIcon: false,
                    segments: [
                      for (final d in UnitDimension.values)
                        ButtonSegment(
                          value: d,
                          icon: Icon(_icon(d), size: 18),
                          label: Text(d.label),
                        ),
                    ],
                    selected: {vm.dimension},
                    onSelectionChanged: (s) => vm.setDimension(s.first),
                  ),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < vm.products.length; i++) ...[
                  _ProductCard(
                    key: ValueKey(vm.products[i].id),
                    index: i,
                    product: vm.products[i],
                  ),
                  const SizedBox(height: 12),
                ],
                _Analysis(vm: vm, format: f),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: vm.swapAB,
                      icon: const Icon(Icons.swap_vert),
                      label: const Text('Tukar A/B'),
                    ),
                    OutlinedButton.icon(
                      onPressed: vm.reset,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset Nilai'),
                    ),
                    if (vm.canAdd)
                      OutlinedButton.icon(
                        onPressed: vm.addProduct,
                        icon: const Icon(Icons.add_circle_outline),
                        label: Text(
                            'Tambah Opsi ${String.fromCharCode(65 + vm.products.length)}'),
                      ),
                  ],
                ),
                if (vm.comparison != null) ...[
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.bookmark_add_outlined, size: 18),
                        label: const Text('Simpan'),
                        onPressed: () async {
                          final entry = vm.toHistoryEntry(f);
                          if (entry == null) return;
                          final ok = await context
                              .read<HistoryViewModel>()
                              .record(entry);
                          if (context.mounted) {
                            showMessage(context,
                                ok ? 'Disimpan ke riwayat' : 'Gagal menyimpan');
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Salin'),
                        onPressed: () async {
                          await context
                              .read<ShareService>()
                              .copy(vm.detailText(f));
                          if (context.mounted) {
                            showMessage(context, 'Hasil disalin');
                          }
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Bagikan hasil',
                      icon: const Icon(Icons.share),
                      onPressed: () =>
                          context.read<ShareService>().share(vm.detailText(f)),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  const _ProductCard({super.key, required this.index, required this.product});
  final int index;
  final UnitProduct product;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  late final TextEditingController _price;
  late final TextEditingController _qty;

  @override
  void initState() {
    super.initState();
    final f = context.read<SettingsViewModel>().format;
    final p = widget.product;
    _price = TextEditingController(
        text: p.price == null ? '' : f.inputText(p.price!));
    _qty = TextEditingController(
        text: p.quantity == null ? '' : f.inputText(p.quantity!));
  }

  @override
  void dispose() {
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UnitPriceViewModel>();
    final f = context.watch<SettingsViewModel>().format;
    final scheme = Theme.of(context).colorScheme;
    final i = widget.index;
    final name = UnitPriceViewModel.optionName(i);
    final item = vm.comparisonFor(i);
    final best = item != null && item.isCheapest && !vm.comparison!.isTie;
    final error = vm.validationFor(i);
    final unitPrice = vm.unitPriceFor(i);
    final unit = widget.product.unit;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: best ? Border.all(color: AppColors.tertiary, width: 2) : null,
      ),
      child: SectionCard(
        color: best ? scheme.primaryContainer.withValues(alpha: 0.25) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(name,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
              if (best)
                const Pill('PALING HEMAT',
                    background: AppColors.tertiary, foreground: Colors.white),
              if (vm.canRemove && i >= 2)
                IconButton(
                  tooltip: 'Hapus $name',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => vm.removeProduct(i),
                ),
            ]),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NumberField(
                    controller: _price,
                    label: 'Harga total $name',
                    prefix: 'Rp',
                    allowDecimal: true,
                    allowNegative: true,
                    onChanged: (v) => vm.setPrice(i, v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: NumberField(
                    controller: _qty,
                    label: 'Ukuran / isi $name',
                    allowDecimal: true,
                    allowNegative: true,
                    onChanged: (v) => vm.setQuantity(i, v),
                  ),
                ),
                const SizedBox(width: 4),
                if (UnitDimension.count == unit.dimension)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(unit.symbol),
                  )
                else
                  DropdownButtonHideUnderline(
                    child: DropdownButton<MeasureUnit>(
                      value: unit,
                      iconSize: 20,
                      items: [
                        for (final u in MeasureUnit.forDimension(vm.dimension))
                          DropdownMenuItem(value: u, child: Text(u.symbol)),
                      ],
                      onChanged: (u) {
                        if (u != null) vm.setUnit(i, u);
                      },
                    ),
                  ),
              ],
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(error,
                    style: TextStyle(color: scheme.error, fontSize: 12)),
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: best ? AppColors.primaryDark : scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Expanded(
                  child: Text('Harga Satuan Unit',
                      style: TextStyle(
                          color: best ? Colors.white : scheme.onSurface)),
                ),
                Text(
                  unitPrice == null
                      ? '-'
                      : '${f.rupiahDecimal(unitPrice)} / ${vm.dimension.baseName}',
                  key: Key('unit_price_$i'),
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: best ? Colors.white : scheme.onSurface),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _Analysis extends StatelessWidget {
  const _Analysis({required this.vm, required this.format});
  final UnitPriceViewModel vm;
  final AppNumberFormat format;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = vm.comparison;
    final textTheme = Theme.of(context).textTheme;

    if (c == null) {
      return SectionCard(
        child: Text(
          vm.comparisonError ??
              'Isi harga dan ukuran minimal dua pilihan untuk melihat '
                  'analisis penghematan.',
          style: textTheme.bodyMedium?.copyWith(
              color: vm.comparisonError == null ? null : scheme.error),
        ),
      );
    }

    final unit = vm.dimension.baseName;
    final Decimal? saving = vm.maxSavingPercent;
    final Decimal? diff = vm.maxNominalDifference;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('Analisis & Penghematan',
                  style: textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800)),
            ),
            if (saving != null) Pill('Hemat ${format.percent(saving)}'),
          ]),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.isTie
                      ? 'Harga satuan sama'
                      : '${UnitPriceViewModel.optionName(c.cheapestIndex)} Lebih Murah!',
                  key: const Key('unit_price_verdict'),
                  style: textTheme.titleMedium?.copyWith(
                      color: scheme.primary, fontWeight: FontWeight.w800),
                ),
                if (diff != null)
                  Text('Selisih ${format.rupiahDecimal(diff)} per $unit '
                      'dibanding opsi termahal.'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text('Perbandingan Biaya Relatif', style: textTheme.labelMedium),
          const SizedBox(height: 6),
          for (final item in c.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(
                  width: 64,
                  child: Text(UnitPriceViewModel.optionName(item.index),
                      style: textTheme.bodySmall),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      minHeight: 10,
                      value: vm.barFraction(item.index),
                      color: item.isCheapest && !c.isTie
                          ? AppColors.primaryDark
                          : scheme.outline,
                      backgroundColor: scheme.surfaceContainerHigh,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(format.rupiahDecimal(item.unitPrice),
                    style: textTheme.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ]),
            ),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.lightbulb_outline, size: 18, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tips: cek tanggal kedaluwarsa sebelum membeli kemasan jumbo '
                'untuk mencegah sisa terbuang.',
                style: textTheme.bodySmall,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
