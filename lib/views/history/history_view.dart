import 'package:flutter/material.dart';

import 'month_history_list.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const HistoryView()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sejarah Bulanan')),
      body: const SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: MonthHistoryList(),
        ),
      ),
    );
  }
}
