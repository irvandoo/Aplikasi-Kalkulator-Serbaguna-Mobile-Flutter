import 'dart:convert';
import 'dart:math';

import 'package:decimal/decimal.dart';

import '../domain/numeric.dart';
import '../domain/shopping_calculator.dart';

final Random _random = Random();

/// Generates a stable, practically-unique identifier (no external package).
String newId() {
  final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final rand = _random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0');
  return '$time$rand';
}

class ValidationException implements Exception {
  const ValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

enum HistoryType {
  calculator('Kalkulator'),
  percentage('Persentase'),
  discount('Diskon'),
  shopping('Belanja'),
  unitPrice('Harga Satuan'),
  billSplit('Patungan');

  const HistoryType(this.label);
  final String label;

  static HistoryType fromName(String name) => HistoryType.values.firstWhere(
        (t) => t.name == name,
        orElse: () => HistoryType.calculator,
      );
}

class HistoryEntry {
  HistoryEntry({
    String? id,
    required this.type,
    required this.title,
    required this.result,
    required this.inputData,
    this.savings,
    DateTime? createdAt,
  })  : id = id ?? newId(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final HistoryType type;

  /// Short description of the calculation (e.g. the expression).
  final String title;

  /// Display-ready result.
  final String result;

  /// Everything needed to reconstruct the calculation.
  final Map<String, dynamic> inputData;

  /// Rupiah saved by this calculation, when applicable (discount/shopping).
  final Decimal? savings;
  final DateTime createdAt;

  String get shareText => '${type.label}: $title\nHasil: $result\n'
      '— Kalkulator Serbaguna';

  Map<String, Object?> toRow() => {
        'id': id,
        'calculation_type': type.name,
        'title': title,
        'input_data': jsonEncode(inputData),
        'result': result,
        'savings': savings?.toString(),
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory HistoryEntry.fromRow(Map<String, Object?> row) {
    Map<String, dynamic> input;
    try {
      input = jsonDecode(row['input_data'] as String) as Map<String, dynamic>;
    } catch (_) {
      input = {};
    }
    return HistoryEntry(
      id: row['id'] as String,
      type: HistoryType.fromName(row['calculation_type'] as String),
      title: row['title'] as String,
      result: row['result'] as String,
      inputData: input,
      savings: tryDec(row['savings'] as String?),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }
}

class ShoppingItem {
  ShoppingItem({
    String? id,
    required this.listId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.discountPercent,
    this.isPurchased = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? newId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String listId;
  final String name;
  final Decimal unitPrice;
  final Decimal quantity;
  final Decimal? discountPercent;
  final bool isPurchased;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingItemData get data => ShoppingItemData(
        unitPrice: unitPrice,
        quantity: quantity,
        discountPercent: discountPercent,
        isPurchased: isPurchased,
      );

  ShoppingItem copyWith({
    String? name,
    Decimal? unitPrice,
    Decimal? quantity,
    Decimal? discountPercent,
    bool clearDiscount = false,
    bool? isPurchased,
  }) =>
      ShoppingItem(
        id: id,
        listId: listId,
        name: name ?? this.name,
        unitPrice: unitPrice ?? this.unitPrice,
        quantity: quantity ?? this.quantity,
        discountPercent:
            clearDiscount ? null : (discountPercent ?? this.discountPercent),
        isPurchased: isPurchased ?? this.isPurchased,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  /// Returns an error message, or null when the item may be persisted.
  static String? validate({
    required String name,
    required Decimal? unitPrice,
    required Decimal? quantity,
    Decimal? discountPercent,
  }) {
    if (name.trim().isEmpty) return 'Nama barang wajib diisi';
    if (name.trim().length > 80) return 'Nama barang maksimal 80 karakter';
    if (unitPrice == null || isNegative(unitPrice)) {
      return 'Harga harus berupa angka 0 atau lebih';
    }
    if (quantity == null || quantity <= decZero) {
      return 'Jumlah harus lebih dari 0';
    }
    if (discountPercent != null &&
        (isNegative(discountPercent) || discountPercent > decHundred)) {
      return 'Diskon harus antara 0% dan 100%';
    }
    return null;
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'shopping_list_id': listId,
        'name': name,
        'unit_price': unitPrice.toString(),
        'quantity': quantity.toString(),
        'discount_percent': discountPercent?.toString(),
        'is_purchased': isPurchased ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  /// Returns null when the row holds corrupt numeric data.
  static ShoppingItem? fromRow(Map<String, Object?> row) {
    final price = tryDec(row['unit_price'] as String?);
    final qty = tryDec(row['quantity'] as String?);
    if (price == null || qty == null) return null;
    return ShoppingItem(
      id: row['id'] as String,
      listId: row['shopping_list_id'] as String,
      name: row['name'] as String,
      unitPrice: price,
      quantity: qty,
      discountPercent: tryDec(row['discount_percent'] as String?),
      isPurchased: (row['is_purchased'] as int) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
    );
  }
}

class ShoppingList {
  ShoppingList({
    String? id,
    required this.name,
    this.budget,
    this.items = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? newId(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  final String name;
  final Decimal? budget;
  final List<ShoppingItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShoppingList copyWith({
    String? name,
    Decimal? budget,
    bool clearBudget = false,
    List<ShoppingItem>? items,
  }) =>
      ShoppingList(
        id: id,
        name: name ?? this.name,
        budget: clearBudget ? null : (budget ?? this.budget),
        items: items ?? this.items,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );

  static String? validate({required String name, Decimal? budget}) {
    if (name.trim().isEmpty) return 'Nama daftar wajib diisi';
    if (name.trim().length > 60) return 'Nama daftar maksimal 60 karakter';
    if (budget != null && isNegative(budget)) {
      return 'Anggaran tidak boleh negatif';
    }
    return null;
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'budget': budget?.toString(),
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  factory ShoppingList.fromRow(
    Map<String, Object?> row, {
    List<ShoppingItem> items = const [],
  }) =>
      ShoppingList(
        id: row['id'] as String,
        name: row['name'] as String,
        budget: tryDec(row['budget'] as String?),
        items: items,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
        updatedAt:
            DateTime.fromMillisecondsSinceEpoch(row['updated_at'] as int),
      );
}
