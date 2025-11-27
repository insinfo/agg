import 'package:vector_math/vector_math.dart';
import '../glyph.dart';

class TouchState {
  static const int none = 0;
  static const int x = 0x1;
  static const int y = 0x2;
  static const int both = x | y;
}

class Zone {
  final List<GlyphPointF> current;
  final List<GlyphPointF> original;
  final List<int> touchState;
  final bool isTwilight;

  Zone(List<GlyphPointF> points, {required this.isTwilight})
      : current = points,
        original = points.map((p) => GlyphPointF(p.x, p.y, p.onCurve)).toList(),
        touchState = List<int>.filled(points.length, TouchState.none);

  Vector2 getCurrent(int index) => Vector2(current[index].x, current[index].y);
  Vector2 getOriginal(int index) => Vector2(original[index].x, original[index].y);
}
