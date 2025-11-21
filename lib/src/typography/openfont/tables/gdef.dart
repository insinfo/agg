import '../../../typography/io/byte_order_swapping_reader.dart';
import '../../../typography/openfont/glyph.dart';
import 'class_def_table.dart';
import 'coverage_table.dart';
import 'table_entry.dart';
import 'utils.dart';

/// Glyph Definition (GDEF) table.
///
/// Provides glyph class definitions, mark attachment classes and additional
/// data used by GSUB/GPOS lookups.
class GDEF extends TableEntry {
  static const String tableName = 'GDEF';
  @override
  String get name => tableName;

  int majorVersion = 0;
  int minorVersion = 0;
  ClassDefTable? glyphClassDef;
  AttachmentListTable? attachmentListTable;
  LigCaretList? ligCaretList;
  ClassDefTable? markAttachmentClassDef;
  MarkGlyphSetsTable? markGlyphSetsTable;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    final tableStart = reader.position;

    majorVersion = reader.readUInt16();
    minorVersion = reader.readUInt16();

    final glyphClassDefOffset = reader.readUInt16();
    final attachListOffset = reader.readUInt16();
    final ligCaretListOffset = reader.readUInt16();
    final markAttachClassDefOffset = reader.readUInt16();

    int markGlyphSetsDefOffset = 0;
    int itemVarStoreOffset = 0;

    switch (minorVersion) {
      case 0:
        break;
      case 2:
        markGlyphSetsDefOffset = reader.readUInt16();
        break;
      case 3:
        markGlyphSetsDefOffset = reader.readUInt16();
        itemVarStoreOffset = reader.readUInt32();
        break;
      default:
        Utils.warnUnimplemented('GDEF minor version $minorVersion');
        return;
    }

    glyphClassDef = glyphClassDefOffset == 0
        ? null
        : ClassDefTable.createFrom(reader, tableStart + glyphClassDefOffset);
    attachmentListTable = attachListOffset == 0
        ? null
        : AttachmentListTable.createFrom(reader, tableStart + attachListOffset);
    ligCaretList = ligCaretListOffset == 0
        ? null
        : LigCaretList.createFrom(reader, tableStart + ligCaretListOffset);
    markAttachmentClassDef = markAttachClassDefOffset == 0
        ? null
        : ClassDefTable.createFrom(
            reader, tableStart + markAttachClassDefOffset);
    markGlyphSetsTable = markGlyphSetsDefOffset == 0
        ? null
        : MarkGlyphSetsTable.createFrom(
            reader, tableStart + markGlyphSetsDefOffset);

    if (itemVarStoreOffset != 0) {
      Utils.warnUnimplemented('GDEF ItemVarStore not yet implemented');
    }
  }

  /// Fill glyph metadata (class definitions, mark classes, etc.) into [glyphs].
  void fillGlyphData(List<Glyph> glyphs) {
    _fillGlyphClassDefs(glyphs);
    _fillMarkAttachmentClassDefs(glyphs);
    // Attachment points, ligature carets and mark glyph sets are currently
    // unused in the Dart port. Keep stubs for future work.
  }

  void _fillGlyphClassDefs(List<Glyph> glyphs) {
    final classDef = glyphClassDef;
    if (classDef == null) {
      return;
    }

    switch (classDef.format) {
      case 1:
        final start = classDef.startGlyph;
        final values = classDef.classValueArray;
        for (var i = 0; i < values.length; i++) {
          final glyphIndex = start + i;
          if (glyphIndex < 0 || glyphIndex >= glyphs.length) {
            continue;
          }
          final classValue = values[i];
          if (classValue >= 0 && classValue < GlyphClassKind.values.length) {
            glyphs[glyphIndex].glyphClass = GlyphClassKind.values[classValue];
          }
        }
        break;
      case 2:
        for (final rec in classDef.records) {
          for (var g = rec.startGlyphId;
              g <= rec.endGlyphId && g < glyphs.length;
              g++) {
            final classValue = rec.classNo;
            if (classValue >= 0 &&
                classValue < GlyphClassKind.values.length) {
              glyphs[g].glyphClass = GlyphClassKind.values[classValue];
            }
          }
        }
        break;
      default:
        Utils.warnUnimplemented(
            'GDEF GlyphClassDef format ${classDef.format}');
    }
  }

  void _fillMarkAttachmentClassDefs(List<Glyph> glyphs) {
    final markClassDef = markAttachmentClassDef;
    if (markClassDef == null) {
      return;
    }

    switch (markClassDef.format) {
      case 1:
        final start = markClassDef.startGlyph;
        final values = markClassDef.classValueArray;
        for (var i = 0; i < values.length; i++) {
          final glyphIndex = start + i;
          if (glyphIndex < 0 || glyphIndex >= glyphs.length) {
            continue;
          }
          glyphs[glyphIndex].markClassDef = values[i];
        }
        break;
      case 2:
        for (final rec in markClassDef.records) {
          for (var g = rec.startGlyphId;
              g <= rec.endGlyphId && g < glyphs.length;
              g++) {
            glyphs[g].markClassDef = rec.classNo;
          }
        }
        break;
      default:
        Utils.warnUnimplemented(
            'GDEF MarkAttachmentClassDef format ${markClassDef.format}');
    }
  }
}

/// Attachment List table containing coverage and attachment points.
class AttachmentListTable {
  final CoverageTable coverage;
  final List<List<int>> attachPoints;

  AttachmentListTable(this.coverage, this.attachPoints);

  static AttachmentListTable createFrom(
    ByteOrderSwappingBinaryReader reader,
    int beginAt,
  ) {
    reader.seek(beginAt);
    final coverageOffset = reader.readUInt16();
    final glyphCount = reader.readUInt16();
    final attachOffsets = Utils.readUInt16Array(reader, glyphCount);

    final coverageTable =
        CoverageTable.createFrom(reader, beginAt + coverageOffset);
    final points = <List<int>>[];
    for (final offset in attachOffsets) {
      reader.seek(beginAt + offset);
      final pointCount = reader.readUInt16();
      points.add(Utils.readUInt16Array(reader, pointCount));
    }

    return AttachmentListTable(coverageTable, points);
  }
}

/// Ligature caret list describing caret positions for ligature glyphs.
class LigCaretList {
  final CoverageTable coverage;
  final List<LigGlyph> ligGlyphs;

  LigCaretList(this.coverage, this.ligGlyphs);

  static LigCaretList createFrom(
    ByteOrderSwappingBinaryReader reader,
    int beginAt,
  ) {
    reader.seek(beginAt);
    final coverageOffset = reader.readUInt16();
    final ligGlyphCount = reader.readUInt16();
    final ligGlyphOffsets = Utils.readUInt16Array(reader, ligGlyphCount);

    final ligatures = <LigGlyph>[];
    for (final offset in ligGlyphOffsets) {
      ligatures.add(LigGlyph.createFrom(reader, beginAt + offset));
    }
    final coverageTable =
        CoverageTable.createFrom(reader, beginAt + coverageOffset);
    return LigCaretList(coverageTable, ligatures);
  }
}

/// Ligature glyph caret information.
class LigGlyph {
  final List<int> caretValueOffsets;

  LigGlyph(this.caretValueOffsets);

  static LigGlyph createFrom(
    ByteOrderSwappingBinaryReader reader,
    int beginAt,
  ) {
    reader.seek(beginAt);
    final caretCount = reader.readUInt16();
    final offsets = Utils.readUInt16Array(reader, caretCount);
    return LigGlyph(offsets);
  }
}

/// Mark glyph sets table used for mark filtering in lookups.
class MarkGlyphSetsTable {
  final int format;
  final List<CoverageTable> coverages;

  MarkGlyphSetsTable(this.format, this.coverages);

  static MarkGlyphSetsTable createFrom(
    ByteOrderSwappingBinaryReader reader,
    int beginAt,
  ) {
    reader.seek(beginAt);
    final format = reader.readUInt16();
    final markSetCount = reader.readUInt16();
    final offsets = List<int>.generate(markSetCount, (_) => reader.readUInt32());

    final coverages = <CoverageTable>[];
    for (final offset in offsets) {
      coverages.add(CoverageTable.createFrom(reader, beginAt + offset));
    }

    return MarkGlyphSetsTable(format, coverages);
  }

  bool containsGlyph(int setIndex, int glyphIndex) {
    if (setIndex < 0 || setIndex >= coverages.length) {
      return false;
    }
    return coverages[setIndex].findPosition(glyphIndex) >= 0;
  }
}
