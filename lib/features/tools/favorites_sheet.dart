import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'favorites_view_model.dart';

/// Bottom sheet to choose and reorder the Home favorites.
Future<void> showFavoritesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<FavoritesViewModel>(),
      child: const _FavoritesSheet(),
    ),
  );
}

class _FavoritesSheet extends StatelessWidget {
  const _FavoritesSheet();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<FavoritesViewModel>();
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final favorites = vm.favorites;
    final others = vm.others;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) => ListView(
        key: const Key('favoritesSheet'),
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Row(children: [
            Expanded(
              child: Text('Atur Alat Favorit',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            ),
            TextButton(
              key: const Key('favoritesReset'),
              onPressed: vm.reset,
              child: const Text('Atur ulang'),
            ),
          ]),
          Text('Tahan dan geser untuk mengubah urutan di Beranda.',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          if (favorites.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Belum ada favorit. Tambahkan dari daftar di bawah.'),
            )
          else
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorderItem: vm.reorder,
              children: [
                for (final t in favorites)
                  ListTile(
                    key: ValueKey('fav_${t.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(t.icon, color: scheme.primary),
                    title: Text(t.title,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(t.subtitle),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        key: Key('unfav_${t.id}'),
                        tooltip: 'Hapus dari favorit',
                        icon: const Icon(Icons.star),
                        color: scheme.primary,
                        onPressed: () => vm.toggle(t.id),
                      ),
                      const Icon(Icons.drag_handle),
                    ]),
                  ),
              ],
            ),
          if (others.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Tambah ke favorit',
                style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            for (final t in others)
              ListTile(
                key: ValueKey('other_${t.id}'),
                contentPadding: EdgeInsets.zero,
                leading: Icon(t.icon, color: scheme.outline),
                title: Text(t.title),
                subtitle: Text(t.subtitle),
                trailing: IconButton(
                  key: Key('fav_${t.id}'),
                  tooltip: 'Tambah ke favorit',
                  icon: const Icon(Icons.star_border),
                  onPressed: () => vm.toggle(t.id),
                ),
              ),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Selesai'),
          ),
        ],
      ),
    );
  }
}
