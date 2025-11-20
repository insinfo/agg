import 'dart:math' as math;

class Point2D {
  double x;
  double y;

  Point2D([this.x = 0.0, this.y = 0.0]);

  Point2D.fromPoint(Point2D other) : x = other.x, y = other.y;

  static double getDistanceBetween(Point2D a, Point2D b) {
    return math.sqrt(getDistanceBetweenSquared(a, b));
  }

  static double getDistanceBetweenSquared(Point2D a, Point2D b) {
    double dx = a.x - b.x;
    double dy = a.y - b.y;
    return dx * dx + dy * dy;
  }

  Point2D operator +(Point2D other) {
    return Point2D(x + other.x, y + other.y);
  }

  Point2D operator -(Point2D other) {
    return Point2D(x - other.x, y - other.y);
  }

  Point2D operator *(dynamic other) {
    if (other is Point2D) {
      return Point2D(x * other.x, y * other.y);
    } else if (other is num) {
      return Point2D(x * other, y * other);
    }
    throw ArgumentError('Operand must be Point2D or number');
  }

  Point2D operator /(dynamic other) {
    if (other is Point2D) {
      return Point2D(x / other.x, y / other.y);
    } else if (other is num) {
      return Point2D(x / other, y / other);
    }
    throw ArgumentError('Operand must be Point2D or number');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Point2D && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Point2D($x, $y)';
}
