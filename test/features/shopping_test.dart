import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulatorserbaguna/data/app_database.dart';
import 'package:kalkulatorserbaguna/data/history_repository.dart';
import 'package:kalkulatorserbaguna/data/models.dart';
import 'package:kalkulatorserbaguna/data/settings_repository.dart';
import 'package:kalkulatorserbaguna/data/shopping_repository.dart';
import 'package:kalkulatorserbaguna/features/history/history_view_model.dart';
import 'package:kalkulatorserbaguna/features/settings/settings_view_model.dart';
import 'package:kalkulatorserbaguna/features/shopping/shopping_screen.dart';
import 'package:kalkulatorserbaguna/features/shopping/shopping_view_model.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Decimal d(String s) => Decimal.parse(s);

void main() {
  sqfliteFfiInit();

  late Database db;
  late SqliteShoppingRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = await AppDatabase.open(
        factory: databaseFactoryFfi, path: inMemoryDatabasePath);
    repo = SqliteShoppingRepository(db);
  });
  tearDown(() => db.close());

  group('ShoppingViewModel', () {
    test('creates a default list when none exists and remembers it', () async {
      final vm = ShoppingViewModel(repo);
      await vm.init();
      expect(vm.current!.name, ShoppingViewModel.defaultListName);
      expect((await repo.lists()).length, 1);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(ShoppingViewModel.lastListKey), vm.current!.id);
    });

    test('opens a requested list instead of the default', () async {
      final other = ShoppingList(name: 'Bulanan');
      await repo.saveList(other);
      final vm = ShoppingViewModel(repo);
      await vm.init(listId: other.id);
      expect(vm.current!.name, 'Bulanan');
    });

    test('totals: budget 150.000 minus 128.500 leaves 21.500', () async {
      final vm = ShoppingViewModel(repo);
      await vm.init();
      await vm.setBudget(d('150000'));
      expect(
          await vm.addItem(
              name: 'Beras', unitPrice: d('64250'), quantity: d('2')),
          isNull);
      expect(vm.totals.estimatedTotal, d('128500'));
      expect(vm.totals.remainingBudget, d('21500'));
      expect(vm.totals.purchasedTotal, d('0'));
    });

    test('purchased vs estimated, reset, quantity and delete', () async {
      final vm = ShoppingViewModel(repo);
      await vm.init();
      await vm.addItem(name: 'A', unitPrice: d('1000'), quantity: d('1'));
      await vm.addItem(name: 'B', unitPrice: d('2000'), quantity: d('1'));
      await vm.togglePurchased(vm.items.first);
      expect(vm.totals.purchasedTotal, d('1000'));
      expect(vm.totals.estimatedTotal, d('3000'));
      await vm.setQuantity(vm.items.last, d('3'));
      expect(vm.totals.estimatedTotal, d('7000'));
      await vm.resetPurchased();
      expect(vm.totals.purchasedCount, 0);
      await vm.deleteItem(vm.items.first);
      expect(vm.items.length, 1);
    });

    test('invalid items return an error and are not stored', () async {
      final vm = ShoppingViewModel(repo);
      await vm.init();
      final error =
          await vm.addItem(name: '', unitPrice: d('1'), quantity: d('1'));
      expect(error, isNotNull);
      expect(vm.items, isEmpty);
    });

    test('budget can be cleared', () async {
      final vm = ShoppingViewModel(repo);
      await vm.init();
      await vm.setBudget(d('500'));
      expect(vm.totals.hasBudget, isTrue);
      await vm.setBudget(null);
      expect(vm.totals.hasBudget, isFalse);
    });
  });

  group('ShoppingScreen', () {
    Future<void> settle(WidgetTester tester) async {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 150)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<void> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final settings = SettingsViewModel(
          PrefsSettingsRepository(await SharedPreferences.getInstance()));
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsViewModel>.value(value: settings),
          ChangeNotifierProvider<HistoryViewModel>.value(
              value: HistoryViewModel(SqliteHistoryRepository(db))),
          Provider<ShoppingRepository>.value(value: repo),
        ],
        child: const MaterialApp(home: ShoppingScreen()),
      ));
      await settle(tester);
    }

    testWidgets('shows the empty state for a new list', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Belanja Mingguan'), findsOneWidget);
      expect(find.text('Belum ada barang'), findsOneWidget);
      expect(find.text('Belum ada anggaran'), findsOneWidget);
    });

    testWidgets('adds an item through the form and shows totals',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('Tambah Barang Belanja'));
      await tester.pumpAndSettle();

      // Submitting empty shows inline validation errors.
      await tester.tap(find.text('Tambahkan'));
      await tester.pumpAndSettle();
      expect(find.text('Nama barang wajib diisi'), findsOneWidget);
      expect(find.text('Harga harus berupa angka 0 atau lebih'), findsOneWidget);

      await tester.enterText(
          find.widgetWithText(TextField, 'Nama barang'), 'Minyak Goreng');
      await tester.enterText(
          find.widgetWithText(TextField, 'Harga satuan'), '34000');
      await tester.enterText(find.widgetWithText(TextField, 'Jumlah'), '2');
      await tester.tap(find.text('Tambahkan'));
      await tester.pumpAndSettle();
      await settle(tester);

      expect(find.text('Minyak Goreng'), findsOneWidget);
      expect(find.text('@Rp 34.000'), findsOneWidget);
      expect(
          tester.widget<Text>(find.byKey(const Key('estimated-total'))).data,
          'Rp 68.000');
      expect(tester.widget<Text>(find.byKey(const Key('purchased-total'))).data,
          'Rp 0');
    });

    testWidgets('toggling purchased updates the cart total', (tester) async {
      await tester.runAsync(() async {
        final list = ShoppingList(name: 'Uji', budget: d('150000'));
        await repo.saveList(list);
        await repo.saveItem(ShoppingItem(
            listId: list.id,
            name: 'Beras',
            unitPrice: d('64250'),
            quantity: d('2')));
        SharedPreferences.setMockInitialValues(
            {ShoppingViewModel.lastListKey: list.id});
      });
      await pumpScreen(tester);

      expect(tester.widget<Text>(find.byKey(const Key('remaining-budget'))).data,
          'Rp 21.500 (Aman)');
      expect(tester.widget<Text>(find.byKey(const Key('estimated-total'))).data,
          'Rp 128.500');

      await tester.tap(find.byType(Checkbox));
      await settle(tester);
      expect(tester.widget<Text>(find.byKey(const Key('purchased-total'))).data,
          'Rp 128.500');
      expect(find.textContaining('1 dari 1 selesai', findRichText: true),
          findsOneWidget);
    });

    testWidgets('over budget shows the exceeded state', (tester) async {
      await tester.runAsync(() async {
        final list = ShoppingList(name: 'Uji', budget: d('100000'));
        await repo.saveList(list);
        await repo.saveItem(ShoppingItem(
            listId: list.id,
            name: 'TV',
            unitPrice: d('150000'),
            quantity: d('1')));
        SharedPreferences.setMockInitialValues(
            {ShoppingViewModel.lastListKey: list.id});
      });
      await pumpScreen(tester);
      expect(find.text('Melebihi'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('remaining-budget'))).data,
          'Rp 50.000');
    });

    testWidgets('deleting an item asks for confirmation', (tester) async {
      await tester.runAsync(() async {
        final list = ShoppingList(name: 'Uji');
        await repo.saveList(list);
        await repo.saveItem(ShoppingItem(
            listId: list.id,
            name: 'Telur',
            unitPrice: d('30000'),
            quantity: d('1')));
        SharedPreferences.setMockInitialValues(
            {ShoppingViewModel.lastListKey: list.id});
      });
      await pumpScreen(tester);

      await tester.tap(find.text('Telur'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus Barang'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus barang?'), findsOneWidget);

      // Cancelling keeps the item.
      await tester.tap(find.text('Batal'));
      await settle(tester);
      expect(find.text('Telur'), findsOneWidget);

      await tester.tap(find.text('Telur'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus Barang'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await settle(tester);
      expect(find.text('Telur'), findsNothing);
      expect(find.text('Belum ada barang'), findsOneWidget);
    });
  });
}
