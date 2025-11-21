import 'package:agg/src/agg/primitives/color.dart';

/// Reusable span buffer for color-based rendering.
class SpanAllocator {
  final List<Color> _span;
  int _capacity;

  SpanAllocator([int initialCapacity = 256])
      : _capacity = initialCapacity,
        _span = List<Color>.generate(initialCapacity, (_) => Color(0, 0, 0, 0));

  /// Ensures at least [spanLen] slots and returns the reusable buffer.
  List<Color> allocate(int spanLen) {
    if (spanLen > _capacity) {
      _capacity = ((spanLen + 255) >> 8) << 8; // align to 256 like AGG
      final needed = _capacity - _span.length;
      for (int i = 0; i < needed; i++) {
        _span.add(Color(0, 0, 0, 0));
      }
    }
    return _span;
  }

  List<Color> get span => _span;

  int maxSpanLen() => _capacity;
}
