/// Simple contract for 2D transforms that can map a point.
abstract class ITransform {
  /// Transform a point and return the mapped coordinates.
  ({double x, double y}) transform(double x, double y);
}
