import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../core/number_format.dart';
import '../../data/models.dart';
import '../../domain/bill_split_calculator.dart';
import '../../domain/numeric.dart';
import '../../domain/outcome.dart';

class BillSplitViewModel extends ChangeNotifier {
  BillSplitViewModel({
    HistoryEntry? restore,
    this._calculator = const BillSplitCalculator(),
  }) {
    if (restore != null && restore.type == HistoryType.billSplit) {
      final d = restore.inputData;
      _bill = tryDec(d['bill'] as String?);
      final p = d['people'];
      if (p is int && p >= 1 && p <= BillSplitCalculator.maxPeople) {
        _people = p;
      }
      _tax = tryDec(d['tax'] as String?);
      _tip = tryDec(d['tip'] as String?);
      _rounding = SplitRounding.values.firstWhere(
        (r) => r.name == d['rounding'],
        orElse: () => SplitRounding.none,
      );
    }
    _recalculate();
  }

  static const List<int> tipPresets = [0, 5, 10, 15];
  static const List<int> taxPresets = [0, 10, 11];

  final BillSplitCalculator _calculator;
  Decimal? _bill;
  int _people = 2;
  Decimal? _tax;
  Decimal? _tip;
  SplitRounding _rounding = SplitRounding.none;
  Outcome<BillSplitResult>? _outcome;

  Decimal? get bill => _bill;
  int get people => _people;
  Decimal? get tax => _tax;
  Decimal? get tip => _tip;
  SplitRounding get rounding => _rounding;
  BillSplitResult? get result => _outcome?.valueOrNull;

  /// Validation error, shown only once a bill amount was typed.
  String? get error => _bill == null ? null : _outcome?.errorOrNull;

  void setBill(Decimal? v) {
    _bill = v;
    _recalculate();
  }

  void setPeople(int n) {
    _people = n.clamp(1, BillSplitCalculator.maxPeople);
    _recalculate();
  }

  void increasePeople() => setPeople(_people + 1);
  void decreasePeople() => setPeople(_people - 1);

  void setTax(Decimal? v) {
    _tax = v;
    _recalculate();
  }

  void setTip(Decimal? v) {
    _tip = v;
    _recalculate();
  }

  void setRounding(SplitRounding r) {
    _rounding = r;
    _recalculate();
  }

  void reset() {
    _bill = null;
    _people = 2;
    _tax = null;
    _tip = null;
    _rounding = SplitRounding.none;
    _recalculate();
  }

  void _recalculate() {
    _outcome = _calculator.calculate(
      bill: _bill,
      people: _people,
      taxPercent: _tax,
      tipPercent: _tip,
      rounding: _rounding,
    );
    notifyListeners();
  }

  String title(AppNumberFormat f) =>
      'Tagihan ${f.rupiah(_bill ?? decZero)} untuk $_people orang';

  String resultText(AppNumberFormat f) {
    final r = result;
    return r == null ? '' : '${f.rupiah(r.perPerson)} / orang';
  }

  String detailText(AppNumberFormat f) {
    final r = result;
    if (r == null) return '';
    final lines = <String>[
      'Patungan: ${title(f)}',
      'Tagihan: ${f.rupiah(r.bill)}',
      if (r.tax > decZero) 'Pajak: ${f.rupiah(r.tax)}',
      if (r.tip > decZero) 'Tip: ${f.rupiah(r.tip)}',
      'Total: ${f.rupiah(r.total)}',
      'Per orang: ${f.rupiah(r.perPerson)} (${r.people} orang)',
    ];
    return lines.join('\n');
  }

  HistoryEntry? toHistoryEntry(AppNumberFormat f) {
    if (result == null) return null;
    return HistoryEntry(
      type: HistoryType.billSplit,
      title: title(f),
      result: resultText(f),
      inputData: {
        'bill': _bill?.toString(),
        'people': _people,
        'tax': _tax?.toString(),
        'tip': _tip?.toString(),
        'rounding': _rounding.name,
      },
    );
  }
}
