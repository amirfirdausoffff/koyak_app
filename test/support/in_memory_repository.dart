import 'package:koyak/repositories/repository.dart';

class InMemoryRepository<T> implements Repository<T> {
  InMemoryRepository([List<T> seed = const []]) : saved = [...seed];

  List<T> saved;

  @override
  Future<List<T>> fetchAll() async => [...saved];

  @override
  Future<void> saveAll(List<T> items) async => saved = [...items];
}
