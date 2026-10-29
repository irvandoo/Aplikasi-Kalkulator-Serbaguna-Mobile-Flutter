import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models.dart';
import '../../data/shopping_repository.dart';
import '../../domain/shopping_calculator.dart';

/// State for the shopping screen: the open list, its items and totals.
/// Every mutation is persisted immediately; mutators return an error message
/// (null on success) so the UI can show it without crashing.
class ShoppingViewModel extends ChangeNotifier {
  ShoppingViewModel(this._repo, {ShoppingCalculator? calculator})
      : _calculator = calculator ?? const ShoppingCalculator();

  static const String lastListKey = 'last_shopping_list_id';
  static const String defaultListName = 'Belanja Mingguan';
  static const String storageError = 'Data belanja tidak dapat disimpan';

  final ShoppingRepository _repo;
  final ShoppingCalculator _calculator;

  ShoppingList? _current;
  bool _loading = true;
  String? _loadError;

  ShoppingList? get current => _current;
  bool get loading => _loading;
  String? get loadError => _loadError;
  List<ShoppingItem> get items => _current?.items ?? const [];

  ShoppingTotals get totals => _calculator.totals(
        items.map((i) => i.data).toList(),
        budget: _current?.budget,
      );

  /// Opens [listId] (or the remembered list, or the first list, creating a
  /// default one when none exists).
  Future<void> init({String? listId}) async {
    _loading = true;
    notifyListeners();
    try {
      var id = listId ?? await _readLastId();
      ShoppingList? list = id == null ? null : await _repo.byId(id);
      if (list == null) {
        final all = await _repo.lists();
        list = all.isEmpty ? null : all.first;
      }
      if (list == null) {
        list = ShoppingList(name: defaultListName);
        await _repo.saveList(list);
      }
      _current = list;
      _loadError = null;
      await _rememberId(list.id);
    } catch (e, st) {
      debugPrint('Shopping init failed: $e\n$st');
      _loadError = 'Daftar belanja tidak dapat dimuat';
    }
    _loading = false;
    notifyListeners();
  }

  Future<String?> _reloadCurrent() async {
    final id = _current?.id;
    if (id == null) return null;
    try {
      final fresh = await _repo.byId(id);
      if (fresh != null) _current = fresh;
      notifyListeners();
      return null;
    } catch (_) {
      return storageError;
    }
  }

  Future<String?> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on ValidationException catch (e) {
      return e.message;
    } catch (_) {
      return storageError;
    }
    return _reloadCurrent();
  }

  Future<String?> addItem({
    required String name,
    required Decimal unitPrice,
    required Decimal quantity,
    Decimal? discountPercent,
  }) {
    final list = _current;
    if (list == null) return Future.value(storageError);
    return _guard(() => _repo.saveItem(ShoppingItem(
          listId: list.id,
          name: name.trim(),
          unitPrice: unitPrice,
          quantity: quantity,
          discountPercent: discountPercent,
        )));
  }

  Future<String?> updateItem(
    ShoppingItem item, {
    required String name,
    required Decimal unitPrice,
    required Decimal quantity,
    Decimal? discountPercent,
  }) =>
      _guard(() => _repo.saveItem(item.copyWith(
            name: name.trim(),
            unitPrice: unitPrice,
            quantity: quantity,
            discountPercent: discountPercent,
            clearDiscount: discountPercent == null,
          )));

  Future<String?> setQuantity(ShoppingItem item, Decimal quantity) =>
      _guard(() => _repo.saveItem(item.copyWith(quantity: quantity)));

  Future<String?> togglePurchased(ShoppingItem item) => _guard(
      () => _repo.saveItem(item.copyWith(isPurchased: !item.isPurchased)));

  Future<String?> deleteItem(ShoppingItem item) =>
      _guard(() => _repo.deleteItem(item.id));

  Future<String?> resetPurchased() {
    final list = _current;
    if (list == null) return Future.value(null);
    return _guard(() => _repo.resetPurchased(list.id));
  }

  /// Sets the budget; null clears it.
  Future<String?> setBudget(Decimal? budget) {
    final list = _current;
    if (list == null) return Future.value(storageError);
    return _guard(() => _repo.saveList(
        list.copyWith(budget: budget, clearBudget: budget == null)));
  }

  Future<String?> _readLastId() async {
    try {
      return (await SharedPreferences.getInstance()).getString(lastListKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _rememberId(String id) async {
    try {
      await (await SharedPreferences.getInstance())
          .setString(lastListKey, id);
    } catch (_) {}
  }
}
