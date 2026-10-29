import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulatorserbaguna/core/number_format.dart';
import 'package:kalkulatorserbaguna/data/models.dart';
import 'package:kalkulatorserbaguna/domain/unit_price_calculator.dart';
import 'package:kalkulatorserbaguna/features/unit_price/unit_price_screen.dart';
import 'package:kalkulatorserbaguna/features/unit_price/unit_price_view_model.dart';

import 'b_harness.dart';

UnitPriceViewModel filled() => UnitPriceViewModel()
  ..setPrice(0, d('12000'))
  ..setQuantity(0, d('500'))
  ..setPrice(1, d('17000'))
  ..setQuantity(1, d('800'));

void main() {
  const f = AppNumberFormat();

  group('UnitPriceViewModel', () {
    test('starts with two empty options and no comparison', () {
      final vm = UnitPriceViewModel();
      expect(vm.products.length, 2);
      expect(vm.comparison, isNull);
      expect(vm.comparisonError, isNull);
    });

    test('500 g/12.000 vs 800 g/17.000: second is cheaper per gram', () {
      final vm = filled();
      expect(vm.unitPriceFor(0), d('24'));
      expect(vm.unitPriceFor(1), d('21.25'));
      expect(vm.comparison!.cheapestIndex, 1);
      expect(vm.comparisonFor(0)!.nominalDifference, d('2.75'));
      expect(vm.maxNominalDifference, d('2.75'));
      expect(vm.barFraction(0), 1.0);
      expect(vm.barFraction(1), closeTo(21.25 / 24, 1e-9));
    });

    test('unit dropdown normalises kg against g', () {
      final vm = filled()
        ..setUnit(1, MeasureUnit.kg)
        ..setQuantity(1, d('0.8'));
      expect(vm.unitPriceFor(1), d('21.25'));
    });

    test('changing dimension resets units and keeps numbers', () {
      final vm = filled()..setUnit(0, MeasureUnit.kg);
      vm.setDimension(UnitDimension.volume);
      expect(vm.products.every((p) => p.unit == MeasureUnit.ml), isTrue);
      expect(vm.products[0].price, d('12000'));
      vm.setUnit(0, MeasureUnit.g); // wrong dimension: ignored
      expect(vm.products[0].unit, MeasureUnit.ml);
    });

    test('zero or negative size shows validation and blocks comparison', () {
      final vm = filled()..setQuantity(0, d('0'));
      expect(vm.validationFor(0), 'Ukuran harus lebih dari nol');
      expect(vm.comparison, isNull);
      expect(vm.comparisonError, isNotNull);
      vm.setQuantity(0, d('-5'));
      expect(vm.validationFor(0), 'Ukuran harus lebih dari nol');
      expect(vm.validationFor(1), isNull);
    });

    test('an empty option shows no validation', () {
      final vm = UnitPriceViewModel();
      expect(vm.validationFor(0), isNull);
    });

    test('add up to five options, remove down to two', () {
      final vm = UnitPriceViewModel();
      while (vm.canAdd) {
        vm.addProduct();
      }
      expect(vm.products.length, UnitPriceViewModel.maxProducts);
      while (vm.canRemove) {
        vm.removeProduct(vm.products.length - 1);
      }
      expect(vm.products.length, UnitPriceViewModel.minProducts);
    });

    test('three options compare together', () {
      final vm = filled()
        ..addProduct()
        ..setPrice(2, d('9000'))
        ..setQuantity(2, d('500'));
      expect(vm.comparison!.cheapestIndex, 2);
      expect(vm.comparison!.items.length, 3);
    });

    test('swap exchanges A and B, reset clears values', () {
      final vm = filled()..swapAB();
      expect(vm.products[0].price, d('17000'));
      expect(vm.comparison!.cheapestIndex, 0);
      final oldId = vm.products[0].id;
      vm.reset();
      expect(vm.products.every((p) => p.isEmpty), isTrue);
      expect(vm.products[0].id, isNot(oldId));
    });

    test('equal unit prices are a tie with no saving', () {
      final vm = UnitPriceViewModel()
        ..setPrice(0, d('1000'))
        ..setQuantity(0, d('100'))
        ..setPrice(1, d('2000'))
        ..setQuantity(1, d('200'));
      expect(vm.comparison!.isTie, isTrue);
      expect(vm.maxSavingPercent, isNull);
    });

    test('history entry round-trips', () {
      final entry = filled().toHistoryEntry(f)!;
      expect(entry.type, HistoryType.unitPrice);
      expect(entry.result, contains('Pilihan B'));
      expect(entry.result, contains('Rp 21,25'));
      final back = UnitPriceViewModel(restore: entry);
      expect(back.comparison!.cheapestIndex, 1);
    });
  });

  group('UnitPriceScreen', () {
    Future<void> fill(WidgetTester tester) async {
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '12000');
      await tester.enterText(fields.at(1), '500');
      await tester.enterText(fields.at(2), '17000');
      await tester.enterText(fields.at(3), '800');
      await tester.pump();
    }

    testWidgets('identifies the cheaper package per gram', (tester) async {
      useTallScreen(tester);
      final h = Harness();
      await tester.pumpWidget(h.wrap(const UnitPriceScreen()));
      await fill(tester);
      expect(find.text('Rp 24,00 / gram'), findsOneWidget);
      expect(find.text('Rp 21,25 / gram'), findsOneWidget);
      expect(find.text('PALING HEMAT'), findsOneWidget);
      expect(find.text('Pilihan B Lebih Murah!'), findsOneWidget);
    });

    testWidgets('shows validation feedback for a zero size', (tester) async {
      useTallScreen(tester);
      final h = Harness();
      await tester.pumpWidget(h.wrap(const UnitPriceScreen()));
      await tester.enterText(find.byType(TextField).at(0), '12000');
      await tester.enterText(find.byType(TextField).at(1), '0');
      await tester.pump();
      expect(find.text('Ukuran harus lebih dari nol'), findsOneWidget);
      expect(find.text('PALING HEMAT'), findsNothing);
    });

    testWidgets('swap, reset, add option and dimension tabs work',
        (tester) async {
      useTallScreen(tester);
      final h = Harness();
      await tester.pumpWidget(h.wrap(const UnitPriceScreen()));
      await fill(tester);

      await tester.tap(find.text('Tukar A/B'));
      await tester.pump();
      expect(find.text('Pilihan A Lebih Murah!'), findsOneWidget);

      await tester.tap(find.text('Tambah Opsi C'));
      await tester.pump();
      expect(find.text('Pilihan C'), findsOneWidget);

      await tester.tap(find.text('Volume'));
      await tester.pump();
      expect(find.text('Rp 24,00 / ml'), findsOneWidget);

      await tester.tap(find.text('Reset Nilai'));
      await tester.pump();
      expect(find.text('Pilihan A Lebih Murah!'), findsNothing);
      expect(find.textContaining('minimal dua pilihan'), findsOneWidget);
    });

    testWidgets('saves the comparison to history', (tester) async {
      useTallScreen(tester);
      final h = Harness();
      await tester.pumpWidget(h.wrap(const UnitPriceScreen()));
      await fill(tester);
      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();
      expect(h.historyRepo.items.single.type, HistoryType.unitPrice);
    });
  });
}
