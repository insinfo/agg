import '../agg_dda_line.dart';
import '../agg_math.dart';
import '../primitives/color.dart';
import '../util.dart';
import 'span_generator.dart';
import 'span_gouraud.dart';

class RgbaCalc {
  double m_x1 = 0;
  double m_y1 = 0;
  double m_dx = 0;
  double m_1dy = 0;
  int m_r1 = 0;
  int m_g1 = 0;
  int m_b1 = 0;
  int m_a1 = 0;
  int m_dr = 0;
  int m_dg = 0;
  int m_db = 0;
  int m_da = 0;
  int m_r = 0;
  int m_g = 0;
  int m_b = 0;
  int m_a = 0;
  int m_x = 0;

  void init(CoordType c1, CoordType c2) {
    m_x1 = c1.x - 0.5;
    m_y1 = c1.y - 0.5;
    m_dx = c2.x - c1.x;
    double dy = c2.y - c1.y;
    m_1dy = (dy < 1e-5) ? 1e5 : 1.0 / dy;
    m_r1 = c1.color.red;
    m_g1 = c1.color.green;
    m_b1 = c1.color.blue;
    m_a1 = c1.color.alpha;
    m_dr = c2.color.red - m_r1;
    m_dg = c2.color.green - m_g1;
    m_db = c2.color.blue - m_b1;
    m_da = c2.color.alpha - m_a1;
  }

  void calc(double y) {
    double k = (y - m_y1) * m_1dy;
    if (k < 0.0) k = 0.0;
    if (k > 1.0) k = 1.0;
    m_r = m_r1 + Util.iround(m_dr * k);
    m_g = m_g1 + Util.iround(m_dg * k);
    m_b = m_b1 + Util.iround(m_db * k);
    m_a = m_a1 + Util.iround(m_da * k);
    m_x = Util.iround((m_x1 + m_dx * k) * SpanGouraudRgba.subpixelScale);
  }
}

class SpanGouraudRgba extends SpanGouraud implements ISpanGenerator {
  static const int subpixelShift = 4;
  static const int subpixelScale = 1 << subpixelShift;

  bool _swap = false;
  int _y2 = 0;
  final RgbaCalc _rgba1 = RgbaCalc();
  final RgbaCalc _rgba2 = RgbaCalc();
  final RgbaCalc _rgba3 = RgbaCalc();

  SpanGouraudRgba([
    Color? c1,
    Color? c2,
    Color? c3,
    double x1 = 0,
    double y1 = 0,
    double x2 = 0,
    double y2 = 0,
    double x3 = 0,
    double y3 = 0,
    double d = 0,
  ]) : super(c1, c2, c3, x1, y1, x2, y2, x3, y3, d);

  @override
  void prepare() {
    List<CoordType> coord = List.generate(3, (_) => CoordType());
    arrangeVertices(coord);

    _y2 = coord[1].y.toInt();

    _swap = AggMath.cross_product(
          coord[0].x,
          coord[0].y,
          coord[2].x,
          coord[2].y,
          coord[1].x,
          coord[1].y,
        ) <
        0.0;

    _rgba1.init(coord[0], coord[2]);
    _rgba2.init(coord[0], coord[1]);
    _rgba3.init(coord[1], coord[2]);
  }

  @override
  void generate(List<Color> span, int spanIndex, int x, int y, int len) {
    _rgba1.calc(y.toDouble());
    RgbaCalc pc1 = _rgba1;
    RgbaCalc pc2 = _rgba2;

    if (y <= _y2) {
      // Bottom part of the triangle (first subtriangle)
      _rgba2.calc(y + _rgba2.m_1dy);
    } else {
      // Upper part (second subtriangle)
      _rgba3.calc(y - _rgba3.m_1dy);
      pc2 = _rgba3;
    }

    if (_swap) {
      // It means that the triangle is oriented clockwise,
      // so that we need to swap the controlling structures
      RgbaCalc t = pc2;
      pc2 = pc1;
      pc1 = t;
    }

    // Get the horizontal length with subpixel accuracy
    // and protect it from division by zero
    int nlen = (pc2.m_x - pc1.m_x).abs();
    if (nlen <= 0) nlen = 1;

    DdaLineInterpolator r = DdaLineInterpolator.init(pc1.m_r, pc2.m_r, nlen, 14);
    DdaLineInterpolator g = DdaLineInterpolator.init(pc1.m_g, pc2.m_g, nlen, 14);
    DdaLineInterpolator b = DdaLineInterpolator.init(pc1.m_b, pc2.m_b, nlen, 14);
    DdaLineInterpolator a = DdaLineInterpolator.init(pc1.m_a, pc2.m_a, nlen, 14);

    // Calculate the starting point of the gradient with subpixel
    // accuracy and correct (roll back) the interpolators.
    // This operation will also clip the beginning of the span
    // if necessary.
    int start = pc1.m_x - (x << subpixelShift);
    r.prevN(start);
    g.prevN(start);
    b.prevN(start);
    a.prevN(start);
    nlen += start;

    int vr, vg, vb, va;
    const int lim = 255;

    // Beginning part of the span.
    while (len != 0 && start > 0) {
      vr = r.y();
      vg = g.y();
      vb = b.y();
      va = a.y();
      if (vr < 0) vr = 0;
      if (vr > lim) vr = lim;
      if (vg < 0) vg = 0;
      if (vg > lim) vg = lim;
      if (vb < 0) vb = 0;
      if (vb > lim) vb = lim;
      if (va < 0) va = 0;
      if (va > lim) va = lim;
      span[spanIndex].red = vr;
      span[spanIndex].green = vg;
      span[spanIndex].blue = vb;
      span[spanIndex].alpha = va;
      r.nextN(subpixelScale);
      g.nextN(subpixelScale);
      b.nextN(subpixelScale);
      a.nextN(subpixelScale);
      nlen -= subpixelScale;
      start -= subpixelScale;
      ++spanIndex;
      --len;
    }

    // Middle part
    while (len != 0 && nlen > 0) {
      span[spanIndex].red = r.y();
      span[spanIndex].green = g.y();
      span[spanIndex].blue = b.y();
      span[spanIndex].alpha = a.y();
      r.nextN(subpixelScale);
      g.nextN(subpixelScale);
      b.nextN(subpixelScale);
      a.nextN(subpixelScale);
      nlen -= subpixelScale;
      ++spanIndex;
      --len;
    }

    // Ending part
    while (len != 0) {
      vr = r.y();
      vg = g.y();
      vb = b.y();
      va = a.y();
      if (vr < 0) vr = 0;
      if (vr > lim) vr = lim;
      if (vg < 0) vg = 0;
      if (vg > lim) vg = lim;
      if (vb < 0) vb = 0;
      if (vb > lim) vb = lim;
      if (va < 0) va = 0;
      if (va > lim) va = lim;
      span[spanIndex].red = vr;
      span[spanIndex].green = vg;
      span[spanIndex].blue = vb;
      span[spanIndex].alpha = va;
      r.nextN(subpixelScale);
      g.nextN(subpixelScale);
      b.nextN(subpixelScale);
      a.nextN(subpixelScale);
      ++spanIndex;
      --len;
    }
  }
}
