import 'dart:math' as math;

import 'package:agg/src/agg/agg_basics.dart';
import 'package:agg/src/shared/ref_param.dart';

/// Coordinate helpers for line AA math.
class LineCoord {
  static int conv(double x) {
    return Agg_basics.iround(x * LineAABasics.line_subpixel_scale);
  }
}

class LineCoordSat {
  static int conv(double x) {
    return Agg_basics.iround2(
      x * LineAABasics.line_subpixel_scale,
      LineAABasics.line_max_coord,
    );
  }
}

/// Parameters describing a line segment in subpixel space.
class LineParameters {
  int x1, y1, x2, y2, dx, dy, sx, sy;
  bool vertical;
  int inc;
  int len;
  int octant;

  static const List<int> s_orthogonal_quadrant = <int>[0, 0, 1, 1, 3, 3, 2, 2];
  static const List<int> s_diagonal_quadrant = <int>[0, 1, 2, 1, 0, 3, 2, 3];

  LineParameters(this.x1, this.y1, this.x2, this.y2, this.len)
      : dx = (x2 - x1).abs(),
        dy = (y2 - y1).abs(),
        sx = x2 > x1 ? 1 : -1,
        sy = y2 > y1 ? 1 : -1,
        vertical = (y2 - y1).abs() >= (x2 - x1).abs(),
        inc = ((y2 - y1).abs() >= (x2 - x1).abs()) ? (y2 > y1 ? 1 : -1) : (x2 > x1 ? 1 : -1),
        octant = (((y2 > y1 ? 1 : -1) & 4) |
            ((x2 > x1 ? 1 : -1) & 2) |
            (((y2 - y1).abs() >= (x2 - x1).abs()) ? 1 : 0));

  int orthogonalQuadrant() => s_orthogonal_quadrant[octant];
  int diagonalQuadrant() => s_diagonal_quadrant[octant];

  bool sameOrthogonalQuadrant(LineParameters lp) =>
      s_orthogonal_quadrant[octant] == s_orthogonal_quadrant[lp.octant];

  bool sameDiagonalQuadrant(LineParameters lp) =>
      s_diagonal_quadrant[octant] == s_diagonal_quadrant[lp.octant];

  void divide(RefParam<LineParameters> lp1, RefParam<LineParameters> lp2) {
    final int xmid = (x1 + x2) >> 1;
    final int ymid = (y1 + y2) >> 1;
    final int len2 = len >> 1;

    lp1.value = LineParameters(x1, y1, xmid, ymid, len2);
    lp2.value = LineParameters(xmid, ymid, x2, y2, len2);
  }
}

/// Core AA line math helpers.
class LineAABasics {
  static const int line_subpixel_shift = 8; //----line_subpixel_shift
  static const int line_subpixel_scale = 1 << line_subpixel_shift; //----line_subpixel_scale
  static const int line_subpixel_mask = line_subpixel_scale - 1; //----line_subpixel_mask
  static const int line_max_coord = (1 << 28) - 1; //----line_max_coord
  static const int line_max_length = 1 << (line_subpixel_shift + 10); //----line_max_length

  static const int line_mr_subpixel_shift = 4; //----line_mr_subpixel_shift
  static const int line_mr_subpixel_scale = 1 << line_mr_subpixel_shift; //----line_mr_subpixel_scale
  static const int line_mr_subpixel_mask = line_mr_subpixel_scale - 1; //----line_mr_subpixel_mask

  static int line_mr(int x) => x >> (line_subpixel_shift - line_mr_subpixel_shift);
  static int line_hr(int x) => x << (line_subpixel_shift - line_mr_subpixel_shift);
  static int line_dbl_hr(int x) => x << line_subpixel_shift;

  static void bisectrix(LineParameters l1, LineParameters l2, RefParam<int> x, RefParam<int> y) {
    final double k = l2.len / l1.len;
    double tx = l2.x2 - (l2.x1 - l1.x1) * k;
    double ty = l2.y2 - (l2.y1 - l1.y1) * k;

    // Ensure bisectrix is on the right side.
    if ((l2.x2 - l2.x1) * (l2.y1 - l1.y1) < (l2.y2 - l2.y1) * (l2.x1 - l1.x1) + 100.0) {
      tx -= (tx - l2.x1) * 2.0;
      ty -= (ty - l2.y1) * 2.0;
    }

    final double dx = tx - l2.x1;
    final double dy = ty - l2.y1;
    if (math.sqrt(dx * dx + dy * dy).toInt() < line_subpixel_scale) {
      x.value = (l2.x1 + l2.x1 + (l2.y1 - l1.y1) + (l2.y2 - l2.y1)) >> 1;
      y.value = (l2.y1 + l2.y1 - (l2.x1 - l1.x1) - (l2.x2 - l2.x1)) >> 1;
      return;
    }

    x.value = Agg_basics.iround(tx);
    y.value = Agg_basics.iround(ty);
  }

  static void fix_degenerate_bisectrix_start(LineParameters lp, RefParam<int> x, RefParam<int> y) {
    final double dx = (lp.x2 - lp.x1).toDouble();
    final double dy = (lp.y2 - lp.y1).toDouble();
    final double dx0 = (x.value - lp.x2).toDouble();
    final double dy0 = (y.value - lp.y2).toDouble();
    final double len = lp.len.toDouble();
    final int d = ((dx0 * dy - dy0 * dx) / len).round().toInt();
    
    if (d < line_subpixel_scale ~/ 2) {
      x.value = lp.x1 + (lp.y2 - lp.y1);
      y.value = lp.y1 - (lp.x2 - lp.x1);
    }
    // else: keep original x, y values
  }

  static void fix_degenerate_bisectrix_end(LineParameters lp, RefParam<int> x, RefParam<int> y) {
    final double dx = (lp.x2 - lp.x1).toDouble();
    final double dy = (lp.y2 - lp.y1).toDouble();
    final double dx0 = (x.value - lp.x2).toDouble();
    final double dy0 = (y.value - lp.y2).toDouble();
    final double len = lp.len.toDouble();
    final int d = ((dx0 * dy - dy0 * dx) / len).round().toInt();
    
    if (d < line_subpixel_scale ~/ 2) {
      x.value = lp.x2 + (lp.y2 - lp.y1);
      y.value = lp.y2 - (lp.x2 - lp.x1);
    }
    // else: keep original x, y values
  }
}
