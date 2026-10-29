import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulatorserbaguna/core/number_format.dart';
import 'package:kalkulatorserbaguna/data/models.dart';
import 'package:kalkulatorserbaguna/domain/percentage_calculator.dart';
import 'package:kalkulatorserbaguna/features/percentage/percentage_screen.dart';
import 'package:kalkulatorserbaguna/features/percentage/percentage_view_model.dart';

import 'b_harness.dart';

void main() {
  const f = AppNumberFormat();

  group('PercentageViewModel', () {
    test('percent of value', () {
      final vm = PercentageViewModel()
        ..setFirst(d('15'))
        ..setSecond(d('200000'));
      expect(vm.result!.value, d('30000'));
      expect(vm.formatResult(f), '30.000');
    });

    test('result is a percentage for whatPercent and change', () {
      final vm = PercentageViewModel()
        ..setMode(PercentageMode.whatPercent)
        ..setFirst(d('25'))
        ..setSecond(d('200'));
      expect(vm.formatResult(f), '12,5%');
      vm
        ..setMode(PercentageMode.change)
        ..setFirst(d('80'))
        ..setSecond(d('100'));
      expect(vm.formatResult(f), '25%');
    });

    test('labels depend on the mode', () {
      final vm = PercentageViewModel();
      expect(vm.labels.first, 'Persen (%)');
      vm.setMode(PercentageMode.increase);
      expect(vm.labels.second, 'Naik (%)');
    });

    test('zero denominator reports an error only when both fields are filled',
        () {
      final vm = PercentageViewModel()
        ..setMode(PercentageMode.whatPercent)
        ..setFirst(d('5'));
      expect(vm.error, isNull);
      expect(vm.result, isNull);
      vm.setSecond(d('0'));
      expect(vm.error, 'Nilai pembanding tidak boleh nol');
      expect(vm.result, isNull);
    });

    test('history entry round-trips', () {
      final vm = PercentageViewModel()
        ..setMode(PercentageMode.decrease)
        ..setFirst(d('200000'))
        ..setSecond(d('10'));
      final entry = vm.toHistoryEntry(f)!;
      expect(entry.type, HistoryType.percentage);
      expect(entry.result, '180.000');
      final back = PercentageViewModel(restore: entry);
      expect(back.mode, PercentageMode.decrease);
      expect(back.result!.value, d('180000'));
    });
  });

  group('PercentageScreen', () {
    testWidgets('calculates and saves to history', (tester) async {
      useTallScreen(tester);
      final h = Harness();
      await tester.pumpWidget(h.wrap(const PercentageScreen()));
      await tester.enterText(find.byType(TextField).at(0), '15');
      await tester.enterText(find.byType(TextField).at(1), '200000');
      await tester.pump();
      expect(find.byKey(const Key('percentage_result')), findsOneWidget);
      expect(find.text('30.000'), findsOneWidget);

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(h.historyRepo.items.single.type, HistoryType.percentage);

      await tester.tap(find.text('Salin'));
      await tester.pump();
      expect(h.share.copied.single, '30.000');
    });

    testWidgets('switching mode changes labels; zero denominator shows error',
        (tester) async {
      useTallScreen(tester);
      final h = Harness();
      await tester.pumpWidget(h.wrap(const PercentageScreen()));
      await tester.tap(find.text(PercentageMode.whatPercent.label));
      await tester.pump();
      expect(find.text('Bagian'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), '5');
      await tester.enterText(find.byType(TextField).at(1), '0');
      await tester.pump();
      expect(find.text('Nilai pembanding tidak boleh nol'), findsOneWidget);
      expect(find.byKey(const Key('percentage_result')), findsNothing);
    });

    testWidgets('empty state asks for input', (tester) async {
      useTallScreen(tester);
      final h = Harness();
      await tester.pumpWidget(h.wrap(const PercentageScreen()));
      expect(find.textContaining('Isi kedua kolom'), findsOneWidget);
    });
  });
}
