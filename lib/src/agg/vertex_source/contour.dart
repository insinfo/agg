import 'contour_generator.dart';
import 'ivertex_source.dart';
import 'stroke_math.dart';
import 'vertex_source_adapter.dart';

class Contour extends VertexSourceAdapter {
  Contour(IVertexSource vertexSource)
      : super(vertexSource, ContourGenerator());

  double get approximationScale => generator.approximationScale;
  set approximationScale(double value) => generator.approximationScale = value;

  bool get autoDetectOrientation => generator.autoDetectOrientation;
  set autoDetectOrientation(bool value) => generator.autoDetectOrientation = value;

  InnerJoin get innerJoin => generator.innerJoin;
  set innerJoin(InnerJoin value) => generator.innerJoin = value;

  double get innerMiterLimit => generator.innerMiterLimit;
  set innerMiterLimit(double value) => generator.innerMiterLimit = value;

  LineJoin get lineJoin => generator.lineJoin;
  set lineJoin(LineJoin value) => generator.lineJoin = value;

  double get miterLimit => generator.miterLimit;
  set miterLimit(double value) => generator.miterLimit = value;

  double get width => generator.width;
  set width(double value) => generator.width = value;

  void miterLimitTheta(double t) {
    generator.miterLimitTheta(t);
  }
}
