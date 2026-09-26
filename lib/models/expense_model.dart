import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'identifiable.dart';

enum ExpenseCategory {
  makan('Makan'),
  minyak('Minyak'),
  bil('Bil'),
  barangDapur('Barang Dapur'),
  beliBelah('Beli-belah'),
  lainLain('Lain-lain');

  const ExpenseCategory(this.label);

  final String label;

  static ExpenseCategory fromName(String? name) =>
      values.asNameMap()[name] ?? ExpenseCategory.lainLain;
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
    'category': category.name,
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
