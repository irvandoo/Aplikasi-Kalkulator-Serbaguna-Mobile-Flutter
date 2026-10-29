import 'package:decimal/decimal.dart';

import 'numeric.dart';
import 'outcome.dart';

enum PercentageMode {
  percentOf('Persen dari nilai'),
  whatPercent('Berapa persen'),
  increase('Kenaikan persen'),
  decrease('Penurunan persen'),
  difference('Selisih'),
  change('Perubahan persen');

  const PercentageMode(this.label);
  final String label;
}

class PercentageResult {
  const PercentageResult({
    required this.mode,
    required this.value,
    required this.isPercent,
    required this.formula,
  });

  final PercentageMode mode;

  /// Exact (unrounded) result.
  final Decimal value;

  /// Whether [value] is a percentage (true) or a plain amount (false).
  final bool isPercent;

  /// Human-readable description of how the value was derived.
  final String formula;
}

/// Percentage rules (all exact, no intermediate rounding):
///  * percentOf(p, v)      = v × p / 100
///  * whatPercent(a, b)    = a / b × 100          (b ≠ 0)
///  * increase(v, p)       = v × (1 + p / 100)
///  * decrease(v, p)       = v × (1 − p / 100)
///  * difference(a, b)     = |a − b|
///  * change(old, new)     = (new − old) / |old| × 100   (old ≠ 0)
/// Negative inputs are accepted and follow the same formulas.
class PercentageCalculator {
  const PercentageCalculator();

  Outcome<PercentageResult> calculate(
    PercentageMode mode,
    Decimal? first,
    Decimal? second,
  ) {
    if (first == null || second == null) {
      return const Err('Isi kedua kolom dengan angka yang valid');
    }
    switch (mode) {
      case PercentageMode.percentOf:
        // first = percent, second = value
        return Ok(PercentageResult(
          mode: mode,
          value: divide(second * first, decHundred),
          isPercent: false,
          formula: 'nilai × persen ÷ 100',
        ));
      case PercentageMode.whatPercent:
        // first = part, second = whole
        if (second == decZero) {
          return const Err('Nilai pembanding tidak boleh nol');
        }
        return Ok(PercentageResult(
          mode: mode,
          value: divide(first * decHundred, second),
          isPercent: true,
          formula: 'bagian ÷ total × 100',
        ));
      case PercentageMode.increase:
        // first = value, second = percent
        return Ok(PercentageResult(
          mode: mode,
          value: first + divide(first * second, decHundred),
          isPercent: false,
          formula: 'nilai × (1 + persen ÷ 100)',
        ));
      case PercentageMode.decrease:
        return Ok(PercentageResult(
          mode: mode,
          value: first - divide(first * second, decHundred),
          isPercent: false,
          formula: 'nilai × (1 − persen ÷ 100)',
        ));
      case PercentageMode.difference:
        return Ok(PercentageResult(
          mode: mode,
          value: (first - second).abs(),
          isPercent: false,
          formula: '|nilai 1 − nilai 2|',
        ));
      case PercentageMode.change:
        // first = old, second = new
        if (first == decZero) {
          return const Err('Nilai awal tidak boleh nol');
        }
        return Ok(PercentageResult(
          mode: mode,
          value: divide((second - first) * decHundred, first.abs()),
          isPercent: true,
          formula: '(baru − awal) ÷ |awal| × 100',
        ));
    }
  }
}
