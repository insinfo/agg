// MIT, 2016-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../openfont/typeface.dart';
import 'glyph_index_list.dart';
import 'glyph_plan.dart';

/// Position technique for glyph layout
enum PositionTechnique {
  /// Use OpenFont (OpenType) positioning
  openFont,
  
  /// Use kern table only
  kern,
  
  /// No positioning
  none,
}

/// Main glyph layout engine
/// 
/// This class handles the conversion of text (codepoints) to positioned glyphs.
/// It performs:
/// 1. Codepoint to glyph index mapping
/// 2. Glyph substitution (ligatures, etc.) - when GSUB support is added
/// 3. Glyph positioning (kerning, etc.) - when GPOS support is added
class GlyphLayout {
  Typeface? _typeface;
  PositionTechnique positionTechnique = PositionTechnique.openFont;
  bool enableLigature = true;
  bool enableComposition = true;

  final GlyphIndexList _inputGlyphs = GlyphIndexList();
  final UnscaledGlyphPlanList _unscaledPlans = UnscaledGlyphPlanList();

  /// Set the typeface to use for layout
  set typeface(Typeface? value) {
    _typeface = value;
  }

  /// Get the current typeface
  Typeface? get typeface => _typeface;

  /// Layout text and generate unscaled glyph plans
  /// 
  /// [text] - the text to layout
  /// Returns a list of unscaled glyph plans
  UnscaledGlyphPlanList layout(String text) {
    if (_typeface == null) {
      throw StateError('Typeface must be set before calling layout');
    }

    // Convert string to codepoints
    final codepoints = _stringToCodepoints(text);

    // Layout the codepoints
    return layoutCodepoints(codepoints);
  }

  /// Layout a list of Unicode codepoints
  UnscaledGlyphPlanList layoutCodepoints(List<int> codepoints) {
    if (_typeface == null) {
      throw StateError('Typeface must be set before calling layout');
    }

    // Convert codepoints to glyph indices
    _inputGlyphs.clear();
    
    for (var i = 0; i < codepoints.length; i++) {
      final codepoint = codepoints[i];
      final nextCodepoint = i + 1 < codepoints.length ? codepoints[i + 1] : 0;
      
      var glyphIndex = _typeface!.getGlyphIndex(codepoint, nextCodepoint);
      
      // If glyph not found, use glyph 0 (notdef)
      if (glyphIndex == 0 && codepoint != 0) {
        // Could add a callback here for handling missing glyphs
      }
      
      _inputGlyphs.addGlyph(i, glyphIndex);
    }

    // TODO: Apply glyph substitution (GSUB) when implemented
    // if (enableLigature || enableComposition) {
    //   _gsub?.doSubstitution(_inputGlyphs);
    // }

    // Generate unscaled glyph plans
    _generateUnscaledPlans();

    return _unscaledPlans;
  }

  /// Generate unscaled glyph plans from glyph indices
  void _generateUnscaledPlans() {
    _unscaledPlans.clear();

    for (var i = 0; i < _inputGlyphs.count; i++) {
      final glyphIndex = _inputGlyphs[i];
      final mapping = _inputGlyphs.getMapping(i);
      
      // Get horizontal advance width
      final advanceWidth = _typeface!.getHAdvanceWidthFromGlyphIndex(glyphIndex);
      
      // TODO: Apply positioning (GPOS) when implemented
      // For now, use simple advance with no offsets
      
      final plan = UnscaledGlyphPlan(
        inputCodepointOffset: mapping.codepointCharOffset,
        glyphIndex: glyphIndex,
        advanceX: advanceWidth,
        offsetX: 0,
        offsetY: 0,
      );
      
      _unscaledPlans.append(plan);
    }
  }

  /// Convert unscaled plans to scaled (pixel) plans
  /// 
  /// [scale] - the scale factor (from Typeface.calculateScaleToPixel)
  GlyphPlanSequence generateGlyphPlans(double scale) {
    final sequence = GlyphPlanSequence();
    var currentX = 0.0;

    for (var i = 0; i < _unscaledPlans.count; i++) {
      final unscaled = _unscaledPlans[i];
      
      final plan = GlyphPlan(
        glyphIndex: unscaled.glyphIndex,
        x: currentX + (unscaled.offsetX * scale),
        y: unscaled.offsetY * scale,
        advanceX: unscaled.advanceX * scale,
      );
      
      sequence.add(plan);
      currentX += plan.advanceX;
    }

    return sequence;
  }

  /// Convert a string to a list of Unicode codepoints
  /// 
  /// This handles surrogate pairs correctly to support characters
  /// outside the Basic Multilingual Plane (e.g., emoji, historic scripts)
  List<int> _stringToCodepoints(String text) {
    final codepoints = <int>[];
    final runes = text.runes.toList();
    codepoints.addAll(runes);
    return codepoints;
  }

  /// Clear all cached data
  void clear() {
    _inputGlyphs.clear();
    _unscaledPlans.clear();
  }
}
