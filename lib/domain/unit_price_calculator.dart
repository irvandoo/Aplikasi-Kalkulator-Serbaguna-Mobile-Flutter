import 'package:decimal/decimal.dart';

import 'numeric.dart';
import 'outcome.dart';

enum UnitDimension {
  weight('Berat', 'gram', 'g'),
  volume('Volume', 'ml', 'ml'),
  count('Jumlah', 'pcs', 'pcs');

  const UnitDimension(this.label, this.baseName, this.baseSymbol);
  final String label;

  /// Display name of the common unit prices are normalised to.
  final String baseName;
  final String baseSymbol;
}

enum MeasureUnit {
  mg('mg', UnitDimension.weight, '0.001'),
  g('g', UnitDimension.weight, '1'),
  kg('kg', UnitDimension.weight, '1000'),
  ml('ml', UnitDimension.volume, '1'),
  l('l', UnitDimension.volume, '1000'),
  pcs('pcs', UnitDimension.count, '1');

  const MeasureUnit(this.symbol, this.dimension, this._factor);
  final String symbol;
  final UnitDimension dimension;
  final String _factor;

  /// How many base units (g, ml or pcs) one of this unit equals.
  Decimal get factor => Decimal.parse(_factor);

  static List<MeasureUnit> forDimension(UnitDimension d) =>
      values.where((u) => u.dimension == d).toList();

  static MeasureUnit defaultFor(UnitDimension d) => switch (d) {
        UnitDimension.weight => MeasureUnit.g,
        UnitDimension.volume => MeasureUnit.ml,
        UnitDimension.count => MeasureUnit.pcs,
      };
}

class ProductInput {
  const ProductInput({
    required this.price,
    required this.quantity,
    required this.unit,
  });

  final Decimal? price;
  final Decimal? quantity;
  final MeasureUnit unit;
}

class ProductComparison {
  const ProductComparison({
    required this.index,
    required this.unitPrice,
    required this.isCheapest,
    required this.nominalDifference,
    required this.percentDifference,
  });

  final int index;

  /// Exact price per base unit (g, ml or pcs).
  final Decimal unitPrice;
  final bool isCheapest;

  /// unitPrice − cheapest unitPrice (0 for the cheapest).
  final Decimal nominalDifference;

  /// (unitPrice − cheapest) / unitPrice × 100: how much cheaper the best
  /// option is relative to this one. 0 for the cheapest.
  final Decimal percentDifference;
}

class UnitPriceComparison {
  const UnitPriceComparison({
    required this.items,
    required this.cheapestIndex,
    required this.isTie,
  });

  /// Only valid products, in input order.
  final List<ProductComparison> items;
  final int cheapestIndex;

  /// True when every valid product has the same unit price.
  final bool isTie;
}

class UnitPriceCalculator {
  const UnitPriceCalculator();

  /// Validation message for a single product, or null when it is valid.
  String? validate(ProductInput p) {
    if (p.price == null || p.quantity == null) return 'Isi harga dan ukuran';
    if (isNegative(p.price!)) return 'Harga tidak boleh negatif';
    if (p.quantity! <= decZero) return 'Ukuran harus lebih dari nol';
    return null;
  }

  /// Price per base unit, or an error for invalid input.
  Outcome<Decimal> unitPrice(ProductInput p) {
    final error = validate(p);
    if (error != null) return Err(error);
    return Ok(divide(p.price!, p.quantity! * p.unit.factor, scale: 12));
  }

  /// Compares at least two valid products of the same [UnitDimension].
  Outcome<UnitPriceComparison> compare(List<ProductInput> products) {
    final valid = <int, Decimal>{};
    UnitDimension? dimension;
    for (var i = 0; i < products.length; i++) {
      final p = products[i];
      if (validate(p) != null) continue;
      dimension ??= p.unit.dimension;
      if (p.unit.dimension != dimension) {
        return const Err('Satuan tidak sebanding (berat, volume, dan jumlah '
            'tidak bisa dibandingkan)');
      }
      valid[i] = unitPrice(p).valueOrNull!;
    }
    if (valid.length < 2) {
      return const Err('Isi minimal dua produk dengan data valid');
    }
    var best = valid.entries.first;
    for (final e in valid.entries) {
      if (e.value < best.value) best = e;
    }
    final items = valid.entries.map((e) {
      final diff = e.value - best.value;
      return ProductComparison(
        index: e.key,
        unitPrice: e.value,
        isCheapest: e.key == best.key,
        nominalDifference: diff,
        percentDifference:
            e.value == decZero ? decZero : divide(diff * decHundred, e.value),
      );
    }).toList();
    final isTie = valid.values.every((v) => v == best.value);
    return Ok(UnitPriceComparison(
      items: items,
      cheapestIndex: best.key,
      isTie: isTie,
    ));
  }
}
