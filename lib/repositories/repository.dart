/// Storage abstraction the view models depend on, so the storage engine can
/// change (or be faked in tests) without touching business logic.
abstract interface class Repository<T> {
  Future<List<T>> fetchAll();

  Future<void> saveAll(List<T> items);
}
