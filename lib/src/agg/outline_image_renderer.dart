import 'dart:math' as math;

import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/line_aa_basics.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/rasterizer_outline_aa.dart';

/// Minimal image-backed line renderer: projects subpixel coords into pixel
/// space and draws a simple solid line.
/// AA line renderer using Xiaolin Wu with optional thickness (in pixels).
class ImageLineRenderer extends LineRenderer {
  final IImageByte _image;
  Color color;
  double thickness;
  CapStyle cap;

  ImageLineRenderer(
    this._image, {
    Color? color,
    this.thickness = 1.0,
    this.cap = CapStyle.butt,
  }) : color = color ?? Color(0, 0, 0, 255);

  @override
  void pie(int x1, int y1, int x2, int y2, int x3, int y3) {
    // Not needed for simple rendering; noop.
  }

  @override
  void line0(LineParameters lp) {
    _drawAA(lp.x1, lp.y1, lp.x2, lp.y2);
  }

  @override
  void line1(LineParameters lp, int xb1, int yb1) {
    _drawAA(lp.x1, lp.y1, lp.x2, lp.y2);
  }

  @override
  void line2(LineParameters lp, int xb2, int yb2) {
    _drawAA(lp.x1, lp.y1, lp.x2, lp.y2);
  }

  @override
  void line3(LineParameters lp, int xb1, int yb1, int xb2, int yb2) {
    _drawAA(lp.x1, lp.y1, lp.x2, lp.y2);
  }

  void _drawAA(int sx, int sy, int ex, int ey) {
    final double x0 = sx / LineAABasics.line_subpixel_scale;
    final double y0 = sy / LineAABasics.line_subpixel_scale;
    final double x1 = ex / LineAABasics.line_subpixel_scale;
    final double y1 = ey / LineAABasics.line_subpixel_scale;

    final int strokes = math.max(1, thickness.round());
    final double half = (strokes - 1) / 2.0;
    for (int i = 0; i < strokes; i++) {
      final double offset = (i - half) * 0.5;
      _wuLine(
        x0,
        y0 + offset,
        x1,
        y1 + offset,
      );
    }

    if (cap != CapStyle.butt) {
      _drawCap(x0, y0);
      _drawCap(x1, y1);
    }
  }

  void _drawCap(double x, double y) {
    final double radius = thickness / 2 + 1.0;
    final int minX = (x - radius).floor();
    final int maxX = (x + radius).ceil();
    final int minY = (y - radius).floor();
    final int maxY = (y + radius).ceil();
    for (int yy = minY; yy <= maxY; yy++) {
      for (int xx = minX; xx <= maxX; xx++) {
        if (cap == CapStyle.round) {
          final double dx = xx + 0.5 - x;
          final double dy = yy + 0.5 - y;
          if (math.sqrt(dx * dx + dy * dy) > radius) continue;
        }
        if (xx >= 0 && yy >= 0 && xx < _image.width && yy < _image.height) {
          _image.SetPixel(xx, yy, color);
        }
      }
    }
  }

  void _plot(int x, int y, double c) {
    if (x < 0 || y < 0 || x >= _image.width || y >= _image.height) return;
    final int cov = (c.clamp(0.0, 1.0) * color.alpha).round();
    _image.BlendPixel(x, y, color, cov);
  }

  void _wuLine(double x0, double y0, double x1, double y1) {
    // Xiaolin Wu line
    final bool steep = (y1 - y0).abs() > (x1 - x0).abs();
    if (steep) {
      final double tx0 = x0, ty0 = y0;
      x0 = ty0;
      y0 = tx0;
      final double tx1 = x1, ty1 = y1;
      x1 = ty1;
      y1 = tx1;
    }
    if (x0 > x1) {
      final double tx0 = x0, ty0 = y0;
      x0 = x1;
      y0 = y1;
      x1 = tx0;
      y1 = ty0;
    }
    final double dx = x1 - x0;
    final double dy = y1 - y0;
    final double gradient = dx == 0 ? 1.0 : dy / dx;

    // first endpoint
    double xend = x0.roundToDouble();
    double yend = y0 + gradient * (xend - x0);
    double xgap = rfpart(x0 + 0.5);
    int xpxl1 = xend.toInt();
    int ypxl1 = ipart(yend);
    if (steep) {
      _plot(ypxl1, xpxl1, rfpart(yend) * xgap);
      _plot(ypxl1 + 1, xpxl1, fpart(yend) * xgap);
    } else {
      _plot(xpxl1, ypxl1, rfpart(yend) * xgap);
      _plot(xpxl1, ypxl1 + 1, fpart(yend) * xgap);
    }
    double intery = yend + gradient;

    // second endpoint
    xend = x1.roundToDouble();
    yend = y1 + gradient * (xend - x1);
    xgap = fpart(x1 + 0.5);
    int xpxl2 = xend.toInt();
    int ypxl2 = ipart(yend);
    if (steep) {
      _plot(ypxl2, xpxl2, rfpart(yend) * xgap);
      _plot(ypxl2 + 1, xpxl2, fpart(yend) * xgap);
    } else {
      _plot(xpxl2, ypxl2, rfpart(yend) * xgap);
      _plot(xpxl2, ypxl2 + 1, fpart(yend) * xgap);
    }

    // main loop
    for (int x = xpxl1 + 1; x < xpxl2; x++) {
      if (steep) {
        _plot(ipart(intery), x, rfpart(intery));
        _plot(ipart(intery) + 1, x, fpart(intery));
      } else {
        _plot(x, ipart(intery), rfpart(intery));
        _plot(x, ipart(intery) + 1, fpart(intery));
      }
      intery += gradient;
    }
  }

  int ipart(double x) => x.floor();
  double fpart(double x) => x - x.floor();
  double rfpart(double x) => 1 - fpart(x);

}

enum CapStyle { butt, square, round }
