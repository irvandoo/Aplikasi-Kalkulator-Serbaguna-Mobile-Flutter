import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/number_format.dart';
import '../../core/number_input.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../domain/numeric.dart';
import '../settings/settings_view_model.dart';
import 'discount_view_model.dart';

/// Compares two or more discount offers by their final price.
class DiscountCompareScreen extends StatelessWidget {
  const DiscountCompareScreen({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => DiscountCompareViewModel(),
        child: const _CompareBody(),
      );
}

class _OfferControllers {
  final price = TextEditingController();
  final first = TextEditingController();
  final second = TextEditingController();
  final fee = TextEditingController();

  void dispose() {
    price.dispose();
    first.dispose();
    second.dispose();
    fee.dispose();
  }
}

class _CompareBody extends StatefulWidget {
  const _CompareBody();

  @override
  State<_CompareBody> createState() => _CompareBodyState();
}

class _CompareBodyState extends State<_CompareBody> {
  final List<_OfferControllers> _controllers = [];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<DiscountCompareViewModel>();
    final f = context.watch<SettingsViewModel>().format;
    while (_controllers.length < vm.offers.length) {
      _controllers.add(_OfferControllers());
    }
    final scheme = Theme.of(context).colorScheme;

    return ToolPage(
      title: 'Bandingkan Penawaran',
      navIndex: 2,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Masukkan harga dan diskon tiap penawaran. Penawaran dengan harga '
            'akhir terendah ditandai "Paling Hemat".',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Tambah PPN 11% pada semua penawaran'),
            value: vm.taxEnabled,
            onChanged: vm.setTaxEnabled,
          ),
          for (var i = 0; i < vm.offers.length; i++) ...[
            _OfferCard(
              index: i,
              controllers: _controllers[i],
              evaluation: vm.evaluations[i],
              format: f,
              vm: vm,
              onRemove: vm.canRemove
                  ? () {
                      vm.remove(i);
                      _controllers.removeAt(i).dispose();
                    }
                  : null,
            ),
            const SizedBox(height: 12),
          ],
          if (vm.canAdd)
            OutlinedButton.icon(
              onPressed: vm.add,
              icon: const Icon(Icons.add),
              label: Text(
                  'Tambah Penawaran ${String.fromCharCode(65 + vm.offers.length)}'),
            ),
          const SizedBox(height: 12),
          _Summary(vm: vm, format: f, scheme: scheme),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.index,
    required this.controllers,
    required this.evaluation,
    required this.format,
    required this.vm,
    required this.onRemove,
  });

  final int index;
  final _OfferControllers controllers;
  final OfferEvaluation evaluation;
  final AppNumberFormat format;
  final DiscountCompareViewModel vm;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = 'Penawaran ${String.fromCharCode(65 + index)}';
    final r = evaluation.result;
    final error = evaluation.outcome?.errorOrNull;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: evaluation.isCheapest
            ? Border.all(color: AppColors.tertiary, width: 2)
            : null,
      ),
      child: SectionCard(
        color: evaluation.isCheapest
            ? scheme.primaryContainer.withValues(alpha: 0.25)
            : null,
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
              if (evaluation.isCheapest)
                const Pill('Paling Hemat',
                    background: AppColors.tertiary, foreground: Colors.white),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Hapus $name',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onRemove,
                ),
            ]),
            const SizedBox(height: 8),
            NumberField(
              controller: controllers.price,
              label: 'Harga asli $name',
              prefix: 'Rp',
              onChanged: (v) => vm.update(index,
                  (o) => v == null ? o.copyWith(clearPrice: true) : o.copyWith(price: v)),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: NumberField(
                  controller: controllers.first,
                  label: 'Diskon 1',
                  suffix: '%',
                  allowDecimal: true,
                  onChanged: (v) => vm.update(index,
                      (o) => v == null ? o.copyWith(clearFirst: true) : o.copyWith(first: v)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NumberField(
                  controller: controllers.second,
                  label: 'Diskon 2',
                  suffix: '%',
                  allowDecimal: true,
                  onChanged: (v) => vm.update(index,
                      (o) => v == null ? o.copyWith(clearSecond: true) : o.copyWith(second: v)),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            NumberField(
              controller: controllers.fee,
              label: 'Biaya tambahan (opsional)',
              prefix: 'Rp',
              onChanged: (v) => vm.update(index,
                  (o) => v == null ? o.copyWith(clearFee: true) : o.copyWith(fee: v)),
            ),
            const SizedBox(height: 12),
            if (error != null)
              Text(error, style: TextStyle(color: scheme.error))
            else if (r != null) ...[
              KeyValueRow('Harga akhir', format.rupiah(r.finalPrice),
                  bold: true, color: scheme.primary),
              KeyValueRow('Total hemat', format.rupiah(r.savings)),
              if (evaluation.nominalDifference != null &&
                  !evaluation.isCheapest)
                KeyValueRow(
                  'Lebih mahal dari yang termurah',
                  '+${format.rupiah(evaluation.nominalDifference!)} '
                      '(${format.percent(evaluation.percentDifference!)})',
                  color: scheme.error,
                ),
            ] else
              Text('Isi harga asli untuk melihat hasil.',
                  style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary(
      {required this.vm, required this.format, required this.scheme});
  final DiscountCompareViewModel vm;
  final AppNumberFormat format;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    if (!vm.comparable) {
      return SectionCard(
        child: Text(
          'Isi minimal dua penawaran dengan harga valid untuk membandingkan.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    final best = vm.evaluations.indexWhere((e) => e.isCheapest);
    final name = String.fromCharCode(65 + best);
    final price = vm.evaluations[best].result!.finalPrice;
    final others = vm.evaluations
        .where((e) => e.nominalDifference != null && !e.isCheapest)
        .toList();
    final tie = others.isNotEmpty &&
        others.every((e) => e.nominalDifference == decZero);
    return SectionCard(
      color: scheme.primaryContainer.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tie ? 'Harga akhir semua penawaran sama' : 'Penawaran $name paling hemat!',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800, color: scheme.primary),
          ),
          const SizedBox(height: 4),
          Text('Harga akhir terendah: ${format.rupiah(price)}'),
        ],
      ),
    );
  }
}
