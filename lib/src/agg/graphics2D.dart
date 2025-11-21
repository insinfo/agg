import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'dart:math' as math;
import 'package:agg/src/agg/line_aa_basics.dart';
import 'package:agg/src/agg/outline_image_renderer.dart';
import 'package:agg/src/agg/rasterizer_outline_aa.dart';
import 'package:agg/src/agg/scanline_renderer.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/scanline_unpacked8.dart';
import 'package:agg/src/agg/vertex_source/i_vertex_source.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';
import 'package:agg/src/agg/vertex_source/arc.dart';
import 'package:agg/src/typography/openfont/glyph.dart';
import 'package:agg/src/typography/openfont/typeface.dart';
import 'package:agg/src/typography/text_layout/glyph_layout.dart';
import 'package:agg/src/agg/svg/svg_parser.dart';
import 'package:agg/src/agg/svg/colored_vertex_source.dart';

abstract class IStyleHandler {
  bool is_solid(int style);
}

enum TransformQuality { Fastest, Best }

/// Minimal graphics context binding an image, rasterizer and scanline cache.
abstract class Graphics2D {
  TransformQuality _imageRenderQuality = TransformQuality.Fastest;
  TransformQuality get imageRenderQuality => _imageRenderQuality;
  set imageRenderQuality(TransformQuality v) => _imageRenderQuality = v;

  int get width;
  int get height;

  void clear(Color color);
}

class BasicGraphics2D extends Graphics2D {
  final IImageByte destImage;
  final ScanlineRasterizer rasterizer;
  final ScanlineUnpacked8 scanline;

  BasicGraphics2D(
    this.destImage, {
    ScanlineRasterizer? rasterizer,
    ScanlineUnpacked8? scanline,
  })  : rasterizer = rasterizer ?? ScanlineRasterizer(),
        scanline = scanline ?? ScanlineUnpacked8();

  @override
  int get width => destImage.width;

  @override
  int get height => destImage.height;

  @override
  void clear(Color color) {
    for (int y = 0; y < destImage.height; y++) {
      destImage.copy_hline(0, y, destImage.width, color);
    }
  }

  /// Render a vertex source as a filled shape.
  void render(IVertexSource src, Color color) {
    rasterizer.reset();
    rasterizer.add_path(src);
    ScanlineRenderer.renderSolid(rasterizer, scanline, destImage, color);
    destImage.markImageChanged();
  }

  /// Draw a simple AA line using the outline rasterizer.
  void drawLine(double x1, double y1, double x2, double y2, Color color, {double thickness = 1.0}) {
    final renderer = ImageLineRenderer(
      destImage,
      color: color,
      thickness: thickness,
      cap: CapStyle.butt,
    );
    final outline = RasterizerOutlineAA(renderer);
    outline.moveTo(
      (x1 * LineAABasics.line_subpixel_scale).toInt(),
      (y1 * LineAABasics.line_subpixel_scale).toInt(),
    );
    outline.lineTo(
      (x2 * LineAABasics.line_subpixel_scale).toInt(),
      (y2 * LineAABasics.line_subpixel_scale).toInt(),
    );
    outline.render();
    destImage.markImageChanged();
  }

  /// Fill an axis-aligned rectangle.
  void fillRect(double x1, double y1, double x2, double y2, Color color) {
    final vs = VertexStorage()
      ..moveTo(x1, y1)
      ..lineTo(x2, y1)
      ..lineTo(x2, y2)
      ..lineTo(x1, y2)
      ..closePath();
    render(vs, color);
  }

  /// Stroke an axis-aligned rectangle using AA lines.
  void strokeRect(double x1, double y1, double x2, double y2, Color color, {double thickness = 1.0}) {
    drawLine(x1, y1, x2, y1, color, thickness: thickness);
    drawLine(x2, y1, x2, y2, color, thickness: thickness);
    drawLine(x2, y2, x1, y2, color, thickness: thickness);
    drawLine(x1, y2, x1, y1, color, thickness: thickness);
  }

  /// Fill a circle.
  void fillCircle(double cx, double cy, double radius, Color color) {
    fillEllipse(cx, cy, radius, radius, color);
  }

  /// Stroke a circle.
  void strokeCircle(double cx, double cy, double radius, Color color, {double thickness = 1.0}) {
    strokeEllipse(cx, cy, radius, radius, color, thickness: thickness);
  }

  /// Fill an ellipse.
  void fillEllipse(double cx, double cy, double rx, double ry, Color color) {
    final path = _arcPath(cx, cy, rx, ry, 0, math.pi * 2, closeToCenter: true);
    render(path, color);
  }

  /// Stroke an ellipse perimeter with AA lines.
  void strokeEllipse(double cx, double cy, double rx, double ry, Color color, {double thickness = 1.0}) {
    final path = _arcPath(cx, cy, rx, ry, 0, math.pi * 2, closeToCenter: false);
    _strokePath(path, color, thickness: thickness);
  }

  /// Fill an arc sector (wedge).
  void fillArc(double cx, double cy, double rx, double ry, double startAngle, double sweepAngle, Color color) {
    final path = _arcPath(cx, cy, rx, ry, startAngle, startAngle + sweepAngle, closeToCenter: true);
    render(path, color);
  }

  /// Stroke an arc outline.
  void strokeArc(
    double cx,
    double cy,
    double rx,
    double ry,
    double startAngle,
    double sweepAngle,
    Color color, {
    double thickness = 1.0,
  }) {
    final path = _arcPath(cx, cy, rx, ry, startAngle, startAngle + sweepAngle, closeToCenter: false);
    _strokePath(path, color, thickness: thickness);
  }

  /// Draw filled text using the Typography pipeline. [x], [y] represent the
  /// top-left origin; baseline is computed using the font ascender.
  void drawText(String text, Typeface typeface, double pixelSize, Color color, {double x = 0, double y = 0}) {
    final layout = GlyphLayout()..typeface = typeface;
    final scale = typeface.calculateScaleToPixel(pixelSize);
    final ascender = typeface.ascender * scale;
    layout.layout(text);
    final plans = layout.generateGlyphPlans(scale);

    for (final plan in plans.plans) {
      final glyph = typeface.getGlyph(plan.glyphIndex);
      final path = _glyphToPath(glyph, scale, x + plan.x, y + ascender);
      if (path != null) {
        render(path, color);
      }
    }
  }

  VertexStorage _arcPath(double cx, double cy, double rx, double ry, double start, double end,
      {bool closeToCenter = false}) {
    final arc = Arc(cx, cy, rx, ry, start, end);
    final vs = VertexStorage();
    var first = true;
    for (final v in arc.vertices()) {
      if (first) {
        vs.moveTo(v.x, v.y);
        first = false;
      } else {
        vs.lineTo(v.x, v.y);
      }
    }
    if (closeToCenter) {
      vs.lineTo(cx, cy);
      vs.closePath();
    } else {
      vs.closePath();
    }
    return vs;
  }

  void _strokePath(VertexStorage path, Color color, {double thickness = 1.0}) {
    final points = <math.Point<double>>[];
    for (final v in path.vertices()) {
      if (v.command.isMoveTo || v.command.isLineTo) {
        points.add(math.Point(v.x, v.y));
      }
    }
    for (int i = 0; i + 1 < points.length; i++) {
      drawLine(points[i].x, points[i].y, points[i + 1].x, points[i + 1].y, color, thickness: thickness);
    }
  }

  VertexStorage? _glyphToPath(Glyph glyph, double scale, double dx, double baselineY) {
    final pts = glyph.glyphPoints;
    final ends = glyph.contourEndPoints;
    if (pts == null || pts.isEmpty || ends == null || ends.isEmpty) return null;

    final vs = VertexStorage();
    int contourStart = 0;
    for (final end in ends) {
      final contour = pts.sublist(contourStart, end + 1);
      contourStart = end + 1;
      if (contour.isEmpty) continue;

      final count = contour.length;
      GlyphPointF startPoint;
      GlyphPointF prevPoint;

      final lastPoint = contour[count - 1];
      final firstPoint = contour[0];
      if (firstPoint.onCurve) {
        startPoint = firstPoint;
        prevPoint = firstPoint;
      } else {
        final prev = lastPoint.onCurve ? lastPoint : GlyphPointF(
          (lastPoint.x + firstPoint.x) * 0.5,
          (lastPoint.y + firstPoint.y) * 0.5,
          true,
        );
        startPoint = prev;
        prevPoint = prev;
      }

      vs.moveTo(dx + startPoint.x * scale, baselineY - startPoint.y * scale);

      for (int i = 0; i < count; i++) {
        final curr = contour[(i + 1) % count];
        if (prevPoint.onCurve && curr.onCurve) {
          vs.lineTo(dx + curr.x * scale, baselineY - curr.y * scale);
          prevPoint = curr;
        } else if (prevPoint.onCurve && !curr.onCurve) {
          final next = contour[(i + 2) % count];
          if (next.onCurve) {
            vs.curve3(
              curr.x * scale + dx,
              baselineY - curr.y * scale,
              next.x * scale + dx,
              baselineY - next.y * scale,
            );
            prevPoint = next;
            i++; // consumed one extra
          } else {
            final mid = GlyphPointF((curr.x + next.x) * 0.5, (curr.y + next.y) * 0.5, true);
            vs.curve3(
              curr.x * scale + dx,
              baselineY - curr.y * scale,
              mid.x * scale + dx,
              baselineY - mid.y * scale,
            );
            prevPoint = mid;
            i++; // consumed next as part of midpoint
          }
        } else {
          // prev off-curve
          if (curr.onCurve) {
            vs.curve3(
              prevPoint.x * scale + dx,
              baselineY - prevPoint.y * scale,
              curr.x * scale + dx,
              baselineY - curr.y * scale,
            );
            prevPoint = curr;
          } else {
            final mid = GlyphPointF((prevPoint.x + curr.x) * 0.5, (prevPoint.y + curr.y) * 0.5, true);
            vs.curve3(
              prevPoint.x * scale + dx,
              baselineY - prevPoint.y * scale,
              mid.x * scale + dx,
              baselineY - mid.y * scale,
            );
            prevPoint = mid;
          }
        }
      }
      vs.closePath();
    }
    return vs;
  }

  /// Render basic SVG content (paths/polygons) parsed from [svgString].
  void drawSvgString(String svgString, {bool flipY = false}) {
    final shapes = SvgParser.parseString(svgString, flipY: flipY);
    for (final ColoredVertexSource cvs in shapes) {
      render(cvs.vertices, cvs.fill);
    }
  }
}
