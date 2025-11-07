// MIT, 2016-present, WinterDev
// Ported to Dart by insinfo, 2025

/// Maps a glyph index to a user codepoint
class GlyphIndexToUserCodePoint {
  /// Offset into the original codepoint array
  final int codepointCharOffset;
  
  /// Length in codepoints (for ligatures, this is > 1)
  final int length;

  const GlyphIndexToUserCodePoint(this.codepointCharOffset, this.length);

  @override
  String toString() => 'GlyphIndexToUserCodePoint(offset: $codepointCharOffset, len: $length)';
}

/// List of glyph indices with mapping back to user codepoints
/// 
/// This class is used during glyph substitution (e.g., ligatures)
/// to track which user codepoints each glyph represents.
class GlyphIndexList {
  final List<int> _glyphIndices = [];
  final List<GlyphIndexToUserCodePoint> _mapGlyphIndexToUserCodePoint = [];
  final List<int> _inputCodePointIndexList = [];

  /// Add a glyph with its codepoint mapping
  void addGlyph(int codepointIndex, int glyphIndex) {
    _inputCodePointIndexList.add(codepointIndex);
    _glyphIndices.add(glyphIndex);
    _mapGlyphIndexToUserCodePoint.add(
      GlyphIndexToUserCodePoint(codepointIndex, 1),
    );
  }

  /// Replace glyphs (e.g., for ligatures)
  /// 
  /// Removes [removeLen] glyphs starting at [index] and replaces them
  /// with a single [newGlyphIndex]. This is used for ligatures where
  /// multiple characters become one glyph.
  void replace(int index, int removeLen, int newGlyphIndex) {
    _glyphIndices.removeRange(index, index + removeLen);
    _glyphIndices.insert(index, newGlyphIndex);

    final firstRemove = _mapGlyphIndexToUserCodePoint[index];
    final newMap = GlyphIndexToUserCodePoint(
      firstRemove.codepointCharOffset,
      removeLen,
    );

    _mapGlyphIndexToUserCodePoint.removeRange(index, index + removeLen);
    _mapGlyphIndexToUserCodePoint.insert(index, newMap);
  }

  /// Replace one glyph with multiple glyphs
  /// 
  /// Removes the glyph at [index] and replaces it with [newGlyphIndices].
  void replaceWithMultiple(int index, List<int> newGlyphIndices) {
    _glyphIndices.removeAt(index);
    _glyphIndices.insertAll(index, newGlyphIndices);

    final current = _mapGlyphIndexToUserCodePoint[index];
    _mapGlyphIndexToUserCodePoint.removeAt(index);

    for (var i = 0; i < newGlyphIndices.length; i++) {
      final newGlyph = GlyphIndexToUserCodePoint(
        current.codepointCharOffset,
        1,
      );
      _mapGlyphIndexToUserCodePoint.insert(index + i, newGlyph);
    }
  }

  /// Number of glyphs in the list
  int get count => _glyphIndices.length;

  /// Get glyph index at position
  int operator [](int index) => _glyphIndices[index];

  /// Get all glyph indices
  List<int> get glyphIndices => _glyphIndices;

  /// Get the codepoint mapping for a glyph
  GlyphIndexToUserCodePoint getMapping(int index) {
    return _mapGlyphIndexToUserCodePoint[index];
  }

  /// Clear all data
  void clear() {
    _glyphIndices.clear();
    _mapGlyphIndexToUserCodePoint.clear();
    _inputCodePointIndexList.clear();
  }

  @override
  String toString() => 'GlyphIndexList(count: $count)';
}
