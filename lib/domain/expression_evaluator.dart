import 'package:decimal/decimal.dart';

import 'numeric.dart';
import 'outcome.dart';

/// Evaluates calculator expressions with exact decimal arithmetic.
///
/// Grammar (lowest to highest precedence):
///   expr    := term (('+' | '−') term)*
///   term    := unary (('×' | '÷') unary | implicit-multiplication)*
///   unary   := ('−' | '+') unary | postfix
///   postfix := primary ('%' | '²')*
///   primary := number | 'π' | '(' expr ')' | '√' primary
///
/// Percent rule: `a + b%` and `a − b%` mean `a ± (a × b / 100)`; everywhere
/// else `x%` means `x / 100`.
class ExpressionEvaluator {
  const ExpressionEvaluator();

  static final Decimal _limit = Decimal.parse('1000000000000000000000000000000');
  static final Decimal pi = Decimal.parse('3.14159265358979');

  static const String overflowMessage = 'Hasil terlalu besar';
  static const String divideByZeroMessage = 'Tidak bisa dibagi nol';
  static const String syntaxMessage = 'Format tidak valid';

  /// Evaluates [expression]. Unclosed parentheses are closed automatically.
  Outcome<Decimal> evaluate(String expression) {
    final source = expression.trim();
    if (source.isEmpty) return const Err('Masukkan perhitungan');
    try {
      final tokens = _tokenize(source);
      final parser = _Parser(tokens);
      final node = parser.parse();
      final value = _eval(node);
      return Ok(_normalize(value));
    } on _CalcException catch (e) {
      return Err(e.message);
    }
  }

  Decimal _normalize(Decimal v) {
    _checkRange(v);
    return roundTo(v, _resultScale);
  }

  /// Fractional digits kept in the final result (≥ the digits of [pi]).
  static const int _resultScale = 15;

  void _checkRange(Decimal v) {
    if (v.abs() >= _limit) throw const _CalcException(overflowMessage);
  }

  Decimal _eval(_Node node) {
    final Decimal result;
    switch (node) {
      case _Num(:final value):
        result = value;
      case _Neg(:final operand):
        result = -_eval(operand);
      case _Percent(:final operand):
        result = divide(_eval(operand), decHundred);
      case _Square(:final operand):
        final v = _eval(operand);
        result = v * v;
      case _Sqrt(:final operand):
        result = _sqrt(_eval(operand));
      case _Bin(:final op, :final left, :final right):
        final l = _eval(left);
        if ((op == '+' || op == '−') && right is _Percent) {
          final p = _eval(right.operand);
          final delta = l * p / decHundred;
          final d = delta.toDecimal(scaleOnInfinitePrecision: divisionScale);
          result = op == '+' ? l + d : l - d;
        } else {
          final r = _eval(right);
          switch (op) {
            case '+':
              result = l + r;
            case '−':
              result = l - r;
            case '×':
              result = l * r;
            case '÷':
              if (r == decZero) {
                throw const _CalcException(divideByZeroMessage);
              }
              result = divide(l, r);
            default:
              throw const _CalcException(syntaxMessage);
          }
        }
    }
    _checkRange(result);
    return result;
  }

  Decimal _sqrt(Decimal v) {
    if (isNegative(v)) {
      throw const _CalcException('Akar bilangan negatif tidak valid');
    }
    if (v == decZero) return decZero;
    // Integer square root on the value scaled by 10^(2*divisionScale).
    final scaled = v.shift(2 * divisionScale).truncate().toBigInt();
    var x = BigInt.one << ((scaled.bitLength + 1) ~/ 2);
    while (true) {
      final y = (x + scaled ~/ x) >> 1;
      if (y >= x) break;
      x = y;
    }
    return Decimal.fromBigInt(x).shift(-divisionScale);
  }

  List<_Token> _tokenize(String s) {
    final tokens = <_Token>[];
    var i = 0;
    while (i < s.length) {
      final c = s[i];
      if (c == ' ') {
        i++;
      } else if (_isDigit(c) || c == '.') {
        final start = i;
        var dots = 0;
        while (i < s.length && (_isDigit(s[i]) || s[i] == '.')) {
          if (s[i] == '.') dots++;
          i++;
        }
        final text = s.substring(start, i);
        if (dots > 1 || text == '.') throw const _CalcException(syntaxMessage);
        final normalized = text.endsWith('.') ? '${text}0' : text;
        final fixed = normalized.startsWith('.') ? '0$normalized' : normalized;
        tokens.add(_Token.number(Decimal.parse(fixed)));
      } else {
        final op = switch (c) {
          '+' => '+',
          '-' || '−' || '–' => '−',
          '*' || '×' || 'x' || 'X' => '×',
          '/' || '÷' => '÷',
          '(' => '(',
          ')' => ')',
          '%' => '%',
          '²' => '²',
          '√' => '√',
          'π' => 'π',
          _ => null,
        };
        if (op == null) throw const _CalcException(syntaxMessage);
        tokens.add(_Token.symbol(op));
        i++;
      }
    }
    return tokens;
  }

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;
}

class _CalcException implements Exception {
  const _CalcException(this.message);
  final String message;
}

class _Token {
  _Token.number(Decimal this.number) : symbol = null;
  _Token.symbol(String this.symbol) : number = null;
  final Decimal? number;
  final String? symbol;
}

sealed class _Node {}

class _Num extends _Node {
  _Num(this.value);
  final Decimal value;
}

class _Neg extends _Node {
  _Neg(this.operand);
  final _Node operand;
}

class _Percent extends _Node {
  _Percent(this.operand);
  final _Node operand;
}

class _Square extends _Node {
  _Square(this.operand);
  final _Node operand;
}

class _Sqrt extends _Node {
  _Sqrt(this.operand);
  final _Node operand;
}

class _Bin extends _Node {
  _Bin(this.op, this.left, this.right);
  final String op;
  final _Node left;
  final _Node right;
}

class _Parser {
  _Parser(this.tokens);
  final List<_Token> tokens;
  int pos = 0;
  int depth = 0;

  static const int _maxDepth = 64;

  _Token? get _peek => pos < tokens.length ? tokens[pos] : null;
  bool _isSymbol(String s) => _peek?.symbol == s;

  _Node parse() {
    final node = _expr();
    if (pos != tokens.length) {
      throw const _CalcException(ExpressionEvaluator.syntaxMessage);
    }
    return node;
  }

  _Node _expr() {
    var left = _term();
    while (_isSymbol('+') || _isSymbol('−')) {
      final op = tokens[pos++].symbol!;
      final right = _term();
      left = _Bin(op, left, right);
    }
    return left;
  }

  bool get _startsOperand {
    final t = _peek;
    if (t == null) return false;
    return t.number != null ||
        t.symbol == '(' ||
        t.symbol == 'π' ||
        t.symbol == '√';
  }

  _Node _term() {
    var left = _unary();
    while (true) {
      if (_isSymbol('×') || _isSymbol('÷')) {
        final op = tokens[pos++].symbol!;
        left = _Bin(op, left, _unary());
      } else if (_startsOperand) {
        left = _Bin('×', left, _unary());
      } else {
        return left;
      }
    }
  }

  _Node _unary() {
    if (_isSymbol('−')) {
      pos++;
      return _Neg(_unary());
    }
    if (_isSymbol('+')) {
      pos++;
      return _unary();
    }
    return _postfix();
  }

  _Node _postfix() {
    var node = _primary();
    while (true) {
      if (_isSymbol('%')) {
        pos++;
        node = _Percent(node);
      } else if (_isSymbol('²')) {
        pos++;
        node = _Square(node);
      } else {
        return node;
      }
    }
  }

  _Node _primary() {
    final t = _peek;
    if (t == null) throw const _CalcException(ExpressionEvaluator.syntaxMessage);
    if (t.number != null) {
      pos++;
      return _Num(t.number!);
    }
    switch (t.symbol) {
      case 'π':
        pos++;
        return _Num(ExpressionEvaluator.pi);
      case '√':
        pos++;
        return _Sqrt(_primary());
      case '(':
        pos++;
        if (++depth > _maxDepth) {
          throw const _CalcException(ExpressionEvaluator.syntaxMessage);
        }
        final inner = _expr();
        // Unclosed parentheses are closed implicitly at the end of input.
        if (_isSymbol(')')) pos++;
        depth--;
        return inner;
      default:
        throw const _CalcException(ExpressionEvaluator.syntaxMessage);
    }
  }
}
