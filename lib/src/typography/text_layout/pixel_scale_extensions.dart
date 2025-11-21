import '../openfont/typeface.dart';
import 'glyph_layout.dart';
import 'glyph_plan.dart';

/// Scaled glyph plan for a specific pixel size.
///
/// The offsets and advance are already multiplied by the
/// scale factor (pixels per font unit).
class PxScaledGlyphPlan {
  final int inputCodepointOffset;
  final int glyphIndex;
  final double advanceX;
  final double offsetX;
  final double offsetY;

  const PxScaledGlyphPlan({
    required this.inputCodepointOffset,
    required this.glyphIndex,
    required this.advanceX,
    required this.offsetX,
    required this.offsetY,
  });

  bool get advanceMoveForward => advanceX > 0;

  @override
  String toString() =>
      'PxScaledGlyphPlan(glyph: $glyphIndex, adv: $advanceX, '
      'offset: ($offsetX, $offsetY))';
}

/// Iterator-style view over unscaled glyph plans with pixel scaling applied.
///
/// This is a lightweight helper that mirrors the C# `GlyphPlanSequencePixelScaleLayout`
/// struct but works on the Dart `UnscaledGlyphPlanList`.
class GlyphPlanSequencePixelScaleLayout {
  final UnscaledGlyphPlanList _plans;
  final double _pxScale;

  int _index = 0;
  double _accumWidth = 0;
  double _exactX = 0;
  double _exactY = 0;
  int _currentGlyphIndex = 0;

  GlyphPlanSequencePixelScaleLayout(this._plans, this._pxScale);

  int get currentIndex => _index;
  double get accumWidth => _accumWidth;
  double get exactX => _exactX;
  double get exactY => _exactY;
  int get currentGlyphIndex => _currentGlyphIndex;

  /// Current scaled glyph plan.
  PxScaledGlyphPlan get glyphPlan {
    final unscaled = _plans[_index];
    final scaledAdv = unscaled.advanceX * _pxScale;
    return PxScaledGlyphPlan(
      inputCodepointOffset: unscaled.inputCodepointOffset,
      glyphIndex: unscaled.glyphIndex,
      advanceX: scaledAdv,
      offsetX: unscaled.offsetX * _pxScale,
      offsetY: unscaled.offsetY * _pxScale,
    );
  }

  /// Advance to next glyph; returns false when finished.
  bool read() {
    if (_index >= _plans.count) {
      return false;
    }

    final unscaled = _plans[_index];
    final scaledAdv = unscaled.advanceX * _pxScale;

    _exactX = _accumWidth + (unscaled.advanceX + unscaled.offsetX) * _pxScale;
    _exactY = unscaled.offsetY * _pxScale;
    _accumWidth += scaledAdv;
    _currentGlyphIndex = unscaled.glyphIndex;
    _index++;
    return true;
  }
}

/// Iterator-style view with snap-to-grid semantics (integer pixel positions).
class GlyphPlanSequenceSnapPixelScaleLayout {
  final UnscaledGlyphPlanList _plans;
  final double _pxScale;

  int _index = 0;
  int _accumWidth = 0;
  int _exactX = 0;
  int _exactY = 0;
  int _currentGlyphIndex = 0;

  GlyphPlanSequenceSnapPixelScaleLayout(this._plans, this._pxScale);

  int get currentIndex => _index;
  int get accumWidth => _accumWidth;
  int get exactX => _exactX;
  int get exactY => _exactY;
  int get currentGlyphIndex => _currentGlyphIndex;

  /// Advance to next glyph; returns false when finished.
  bool read() {
    if (_index >= _plans.count) {
      return false;
    }

    final unscaled = _plans[_index];
    final scaledAdv = (unscaled.advanceX * _pxScale).round();
    final scaledOffsetX = (unscaled.offsetX * _pxScale).round();
    final scaledOffsetY = (unscaled.offsetY * _pxScale).round();

    _exactX = _accumWidth + scaledOffsetX;
    _exactY = scaledOffsetY;
    _accumWidth += scaledAdv;
    _currentGlyphIndex = unscaled.glyphIndex;
    _index++;
    return true;
  }
}

/// Measured box for a laid out string at a given pixel size.
class MeasuredStringBox {
  /// Pixel-scaled width of the measured span.
  final double width;

  final double _pxScale;
  final int _ascending;
  final int _descending;
  final int _lineGap;
  final int _clipAscending;
  final int _clipDescending;

  int _stopAt;

  MeasuredStringBox(
    this.width,
    this._ascending,
    this._descending,
    this._lineGap,
    this._clipAscending,
    this._clipDescending,
    this._pxScale, {
    int stopAt = 0,
  }) : _stopAt = stopAt;

  /// Scaled ascending (in pixels).
  double get ascendingInPx => _ascending * _pxScale;

  /// Scaled descending (in pixels).
  double get descendingInPx => _descending * _pxScale;

  /// Scaled line gap (in pixels).
  double get lineGapInPx => _lineGap * _pxScale;

  /// Total clip height in pixels.
  double get clipHeightInPx => (_clipAscending + _clipDescending) * _pxScale;

  double get clipAscendingInPx => _clipAscending * _pxScale;

  double get clipDescendingInPx => _clipDescending * _pxScale;

  /// Recommended line space (baseline-to-baseline distance) in pixels.
  double get lineSpaceInPx =>
      ((_ascending - _descending) + _lineGap) * _pxScale;

  /// Number of characters that fit within a width limit (when used).
  int get stopAt => _stopAt;
  set stopAt(int value) => _stopAt = value;

  /// Scale the measured box by an additional factor.
  MeasuredStringBox scaled(double scale) {
    final box = MeasuredStringBox(
      width * scale,
      _ascending,
      _descending,
      _lineGap,
      _clipAscending,
      _clipDescending,
      _pxScale * scale,
      stopAt: _stopAt,
    );
    return box;
  }
}

double _measureGlyphPlans(
  GlyphLayout glyphLayout,
  double pxScale, {
  required bool snapToGrid,
}) {
  final positions = glyphLayout.resultUnscaledGlyphPositions;
  var accumW = 0.0;

  if (snapToGrid) {
    for (var i = 0; i < positions.count; i++) {
      final glyph = positions.getGlyph(i);
      accumW += (glyph.advanceW * pxScale).round();
    }
  } else {
    for (var i = 0; i < positions.count; i++) {
      final glyph = positions.getGlyph(i);
      accumW += glyph.advanceW * pxScale;
    }
  }
  return accumW;
}

double _measureGlyphPlansWithLimitWidth(
  GlyphLayout glyphLayout,
  double pxScale,
  double limitWidth, {
  required bool snapToGrid,
  required void Function(int stopAtGlyphIndex) onStopAtGlyphIndex,
}) {
  final positions = glyphLayout.resultUnscaledGlyphPositions;
  var accumW = 0.0;
  var stopAtGlyphIndex = 0;

  if (snapToGrid) {
    for (var i = 0; i < positions.count; i++) {
      final glyph = positions.getGlyph(i);
      stopAtGlyphIndex = i;

      final w = (glyph.advanceW * pxScale).round().toDouble();
      if (accumW + w > limitWidth) {
        break;
      }
      accumW += w;
    }
  } else {
    for (var i = 0; i < positions.count; i++) {
      final glyph = positions.getGlyph(i);
      stopAtGlyphIndex = i;

      final w = glyph.advanceW * pxScale;
      if (accumW + w > limitWidth) {
        break;
      }
      accumW += w;
    }
  }

  onStopAtGlyphIndex(stopAtGlyphIndex);
  return accumW;
}

/// Layout a string and return its measured box at the given font size.
///
/// This is a high-level helper that mirrors the C# `LayoutAndMeasureString`
/// extension. It always lays out the full [text] string; if you need to
/// measure a substring, pass the slice explicitly.
MeasuredStringBox layoutAndMeasureString(
  GlyphLayout glyphLayout,
  String text,
  double fontSizeInPoints, {
  double limitWidth = -1,
  bool snapToGrid = true,
}) {
  if (glyphLayout.typeface == null) {
    throw StateError('GlyphLayout.typeface must be set before layout');
  }

  // 1. Perform unscaled layout (in font units).
  glyphLayout.layout(text);

  // 2. Scale to specific font size.
  final Typeface typeface = glyphLayout.typeface!;
  final pxScale = typeface.calculateScaleToPixelFromPointSize(fontSizeInPoints);

  double scaledAccumX;
  if (limitWidth < 0) {
    scaledAccumX = _measureGlyphPlans(
      glyphLayout,
      pxScale,
      snapToGrid: snapToGrid,
    );
    return MeasuredStringBox(
      scaledAccumX,
      typeface.ascender,
      typeface.descender,
      typeface.lineGap,
      typeface.clipedAscender,
      typeface.clipedDescender,
      pxScale,
    );
  } else if (limitWidth > 0) {
    var stopAtGlyphIndex = 0;
    scaledAccumX = _measureGlyphPlansWithLimitWidth(
      glyphLayout,
      pxScale,
      limitWidth,
      snapToGrid: snapToGrid,
      onStopAtGlyphIndex: (i) => stopAtGlyphIndex = i,
    );

    final box = MeasuredStringBox(
      scaledAccumX,
      typeface.ascender,
      typeface.descender,
      typeface.lineGap,
      typeface.clipedAscender,
      typeface.clipedDescender,
      pxScale,
    );
    box.stopAt = stopAtGlyphIndex;
    return box;
  } else {
    return MeasuredStringBox(
      0,
      typeface.ascender,
      typeface.descender,
      typeface.lineGap,
      typeface.clipedAscender,
      typeface.clipedDescender,
      pxScale,
    );
  }
}

