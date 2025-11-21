/// Mapping from a user codepoint (input index) to glyph indices produced by layout.
///
/// `glyphIndexListOffsetPlus1` is 1-based; a value of 0 means "no glyph".
class UserCodePointToGlyphIndex {
  /// 1-based offset into the glyph index list. Zero means no mapping.
  int glyphIndexListOffsetPlus1;

  /// Number of glyphs associated with this codepoint.
  int len;

  /// Original index of the codepoint in the input buffer.
  int userCodePointIndex;

  UserCodePointToGlyphIndex({
    this.glyphIndexListOffsetPlus1 = 0,
    this.len = 0,
    this.userCodePointIndex = 0,
  });

  /// Append new mapping data, merging consecutive glyph ranges when possible.
  void appendData(int glyphIndexListOffsetPlus1, int len) {
    if (glyphIndexListOffsetPlus1 == 0) {
      return;
    }

    // If we already have contiguous data, extend it; otherwise replace.
    if (this.glyphIndexListOffsetPlus1 != 0) {
      final expectedNext = this.glyphIndexListOffsetPlus1 + this.len;
      if (expectedNext == glyphIndexListOffsetPlus1 && len == 1) {
        this.len += 1;
        return;
      }
    }

    this.glyphIndexListOffsetPlus1 = glyphIndexListOffsetPlus1;
    this.len = len;
  }

  @override
  String toString() =>
      'UserCodePointToGlyphIndex(userIdx: $userCodePointIndex, '
      'offset+: $glyphIndexListOffsetPlus1, len: $len)';
}
