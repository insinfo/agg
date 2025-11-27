import 'package:agg/src/agg/vertex_source/vertex_storage.dart';
import 'package:agg/src/agg/svg/svg_paint.dart';

enum StrokeLineCap { butt, round, square }
enum StrokeLineJoin { miter, round, bevel }

class SvgShape {
  final VertexStorage path;
  final SvgPaint? fill;
  final SvgPaint? stroke;
  final double strokeWidth;
  final double opacity;
  final double fillOpacity;
  final double strokeOpacity;
  final StrokeLineCap strokeLineCap;
  final StrokeLineJoin strokeLineJoin;
  final double strokeMiterLimit;

  SvgShape(
    this.path, {
    this.fill,
    this.stroke,
    this.strokeWidth = 1.0,
    this.opacity = 1.0,
    this.fillOpacity = 1.0,
    this.strokeOpacity = 1.0,
    this.strokeLineCap = StrokeLineCap.butt,
    this.strokeLineJoin = StrokeLineJoin.miter,
    this.strokeMiterLimit = 4.0,
  });
}
