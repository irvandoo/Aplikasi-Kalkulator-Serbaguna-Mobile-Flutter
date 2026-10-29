import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets.dart';
import 'favorites_view_model.dart';
import 'tool_catalog.dart';

class AllToolsScreen extends StatefulWidget {
  const AllToolsScreen({super.key});

  @override
  State<AllToolsScreen> createState() => _AllToolsScreenState();
}

class _AllToolsScreenState extends State<AllToolsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final tools = ToolCatalog.all.where((t) => t.matches(_query)).toList();
    final scheme = Theme.of(context).colorScheme;
    final favorites = context.watch<FavoritesViewModel>();
    return ToolPage(
      title: 'Semua Alat',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            key: const Key('allToolsSearch'),
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Cari alat (misal: diskon, gram)',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          if (tools.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Column(children: [
                Icon(Icons.search_off, size: 48, color: scheme.outline),
                const SizedBox(height: 8),
                const Text('Alat tidak ditemukan'),
              ]),
            ),
          for (final t in tools)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: ListTile(
                  key: Key('tool_${t.id}'),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(t.icon, color: scheme.onPrimaryContainer),
                  ),
                  title: Text(t.title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(t.description),
                  trailing: IconButton(
                    key: Key('star_${t.id}'),
                    tooltip: favorites.isFavorite(t.id)
                        ? 'Hapus dari favorit'
                        : 'Jadikan favorit',
                    icon: Icon(favorites.isFavorite(t.id)
                        ? Icons.star
                        : Icons.star_border),
                    color: favorites.isFavorite(t.id)
                        ? scheme.primary
                        : scheme.outline,
                    onPressed: () => favorites.toggle(t.id),
                  ),
                  onTap: () => t.open(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
