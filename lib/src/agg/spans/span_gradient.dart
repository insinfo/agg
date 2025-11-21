import 'dart:math' as math;
import '../primitives/color.dart';
import 'span_generator.dart';

/// Base class for gradient span generators.
///
/// Generates color spans based on a gradient function.
abstract class SpanGradient implements ISpanGenerator {
  final List<Color> _colorLut = [];
  int _lutSize = 256;

  SpanGradient() {
    _initializeDefaultGradient();
  }

  /// Sets the color lookup table size.
  void setLutSize(int size) {
    _lutSize = size;
    if (_colorLut.length != size) {
      _colorLut.length = size;
    }
  }

  /// Gets the lookup table size.
  int get lutSize => _lutSize;

  /// Adds a color stop to the gradient.
  void addColor(double offset, Color color) {
    final index = (offset * (_lutSize - 1)).round().clamp(0, _lutSize - 1);
    if (index < _colorLut.length) {
      _colorLut[index] = color;
    }
  }

  /// Builds the gradient lookup table from color stops.
  void buildLut(List<({double offset, Color color})> stops) {
    if (stops.isEmpty) {
      _initializeDefaultGradient();
      return;
    }

    // Sort stops by offset
    final sortedStops = List<({double offset, Color color})>.from(stops);
    sortedStops.sort((a, b) => a.offset.compareTo(b.offset));

    // Fill the lookup table with interpolated colors
    for (int i = 0; i < _lutSize; i++) {
      final t = i / (_lutSize - 1);
      _colorLut[i] = _interpolateColor(t, sortedStops);
    }
  }

  Color _interpolateColor(
      double t, List<({double offset, Color color})> stops) {
    if (t <= stops.first.offset) {
      return stops.first.color;
    }
    if (t >= stops.last.offset) {
      return stops.last.color;
    }

    // Find the two stops to interpolate between
    for (int i = 0; i < stops.length - 1; i++) {
      if (t >= stops[i].offset && t <= stops[i + 1].offset) {
        final t0 = stops[i].offset;
        final t1 = stops[i + 1].offset;
        final localT = (t - t0) / (t1 - t0);

        final c0 = stops[i].color;
        final c1 = stops[i + 1].color;

        return Color.fromRgba(
          (c0.red + (c1.red - c0.red) * localT).round(),
          (c0.green + (c1.green - c0.green) * localT).round(),
          (c0.blue + (c1.blue - c0.blue) * localT).round(),
          (c0.alpha + (c1.alpha - c0.alpha) * localT).round(),
        );
      }
    }

    return stops.last.color;
  }

  void _initializeDefaultGradient() {
    // Default: black to white gradient
    _colorLut.clear();
    for (int i = 0; i < _lutSize; i++) {
      final v = (i * 255 / (_lutSize - 1)).round();
      _colorLut.add(Color.fromRgba(v, v, v, 255));
    }
  }

  /// Gets a color from the lookup table at the given position [0..1].
  Color getColor(double t) {
    final index = (t * (_lutSize - 1)).round().clamp(0, _lutSize - 1);
    return _colorLut[index];
  }

  @override
  void prepare() {
    // Base implementation does nothing
  }
}

/// Linear gradient span generator.
class SpanGradientLinear extends SpanGradient {
  double _x1, _y1, _x2, _y2;
  double _dx = 0, _dy = 0, _length = 0;

  SpanGradientLinear(this._x1, this._y1, this._x2, this._y2) {
    _updateGradient();
  }

  void setGradient(double x1, double y1, double x2, double y2) {
    _x1 = x1;
    _y1 = y1;
    _x2 = x2;
    _y2 = y2;
    _updateGradient();
  }

  void _updateGradient() {
    _dx = _x2 - _x1;
    _dy = _y2 - _y1;
    _length = math.sqrt(_dx * _dx + _dy * _dy);
    if (_length > 0) {
      _dx /= _length;
      _dy /= _length;
    }
  }

  @override
  void generate(List<Color> span, int spanIndex, int x, int y, int len) {
    if (_length == 0) {
      // Degenerate gradient - fill with first color
      final color = getColor(0);
      for (int i = 0; i < len; i++) {
        span[spanIndex + i] = color;
      }
      return;
    }

    for (int i = 0; i < len; i++) {
      final px = x + i - _x1;
      final py = y - _y1;

      // Project point onto gradient line
      final t = (px * _dx + py * _dy) / _length;
      final clampedT = t.clamp(0.0, 1.0);

      span[spanIndex + i] = getColor(clampedT);
    }
  }
}

/// Radial gradient span generator.
class SpanGradientRadial extends SpanGradient {
  double _cx, _cy, _radius;
  double _radiusSquared = 0;

  SpanGradientRadial(this._cx, this._cy, this._radius) {
    _updateGradient();
  }

  void setGradient(double cx, double cy, double radius) {
    _cx = cx;
    _cy = cy;
    _radius = radius;
    _updateGradient();
  }

  void _updateGradient() {
    _radiusSquared = _radius * _radius;
  }

  @override
  void generate(List<Color> span, int spanIndex, int x, int y, int len) {
    if (_radius == 0) {
      // Degenerate gradient - fill with first color
      final color = getColor(0);
      for (int i = 0; i < len; i++) {
        span[spanIndex + i] = color;
      }
      return;
    }

    for (int i = 0; i < len; i++) {
      final dx = x + i - _cx;
      final dy = y - _cy;

      final distSquared = dx * dx + dy * dy;
      final t = math.sqrt(distSquared / _radiusSquared).clamp(0.0, 1.0);

      span[spanIndex + i] = getColor(t);
    }
  }
}
