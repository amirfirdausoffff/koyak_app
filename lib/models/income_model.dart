import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'identifiable.dart';
import 'income_entry.dart';

@immutable
class IncomeModel implements Identifiable {
  const IncomeModel({
    required this.id,
    required this.source,
    required this.amount,
    required this.date,
    this.entries = const [],
  });

  factory IncomeModel.fromMap(Map<String, dynamic> map) => IncomeModel(
    id: map['id'] as String,
    source: map['source'] as String? ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0,
    date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
    entries:
        (map['entries'] as List<dynamic>?)
            ?.whereType<Map<dynamic, dynamic>>()
            .map(
              (entry) => IncomeEntry.fromMap(Map<String, dynamic>.from(entry)),
            )
            .toList() ??
        const [],
  );

  factory IncomeModel.fromJson(String json) =>
      IncomeModel.fromMap(jsonDecode(json) as Map<String, dynamic>);

  @override
  final String id;
  final String source;
  final double amount;
  final DateTime date;

  /// Individual deposits. Old saved sources have no entries; [historyEntries]
  /// turns their original amount into one compatible first deposit.
  final List<IncomeEntry> entries;

  List<IncomeEntry> get historyEntries =>
      entries.isEmpty ? [IncomeEntry(amount: amount, date: date)] : entries;

  IncomeModel copyWith({
    String? source,
    double? amount,
    DateTime? date,
    List<IncomeEntry>? entries,
  }) => IncomeModel(
    id: id,
    source: source ?? this.source,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    entries: entries ?? this.entries,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'source': source,
    'amount': amount,
    'date': date.toIso8601String(),
    'entries': entries.map((entry) => entry.toMap()).toList(),
  };

  String toJson() => jsonEncode(toMap());

  @override
  bool operator ==(Object other) =>
      other is IncomeModel &&
      other.id == id &&
      other.source == source &&
      other.amount == amount &&
      other.date == date &&
      listEquals(other.entries, entries);

  @override
  int get hashCode =>
      Object.hash(id, source, amount, date, Object.hashAll(entries));
}
