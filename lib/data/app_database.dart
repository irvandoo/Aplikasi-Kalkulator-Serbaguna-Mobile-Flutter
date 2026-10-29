import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens the local SQLite database and owns schema creation and migrations.
///
/// Schema history:
///  * v1 – calculation_history, shopping_lists, shopping_items.
///
/// To change the schema: bump [version], add the SQL to [_migrations] under
/// the new version number (applied in order for upgrades), and update
/// [_createSchema] so fresh installs reach the same shape.
class AppDatabase {
  AppDatabase._();

  static const int version = 1;
  static const String fileName = 'kalkulator_serbaguna.db';

  static const Map<int, List<String>> _migrations = {
    // 2: ['ALTER TABLE shopping_items ADD COLUMN note TEXT'],
  };

  static Future<Database> open({DatabaseFactory? factory, String? path}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), fileName);
    return f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, v) => _createSchema(db),
        onUpgrade: _upgrade,
      ),
    );
  }

  static Future<void> _createSchema(Database db) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE calculation_history (
        id TEXT PRIMARY KEY,
        calculation_type TEXT NOT NULL,
        title TEXT NOT NULL,
        input_data TEXT NOT NULL,
        result TEXT NOT NULL,
        savings TEXT,
        created_at INTEGER NOT NULL
      )''');
    batch.execute(
        'CREATE INDEX idx_history_created ON calculation_history(created_at DESC)');
    batch.execute('''
      CREATE TABLE shopping_lists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        budget TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''');
    batch.execute('''
      CREATE TABLE shopping_items (
        id TEXT PRIMARY KEY,
        shopping_list_id TEXT NOT NULL
          REFERENCES shopping_lists(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        unit_price TEXT NOT NULL,
        quantity TEXT NOT NULL,
        discount_percent TEXT,
        is_purchased INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )''');
    batch.execute(
        'CREATE INDEX idx_items_list ON shopping_items(shopping_list_id, created_at)');
    await batch.commit(noResult: true);
  }

  static Future<void> _upgrade(Database db, int from, int to) async {
    for (var v = from + 1; v <= to; v++) {
      final statements = _migrations[v];
      if (statements == null) continue;
      for (final sql in statements) {
        await db.execute(sql);
      }
    }
  }
}
