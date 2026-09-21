import '../services/preference_service.dart';
import 'repository.dart';

/// Persists a list of [T] as a JSON array under one preference key.
class LocalRepository<T> implements Repository<T> {
  LocalRepository({
    required this._storage,
    required this._storageKey,
    required this._fromMap,
    required this._toMap,
  });

  final PreferenceService _storage;
  final String _storageKey;
  final T Function(Map<String, dynamic> map) _fromMap;
  final Map<String, dynamic> Function(T item) _toMap;

  @override
  Future<List<T>> fetchAll() async {
    final items = <T>[];
    for (final map in _storage.readJsonList(_storageKey)) {
      try {
        items.add(_fromMap(map));
      } catch (_) {
        // Skip a corrupted entry rather than losing the whole list.
      }
    }
    return items;
  }

  @override
  Future<void> saveAll(List<T> items) =>
      _storage.writeJsonList(_storageKey, items.map(_toMap).toList());
}
