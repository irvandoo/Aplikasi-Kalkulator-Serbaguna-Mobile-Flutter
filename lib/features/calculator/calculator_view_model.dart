import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../core/number_format.dart';
import '../../data/models.dart';
import '../../domain/expression_evaluator.dart';
import '../../domain/numeric.dart';
import '../../domain/outcome.dart';

/// A successfully evaluated expression, ready to be stored in history.
class CalculationCommit {
  const CalculationCommit(this.expression, this.result);
  final String expression;
  final Decimal result;
}

/// Presentation state for the basic calculator. The raw expression uses
/// `.` as decimal point and the operator glyphs `+ − × ÷ ( ) % ² √ π`.
class CalculatorViewModel extends ChangeNotifier {
  static const int maxDigitsPerNumber = 18;
  static const int maxLength = 200;
  static final RegExp _allowed = RegExp(r'^[0-9.+−×÷()%²√π]*$');

  final ExpressionEvaluator _evaluator = const ExpressionEvaluator();
  AppNumberFormat _format = const AppNumberFormat();

  String _expression = '';
  String _previous = '';
  String? _error;
  bool _justEvaluated = false;
  Decimal _memory = decZero;
  bool _hasMemory = false;

  String get expression => _expression;
  String get previousExpression => _previous;
  String? get error => _error;
  bool get hasMemory => _hasMemory;
  bool get isEmpty => _expression.isEmpty;

  AppNumberFormat get format => _format;
  set format(AppNumberFormat f) {
    if (f.style == _format.style && f.decimalPlaces == _format.decimalPlaces) {
      return;
    }
    _format = f;
    notifyListeners();
  }

  // ---- character classes -------------------------------------------------

  static bool _isDigit(String c) =>
      c.isNotEmpty && c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
  static bool _isOperator(String c) => '+−×÷'.contains(c) && c.isNotEmpty;

  /// True when the character can end an operand (digit, ")", "%", "²", "π").
  static bool _endsOperand(String c) =>
      c.isNotEmpty && (_isDigit(c) || ')%²π.'.contains(c));

  String get _last =>
      _expression.isEmpty ? '' : _expression[_expression.length - 1];

  /// Start index of the number token ending the expression, or -1.
  int get _numberStart {
    var i = _expression.length;
    while (i > 0 &&
        (_isDigit(_expression[i - 1]) || _expression[i - 1] == '.')) {
      i--;
    }
    return i == _expression.length ? -1 : i;
  }

  String get _currentNumber {
    final s = _numberStart;
    return s < 0 ? '' : _expression.substring(s);
  }

  // ---- editing -----------------------------------------------------------

  void _startFreshIfEvaluated() {
    if (_justEvaluated) {
      _expression = '';
      _previous = '';
      _justEvaluated = false;
    }
  }

  void _afterEdit() {
    _error = null;
    notifyListeners();
  }

  bool get _full => _expression.length >= maxLength;

  void inputDigit(String digit) {
    assert(_isDigit(digit));
    _startFreshIfEvaluated();
    if (_full) return;
    final current = _currentNumber;
    if (current.replaceAll('.', '').length >= maxDigitsPerNumber) return;
    if (_last == ')' || _last == '%' || _last == '²' || _last == 'π') {
      _expression += '×';
    }
    if (current == '0') {
      // Replace a lone leading zero.
      _expression = _expression.substring(0, _expression.length - 1);
    }
    _expression += digit;
    _afterEdit();
  }

  void inputDecimal() {
    _startFreshIfEvaluated();
    if (_full) return;
    final current = _currentNumber;
    if (current.contains('.')) return;
    if (current.isEmpty) {
      if (_last == ')' || _last == '%' || _last == '²' || _last == 'π') {
        _expression += '×';
      }
      _expression += '0.';
    } else {
      _expression += '.';
    }
    _afterEdit();
  }

  void inputOperator(String op) {
    assert(_isOperator(op));
    _justEvaluated = false;
    if (_expression.isEmpty) {
      if (op == '−') {
        _expression = '−';
        _afterEdit();
      }
      return;
    }
    if (_last == '.') {
      _expression = _expression.substring(0, _expression.length - 1);
    }
    final last = _last;
    if (last == '(' || last == '√') {
      if (op == '−' && last == '(') {
        _expression += op;
        _afterEdit();
      }
      return;
    }
    if (_isOperator(last)) {
      // Replace the previous operator; a lone leading minus is removed.
      if (_expression.length == 1) {
        if (op != '−') _expression = '';
        _afterEdit();
        return;
      }
      _expression = _expression.substring(0, _expression.length - 1);
      final beforeLast = _last;
      if (beforeLast == '(' && op != '−') {
        _afterEdit();
        return;
      }
    }
    if (_full) return;
    _expression += op;
    _afterEdit();
  }

  void openParen() {
    _startFreshIfEvaluated();
    if (_full) return;
    if (_endsOperand(_last)) _expression += '×';
    _expression += '(';
    _afterEdit();
  }

  void closeParen() {
    _justEvaluated = false;
    final open = '('.allMatches(_expression).length;
    final close = ')'.allMatches(_expression).length;
    if (open <= close || _full) return;
    if (!_endsOperand(_last)) return;
    _expression += ')';
    _afterEdit();
  }

  void percent() {
    _justEvaluated = false;
    if (!_endsOperand(_last) || _last == '.' || _full) return;
    _expression += '%';
    _afterEdit();
  }

  void square() {
    _justEvaluated = false;
    if (!_endsOperand(_last) || _last == '.' || _full) return;
    _expression += '²';
    _afterEdit();
  }

  void squareRoot() {
    _startFreshIfEvaluated();
    if (_full) return;
    if (_endsOperand(_last)) _expression += '×';
    _expression += '√';
    _afterEdit();
  }

  void inputPi() {
    _startFreshIfEvaluated();
    if (_full) return;
    if (_endsOperand(_last)) _expression += '×';
    _expression += 'π';
    _afterEdit();
  }

  /// Flips the sign of the trailing number.
  void toggleSign() {
    _justEvaluated = false;
    final start = _numberStart;
    if (start < 0) return;
    final signAt = start - 1;
    final isUnaryMinus = signAt >= 0 &&
        _expression[signAt] == '−' &&
        (signAt == 0 || '(+−×÷'.contains(_expression[signAt - 1]));
    if (isUnaryMinus) {
      _expression = _expression.replaceRange(signAt, signAt + 1, '');
    } else {
      _expression = _expression.replaceRange(start, start, '−');
    }
    _afterEdit();
  }

  void backspace() {
    if (_justEvaluated) {
      _justEvaluated = false;
      _previous = '';
    }
    if (_expression.isEmpty) return;
    _expression = _expression.substring(0, _expression.length - 1);
    _afterEdit();
  }

  void clear() {
    _expression = '';
    _previous = '';
    _justEvaluated = false;
    _afterEdit();
  }

  /// Replaces the expression (e.g. from history). Invalid text is ignored.
  bool load(String? raw) {
    if (raw == null || raw.isEmpty || raw.length > maxLength) return false;
    if (!_allowed.hasMatch(raw)) return false;
    _expression = raw;
    _previous = '';
    _justEvaluated = false;
    _afterEdit();
    return true;
  }

  // ---- evaluation --------------------------------------------------------

  String get _evaluable {
    var s = _expression;
    while (s.isNotEmpty && (_isOperator(_last2(s)) || _last2(s) == '.')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  static String _last2(String s) => s.isEmpty ? '' : s[s.length - 1];

  /// Current numeric value of the expression, or null when incomplete/invalid.
  Decimal? get value {
    final s = _evaluable;
    if (s.isEmpty) return null;
    return _evaluator.evaluate(s).valueOrNull;
  }

  bool get _isPlainNumber => RegExp(r'^−?[0-9.]*$').hasMatch(_expression);

  /// Small line above the result.
  String get topLine {
    if (_justEvaluated) return _format.expression(_previous);
    return _isPlainNumber ? '' : _format.expression(_expression);
  }

  /// Large line: error, live result, or the number being typed.
  String get mainLine {
    if (_error != null) return _error!;
    if (_expression.isEmpty) return '0';
    if (_isPlainNumber || _justEvaluated) {
      return _format.expression(_expression);
    }
    final v = value;
    return v == null ? '' : _format.calculator(v);
  }

  /// Result text for copy/share (null when there is nothing to show).
  String? get resultText {
    if (_error != null || _expression.isEmpty) return null;
    final v = value;
    return v == null ? null : _format.calculator(v);
  }

  String get shareText {
    final result = resultText ?? '';
    final expr = _justEvaluated ? _previous : _expression;
    return '${_format.expression(expr)} = $result\n— Kalkulator Serbaguna';
  }

  /// Evaluates for "=". Returns a commit on success, null otherwise.
  CalculationCommit? equals() {
    final s = _evaluable;
    if (s.isEmpty) return null;
    if (_justEvaluated) return null;
    final Outcome<Decimal> r = _evaluator.evaluate(s);
    switch (r) {
      case Err(:final message):
        _error = message;
        notifyListeners();
        return null;
      case Ok(:final value):
        final display = value.toString().replaceAll('-', '−');
        _previous = s;
        _expression = display;
        _justEvaluated = true;
        _error = null;
        notifyListeners();
        return CalculationCommit(s, value);
    }
  }

  /// Evaluates the current expression without changing it (for "Simpan").
  CalculationCommit? snapshot() {
    final s = _justEvaluated ? _previous : _evaluable;
    if (s.isEmpty) return null;
    final v = _evaluator.evaluate(s).valueOrNull;
    return v == null ? null : CalculationCommit(s, v);
  }

  HistoryEntry entryFor(CalculationCommit c) => HistoryEntry(
        type: HistoryType.calculator,
        title: _format.expression(c.expression),
        result: _format.calculator(c.result),
        inputData: {'expression': c.expression},
      );

  // ---- memory ------------------------------------------------------------

  void memoryClear() {
    _memory = decZero;
    _hasMemory = false;
    notifyListeners();
  }

  void memoryRecall() {
    if (!_hasMemory) return;
    _startFreshIfEvaluated();
    if (_full) return;
    if (_endsOperand(_last)) _expression += '×';
    final text = _memory.toString().replaceAll('-', '−');
    _expression += _memory < decZero ? '($text)' : text;
    _afterEdit();
  }

  void memoryAdd() => _memoryChange(1);
  void memorySubtract() => _memoryChange(-1);

  void _memoryChange(int sign) {
    final v = _justEvaluated ? snapshot()?.result : value;
    if (v == null) return;
    _memory = sign > 0 ? _memory + v : _memory - v;
    _hasMemory = true;
    notifyListeners();
  }

  @visibleForTesting
  Decimal get memoryValue => _memory;
}
