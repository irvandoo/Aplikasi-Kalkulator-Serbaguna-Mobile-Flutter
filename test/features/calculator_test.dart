import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulatorserbaguna/core/number_format.dart';
import 'package:kalkulatorserbaguna/data/models.dart';
import 'package:kalkulatorserbaguna/features/calculator/calculator_screen.dart';
import 'package:kalkulatorserbaguna/features/calculator/calculator_view_model.dart';
import 'package:kalkulatorserbaguna/features/history/history_view_model.dart';

import 'calc_history_helpers.dart';

void main() {
  group('CalculatorViewModel', () {
    late CalculatorViewModel vm;
    setUp(() => vm = CalculatorViewModel());

    void type(String s) {
      for (final c in s.split('')) {
        switch (c) {
          case '.':
            vm.inputDecimal();
          case '+' || '−' || '×' || '÷':
            vm.inputOperator(c);
          default:
            vm.inputDigit(c);
        }
      }
    }

    test('typing and = evaluates with precedence and exposes a commit', () {
      type('2+3×4');
      expect(vm.mainLine, '14'); // live preview
      final c = vm.equals();
      expect(c!.result, Decimal.parse('14'));
      expect(vm.expression, '14');
      expect(vm.topLine, '2+3×4');
    });

    test('display uses Indonesian grouping', () {
      type('12500×4+75000');
      expect(vm.topLine, '12.500×4+75.000');
      expect(vm.mainLine, '125.000');
    });

    test('division by zero shows a safe message and records nothing', () {
      type('5÷0');
      expect(vm.equals(), isNull);
      expect(vm.error, 'Tidak bisa dibagi nol');
      expect(vm.mainLine, 'Tidak bisa dibagi nol');
      vm.backspace();
      expect(vm.error, isNull);
    });

    test('operators: replace, no leading operator, leading minus', () {
      vm.inputOperator('+');
      expect(vm.expression, '');
      vm.inputOperator('−');
      expect(vm.expression, '−');
      type('5');
      vm.inputOperator('+');
      vm.inputOperator('×');
      expect(vm.expression, '−5×');
    });

    test('decimals: only one per number, leading zero added', () {
      vm.inputDecimal();
      expect(vm.expression, '0.');
      type('5.5');
      expect(vm.expression, '0.55');
      vm.inputOperator('+');
      type('1.2.3');
      expect(vm.expression, '0.55+1.23');
    });

    test('leading zeros collapse and digits are capped at 18', () {
      type('007');
      expect(vm.expression, '7');
      vm.clear();
      type('1' * 25);
      expect(vm.expression.length, CalculatorViewModel.maxDigitsPerNumber);
    });

    test('percent rule: 200+10% = 220', () {
      type('200+10');
      vm.percent();
      expect(vm.equals()!.result, Decimal.parse('220'));
    });

    test('toggle sign flips trailing number', () {
      type('5');
      vm.toggleSign();
      expect(vm.expression, '−5');
      vm.toggleSign();
      expect(vm.expression, '5');
      vm.inputOperator('+');
      type('3');
      vm.toggleSign();
      expect(vm.expression, '5+−3');
      expect(vm.value, Decimal.parse('2'));
    });

    test('parentheses auto-close and implicit multiplication', () {
      type('2');
      vm.openParen();
      type('3+4');
      expect(vm.equals()!.result, Decimal.parse('14'));
    });

    test('closeParen ignored without open paren', () {
      type('5');
      vm.closeParen();
      expect(vm.expression, '5');
    });

    test('sqrt, square, pi', () {
      vm.squareRoot();
      type('9');
      expect(vm.equals()!.result, Decimal.parse('3'));
      vm.clear();
      type('5');
      vm.square();
      expect(vm.value, Decimal.parse('25'));
      vm.clear();
      vm.inputPi();
      expect(vm.value, Decimal.parse('3.14159265358979'));
    });

    test('after =, a digit starts fresh and an operator continues', () {
      type('2+2');
      vm.equals();
      vm.inputOperator('×');
      type('3');
      expect(vm.equals()!.result, Decimal.parse('12'));
      type('7');
      expect(vm.expression, '7');
    });

    test('backspace and clear', () {
      type('123');
      vm.backspace();
      expect(vm.expression, '12');
      vm.clear();
      expect(vm.expression, '');
      expect(vm.mainLine, '0');
    });

    test('memory add, subtract, recall, clear', () {
      type('5');
      vm.memoryAdd();
      expect(vm.hasMemory, isTrue);
      vm.clear();
      type('2');
      vm.memorySubtract();
      expect(vm.memoryValue, Decimal.parse('3'));
      vm.clear();
      vm.memoryRecall();
      expect(vm.expression, '3');
      vm.memoryClear();
      expect(vm.hasMemory, isFalse);
    });

    test('load sanitises restored expressions', () {
      expect(vm.load('12×3'), isTrue);
      expect(vm.expression, '12×3');
      expect(vm.load('abc'), isFalse);
      expect(vm.load(null), isFalse);
      expect(vm.expression, '12×3');
    });

    test('international number style changes display only', () {
      vm.format = const AppNumberFormat(style: NumberStyle.international);
      type('1234.5');
      expect(vm.mainLine, '1,234.5');
      expect(vm.expression, '1234.5');
    });

    test('entryFor stores everything needed to reconstruct', () {
      type('1500×2');
      final e = vm.entryFor(vm.equals()!);
      expect(e.type, HistoryType.calculator);
      expect(e.inputData['expression'], '1500×2');
      expect(e.result, '3.000');
      expect(e.title, '1.500×2');
    });
  });

  group('CalculatorScreen', () {
    late MemoryHistoryRepo repo;
    late HistoryViewModel history;
    late FakeShareService share;

    setUp(() {
      repo = MemoryHistoryRepo();
      history = HistoryViewModel(repo);
      share = FakeShareService();
    });

    Future<void> pump(WidgetTester t, {HistoryEntry? restore}) async {
      await t.binding.setSurfaceSize(const Size(400, 1000));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(harness(
          child: CalculatorScreen(restore: restore),
          history: history,
          share: share));
      await t.pumpAndSettle();
    }

    Future<void> tapKeys(WidgetTester t, List<String> labels) async {
      for (final l in labels) {
        await t.tap(find.bySemanticsLabel(l).first);
        await t.pump();
      }
    }

    String main(WidgetTester t) =>
        t.widget<Text>(find.byKey(const Key('calc-main-line'))).data!;

    testWidgets('keypad input, = and history recording', (t) async {
      await pump(t);
      await tapKeys(t, ['1', '2', 'Kali', '3']);
      expect(main(t), '36');
      await t.tap(find.bySemanticsLabel('Hitung'));
      await t.pumpAndSettle();
      expect(repo.items.length, 1);
      expect(repo.items.first.result, '36');
      expect(repo.items.first.inputData['expression'], '12×3');
      expect(find.text('Pita Hitung Terakhir'), findsOneWidget);
      expect(find.text('1 Catatan'), findsOneWidget);
    });

    testWidgets('division by zero shows message, no crash', (t) async {
      await pump(t);
      await tapKeys(t, ['5', 'Bagi', '0', 'Hitung']);
      expect(main(t), 'Tidak bisa dibagi nol');
      expect(repo.items, isEmpty);
    });

    testWidgets('copy and share use the share service', (t) async {
      await pump(t);
      await tapKeys(t, ['9', 'Tambah', '1']);
      await t.tap(find.text('Salin'));
      await t.pump();
      expect(share.copied, ['10']);
      await t.tap(find.text('Bagikan'));
      await t.pump();
      expect(share.shared.single, contains('= 10'));
      await t.tap(find.text('Simpan'));
      await t.pumpAndSettle();
      expect(repo.items.length, 1);
    });

    testWidgets('copy with nothing to copy shows a message', (t) async {
      await pump(t);
      await t.tap(find.text('Salin'));
      await t.pump();
      expect(share.copied, isEmpty);
      expect(find.text('Belum ada hasil untuk disalin'), findsOneWidget);
    });

    testWidgets('restore preloads the expression', (t) async {
      final entry = HistoryEntry(
          type: HistoryType.calculator,
          title: '250×2',
          result: '500',
          inputData: {'expression': '250×2'});
      await pump(t, restore: entry);
      expect(main(t), '500');
    });

    testWidgets('Pita toggle hides history rows; tap reuses an entry',
        (t) async {
      await repo.add(HistoryEntry(
          type: HistoryType.calculator,
          title: '2+2',
          result: '4',
          inputData: {'expression': '2+2'}));
      await history.load();
      await pump(t);
      expect(find.text('Bersihkan Riwayat'), findsOneWidget);
      await t.tap(find.text('2+2'));
      await t.pump();
      expect(main(t), '4');
      await t.tap(find.text('Pita'));
      await t.pump();
      expect(find.text('Bersihkan Riwayat'), findsNothing);
    });

    testWidgets('clear history asks for confirmation', (t) async {
      await repo.add(HistoryEntry(
          type: HistoryType.calculator,
          title: '2+2',
          result: '4',
          inputData: {'expression': '2+2'}));
      await history.load();
      await pump(t);
      await t.tap(find.text('Bersihkan Riwayat'));
      await t.pumpAndSettle();
      await t.tap(find.text('Batal'));
      await t.pumpAndSettle();
      expect(repo.items.length, 1);
      await t.tap(find.text('Bersihkan Riwayat'));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(FilledButton, 'Bersihkan'));
      await t.pumpAndSettle();
      expect(repo.items, isEmpty);
    });

    testWidgets('Lihat Rekap Lengkap navigates to history', (t) async {
      await pump(t);
      await t.ensureVisible(find.text('Lihat Rekap Lengkap'));
      await t.tap(find.text('Lihat Rekap Lengkap'));
      await t.pumpAndSettle();
      expect(find.text('RIWAYAT-PAGE'), findsOneWidget);
    });
  });
}
