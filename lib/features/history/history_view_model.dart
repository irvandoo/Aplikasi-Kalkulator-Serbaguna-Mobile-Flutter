import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../data/history_repository.dart';
import '../../data/models.dart';
import '../../domain/numeric.dart';

/// App-wide history state. Every tool records its calculations through
/// [record]; Home reads [count] and [savingsThisWeek].
class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel(this._repo);

  final HistoryRepository _repo;

  List<HistoryEntry> _entries = const [];
  Decimal _savingsThisWeek = decZero;
  bool _loading = true;
  String? _error;
  HistoryType? _filter;

  List<HistoryEntry> get entries => _entries;
  int get count => _entries.length;
  Decimal get savingsThisWeek => _savingsThisWeek;
  bool get loading => _loading;
  String? get error => _error;
  HistoryType? get filter => _filter;
  HistoryEntry? get latest => _entries.isEmpty ? null : _entries.first;

  List<HistoryEntry> get visible => _filter == null
      ? _entries
      : _entries.where((e) => e.type == _filter).toList();

  Future<void> load() async {
    try {
      _entries = await _repo.all();
      _savingsThisWeek = await _repo
          .savingsSince(DateTime.now().subtract(const Duration(days: 7)));
      _error = null;
    } catch (e, st) {
      debugPrint('History load failed: $e\n$st');
      _error = 'Riwayat tidak dapat dimuat';
    }
    _loading = false;
    notifyListeners();
  }

  void setFilter(HistoryType? type) {
    _filter = type;
    notifyListeners();
  }

  /// Saves a calculation. Failures are swallowed (returns false) so that a
  /// storage problem never blocks a calculation.
  Future<bool> record(HistoryEntry entry) async {
    try {
      await _repo.add(entry);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repo.delete(id);
    } catch (_) {}
    await load();
  }

  Future<void> clear() async {
    try {
      await _repo.clear();
    } catch (_) {}
    await load();
  }
}
