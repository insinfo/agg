import 'package:agg/src/shared/ref_param.dart';
import 'dart:math' as math;
import '../agg_math.dart';
import 'ivertex_source.dart';
import 'path_commands.dart';
import 'vertex_data.dart';
import '../primitives/point2d.dart';
import '../util.dart';

enum CurveApproximationMethod {
  curve_inc,
  curve_div
}

class Curves {
  static const double curve_distance_epsilon = 1e-30;
  static const double curve_collinearity_epsilon = 1e-30;
  static const double curve_angle_tolerance_epsilon = 0.01;
  static const int curve_recursion_limit = 32;

  static Curve4Points catrom_to_bezier(
      double x1, double y1, double x2, double y2,
      double x3, double y3, double x4, double y4) {
    return Curve4Points(
      x2,
      y2,
      (-x1 + 6 * x2 + x3) / 6,
      (-y1 + 6 * y2 + y3) / 6,
      (x2 + 6 * x3 - x4) / 6,
      (y2 + 6 * y3 - y4) / 6,
      x3,
      y3,
    );
  }

  static Curve4Points catrom_to_bezier_cp(Curve4Points cp) {
    return catrom_to_bezier(
        cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7]);
  }

  static Curve4Points ubspline_to_bezier(
      double x1, double y1, double x2, double y2,
      double x3, double y3, double x4, double y4) {
    return Curve4Points(
      (x1 + 4 * x2 + x3) / 6,
      (y1 + 4 * y2 + y3) / 6,
      (4 * x2 + 2 * x3) / 6,
      (4 * y2 + 2 * y3) / 6,
      (2 * x2 + 4 * x3) / 6,
      (2 * y2 + 4 * y3) / 6,
      (x2 + 4 * x3 + x4) / 6,
      (y2 + 4 * y3 + y4) / 6,
    );
  }

  static Curve4Points ubspline_to_bezier_cp(Curve4Points cp) {
    return ubspline_to_bezier(
        cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7]);
  }

  static Curve4Points hermite_to_bezier(
      double x1, double y1, double x2, double y2,
      double x3, double y3, double x4, double y4) {
    return Curve4Points(
      x1,
      y1,
      (3 * x1 + x3) / 3,
      (3 * y1 + y3) / 3,
      (3 * x2 - x4) / 3,
      (3 * y2 - y4) / 3,
      x2,
      y2,
    );
  }

  static Curve4Points hermite_to_bezier_cp(Curve4Points cp) {
    return hermite_to_bezier(
        cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7]);
  }
}

class Curve3Inc {
  int m_num_steps = 0;
  int m_step = 0;
  double m_scale = 1.0;
  double m_start_x = 0.0;
  double m_start_y = 0.0;
  double m_end_x = 0.0;
  double m_end_y = 0.0;
  double m_fx = 0.0;
  double m_fy = 0.0;
  double m_dfx = 0.0;
  double m_dfy = 0.0;
  double m_ddfx = 0.0;
  double m_ddfy = 0.0;
  double m_saved_fx = 0.0;
  double m_saved_fy = 0.0;
  double m_saved_dfx = 0.0;
  double m_saved_dfy = 0.0;

  Curve3Inc([double x1 = 0, double y1 = 0, double x2 = 0, double y2 = 0, double x3 = 0, double y3 = 0]) {
    if (x1 != 0 || y1 != 0 || x2 != 0 || y2 != 0 || x3 != 0 || y3 != 0) {
      init(x1, y1, x2, y2, x3, y3);
    }
  }

  void reset() {
    m_num_steps = 0;
    m_step = -1;
  }

  void init(double x1, double y1, double cx, double cy, double x2, double y2) {
    m_start_x = x1;
    m_start_y = y1;
    m_end_x = x2;
    m_end_y = y2;

    double dx1 = cx - x1;
    double dy1 = cy - y1;
    double dx2 = x2 - cx;
    double dy2 = y2 - cy;

    double len = math.sqrt(dx1 * dx1 + dy1 * dy1) + math.sqrt(dx2 * dx2 + dy2 * dy2);

    m_num_steps = Util.uround(len * 0.25 * m_scale);

    if (m_num_steps < 4) {
      m_num_steps = 4;
    }

    double subdivide_step = 1.0 / m_num_steps;
    double subdivide_step2 = subdivide_step * subdivide_step;

    double tmpx = (x1 - cx * 2.0 + x2) * subdivide_step2;
    double tmpy = (y1 - cy * 2.0 + y2) * subdivide_step2;

    m_saved_fx = m_fx = x1;
    m_saved_fy = m_fy = y1;

    m_saved_dfx = m_dfx = tmpx + (cx - x1) * (2.0 * subdivide_step);
    m_saved_dfy = m_dfy = tmpy + (cy - y1) * (2.0 * subdivide_step);

    m_ddfx = tmpx * 2.0;
    m_ddfy = tmpy * 2.0;

    m_step = m_num_steps;
  }

  void approximation_method(CurveApproximationMethod method) {}

  CurveApproximationMethod get_approximation_method() {
    return CurveApproximationMethod.curve_inc;
  }

  void approximation_scale(double s) {
    m_scale = s;
  }

  double get_approximation_scale() {
    return m_scale;
  }

  void angle_tolerance(double angle) {}

  double get_angle_tolerance() {
    return 0.0;
  }

  void cusp_limit(double limit) {}

  double get_cusp_limit() {
    return 0.0;
  }

  void rewind(int path_id) {
    if (m_num_steps == 0) {
      m_step = -1;
      return;
    }
    m_step = m_num_steps;
    m_fx = m_saved_fx;
    m_fy = m_saved_fy;
    m_dfx = m_saved_dfx;
    m_dfy = m_saved_dfy;
  }

  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    if (m_step < 0) {
      x.value = 0;
      y.value = 0;
      return FlagsAndCommand.commandStop;
    }
    if (m_step == m_num_steps) {
      x.value = m_start_x;
      y.value = m_start_y;
      --m_step;
      return FlagsAndCommand.commandMoveTo;
    }
    if (m_step == 0) {
      x.value = m_end_x;
      y.value = m_end_y;
      --m_step;
      return FlagsAndCommand.commandLineTo;
    }
    m_fx += m_dfx;
    m_fy += m_dfy;
    m_dfx += m_ddfx;
    m_dfy += m_ddfy;
    x.value = m_fx;
    y.value = m_fy;
    --m_step;
    return FlagsAndCommand.commandLineTo;
  }
}

class Curve3Div {
  double m_approximation_scale = 1.0;
  double m_distance_tolerance_square = 0.0;
  double m_angle_tolerance = 0.0;
  int m_count = 0;
  final List<Point2D> m_points = [];

  Curve3Div([double x1 = 0, double y1 = 0, double cx = 0, double cy = 0, double x2 = 0, double y2 = 0]) {
    if (x1 != 0 || y1 != 0 || cx != 0 || cy != 0 || x2 != 0 || y2 != 0) {
      init(x1, y1, cx, cy, x2, y2);
    }
  }

  void reset() {
    m_points.clear();
    m_count = 0;
  }

  void init(double x1, double y1, double cx, double cy, double x2, double y2) {
    m_points.clear();
    m_distance_tolerance_square = 0.5 / m_approximation_scale;
    m_distance_tolerance_square *= m_distance_tolerance_square;
    bezier(x1, y1, cx, cy, x2, y2);
    m_count = 0;
  }

  void approximation_method(CurveApproximationMethod method) {}

  CurveApproximationMethod get_approximation_method() {
    return CurveApproximationMethod.curve_div;
  }

  void approximation_scale(double s) {
    m_approximation_scale = s;
  }

  double get_approximation_scale() {
    return m_approximation_scale;
  }

  void angle_tolerance(double a) {
    m_angle_tolerance = a;
  }

  double get_angle_tolerance() {
    return m_angle_tolerance;
  }

  void cusp_limit(double limit) {}

  double get_cusp_limit() {
    return 0.0;
  }

  void rewind(int idx) {
    m_count = 0;
  }

  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    if (m_count >= m_points.length) {
      x.value = 0;
      y.value = 0;
      return FlagsAndCommand.commandStop;
    }

    Point2D p = m_points[m_count++];
    x.value = p.x;
    y.value = p.y;
    return (m_count == 1) ? FlagsAndCommand.commandMoveTo : FlagsAndCommand.commandLineTo;
  }

  void bezier(double x1, double y1, double x2, double y2, double x3, double y3) {
    m_points.add(Point2D(x1, y1));
    recursive_bezier(x1, y1, x2, y2, x3, y3, 0);
    m_points.add(Point2D(x3, y3));
  }

  void recursive_bezier(double x1, double y1, double x2, double y2, double x3, double y3, int level) {
    if (level > Curves.curve_recursion_limit) {
      return;
    }

    double x12 = (x1 + x2) / 2;
    double y12 = (y1 + y2) / 2;
    double x23 = (x2 + x3) / 2;
    double y23 = (y2 + y3) / 2;
    double x123 = (x12 + x23) / 2;
    double y123 = (y12 + y23) / 2;

    double dx = x3 - x1;
    double dy = y3 - y1;
    double d = (x2 - x3) * dy - (y2 - y3) * dx;
    d = d.abs();
    double da;

    if (d > Curves.curve_collinearity_epsilon) {
      if (d * d <= m_distance_tolerance_square * (dx * dx + dy * dy)) {
        if (m_angle_tolerance < Curves.curve_angle_tolerance_epsilon) {
          m_points.add(Point2D(x123, y123));
          return;
        }

        da = (math.atan2(y3 - y2, x3 - x2) - math.atan2(y2 - y1, x2 - x1)).abs();
        if (da >= math.pi) da = 2 * math.pi - da;

        if (da < m_angle_tolerance) {
          m_points.add(Point2D(x123, y123));
          return;
        }
      }
    } else {
      da = dx * dx + dy * dy;
      if (da == 0) {
        d = AggMath.calc_sq_distance(x1, y1, x2, y2);
      } else {
        d = ((x2 - x1) * dx + (y2 - y1) * dy) / da;
        if (d > 0 && d < 1) {
          return;
        }
        if (d <= 0)
          d = AggMath.calc_sq_distance(x2, y2, x1, y1);
        else if (d >= 1)
          d = AggMath.calc_sq_distance(x2, y2, x3, y3);
        else
          d = AggMath.calc_sq_distance(x2, y2, x1 + d * dx, y1 + d * dy);
      }
      if (d < m_distance_tolerance_square) {
        m_points.add(Point2D(x2, y2));
        return;
      }
    }

    recursive_bezier(x1, y1, x12, y12, x123, y123, level + 1);
    recursive_bezier(x123, y123, x23, y23, x3, y3, level + 1);
  }
}

class Curve4Points {
  final List<double> cp = List.filled(8, 0.0);

  Curve4Points([double x1 = 0, double y1 = 0, double x2 = 0, double y2 = 0, double x3 = 0, double y3 = 0, double x4 = 0, double y4 = 0]) {
    cp[0] = x1; cp[1] = y1; cp[2] = x2; cp[3] = y2;
    cp[4] = x3; cp[5] = y3; cp[6] = x4; cp[7] = y4;
  }

  void init(double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4) {
    cp[0] = x1; cp[1] = y1; cp[2] = x2; cp[3] = y2;
    cp[4] = x3; cp[5] = y3; cp[6] = x4; cp[7] = y4;
  }

  double operator [](int i) => cp[i];
  void operator []=(int i, double value) => cp[i] = value;
}

class Curve4Increment {
  int numSteps = 0;
  int remainingSteps = 0;
  double scale = 1.0;
  Point2D start = Point2D();
  Point2D end = Point2D();
  double m_fx = 0.0;
  double m_fy = 0.0;
  double m_dfx = 0.0;
  double m_dfy = 0.0;
  double m_ddfx = 0.0;
  double m_ddfy = 0.0;
  double m_dddfx = 0.0;
  double m_dddfy = 0.0;
  double m_saved_fx = 0.0;
  double m_saved_fy = 0.0;
  double m_saved_dfx = 0.0;
  double m_saved_dfy = 0.0;
  double m_saved_ddfx = 0.0;
  double m_saved_ddfy = 0.0;

  Curve4Increment([double xStart = 0, double yStart = 0, double xControl1 = 0, double yControl1 = 0, double xControl2 = 0, double yControl2 = 0, double xEnd = 0, double yEnd = 0]) {
    if (xStart != 0 || yStart != 0 || xControl1 != 0 || yControl1 != 0 || xControl2 != 0 || yControl2 != 0 || xEnd != 0 || yEnd != 0) {
      init(xStart, yStart, xControl1, yControl1, xControl2, yControl2, xEnd, yEnd);
    }
  }

  Curve4Increment.fromPoints(Curve4Points cp) {
    init(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7]);
  }

  void reset() {
    numSteps = 0;
    remainingSteps = -1;
  }

  void init(double xStart, double yStart, double xControl1, double yControl1, double xControl2, double yControl2, double xEnd, double yEnd) {
    double dx1 = xControl1 - xStart;
    double dy1 = yControl1 - yStart;
    double dx2 = xControl2 - xControl1;
    double dy2 = yControl2 - yControl1;
    double dx3 = xEnd - xControl2;
    double dy3 = yEnd - yControl2;

    double len = (math.sqrt(dx1 * dx1 + dy1 * dy1) +
                  math.sqrt(dx2 * dx2 + dy2 * dy2) +
                  math.sqrt(dx3 * dx3 + dy3 * dy3)) * 0.25 * scale;

    initSteps(xStart, yStart, xControl1, yControl1, xControl2, yControl2, xEnd, yEnd, Util.uround(len));
  }

  void initSteps(double xStart, double yStart, double xControl1, double yControl1, double xControl2, double yControl2, double xEnd, double yEnd, int numSteps) {
    start.x = xStart;
    start.y = yStart;
    end.x = xEnd;
    end.y = yEnd;

    this.numSteps = numSteps;

    if (numSteps < 4) {
      this.numSteps = 4;
    }

    double subdivide_step = 1.0 / this.numSteps;
    double subdivide_step2 = subdivide_step * subdivide_step;
    double subdivide_step3 = subdivide_step * subdivide_step * subdivide_step;

    double pre1 = 3.0 * subdivide_step;
    double pre2 = 3.0 * subdivide_step2;
    double pre4 = 6.0 * subdivide_step2;
    double pre5 = 6.0 * subdivide_step3;

    double tmp1x = xStart - xControl1 * 2.0 + xControl2;
    double tmp1y = yStart - yControl1 * 2.0 + yControl2;

    double tmp2x = (xControl1 - xControl2) * 3.0 - xStart + xEnd;
    double tmp2y = (yControl1 - yControl2) * 3.0 - yStart + yEnd;

    m_saved_fx = m_fx = xStart;
    m_saved_fy = m_fy = yStart;

    m_saved_dfx = m_dfx = (xControl1 - xStart) * pre1 + tmp1x * pre2 + tmp2x * subdivide_step3;
    m_saved_dfy = m_dfy = (yControl1 - yStart) * pre1 + tmp1y * pre2 + tmp2y * subdivide_step3;

    m_saved_ddfx = m_ddfx = tmp1x * pre4 + tmp2x * pre5;
    m_saved_ddfy = m_ddfy = tmp1y * pre4 + tmp2y * pre5;

    m_dddfx = tmp2x * pre5;
    m_dddfy = tmp2y * pre5;

    remainingSteps = this.numSteps;
  }

  void initFromPoints(Curve4Points cp) {
    init(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7]);
  }

  void approximation_scale(double s) {
    scale = s;
  }

  double get_approximation_scale() {
    return scale;
  }

  void angle_tolerance(double angle) {}

  double get_angle_tolerance() {
    return 0.0;
  }

  void cusp_limit(double limit) {}

  double get_cusp_limit() {
    return 0.0;
  }

  void rewind(int path_id) {
    if (numSteps == 0) {
      remainingSteps = -1;
      return;
    }
    
    remainingSteps = numSteps;
    m_fx = m_saved_fx;
    m_fy = m_saved_fy;
    m_dfx = m_saved_dfx;
    m_dfy = m_saved_dfy;
    m_ddfx = m_saved_ddfx;
    m_ddfy = m_saved_ddfy;
  }

  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    if (remainingSteps < 0) {
      x.value = 0;
      y.value = 0;
      return FlagsAndCommand.commandStop;
    }

    if (remainingSteps == numSteps) {
      x.value = start.x;
      y.value = start.y;
      --remainingSteps;
      return FlagsAndCommand.commandMoveTo;
    }

    if (remainingSteps == 0) {
      x.value = end.x;
      y.value = end.y;
      --remainingSteps;
      return FlagsAndCommand.commandLineTo;
    }

    m_fx += m_dfx;
    m_fy += m_dfy;
    m_dfx += m_ddfx;
    m_dfy += m_ddfy;
    m_ddfx += m_dddfx;
    m_ddfy += m_dddfy;

    x.value = m_fx;
    y.value = m_fy;
    --remainingSteps;
    return FlagsAndCommand.commandLineTo;
  }
}

class Curve4Div {
  double m_approximation_scale = 1.0;
  double m_distance_tolerance_square = 0.0;
  double m_angle_tolerance = 0.0;
  double m_cusp_limit = 0.0;
  int m_count = 0;
  final List<Point2D> m_points = [];

  Curve4Div([double x1 = 0, double y1 = 0, double x2 = 0, double y2 = 0, double x3 = 0, double y3 = 0, double x4 = 0, double y4 = 0]) {
    if (x1 != 0 || y1 != 0 || x2 != 0 || y2 != 0 || x3 != 0 || y3 != 0 || x4 != 0 || y4 != 0) {
      init(x1, y1, x2, y2, x3, y3, x4, y4);
    }
  }

  Curve4Div.fromPoints(Curve4Points cp) {
    init(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7]);
  }

  void reset() {
    m_points.clear();
    m_count = 0;
  }

  void init(double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4) {
    m_points.clear();
    m_distance_tolerance_square = 0.5 / m_approximation_scale;
    m_distance_tolerance_square *= m_distance_tolerance_square;
    bezier(x1, y1, x2, y2, x3, y3, x4, y4);
    m_count = 0;
  }

  void initFromPoints(Curve4Points cp) {
    init(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7]);
  }

  void approximation_method(CurveApproximationMethod method) {}

  CurveApproximationMethod get_approximation_method() {
    return CurveApproximationMethod.curve_div;
  }

  void approximation_scale(double s) {
    m_approximation_scale = s;
  }

  double get_approximation_scale() {
    return m_approximation_scale;
  }

  void angle_tolerance(double a) {
    m_angle_tolerance = a;
  }

  double get_angle_tolerance() {
    return m_angle_tolerance;
  }

  void cusp_limit(double v) {
    m_cusp_limit = (v == 0.0) ? 0.0 : math.pi - v;
  }

  double get_cusp_limit() {
    return (m_cusp_limit == 0.0) ? 0.0 : math.pi - m_cusp_limit;
  }

  void rewind(int idx) {
    m_count = 0;
  }

  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    if (m_count >= m_points.length) {
      x.value = 0;
      y.value = 0;
      return FlagsAndCommand.commandStop;
    }
    Point2D p = m_points[m_count++];
    x.value = p.x;
    y.value = p.y;
    return (m_count == 1) ? FlagsAndCommand.commandMoveTo : FlagsAndCommand.commandLineTo;
  }

  void bezier(double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4) {
    m_points.add(Point2D(x1, y1));
    recursive_bezier(x1, y1, x2, y2, x3, y3, x4, y4, 0);
    m_points.add(Point2D(x4, y4));
  }

  void recursive_bezier(double x1, double y1, double x2, double y2, double x3, double y3, double x4, double y4, int level) {
    if (level > Curves.curve_recursion_limit) {
      return;
    }

    double x12 = (x1 + x2) / 2;
    double y12 = (y1 + y2) / 2;
    double x23 = (x2 + x3) / 2;
    double y23 = (y2 + y3) / 2;
    double x34 = (x3 + x4) / 2;
    double y34 = (y3 + y4) / 2;
    double x123 = (x12 + x23) / 2;
    double y123 = (y12 + y23) / 2;
    double x234 = (x23 + x34) / 2;
    double y234 = (y23 + y34) / 2;
    double x1234 = (x123 + x234) / 2;
    double y1234 = (y123 + y234) / 2;

    double dx = x4 - x1;
    double dy = y4 - y1;

    double d2 = ((x2 - x4) * dy - (y2 - y4) * dx).abs();
    double d3 = ((x3 - x4) * dy - (y3 - y4) * dx).abs();
    double da1, da2, k;

    int switchCase = 0;
    if (d2 > Curves.curve_collinearity_epsilon) {
      switchCase = 2;
    }
    if (d3 > Curves.curve_collinearity_epsilon) {
      switchCase++;
    }

    switch (switchCase) {
      case 0:
        k = dx * dx + dy * dy;
        if (k == 0) {
          d2 = AggMath.calc_sq_distance(x1, y1, x2, y2);
          d3 = AggMath.calc_sq_distance(x4, y4, x3, y3);
        } else {
          k = 1 / k;
          da1 = x2 - x1;
          da2 = y2 - y1;
          d2 = k * (da1 * dx + da2 * dy);
          da1 = x3 - x1;
          da2 = y3 - y1;
          d3 = k * (da1 * dx + da2 * dy);
          if (d2 > 0 && d2 < 1 && d3 > 0 && d3 < 1) {
            return;
          }
          if (d2 <= 0)
            d2 = AggMath.calc_sq_distance(x2, y2, x1, y1);
          else if (d2 >= 1)
            d2 = AggMath.calc_sq_distance(x2, y2, x4, y4);
          else
            d2 = AggMath.calc_sq_distance(x2, y2, x1 + d2 * dx, y1 + d2 * dy);

          if (d3 <= 0)
            d3 = AggMath.calc_sq_distance(x3, y3, x1, y1);
          else if (d3 >= 1)
            d3 = AggMath.calc_sq_distance(x3, y3, x4, y4);
          else
            d3 = AggMath.calc_sq_distance(x3, y3, x1 + d3 * dx, y1 + d3 * dy);
        }
        if (d2 > d3) {
          if (d2 < m_distance_tolerance_square) {
            m_points.add(Point2D(x2, y2));
            return;
          }
        } else {
          if (d3 < m_distance_tolerance_square) {
            m_points.add(Point2D(x3, y3));
            return;
          }
        }
        break;

      case 1:
        if (d3 * d3 <= m_distance_tolerance_square * (dx * dx + dy * dy)) {
          if (m_angle_tolerance < Curves.curve_angle_tolerance_epsilon) {
            m_points.add(Point2D(x23, y23));
            return;
          }

          da1 = (math.atan2(y4 - y3, x4 - x3) - math.atan2(y3 - y2, x3 - x2)).abs();
          if (da1 >= math.pi) da1 = 2 * math.pi - da1;

          if (da1 < m_angle_tolerance) {
            m_points.add(Point2D(x2, y2));
            m_points.add(Point2D(x3, y3));
            return;
          }

          if (m_cusp_limit != 0.0) {
            if (da1 > m_cusp_limit) {
              m_points.add(Point2D(x3, y3));
              return;
            }
          }
        }
        break;

      case 2:
        if (d2 * d2 <= m_distance_tolerance_square * (dx * dx + dy * dy)) {
          if (m_angle_tolerance < Curves.curve_angle_tolerance_epsilon) {
            m_points.add(Point2D(x23, y23));
            return;
          }

          da1 = (math.atan2(y3 - y2, x3 - x2) - math.atan2(y2 - y1, x2 - x1)).abs();
          if (da1 >= math.pi) da1 = 2 * math.pi - da1;

          if (da1 < m_angle_tolerance) {
            m_points.add(Point2D(x2, y2));
            m_points.add(Point2D(x3, y3));
            return;
          }

          if (m_cusp_limit != 0.0) {
            if (da1 > m_cusp_limit) {
              m_points.add(Point2D(x2, y2));
              return;
            }
          }
        }
        break;

      case 3:
        if ((d2 + d3) * (d2 + d3) <= m_distance_tolerance_square * (dx * dx + dy * dy)) {
          if (m_angle_tolerance < Curves.curve_angle_tolerance_epsilon) {
            m_points.add(Point2D(x23, y23));
            return;
          }

          k = math.atan2(y3 - y2, x3 - x2);
          da1 = (k - math.atan2(y2 - y1, x2 - x1)).abs();
          da2 = (math.atan2(y4 - y3, x4 - x3) - k).abs();
          if (da1 >= math.pi) da1 = 2 * math.pi - da1;
          if (da2 >= math.pi) da2 = 2 * math.pi - da2;

          if (da1 + da2 < m_angle_tolerance) {
            m_points.add(Point2D(x23, y23));
            return;
          }

          if (m_cusp_limit != 0.0) {
            if (da1 > m_cusp_limit) {
              m_points.add(Point2D(x2, y2));
              return;
            }

            if (da2 > m_cusp_limit) {
              m_points.add(Point2D(x3, y3));
              return;
            }
          }
        }
        break;
    }

    recursive_bezier(x1, y1, x12, y12, x123, y123, x1234, y1234, level + 1);
    recursive_bezier(x1234, y1234, x234, y234, x34, y34, x4, y4, level + 1);
  }
}

class Curve3 implements IVertexSource {
  final Curve3Inc m_curve_inc = Curve3Inc();
  final Curve3Div m_curve_div = Curve3Div();
  CurveApproximationMethod m_approximation_method = CurveApproximationMethod.curve_div;

  Curve3([double x1 = 0, double y1 = 0, double cx = 0, double cy = 0, double x2 = 0, double y2 = 0]) {
    if (x1 != 0 || y1 != 0 || cx != 0 || cy != 0 || x2 != 0 || y2 != 0) {
      init(x1, y1, cx, cy, x2, y2);
    }
  }

  void reset() {
    m_curve_inc.reset();
    m_curve_div.reset();
  }

  void init(double x1, double y1, double cx, double cy, double x2, double y2) {
    if (m_approximation_method == CurveApproximationMethod.curve_inc) {
      m_curve_inc.init(x1, y1, cx, cy, x2, y2);
    } else {
      m_curve_div.init(x1, y1, cx, cy, x2, y2);
    }
  }

  void approximation_method(CurveApproximationMethod v) {
    m_approximation_method = v;
  }

  CurveApproximationMethod get_approximation_method() {
    return m_approximation_method;
  }

  void approximation_scale(double s) {
    m_curve_inc.approximation_scale(s);
    m_curve_div.approximation_scale(s);
  }

  double get_approximation_scale() {
    return m_curve_inc.get_approximation_scale();
  }

  void angle_tolerance(double a) {
    m_curve_div.angle_tolerance(a);
  }

  double get_angle_tolerance() {
    return m_curve_div.get_angle_tolerance();
  }

  void cusp_limit(double v) {
    m_curve_div.cusp_limit(v);
  }

  double get_cusp_limit() {
    return m_curve_div.get_cusp_limit();
  }

  @override
  void rewind([int path_id = 0]) {
    if (m_approximation_method == CurveApproximationMethod.curve_inc) {
      m_curve_inc.rewind(path_id);
    } else {
      m_curve_div.rewind(path_id);
    }
  }

  @override
  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    if (m_approximation_method == CurveApproximationMethod.curve_inc) {
      return m_curve_inc.vertex(x, y);
    }
    return m_curve_div.vertex(x, y);
  }

  @override
  int getLongHashCode([int hash = 0xcbf29ce484222325]) {
    // TODO: Implement hash code
    return hash;
  }
  
  @override
  Iterable<VertexData> vertices() sync* {
    var x = RefParam(0.0);
    var y = RefParam(0.0);
    var cmd = vertex(x, y);
    while (!cmd.isStop) {
      yield VertexData(cmd, x.value, y.value);
      cmd = vertex(x, y);
    }
  }
}

class Curve4 implements IVertexSource {
  final Curve4Increment m_curve_inc = Curve4Increment();
  final Curve4Div m_curve_div = Curve4Div();
  CurveApproximationMethod m_approximation_method = CurveApproximationMethod.curve_div;

  Curve4([double x1 = 0, double y1 = 0, double cx1 = 0, double cy1 = 0, double cx2 = 0, double cy2 = 0, double x2 = 0, double y2 = 0]) {
    if (x1 != 0 || y1 != 0 || cx1 != 0 || cy1 != 0 || cx2 != 0 || cy2 != 0 || x2 != 0 || y2 != 0) {
      init(x1, y1, cx1, cy1, cx2, cy2, x2, y2);
    }
  }

  Curve4.fromPoints(Curve4Points cp) {
    init(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7]);
  }

  void reset() {
    m_curve_inc.reset();
    m_curve_div.reset();
  }

  void init(double xStart, double yStart, double xControl1, double yControl1, double xControl2, double yControl2, double xEnd, double yEnd) {
    if (m_approximation_method == CurveApproximationMethod.curve_inc) {
      m_curve_inc.init(xStart, yStart, xControl1, yControl1, xControl2, yControl2, xEnd, yEnd);
    } else {
      m_curve_div.init(xStart, yStart, xControl1, yControl1, xControl2, yControl2, xEnd, yEnd);
    }
  }

  void initFromPoints(Curve4Points cp) {
    init(cp[0], cp[1], cp[2], cp[3], cp[4], cp[5], cp[6], cp[7]);
  }

  void approximation_method(CurveApproximationMethod v) {
    m_approximation_method = v;
  }

  CurveApproximationMethod get_approximation_method() {
    return m_approximation_method;
  }

  void approximation_scale(double s) {
    m_curve_inc.approximation_scale(s);
    m_curve_div.approximation_scale(s);
  }

  double get_approximation_scale() {
    return m_curve_inc.get_approximation_scale();
  }

  void angle_tolerance(double v) {
    m_curve_div.angle_tolerance(v);
  }

  double get_angle_tolerance() {
    return m_curve_div.get_angle_tolerance();
  }

  void cusp_limit(double v) {
    m_curve_div.cusp_limit(v);
  }

  double get_cusp_limit() {
    return m_curve_div.get_cusp_limit();
  }

  @override
  void rewind([int path_id = 0]) {
    if (m_approximation_method == CurveApproximationMethod.curve_inc) {
      m_curve_inc.rewind(path_id);
    } else {
      m_curve_div.rewind(path_id);
    }
  }

  @override
  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    if (m_approximation_method == CurveApproximationMethod.curve_inc) {
      return m_curve_inc.vertex(x, y);
    }
    return m_curve_div.vertex(x, y);
  }

  @override
  int getLongHashCode([int hash = 0xcbf29ce484222325]) {
    // TODO: Implement hash code
    return hash;
  }

  @override
  Iterable<VertexData> vertices() sync* {
    var x = RefParam(0.0);
    var y = RefParam(0.0);
    var cmd = vertex(x, y);
    while (!cmd.isStop) {
      yield VertexData(cmd, x.value, y.value);
      cmd = vertex(x, y);
    }
  }
}
