import 'package:agg/src/agg/primitives/rectangle_int.dart';

/// Liang–Barsky clipping helpers used by the vector clipper.
class ClipLiangBarsky {
  ClipLiangBarsky._();

  //------------------------------------------------------------------------
  // Determine the clipping code of the vertex according to the
  // Cyrus–Beck line clipping algorithm.
  static int clippingFlags(int x, int y, RectangleInt clipBox) {
    return ((x > clipBox.right) ? 1 : 0) |
        ((y > clipBox.top) ? 1 << 1 : 0) |
        ((x < clipBox.left) ? 1 << 2 : 0) |
        ((y < clipBox.bottom) ? 1 << 3 : 0);
  }

  static int clippingFlagsX(int x, RectangleInt clipBox) {
    return ((x > clipBox.right ? 1 : 0) | ((x < clipBox.left ? 1 : 0) << 2));
  }

  static int clippingFlagsY(int y, RectangleInt clipBox) {
    return (((y > clipBox.top ? 1 : 0) << 1) |
        ((y < clipBox.bottom ? 1 : 0) << 3));
  }

  /// Clip a segment against [clipBox]. Returns the number of produced points
  /// (0..4) while writing the results into [x]/[y].
  static int clip(
    int x1,
    int y1,
    int x2,
    int y2,
    RectangleInt clipBox,
    List<int> x,
    List<int> y,
  ) {
    int xIndex = 0;
    int yIndex = 0;
    const double nearZero = 1e-30;

    double deltaX = (x2 - x1).toDouble();
    double deltaY = (y2 - y1).toDouble();
    double xin;
    double xout;
    double yin;
    double yout;

    if (deltaX == 0.0) {
      // bump off of the vertical
      deltaX = (x1 > clipBox.left) ? -nearZero : nearZero;
    }
    if (deltaY == 0.0) {
      // bump off of the horizontal
      deltaY = (y1 > clipBox.bottom) ? -nearZero : nearZero;
    }

    if (deltaX > 0.0) {
      // points to right
      xin = clipBox.left.toDouble();
      xout = clipBox.right.toDouble();
    } else {
      xin = clipBox.right.toDouble();
      xout = clipBox.left.toDouble();
    }

    if (deltaY > 0.0) {
      // points up
      yin = clipBox.bottom.toDouble();
      yout = clipBox.top.toDouble();
    } else {
      yin = clipBox.top.toDouble();
      yout = clipBox.bottom.toDouble();
    }

    final double tinx = (xin - x1) / deltaX;
    final double tiny = (yin - y1) / deltaY;
    final double tin1;
    final double tin2;
    if (tinx < tiny) {
      tin1 = tinx;
      tin2 = tiny;
    } else {
      tin1 = tiny;
      tin2 = tinx;
    }

    int points = 0;
    if (tin1 <= 1.0) {
      if (0.0 < tin1) {
        x[xIndex++] = xin.toInt();
        y[yIndex++] = yin.toInt();
        points++;
      }

      if (tin2 <= 1.0) {
        final double toutx = (xout - x1) / deltaX;
        final double touty = (yout - y1) / deltaY;
        final double tout1 = (toutx < touty) ? toutx : touty;

        if (tin2 > 0.0 || tout1 > 0.0) {
          if (tin2 <= tout1) {
            if (tin2 > 0.0) {
              if (tinx > tiny) {
                x[xIndex++] = xin.toInt();
                y[yIndex++] = (y1 + tinx * deltaY).toInt();
              } else {
                x[xIndex++] = (x1 + tiny * deltaX).toInt();
                y[yIndex++] = yin.toInt();
              }
              points++;
            }

            if (tout1 < 1.0) {
              if (toutx < touty) {
                x[xIndex++] = xout.toInt();
                y[yIndex++] = (y1 + toutx * deltaY).toInt();
              } else {
                x[xIndex++] = (x1 + touty * deltaX).toInt();
                y[yIndex++] = yout.toInt();
              }
            } else {
              x[xIndex++] = x2;
              y[yIndex++] = y2;
            }
            points++;
          } else {
            if (tinx > tiny) {
              x[xIndex++] = xin.toInt();
              y[yIndex++] = yout.toInt();
            } else {
              x[xIndex++] = xout.toInt();
              y[yIndex++] = yin.toInt();
            }
            points++;
          }
        }
      }
    }
    return points;
  }

  /// Move [x]/[y] to the first intersection with [clipBox] based on [flags].
  static bool clipMovePoint(
    int x1,
    int y1,
    int x2,
    int y2,
    RectangleInt clipBox,
    int flags,
    List<int> xy,
  ) {
    int x = xy[0];
    int y = xy[1];

    const int x1Clipped = 4;
    const int x2Clipped = 1;
    const int y1Clipped = 8;
    const int y2Clipped = 2;
    const int xClipped = x1Clipped | x2Clipped;
    const int yClipped = y1Clipped | y2Clipped;

    if ((flags & xClipped) != 0) {
      if (x1 == x2) return false;
      final int bound = (flags & x1Clipped) != 0 ? clipBox.left : clipBox.right;
      y = ((bound - x1) * (y2 - y1) / (x2 - x1) + y1).toInt();
      x = bound;
    }

    final int yFlags = clippingFlagsY(y, clipBox);
    if ((yFlags & yClipped) != 0) {
      if (y1 == y2) return false;
      final int bound = (yFlags & y1Clipped) != 0 ? clipBox.bottom : clipBox.top;
      x = ((bound - y1) * (x2 - x1) / (y2 - y1) + x1).toInt();
      y = bound;
    }

    xy[0] = x;
    xy[1] = y;
    return true;
  }

  /// Clip a line segment in place. Return codes mirror the C# port:
  /// - >=4: fully clipped
  /// - bit0: first point moved
  /// - bit1: second point moved
  static int clipLineSegment(
    List<int> p1,
    List<int> p2,
    RectangleInt clipBox,
  ) {
    int x1 = p1[0];
    int y1 = p1[1];
    int x2 = p2[0];
    int y2 = p2[1];

    int f1 = clippingFlags(x1, y1, clipBox);
    int f2 = clippingFlags(x2, y2, clipBox);
    int ret = 0;

    const xClipped = 4 | 1;
    const yClipped = 8 | 2;

    if ((f2 | f1) == 0) {
      p1[0] = x1;
      p1[1] = y1;
      p2[0] = x2;
      p2[1] = y2;
      return 0; // Fully visible
    }

    if ((f1 & xClipped) != 0 && (f1 & xClipped) == (f2 & xClipped)) {
      return 4; // Fully clipped
    }
    if ((f1 & yClipped) != 0 && (f1 & yClipped) == (f2 & yClipped)) {
      return 4; // Fully clipped
    }

    final int tx1 = x1;
    final int ty1 = y1;
    final int tx2 = x2;
    final int ty2 = y2;

    if (f1 != 0) {
      final xy = [x1, y1];
      if (!clipMovePoint(tx1, ty1, tx2, ty2, clipBox, f1, xy)) {
        return 4;
      }
      x1 = xy[0];
      y1 = xy[1];
      if (x1 == x2 && y1 == y2) return 4;
      ret |= 1;
    }
    if (f2 != 0) {
      final xy = [x2, y2];
      if (!clipMovePoint(tx1, ty1, tx2, ty2, clipBox, f2, xy)) {
        return 4;
      }
      x2 = xy[0];
      y2 = xy[1];
      if (x1 == x2 && y1 == y2) return 4;
      ret |= 2;
    }

    p1[0] = x1;
    p1[1] = y1;
    p2[0] = x2;
    p2[1] = y2;
    return ret;
  }
}
