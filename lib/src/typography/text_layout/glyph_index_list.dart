// MIT, 2016-present, WinterDev
// Ported to Dart by insinfo, 2025
import '../openfont/tables/i_glyph_index_list.dart';
import 'user_char_to_glyph_index_map.dart';

/// Maps a glyph index to a user codepoint
class GlyphIndexToUserCodePoint {
  /// Offset into the original codepoint array
  final int codepointCharOffset;

  /// Length in codepoints (for ligatures, this is > 1)
  final int length;

  const GlyphIndexToUserCodePoint(this.codepointCharOffset, this.length);

  @override
  String toString() =>
      'GlyphIndexToUserCodePoint(offset: $codepointCharOffset, len: $length)';
}

/// List of glyph indices with mapping back to user codepoints
///
/// This class is used during glyph substitution (e.g., ligatures)
/// to track which user codepoints each glyph represents.
class GlyphIndexList implements IGlyphIndexList {
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
  /// Replace glyphs (e.g., for ligatures)
  ///
  /// Removes [removeLen] glyphs starting at [index] and replaces them
  /// with a single [newGlyphIndex]. This is used for ligatures where
  /// multiple characters become one glyph.
  @override
  void replaceRange(int index, int removeLen, int newGlyphIndex) {
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

  @override
  void replace(int index, int newGlyphIndex) {
    replaceRange(index, 1, newGlyphIndex);
  }

  /// Replace one glyph with multiple glyphs
  ///
  /// Removes the glyph at [index] and replaces it with [newGlyphIndices].
  @override
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
  @override
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

  /// Build a map from user codepoint positions to glyph indices after substitution.
  void createMapFromUserCodePointToGlyphIndices(
    List<UserCodePointToGlyphIndex> output,
  ) {
    // Step 1: seed with codepoint order.
    for (final codepointIndex in _inputCodePointIndexList) {
      output.add(UserCodePointToGlyphIndex(
        userCodePointIndex: codepointIndex,
      ));
    }

    // Step 2: fill each codepoint entry with glyph offsets/lengths.
    for (var i = 0; i < _glyphIndices.length; i++) {
      final map = _mapGlyphIndexToUserCodePoint[i];
      final entry = output[map.codepointCharOffset];
      entry.appendData(i + 1, map.length); // 1-based offset
      output[map.codepointCharOffset] = entry;
    }
  }

  @override
  String toString() => 'GlyphIndexList(count: $count)';
}
