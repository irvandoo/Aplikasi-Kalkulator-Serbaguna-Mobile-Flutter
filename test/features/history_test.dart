import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kalkulatorserbaguna/data/history_repository.dart';
import 'package:kalkulatorserbaguna/data/app_database.dart';
import 'package:kalkulatorserbaguna/data/models.dart';
import 'package:kalkulatorserbaguna/features/history/history_screen.dart';
import 'package:kalkulatorserbaguna/features/history/history_view_model.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'calc_history_helpers.dart';

class FailingRepo extends MemoryHistoryRepo {
  @override
  Future<List<HistoryEntry>> all({HistoryType? type}) async =>
      throw Exception('db');
}

HistoryEntry entry(String title, HistoryType type,
        {String result = 'Rp 1', DateTime? at, Decimal? savings}) =>
    HistoryEntry(
      type: type,
      title: title,
      result: result,
      inputData: {'expression': title},
      createdAt: at,
      savings: savings,
    );

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    await initializeDateFormatting('id_ID');
  });

  group('HistoryViewModel with sqlite', () {
    late Database db;
    late HistoryViewModel vm;

    setUp(() async {
      db = await AppDatabase.open(
          factory: databaseFactoryFfi, path: inMemoryDatabasePath);
      vm = HistoryViewModel(SqliteHistoryRepository(db));
    });
    tearDown(() => db.close());

    test('record, filter, delete and clear', () async {
      await vm.load();
      expect(vm.loading, isFalse);
      expect(await vm.record(entry('a', HistoryType.calculator)), isTrue);
      await vm.record(entry('b', HistoryType.discount, savings: Decimal.parse('500')));
      expect(vm.count, 2);
      expect(vm.savingsThisWeek, Decimal.parse('500'));
      vm.setFilter(HistoryType.discount);
      expect(vm.visible.map((e) => e.title), ['b']);
      vm.setFilter(null);
      await vm.delete(vm.entries.first.id);
      expect(vm.count, 1);
      await vm.clear();
      expect(vm.count, 0);
    });
  });

  test('record never throws when storage fails', () async {
    final vm = HistoryViewModel(FailingRepo());
    expect(await vm.record(entry('a', HistoryType.calculator)), isTrue);
    expect(vm.error, isNotNull);
  });

  group('HistoryScreen', () {
    late MemoryHistoryRepo repo;
    late HistoryViewModel history;
    late FakeShareService share;

    setUp(() {
      repo = MemoryHistoryRepo();
      history = HistoryViewModel(repo);
      share = FakeShareService();
    });

    Future<void> pump(WidgetTester t, {HistoryViewModel? vm}) async {
      await t.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(harness(
          child: const HistoryScreen(), history: vm ?? history, share: share));
      await t.pumpAndSettle();
    }

    testWidgets('empty state', (t) async {
      await history.load();
      await pump(t);
      expect(find.textContaining('Belum ada riwayat'), findsOneWidget);
    });

    testWidgets('error state offers retry', (t) async {
      final vm = HistoryViewModel(FailingRepo());
      await vm.load();
      await pump(t, vm: vm);
      expect(find.text('Riwayat tidak dapat dimuat'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });

    testWidgets('lists entries with timestamp and filters by type', (t) async {
      await repo.add(entry('2+2', HistoryType.calculator,
          result: '4', at: DateTime(2026, 3, 5, 14, 7)));
      await repo.add(entry('Diskon 20%', HistoryType.discount));
      await history.load();
      await pump(t);
      expect(find.text('2+2'), findsOneWidget);
      expect(find.text('Diskon 20%'), findsOneWidget);
      expect(find.textContaining(RegExp(r'5 Mar 2026, 14[.:]07')),
          findsOneWidget);
      final chip = find.widgetWithText(ChoiceChip, 'Diskon');
      await t.ensureVisible(chip);
      await t.pumpAndSettle();
      await t.tap(chip);
      await t.pumpAndSettle();
      expect(find.text('2+2'), findsNothing);
      expect(find.text('Diskon 20%'), findsOneWidget);
    });

    testWidgets('copy, share and delete a single entry', (t) async {
      await repo.add(entry('2+2', HistoryType.calculator, result: '4'));
      await history.load();
      await pump(t);
      await t.tap(find.byTooltip('Salin hasil'));
      await t.pump();
      expect(share.copied, ['4']);
      await t.tap(find.byTooltip('Bagikan'));
      await t.pump();
      expect(share.shared.single, contains('Hasil: 4'));
      await t.tap(find.byTooltip('Hapus'));
      await t.pumpAndSettle();
      expect(repo.items, isEmpty);
      expect(find.textContaining('Belum ada riwayat'), findsOneWidget);
    });

    testWidgets('clear all requires confirmation', (t) async {
      await repo.add(entry('2+2', HistoryType.calculator));
      await history.load();
      await pump(t);
      await t.tap(find.byTooltip('Hapus semua riwayat'));
      await t.pumpAndSettle();
      await t.tap(find.text('Batal'));
      await t.pumpAndSettle();
      expect(repo.items.length, 1);
      await t.tap(find.byTooltip('Hapus semua riwayat'));
      await t.pumpAndSettle();
      await t.tap(find.text('Hapus semua'));
      await t.pumpAndSettle();
      expect(repo.items, isEmpty);
    });

    testWidgets('Hitung ulang opens the tool with the entry', (t) async {
      await repo.add(entry('Promo Mall', HistoryType.discount));
      await history.load();
      await pump(t);
      await t.tap(find.byTooltip('Hitung ulang'));
      await t.pumpAndSettle();
      expect(find.text('DISKON-PAGE Promo Mall'), findsOneWidget);
    });
  });
}
