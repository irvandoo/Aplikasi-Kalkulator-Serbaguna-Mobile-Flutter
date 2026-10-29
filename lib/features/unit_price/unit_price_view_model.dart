import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../core/number_format.dart';
import '../../data/models.dart';
import '../../domain/numeric.dart';
import '../../domain/outcome.dart';
import '../../domain/unit_price_calculator.dart';

/// One product row. [id] keeps widget state attached when rows are reordered.
class UnitProduct {
  const UnitProduct({
    required this.id,
    this.price,
    this.quantity,
    required this.unit,
  });

  final int id;
  final Decimal? price;
  final Decimal? quantity;
  final MeasureUnit unit;

  UnitProduct copyWith({
    Decimal? price,
    bool clearPrice = false,
    Decimal? quantity,
    bool clearQuantity = false,
    MeasureUnit? unit,
  }) =>
      UnitProduct(
        id: id,
        price: clearPrice ? null : (price ?? this.price),
        quantity: clearQuantity ? null : (quantity ?? this.quantity),
        unit: unit ?? this.unit,
      );

  ProductInput get input =>
      ProductInput(price: price, quantity: quantity, unit: unit);

  bool get isEmpty => price == null && quantity == null;
}

class UnitPriceViewModel extends ChangeNotifier {
  UnitPriceViewModel({
    HistoryEntry? restore,
    this._calculator = const UnitPriceCalculator(),
  }) {
    if (restore != null && restore.type == HistoryType.unitPrice) {
      _restore(restore.inputData);
    }
    if (_products.isEmpty) _resetProducts();
    _recalculate();
  }

  static const int minProducts = 2;
  static const int maxProducts = 5;

  final UnitPriceCalculator _calculator;
  UnitDimension _dimension = UnitDimension.weight;
  final List<UnitProduct> _products = [];
  int _nextId = 0;
  Outcome<UnitPriceComparison>? _comparison;

  UnitDimension get dimension => _dimension;
  List<UnitProduct> get products => List.unmodifiable(_products);
  bool get canAdd => _products.length < maxProducts;
  bool get canRemove => _products.length > minProducts;
  UnitPriceComparison? get comparison => _comparison?.valueOrNull;

  /// Why a comparison is not available (null while the user has not typed
  /// enough yet, or when all is well).
  String? get comparisonError {
    final filled = _products.where((p) => !p.isEmpty).length;
    if (filled < 2) return null;
    return _comparison?.errorOrNull;
  }

  /// Validation message for product [i], shown only after the user typed in it.
  String? validationFor(int i) {
    final p = _products[i];
    if (p.isEmpty) return null;
    return _calculator.validate(p.input);
  }

  /// Price per base unit for product [i], or null when invalid.
  Decimal? unitPriceFor(int i) =>
      _calculator.unitPrice(_products[i].input).valueOrNull;

  ProductComparison? comparisonFor(int i) {
    final c = comparison;
    if (c == null) return null;
    for (final item in c.items) {
      if (item.index == i) return item;
    }
    return null;
  }

  /// Width of the relative-cost bar for product [i], 0–1.
  double barFraction(int i) {
    final c = comparison;
    final item = comparisonFor(i);
    if (c == null || item == null) return 0;
    var max = decZero;
    for (final e in c.items) {
      if (e.unitPrice > max) max = e.unitPrice;
    }
    if (max == decZero) return 1;
    return divide(item.unitPrice, max).toDouble().clamp(0.0, 1.0);
  }

  /// Largest saving of the cheapest option over any other, in percent.
  Decimal? get maxSavingPercent {
    final c = comparison;
    if (c == null || c.isTie) return null;
    var max = decZero;
    for (final e in c.items) {
      if (e.percentDifference > max) max = e.percentDifference;
    }
    return max;
  }

  /// Nominal difference per base unit between cheapest and most expensive.
  Decimal? get maxNominalDifference {
    final c = comparison;
    if (c == null || c.isTie) return null;
    var max = decZero;
    for (final e in c.items) {
      if (e.nominalDifference > max) max = e.nominalDifference;
    }
    return max;
  }

  void setDimension(UnitDimension d) {
    if (d == _dimension) return;
    _dimension = d;
    for (var i = 0; i < _products.length; i++) {
      _products[i] = _products[i].copyWith(unit: MeasureUnit.defaultFor(d));
    }
    _recalculate();
  }

  void setPrice(int i, Decimal? v) => _update(i,
      (p) => v == null ? p.copyWith(clearPrice: true) : p.copyWith(price: v));

  void setQuantity(int i, Decimal? v) => _update(
      i,
      (p) => v == null
          ? p.copyWith(clearQuantity: true)
          : p.copyWith(quantity: v));

  void setUnit(int i, MeasureUnit u) {
    if (u.dimension != _dimension) return;
    _update(i, (p) => p.copyWith(unit: u));
  }

  void _update(int i, UnitProduct Function(UnitProduct) change) {
    if (i < 0 || i >= _products.length) return;
    _products[i] = change(_products[i]);
    _recalculate();
  }

  void addProduct() {
    if (!canAdd) return;
    _products.add(_blank());
    _recalculate();
  }

  void removeProduct(int i) {
    if (!canRemove || i < 0 || i >= _products.length) return;
    _products.removeAt(i);
    _recalculate();
  }

  /// Swaps the first two options (Pilihan A and B).
  void swapAB() {
    if (_products.length < 2) return;
    final a = _products[0];
    _products[0] = _products[1];
    _products[1] = a;
    _recalculate();
  }

  void reset() {
    _resetProducts();
    _recalculate();
  }

  UnitProduct _blank() =>
      UnitProduct(id: _nextId++, unit: MeasureUnit.defaultFor(_dimension));

  void _resetProducts() {
    _products
      ..clear()
      ..addAll([_blank(), _blank()]);
  }

  void _recalculate() {
    _comparison = _calculator.compare(_products.map((p) => p.input).toList());
    notifyListeners();
  }

  void _restore(Map<String, dynamic> data) {
    final dim = UnitDimension.values.firstWhere(
      (d) => d.name == data['dimension'],
      orElse: () => UnitDimension.weight,
    );
    _dimension = dim;
    final list = data['products'];
    if (list is! List) return;
    for (final raw in list.take(maxProducts)) {
      if (raw is! Map) continue;
      final unit = MeasureUnit.values.firstWhere(
        (u) => u.name == raw['unit'] && u.dimension == dim,
        orElse: () => MeasureUnit.defaultFor(dim),
      );
      _products.add(UnitProduct(
        id: _nextId++,
        price: tryDec(raw['price'] as String?),
        quantity: tryDec(raw['quantity'] as String?),
        unit: unit,
      ));
    }
    while (_products.length < minProducts) {
      _products.add(_blank());
    }
  }

  static String optionName(int i) => 'Pilihan ${String.fromCharCode(65 + i)}';

  /// History entry, or null while no valid comparison exists.
  HistoryEntry? toHistoryEntry(AppNumberFormat f) {
    final c = comparison;
    if (c == null) return null;
    final best = c.cheapestIndex;
    final unit = _dimension.baseName;
    final parts = <String>[];
    for (var i = 0; i < _products.length; i++) {
      final p = _products[i];
      if (validationFor(i) != null || p.isEmpty) continue;
      parts.add('${optionName(i)}: ${f.rupiah(p.price!)} / '
          '${f.number(p.quantity!)} ${p.unit.symbol}');
    }
    final bestPrice = comparisonFor(best)!.unitPrice;
    final resultText = c.isTie
        ? 'Harga satuan sama (${f.rupiahDecimal(bestPrice)}/$unit)'
        : '${optionName(best)} paling hemat '
            '(${f.rupiahDecimal(bestPrice)}/$unit)';
    return HistoryEntry(
      type: HistoryType.unitPrice,
      title: parts.join(' vs '),
      result: resultText,
      inputData: {
        'dimension': _dimension.name,
        'products': [
          for (final p in _products)
            {
              'price': p.price?.toString(),
              'quantity': p.quantity?.toString(),
              'unit': p.unit.name,
            },
        ],
      },
    );
  }

  String detailText(AppNumberFormat f) {
    final e = toHistoryEntry(f);
    if (e == null) return '';
    return 'Perbandingan Harga Satuan\n${e.title}\n${e.result}';
  }
}
