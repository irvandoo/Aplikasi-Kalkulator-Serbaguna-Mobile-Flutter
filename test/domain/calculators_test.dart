import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulatorserbaguna/core/number_format.dart';
import 'package:kalkulatorserbaguna/domain/discount_calculator.dart';
import 'package:kalkulatorserbaguna/domain/expression_evaluator.dart';
import 'package:kalkulatorserbaguna/domain/numeric.dart';
import 'package:kalkulatorserbaguna/domain/outcome.dart';
import 'package:kalkulatorserbaguna/domain/percentage_calculator.dart';
import 'package:kalkulatorserbaguna/domain/shopping_calculator.dart';
import 'package:kalkulatorserbaguna/domain/unit_price_calculator.dart';

Decimal d(String s) => Decimal.parse(s);

void main() {
  group('numeric helpers', () {
    test('roundRupiah rounds half away from zero', () {
      expect(roundRupiah(d('2.5')), d('3'));
      expect(roundRupiah(d('-2.5')), d('-3'));
      expect(roundRupiah(d('2.49')), d('2'));
    });
    test('divide keeps exact results exact', () {
      expect(divide(d('1'), d('4')), d('0.25'));
      expect(divide(d('1'), d('3')).toString().length, greaterThan(10));
    });
  });

  group('ExpressionEvaluator', () {
    const e = ExpressionEvaluator();
    String? ok(String s) => e.evaluate(s).valueOrNull?.toString();

    test('basic arithmetic and precedence', () {
      expect(ok('2+3×4'), '14');
      expect(ok('(2+3)×4'), '20');
      expect(ok('10−4−3'), '3');
      expect(ok('100÷4÷5'), '5');
    });
    test('decimal arithmetic is exact', () {
      expect(ok('0.1+0.2'), '0.3');
      expect(ok('1.1×1.1'), '1.21');
    });
    test('negative numbers', () {
      expect(ok('−5+3'), '-2');
      expect(ok('2×−3'), '-6');
      expect(ok('−2²'), '-4');
    });
    test('percent after additive operator is relative to left operand', () {
      expect(ok('200+10%'), '220');
      expect(ok('200−15%'), '170');
      expect(ok('50%'), '0.5');
      expect(ok('200×10%'), '20');
    });
    test('parentheses, implicit multiplication, unclosed parentheses', () {
      expect(ok('2(3+4)'), '14');
      expect(ok('(2+3'), '5');
    });
    test('sqrt, square and pi', () {
      expect(ok('√9'), '3');
      expect(ok('√16+1'), '5');
      expect(ok('5²'), '25');
      expect(ok('π'), '3.14159265358979');
      expect(ok('√2'), '1.414213562373');
    });
    test('division by zero is a safe error', () {
      final r = e.evaluate('5÷0');
      expect(r, isA<Err<Decimal>>());
      expect(r.errorOrNull, ExpressionEvaluator.divideByZeroMessage);
      expect(e.evaluate('1÷(2−2)'), isA<Err<Decimal>>());
    });
    test('invalid expressions produce errors, never throw', () {
      for (final s in ['', '+', '2+', '×3', '()', '2..3', 'abc', '2+*3', ')(']) {
        expect(() => e.evaluate(s), returnsNormally, reason: s);
        expect(e.evaluate(s), isA<Err<Decimal>>(), reason: s);
      }
    });
    test('negative square root is an error', () {
      expect(e.evaluate('√(0−4)'), isA<Err<Decimal>>());
    });
    test('extreme values are rejected rather than overflowing', () {
      final r = e.evaluate('999999999999999999²²²');
      expect(r.errorOrNull, ExpressionEvaluator.overflowMessage);
    });
    test('deep nesting does not crash', () {
      final s = '${'(' * 500}1${')' * 500}';
      expect(() => e.evaluate(s), returnsNormally);
    });
    test('zero edge cases', () {
      expect(ok('0×5'), '0');
      expect(ok('0÷5'), '0');
    });
  });

  group('PercentageCalculator', () {
    const c = PercentageCalculator();
    Decimal? v(PercentageMode m, String a, String b) =>
        c.calculate(m, d(a), d(b)).valueOrNull?.value;

    test('percent of value', () {
      expect(v(PercentageMode.percentOf, '15', '200000'), d('30000'));
    });
    test('what percent', () {
      expect(v(PercentageMode.whatPercent, '25', '200'), d('12.5'));
    });
    test('increase and decrease', () {
      expect(v(PercentageMode.increase, '200000', '10'), d('220000'));
      expect(v(PercentageMode.decrease, '200000', '10'), d('180000'));
    });
    test('difference is absolute', () {
      expect(v(PercentageMode.difference, '30', '50'), d('20'));
      expect(v(PercentageMode.difference, '50', '30'), d('20'));
    });
    test('change between two values', () {
      expect(v(PercentageMode.change, '80', '100'), d('25'));
      expect(v(PercentageMode.change, '100', '80'), d('-20'));
      expect(v(PercentageMode.change, '-100', '-50'), d('50'));
    });
    test('zero denominators and missing input are safe', () {
      expect(c.calculate(PercentageMode.whatPercent, d('5'), d('0')),
          isA<Err<PercentageResult>>());
      expect(c.calculate(PercentageMode.change, d('0'), d('5')),
          isA<Err<PercentageResult>>());
      expect(c.calculate(PercentageMode.percentOf, null, d('5')),
          isA<Err<PercentageResult>>());
    });
    test('zero values', () {
      expect(v(PercentageMode.percentOf, '0', '500'), d('0'));
    });
  });

  group('DiscountCalculator', () {
    const c = DiscountCalculator();

    test('sequential 20% + 10% on Rp200.000 = Rp144.000, savings Rp56.000', () {
      final r = c
          .calculate(
            originalPrice: d('200000'),
            discountPercents: [d('20'), d('10')],
          )
          .valueOrNull!;
      expect(r.discountedPrice, d('144000'));
      expect(r.finalPrice, d('144000'));
      expect(r.savings, d('56000'));
      expect(r.savingsPercent, d('28'));
      expect(r.steps[0].remaining, d('160000'));
      expect(r.steps[1].amount, d('16000'));
    });
    test('mockup example 250.000 with 30% + 10% = 157.500', () {
      final r = c
          .calculate(
            originalPrice: d('250000'),
            discountPercents: [d('30'), d('10')],
          )
          .valueOrNull!;
      expect(r.finalPrice, d('157500'));
      expect(r.savings, d('92500'));
    });
    test('tax is applied after discounts, fee added last and untaxed', () {
      final r = c
          .calculate(
            originalPrice: d('200000'),
            discountPercents: [d('20'), d('10')],
            taxPercent: d('11'),
            additionalFee: d('5000'),
          )
          .valueOrNull!;
      expect(r.taxAmount, d('15840'));
      expect(r.finalPrice, d('164840'));
      expect(r.savings, d('56000'));
    });
    test('no discounts, zero price, 100% discount', () {
      expect(
          c
              .calculate(originalPrice: d('1000'), discountPercents: [])
              .valueOrNull!
              .finalPrice,
          d('1000'));
      final zero = c
          .calculate(originalPrice: d('0'), discountPercents: [d('50')])
          .valueOrNull!;
      expect(zero.finalPrice, d('0'));
      expect(zero.savingsPercent, d('0'));
      final free = c
          .calculate(originalPrice: d('1000'), discountPercents: [d('100')])
          .valueOrNull!;
      expect(free.finalPrice, d('0'));
    });
    test('fractional results are rounded once, at the end', () {
      final r = c
          .calculate(
              originalPrice: d('99999'), discountPercents: [d('33.3'), d('7')])
          .valueOrNull!;
      // 99999 × 0.667 × 0.93 = 62030.0...
      expect(r.discountedPrice, roundRupiah(d('99999') * d('0.667') * d('0.93')));
    });
    test('invalid input is rejected', () {
      expect(c.calculate(originalPrice: null, discountPercents: []),
          isA<Err<DiscountResult>>());
      expect(c.calculate(originalPrice: d('-1'), discountPercents: []),
          isA<Err<DiscountResult>>());
      expect(c.calculate(originalPrice: d('1'), discountPercents: [d('101')]),
          isA<Err<DiscountResult>>());
      expect(c.calculate(originalPrice: d('1'), discountPercents: [d('-5')]),
          isA<Err<DiscountResult>>());
    });
    test('cheapestIndex compares final prices', () {
      final a = c
          .calculate(originalPrice: d('100000'), discountPercents: [d('30')])
          .valueOrNull!;
      final b = c
          .calculate(
              originalPrice: d('100000'), discountPercents: [d('20'), d('15')])
          .valueOrNull!;
      expect(c.cheapestIndex([a, b]), 1); // 68.000 < 70.000
      expect(c.cheapestIndex([]), isNull);
    });
  });

  group('ShoppingCalculator', () {
    const c = ShoppingCalculator();
    ShoppingItemData item(String price, String qty,
            {String? disc, bool bought = false}) =>
        ShoppingItemData(
          unitPrice: d(price),
          quantity: d(qty),
          discountPercent: disc == null ? null : d(disc),
          isPurchased: bought,
        );

    test('budget Rp150.000 minus total Rp128.500 leaves Rp21.500', () {
      final t = c.totals([
        item('64250', '2'),
      ], budget: d('150000'));
      expect(t.estimatedTotal, d('128500'));
      expect(t.remainingBudget, d('21500'));
      expect(t.isOverBudget, isFalse);
    });
    test('estimated vs purchased totals (mockup numbers)', () {
      final t = c.totals([
        item('34000', '2', bought: true),
        item('72000', '1', bought: true),
        item('48000', '1'),
        item('30000', '1'),
      ], budget: d('300000'));
      expect(t.estimatedTotal, d('218000'));
      expect(t.purchasedTotal, d('140000'));
      expect(t.remainingBudget, d('82000'));
      expect(t.remainingAfterPurchased, d('160000'));
      expect(t.purchasedCount, 2);
      expect(t.itemCount, 4);
    });
    test('item discounts and fractional quantity', () {
      final t = c.totals([
        item('30000', '0.5'),
        item('10000', '3', disc: '10'),
      ]);
      expect(t.estimatedTotal, d('42000'));
      expect(t.discountSavings, d('3000'));
    });
    test('over budget, no budget, empty list', () {
      final over = c.totals([item('100', '5')], budget: d('400'));
      expect(over.isOverBudget, isTrue);
      expect(over.remainingBudget, d('-100'));
      final none = c.totals([item('100', '5')]);
      expect(none.hasBudget, isFalse);
      expect(none.isOverBudget, isFalse);
      final empty = c.totals([], budget: d('1000'));
      expect(empty.estimatedTotal, d('0'));
      expect(empty.remainingBudget, d('1000'));
    });
    test('line total rounding is consistent', () {
      final i = item('3333', '0.5');
      expect(i.lineTotal, d('1667')); // 1666.5 → 1667
    });
  });

  group('UnitPriceCalculator', () {
    const c = UnitPriceCalculator();
    ProductInput p(String price, String qty, MeasureUnit u) =>
        ProductInput(price: d(price), quantity: d(qty), unit: u);

    test('500 g at Rp12.000 is Rp24/g; 800 g at Rp17.000 is Rp21,25/g', () {
      expect(c.unitPrice(p('12000', '500', MeasureUnit.g)).valueOrNull,
          d('24'));
      expect(c.unitPrice(p('17000', '800', MeasureUnit.g)).valueOrNull,
          d('21.25'));
    });
    test('800 g package is identified as cheaper per gram', () {
      final r = c
          .compare([
            p('12000', '500', MeasureUnit.g),
            p('17000', '800', MeasureUnit.g),
          ])
          .valueOrNull!;
      expect(r.cheapestIndex, 1);
      expect(r.items[1].isCheapest, isTrue);
      expect(r.items[0].nominalDifference, d('2.75'));
      expect(r.items[0].percentDifference.round(scale: 2), d('11.46'));
    });
    test('units are normalised (kg vs g, l vs ml, mg)', () {
      final r = c
          .compare([
            p('20000', '1', MeasureUnit.kg),
            p('12000', '500', MeasureUnit.g),
          ])
          .valueOrNull!;
      expect(r.items[0].unitPrice, d('20'));
      expect(r.cheapestIndex, 0);
      expect(c.unitPrice(p('1000', '2', MeasureUnit.l)).valueOrNull, d('0.5'));
      expect(c.unitPrice(p('1', '1000', MeasureUnit.mg)).valueOrNull, d('1'));
    });
    test('three or more products', () {
      final r = c
          .compare([
            p('10000', '100', MeasureUnit.ml),
            p('25000', '300', MeasureUnit.ml),
            p('50000', '1', MeasureUnit.l),
          ])
          .valueOrNull!;
      expect(r.items.length, 3);
      expect(r.cheapestIndex, 2);
    });
    test('incompatible dimensions are rejected', () {
      final r = c.compare([
        p('1000', '100', MeasureUnit.g),
        p('1000', '100', MeasureUnit.ml),
      ]);
      expect(r, isA<Err<UnitPriceComparison>>());
    });
    test('zero, negative and missing quantities are invalid', () {
      expect(c.validate(p('1000', '0', MeasureUnit.g)), isNotNull);
      expect(c.validate(p('1000', '-5', MeasureUnit.g)), isNotNull);
      expect(c.validate(p('-1', '5', MeasureUnit.g)), isNotNull);
      expect(
          c.validate(const ProductInput(
              price: null, quantity: null, unit: MeasureUnit.g)),
          isNotNull);
      expect(
          c.compare([
            p('1000', '0', MeasureUnit.g),
            p('1000', '5', MeasureUnit.g),
          ]),
          isA<Err<UnitPriceComparison>>());
    });
    test('equal unit prices are a tie', () {
      final r = c
          .compare([p('1000', '100', MeasureUnit.g), p('2000', '200', MeasureUnit.g)])
          .valueOrNull!;
      expect(r.isTie, isTrue);
    });
    test('zero price is valid and cheapest', () {
      final r = c
          .compare([p('0', '100', MeasureUnit.g), p('2000', '200', MeasureUnit.g)])
          .valueOrNull!;
      expect(r.cheapestIndex, 0);
    });
  });

  group('AppNumberFormat', () {
    const id = AppNumberFormat();
    const en = AppNumberFormat(style: NumberStyle.international);

    test('rupiah formatting', () {
      expect(id.rupiah(d('250000')), 'Rp 250.000');
      expect(id.rupiah(d('-1500')), '-Rp 1.500');
      expect(id.rupiah(d('0')), 'Rp 0');
      expect(en.rupiah(d('1234567')), 'Rp 1,234,567');
    });
    test('decimals follow the style and setting', () {
      expect(id.number(d('1234.5')), '1.234,5');
      expect(en.number(d('1234.5')), '1,234.5');
      expect(id.rupiahDecimal(d('27.5')), 'Rp 27,50');
      expect(const AppNumberFormat(decimalPlaces: 0).number(d('2.5')), '3');
      expect(id.number(d('-0.001')), '0');
    });
    test('parse round-trips', () {
      expect(id.parse('1.234,5'), d('1234.5'));
      expect(en.parse('1,234.5'), d('1234.5'));
      expect(id.parse('abc'), isNull);
      expect(id.parse(''), isNull);
      expect(id.parse('-5'), d('-5'));
    });
    test('expression display', () {
      expect(id.expression('12500×4+75000.5'), '12.500×4+75.000,5');
      expect(id.expression('.5'), '0,5');
    });
  });
}
