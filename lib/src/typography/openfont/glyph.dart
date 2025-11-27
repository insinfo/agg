// Apache2, 2017-present, WinterDev
// Apache2, 2014-2016, Samuel Carlsson, WinterDev
// Ported to Dart by insinfo, 2025

import 'tables/utils.dart';

/// A point in a glyph contour with coordinates and on-curve flag
class GlyphPointF {
  double x;
  double y;
  final bool onCurve;

  GlyphPointF(this.x, this.y, this.onCurve);

  GlyphPointF offset(int dx, int dy) {
    return GlyphPointF(x + dx, y + dy, onCurve);
  }

  void applyScale(double scale) {
    x *= scale;
    y *= scale;
  }

  void applyScaleOnlyOnXAxis(double scale) {
    x *= scale;
  }

  void updateX(double newX) {
    x = newX;
  }

  void updateY(double newY) {
    y = newY;
  }

  void offsetX(double dx) {
    x += dx;
  }

  void offsetY(double dy) {
    y += dy;
  }

  GlyphPointF operator *(double n) {
    return GlyphPointF(x * n, y * n, onCurve);
  }

  @override
  String toString() => 'GlyphPointF($x, $y, onCurve: $onCurve)';
}

/// Glyph class definition from GDEF table
enum GlyphClassKind {
  /// Class 0 - unclassified
  zero(0),

  /// Class 1 - Base glyph (single character, spacing glyph)
  base(1),

  /// Class 2 - Ligature glyph (multiple character, spacing glyph)
  ligature(2),

  /// Class 3 - Mark glyph (non-spacing combining glyph)
  mark(3),

  /// Class 4 - Component glyph (part of single character, spacing glyph)
  component(4);

  final int value;
  const GlyphClassKind(this.value);
}

/// Represents a glyph in a font
class Glyph {
  // TrueType glyph data
  final List<GlyphPointF>? glyphPoints;
  final List<int>? contourEndPoints;
  Bounds bounds;
  List<int>? glyphInstructions;
  final int glyphIndex;

  // Metrics
  int? _originalAdvanceWidth;

  // GDEF information
  GlyphClassKind glyphClass = GlyphClassKind.zero;
  int markClassDef = 0;

  // CFF data
  Object? cffGlyphData;

  // Bitmap data
  final int? bitmapOffset;
  final int? bitmapLength;
  final int? bitmapFormat;

  // Private constructor for TTF glyphs
  Glyph._ttf({
    required this.glyphPoints,
    required this.contourEndPoints,
    required this.bounds,
    required this.glyphInstructions,
    required this.glyphIndex,
    this.cffGlyphData,
    this.bitmapOffset,
    this.bitmapLength,
    this.bitmapFormat,
  });

  /// Creates a TrueType glyph
  factory Glyph.fromTrueType({
    required List<GlyphPointF> glyphPoints,
    required List<int> contourEndPoints,
    required Bounds bounds,
    List<int>? glyphInstructions,
    required int glyphIndex,
  }) {
    return Glyph._ttf(
      glyphPoints: glyphPoints,
      contourEndPoints: contourEndPoints,
      bounds: bounds,
      glyphInstructions: glyphInstructions,
      glyphIndex: glyphIndex,
    );
  }

  /// Creates a CFF glyph
  factory Glyph.cff({
    required int glyphIndex,
    required Object cffGlyphData,
  }) {
    return Glyph._ttf(
      glyphPoints: null,
      contourEndPoints: null,
      bounds: Bounds.zero,
      glyphInstructions: null,
      glyphIndex: glyphIndex,
      cffGlyphData: cffGlyphData,
    );
  }

  /// Creates a Bitmap glyph
  factory Glyph.bitmap({
    required int glyphIndex,
    required int bitmapOffset,
    required int bitmapLength,
    required int bitmapFormat,
  }) {
    return Glyph._ttf(
      glyphPoints: null,
      contourEndPoints: null,
      bounds: Bounds.zero,
      glyphInstructions: null,
      glyphIndex: glyphIndex,
      bitmapOffset: bitmapOffset,
      bitmapLength: bitmapLength,
      bitmapFormat: bitmapFormat,
    );
  }

  /// Creates an empty glyph
  factory Glyph.empty(int glyphIndex) {
    return Glyph._ttf(
      glyphPoints: const [],
      contourEndPoints: const [],
      bounds: Bounds.zero,
      glyphInstructions: null,
      glyphIndex: glyphIndex,
    );
  }

  List<int>? get endPoints => contourEndPoints;
  bool get hasGlyphInstructions => glyphInstructions != null;

  int? get originalAdvanceWidth => _originalAdvanceWidth;
  set originalAdvanceWidth(int? value) => _originalAdvanceWidth = value;
  bool get hasOriginalAdvanceWidth => _originalAdvanceWidth != null;

  int get minX => bounds.xMin;
  int get maxX => bounds.xMax;
  int get minY => bounds.yMin;
  int get maxY => bounds.yMax;

  /// Offsets all points in the glyph by dx, dy
  static void offsetXY(Glyph glyph, int dx, int dy) {
    if (glyph.glyphPoints == null) return;

    for (final point in glyph.glyphPoints!) {
      point.x += dx;
      point.y += dy;
    }

    // Note: bounds is final, so we would need to make it mutable
    // or recreate the glyph to update bounds.
    // The C# version modifies the bounds field directly.
  }

  /// Transforms the glyph using a 2x2 matrix
  static void transformNormalWith2x2Matrix(
    Glyph glyph,
    double m00,
    double m01,
    double m10,
    double m11,
  ) {
    if (glyph.glyphPoints == null) return;

    double newXMin = 0;
    double newYMin = 0;
    double newXMax = 0;
    double newYMax = 0;

    for (var i = 0; i < glyph.glyphPoints!.length; i++) {
      final point = glyph.glyphPoints![i];
      final x = point.x;
      final y = point.y;

      // Transform normal (not homogeneous)
      final newX = (x * m00 + y * m10).roundToDouble();
      final newY = (x * m01 + y * m11).roundToDouble();

      point.x = newX;
      point.y = newY;

      // Track bounds
      if (i == 0 || newX < newXMin) newXMin = newX;
      if (i == 0 || newX > newXMax) newXMax = newX;
      if (i == 0 || newY < newYMin) newYMin = newY;
      if (i == 0 || newY > newYMax) newYMax = newY;
    }

    // Note: bounds is final, so we would need to make it mutable
    // or recreate the glyph
  }

  /// Clones a glyph with a new glyph index
  static Glyph clone(Glyph original, int newGlyphIndex) {
    return Glyph._ttf(
      glyphPoints: original.glyphPoints != null
          ? List<GlyphPointF>.from(
              original.glyphPoints!.map((p) => GlyphPointF(p.x, p.y, p.onCurve)))
          : null,
      contourEndPoints: original.contourEndPoints != null
          ? List<int>.from(original.contourEndPoints!)
          : null,
      bounds: original.bounds,
      glyphInstructions: original.glyphInstructions != null
          ? List<int>.from(original.glyphInstructions!)
          : null,
      glyphIndex: newGlyphIndex,
    );
  }

  /// Appends src glyph data to dest glyph (modifies dest)
  static void appendGlyph(Glyph dest, Glyph src) {
    if (dest.glyphPoints == null || 
        dest.contourEndPoints == null ||
        src.glyphPoints == null || 
        src.contourEndPoints == null) {
      return;
    }

    final orgDestLen = dest.contourEndPoints!.length;

    if (orgDestLen == 0) {
      // Original is empty, just copy
      dest.glyphPoints!.addAll(src.glyphPoints!);
      dest.contourEndPoints!.addAll(src.contourEndPoints!);
    } else {
      final orgLastPoint = dest.contourEndPoints![orgDestLen - 1] + 1;

      dest.glyphPoints!.addAll(src.glyphPoints!);
      dest.contourEndPoints!.addAll(src.contourEndPoints!);

      // Offset the appended contour end points
      for (var i = orgDestLen; i < dest.contourEndPoints!.length; i++) {
        dest.contourEndPoints![i] += orgLastPoint;
      }
    }

    // Note: bounds is final, would need to make it mutable
    // The C# version calculates new bounds and updates the field.
    // In Dart, we would need to recreate the glyph or make bounds mutable.
  }

  @override
  String toString() {
    return 'Glyph(index: $glyphIndex, class: $glyphClass, '
        'points: ${glyphPoints?.length ?? 0}, '
        'contours: ${contourEndPoints?.length ?? 0})';
  }
}
