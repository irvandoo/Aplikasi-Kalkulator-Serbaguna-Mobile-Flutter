import 'package:sqflite/sqflite.dart';

import 'models.dart';

abstract class ShoppingRepository {
  /// All lists, newest-updated first, each with its items.
  Future<List<ShoppingList>> lists();
  Future<ShoppingList?> byId(String id);
  Future<void> saveList(ShoppingList list);
  Future<void> deleteList(String id);
  Future<void> saveItem(ShoppingItem item);
  Future<void> deleteItem(String id);
  Future<void> resetPurchased(String listId);
}

class SqliteShoppingRepository implements ShoppingRepository {
  SqliteShoppingRepository(this._db);
  final Database _db;

  Future<List<ShoppingItem>> _items(String listId) async {
    final rows = await _db.query(
      'shopping_items',
      where: 'shopping_list_id = ?',
      whereArgs: [listId],
      orderBy: 'created_at ASC, id ASC',
    );
    return rows.map(ShoppingItem.fromRow).whereType<ShoppingItem>().toList();
  }

  @override
  Future<List<ShoppingList>> lists() async {
    final rows = await _db.query('shopping_lists', orderBy: 'updated_at DESC');
    final result = <ShoppingList>[];
    for (final row in rows) {
      result.add(ShoppingList.fromRow(row,
          items: await _items(row['id'] as String)));
    }
    return result;
  }

  @override
  Future<ShoppingList?> byId(String id) async {
    final rows =
        await _db.query('shopping_lists', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ShoppingList.fromRow(rows.first, items: await _items(id));
  }

  @override
  Future<void> saveList(ShoppingList list) async {
    final error = ShoppingList.validate(name: list.name, budget: list.budget);
    if (error != null) throw ValidationException(error);
    await _db.insert('shopping_lists', list.toRow(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<void> deleteList(String id) async {
    // Items are removed by ON DELETE CASCADE.
    await _db.delete('shopping_lists', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> saveItem(ShoppingItem item) async {
    final error = ShoppingItem.validate(
      name: item.name,
      unitPrice: item.unitPrice,
      quantity: item.quantity,
      discountPercent: item.discountPercent,
    );
    if (error != null) throw ValidationException(error);
    await _db.transaction((txn) async {
      await txn.insert('shopping_items', item.toRow(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await _touch(txn, item.listId);
    });
  }

  @override
  Future<void> deleteItem(String id) async {
    await _db.transaction((txn) async {
      final rows = await txn.query('shopping_items',
          columns: ['shopping_list_id'], where: 'id = ?', whereArgs: [id]);
      await txn.delete('shopping_items', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        await _touch(txn, rows.first['shopping_list_id'] as String);
      }
    });
  }

  @override
  Future<void> resetPurchased(String listId) async {
    await _db.transaction((txn) async {
      await txn.update('shopping_items', {'is_purchased': 0},
          where: 'shopping_list_id = ?', whereArgs: [listId]);
      await _touch(txn, listId);
    });
  }

  Future<void> _touch(DatabaseExecutor db, String listId) => db.update(
        'shopping_lists',
        {'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [listId],
      );
}
