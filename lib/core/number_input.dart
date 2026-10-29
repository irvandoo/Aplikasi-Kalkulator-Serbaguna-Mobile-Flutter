import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../features/settings/settings_view_model.dart';
import 'number_format.dart';

/// Live-formats numeric text with thousand separators in the active style.
/// Only digits, one decimal separator (optional) and a leading minus
/// (optional) are accepted.
class NumberInputFormatter extends TextInputFormatter {
  NumberInputFormatter(this.format,
      {this.allowDecimal = false, this.allowNegative = false});

  final AppNumberFormat format;
  final bool allowDecimal;
  final bool allowNegative;

  static const int maxIntegerDigits = 15;
  static const int maxFractionDigits = 8;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var raw = newValue.text;
    final negative = allowNegative && raw.trimLeft().startsWith('-');
    final sep = format.decimalSeparator;
    final buffer = StringBuffer();
    var seenSep = false;
    var intDigits = 0;
    var fracDigits = 0;
    for (final ch in raw.split('')) {
      final isDigit = ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
      if (isDigit) {
        if (seenSep) {
          if (fracDigits >= maxFractionDigits) continue;
          fracDigits++;
        } else {
          if (intDigits >= maxIntegerDigits) continue;
          intDigits++;
        }
        buffer.write(ch);
      } else if (allowDecimal && !seenSep && ch == sep) {
        seenSep = true;
        buffer.write('.');
      }
    }
    var text = buffer.toString();
    if (text.isEmpty) {
      final out = negative ? '-' : '';
      return TextEditingValue(
          text: out, selection: TextSelection.collapsed(offset: out.length));
    }
    final dot = text.indexOf('.');
    final intPart = dot < 0 ? text : text.substring(0, dot);
    final frac = dot < 0 ? '' : text.substring(dot + 1);
    // Strip leading zeros but keep a single zero.
    var cleanInt = intPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (cleanInt.isEmpty) cleanInt = '0';
    final grouped = format.expression(cleanInt);
    final out = '${negative ? '-' : ''}$grouped'
        '${dot < 0 ? '' : sep}$frac';
    return TextEditingValue(
        text: out, selection: TextSelection.collapsed(offset: out.length));
  }
}

/// Numeric text field bound to the app number style. Reports the parsed value
/// (null when empty/invalid) through [onChanged].
class NumberField extends StatelessWidget {
  const NumberField({
    super.key,
    required this.controller,
    this.onChanged,
    this.label,
    this.hint,
    this.prefix,
    this.suffix,
    this.allowDecimal = false,
    this.allowNegative = false,
    this.errorText,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.semanticLabel,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  /// Called with the parsed value (null when the text is empty or invalid).
  final ValueChanged<Decimal?>? onChanged;
  final String? label;
  final String? hint;
  final String? prefix;
  final String? suffix;
  final bool allowDecimal;
  final bool allowNegative;
  final String? errorText;
  final TextStyle? textStyle;
  final TextAlign textAlign;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final format = context.watch<SettingsViewModel>().format;
    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: textAlign,
        style: textStyle,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        keyboardType: TextInputType.numberWithOptions(
            decimal: allowDecimal, signed: allowNegative),
        inputFormatters: [
          NumberInputFormatter(format,
              allowDecimal: allowDecimal, allowNegative: allowNegative),
        ],
        onChanged: (text) => onChanged?.call(format.parse(text)),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixText: prefix == null ? null : '$prefix ',
          suffixText: suffix,
          errorText: errorText,
        ),
      ),
    );
  }
}
