import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulatorserbaguna/core/number_format.dart';
import 'package:kalkulatorserbaguna/data/models.dart';
import 'package:kalkulatorserbaguna/domain/outcome.dart';
import 'package:kalkulatorserbaguna/features/discount/discount_compare_screen.dart';
import 'package:kalkulatorserbaguna/features/discount/discount_screen.dart';
import 'package:kalkulatorserbaguna/features/discount/discount_view_model.dart';

import 'b_harness.dart';

void main() {
  const f = AppNumberFormat();

  group('DiscountViewModel', () {
    test('no result until a price is entered', () {
      final vm = DiscountViewModel();
      expect(vm.outcome, isNull);
      expect(vm.error, isNull);
    });

    test('250.000 with 30% + 10% = Rp 157.500, savings Rp 92.500', () {
      final vm = DiscountViewModel()
        ..setPrice(d('250000'))
        ..setStage(0, d('30'))
        ..setExtraEnabled(true)
        ..setStage(1, d('10'));
      expect(vm.result!.finalPrice, d('157500'));
      expect(vm.result!.savings, d('92500'));
      expect(f.rupiah(vm.result!.finalPrice), 'Rp 157.500');
    });

    test('second stage is ignored while the toggle is off', () {
      final vm = DiscountViewModel()
        ..setPrice(d('200000'))
        ..setStage(0, d('20'))
        ..setExtraEnabled(true)
        ..setStage(1, d('10'));
      expect(vm.result!.finalPrice, d('144000'));
      vm.setExtraEnabled(false);
      expect(vm.result!.finalPrice, d('160000'));
    });

    test('extra stages can be added up to the limit and removed', () {
      final vm = DiscountViewModel()..setExtraEnabled(true);
      while (vm.canAddStage) {
        vm.addStage();
      }
      expect(vm.stages.length, DiscountViewModel.maxStages);
      vm.removeStage(2);
      expect(vm.stages.length, DiscountViewModel.maxStages - 1);
    });

    test('PPN and fee apply after discounts', () {
      final vm = DiscountViewModel()
        ..setPrice(d('200000'))
        ..setStage(0, d('20'))
        ..setTaxEnabled(true)
        ..setFee(d('5000'));
      // 160.000 + 17.600 PPN + 5.000
      expect(vm.result!.finalPrice, d('182600'));
    });

    test('invalid discount surfaces an error, no crash', () {
      final vm = DiscountViewModel()
        ..setPrice(d('1000'))
        ..setStage(0, d('150'));
      expect(vm.result, isNull);
      expect(vm.error, isNotNull);
    });

    test('history entry carries savings and can be restored', () {
      final vm = DiscountViewModel()
        ..setPrice(d('250000'))
        ..setStage(0, d('30'))
        ..setExtraEnabled(true)
        ..setStage(1, d('10'))
        ..setTaxEnabled(true);
      final entry = vm.toHistoryEntry(f)!;
      expect(entry.type, HistoryType.discount);
      expect(entry.savings, d('92500'));
      final restored = DiscountViewModel(restore: entry);
      expect(restored.price, d('250000'));
      expect(restored.extraEnabled, isTrue);
      expect(restored.taxEnabled, isTrue);
      expect(restored.result!.finalPrice, vm.result!.finalPrice);
    });

    test('detail text lists steps', () {
      final vm = DiscountViewModel()
        ..setPrice(d('200000'))
        ..setStage(0, d('20'));
      expect(vm.detailText(f), contains('Harga akhir: Rp 160.000'));
    });
  });

  group('DiscountCompareViewModel', () {
    test('cheapest offer by final price is flagged with differences', () {
      final vm = DiscountCompareViewModel();
      vm.update(0, (o) => o.copyWith(price: d('100000'), first: d('30')));
      expect(vm.comparable, isFalse);
      vm.update(1,
          (o) => o.copyWith(price: d('100000'), first: d('20'), second: d('15')));
      expect(vm.comparable, isTrue);
      expect(vm.evaluations[0].isCheapest, isFalse);
      expect(vm.evaluations[1].isCheapest, isTrue);
      expect(vm.evaluations[1].result!.finalPrice, d('68000'));
      expect(vm.evaluations[0].nominalDifference, d('2000'));
      expect(vm.evaluations[1].nominalDifference, d('0'));
    });

    test('invalid offers are excluded, offers can be added and removed', () {
      final vm = DiscountCompareViewModel();
      vm.update(0, (o) => o.copyWith(price: d('1000'), first: d('500')));
      expect(vm.evaluations[0].outcome, isA<Err>());
      vm.add();
      expect(vm.offers.length, 3);
      vm.remove(2);
      vm.remove(1);
      expect(vm.offers.length, DiscountCompareViewModel.minOffers);
    });
  });

  group('DiscountScreen', () {
    testWidgets('shows Rp 157.500 for 250.000 with 30% + 10%', (tester) async {
      useTallScreen(tester);
      final h = Harness();
      await tester.pumpWidget(h.wrap(const DiscountScreen()));

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), '250000');
      await tester.enterText(fields.at(1), '30');
      await tester.tap(find.byType(Switch).first);
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(2), '10');
      await tester.pump();

      expect(find.byKey(const Key('discount_final_price')), findsOneWidget);
      expect(find.text('Rp 157.500'), findsOneWidget);
      expect(find.text('-Rp 92.500'), findsOneWidget);
    });

    testWidgets('quick chips fill the price and discount', (tester) async {
      useTallScreen(tester);
      final h = Harness();
      await tester.pumpWidget(h.wrap(const DiscountScreen()));
      await tester.tap(find.text('Rp250rb'));
      await tester.pump();
      await tester.tap(find.text('30%').first);
      await tester.pump();
      expect(find.text('250.000'), findsOneWidget);
      expect(find.text('Rp 175.000'), findsOneWidget);
    });

    testWidgets('save records history, copy uses the share service',
        (tester) async {
      useTallScreen(tester);
      final h = Harness();
      await tester.pumpWidget(h.wrap(const DiscountScreen()));
      await tester.enterText(find.byType(TextField).at(0), '200000');
      await tester.enterText(find.byType(TextField).at(1), '20');
      await tester.pump();

      await tester.tap(find.text('Salin Rincian'));
      await tester.pump();
      expect(h.share.copied.single, contains('Rp 160.000'));

      await tester.tap(find.text('Simpan Catatan'));
      await tester.pumpAndSettle();
      expect(h.historyRepo.items.length, 1);
      expect(h.historyRepo.items.single.type, HistoryType.discount);
      expect(h.historyRepo.items.single.savings, d('40000'));
    });

    testWidgets('shows an empty state and a validation error', (tester) async {
      useTallScreen(tester);
      final h = Harness();
      await tester.pumpWidget(h.wrap(const DiscountScreen()));
      expect(find.textContaining('Masukkan harga asli'), findsOneWidget);
      await tester.enterText(find.byType(TextField).at(0), '1000');
      await tester.enterText(find.byType(TextField).at(1), '150');
      await tester.pump();
      expect(find.text('Diskon harus antara 0% dan 100%'), findsOneWidget);
    });

    testWidgets('reopens a saved entry with its inputs', (tester) async {
      useTallScreen(tester);
      final h = Harness();
      final entry = (DiscountViewModel()
            ..setPrice(d('200000'))
            ..setStage(0, d('20'))
            ..setExtraEnabled(true)
            ..setStage(1, d('10')))
          .toHistoryEntry(f)!;
      await tester.pumpWidget(h.wrap(DiscountScreen(restore: entry)));
      expect(find.text('Rp 144.000'), findsOneWidget);
    });
  });

  group('DiscountCompareScreen', () {
    testWidgets('highlights the cheapest offer', (tester) async {
      useTallScreen(tester);
      final h = Harness();
      await tester.pumpWidget(h.wrap(const DiscountCompareScreen()));
      final fields = find.byType(TextField);
      // Offer A: price, disc1, disc2, fee; Offer B: same order.
      await tester.enterText(fields.at(0), '100000');
      await tester.enterText(fields.at(1), '30');
      await tester.enterText(fields.at(4), '100000');
      await tester.enterText(fields.at(5), '20');
      await tester.enterText(fields.at(6), '15');
      await tester.pump();
      expect(find.text('Paling Hemat'), findsOneWidget);
      expect(find.text('Penawaran B paling hemat!'), findsOneWidget);
      expect(find.text('Rp 68.000'), findsWidgets);
    });

    testWidgets('asks for more input when only one offer is valid',
        (tester) async {
      useTallScreen(tester);
      final h = Harness();
      await tester.pumpWidget(h.wrap(const DiscountCompareScreen()));
      expect(find.textContaining('minimal dua penawaran'), findsOneWidget);
    });
  });
}
