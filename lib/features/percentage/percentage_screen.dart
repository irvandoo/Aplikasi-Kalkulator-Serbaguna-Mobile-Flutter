import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/number_input.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../domain/percentage_calculator.dart';
import '../../infrastructure/share_service.dart';
import '../history/history_view_model.dart';
import '../settings/settings_view_model.dart';
import 'percentage_view_model.dart';

class PercentageScreen extends StatelessWidget {
  const PercentageScreen({super.key, this.restore});
  final HistoryEntry? restore;

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        key: ObjectKey(restore),
        create: (_) => PercentageViewModel(restore: restore),
        child: const _PercentageBody(),
      );
}

class _PercentageBody extends StatefulWidget {
  const _PercentageBody();

  @override
  State<_PercentageBody> createState() => _PercentageBodyState();
}

class _PercentageBodyState extends State<_PercentageBody> {
  late final TextEditingController _first;
  late final TextEditingController _second;

  @override
  void initState() {
    super.initState();
    final vm = context.read<PercentageViewModel>();
    final f = context.read<SettingsViewModel>().format;
    _first = TextEditingController(
        text: vm.first == null ? '' : f.inputText(vm.first!));
    _second = TextEditingController(
        text: vm.second == null ? '' : f.inputText(vm.second!));
  }

  @override
  void dispose() {
    _first.dispose();
    _second.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PercentageViewModel>();
    final f = context.watch<SettingsViewModel>().format;
    final scheme = Theme.of(context).colorScheme;
    final labels = vm.labels;
    final result = vm.result;

    return ToolPage(
      title: 'Kalkulator Persentase',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final m in PercentageMode.values)
                ChoiceChip(
                  label: Text(m.label),
                  selected: vm.mode == m,
                  onSelected: (_) => vm.setMode(m),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(labels.hint, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(children: [
              NumberField(
                controller: _first,
                label: labels.first,
                suffix: PercentageFieldLabels.firstIsPercent(vm.mode) ? '%' : null,
                allowDecimal: true,
                allowNegative: true,
                onChanged: vm.setFirst,
              ),
              const SizedBox(height: 12),
              NumberField(
                controller: _second,
                label: labels.second,
                suffix:
                    PercentageFieldLabels.secondIsPercent(vm.mode) ? '%' : null,
                allowDecimal: true,
                allowNegative: true,
                errorText: vm.error,
                onChanged: vm.setSecond,
              ),
            ]),
          ),
          const SizedBox(height: 12),
          SectionCard(
            color: scheme.primaryContainer.withValues(alpha: 0.35),
            child: result == null
                ? Text('Isi kedua kolom untuk melihat hasil.',
                    style: Theme.of(context).textTheme.bodyMedium)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HASIL',
                          style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(vm.formatResult(f),
                            key: const Key('percentage_result'),
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(height: 4),
                      Text('Rumus: ${result.formula}',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
          ),
          if (result != null) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Salin'),
                  onPressed: () async {
                    await context.read<ShareService>().copy(vm.formatResult(f));
                    if (context.mounted) showMessage(context, 'Hasil disalin');
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
