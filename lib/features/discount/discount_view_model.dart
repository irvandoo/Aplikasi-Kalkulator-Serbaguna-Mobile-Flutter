import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import '../../core/number_format.dart';
import '../../data/models.dart';
import '../../domain/discount_calculator.dart';
import '../../domain/numeric.dart';
import '../../domain/outcome.dart';

/// State for the discount calculator. All maths is delegated to
/// [DiscountCalculator]; this class only collects inputs.
class DiscountViewModel extends ChangeNotifier {
  DiscountViewModel({
    HistoryEntry? restore,
    this._calculator = const DiscountCalculator(),
  }) {
    if (restore != null && restore.type == HistoryType.discount) {
      _restore(restore.inputData);
    }
    _recalculate();
  }

  static const int maxStages = 4;
  static final Decimal ppnPercent = Decimal.fromInt(11);

  final DiscountCalculator _calculator;

  Decimal? _price;
  final List<Decimal?> _stages = [null];
  bool _extraEnabled = false;
  bool _taxEnabled = false;
  Decimal? _fee;
  Outcome<DiscountResult>? _outcome;

  Decimal? get price => _price;
  List<Decimal?> get stages => List.unmodifiable(_stages);
  bool get extraEnabled => _extraEnabled;
  bool get taxEnabled => _taxEnabled;
  Decimal? get fee => _fee;
  bool get canAddStage => _stages.length < maxStages;

  /// Null until a price has been entered.
  Outcome<DiscountResult>? get outcome => _outcome;
  DiscountResult? get result => _outcome?.valueOrNull;
  String? get error => _outcome?.errorOrNull;

  void setPrice(Decimal? v) {
    _price = v;
    _recalculate();
  }

  void setStage(int index, Decimal? v) {
    if (index < 0 || index >= _stages.length) return;
    _stages[index] = v;
    _recalculate();
  }

  void setExtraEnabled(bool enabled) {
    _extraEnabled = enabled;
    if (enabled && _stages.length < 2) _stages.add(null);
    _recalculate();
  }

  void addStage() {
    if (!canAddStage) return;
    _stages.add(null);
    _recalculate();
  }

  void removeStage(int index) {
    if (index < 1 || index >= _stages.length) return;
    _stages.removeAt(index);
    if (_stages.length < 2) _extraEnabled = false;
    _recalculate();
  }

  void setTaxEnabled(bool enabled) {
    _taxEnabled = enabled;
    _recalculate();
  }

  void setFee(Decimal? v) {
    _fee = v;
    _recalculate();
  }

  /// Stages that take part in the calculation, in order.
  List<Decimal> get activePercents {
    final used = _extraEnabled ? _stages : _stages.take(1);
    return used.whereType<Decimal>().toList();
  }

  void _recalculate() {
    _outcome = _price == null
        ? null
        : _calculator.calculate(
            originalPrice: _price,
            discountPercents: activePercents,
            taxPercent: _taxEnabled ? ppnPercent : null,
            additionalFee: _fee,
          );
    notifyListeners();
  }

  void _restore(Map<String, dynamic> data) {
    _price = tryDec(data['price'] as String?);
    final stages = data['stages'];
    if (stages is List && stages.isNotEmpty) {
      _stages
        ..clear()
        ..addAll(stages
            .take(maxStages)
            .map((s) => s is String ? tryDec(s) : null));
    }
    _extraEnabled = data['extra'] == true && _stages.length > 1;
    _taxEnabled = data['tax'] == true;
    _fee = tryDec(data['fee'] as String?);
  }

  Map<String, dynamic> get inputData => {
        'price': _price?.toString(),
        'stages': _stages.map((s) => s?.toString()).toList(),
        'extra': _extraEnabled,
        'tax': _taxEnabled,
        'fee': _fee?.toString(),
      };

  /// Plain-text breakdown used for copy and share.
  String detailText(AppNumberFormat f) {
    final r = result;
    if (r == null) return '';
    final b = StringBuffer('Kalkulator Diskon\n');
    b.writeln('Harga asli: ${f.rupiah(r.originalPrice)}');
    for (var i = 0; i < r.steps.length; i++) {
      final s = r.steps[i];
      b.writeln('Diskon ${i + 1} (${f.percent(s.percent)}): '
          '-${f.rupiah(s.amount)} → sisa ${f.rupiah(s.remaining)}');
    }
    if (r.taxAmount > decZero) {
      b.writeln('PPN (${f.percent(r.taxPercent)}): ${f.rupiah(r.taxAmount)}');
    }
    if (r.additionalFee > decZero) {
      b.writeln('Biaya tambahan: ${f.rupiah(r.additionalFee)}');
    }
    b.writeln('Harga akhir: ${f.rupiah(r.finalPrice)}');
    b.write('Total hemat: ${f.rupiah(r.savings)} '
        '(${f.percent(r.savingsPercent)})');
    return b.toString();
  }

  /// History entry for the current calculation, or null without a result.
  HistoryEntry? toHistoryEntry(AppNumberFormat f) {
    final r = result;
    if (r == null) return null;
    final title = StringBuffer(f.rupiah(r.originalPrice));
    for (final s in r.steps) {
      title.write(' − ${f.percent(s.percent)}');
    }
    if (r.taxAmount > decZero) title.write(' + PPN ${f.percent(r.taxPercent)}');
    return HistoryEntry(
      type: HistoryType.discount,
      title: title.toString(),
      result: f.rupiah(r.finalPrice),
      inputData: inputData,
      savings: r.savings,
    );
  }
}

/// One offer in the comparison screen.
class OfferInput {
  const OfferInput({this.price, this.first, this.second, this.fee});
  final Decimal? price;
  final Decimal? first;
  final Decimal? second;
  final Decimal? fee;

  OfferInput copyWith({
    Decimal? price,
    bool clearPrice = false,
    Decimal? first,
    bool clearFirst = false,
    Decimal? second,
    bool clearSecond = false,
    Decimal? fee,
    bool clearFee = false,
  }) =>
      OfferInput(
        price: clearPrice ? null : (price ?? this.price),
        first: clearFirst ? null : (first ?? this.first),
        second: clearSecond ? null : (second ?? this.second),
        fee: clearFee ? null : (fee ?? this.fee),
      );
}

class OfferEvaluation {
  const OfferEvaluation({
    required this.outcome,
    required this.isCheapest,
    this.nominalDifference,
    this.percentDifference,
  });

  final Outcome<DiscountResult>? outcome;
  final bool isCheapest;

  /// finalPrice − cheapest finalPrice (null when not comparable).
  final Decimal? nominalDifference;

  /// Difference relative to this offer's final price.
  final Decimal? percentDifference;

  DiscountResult? get result => outcome?.valueOrNull;
}

class DiscountCompareViewModel extends ChangeNotifier {
  DiscountCompareViewModel({this._calculator = const DiscountCalculator()}) {
    _evaluate();
  }

  static const int minOffers = 2;
  static const int maxOffers = 4;

  final DiscountCalculator _calculator;
  final List<OfferInput> _offers = [const OfferInput(), const OfferInput()];
  bool _taxEnabled = false;
  List<OfferEvaluation> _evaluations = const [];
  bool _comparable = false;

  List<OfferInput> get offers => List.unmodifiable(_offers);
  bool get taxEnabled => _taxEnabled;
  List<OfferEvaluation> get evaluations => _evaluations;

  /// True when at least two offers are valid and a cheapest one exists.
  bool get comparable => _comparable;
  bool get canAdd => _offers.length < maxOffers;
  bool get canRemove => _offers.length > minOffers;

  void update(int i, OfferInput Function(OfferInput) change) {
    if (i < 0 || i >= _offers.length) return;
    _offers[i] = change(_offers[i]);
    _evaluate();
  }

  void setTaxEnabled(bool v) {
    _taxEnabled = v;
    _evaluate();
  }

  void add() {
    if (!canAdd) return;
    _offers.add(const OfferInput());
    _evaluate();
  }

  void remove(int i) {
    if (!canRemove || i < 0 || i >= _offers.length) return;
    _offers.removeAt(i);
    _evaluate();
  }

  void _evaluate() {
    final outcomes = _offers.map<Outcome<DiscountResult>?>((o) {
      if (o.price == null) return null;
      return _calculator.calculate(
        originalPrice: o.price,
        discountPercents: [
          if (o.first != null) o.first!,
          if (o.second != null) o.second!,
        ],
        taxPercent: _taxEnabled ? DiscountViewModel.ppnPercent : null,
        additionalFee: o.fee,
      );
    }).toList();

    final validIdx = <int>[
      for (var i = 0; i < outcomes.length; i++)
        if (outcomes[i] is Ok<DiscountResult>) i,
    ];
    _comparable = validIdx.length >= minOffers;
    int? best;
    if (_comparable) {
      final local = _calculator.cheapestIndex(
          validIdx.map((i) => outcomes[i]!.valueOrNull!).toList());
      best = validIdx[local!];
    }
    _evaluations = [
      for (var i = 0; i < outcomes.length; i++)
        _evaluation(outcomes[i], i, best, outcomes),
    ];
    notifyListeners();
  }

  OfferEvaluation _evaluation(Outcome<DiscountResult>? o, int i, int? best,
      List<Outcome<DiscountResult>?> all) {
    final r = o?.valueOrNull;
    if (best == null || r == null) {
      return OfferEvaluation(outcome: o, isCheapest: false);
    }
    final bestPrice = all[best]!.valueOrNull!.finalPrice;
    final diff = r.finalPrice - bestPrice;
    return OfferEvaluation(
      outcome: o,
      isCheapest: i == best,
      nominalDifference: diff,
      percentDifference:
          r.finalPrice == decZero ? decZero : divide(diff * decHundred, r.finalPrice),
    );
  }
}
