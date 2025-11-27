/// Simple contract for 2D transforms that can map a point.
abstract class ITransform {
  /// Transform a point and return the mapped coordinates.
  void transform(List<double> xy);
}
