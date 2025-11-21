import '../openfont/glyph.dart';
import '../openfont/tables/gpos.dart';
import '../openfont/typeface.dart';

/// Tracks the layout information for a single glyph.
class GlyphPos {
  final int inputOffset;
  final int glyphIndex;
  final GlyphClassKind glyphClass;
  final int markAttachmentClass;

  int xoffset;
  int yoffset;
  int advanceW;

  GlyphPos({
    required this.inputOffset,
    required this.glyphIndex,
    required this.glyphClass,
    required this.markAttachmentClass,
    required this.advanceW,
    this.xoffset = 0,
    this.yoffset = 0,
  });
}

/// Holds the glyph positions produced by the layout engine and exposes helpers for GPOS.
class GlyphPosStream implements IGlyphPositions {
  final List<GlyphPos> _glyphPosList = [];
  Typeface? _typeface;

  int get count => _glyphPosList.length;

  @override
  GlyphClassKind getGlyphClassKind(int index) =>
      _glyphPosList[index].glyphClass;

  @override
  int getGlyphMarkAttachmentType(int index) =>
      _glyphPosList[index].markAttachmentClass;

  GlyphPos getGlyph(int index) => _glyphPosList[index];

  @override
  int getGlyphIndex(int index) => _glyphPosList[index].glyphIndex;

  @override
  int getGlyphAdvanceWidth(int index) => _glyphPosList[index].advanceW;

  @override
  void appendGlyphAdvance(int index, int appendAdvX, int appendAdvY) {
    final pos = _glyphPosList[index];
    pos.advanceW += appendAdvX;
    // ignore appendAdvY for horizontal layouts
  }

  @override
  void appendGlyphOffset(int index, int appendOffsetX, int appendOffsetY) {
    final pos = _glyphPosList[index];
    pos.xoffset += appendOffsetX;
    pos.yoffset += appendOffsetY;
  }

  void addGlyph(int inputOffset, int glyphIndex, Glyph glyph) {
    if (!glyph.hasOriginalAdvanceWidth) {
      if (_typeface == null) {
        throw StateError('Typeface must be set before adding glyphs');
      }
      glyph.originalAdvanceWidth =
          _typeface!.getHAdvanceWidthFromGlyphIndex(glyphIndex);
    }

    final advanceWidth = glyph.originalAdvanceWidth!;

    _glyphPosList.add(GlyphPos(
      inputOffset: inputOffset,
      glyphIndex: glyphIndex,
      glyphClass: glyph.glyphClass,
      markAttachmentClass: glyph.markClassDef,
      advanceW: advanceWidth,
    ));
  }

  void clear() {
    _glyphPosList.clear();
    _typeface = null;
  }

  set typeface(Typeface? value) => _typeface = value;
}
