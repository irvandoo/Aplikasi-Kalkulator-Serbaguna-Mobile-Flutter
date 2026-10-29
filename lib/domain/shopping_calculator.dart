import 'package:decimal/decimal.dart';

import 'numeric.dart';

class ShoppingItemData {
  const ShoppingItemData({
    required this.unitPrice,
    required this.quantity,
    this.discountPercent,
    this.isPurchased = false,
  });

  final Decimal unitPrice;
  final Decimal quantity;

  /// Optional item-level discount in percent (0–100).
  final Decimal? discountPercent;
  final bool isPurchased;

  /// Gross line amount before the item discount, rounded to whole Rupiah.
  Decimal get grossTotal => roundRupiah(unitPrice * quantity);

  /// Line total after item discount, rounded to whole Rupiah. This is the
  /// single rule used everywhere a line total is needed.
  Decimal get lineTotal {
    final percent = discountPercent ?? decZero;
    final net = unitPrice *
        quantity *
        (decOne - divide(percent, decHundred));
    return roundRupiah(net);
  }

  Decimal get discountAmount => grossTotal - lineTotal;
}

class ShoppingTotals {
  const ShoppingTotals({
    required this.estimatedTotal,
    required this.purchasedTotal,
    required this.discountSavings,
    required this.itemCount,
    required this.purchasedCount,
    required this.budget,
  });

  /// Sum of every item's line total (planned spending).
  final Decimal estimatedTotal;

  /// Sum of line totals for items marked as purchased.
  final Decimal purchasedTotal;
  final Decimal discountSavings;
  final int itemCount;
  final int purchasedCount;

  /// Zero means "no budget set".
  final Decimal budget;

  bool get hasBudget => budget > decZero;

  /// budget − estimatedTotal. Negative means the list exceeds the budget.
  Decimal get remainingBudget => budget - estimatedTotal;

  /// budget − purchasedTotal.
  Decimal get remainingAfterPurchased => budget - purchasedTotal;

  bool get isOverBudget => hasBudget && remainingBudget < decZero;

  /// Fraction of the budget used by the estimated total (0–∞), as percent.
  Decimal get usedPercent =>
      hasBudget ? divide(estimatedTotal * decHundred, budget) : decZero;
}

class ShoppingCalculator {
  const ShoppingCalculator();

  ShoppingTotals totals(List<ShoppingItemData> items, {Decimal? budget}) {
    var estimated = decZero;
    var purchased = decZero;
    var savings = decZero;
    var purchasedCount = 0;
    for (final item in items) {
      final line = item.lineTotal;
      estimated += line;
      savings += item.discountAmount;
      if (item.isPurchased) {
        purchased += line;
        purchasedCount++;
      }
    }
    return ShoppingTotals(
      estimatedTotal: estimated,
      purchasedTotal: purchased,
      discountSavings: savings,
      itemCount: items.length,
      purchasedCount: purchasedCount,
      budget: budget ?? decZero,
    );
  }
}
