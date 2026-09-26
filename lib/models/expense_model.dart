import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'identifiable.dart';

/// A spending category. The built-in choices are only suggestions: users may
/// type a category of their own, which is saved with the expense and becomes a
/// suggestion in future entries.
@immutable
class ExpenseCategory {
  const ExpenseCategory._(this.name, this.label);

  static const makan = ExpenseCategory._('makan', 'Makan');
  static const minyak = ExpenseCategory._('minyak', 'Minyak');
  static const bil = ExpenseCategory._('bil', 'Bil');
  static const barangDapur = ExpenseCategory._('barangDapur', 'Barang Dapur');
  static const beliBelah = ExpenseCategory._('beliBelah', 'Beli-belah');
  static const lainLain = ExpenseCategory._('lainLain', 'Lain-lain');

  static const values = [makan, minyak, bil, barangDapur, beliBelah, lainLain];

  /// Stable key for built-ins and a normalised key for user-created names.
  final String name;
  final String label;

  bool get isCustom => !values.any((category) => category.name == name);

  /// The original category names are kept for backward-compatible storage.
  String get storageValue => isCustom ? label : name;

  factory ExpenseCategory.fromName(String? name) {
    final value = name?.trim() ?? '';
    for (final category in values) {
      if (category.name == value) return category;
    }
    return ExpenseCategory.fromLabel(value);
  }

  factory ExpenseCategory.fromLabel(String label) {
    final value = label.trim();
    if (value.isEmpty) return lainLain;
    final normalised = value.toLowerCase();
    for (final category in values) {
      if (category.label.toLowerCase() == normalised) return category;
    }
    return ExpenseCategory._('custom:$normalised', value);
  }

  @override
  bool operator ==(Object other) =>
      other is ExpenseCategory && other.name == name;

  @override
  int get hashCode => name.hashCode;
}

@immutable
class ExpenseModel implements Identifiable {
  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.account = '',
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) => ExpenseModel(
    id: map['id'] as String,
    title: map['title'] as String? ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0,
    category: ExpenseCategory.fromName(map['category'] as String?),
    date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
    account: map['account'] as String? ?? '',
  );

  factory ExpenseModel.fromJson(String json) =>
      ExpenseModel.fromMap(jsonDecode(json) as Map<String, dynamic>);

  @override
  final String id;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;

  /// The money source used for this expense, e.g. Maybank or TNG.
  /// Empty values are records created before account tracking was added.
  final String account;

  ExpenseModel copyWith({
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? account,
  }) => ExpenseModel(
    id: id,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    date: date ?? this.date,
    account: account ?? this.account,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category.storageValue,
    'date': date.toIso8601String(),
    'account': account,
  };

  String toJson() => jsonEncode(toMap());

  @override
  bool operator ==(Object other) =>
      other is ExpenseModel &&
      other.id == id &&
      other.title == title &&
      other.amount == amount &&
      other.category == category &&
      other.date == date &&
      other.account == account;

  @override
  int get hashCode => Object.hash(id, title, amount, category, date, account);
}
