import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../models/income_model.dart';
import '../../viewmodels/income_view_model.dart';
import '../shared/widgets/amount_field.dart';
import '../shared/widgets/koyak_sheet.dart';

Future<void> showIncomeSheet(BuildContext context) => showKoyakSheet<void>(
  context,
  title: 'Pendapatan ${DateFormatter.month(DateTime.now())}',
  builder: (_) => const IncomeSheet(),
);

class IncomeSheet extends StatefulWidget {
  const IncomeSheet({super.key});

  @override
  State<IncomeSheet> createState() => _IncomeSheetState();
}

class _IncomeSheetState extends State<IncomeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _source = TextEditingController();
  final _amount = TextEditingController();

  @override
  void dispose() {
    _source.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount = CurrencyFormatter.parse(_amount.text)!;
    await context.read<IncomeViewModel>().add(
      source: _source.text,
      amount: amount,
    );
    if (!mounted) return;
    _source.clear();
    _amount.clear();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<IncomeViewModel>();
    final incomes = vm.incomes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (incomes.isEmpty)
          const Text(
            'Belum ada pendapatan. Tambah gaji kat bawah.',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else ...[
          for (final income in incomes)
            _IncomeRow(income: income, onDelete: () => vm.remove(income.id)),
          const Divider(height: 24),
          Row(
            children: [
              const Text(
                'Jumlah',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const Spacer(),
              Text(
                vm.total.asRinggit,
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _source,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Sumber (cth: Gaji, Side income)',
                ),
              ),
              const SizedBox(height: 10),
              AmountField(
                controller: _amount,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Tambah Pendapatan'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IncomeRow extends StatelessWidget {
  const _IncomeRow({required this.income, required this.onDelete});

  final IncomeModel income;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  income.source,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  DateFormatter.full(income.date),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            income.amount.asRinggit,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: 'Padam',
            icon: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
