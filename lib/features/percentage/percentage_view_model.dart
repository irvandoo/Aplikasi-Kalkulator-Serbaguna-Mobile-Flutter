import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../core/number_format.dart';
import '../../data/models.dart';
import '../../domain/numeric.dart';
import '../../domain/outcome.dart';
import '../../domain/percentage_calculator.dart';

/// Field captions per mode. Which input is which follows the documentation of
/// [PercentageCalculator].
class PercentageFieldLabels {
  const PercentageFieldLabels(this.first, this.second, this.hint);
  final String first;
  final String second;
  final String hint;

  static PercentageFieldLabels of(PercentageMode mode) => switch (mode) {
        PercentageMode.percentOf => const PercentageFieldLabels(
            'Persen (%)', 'Dari nilai', 'Berapa X% dari suatu nilai?'),
        PercentageMode.whatPercent => const PercentageFieldLabels(
            'Bagian', 'Total', 'Bagian itu berapa persen dari total?'),
        PercentageMode.increase => const PercentageFieldLabels(
            'Nilai awal', 'Naik (%)', 'Nilai setelah dinaikkan X%'),
        PercentageMode.decrease => const PercentageFieldLabels(
            'Nilai awal', 'Turun (%)', 'Nilai setelah diturunkan X%'),
        PercentageMode.difference => const PercentageFieldLabels(
            'Nilai 1', 'Nilai 2', 'Selisih mutlak dua nilai'),
        PercentageMode.change => const PercentageFieldLabels(
            'Nilai awal', 'Nilai baru', 'Persentase perubahan dari awal ke baru'),
      };

  /// Whether the field expects a percentage (shows a % suffix).
  static bool firstIsPercent(PercentageMode m) => m == PercentageMode.percentOf;
  static bool secondIsPercent(PercentageMode m) =>
      m == PercentageMode.increase || m == PercentageMode.decrease;
}

class PercentageViewModel extends ChangeNotifier {
  PercentageViewModel({
    HistoryEntry? restore,
    this._calculator = const PercentageCalculator(),
  }) {
    if (restore != null && restore.type == HistoryType.percentage) {
      final name = restore.inputData['mode'];
      _mode = PercentageMode.values.firstWhere(
        (m) => m.name == name,
        orElse: () => PercentageMode.percentOf,
      );
      _first = tryDec(restore.inputData['first'] as String?);
      _second = tryDec(restore.inputData['second'] as String?);
    }
    _recalculate();
  }

  final PercentageCalculator _calculator;
  PercentageMode _mode = PercentageMode.percentOf;
  Decimal? _first;
  Decimal? _second;
  Outcome<PercentageResult>? _outcome;

  PercentageMode get mode => _mode;
  Decimal? get first => _first;
  Decimal? get second => _second;
  PercentageFieldLabels get labels => PercentageFieldLabels.of(_mode);
  PercentageResult? get result => _outcome?.valueOrNull;

  /// Validation error, shown only once both fields hold numbers.
  String? get error =>
      (_first != null && _second != null) ? _outcome?.errorOrNull : null;

  void setMode(PercentageMode m) {
    _mode = m;
    _recalculate();
  }

  void setFirst(Decimal? v) {
    _first = v;
    _recalculate();
  }

  void setSecond(Decimal? v) {
    _second = v;
    _recalculate();
  }

  void _recalculate() {
    _outcome = _calculator.calculate(_mode, _first, _second);
    notifyListeners();
  }

  String formatResult(AppNumberFormat f) {
    final r = result;
    if (r == null) return '';
    return r.isPercent ? f.percent(r.value) : f.number(r.value);
  }

  String title(AppNumberFormat f) {
    final a = f.number(_first ?? decZero, places: 8);
    final b = f.number(_second ?? decZero, places: 8);
    return switch (_mode) {
      PercentageMode.percentOf => '$a% dari $b',
      PercentageMode.whatPercent => '$a dari $b = berapa persen',
      PercentageMode.increase => '$a naik $b%',
      PercentageMode.decrease => '$a turun $b%',
      PercentageMode.difference => 'Selisih $a dan $b',
      PercentageMode.change => 'Perubahan dari $a ke $b',
    };
  }

  String detailText(AppNumberFormat f) {
    final r = result;
    if (r == null) return '';
    return '${_mode.label}: ${title(f)}\nHasil: ${formatResult(f)}\n'
        'Rumus: ${r.formula}';
  }

  HistoryEntry? toHistoryEntry(AppNumberFormat f) {
    if (result == null) return null;
    return HistoryEntry(
      type: HistoryType.percentage,
      title: title(f),
      result: formatResult(f),
      inputData: {
        'mode': _mode.name,
        'first': _first?.toString(),
        'second': _second?.toString(),
      },
    );
  }
}
