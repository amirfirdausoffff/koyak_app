import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/utils/date_helper.dart';
import 'identifiable.dart';
import 'year_month.dart';

enum DebtCategory {
  halal('Halal / Bank', 'Halal'),
  risky('Risiko / Peribadi', 'Risiko');

  const DebtCategory(this.label, this.shortLabel);

  final String label;
  final String shortLabel;

  static DebtCategory fromName(String? name) =>
      values.asNameMap()[name] ?? DebtCategory.halal;
}

/// A recurring monthly commitment. [amount] is the monthly payment.
///
/// Payment status is kept per month in [payments], so every month starts
/// unpaid on its own and past months keep their record. The debt counts
/// from the month of [createdAt] until the month it was ended ([endedAt]).
@immutable
class DebtModel implements Identifiable {
  const DebtModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.createdAt,
    this.dueDate,
    this.payments = const {},
    this.endedAt,
  });

  factory DebtModel.fromMap(Map<String, dynamic> map) {
    final amount = (map['amount'] as num?)?.toDouble() ?? 0;
    return DebtModel(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      amount: amount,
      category: DebtCategory.fromName(map['category'] as String?),
      createdAt:
          DateTime.tryParse(map['createdAt'] as String? ?? '') ?? legacyStart,
      dueDate: DateTime.tryParse(map['dueDate'] as String? ?? ''),
      payments: _paymentsFrom(map, amount),
      endedAt: DateTime.tryParse(map['endedAt'] as String? ?? ''),
    );
  }

  factory DebtModel.fromJson(String json) =>
      DebtModel.fromMap(jsonDecode(json) as Map<String, dynamic>);

  /// v1.0.0 records had no start date; they count in every month.
  static final legacyStart = DateTime(2000);

  @override
  final String id;
  final String title;
  final double amount;
  final DebtCategory category;
  final DateTime createdAt;

  /// Only its day matters: the debt is due on that day every month.
  final DateTime? dueDate;

  /// Month key (`2026-09`) → amount paid that month.
  final Map<String, double> payments;

  /// When the user removed it; it no longer counts from that month on.
  final DateTime? endedAt;

  bool isActiveIn(YearMonth month) {
    final ended = endedAt;
    return !month.isBefore(YearMonth.of(createdAt)) &&
        (ended == null || month.isBefore(YearMonth.of(ended)));
  }

  bool isPaidIn(YearMonth month) => payments.containsKey(month.key);

  /// What [month] cost: the recorded payment, else the current [amount].
  double amountIn(YearMonth month) => payments[month.key] ?? amount;

  /// This debt's due date within [month] (the 31st becomes 30 Sep, 28 Feb).
  DateTime? dueDateIn(YearMonth month) {
    final due = dueDate;
    if (due == null) return null;
    return DateTime(month.year, month.month, math.min(due.day, month.dayCount));
  }

  /// Days until this month's due date (0 = today, negative = overdue).
  int? daysUntilDue(DateTime today) {
    final due = dueDateIn(YearMonth.of(today));
    return due == null ? null : DateHelper.daysBetween(today, due);
  }

  DebtModel togglePaidIn(YearMonth month) {
    final next = Map<String, double>.of(payments);
    if (next.remove(month.key) == null) next[month.key] = amount;
    return _copy(payments: next);
  }

  DebtModel endedOn(DateTime date) => _copy(endedAt: date);

  DebtModel copyWith({
    String? title,
    double? amount,
    DebtCategory? category,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) => _copy(
    title: title,
    amount: amount,
    category: category,
    dueDate: dueDate,
    clearDueDate: clearDueDate,
  );

  DebtModel _copy({
    String? title,
    double? amount,
    DebtCategory? category,
    DateTime? dueDate,
    bool clearDueDate = false,
    Map<String, double>? payments,
    DateTime? endedAt,
  }) => DebtModel(
    id: id,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    createdAt: createdAt,
    dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
    payments: payments ?? this.payments,
    endedAt: endedAt ?? this.endedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category.name,
    'createdAt': createdAt.toIso8601String(),
    'dueDate': dueDate?.toIso8601String(),
    'payments': payments,
    'endedAt': endedAt?.toIso8601String(),
  };

  String toJson() => jsonEncode(toMap());

  static Map<String, double> _paymentsFrom(
    Map<String, dynamic> map,
    double amount,
  ) {
    final raw = map['payments'];
    if (raw is Map) {
      return {
        for (final MapEntry(:key, :value) in raw.entries)
          if (key is String && YearMonth.tryParse(key) != null && value is num)
            key: value.toDouble(),
      };
    }
    // v1.0.0 stored a single `isPaid` flag meaning "paid this month".
    final wasPaid = map['isPaid'] == true;
    return wasPaid ? {YearMonth.of(DateTime.now()).key: amount} : const {};
  }

  @override
  bool operator ==(Object other) =>
      other is DebtModel &&
      other.id == id &&
      other.title == title &&
      other.amount == amount &&
      other.category == category &&
      other.createdAt == createdAt &&
      other.dueDate == dueDate &&
      mapEquals(other.payments, payments) &&
      other.endedAt == endedAt;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    amount,
    category,
    createdAt,
    dueDate,
    Object.hashAllUnordered(payments.entries.map((e) => (e.key, e.value))),
    endedAt,
  );
}
