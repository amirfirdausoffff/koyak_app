/// Keys for data kept in the phone's local cache (no backend).
abstract final class StorageKeys {
  static const incomes = 'koyak.incomes';
  static const debts = 'koyak.debts';
  static const expenses = 'koyak.expenses';

  static const autoBackupEnabled = 'koyak.backup.auto_enabled';
  static const backupAccountEmail = 'koyak.backup.account_email';
  static const lastBackupAt = 'koyak.backup.last_at';

  /// User records — what a backup file carries.
  static const data = {incomes, debts, expenses};

  static const all = {
    ...data,
    autoBackupEnabled,
    backupAccountEmail,
    lastBackupAt,
  };
}
