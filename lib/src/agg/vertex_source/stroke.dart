import 'ivertex_source.dart';
import 'stroke_generator.dart';
import 'stroke_math.dart';
import 'vertex_source_adapter.dart';

class Stroke extends VertexSourceAdapter {
  Stroke(IVertexSource vertexSource, [double inWidth = 1])
      : super(vertexSource, StrokeGenerator()) {
    width = inWidth;
  }

  double get approximationScale => generator.approximationScale;
  set approximationScale(double value) => generator.approximationScale = value;

  InnerJoin get innerJoin => generator.innerJoin;
  set innerJoin(InnerJoin value) => generator.innerJoin = value;

  double get innerMiterLimit => generator.innerMiterLimit;
  set innerMiterLimit(double value) => generator.innerMiterLimit = value;

  LineCap get lineCap => generator.lineCap;
  set lineCap(LineCap value) => generator.lineCap = value;

  LineJoin get lineJoin => generator.lineJoin;
  set lineJoin(LineJoin value) => generator.lineJoin = value;

  double get miterLimit => generator.miterLimit;
  set miterLimit(double value) => generator.miterLimit = value;

  double get shorten => generator.shorten;
  set shorten(double value) => generator.shorten = value;

  double get width => generator.width;
  set width(double value) => generator.width = value;

  void miterLimitTheta(double t) {
    generator.miterLimitTheta(t);
  }
}
