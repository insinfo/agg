import 'package:agg/src/agg/agg_math.dart';

/// Vertex (x, y) with distance to next vertex; implements [XY] for area helpers.
class VertexDistance implements XY {
  @override
  double x;
  @override
  double y;
  double dist;

  VertexDistance(this.x, this.y) : dist = 0.0;

  /// Returns true if the distance to [val] exceeds the epsilon; updates [dist].
  bool isEqual(VertexDistance val) {
    final bool ret = (dist = AggMath.CalcDistance(x, y, val.x, val.y)) >
        AggMath.vertex_dist_epsilon;
    if (!ret) dist = 1.0 / AggMath.vertex_dist_epsilon;
    return ret;
  }
}

/// Container behaving like the C# VectorPOD-based vertex_sequence.
class VertexSequence {
  final List<VertexDistance> _items = <VertexDistance>[];

  int get length => _items.length;

  VertexDistance operator [](int index) => _items[index];

  void operator []=(int index, VertexDistance value) {
    _items[index] = value;
  }

  void add(VertexDistance val) {
    if (_items.length > 1) {
      if (!_items[_items.length - 2].isEqual(_items[_items.length - 1])) {
        _items.removeLast();
      }
    }
    _items.add(val);
  }

  void modifyLast(VertexDistance val) {
    _items.removeLast();
    add(val);
  }

  void close(bool closed) {
    while (_items.length > 1) {
      if (_items[_items.length - 2].isEqual(_items[_items.length - 1])) break;
      final VertexDistance t = this[_items.length - 1];
      _items.removeLast();
      modifyLast(t);
    }

    if (closed) {
      while (_items.length > 1) {
        if (_items[_items.length - 1].isEqual(_items[0])) break;
        _items.removeLast();
      }
    }
  }

  VertexDistance prev(int idx) {
    return this[(idx + _items.length - 1) % _items.length];
  }

  VertexDistance curr(int idx) {
    return this[idx];
  }

  VertexDistance next(int idx) {
    return this[(idx + 1) % _items.length];
  }
}
