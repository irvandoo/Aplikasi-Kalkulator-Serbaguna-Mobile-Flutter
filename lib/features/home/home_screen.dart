import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../domain/numeric.dart';
import '../../infrastructure/ad_service.dart';
import '../history/history_view_model.dart';
import '../settings/settings_view_model.dart';
import '../tools/favorites_sheet.dart';
import '../tools/favorites_view_model.dart';
import '../tools/tool_catalog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final searching = _query.trim().isNotEmpty;
    final results = ToolCatalog.all.where((t) => t.matches(_query)).toList();
    return Scaffold(
      appBar: const AppHeader(section: 'Beranda'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          const _GreetingCard(),
          const SizedBox(height: 12),
          const _GuideCard(),
          const SizedBox(height: 12),
          TextField(
            key: const Key('homeSearch'),
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Cari alat kalkulator (misal: diskon, gram)',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 16),
          if (searching)
            _SearchResults(results: results)
          else ...[
            const _SavingsCard(),
            const SizedBox(height: 20),
            const _FavoriteTools(),
            const SizedBox(height: 20),
            const _RecentHistory(),
            const SizedBox(height: 16),
            const Center(
              child: Pill('100% Offline & Ringan · Tanpa Kuota Internet'),
            ),
            const SizedBox(height: 12),
            Center(child: AdBanner(service: context.read<AdService>())),
          ],
        ],
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  const _GreetingCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Halo, Penghemat Cerdas! 👋',
              style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Hitung cepat, belanja lebih hemat hari ini.',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _SavingsCard extends StatelessWidget {
  const _SavingsCard();

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryViewModel>();
    final format = context.watch<SettingsViewModel>().format;
    final savings = history.savingsThisWeek;
    final hasSavings = savings > decZero;
    return Container(
      key: const Key('savingsCard'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.savings_outlined, color: Colors.white70, size: 18),
            const SizedBox(width: 6),
            const Expanded(
              child: Text('AKUMULASI PENGHEMATAN',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6)),
            ),
            if (hasSavings)
              const Pill('Paling Hemat',
                  background: Color(0xFF6FFBBE), foreground: Color(0xFF002113)),
          ]),
          const SizedBox(height: 8),
          const Text('Hemat Pekan Ini',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          Text(format.rupiah(savings),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Pill('${history.count} Perhitungan Tersimpan',
              background: Colors.white.withValues(alpha: 0.18),
              foreground: Colors.white),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: const Key('guideCard'),
        onTap: () => context.push(Routes.guide),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Icon(Icons.menu_book_outlined, color: scheme.primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Panduan Penggunaan',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                  Text('Cara memakai setiap alat dan fitur'),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ]),
        ),
      ),
    );
  }
}

class _FavoriteTools extends StatelessWidget {
  const _FavoriteTools();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final favorites = context.watch<FavoritesViewModel>().favorites;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text('Alat Favorit',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          ),
          TextButton.icon(
            key: const Key('editFavorites'),
            onPressed: () => showFavoritesSheet(context),
            icon: const Icon(Icons.tune, size: 18),
            label: const Text('Atur'),
          ),
          TextButton(
            onPressed: () => context.push(Routes.allTools),
            child: const Text('Semua Alat'),
          ),
        ]),
        const SizedBox(height: 4),
        if (favorites.isEmpty)
          SectionCard(
            key: const Key('noFavorites'),
            child: Row(children: [
              Icon(Icons.star_border, color: scheme.outline),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                    'Belum ada alat favorit. Ketuk "Atur" untuk memilih alat yang sering dipakai.'),
              ),
            ]),
          )
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [for (final t in favorites) _ToolCard(tool: t)],
          ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.tool});
  final ToolInfo tool;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '${tool.title}. ${tool.subtitle}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('tool_${tool.id}'),
          onTap: () => tool.open(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tool.icon, color: scheme.primary),
                  ),
                  const Spacer(),
                  if (tool.badge != null) Pill(tool.badge!),
                ]),
                const Spacer(),
                Text(tool.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                Text(tool.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchResults extends StatelessWidget {
  const _SearchResults({required this.results});
  final List<ToolInfo> results;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(children: [
          Icon(Icons.search_off, size: 48, color: scheme.outline),
          const SizedBox(height: 8),
          const Text('Alat tidak ditemukan'),
        ]),
      );
    }
    return Column(children: [
      for (final t in results)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            key: Key('result_${t.id}'),
            leading: Icon(t.icon, color: scheme.primary),
            title: Text(t.title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(t.subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => t.open(context),
          ),
        ),
    ]);
  }
}

class _RecentHistory extends StatelessWidget {
  const _RecentHistory();

  @override
  Widget build(BuildContext context) {
    final history = context.watch<HistoryViewModel>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final latest = history.latest;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Riwayat Terakhir',
            style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (latest == null)
          SectionCard(
            child: Row(children: [
              Icon(Icons.history, color: scheme.outline),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                    'Belum ada riwayat. Hasil perhitungan yang Anda simpan akan muncul di sini.'),
              ),
            ]),
          )
        else
          SectionCard(
            key: const Key('recentCard'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(latest.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        Text(latest.type.label,
                            style: text.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(latest.result,
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: scheme.primary)),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _recalculate(context, latest),
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Hitung Ulang'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonal(
                      onPressed: () => context.push(Routes.history),
                      child: const Text('Lihat Semua Riwayat'),
                    ),
                  ),
                ]),
              ],
            ),
          ),
      ],
    );
  }

  void _recalculate(BuildContext context, HistoryEntry entry) {
    final tool = ToolCatalog.forType(entry.type);
    if (tool == null) {
      context.push(Routes.history);
      return;
    }
    tool.open(context, restore: entry);
  }
}
