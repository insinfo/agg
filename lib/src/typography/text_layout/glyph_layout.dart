import '../openfont/typeface.dart';
import 'glyph_index_list.dart';
import 'glyph_plan.dart';
import 'glyph_pos_stream.dart';
import 'glyph_set_position.dart';
import 'glyph_substitution.dart';
import 'script_lang.dart';

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
/// 2. Glyph substitution (ligatures, etc.)
/// 3. Glyph positioning (kerning, marks)
class GlyphLayout {
  Typeface? _typeface;
  PositionTechnique positionTechnique = PositionTechnique.openFont;
  bool _enableLigature = true;
  bool _enableComposition = true;
  ScriptLang _scriptLang = ScriptLang.latin;

  final GlyphIndexList _inputGlyphs = GlyphIndexList();
  final UnscaledGlyphPlanList _unscaledPlans = UnscaledGlyphPlanList();
  final GlyphPosStream _glyphPositions = GlyphPosStream();

  final GlyphLayoutPlanCollection _layoutPlanCollection =
      GlyphLayoutPlanCollection();
  GlyphSubstitution? _gsub;
  GlyphSetPosition? _gpos;
  bool _needPlanUpdate = true;

  /// Set the typeface to use for layout
  set typeface(Typeface? value) {
    if (_typeface != value) {
      _typeface = value;
      _needPlanUpdate = true;
    }
  }

  /// Get the current typeface
  Typeface? get typeface => _typeface;

  /// Current script language used to query OpenType features
  ScriptLang get scriptLang => _scriptLang;
  set scriptLang(ScriptLang value) {
    if (_scriptLang.shortname != value.shortname) {
      _scriptLang = value;
      _needPlanUpdate = true;
    }
  }

  /// Enable or disable standard ligature substitution
  bool get enableLigature => _enableLigature;
  set enableLigature(bool value) {
    if (_enableLigature != value) {
      _enableLigature = value;
      _needPlanUpdate = true;
    }
  }

  /// Enable or disable glyph composition (ccmp)
  bool get enableComposition => _enableComposition;
  set enableComposition(bool value) {
    if (_enableComposition != value) {
      _enableComposition = value;
      _needPlanUpdate = true;
    }
  }

  /// Layout text and generate unscaled glyph plans
  ///
  /// [text] - the text to layout
  /// Returns a list of unscaled glyph plans
  UnscaledGlyphPlanList layout(String text) {
    if (_typeface == null) {
      throw StateError('Typeface must be set before calling layout');
    }

    final codepoints = _stringToCodepoints(text);
    return layoutCodepoints(codepoints);
  }

  /// Layout a list of Unicode codepoints
  UnscaledGlyphPlanList layoutCodepoints(List<int> codepoints) {
    if (_typeface == null) {
      throw StateError('Typeface must be set before calling layout');
    }

    _inputGlyphs.clear();
    for (var i = 0; i < codepoints.length; i++) {
      final codepoint = codepoints[i];
      final nextCodepoint = i + 1 < codepoints.length ? codepoints[i + 1] : 0;
      final glyphIndex = _typeface!.getGlyphIndex(codepoint, nextCodepoint);
      _inputGlyphs.addGlyph(i, glyphIndex);
    }

    _layoutGlyphIndices();
    return _unscaledPlans;
  }

  void _layoutGlyphIndices() {
    if (_typeface == null) {
      throw StateError('Typeface must be set before layout');
    }

    if (_needPlanUpdate) {
      _updateLayoutPlan();
    }

    if (_gsub != null && _inputGlyphs.count > 0) {
      _gsub!.enableLigation = _enableLigature;
      _gsub!.enableComposition = _enableComposition;
      _gsub!.doSubstitution(_inputGlyphs);
    }

    _buildGlyphPositions();

    if (positionTechnique == PositionTechnique.openFont &&
        _gpos != null &&
        _glyphPositions.count > 1) {
      _gpos!.doGlyphPosition(_glyphPositions);
    }

    _generateUnscaledPlansFromPositions();
  }

  void _buildGlyphPositions() {
    _glyphPositions.clear();
    _glyphPositions.typeface = _typeface;

    for (var i = 0; i < _inputGlyphs.count; i++) {
      final glyphIndex = _inputGlyphs[i];
      final mapping = _inputGlyphs.getMapping(i);
      final glyph = _typeface!.getGlyph(glyphIndex);
      _glyphPositions.addGlyph(mapping.codepointCharOffset, glyphIndex, glyph);
    }
  }

  void _generateUnscaledPlansFromPositions() {
    _unscaledPlans.clear();

    for (var i = 0; i < _glyphPositions.count; i++) {
      final glyphPos = _glyphPositions.getGlyph(i);
      _unscaledPlans.append(UnscaledGlyphPlan(
        inputCodepointOffset: glyphPos.inputOffset,
        glyphIndex: glyphPos.glyphIndex,
        advanceX: glyphPos.advanceW,
        offsetX: glyphPos.xoffset,
        offsetY: glyphPos.yoffset,
      ));
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

  List<int> _stringToCodepoints(String text) {
    final codepoints = <int>[];
    final runes = text.runes.toList();
    codepoints.addAll(runes);
    return codepoints;
  }

  void clear() {
    _inputGlyphs.clear();
    _unscaledPlans.clear();
    _glyphPositions.clear();
    _needPlanUpdate = true;
  }

  void _updateLayoutPlan() {
    if (_typeface == null) {
      return;
    }

    final context =
        _layoutPlanCollection.getPlanOrCreate(_typeface!, _scriptLang);
    _gsub = context.glyphSubstitution;
    _gpos = context.glyphSetPosition;
    _needPlanUpdate = false;
  }
}

class GlyphLayoutPlanCollection {
  final Map<_GlyphLayoutPlanKey, GlyphLayoutPlanContext> _collection = {};

  GlyphLayoutPlanContext getPlanOrCreate(
      Typeface typeface, ScriptLang scriptLang) {
    final key = _GlyphLayoutPlanKey(typeface, scriptLang.normalizedTag);
    return _collection.putIfAbsent(key, () {
      final glyphSub = typeface.gsubTable != null
          ? GlyphSubstitution(typeface.gsubTable!, scriptLang.normalizedTag)
          : null;
      final glyphPos = typeface.gposTable != null
          ? GlyphSetPosition(typeface.gposTable!, scriptLang.normalizedTag)
          : null;
      return GlyphLayoutPlanContext(
        glyphSubstitution: glyphSub,
        glyphSetPosition: glyphPos,
      );
    });
  }
}

class GlyphLayoutPlanContext {
  final GlyphSubstitution? glyphSubstitution;
  final GlyphSetPosition? glyphSetPosition;

  GlyphLayoutPlanContext({this.glyphSubstitution, this.glyphSetPosition});
}

class _GlyphLayoutPlanKey {
  final Typeface typeface;
  final String scriptTag;

  _GlyphLayoutPlanKey(this.typeface, this.scriptTag);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _GlyphLayoutPlanKey &&
        identical(typeface, other.typeface) &&
        scriptTag == other.scriptTag;
  }

  @override
  int get hashCode => identityHashCode(typeface) ^ scriptTag.hashCode;
}
