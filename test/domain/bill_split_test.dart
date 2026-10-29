import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalkulatorserbaguna/domain/bill_split_calculator.dart';

Decimal d(String s) => Decimal.parse(s);

void main() {
  const calc = BillSplitCalculator();

  BillSplitResult ok({
    String bill = '300000',
    int people = 3,
    String? tax,
    String? tip,
    SplitRounding rounding = SplitRounding.none,
  }) =>
      calc
          .calculate(
            bill: d(bill),
            people: people,
            taxPercent: tax == null ? null : d(tax),
            tipPercent: tip == null ? null : d(tip),
            rounding: rounding,
          )
          .valueOrNull!;

  test('even split without extras', () {
    final r = ok();
    expect(r.total, d('300000'));
    expect(r.perPerson, d('100000'));
    expect(r.surplus, d('0'));
  });

  test('tax 11% and tip 10% are both taken from the pre-tax bill', () {
    final r = ok(bill: '200000', people: 2, tax: '11', tip: '10');
    expect(r.tax, d('22000'));
    expect(r.tip, d('20000'));
    expect(r.total, d('242000'));
    expect(r.perPerson, d('121000'));
  });

  test('non-divisible total rounds each share up to whole rupiah', () {
    final r = ok(bill: '100000', people: 3);
    expect(r.perPerson, d('33334'));
    expect(r.collected, d('100002'));
    expect(r.surplus, d('2'));
    expect(r.collected >= r.total, isTrue);
  });

  test('rounding steps always round up and never collect less', () {
    for (final step in SplitRounding.values) {
      final r = ok(bill: '123457', people: 4, tax: '11', rounding: step);
      expect(r.collected >= r.total, isTrue, reason: step.name);
      expect(
          (r.perPerson % Decimal.fromInt(step.step)).toBigInt(), BigInt.zero,
          reason: step.name);
      expect(r.surplus >= Decimal.zero, isTrue);
    }
    expect(ok(bill: '100000', people: 3, rounding: SplitRounding.thousand)
        .perPerson, d('34000'));
  });

  test('one person pays the whole total', () {
    expect(ok(bill: '50000', people: 1, tip: '5').perPerson, d('52500'));
  });

  test('validation', () {
    String? err({Decimal? bill, int people = 2, String? tax, String? tip}) =>
        calc
            .calculate(
              bill: bill,
              people: people,
              taxPercent: tax == null ? null : d(tax),
              tipPercent: tip == null ? null : d(tip),
            )
            .errorOrNull;
    expect(err(bill: null), isNotNull);
    expect(err(bill: d('0')), isNotNull);
    expect(err(bill: d('-5')), isNotNull);
    expect(err(bill: d('100'), people: 0), isNotNull);
    expect(err(bill: d('100'), people: 101), isNotNull);
    expect(err(bill: d('100'), tax: '101'), isNotNull);
    expect(err(bill: d('100'), tip: '-1'), isNotNull);
    expect(err(bill: d('100')), isNull);
  });
}
