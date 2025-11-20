import 'rectangle_int.dart';

class RectangleDouble {
  double left;
  double bottom;
  double right;
  double top;

  RectangleDouble(this.left, this.bottom, this.right, this.top);

  RectangleDouble.fromRect(RectangleInt rect)
      : left = rect.left.toDouble(),
        bottom = rect.bottom.toDouble(),
        right = rect.right.toDouble(),
        top = rect.top.toDouble();

  double get height => top - bottom;
  double get width => right - left;

  double get centerX => (left + right) / 2.0;
  double get centerY => (bottom + top) / 2.0;

  void normalize() {
    if (left > right) {
      double temp = left;
      left = right;
      right = temp;
    }
    if (bottom > top) {
      double temp = bottom;
      bottom = top;
      top = temp;
    }
  }

  bool clip(RectangleDouble r) {
    if (right < r.left || left > r.right || top < r.bottom || bottom > r.top) {
      left = right = bottom = top = 0;
      return false;
    }

    if (left < r.left) left = r.left;
    if (right > r.right) right = r.right;
    if (bottom < r.bottom) bottom = r.bottom;
    if (top > r.top) top = r.top;

    return true;
  }

  bool contains(double x, double y) {
    return x >= left && x <= right && y >= bottom && y <= top;
  }

  void expand(double v) {
    left -= v;
    bottom -= v;
    right += v;
    top += v;
  }

  void intersectWith(RectangleDouble other) {
    if (left < other.left) left = other.left;
    if (bottom < other.bottom) bottom = other.bottom;
    if (right > other.right) right = other.right;
    if (top > other.top) top = other.top;

    // If empty
    if (left > right || bottom > top) {
      left = right = bottom = top = 0;
    }
  }

  void unionWith(RectangleDouble other) {
    if (other.left == 0 &&
        other.right == 0 &&
        other.bottom == 0 &&
        other.top == 0) return;
    if (left == 0 && right == 0 && bottom == 0 && top == 0) {
      left = other.left;
      bottom = other.bottom;
      right = other.right;
      top = other.top;
      return;
    }

    if (left > other.left) left = other.left;
    if (bottom > other.bottom) bottom = other.bottom;
    if (right < other.right) right = other.right;
    if (top < other.top) top = other.top;
  }

  @override
  String toString() => 'RectangleDouble($left, $bottom, $right, $top)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RectangleDouble &&
        other.left == left &&
        other.bottom == bottom &&
        other.right == right &&
        other.top == top;
  }

  @override
  int get hashCode => Object.hash(left, bottom, right, top);
}
