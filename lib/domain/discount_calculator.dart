import 'package:decimal/decimal.dart';

import 'numeric.dart';
import 'outcome.dart';

class DiscountStep {
  const DiscountStep({
    required this.percent,
    required this.amount,
    required this.remaining,
  });

  final Decimal percent;

  /// Amount removed by this step (exact).
  final Decimal amount;

  /// Price left after this step (exact).
  final Decimal remaining;
}

class DiscountResult {
  const DiscountResult({
    required this.originalPrice,
    required this.steps,
    required this.discountedPrice,
    required this.taxPercent,
    required this.taxAmount,
    required this.additionalFee,
    required this.finalPrice,
    required this.savings,
    required this.savingsPercent,
  });

  final Decimal originalPrice;
  final List<DiscountStep> steps;

  /// Price after all discounts, rounded to whole Rupiah.
  final Decimal discountedPrice;
  final Decimal taxPercent;

  /// Tax on [discountedPrice], rounded to whole Rupiah.
  final Decimal taxAmount;
  final Decimal additionalFee;

  /// discountedPrice + taxAmount + additionalFee.
  final Decimal finalPrice;

  /// originalPrice − discountedPrice (discounts only; taxes/fees excluded).
  final Decimal savings;

  /// savings / originalPrice × 100 (exact; 0 when originalPrice is 0).
  final Decimal savingsPercent;
}

/// Discount rules:
///  1. Each discount applies to the price remaining after the previous one
///     (20% then 10% on 200.000 = 144.000, not 30%).
///  2. The discounted price is rounded to whole Rupiah (half away from zero).
///  3. Tax is charged on the rounded discounted price and rounded to Rupiah.
///  4. A flat additional fee is added last and is not taxed.
///  5. Savings only reflect discounts, never taxes or fees.
class DiscountCalculator {
  const DiscountCalculator();

  Outcome<DiscountResult> calculate({
    required Decimal? originalPrice,
    required List<Decimal> discountPercents,
    Decimal? taxPercent,
    Decimal? additionalFee,
  }) {
    if (originalPrice == null) return const Err('Masukkan harga asli');
    if (isNegative(originalPrice)) {
      return const Err('Harga tidak boleh negatif');
    }
    for (final p in discountPercents) {
      if (isNegative(p) || p > decHundred) {
        return const Err('Diskon harus antara 0% dan 100%');
      }
    }
    final tax = taxPercent ?? decZero;
    if (isNegative(tax)) return const Err('Pajak tidak boleh negatif');
    final fee = additionalFee ?? decZero;
    if (isNegative(fee)) return const Err('Biaya tambahan tidak boleh negatif');

    var remaining = originalPrice;
    final steps = <DiscountStep>[];
    for (final p in discountPercents) {
      final amount = divide(remaining * p, decHundred);
      remaining = remaining - amount;
      steps.add(DiscountStep(percent: p, amount: amount, remaining: remaining));
    }
    final discounted = roundRupiah(remaining);
    final taxAmount = roundRupiah(divide(discounted * tax, decHundred));
    final savings = roundRupiah(originalPrice) - discounted;
    final savingsPercent = originalPrice == decZero
        ? decZero
        : divide(savings * decHundred, roundRupiah(originalPrice));
    return Ok(DiscountResult(
      originalPrice: originalPrice,
      steps: steps,
      discountedPrice: discounted,
      taxPercent: tax,
      taxAmount: taxAmount,
      additionalFee: fee,
      finalPrice: discounted + taxAmount + fee,
      savings: savings,
      savingsPercent: savingsPercent,
    ));
  }

  /// Index of the offer with the lowest final price, or null if [results] is
  /// empty. Ties resolve to the earliest offer.
  int? cheapestIndex(List<DiscountResult> results) {
    if (results.isEmpty) return null;
    var best = 0;
    for (var i = 1; i < results.length; i++) {
      if (results[i].finalPrice < results[best].finalPrice) best = i;
    }
    return best;
  }
}
