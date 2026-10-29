import 'package:decimal/decimal.dart';

/// Shared numeric helpers. All app arithmetic goes through [Decimal] so that
/// money, percentages and unit conversions never touch binary floating point.
final Decimal decZero = Decimal.zero;
final Decimal decOne = Decimal.one;
final Decimal decHundred = Decimal.fromInt(100);

/// Number of fractional digits kept when a division is not exact.
const int divisionScale = 12;

Decimal dec(Object value) => Decimal.parse(value.toString());

Decimal? tryDec(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  return Decimal.tryParse(trimmed);
}

/// Exact division, truncated to [scale] digits only when the result repeats.
Decimal divide(Decimal a, Decimal b, {int scale = divisionScale}) {
  return (a / b).toDecimal(scaleOnInfinitePrecision: scale);
}

/// Rounds half away from zero to [scale] fractional digits.
Decimal roundTo(Decimal value, int scale) => value.round(scale: scale);

/// Currency rounding rule: whole Rupiah, half away from zero. Only applied to
/// final amounts; intermediate values stay exact.
Decimal roundRupiah(Decimal value) => value.round(scale: 0);

bool isNegative(Decimal v) => v < decZero;
bool isPositive(Decimal v) => v > decZero;
