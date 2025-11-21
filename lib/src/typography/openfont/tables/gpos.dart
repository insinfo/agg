import '../../../typography/io/byte_order_swapping_reader.dart';
import 'coverage_table.dart';
import 'class_def_table.dart';
import 'glyph_shaping_table_entry.dart';
import 'utils.dart';

/// Interface used by GPOS lookups to read/write glyph positions.
abstract class IGlyphPositions {
  int get count;

  int getGlyphIndex(int index);

  int getGlyphAdvanceWidth(int index);

  void appendGlyphAdvance(int index, int appendAdvX, int appendAdvY);

  void appendGlyphOffset(int index, int appendOffsetX, int appendOffsetY);
}

/// Glyph Positioning Table (GPOS) parser.
class GPOS extends GlyphShapingTableEntry {
  static const String _N = 'GPOS';
  @override
  String get name => _N;

  final List<LookupTable> _lookupList = [];
  List<LookupTable> get lookupList => _lookupList;

  @override
  void readLookupTable(
    ByteOrderSwappingBinaryReader reader,
    int lookupTablePos,
    int lookupType,
    int lookupFlags,
    List<int> subTableOffsets,
    int markFilteringSet,
  ) {
    final lookupTable = LookupTable(lookupType, lookupFlags, markFilteringSet);
    for (final subTableOffset in subTableOffsets) {
      final subTable =
          lookupTable.readSubTable(reader, lookupTablePos + subTableOffset);
      lookupTable.subTables.add(subTable);
    }
    _lookupList.add(lookupTable);
  }

  @override
  void readFeatureVariations(
    ByteOrderSwappingBinaryReader reader,
    int featureVariationsBeginAt,
  ) {
    Utils.warnUnimplemented('GPOS feature variations');
  }
}

/// Lookup table container for GPOS.
class LookupTable {
  final int lookupType;
  final int lookupFlags;
  final int markFilteringSet;
  final List<LookupSubTable> subTables = [];

  LookupTable(this.lookupType, this.lookupFlags, this.markFilteringSet);

  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    for (final subTable in subTables) {
      subTable.doGlyphPosition(glyphPositions, startAt, len);
    }
  }

  LookupSubTable readSubTable(
    ByteOrderSwappingBinaryReader reader,
    int subTableStartAt,
  ) {
    switch (lookupType) {
      case 1:
        return _readLookupType1(reader, subTableStartAt);
      case 2:
        return _readLookupType2(reader, subTableStartAt);
      case 3:
        // Contextual Positioning (not yet implemented)
        return UnimplementedLookupSubTable('GPOS Lookup Type 3');
      case 4:
        return _readLookupType4(reader, subTableStartAt);
      case 5:
        // Mark-to-Ligature (not yet implemented)
        return UnimplementedLookupSubTable('GPOS Lookup Type 5');
      case 6:
        // Mark-to-Mark (not yet implemented)
        return UnimplementedLookupSubTable('GPOS Lookup Type 6');
      case 7:
        // Contextual Positioning (extended) (not yet implemented)
        return UnimplementedLookupSubTable('GPOS Lookup Type 7');
      case 8:
        // Chaining Contextual Positioning (not yet implemented)
        return UnimplementedLookupSubTable('GPOS Lookup Type 8');
      case 9:
        // Extension Positioning (not yet implemented)
        return UnimplementedLookupSubTable('GPOS Lookup Type 9');
      default:
        return UnimplementedLookupSubTable('GPOS Lookup Type $lookupType');
    }
  }

  LookupSubTable _readLookupType1(
    ByteOrderSwappingBinaryReader reader,
    int subTableStartAt,
  ) {
    reader.seek(subTableStartAt);
    final format = reader.readUInt16();
    switch (format) {
      case 1:
        final coverageOffset = reader.readUInt16();
        final valueFormat = reader.readUInt16();
        final singleValue = ValueRecord.createFrom(reader, valueFormat);
        final coverageTable =
            CoverageTable.createFrom(reader, subTableStartAt + coverageOffset);
        return LkSubTableType1(
            singleValue: singleValue, coverageTable: coverageTable);
      case 2:
        final coverageOffset = reader.readUInt16();
        final valueFormat = reader.readUInt16();
        final valueCount = reader.readUInt16();
        final values = List<ValueRecord?>.generate(valueCount, (i) {
          return ValueRecord.createFrom(reader, valueFormat);
        });
        final coverageTable =
            CoverageTable.createFrom(reader, subTableStartAt + coverageOffset);
        return LkSubTableType1(
            multiValues: values, coverageTable: coverageTable);
      default:
        return UnimplementedLookupSubTable('GPOS Lookup Type 1 Format $format');
    }
  }

  LookupSubTable _readLookupType2(
    ByteOrderSwappingBinaryReader reader,
    int subTableStartAt,
  ) {
    reader.seek(subTableStartAt);
    final format = reader.readUInt16();
    switch (format) {
      case 1:
        final coverageOffset = reader.readUInt16();
        final valueFormat1 = reader.readUInt16();
        final valueFormat2 = reader.readUInt16();
        final pairSetCount = reader.readUInt16();
        final pairSetOffsets = Utils.readUInt16Array(reader, pairSetCount);
        final pairSets = List<PairSetTable>.generate(pairSetCount, (i) {
          return PairSetTable.createFrom(
            reader,
            subTableStartAt + pairSetOffsets[i],
            valueFormat1,
            valueFormat2,
          );
        });
        final coverageTable =
            CoverageTable.createFrom(reader, subTableStartAt + coverageOffset);
        return LkSubTableType2Fmt1(coverageTable, pairSets);
      case 2:
        final coverageOffset = reader.readUInt16();
        final value1Format = reader.readUInt16();
        final value2Format = reader.readUInt16();
        final classDef1Offset = reader.readUInt16();
        final classDef2Offset = reader.readUInt16();
        final class1Count = reader.readUInt16();
        final class2Count = reader.readUInt16();

        final class1Records = List<Lk2Class1Record>.generate(class1Count, (c1) {
          final class2Records =
              List<Lk2Class2Record>.generate(class2Count, (c2) {
            return Lk2Class2Record(
              ValueRecord.createFrom(reader, value1Format),
              ValueRecord.createFrom(reader, value2Format),
            );
          });
          return Lk2Class1Record(class2Records);
        });

        final coverageTable =
            CoverageTable.createFrom(reader, subTableStartAt + coverageOffset);
        final classDef1 =
            ClassDefTable.createFrom(reader, subTableStartAt + classDef1Offset);
        final classDef2 =
            ClassDefTable.createFrom(reader, subTableStartAt + classDef2Offset);

        return LkSubTableType2Fmt2(
          class1Records,
          classDef1,
          classDef2,
          coverageTable,
        );
      default:
        return UnimplementedLookupSubTable('GPOS Lookup Type 2 Format $format');
    }
  }

  LookupSubTable _readLookupType4(
    ByteOrderSwappingBinaryReader reader,
    int subTableStartAt,
  ) {
    reader.seek(subTableStartAt);
    final format = reader.readUInt16();
    if (format != 1) {
      return UnimplementedLookupSubTable('GPOS Lookup Type 4 Format $format');
    }

    final markCoverageOffset = reader.readUInt16();
    final baseCoverageOffset = reader.readUInt16();
    final markClassCount = reader.readUInt16();
    final markArrayOffset = reader.readUInt16();
    final baseArrayOffset = reader.readUInt16();

    final lookup = LkSubTableType4();
    lookup.markCoverageTable =
        CoverageTable.createFrom(reader, subTableStartAt + markCoverageOffset);
    lookup.baseCoverageTable =
        CoverageTable.createFrom(reader, subTableStartAt + baseCoverageOffset);
    lookup.markArrayTable =
        MarkArrayTable.createFrom(reader, subTableStartAt + markArrayOffset);
    lookup.baseArrayTable = BaseArrayTable.createFrom(
        reader, subTableStartAt + baseArrayOffset, markClassCount);
    return lookup;
  }
}

abstract class LookupSubTable {
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len);
}

class UnimplementedLookupSubTable extends LookupSubTable {
  final String message;

  UnimplementedLookupSubTable(this.message) {
    Utils.warnUnimplemented(message);
  }

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    // No-op when feature is not implemented.
  }
}

class LkSubTableType1 extends LookupSubTable {
  final ValueRecord? singleValue;
  final List<ValueRecord?>? multiValues;
  final CoverageTable coverageTable;

  LkSubTableType1({
    this.singleValue,
    this.multiValues,
    required this.coverageTable,
  });

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    final limit = glyphPositions.count;
    for (var i = 0; i < limit; i++) {
      final glyphIndex = glyphPositions.getGlyphIndex(i);
      final coverageIndex = coverageTable.findPosition(glyphIndex);
      if (coverageIndex < 0) {
        continue;
      }

      ValueRecord? record;
      if (singleValue != null) {
        record = singleValue;
      } else if (multiValues != null && coverageIndex < multiValues!.length) {
        record = multiValues![coverageIndex];
      }

      if (record != null) {
        if (record.xPlacement != 0 || record.yPlacement != 0) {
          glyphPositions.appendGlyphOffset(
              i, record.xPlacement, record.yPlacement);
        }
        if (record.xAdvance != 0 || record.yAdvance != 0) {
          glyphPositions.appendGlyphAdvance(
              i, record.xAdvance, record.yAdvance);
        }
      }
    }
  }
}

class LkSubTableType2Fmt1 extends LookupSubTable {
  final CoverageTable coverageTable;
  final List<PairSetTable> pairSetTables;

  LkSubTableType2Fmt1(this.coverageTable, this.pairSetTables);

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    final limit = glyphPositions.count - 1;
    for (var i = 0; i < limit; i++) {
      final coverageIndex =
          coverageTable.findPosition(glyphPositions.getGlyphIndex(i));
      if (coverageIndex < 0) {
        continue;
      }
      final pairTable = pairSetTables[coverageIndex];
      final nextGlyphIndex = glyphPositions.getGlyphIndex(i + 1);
      final pair = pairTable.findPairSet(nextGlyphIndex);
      if (pair == null) {
        continue;
      }
      final v1 = pair.value1;
      final v2 = pair.value2;
      // Apply adjustments for first glyph
      if (v1 != null) {
        if (v1.xPlacement != 0 || v1.yPlacement != 0) {
          glyphPositions.appendGlyphOffset(i, v1.xPlacement, v1.yPlacement);
        }
        if (v1.xAdvance != 0 || v1.yAdvance != 0) {
          glyphPositions.appendGlyphAdvance(i, v1.xAdvance, v1.yAdvance);
        }
      }
      // Apply adjustments for second glyph
      if (v2 != null) {
        if (v2.xPlacement != 0 || v2.yPlacement != 0) {
          glyphPositions.appendGlyphOffset(i + 1, v2.xPlacement, v2.yPlacement);
        }
        if (v2.xAdvance != 0 || v2.yAdvance != 0) {
          glyphPositions.appendGlyphAdvance(i + 1, v2.xAdvance, v2.yAdvance);
        }
      }
    }
  }
}

class LkSubTableType2Fmt2 extends LookupSubTable {
  final List<Lk2Class1Record> class1Records;
  final ClassDefTable class1Def;
  final ClassDefTable class2Def;
  final CoverageTable coverageTable;

  LkSubTableType2Fmt2(
    this.class1Records,
    this.class1Def,
    this.class2Def,
    this.coverageTable,
  );

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    final limit = glyphPositions.count - 1;
    for (var i = 0; i < limit; i++) {
      final glyph1Index = glyphPositions.getGlyphIndex(i);
      final record1Index = coverageTable.findPosition(glyph1Index);

      if (record1Index > -1) {
        final class1No = class1Def.getClassValue(glyph1Index);
        if (class1No > -1 && class1No < class1Records.length) {
          final glyph2Index = glyphPositions.getGlyphIndex(i + 1);
          final class2No = class2Def.getClassValue(glyph2Index);

          if (class2No > -1) {
            final class1Rec = class1Records[class1No];
            if (class2No < class1Rec.class2Records.length) {
              final pair = class1Rec.class2Records[class2No];
              final v1 = pair.value1;
              final v2 = pair.value2;

              if (v1 != null) {
                if (v1.xPlacement != 0 || v1.yPlacement != 0) {
                  glyphPositions.appendGlyphOffset(
                      i, v1.xPlacement, v1.yPlacement);
                }
                if (v1.xAdvance != 0 || v1.yAdvance != 0) {
                  glyphPositions.appendGlyphAdvance(
                      i, v1.xAdvance, v1.yAdvance);
                }
              }

              if (v2 != null) {
                if (v2.xPlacement != 0 || v2.yPlacement != 0) {
                  glyphPositions.appendGlyphOffset(
                      i + 1, v2.xPlacement, v2.yPlacement);
                }
                if (v2.xAdvance != 0 || v2.yAdvance != 0) {
                  glyphPositions.appendGlyphAdvance(
                      i + 1, v2.xAdvance, v2.yAdvance);
                }
              }
            }
          }
        }
      }
    }
  }
}

class Lk2Class1Record {
  final List<Lk2Class2Record> class2Records;
  Lk2Class1Record(this.class2Records);
}

class Lk2Class2Record {
  final ValueRecord? value1;
  final ValueRecord? value2;
  Lk2Class2Record(this.value1, this.value2);
}

class PairSetTable {
  final List<PairSet> _pairSets;

  PairSetTable(this._pairSets);

  static PairSetTable createFrom(
    ByteOrderSwappingBinaryReader reader,
    int beginAt,
    int valueFormat1,
    int valueFormat2,
  ) {
    reader.seek(beginAt);
    final pairValueCount = reader.readUInt16();
    final pairs = List<PairSet>.generate(pairValueCount, (index) {
      final secondGlyph = reader.readUInt16();
      final v1 = ValueRecord.createFrom(reader, valueFormat1);
      final v2 = ValueRecord.createFrom(reader, valueFormat2);
      return PairSet(secondGlyph, v1, v2);
    });
    return PairSetTable(pairs);
  }

  PairSet? findPairSet(int secondGlyphIndex) {
    for (final pair in _pairSets) {
      if (pair.secondGlyph == secondGlyphIndex) {
        return pair;
      }
    }
    return null;
  }
}

class PairSet {
  final int secondGlyph;
  final ValueRecord? value1;
  final ValueRecord? value2;

  PairSet(this.secondGlyph, this.value1, this.value2);
}

class ValueRecord {
  int valueFormat = 0;
  int xPlacement = 0;
  int yPlacement = 0;
  int xAdvance = 0;
  int yAdvance = 0;
  int xPlaDevice = 0;
  int yPlaDevice = 0;
  int xAdvDevice = 0;
  int yAdvDevice = 0;

  static const int fmtXPlacement = 1;
  static const int fmtYPlacement = 1 << 1;
  static const int fmtXAdvance = 1 << 2;
  static const int fmtYAdvance = 1 << 3;
  static const int fmtXPlaDevice = 1 << 4;
  static const int fmtYPlaDevice = 1 << 5;
  static const int fmtXAdvDevice = 1 << 6;
  static const int fmtYAdvDevice = 1 << 7;

  static ValueRecord? createFrom(
    ByteOrderSwappingBinaryReader reader,
    int valueFormat,
  ) {
    if (valueFormat == 0) {
      return null;
    }
    final record = ValueRecord();
    record.valueFormat = valueFormat;
    if ((valueFormat & fmtXPlacement) == fmtXPlacement) {
      record.xPlacement = reader.readInt16();
    }
    if ((valueFormat & fmtYPlacement) == fmtYPlacement) {
      record.yPlacement = reader.readInt16();
    }
    if ((valueFormat & fmtXAdvance) == fmtXAdvance) {
      record.xAdvance = reader.readInt16();
    }
    if ((valueFormat & fmtYAdvance) == fmtYAdvance) {
      record.yAdvance = reader.readInt16();
    }
    if ((valueFormat & fmtXPlaDevice) == fmtXPlaDevice) {
      record.xPlaDevice = reader.readUInt16();
    }
    if ((valueFormat & fmtYPlaDevice) == fmtYPlaDevice) {
      record.yPlaDevice = reader.readUInt16();
    }
    if ((valueFormat & fmtXAdvDevice) == fmtXAdvDevice) {
      record.xAdvDevice = reader.readUInt16();
    }
    if ((valueFormat & fmtYAdvDevice) == fmtYAdvDevice) {
      record.yAdvDevice = reader.readUInt16();
    }
    return record;
  }
}

class LkSubTableType4 extends LookupSubTable {
  late CoverageTable markCoverageTable;
  late CoverageTable baseCoverageTable;
  late MarkArrayTable markArrayTable;
  late BaseArrayTable baseArrayTable;

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    final count = glyphPositions.count;
    for (var i = 1; i < count; ++i) {
      final markCoverageIndex =
          markCoverageTable.findPosition(glyphPositions.getGlyphIndex(i));
      if (markCoverageIndex < 0) {
        continue;
      }
      final prevIndex = i - 1;
      final baseCoverageIndex = baseCoverageTable
          .findPosition(glyphPositions.getGlyphIndex(prevIndex));
      if (baseCoverageIndex < 0) {
        continue;
      }

      final markClass = markArrayTable.getMarkClass(markCoverageIndex);
      final markAnchor = markArrayTable.getAnchorPoint(markCoverageIndex);
      final baseRecord = baseArrayTable.getBaseRecord(baseCoverageIndex);
      final baseAnchor = baseRecord.getAnchor(markClass);
      if (markAnchor == null || baseAnchor == null) {
        continue;
      }

      final prevAdvance = glyphPositions.getGlyphAdvanceWidth(prevIndex);
      final offsetX = (-prevAdvance + baseAnchor.xcoord - markAnchor.xcoord);
      final offsetY = baseAnchor.ycoord - markAnchor.ycoord;
      glyphPositions.appendGlyphOffset(i, offsetX, offsetY);
    }
  }
}

class AnchorPoint {
  final int format;
  final int xcoord;
  final int ycoord;
  final int refGlyphContourPoint;
  final int xdeviceTableOffset;
  final int ydeviceTableOffset;

  AnchorPoint({
    required this.format,
    required this.xcoord,
    required this.ycoord,
    this.refGlyphContourPoint = 0,
    this.xdeviceTableOffset = 0,
    this.ydeviceTableOffset = 0,
  });

  static AnchorPoint createFrom(
      ByteOrderSwappingBinaryReader reader, int beginAt) {
    reader.seek(beginAt);
    final format = reader.readUInt16();
    switch (format) {
      case 1:
        return AnchorPoint(
          format: format,
          xcoord: reader.readInt16(),
          ycoord: reader.readInt16(),
        );
      case 2:
        return AnchorPoint(
          format: format,
          xcoord: reader.readInt16(),
          ycoord: reader.readInt16(),
          refGlyphContourPoint: reader.readUInt16(),
        );
      case 3:
        return AnchorPoint(
          format: format,
          xcoord: reader.readInt16(),
          ycoord: reader.readInt16(),
          xdeviceTableOffset: reader.readUInt16(),
          ydeviceTableOffset: reader.readUInt16(),
        );
      default:
        throw UnsupportedError('Anchor format $format not supported');
    }
  }
}

class MarkArrayTable {
  final List<MarkRecord> _records;

  MarkArrayTable(this._records);

  static MarkArrayTable createFrom(
      ByteOrderSwappingBinaryReader reader, int beginAt) {
    reader.seek(beginAt);
    final markCount = reader.readUInt16();
    final markClasses = List<int>.filled(markCount, 0);
    final anchorOffsets = List<int>.filled(markCount, 0);

    for (var i = 0; i < markCount; i++) {
      markClasses[i] = reader.readUInt16();
      anchorOffsets[i] = reader.readUInt16();
    }

    final records = List<MarkRecord>.generate(markCount, (index) {
      final anchorOffset = anchorOffsets[index];
      AnchorPoint? anchor;
      if (anchorOffset > 0) {
        anchor = AnchorPoint.createFrom(reader, beginAt + anchorOffset);
      }
      return MarkRecord(markClasses[index], anchor);
    });

    return MarkArrayTable(records);
  }

  int getMarkClass(int index) => _records[index].markClass;

  AnchorPoint? getAnchorPoint(int index) => _records[index].anchorPoint;
}

class MarkRecord {
  final int markClass;
  final AnchorPoint? anchorPoint;

  MarkRecord(this.markClass, this.anchorPoint);
}

class BaseArrayTable {
  final List<BaseRecord> _records;

  BaseArrayTable(this._records);

  static BaseArrayTable createFrom(
    ByteOrderSwappingBinaryReader reader,
    int beginAt,
    int classCount,
  ) {
    reader.seek(beginAt);
    final baseCount = reader.readUInt16();
    final offsets = Utils.readUInt16Array(reader, baseCount * classCount);
    final records = List<BaseRecord>.generate(baseCount, (index) {
      final anchors = List<AnchorPoint?>.generate(classCount, (classIndex) {
        final offset = offsets[index * classCount + classIndex];
        if (offset == 0) {
          return null;
        }
        return AnchorPoint.createFrom(reader, beginAt + offset);
      });
      return BaseRecord(anchors);
    });
    return BaseArrayTable(records);
  }

  BaseRecord getBaseRecord(int index) => _records[index];
}

class BaseRecord {
  final List<AnchorPoint?> anchors;

  BaseRecord(this.anchors);

  AnchorPoint? getAnchor(int classId) {
    if (classId < 0 || classId >= anchors.length) {
      return null;
    }
    return anchors[classId];
  }
}
