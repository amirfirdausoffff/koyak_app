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

/// How often a debt is paid.
enum DebtKind {
  /// Every month (PTPTN, kereta), optionally until [DebtModel.lastMonth].
  monthly('Bulanan'),

  /// Paid once (hutang kawan).
  once('Sekali je');

  const DebtKind(this.label);

  final String label;

  static DebtKind fromName(String? name) =>
      values.asNameMap()[name] ?? DebtKind.monthly;
}

/// A debt counted in the monthly baki.
///
/// A [DebtKind.monthly] debt is a commitment: [amount] is the monthly
/// payment and it counts from the month of [createdAt] through [lastMonth]
/// (or until it is ended). Payment status is kept per month in [payments],
/// so every month starts unpaid on its own and past months keep their record.
///
/// A [DebtKind.once] debt counts in its start month only. Left unpaid, it
/// stays on the list as tertunggak in later months, without counting in
/// their baki again, until the month it is paid.
@immutable
class DebtModel implements Identifiable {
  const DebtModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.createdAt,
    this.kind = DebtKind.monthly,
    this.dueDate,
    this.lastMonth,
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
      kind: DebtKind.fromName(map['kind'] as String?),
      dueDate: DateTime.tryParse(map['dueDate'] as String? ?? ''),
      lastMonth: YearMonth.tryParse(map['lastMonth'] as String? ?? ''),
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
  final DebtKind kind;

  /// Monthly: only its day matters, the debt is due on that day every month.
  /// Once: the actual date.
  final DateTime? dueDate;

  /// The last month a monthly debt is paid; null means no end date.
  final YearMonth? lastMonth;

  /// Month key (`2026-09`) → amount paid that month. A one-off debt has at
  /// most one entry: the month it was paid in.
  final Map<String, double> payments;

  /// When the user removed it; it no longer counts from that month on.
  final DateTime? endedAt;

  bool get isOnce => kind == DebtKind.once;

  /// A v1.0.0 record whose real start month is unknown.
  bool get isLegacy => createdAt == legacyStart;

  YearMonth get startMonth => YearMonth.of(createdAt);

  /// The last month this debt counts in: its start month for a one-off,
  /// otherwise [lastMonth], cut short if it was ended earlier. Null while a
  /// monthly debt has no end.
  YearMonth? get finalMonth {
    final ended = endedAt;
    final beforeEnd = ended == null ? null : YearMonth.of(ended).previous;
    final planned = isOnce ? startMonth : lastMonth;
    if (planned == null || beforeEnd == null) return planned ?? beforeEnd;
    return beforeEnd.isBefore(planned) ? beforeEnd : planned;
  }

  /// How many monthly payments it ran for; null for a one-off, a legacy
  /// record, or a debt with no end yet.
  int? get scheduledPayments {
    final last = finalMonth;
    if (isOnce || isLegacy || last == null) return null;
    return last.compareTo(startMonth) + 1;
  }

  double get totalPaid => payments.values.fold(0, (sum, paid) => sum + paid);

  /// The month a one-off debt was paid in, if it has been.
  YearMonth? get paidMonth {
    if (!isOnce) return null;
    final months = payments.keys.map(YearMonth.tryParse).nonNulls;
    return months.isEmpty
        ? null
        : months.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  bool _isEndedBy(YearMonth month) {
    final ended = endedAt;
    return ended != null && !month.isBefore(YearMonth.of(ended));
  }

  /// Whether this debt counts in [month]'s baki.
  bool isActiveIn(YearMonth month) {
    if (month.isBefore(startMonth) || _isEndedBy(month)) return false;
    if (isOnce) return month == startMonth;
    final last = lastMonth;
    return last == null || !last.isBefore(month);
  }

  /// A one-off debt from an earlier month, still listed in [month] because
  /// it was unpaid when the month began. It already counted in its own
  /// month's baki, so it doesn't count again.
  bool isOverdueIn(YearMonth month) {
    if (!isOnce || !startMonth.isBefore(month) || _isEndedBy(month)) {
      return false;
    }
    final paid = paidMonth;
    return paid == null || !paid.isBefore(month);
  }

  /// A one-off debt counts as paid from the month it was paid in onwards.
  bool isPaidIn(YearMonth month) {
    if (!isOnce) return payments.containsKey(month.key);
    final paid = paidMonth;
    return paid != null && !month.isBefore(paid);
  }

  /// What [month] cost: the recorded payment, else the current [amount].
  double amountIn(YearMonth month) =>
      (isOnce ? payments.values.firstOrNull : payments[month.key]) ?? amount;

  /// Payments still due on a monthly debt with an end date, counting
  /// [month]'s own unless it's paid. Null without an end date.
  int? paymentsLeftIn(YearMonth month) {
    final last = lastMonth;
    if (isOnce || last == null) return null;
    final left = last.compareTo(month) + (isPaidIn(month) ? 0 : 1);
    return math.max(left, 0);
  }

  /// This debt's due date within [month] (the 31st becomes 30 Sep, 28 Feb).
  /// A one-off debt keeps its own date.
  DateTime? dueDateIn(YearMonth month) {
    final due = dueDate;
    if (due == null) return null;
    if (isOnce) return DateTime(due.year, due.month, due.day);
    return DateTime(month.year, month.month, math.min(due.day, month.dayCount));
  }

  /// Days until this month's due date (0 = today, negative = overdue).
  int? daysUntilDue(DateTime today) {
    final due = dueDateIn(YearMonth.of(today));
    return due == null ? null : DateHelper.daysBetween(today, due);
  }

  DebtModel togglePaidIn(YearMonth month) {
    if (isOnce) {
      return _copy(payments: isPaidIn(month) ? const {} : {month.key: amount});
    }
    final next = Map<String, double>.of(payments);
    if (next.remove(month.key) == null) next[month.key] = amount;
    return _copy(payments: next);
  }

  DebtModel endedOn(DateTime date) => _copy(endedAt: date);

  DebtModel copyWith({
    String? title,
    double? amount,
    DebtCategory? category,
    DebtKind? kind,
    DateTime? dueDate,
    bool clearDueDate = false,
    YearMonth? lastMonth,
    bool clearLastMonth = false,
  }) => _copy(
    title: title,
    amount: amount,
    category: category,
    kind: kind,
    dueDate: dueDate,
    clearDueDate: clearDueDate,
    lastMonth: lastMonth,
    clearLastMonth: clearLastMonth,
  );

  DebtModel _copy({
    String? title,
    double? amount,
    DebtCategory? category,
    DebtKind? kind,
    DateTime? dueDate,
    bool clearDueDate = false,
    YearMonth? lastMonth,
    bool clearLastMonth = false,
    Map<String, double>? payments,
    DateTime? endedAt,
  }) => DebtModel(
    id: id,
    title: title ?? this.title,
    amount: amount ?? this.amount,
    category: category ?? this.category,
    createdAt: createdAt,
    kind: kind ?? this.kind,
    dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
    lastMonth: clearLastMonth ? null : lastMonth ?? this.lastMonth,
    payments: payments ?? this.payments,
    endedAt: endedAt ?? this.endedAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'category': category.name,
    'createdAt': createdAt.toIso8601String(),
    'kind': kind.name,
    'dueDate': dueDate?.toIso8601String(),
    'lastMonth': lastMonth?.key,
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
      other.kind == kind &&
      other.dueDate == dueDate &&
      other.lastMonth == lastMonth &&
      mapEquals(other.payments, payments) &&
      other.endedAt == endedAt;

  @override
  int get hashCode => Object.hash(
    id,
    title,
    amount,
    category,
    createdAt,
    kind,
    dueDate,
    lastMonth,
    Object.hashAllUnordered(payments.entries.map((e) => (e.key, e.value))),
    endedAt,
  );
}
