import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../infrastructure/ad_service.dart';
import '../../infrastructure/share_service.dart';
import 'history_view_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const List<HistoryType> _filters = [
    HistoryType.calculator,
    HistoryType.percentage,
    HistoryType.discount,
    HistoryType.shopping,
    HistoryType.unitPrice,
    HistoryType.billSplit,
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();
    final ads = context.watch<AdService>();
    return ToolPage(
      title: 'Riwayat',
      actions: [
        IconButton(
          tooltip: 'Hapus semua riwayat',
          icon: const Icon(Icons.delete_sweep_outlined),
          onPressed: vm.entries.isEmpty ? null : () => _clearAll(context, vm),
        ),
      ],
      child: Column(
        children: [
          SizedBox(
            height: 56,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  _chip('Semua', vm.filter == null, () => vm.setFilter(null)),
                  for (final t in _filters)
                    _chip(t.label, vm.filter == t, () => vm.setFilter(t)),
                ],
              ),
            ),
          ),
          Expanded(child: _body(context, vm)),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: AdBanner(service: ads),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
        ),
      );

  Widget _body(BuildContext context, HistoryViewModel vm) {
    final scheme = Theme.of(context).colorScheme;
    if (vm.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.error != null) {
      return _Message(
        icon: Icons.error_outline,
        text: vm.error!,
        action: FilledButton(onPressed: vm.load, child: const Text('Coba lagi')),
      );
    }
    final items = vm.visible;
    if (items.isEmpty) {
      return _Message(
        icon: Icons.history,
        text: vm.filter == null
            ? 'Belum ada riwayat.\nPerhitungan yang disimpan muncul di sini.'
            : 'Belum ada riwayat ${vm.filter!.label}.',
        color: scheme.onSurfaceVariant,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _HistoryTile(entry: items[i]),
    );
  }

  Future<void> _clearAll(BuildContext context, HistoryViewModel vm) async {
    final ok = await confirmDelete(
      context,
      title: 'Hapus semua riwayat?',
      message: '${vm.count} catatan akan dihapus permanen.',
      confirmLabel: 'Hapus semua',
    );
    if (ok) await vm.clear();
  }
}

class _Message extends StatelessWidget {
  const _Message(
      {required this.icon, required this.text, this.action, this.color});
  final IconData icon;
  final String text;
  final Widget? action;
  final Color? color;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(text,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: color)),
              if (action != null) ...[const SizedBox(height: 16), action!],
            ],
          ),
        ),
      );
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});
  final HistoryEntry entry;

  static String _route(HistoryType t) => switch (t) {
        HistoryType.calculator => Routes.calculator,
        HistoryType.percentage => Routes.percentage,
        HistoryType.discount => Routes.discount,
        HistoryType.shopping => Routes.shopping,
        HistoryType.unitPrice => Routes.unitPrice,
        HistoryType.billSplit => Routes.billSplit,
      };

  void _recalculate(BuildContext context) {
    final route = _route(entry.type);
    if (entry.type == HistoryType.percentage ||
        entry.type == HistoryType.billSplit) {
      context.push(route, extra: entry);
    } else {
      context.go(route, extra: entry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final share = context.read<ShareService>();
    final time = DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(entry.createdAt);
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Pill(entry.type.label),
            const SizedBox(width: 8),
            Expanded(
              child: Text(time,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(entry.title, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 2),
          Text(entry.result,
              style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800, color: scheme.primary)),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Salin hasil',
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () async {
                  await share.copy(entry.result);
                  if (context.mounted) showMessage(context, 'Hasil disalin');
                },
              ),
              IconButton(
                tooltip: 'Bagikan',
                icon: const Icon(Icons.share, size: 20),
                onPressed: () async {
                  try {
                    await share.share(entry.shareText);
                  } catch (_) {
                    if (context.mounted) {
                      showMessage(context, 'Gagal membagikan');
                    }
                  }
                },
              ),
              IconButton(
                tooltip: 'Hitung ulang',
                icon: const Icon(Icons.replay, size: 20),
                onPressed: () => _recalculate(context),
              ),
              IconButton(
                tooltip: 'Hapus',
                icon: Icon(Icons.delete_outline, size: 20, color: scheme.error),
                onPressed: () => context.read<HistoryViewModel>().delete(entry.id),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
