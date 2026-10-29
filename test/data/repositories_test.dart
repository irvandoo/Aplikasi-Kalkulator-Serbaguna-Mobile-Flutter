import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulatorserbaguna/core/number_format.dart';
import 'package:kalkulatorserbaguna/data/app_database.dart';
import 'package:kalkulatorserbaguna/data/history_repository.dart';
import 'package:kalkulatorserbaguna/data/models.dart';
import 'package:kalkulatorserbaguna/data/settings_repository.dart';
import 'package:kalkulatorserbaguna/data/shopping_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Decimal d(String s) => Decimal.parse(s);

void main() {
  sqfliteFfiInit();

  group('HistoryRepository', () {
    late SqliteHistoryRepository repo;
    late Database db;

    setUp(() async {
      db = await AppDatabase.open(
          factory: databaseFactoryFfi, path: inMemoryDatabasePath);
      repo = SqliteHistoryRepository(db);
    });
    tearDown(() => db.close());

    HistoryEntry entry(String title,
            {HistoryType type = HistoryType.calculator,
            Decimal? savings,
            DateTime? at}) =>
        HistoryEntry(
          type: type,
          title: title,
          result: 'r',
          inputData: {'expr': title},
          savings: savings,
          createdAt: at,
        );

    test('stores and returns newest first, with input data intact', () async {
      await repo.add(entry('a', at: DateTime(2026, 1, 1)));
      await repo.add(entry('b', at: DateTime(2026, 1, 2)));
      final all = await repo.all();
      expect(all.map((e) => e.title), ['b', 'a']);
      expect(all.first.inputData['expr'], 'b');
      expect(all.first.type, HistoryType.calculator);
    });
    test('filters by type, deletes one and clears all', () async {
      await repo.add(entry('a'));
      await repo.add(entry('b', type: HistoryType.discount));
      expect((await repo.all(type: HistoryType.discount)).length, 1);
      final id = (await repo.all()).first.id;
      await repo.delete(id);
      expect(await repo.count(), 1);
      await repo.clear();
      expect(await repo.count(), 0);
    });
    test('retention keeps only the most recent entries', () async {
      for (var i = 0; i < HistoryRepository.maxEntries + 15; i++) {
        await repo.add(entry('e$i', at: DateTime(2026, 1, 1).add(Duration(minutes: i))));
      }
      expect(await repo.count(), HistoryRepository.maxEntries);
      final newest = (await repo.all()).first;
      expect(newest.title, 'e${HistoryRepository.maxEntries + 14}');
    });
    test('sums savings since a date exactly', () async {
      final now = DateTime.now();
      await repo.add(entry('x', savings: d('56000.5'), at: now));
      await repo.add(entry('y', savings: d('0.5'), at: now));
      await repo.add(entry('old',
          savings: d('999'), at: now.subtract(const Duration(days: 30))));
      expect(await repo.savingsSince(now.subtract(const Duration(days: 7))),
          d('56001'));
    });
  });

  group('ShoppingRepository', () {
    late SqliteShoppingRepository repo;
    late Database db;

    setUp(() async {
      db = await AppDatabase.open(
          factory: databaseFactoryFfi, path: inMemoryDatabasePath);
      repo = SqliteShoppingRepository(db);
    });
    tearDown(() => db.close());

    test('creates a list with items and reads them back', () async {
      final list = ShoppingList(name: 'Mingguan', budget: d('300000'));
      await repo.saveList(list);
      await repo.saveItem(ShoppingItem(
          listId: list.id,
          name: 'Beras',
          unitPrice: d('72000.50'),
          quantity: d('1.5'),
          discountPercent: d('10')));
      final loaded = await repo.byId(list.id);
      expect(loaded!.name, 'Mingguan');
      expect(loaded.budget, d('300000'));
      expect(loaded.items.single.unitPrice, d('72000.5'));
      expect(loaded.items.single.quantity, d('1.5'));
      expect(loaded.items.single.discountPercent, d('10'));
      expect(loaded.items.single.isPurchased, isFalse);
    });
    test('edits an item and toggles purchased', () async {
      final list = ShoppingList(name: 'A');
      await repo.saveList(list);
      final item = ShoppingItem(
          listId: list.id, name: 'Telur', unitPrice: d('30000'), quantity: d('1'));
      await repo.saveItem(item);
      await repo.saveItem(item.copyWith(isPurchased: true, quantity: d('2')));
      var loaded = (await repo.byId(list.id))!;
      expect(loaded.items.length, 1);
      expect(loaded.items.single.isPurchased, isTrue);
      expect(loaded.items.single.quantity, d('2'));
      await repo.resetPurchased(list.id);
      loaded = (await repo.byId(list.id))!;
      expect(loaded.items.single.isPurchased, isFalse);
    });
    test('deleting a list cascades to its items', () async {
      final list = ShoppingList(name: 'A');
      await repo.saveList(list);
      await repo.saveItem(ShoppingItem(
          listId: list.id, name: 'x', unitPrice: d('1'), quantity: d('1')));
      await repo.deleteList(list.id);
      expect(await repo.byId(list.id), isNull);
      expect(await repo.lists(), isEmpty);
    });
    test('deleting an item removes only that item', () async {
      final list = ShoppingList(name: 'A');
      await repo.saveList(list);
      final a = ShoppingItem(
          listId: list.id, name: 'a', unitPrice: d('1'), quantity: d('1'));
      final b = ShoppingItem(
          listId: list.id, name: 'b', unitPrice: d('2'), quantity: d('1'));
      await repo.saveItem(a);
      await repo.saveItem(b);
      await repo.deleteItem(a.id);
      expect((await repo.byId(list.id))!.items.map((i) => i.name), ['b']);
    });
    test('rejects invalid data before persisting', () async {
      final list = ShoppingList(name: 'A');
      await repo.saveList(list);
      Future<void> save(String name, String price, String qty, [String? disc]) =>
          repo.saveItem(ShoppingItem(
              listId: list.id,
              name: name,
              unitPrice: d(price),
              quantity: d(qty),
              discountPercent: disc == null ? null : d(disc)));
      expect(save('', '1', '1'), throwsA(isA<ValidationException>()));
      expect(save('x', '-1', '1'), throwsA(isA<ValidationException>()));
      expect(save('x', '1', '0'), throwsA(isA<ValidationException>()));
      expect(save('x', '1', '1', '101'), throwsA(isA<ValidationException>()));
      expect(repo.saveList(ShoppingList(name: ' ')),
          throwsA(isA<ValidationException>()));
      expect((await repo.byId(list.id))!.items, isEmpty);
    });
  });

  group('persistence across restarts', () {
    test('data written to a file database survives reopening', () async {
      final dir = await Directory.systemTemp.createTemp('kalkulator_test');
      final path = '${dir.path}/test.db';
      try {
        var db = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
        final history = SqliteHistoryRepository(db);
        final shopping = SqliteShoppingRepository(db);
        await history.add(HistoryEntry(
            type: HistoryType.discount,
            title: '200.000 − 20% − 10%',
            result: 'Rp 144.000',
            inputData: {'price': '200000'}));
        final list = ShoppingList(name: 'Bulanan', budget: d('150000'));
        await shopping.saveList(list);
        await shopping.saveItem(ShoppingItem(
            listId: list.id, name: 'Beras', unitPrice: d('64250'), quantity: d('2')));
        await db.close();

        db = await AppDatabase.open(factory: databaseFactoryFfi, path: path);
        expect(await SqliteHistoryRepository(db).count(), 1);
        final loaded = (await SqliteShoppingRepository(db).lists()).single;
        expect(loaded.name, 'Bulanan');
        expect(loaded.items.single.name, 'Beras');
        await db.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });
  });

  group('PrefsSettingsRepository', () {
    test('defaults, save and reload', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = PrefsSettingsRepository(prefs);
      var s = await repo.load();
      expect(s.themeMode, ThemeMode.system);
      expect(s.numberStyle, NumberStyle.indonesia);
      expect(s.decimalPlaces, 2);
      await repo.save(const AppSettings(
          themeMode: ThemeMode.dark,
          numberStyle: NumberStyle.international,
          decimalPlaces: 4));
      s = await PrefsSettingsRepository(prefs).load();
      expect(s.themeMode, ThemeMode.dark);
      expect(s.numberStyle, NumberStyle.international);
      expect(s.decimalPlaces, 4);
    });
    test('corrupt stored values fall back to defaults', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'nonsense',
        'number_style': 'x',
        'decimal_places': 99,
      });
      final s = await PrefsSettingsRepository(
              await SharedPreferences.getInstance())
          .load();
      expect(s.themeMode, ThemeMode.system);
      expect(s.decimalPlaces, 2);
    });
  });
}
