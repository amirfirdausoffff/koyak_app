import 'core/constants/storage_keys.dart';
import 'models/debt_model.dart';
import 'models/expense_model.dart';
import 'models/income_model.dart';
import 'repositories/backup_repository.dart';
import 'repositories/local_repository.dart';
import 'repositories/repository.dart';
import 'services/preference_service.dart';

/// Composition root: which storage backs each repository.
class AppDependencies {
  const AppDependencies({
    required this.incomeRepository,
    required this.debtRepository,
    required this.expenseRepository,
    required this.backupRepository,
  });

  /// 100% offline — everything lives in the phone's SharedPreferences.
  factory AppDependencies.local(PreferenceService storage) => AppDependencies(
    incomeRepository: LocalRepository(
      storage: storage,
      storageKey: StorageKeys.incomes,
      fromMap: IncomeModel.fromMap,
      toMap: (income) => income.toMap(),
    ),
    debtRepository: LocalRepository(
      storage: storage,
      storageKey: StorageKeys.debts,
      fromMap: DebtModel.fromMap,
      toMap: (debt) => debt.toMap(),
    ),
    expenseRepository: LocalRepository(
      storage: storage,
      storageKey: StorageKeys.expenses,
      fromMap: ExpenseModel.fromMap,
      toMap: (expense) => expense.toMap(),
    ),
    backupRepository: BackupRepository(storage: storage),
  );

  final Repository<IncomeModel> incomeRepository;
  final Repository<DebtModel> debtRepository;
  final Repository<ExpenseModel> expenseRepository;
  final BackupRepository backupRepository;
}
