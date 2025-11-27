import 'dart:math' as math;

import 'package:agg/src/agg/agg_basics.dart';
import 'package:agg/src/agg/line_aa_basics.dart';

/// Vertex with subpixel x/y and cached length to next vertex.
class LineAAVertex {
  int x;
  int y;
  int len;

  LineAAVertex(this.x, this.y) : len = 0;

  /// Returns true if distance to [val] exceeds threshold; updates [len].
  bool compare(LineAAVertex val) {
    final double dx = (val.x - x).toDouble();
    final double dy = (val.y - y).toDouble();
    len = Agg_basics.uround(math.sqrt(dx * dx + dy * dy));
    return len >
        (LineAABasics.line_subpixel_scale +
            LineAABasics.line_subpixel_scale ~/ 2);
  }
}

/// Container equivalent to AGG/MatterHackers line_aa_vertex_sequence.
class LineAAVertexSequence {
  final List<LineAAVertex> _items = <LineAAVertex>[];

  int get length => _items.length;
  LineAAVertex operator [](int index) => _items[index];

  void add(LineAAVertex val) {
    if (_items.length > 1) {
      if (!_items[_items.length - 2].compare(_items[_items.length - 1])) {
        _items.removeLast();
      }
    }
    _items.add(val);
  }

  void modifyLast(LineAAVertex val) {
    _items.removeLast();
    add(val);
  }

  void close(bool closed) {
    while (_items.length > 1) {
      if (_items[_items.length - 2].compare(_items[_items.length - 1])) break;
      final LineAAVertex t = this[_items.length - 1];
      _items.removeLast();
      modifyLast(t);
    }

    if (closed) {
      while (_items.length > 1) {
        if (_items[_items.length - 1].compare(_items[0])) break;
        _items.removeLast();
      }
    }
  }

  LineAAVertex prev(int idx) => this[(idx + _items.length - 1) % _items.length];
  LineAAVertex curr(int idx) => this[idx];
  LineAAVertex next(int idx) => this[(idx + 1) % _items.length];

  void clear() {
    _items.clear();
  }
}
