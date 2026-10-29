import 'package:decimal/decimal.dart';
import 'package:sqflite/sqflite.dart';

import '../domain/numeric.dart';
import 'models.dart';

abstract class HistoryRepository {
  /// Retention policy: only the most recent [maxEntries] entries are kept.
  static const int maxEntries = 200;

  Future<void> add(HistoryEntry entry);
  Future<List<HistoryEntry>> all({HistoryType? type});
  Future<void> delete(String id);
  Future<void> clear();
  Future<int> count();

  /// Sum of recorded savings for entries created at or after [since].
  Future<Decimal> savingsSince(DateTime since);
}

class SqliteHistoryRepository implements HistoryRepository {
  SqliteHistoryRepository(this._db);
  final Database _db;

  static const _table = 'calculation_history';

  @override
  Future<void> add(HistoryEntry entry) async {
    await _db.transaction((txn) async {
      await txn.insert(_table, entry.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.rawDelete('''
        DELETE FROM $_table WHERE id NOT IN (
          SELECT id FROM $_table ORDER BY created_at DESC LIMIT ?
        )''', [HistoryRepository.maxEntries]);
    });
  }

  @override
  Future<List<HistoryEntry>> all({HistoryType? type}) async {
    final rows = await _db.query(
      _table,
      where: type == null ? null : 'calculation_type = ?',
      whereArgs: type == null ? null : [type.name],
      orderBy: 'created_at DESC',
    );
    return rows.map(HistoryEntry.fromRow).toList();
  }

  @override
  Future<void> delete(String id) async {
    await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clear() async {
    await _db.delete(_table);
  }

  @override
  Future<int> count() async {
    final result = await _db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    return (result.first['c'] as int?) ?? 0;
  }

  @override
  Future<Decimal> savingsSince(DateTime since) async {
    final rows = await _db.query(
      _table,
      columns: ['savings'],
      where: 'savings IS NOT NULL AND created_at >= ?',
      whereArgs: [since.millisecondsSinceEpoch],
    );
    var total = decZero;
    for (final row in rows) {
      total += tryDec(row['savings'] as String?) ?? decZero;
    }
    return total;
  }
}
