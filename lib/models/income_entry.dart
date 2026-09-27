import 'package:flutter/foundation.dart';

/// One recorded deposit into a money source.
@immutable
class IncomeEntry {
  const IncomeEntry({required this.amount, required this.date});

  factory IncomeEntry.fromMap(Map<String, dynamic> map) => IncomeEntry(
    amount: (map['amount'] as num?)?.toDouble() ?? 0,
    date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
  );

  final double amount;
  final DateTime date;

  Map<String, dynamic> toMap() => {
    'amount': amount,
    'date': date.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is IncomeEntry && other.amount == amount && other.date == date;

  @override
  int get hashCode => Object.hash(amount, date);
}
