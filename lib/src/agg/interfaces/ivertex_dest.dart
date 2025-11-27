import 'package:vector_math/vector_math.dart';

abstract class IVertexDest {
  void clear();
  int get count;
  void add(Vector2 vertex);
}
