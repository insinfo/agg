import 'package:vector_math/vector_math.dart';
import '../interfaces/ivertex_dest.dart';

class Vector2Container implements IVertexDest {
  final List<Vector2> _items = <Vector2>[];

  @override
  void clear() {
    _items.clear();
  }

  @override
  int get count => _items.length;

  @override
  void add(Vector2 vertex) {
    _items.add(vertex);
  }

  Vector2 operator [](int index) => _items[index];
}
