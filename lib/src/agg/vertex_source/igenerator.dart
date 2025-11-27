import '../../shared/ref_param.dart';
import 'path_commands.dart';
import 'stroke_math.dart';

abstract class IGenerator {
  double get approximationScale;
  set approximationScale(double value);

  bool get autoDetectOrientation;
  set autoDetectOrientation(bool value);

  InnerJoin get innerJoin;
  set innerJoin(InnerJoin value);

  double get innerMiterLimit;
  set innerMiterLimit(double value);

  LineCap get lineCap;
  set lineCap(LineCap value);

  LineJoin get lineJoin;
  set lineJoin(LineJoin value);

  double get miterLimit;
  set miterLimit(double value);

  void miterLimitTheta(double t);

  double get shorten;
  set shorten(double value);

  double get width;
  set width(double value);

  void removeAll();
  void rewind(int pathId);
  void addVertex(double x, double y, FlagsAndCommand cmd);

  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y);
}
