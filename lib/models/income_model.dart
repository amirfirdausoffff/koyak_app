import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'identifiable.dart';

@immutable
class IncomeModel implements Identifiable {
  const IncomeModel({
    required this.id,
    required this.source,
    required this.amount,
    required this.date,
  });

  factory IncomeModel.fromMap(Map<String, dynamic> map) => IncomeModel(
    id: map['id'] as String,
    source: map['source'] as String? ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0,
    date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
  );

  factory IncomeModel.fromJson(String json) =>
      IncomeModel.fromMap(jsonDecode(json) as Map<String, dynamic>);

  @override
  final String id;
  final String source;
  final double amount;
  final DateTime date;

  IncomeModel copyWith({String? source, double? amount, DateTime? date}) =>
      IncomeModel(
        id: id,
        source: source ?? this.source,
        amount: amount ?? this.amount,
        date: date ?? this.date,
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'source': source,
    'amount': amount,
    'date': date.toIso8601String(),
  };

  String toJson() => jsonEncode(toMap());

  @override
  bool operator ==(Object other) =>
      other is IncomeModel &&
      other.id == id &&
      other.source == source &&
      other.amount == amount &&
      other.date == date;

  @override
  int get hashCode => Object.hash(id, source, amount, date);
}
