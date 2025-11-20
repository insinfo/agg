/// Replaceable glyph index list interface
abstract class IGlyphIndexList {
  int get count;
  int operator [](int index);

  /// remove:add_new 1:1
  void replace(int index, int newGlyphIndex);

  /// remove:add_new >=1:1
  void replaceRange(int index, int removeLen, int newGlyphIndex);

  /// remove: add_new 1:>=1
  void replaceWithMultiple(int index, List<int> newGlyphIndices);
}
