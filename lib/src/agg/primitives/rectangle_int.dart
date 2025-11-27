import 'rectangle_double.dart';

class RectangleInt {
  int left;
  int bottom;
  int right;
  int top;

  RectangleInt(this.left, this.bottom, this.right, this.top);

  RectangleInt.fromRect(RectangleDouble rect)
      : left = rect.left.floor(),
        bottom = rect.bottom.floor(),
        right = rect.right.ceil(),
        top = rect.top.ceil();

  int get height => top - bottom;
  int get width => right - left;

  int get centerX => (left + right) ~/ 2;
  int get centerY => (bottom + top) ~/ 2;

  void normalize() {
    if (left > right) {
      int temp = left;
      left = right;
      right = temp;
    }
    if (bottom > top) {
      int temp = bottom;
      bottom = top;
      top = temp;
    }
  }

  bool clip(RectangleInt r) {
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

  bool contains(int x, int y) {
    return x >= left && x <= right && y >= bottom && y <= top;
  }

  void expand(int v) {
    left -= v;
    bottom -= v;
    right += v;
    top += v;
  }

  void expandToInclude(RectangleInt other) {
    unionWith(other);
  }

  void intersectWith(RectangleInt other) {
    if (left < other.left) left = other.left;
    if (bottom < other.bottom) bottom = other.bottom;
    if (right > other.right) right = other.right;
    if (top > other.top) top = other.top;

    // If empty
    if (left > right || bottom > top) {
      left = right = bottom = top = 0;
    }
  }

  void unionWith(RectangleInt other) {
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

  void Offset(int dx, int dy) {
    left += dx;
    right += dx;
    bottom += dy;
    top += dy;
  }

  bool IntersectRectangles(RectangleInt r1, RectangleInt r2) {
    left = r1.left;
    bottom = r1.bottom;
    right = r1.right;
    top = r1.top;
    
    if (left < r2.left) left = r2.left;
    if (bottom < r2.bottom) bottom = r2.bottom;
    if (right > r2.right) right = r2.right;
    if (top > r2.top) top = r2.top;

    if (left > right || bottom > top) {
      left = right = bottom = top = 0;
      return false;
    }
    return true;
  }

  @override
  String toString() => 'RectangleInt($left, $bottom, $right, $top)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RectangleInt &&
        other.left == left &&
        other.bottom == bottom &&
        other.right == right &&
        other.top == top;
  }

  @override
  int get hashCode => Object.hash(left, bottom, right, top);
}
