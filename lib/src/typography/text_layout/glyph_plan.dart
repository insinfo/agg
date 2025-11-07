// MIT, 2016-present, WinterDev
// Ported to Dart by insinfo, 2025

/// Represents an unscaled glyph plan with positioning information
/// 
/// This structure contains the basic information needed to position a glyph
/// in font units (unscaled). The values are later scaled to pixel size.
class UnscaledGlyphPlan {
  /// Offset into the input codepoint array
  final int inputCodepointOffset;
  
  /// Glyph index in the font
  final int glyphIndex;
  
  /// Horizontal advance width in font units
  final int advanceX;
  
  /// X offset from current position in font units
  final int offsetX;
  
  /// Y offset from current position in font units
  final int offsetY;

  const UnscaledGlyphPlan({
    required this.inputCodepointOffset,
    required this.glyphIndex,
    required this.advanceX,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  /// Whether this glyph advances forward (positive advance)
  bool get advanceMoveForward => advanceX > 0;

  @override
  String toString() {
    return 'UnscaledGlyphPlan(glyph: $glyphIndex, adv: $advanceX, '
        'offset: ($offsetX, $offsetY))';
  }
}

/// List of unscaled glyph plans
class UnscaledGlyphPlanList {
  final List<UnscaledGlyphPlan> _plans = [];

  /// Add a glyph plan to the list
  void append(UnscaledGlyphPlan plan) {
    _plans.add(plan);
  }

  /// Number of glyph plans
  int get count => _plans.length;

  /// Get a glyph plan by index
  UnscaledGlyphPlan operator [](int index) => _plans[index];

  /// Get all plans
  List<UnscaledGlyphPlan> get plans => _plans;

  /// Clear all plans
  void clear() {
    _plans.clear();
  }

  @override
  String toString() => 'UnscaledGlyphPlanList(count: $count)';
}

/// Scaled glyph plan with pixel-based measurements
class GlyphPlan {
  /// Glyph index
  final int glyphIndex;
  
  /// X position in pixels
  final double x;
  
  /// Y position in pixels
  final double y;
  
  /// Advance width in pixels
  final double advanceX;

  const GlyphPlan({
    required this.glyphIndex,
    required this.x,
    required this.y,
    required this.advanceX,
  });

  @override
  String toString() {
    return 'GlyphPlan(glyph: $glyphIndex, pos: ($x, $y), adv: $advanceX)';
  }
}

/// Sequence of glyph plans
class GlyphPlanSequence {
  final List<GlyphPlan> _plans = [];

  /// Add a glyph plan
  void add(GlyphPlan plan) {
    _plans.add(plan);
  }

  /// Number of plans
  int get count => _plans.length;

  /// Get a plan by index
  GlyphPlan operator [](int index) => _plans[index];

  /// Get all plans
  List<GlyphPlan> get plans => _plans;

  /// Clear all plans
  void clear() {
    _plans.clear();
  }

  @override
  String toString() => 'GlyphPlanSequence(count: $count)';
}
