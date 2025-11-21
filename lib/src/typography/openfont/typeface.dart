// MIT, 2016-present, WinterDev
// Apache2, 2014-2016, Samuel Carlsson, WinterDev
// Ported to Dart by insinfo, 2025

import 'glyph.dart';
import 'tables/cmap.dart';
import 'tables/gpos.dart';
import 'tables/gdef.dart';
import 'tables/gsub.dart';
import 'tables/hhea.dart';
import 'tables/hmtx.dart';
import 'tables/maxp.dart';
import 'tables/name_entry.dart';
import 'tables/os2.dart';
import 'tables/utils.dart';

/// Represents a complete typeface with all its tables and glyphs
class Typeface {
  final Bounds _bounds;
  final int _unitsPerEm;
  final List<Glyph> _glyphs;
  final HorizontalMetrics _horizontalMetrics;
  final NameEntry _nameEntry;
  final OS2Table _os2Table;

  // Optional tables
  Cmap? cmapTable;
  MaxProfile? maxProfile;
  HorizontalHeader? hheaTable;
  String? filename;
  GDEF? gdefTable;
  GSUB? gsubTable;
  GPOS? gposTable;

  Typeface._({
    required NameEntry nameEntry,
    required Bounds bounds,
    required int unitsPerEm,
    required List<Glyph> glyphs,
    required HorizontalMetrics horizontalMetrics,
    required OS2Table os2Table,
    this.cmapTable,
    this.maxProfile,
    this.hheaTable,
    this.filename,
    this.gdefTable,
    this.gsubTable,
    this.gposTable,
  })  : _nameEntry = nameEntry,
        _bounds = bounds,
        _unitsPerEm = unitsPerEm,
        _glyphs = glyphs,
        _horizontalMetrics = horizontalMetrics,
        _os2Table = os2Table;

  /// Creates a Typeface from TrueType tables
  factory Typeface.fromTrueType({
    required NameEntry nameEntry,
    required Bounds bounds,
    required int unitsPerEm,
    required List<Glyph> glyphs,
    required HorizontalMetrics horizontalMetrics,
    required OS2Table os2Table,
    Cmap? cmapTable,
    MaxProfile? maxProfile,
    HorizontalHeader? hheaTable,
    String? filename,
    GDEF? gdefTable,
    GSUB? gsubTable,
    GPOS? gposTable,
  }) {
    final typeface = Typeface._(
      nameEntry: nameEntry,
      bounds: bounds,
      unitsPerEm: unitsPerEm,
      glyphs: glyphs,
      horizontalMetrics: horizontalMetrics,
      os2Table: os2Table,
      cmapTable: cmapTable,
      maxProfile: maxProfile,
      hheaTable: hheaTable,
      filename: filename,
      gdefTable: gdefTable,
      gsubTable: gsubTable,
      gposTable: gposTable,
    );
    gdefTable?.fillGlyphData(typeface._glyphs);

    final markGlyphSets = gdefTable?.markGlyphSetsTable;
    if (markGlyphSets != null) {
      gposTable?.setMarkGlyphSets(markGlyphSets);
      gsubTable?.setMarkGlyphSets(markGlyphSets);
    }

    if (gsubTable != null) {
      GlyphClassResolver resolver =
          (int glyphIndex) => (glyphIndex >= 0 && glyphIndex < glyphs.length)
              ? glyphs[glyphIndex].glyphClass
              : GlyphClassKind.zero;
      GlyphMarkClassResolver markResolver =
          (int glyphIndex) => (glyphIndex >= 0 && glyphIndex < glyphs.length)
              ? glyphs[glyphIndex].markClassDef
              : 0;
      gsubTable
        ..setGlyphClassResolver(resolver)
        ..setMarkAttachmentClassResolver(markResolver);
    }

    return typeface;
  }

  // Font metrics from OS/2 table

  /// OS2 sTypoAscender, in font designed unit
  int get ascender => _os2Table.sTypoAscender;

  /// OS2 sTypoDescender, in font designed unit
  int get descender => _os2Table.sTypoDescender;

  /// OS2 usWinAscent
  int get clipedAscender => _os2Table.usWinAscent;

  /// OS2 usWinDescent
  int get clipedDescender => _os2Table.usWinDescent;

  /// OS2 Linegap - typographic line gap
  /// 
  /// The suggested usage for sTypoLineGap is that it be used in conjunction
  /// with unitsPerEm to compute a typographically correct default line spacing.
  /// Typical values average 7-10% of units per em.
  int get lineGap => _os2Table.sTypoLineGap;

  // Font names from Name table

  /// Font family name
  String get name => _nameEntry.fontName;

  /// Font subfamily name (Regular, Bold, Italic, etc.)
  String get fontSubFamily => _nameEntry.fontSubFamily;

  /// PostScript name
  String? get postScriptName => _nameEntry.postScriptName;

  /// Version string
  String? get versionString => _nameEntry.versionString;

  /// Unique font identifier
  String? get uniqueFontIdentifier => _nameEntry.uniqueFontIden;

  // Glyph access

  /// Total number of glyphs in the font
  int get glyphCount => _glyphs.length;

  /// Get all glyphs
  List<Glyph> get glyphs => _glyphs;

  /// Font bounding box
  Bounds get bounds => _bounds;

  /// Units per em (typically 1000 for PostScript, 2048 for TrueType)
  int get unitsPerEm => _unitsPerEm;

  /// Find glyph index by Unicode codepoint
  int getGlyphIndex(int codepoint, [int nextCodepoint = 0]) {
    if (cmapTable == null) return 0;
    return cmapTable!.getGlyphIndex(codepoint, nextCodepoint);
  }

  /// Get a glyph by its index
  Glyph getGlyph(int glyphIndex) {
    if (glyphIndex >= 0 && glyphIndex < _glyphs.length) {
      return _glyphs[glyphIndex];
    }
    // Return empty glyph for invalid index
    return _glyphs[0];
  }

  /// Get glyph by Unicode codepoint
  Glyph getGlyphByCodepoint(int codepoint) {
    final glyphIndex = getGlyphIndex(codepoint);
    return getGlyph(glyphIndex);
  }

  /// Get horizontal advance width for a codepoint
  int getAdvanceWidth(int codepoint) {
    return _horizontalMetrics.getAdvanceWidth(getGlyphIndex(codepoint));
  }

  /// Get horizontal advance width from glyph index
  int getHAdvanceWidthFromGlyphIndex(int glyphIndex) {
    return _horizontalMetrics.getAdvanceWidth(glyphIndex);
  }

  /// Get horizontal front side bearing (left side bearing) from glyph index
  int getHFrontSideBearingFromGlyphIndex(int glyphIndex) {
    return _horizontalMetrics.getLeftSideBearing(glyphIndex);
  }

  // Scaling utilities

  static const int _pointsPerInch = 72;

  /// Convert from point-unit value to pixel value
  /// 
  /// [targetPointSize] - font size in points
  /// [resolution] - DPI resolution (default 96)
  static double convertPointsToPixels(double targetPointSize, [int resolution = 96]) {
    // pixels = targetPointSize * resolution / pointsPerInch
    return targetPointSize * resolution / _pointsPerInch;
  }

  /// Calculate scale to target pixel size based on current typeface's UnitsPerEm
  /// 
  /// [targetPixelSize] - target font size in pixels
  double calculateScaleToPixel(double targetPixelSize) {
    return targetPixelSize / unitsPerEm;
  }

  /// Calculate scale to target pixel size from point size
  /// 
  /// [targetPointSize] - target font size in points
  /// [resolution] - DPI resolution (default 96)
  double calculateScaleToPixelFromPointSize(double targetPointSize, [int resolution = 96]) {
    // 1. Convert points to pixels
    // 2. Scale based on unitsPerEm
    return (targetPointSize * resolution / _pointsPerInch) / unitsPerEm;
  }

  @override
  String toString() {
    return 'Typeface(name: $name, subfamily: $fontSubFamily, '
        'glyphCount: $glyphCount, unitsPerEm: $unitsPerEm)';
  }
}
