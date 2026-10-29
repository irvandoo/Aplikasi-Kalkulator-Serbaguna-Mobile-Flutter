import 'package:decimal/decimal.dart';

import 'numeric.dart';
import 'outcome.dart';

/// Step each person's share is rounded UP to, so the group never collects
/// less than the bill.
enum SplitRounding {
  none('Pas', 1),
  hundred('100', 100),
  fiveHundred('500', 500),
  thousand('1.000', 1000);

  const SplitRounding(this.label, this.step);
  final String label;
  final int step;
}

class BillSplitResult {
  const BillSplitResult({
    required this.bill,
    required this.tax,
    required this.tip,
    required this.total,
    required this.people,
    required this.perPerson,
    required this.collected,
    required this.surplus,
  });

  final Decimal bill;
  final Decimal tax;
  final Decimal tip;

  /// bill + tax + tip, exact.
  final Decimal total;
  final int people;

  /// What each person pays (rounded up to the chosen step).
  final Decimal perPerson;

  /// perPerson × people.
  final Decimal collected;

  /// collected − total: the extra caused by rounding up (never negative).
  final Decimal surplus;
}

/// Bill splitting rules:
///  * tax   = bill × tax% / 100
///  * tip   = bill × tip% / 100        (tip is on the pre-tax bill)
///  * total = bill + tax + tip
///  * perPerson = ceil(total / people / step) × step
/// Intermediate values stay exact; only the per-person share is rounded.
class BillSplitCalculator {
  const BillSplitCalculator();

  static const int maxPeople = 100;

  Outcome<BillSplitResult> calculate({
    required Decimal? bill,
    required int people,
    Decimal? taxPercent,
    Decimal? tipPercent,
    SplitRounding rounding = SplitRounding.none,
  }) {
    if (bill == null) return const Err('Isi total tagihan');
    if (!isPositive(bill)) return const Err('Tagihan harus lebih dari 0');
    if (people < 1 || people > maxPeople) {
      return const Err('Jumlah orang harus 1 sampai $maxPeople');
    }
    final taxP = taxPercent ?? decZero;
    final tipP = tipPercent ?? decZero;
    if (isNegative(taxP) || taxP > decHundred) {
      return const Err('Pajak harus antara 0% dan 100%');
    }
    if (isNegative(tipP) || tipP > decHundred) {
      return const Err('Tip harus antara 0% dan 100%');
    }

    final tax = divide(bill * taxP, decHundred);
    final tip = divide(bill * tipP, decHundred);
    final total = bill + tax + tip;

    final peopleDec = Decimal.fromInt(people);
    final step = Decimal.fromInt(rounding.step);
    final exactShare = divide(total, peopleDec);
    final units = divide(exactShare, step).ceil(scale: 0);
    final perPerson = units * step;
    final collected = perPerson * peopleDec;

    return Ok(BillSplitResult(
      bill: bill,
      tax: tax,
      tip: tip,
      total: total,
      people: people,
      perPerson: perPerson,
      collected: collected,
      surplus: collected - total,
    ));
  }
}
