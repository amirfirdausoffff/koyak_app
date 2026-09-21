import 'dart:math';

abstract final class IdGenerator {
  static final _random = Random();

  /// Time-ordered, collision-resistant id for locally stored records.
  static String next() {
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final salt = _random.nextInt(1 << 20).toRadixString(36);
    return '$time$salt';
  }
}
