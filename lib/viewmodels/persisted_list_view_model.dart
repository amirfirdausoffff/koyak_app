import 'package:flutter/foundation.dart';

import '../models/identifiable.dart';
import '../repositories/repository.dart';

/// Shared list state + persistence for the record-keeping view models.
/// Updates are optimistic: the UI changes first, then storage is written.
abstract class PersistedListViewModel<T extends Identifiable>
    extends ChangeNotifier {
  PersistedListViewModel(this._repository);

  final Repository<T> _repository;
  List<T> _items = const [];
  bool _isLoaded = false;
  bool _isDisposed = false;

  bool get isLoaded => _isLoaded;

  @protected
  List<T> get items => _items;

  Future<void> load() async {
    _items = List.unmodifiable(await _repository.fetchAll());
    _isLoaded = true;
    _notify();
  }

  /// Adds [item], or replaces the stored record with the same id.
  Future<void> upsert(T item) {
    final next = [..._items];
    final index = next.indexWhere((e) => e.id == item.id);
    if (index == -1) {
      next.add(item);
    } else {
      next[index] = item;
    }
    return commit(next);
  }

  Future<void> remove(String id) =>
      commit(_items.where((e) => e.id != id).toList());

  Future<void> clear() => commit(const []);

  /// Rebuilds listeners without changing data, e.g. when the day (and so
  /// the current month) may have changed while the app was in background.
  void refresh() => _notify();

  @protected
  Future<void> commit(List<T> next) async {
    _items = List.unmodifiable(next);
    _notify();
    await _repository.saveAll(_items);
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
