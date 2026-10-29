import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tool_catalog.dart';

abstract class FavoritesRepository {
  /// Saved tool ids in display order, or null when the user never edited them.
  Future<List<String>?> load();
  Future<void> save(List<String> ids);
}

class PrefsFavoritesRepository implements FavoritesRepository {
  PrefsFavoritesRepository(this._prefs);
  final SharedPreferences _prefs;
  static const _key = 'favorite_tools';

  @override
  Future<List<String>?> load() async => _prefs.getStringList(_key);

  @override
  Future<void> save(List<String> ids) => _prefs.setStringList(_key, ids);
}

class MemoryFavoritesRepository implements FavoritesRepository {
  MemoryFavoritesRepository([this.saved]);
  List<String>? saved;

  @override
  Future<List<String>?> load() async => saved;
  @override
  Future<void> save(List<String> ids) async => saved = [...ids];
}

/// The tools pinned on Home ("Alat Favorit"): which ones, and in what order.
/// Until the user edits them, every tool is a favorite.
class FavoritesViewModel extends ChangeNotifier {
  FavoritesViewModel(this._repo, [List<String>? initial])
      : _ids = _sanitize(initial);

  final FavoritesRepository _repo;
  List<String> _ids;

  static List<String> get defaultIds =>
      [for (final t in ToolCatalog.all) t.id];

  /// Drops unknown and duplicate ids; null means "use the defaults".
  static List<String> _sanitize(List<String>? ids) {
    if (ids == null) return defaultIds;
    final seen = <String>{};
    return [
      for (final id in ids)
        if (ToolCatalog.byId(id) != null && seen.add(id)) id,
    ];
  }

  static Future<FavoritesViewModel> load(FavoritesRepository repo) async {
    try {
      return FavoritesViewModel(repo, await repo.load());
    } catch (_) {
      return FavoritesViewModel(repo);
    }
  }

  List<ToolInfo> get favorites =>
      [for (final id in _ids) ToolCatalog.byId(id)!];

  List<ToolInfo> get others => [
        for (final t in ToolCatalog.all)
          if (!_ids.contains(t.id)) t,
      ];

  bool isFavorite(String id) => _ids.contains(id);

  Future<void> toggle(String id) {
    if (ToolCatalog.byId(id) == null) return Future.value();
    isFavorite(id) ? _ids.remove(id) : _ids.add(id);
    return _commit();
  }

  /// [newIndex] is the final position (ReorderableListView.onReorderItem).
  Future<void> reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _ids.length) return Future.value();
    newIndex = newIndex.clamp(0, _ids.length - 1);
    _ids.insert(newIndex, _ids.removeAt(oldIndex));
    return _commit();
  }

  Future<void> reset() {
    _ids = defaultIds;
    return _commit();
  }

  Future<void> _commit() async {
    notifyListeners();
    try {
      await _repo.save(_ids);
    } catch (_) {
      // Best-effort persistence; the in-memory order still applies.
    }
  }
}
