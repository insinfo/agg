import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/transform/affine.dart';

abstract class SvgPaint {
  const SvgPaint();
}

class SvgPaintSolid extends SvgPaint {
  final Color color;
  const SvgPaintSolid(this.color);
}

class SvgPaintLinearGradient extends SvgPaint {
  final String id;
  final double x1, y1, x2, y2;
  final List<GradientStop> stops;
  final Affine? gradientTransform;
  final bool userSpaceOnUse;

  const SvgPaintLinearGradient({
    required this.id,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.stops,
    this.gradientTransform,
    this.userSpaceOnUse = false,
  });
}

class SvgPaintRadialGradient extends SvgPaint {
  final String id;
  final double cx, cy, r, fx, fy;
  final List<GradientStop> stops;
  final Affine? gradientTransform;
  final bool userSpaceOnUse;

  const SvgPaintRadialGradient({
    required this.id,
    required this.cx,
    required this.cy,
    required this.r,
    required this.fx,
    required this.fy,
    required this.stops,
    this.gradientTransform,
    this.userSpaceOnUse = false,
  });
}

class GradientStop {
  final double offset;
  final Color color;
  const GradientStop(this.offset, this.color);
}
