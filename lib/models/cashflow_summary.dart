import 'dart:convert';

import 'package:flutter/foundation.dart';

/// One month's money:
/// Baki bulan lepas + Duit masuk − Hutang − Belanja = Baki.
@immutable
class CashflowSummary {
  const CashflowSummary({
    required this.totalIncome,
    required this.totalDebt,
    required this.totalExpense,
    required this.netRemaining,
    required this.dailyLimit,
    required this.daysRemaining,
    this.carriedForward = 0,
  });

  factory CashflowSummary.fromMap(Map<String, dynamic> map) => CashflowSummary(
    totalIncome: (map['totalIncome'] as num?)?.toDouble() ?? 0,
    totalDebt: (map['totalDebt'] as num?)?.toDouble() ?? 0,
    totalExpense: (map['totalExpense'] as num?)?.toDouble() ?? 0,
    netRemaining: (map['netRemaining'] as num?)?.toDouble() ?? 0,
    dailyLimit: (map['dailyLimit'] as num?)?.toDouble() ?? 0,
    daysRemaining: map['daysRemaining'] as int? ?? 0,
    carriedForward: (map['carriedForward'] as num?)?.toDouble() ?? 0,
  );

  factory CashflowSummary.fromJson(String json) =>
      CashflowSummary.fromMap(jsonDecode(json) as Map<String, dynamic>);

  static const empty = CashflowSummary(
    totalIncome: 0,
    totalDebt: 0,
    totalExpense: 0,
    netRemaining: 0,
    dailyLimit: 0,
    daysRemaining: 0,
  );

  final double totalIncome;
  final double totalDebt;
  final double totalExpense;

  /// Baki left over from the previous month (negative if it overspent).
  final double carriedForward;

  /// Baki Duit Semasa.
  final double netRemaining;

  /// Had Belanja Harian (RM/hari).
  final double dailyLimit;

  /// Days left in the month, today included.
  final int daysRemaining;

  /// Money to work with this month: last month's baki plus this month's pay.
  double get available => carriedForward + totalIncome;

  /// Cash after this month's recorded spending, before reserving scheduled
  /// debt commitments. This is the amount shown as Duit on the dashboard.
  double get cashOnHand => available - totalExpense;

  /// Anything to budget with — this month's pay or a carried balance.
  bool get hasFunds => totalIncome > 0 || carriedForward != 0;

  /// Spent more than there was.
  bool get isKoyak => netRemaining < 0;

  Map<String, dynamic> toMap() => {
    'totalIncome': totalIncome,
    'totalDebt': totalDebt,
    'totalExpense': totalExpense,
    'carriedForward': carriedForward,
    'netRemaining': netRemaining,
    'dailyLimit': dailyLimit,
    'daysRemaining': daysRemaining,
  };

  String toJson() => jsonEncode(toMap());

  @override
  bool operator ==(Object other) =>
      other is CashflowSummary &&
      other.totalIncome == totalIncome &&
      other.totalDebt == totalDebt &&
      other.totalExpense == totalExpense &&
      other.carriedForward == carriedForward &&
      other.netRemaining == netRemaining &&
      other.dailyLimit == dailyLimit &&
      other.daysRemaining == daysRemaining;

  @override
  int get hashCode => Object.hash(
    totalIncome,
    totalDebt,
    totalExpense,
    carriedForward,
    netRemaining,
    dailyLimit,
    daysRemaining,
  );
}
