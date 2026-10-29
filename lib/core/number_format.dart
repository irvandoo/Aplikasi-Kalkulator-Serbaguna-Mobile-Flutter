import 'package:decimal/decimal.dart';

import '../domain/numeric.dart';

enum NumberStyle {
  indonesia('Indonesia (1.234,56)', '.', ','),
  international('Internasional (1,234.56)', ',', '.');

  const NumberStyle(this.label, this.group, this.decimal);
  final String label;
  final String group;
  final String decimal;
}

/// Locale-aware formatting and parsing for numbers and Rupiah amounts.
///
/// Implemented by hand (not via intl number symbols) so that it is
/// synchronous, deterministic and works in tests without locale data.
class AppNumberFormat {
  const AppNumberFormat({
    this.style = NumberStyle.indonesia,
    this.decimalPlaces = 2,
  });

  final NumberStyle style;

  /// Fraction digits for percentages and unit prices.
  final int decimalPlaces;

  String get group => style.group;
  String get decimalSeparator => style.decimal;

  String _groupInt(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(group);
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  /// Formats [v] rounded to [places] decimals; trailing zeros are removed
  /// unless [fixed] is true.
  String number(Decimal v, {int? places, bool fixed = false}) {
    final p = places ?? decimalPlaces;
    final rounded = roundTo(v, p);
    final negative = rounded < decZero;
    final text = rounded.abs().toStringAsFixed(p);
    final parts = text.split('.');
    var frac = parts.length > 1 ? parts[1] : '';
    if (!fixed) frac = frac.replaceFirst(RegExp(r'0+$'), '');
    final body = frac.isEmpty
        ? _groupInt(parts[0])
        : '${_groupInt(parts[0])}$decimalSeparator$frac';
    final isZero = rounded == decZero;
    return '${negative && !isZero ? '-' : ''}$body';
  }

  /// Calculator display: up to 10 decimals regardless of the setting.
  String calculator(Decimal v) => number(v, places: 10);

  /// Whole-Rupiah amount, e.g. `Rp 250.000` or `-Rp 1.500`.
  String rupiah(Decimal v) {
    final rounded = roundRupiah(v);
    final negative = rounded < decZero;
    final body = _groupInt(rounded.abs().toStringAsFixed(0));
    return '${negative ? '-' : ''}Rp $body';
  }

  /// Rupiah amount with [places] decimals (used for unit prices).
  String rupiahDecimal(Decimal v, {int? places}) {
    final p = places ?? decimalPlaces;
    final rounded = roundTo(v, p);
    final negative = rounded < decZero;
    return '${negative ? '-' : ''}Rp ${number(rounded.abs(), places: p, fixed: true)}';
  }

  String percent(Decimal v) => '${number(v)}%';

  /// Formats the digits and `.` decimal point inside a raw calculator
  /// expression for display, leaving operators untouched.
  String expression(String raw) {
    return raw.replaceAllMapped(RegExp(r'\d+(\.\d*)?|\.\d+'), (m) {
      final text = m[0]!;
      final dot = text.indexOf('.');
      if (dot < 0) return _groupInt(text);
      final intPart = text.substring(0, dot);
      final frac = text.substring(dot + 1);
      final head = intPart.isEmpty ? '0' : _groupInt(intPart);
      return '$head$decimalSeparator$frac';
    });
  }

  /// Parses user-typed text in the current style. Returns null when invalid.
  Decimal? parse(String text) {
    var t = text.trim().replaceAll(' ', '');
    if (t.isEmpty) return null;
    t = t.replaceAll(group, '');
    if (decimalSeparator != '.') t = t.replaceAll(decimalSeparator, '.');
    if (t.startsWith('.')) t = '0$t';
    if (t.endsWith('.')) t = t.substring(0, t.length - 1);
    return Decimal.tryParse(t);
  }

  /// Text to show in an input field for [v].
  String inputText(Decimal v) => number(v, places: 12);
}
