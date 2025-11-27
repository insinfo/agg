import '../../../typography/io/byte_order_swapping_reader.dart';
import '../glyph.dart';
import 'coverage_table.dart';
import 'class_def_table.dart';
import 'gdef.dart';
import 'glyph_shaping_table_entry.dart';
import 'utils.dart';

/// Interface used by GPOS lookups to read/write glyph positions.
abstract class IGlyphPositions {
  int get count;

  int getGlyphIndex(int index);

  int getGlyphAdvanceWidth(int index);

  GlyphClassKind getGlyphClassKind(int index);

  int getGlyphMarkAttachmentType(int index);

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
  MarkGlyphSetsTable? _markGlyphSets;

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
    lookupTable.owner = this;
    lookupTable.setMarkGlyphSets(_markGlyphSets);
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

  void setMarkGlyphSets(MarkGlyphSetsTable? markGlyphSets) {
    _markGlyphSets = markGlyphSets;
    for (final lookup in _lookupList) {
      lookup.setMarkGlyphSets(markGlyphSets);
    }
  }
}

/// Lookup table container for GPOS.
class LookupTable {
  final int lookupType;
  final int lookupFlags;
  final int markFilteringSet;
  final List<LookupSubTable> subTables = [];
  MarkGlyphSetsTable? _markGlyphSets;
  GPOS? owner;
  static const int _flagIgnoreBaseGlyphs = 0x0002;
  static const int _flagIgnoreLigatures = 0x0004;
  static const int _flagIgnoreMarks = 0x0008;
  static const int _flagUseMarkFilteringSet = 0x0010;

  LookupTable(this.lookupType, this.lookupFlags, this.markFilteringSet);

  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    for (final subTable in subTables) {
      subTable.doGlyphPosition(glyphPositions, startAt, len);
    }
  }

  void setMarkGlyphSets(MarkGlyphSetsTable? markGlyphSets) {
    _markGlyphSets = markGlyphSets;
  }

  bool shouldProcessGlyph(IGlyphPositions glyphPositions, int index) {
    final glyphClass = glyphPositions.getGlyphClassKind(index);

    if ((lookupFlags & _flagIgnoreBaseGlyphs) != 0 &&
        glyphClass == GlyphClassKind.base) {
      return false;
    }

    if ((lookupFlags & _flagIgnoreLigatures) != 0 &&
        glyphClass == GlyphClassKind.ligature) {
      return false;
    }

    if ((lookupFlags & _flagIgnoreMarks) != 0 &&
        glyphClass == GlyphClassKind.mark) {
      return false;
    }

    if ((lookupFlags & _flagUseMarkFilteringSet) != 0 &&
        glyphClass == GlyphClassKind.mark) {
      if (_markGlyphSets == null) {
        return false;
      }
      final glyphId = glyphPositions.getGlyphIndex(index);
      if (!_markGlyphSets!.containsGlyph(markFilteringSet, glyphId)) {
        return false;
      }
    }

    final markAttachmentType = (lookupFlags >> 8) & 0xFF;
    if (markAttachmentType != 0 && glyphClass == GlyphClassKind.mark) {
      final glyphMarkClass =
          glyphPositions.getGlyphMarkAttachmentType(index);
      if (glyphMarkClass != markAttachmentType) {
        return false;
      }
    }

    return true;
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
        return UnimplementedLookupSubTable(this, 'GPOS Lookup Type 3');
      case 4:
        return _readLookupType4(reader, subTableStartAt);
      case 5:
        return _readLookupType5(reader, subTableStartAt);
      case 6:
        return _readLookupType6(reader, subTableStartAt);
      case 7:
        return _readLookupType7(reader, subTableStartAt);
      case 8:
        return _readLookupType8(reader, subTableStartAt);
      case 9:
        // Extension Positioning (not yet implemented)
        return UnimplementedLookupSubTable(this, 'GPOS Lookup Type 9');
      default:
        return UnimplementedLookupSubTable(this, 'GPOS Lookup Type $lookupType');
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
          owner: this,
          singleValue: singleValue,
          coverageTable: coverageTable,
        );
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
          owner: this,
          multiValues: values,
          coverageTable: coverageTable,
        );
      default:
        return UnimplementedLookupSubTable(
            this, 'GPOS Lookup Type 1 Format $format');
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
        return LkSubTableType2Fmt1(this, coverageTable, pairSets);
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
          this,
          class1Records,
          classDef1,
          classDef2,
          coverageTable,
        );
      default:
        return UnimplementedLookupSubTable(
            this, 'GPOS Lookup Type 2 Format $format');
    }
  }

  LookupSubTable _readLookupType4(
    ByteOrderSwappingBinaryReader reader,
    int subTableStartAt,
  ) {
    reader.seek(subTableStartAt);
    final format = reader.readUInt16();
    if (format != 1) {
      return UnimplementedLookupSubTable(
          this, 'GPOS Lookup Type 4 Format $format');
    }

    final markCoverageOffset = reader.readUInt16();
    final baseCoverageOffset = reader.readUInt16();
    final markClassCount = reader.readUInt16();
    final markArrayOffset = reader.readUInt16();
    final baseArrayOffset = reader.readUInt16();

    final lookup = LkSubTableType4(this);
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

  LookupSubTable _readLookupType5(
    ByteOrderSwappingBinaryReader reader,
    int subTableStartAt,
  ) {
    reader.seek(subTableStartAt);
    final format = reader.readUInt16();
    switch (format) {
      case 1:
        final markCoverageOffset = reader.readUInt16();
        final ligatureCoverageOffset = reader.readUInt16();
        final markClassCount = reader.readUInt16();
        final markArrayOffset = reader.readUInt16();
        final ligatureArrayOffset = reader.readUInt16();

        final markCoverage =
            CoverageTable.createFrom(reader, subTableStartAt + markCoverageOffset);
        final ligCoverage =
            CoverageTable.createFrom(reader, subTableStartAt + ligatureCoverageOffset);
        final markArray =
            MarkArrayTable.createFrom(reader, subTableStartAt + markArrayOffset);
        final ligatureArray = LigatureArrayTable.createFrom(
          reader,
          subTableStartAt + ligatureArrayOffset,
          markClassCount,
        );
        return LkSubTableType5(
          this,
          markCoverage,
          ligCoverage,
          markArray,
          ligatureArray,
        );
      default:
        return UnimplementedLookupSubTable(
            this, 'GPOS Lookup Type 5 Format $format');
    }
  }

  LookupSubTable _readLookupType6(
    ByteOrderSwappingBinaryReader reader,
    int subTableStartAt,
  ) {
    reader.seek(subTableStartAt);
    final format = reader.readUInt16();
    switch (format) {
      case 1:
        final mark1CoverageOffset = reader.readUInt16();
        final mark2CoverageOffset = reader.readUInt16();
        final markClassCount = reader.readUInt16();
        final mark1ArrayOffset = reader.readUInt16();
        final mark2ArrayOffset = reader.readUInt16();

        final mark1Coverage =
            CoverageTable.createFrom(reader, subTableStartAt + mark1CoverageOffset);
        final mark2Coverage =
            CoverageTable.createFrom(reader, subTableStartAt + mark2CoverageOffset);
        final markArray =
            MarkArrayTable.createFrom(reader, subTableStartAt + mark1ArrayOffset);
        final mark2Array = Mark2ArrayTable.createFrom(
          reader,
          subTableStartAt + mark2ArrayOffset,
          markClassCount,
        );

        return LkSubTableType6(
          this,
          mark1Coverage,
          mark2Coverage,
          markArray,
          mark2Array,
        );
      default:
        return UnimplementedLookupSubTable(
            this, 'GPOS Lookup Type 6 Format $format');
    }
  }

  LookupSubTable _readLookupType7(
    ByteOrderSwappingBinaryReader reader,
    int subTableStartAt,
  ) {
    reader.seek(subTableStartAt);
    final format = reader.readUInt16();
    switch (format) {
      case 1:
        final coverageOffset = reader.readUInt16();
        final ruleSetCount = reader.readUInt16();
        final ruleSetOffsets = Utils.readUInt16Array(reader, ruleSetCount);

        final coverage = CoverageTable.createFrom(reader, subTableStartAt + coverageOffset);
        final ruleSets = List<RuleSet>.generate(ruleSetCount, (i) {
            reader.seek(subTableStartAt + ruleSetOffsets[i]);
            final ruleCount = reader.readUInt16();
            final ruleOffsets = Utils.readUInt16Array(reader, ruleCount);
            final rules = List<Rule>.generate(ruleCount, (j) {
                reader.seek(subTableStartAt + ruleSetOffsets[i] + ruleOffsets[j]);
                final glyphCount = reader.readUInt16();
                final posCount = reader.readUInt16();
                final input = Utils.readUInt16Array(reader, glyphCount - 1);
                final records = List<PosLookupRecord>.generate(posCount, (k) => PosLookupRecord.createFrom(reader));
                return Rule(input, records);
            });
            return RuleSet(rules);
        });
        return LkSubTableType7Fmt1(this, coverage, ruleSets);

      case 2:
        final coverageOffset = reader.readUInt16();
        final classDefOffset = reader.readUInt16();
        final classSetCount = reader.readUInt16();
        final classSetOffsets = Utils.readUInt16Array(reader, classSetCount);

        final coverage = CoverageTable.createFrom(reader, subTableStartAt + coverageOffset);
        final classDef = ClassDefTable.createFrom(reader, subTableStartAt + classDefOffset);

        final classRuleSets = List<ClassRuleSet>.generate(classSetCount, (i) {
            if (classSetOffsets[i] == 0) return ClassRuleSet([]); // Empty set

            reader.seek(subTableStartAt + classSetOffsets[i]);
            final ruleCount = reader.readUInt16();
            final ruleOffsets = Utils.readUInt16Array(reader, ruleCount);
            final rules = List<ClassRule>.generate(ruleCount, (j) {
                reader.seek(subTableStartAt + classSetOffsets[i] + ruleOffsets[j]);
                final glyphCount = reader.readUInt16();
                final posCount = reader.readUInt16();
                final input = Utils.readUInt16Array(reader, glyphCount - 1);
                final records = List<PosLookupRecord>.generate(posCount, (k) => PosLookupRecord.createFrom(reader));
                return ClassRule(input, records);
            });
            return ClassRuleSet(rules);
        });
        return LkSubTableType7Fmt2(this, coverage, classDef, classRuleSets);

      case 3:
        final glyphCount = reader.readUInt16();
        final posCount = reader.readUInt16();
        final coverageOffsets = Utils.readUInt16Array(reader, glyphCount);
        final records = List<PosLookupRecord>.generate(posCount, (k) => PosLookupRecord.createFrom(reader));

        final coverages = List<CoverageTable>.generate(glyphCount, (i) {
            return CoverageTable.createFrom(reader, subTableStartAt + coverageOffsets[i]);
        });
        return LkSubTableType7Fmt3(this, coverages, records);

      default:
        return UnimplementedLookupSubTable(
            this, 'GPOS Lookup Type 7 Format $format');
    }
  }

  LookupSubTable _readLookupType8(
    ByteOrderSwappingBinaryReader reader,
    int subTableStartAt,
  ) {
    reader.seek(subTableStartAt);
    final format = reader.readUInt16();
    switch (format) {
      case 1:
        final coverageOffset = reader.readUInt16();
        final ruleSetCount = reader.readUInt16();
        final ruleSetOffsets = Utils.readUInt16Array(reader, ruleSetCount);

        final coverage = CoverageTable.createFrom(reader, subTableStartAt + coverageOffset);
        final ruleSets = List<ChainRuleSet>.generate(ruleSetCount, (i) {
            reader.seek(subTableStartAt + ruleSetOffsets[i]);
            final ruleCount = reader.readUInt16();
            final ruleOffsets = Utils.readUInt16Array(reader, ruleCount);
            final rules = List<ChainRule>.generate(ruleCount, (j) {
                reader.seek(subTableStartAt + ruleSetOffsets[i] + ruleOffsets[j]);
                final backtrackCount = reader.readUInt16();
                final backtrack = Utils.readUInt16Array(reader, backtrackCount);
                final inputCount = reader.readUInt16();
                final input = Utils.readUInt16Array(reader, inputCount - 1);
                final lookaheadCount = reader.readUInt16();
                final lookahead = Utils.readUInt16Array(reader, lookaheadCount);
                final posCount = reader.readUInt16();
                final records = List<PosLookupRecord>.generate(posCount, (k) => PosLookupRecord.createFrom(reader));
                return ChainRule(backtrack, input, lookahead, records);
            });
            return ChainRuleSet(rules);
        });
        return LkSubTableType8Fmt1(this, coverage, ruleSets);

      case 2:
        final coverageOffset = reader.readUInt16();
        final backtrackClassDefOffset = reader.readUInt16();
        final inputClassDefOffset = reader.readUInt16();
        final lookaheadClassDefOffset = reader.readUInt16();
        final chainClassSetCount = reader.readUInt16();
        final chainClassSetOffsets = Utils.readUInt16Array(reader, chainClassSetCount);

        final coverage = CoverageTable.createFrom(reader, subTableStartAt + coverageOffset);
        final backtrackClassDef = ClassDefTable.createFrom(reader, subTableStartAt + backtrackClassDefOffset);
        final inputClassDef = ClassDefTable.createFrom(reader, subTableStartAt + inputClassDefOffset);
        final lookaheadClassDef = ClassDefTable.createFrom(reader, subTableStartAt + lookaheadClassDefOffset);

        final ruleSets = List<ChainClassRuleSet>.generate(chainClassSetCount, (i) {
            if (chainClassSetOffsets[i] == 0) return ChainClassRuleSet([]);

            reader.seek(subTableStartAt + chainClassSetOffsets[i]);
            final ruleCount = reader.readUInt16();
            final ruleOffsets = Utils.readUInt16Array(reader, ruleCount);
            final rules = List<ChainClassRule>.generate(ruleCount, (j) {
                reader.seek(subTableStartAt + chainClassSetOffsets[i] + ruleOffsets[j]);
                final backtrackCount = reader.readUInt16();
                final backtrack = Utils.readUInt16Array(reader, backtrackCount);
                final inputCount = reader.readUInt16();
                final input = Utils.readUInt16Array(reader, inputCount - 1);
                final lookaheadCount = reader.readUInt16();
                final lookahead = Utils.readUInt16Array(reader, lookaheadCount);
                final posCount = reader.readUInt16();
                final records = List<PosLookupRecord>.generate(posCount, (k) => PosLookupRecord.createFrom(reader));
                return ChainClassRule(backtrack, input, lookahead, records);
            });
            return ChainClassRuleSet(rules);
        });
        return LkSubTableType8Fmt2(this, coverage, backtrackClassDef, inputClassDef, lookaheadClassDef, ruleSets);

      case 3:
        final backtrackCount = reader.readUInt16();
        final backtrackOffsets = Utils.readUInt16Array(reader, backtrackCount);
        final inputCount = reader.readUInt16();
        final inputOffsets = Utils.readUInt16Array(reader, inputCount);
        final lookaheadCount = reader.readUInt16();
        final lookaheadOffsets = Utils.readUInt16Array(reader, lookaheadCount);
        final posCount = reader.readUInt16();
        final records = List<PosLookupRecord>.generate(posCount, (k) => PosLookupRecord.createFrom(reader));

        final backtrackCoverages = List<CoverageTable>.generate(backtrackCount, (i) {
            return CoverageTable.createFrom(reader, subTableStartAt + backtrackOffsets[i]);
        });
        final inputCoverages = List<CoverageTable>.generate(inputCount, (i) {
            return CoverageTable.createFrom(reader, subTableStartAt + inputOffsets[i]);
        });
        final lookaheadCoverages = List<CoverageTable>.generate(lookaheadCount, (i) {
            return CoverageTable.createFrom(reader, subTableStartAt + lookaheadOffsets[i]);
        });

        return LkSubTableType8Fmt3(this, backtrackCoverages, inputCoverages, lookaheadCoverages, records);

      default:
        return UnimplementedLookupSubTable(
            this, 'GPOS Lookup Type 8 Format $format');
    }
  }
}

abstract class LookupSubTable {
  final LookupTable owner;
  LookupSubTable(this.owner);

  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len);
}

class UnimplementedLookupSubTable extends LookupSubTable {
  final String message;

  UnimplementedLookupSubTable(LookupTable owner, this.message) : super(owner) {
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
    required LookupTable owner,
    this.singleValue,
    this.multiValues,
    required this.coverageTable,
  }) : super(owner);

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    final limit = glyphPositions.count;
    for (var i = 0; i < limit; i++) {
      if (!owner.shouldProcessGlyph(glyphPositions, i)) {
        continue;
      }
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

  LkSubTableType2Fmt1(
      LookupTable owner, this.coverageTable, this.pairSetTables)
      : super(owner);

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    final limit = glyphPositions.count - 1;
    for (var i = 0; i < limit; i++) {
      if (!owner.shouldProcessGlyph(glyphPositions, i)) {
        continue;
      }
      final coverageIndex =
          coverageTable.findPosition(glyphPositions.getGlyphIndex(i));
      if (coverageIndex < 0) {
        continue;
      }
      final pairTable = pairSetTables[coverageIndex];
      if (!owner.shouldProcessGlyph(glyphPositions, i + 1)) {
        continue;
      }
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
    LookupTable owner,
    this.class1Records,
    this.class1Def,
    this.class2Def,
    this.coverageTable,
  ) : super(owner);

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    final limit = glyphPositions.count - 1;
    for (var i = 0; i < limit; i++) {
      if (!owner.shouldProcessGlyph(glyphPositions, i)) {
        continue;
      }
      final glyph1Index = glyphPositions.getGlyphIndex(i);
      final record1Index = coverageTable.findPosition(glyph1Index);

      if (record1Index > -1) {
        final class1No = class1Def.getClassValue(glyph1Index);
        if (class1No > -1 && class1No < class1Records.length) {
          if (!owner.shouldProcessGlyph(glyphPositions, i + 1)) {
            continue;
          }
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

  LkSubTableType4(LookupTable owner) : super(owner);

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    final count = glyphPositions.count;
    for (var i = 1; i < count; ++i) {
      if (!owner.shouldProcessGlyph(glyphPositions, i)) {
        continue;
      }
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

class LkSubTableType5 extends LookupSubTable {
  final CoverageTable markCoverageTable;
  final CoverageTable ligatureCoverageTable;
  final MarkArrayTable markArrayTable;
  final LigatureArrayTable ligatureArrayTable;

  LkSubTableType5(
    LookupTable owner,
    this.markCoverageTable,
    this.ligatureCoverageTable,
    this.markArrayTable,
    this.ligatureArrayTable,
  ) : super(owner);

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    final count = glyphPositions.count;
    for (var i = 1; i < count; i++) {
      if (!owner.shouldProcessGlyph(glyphPositions, i)) continue;
      final markIdx = glyphPositions.getGlyphIndex(i);
      final markCoverageIndex = markCoverageTable.findPosition(markIdx);
      if (markCoverageIndex < 0) continue;

      final prevIndex = i - 1;
      if (!owner.shouldProcessGlyph(glyphPositions, prevIndex)) continue;
      final ligIndex = glyphPositions.getGlyphIndex(prevIndex);
      final ligCoverageIndex = ligatureCoverageTable.findPosition(ligIndex);
      if (ligCoverageIndex < 0) continue;

      final markClass = markArrayTable.getMarkClass(markCoverageIndex);
      final markAnchor = markArrayTable.getAnchorPoint(markCoverageIndex);
      final ligAttach = ligatureArrayTable.getLigatureAttach(ligCoverageIndex);
      final component = ligAttach.components.isNotEmpty
          ? ligAttach.components.first
          : null;
      final ligAnchor = component?.getAnchor(markClass);
      if (markAnchor == null || ligAnchor == null) continue;

      final prevAdvance = glyphPositions.getGlyphAdvanceWidth(prevIndex);
      final offsetX = -prevAdvance + ligAnchor.xcoord - markAnchor.xcoord;
      final offsetY = ligAnchor.ycoord - markAnchor.ycoord;
      glyphPositions.appendGlyphOffset(i, offsetX, offsetY);
    }
  }
}

class LkSubTableType6 extends LookupSubTable {
  final CoverageTable mark1CoverageTable;
  final CoverageTable mark2CoverageTable;
  final MarkArrayTable markArrayTable;
  final Mark2ArrayTable mark2ArrayTable;

  LkSubTableType6(
    LookupTable owner,
    this.mark1CoverageTable,
    this.mark2CoverageTable,
    this.markArrayTable,
    this.mark2ArrayTable,
  ) : super(owner);

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    final count = glyphPositions.count;
    for (var i = 1; i < count; i++) {
      if (!owner.shouldProcessGlyph(glyphPositions, i)) continue;
      final mark1Glyph = glyphPositions.getGlyphIndex(i);
      final mark1Cov = mark1CoverageTable.findPosition(mark1Glyph);
      if (mark1Cov < 0) continue;

      final prevIndex = i - 1;
      if (!owner.shouldProcessGlyph(glyphPositions, prevIndex)) continue;
      final mark2Glyph = glyphPositions.getGlyphIndex(prevIndex);
      final mark2Cov = mark2CoverageTable.findPosition(mark2Glyph);
      if (mark2Cov < 0) continue;

      final markClass = markArrayTable.getMarkClass(mark1Cov);
      final markAnchor = markArrayTable.getAnchorPoint(mark1Cov);
      final mark2Record = mark2ArrayTable.getRecord(mark2Cov);
      final mark2Anchor = mark2Record.getAnchor(markClass);
      if (markAnchor == null || mark2Anchor == null) continue;

      final offsetX = mark2Anchor.xcoord - markAnchor.xcoord;
      final offsetY = mark2Anchor.ycoord - markAnchor.ycoord;
      glyphPositions.appendGlyphOffset(i, offsetX, offsetY);
    }
  }
}

class LigatureArrayTable {
  final List<LigatureAttachTable> _records;

  LigatureArrayTable(this._records);

  static LigatureArrayTable createFrom(
    ByteOrderSwappingBinaryReader reader,
    int beginAt,
    int classCount,
  ) {
    reader.seek(beginAt);
    final ligCount = reader.readUInt16();
    final offsets = Utils.readUInt16Array(reader, ligCount);
    final records = List<LigatureAttachTable>.generate(ligCount, (index) {
      return LigatureAttachTable.createFrom(
          reader, beginAt + offsets[index], classCount);
    });
    return LigatureArrayTable(records);
  }

  LigatureAttachTable getLigatureAttach(int index) => _records[index];
}

class LigatureAttachTable {
  final List<LigatureComponentRecord> components;

  LigatureAttachTable(this.components);

  static LigatureAttachTable createFrom(
    ByteOrderSwappingBinaryReader reader,
    int beginAt,
    int classCount,
  ) {
    reader.seek(beginAt);
    final compCount = reader.readUInt16();
    final offsets = Utils.readUInt16Array(reader, compCount);
    final comps = List<LigatureComponentRecord>.generate(compCount, (i) {
      return LigatureComponentRecord.createFrom(
          reader, beginAt + offsets[i], classCount);
    });
    return LigatureAttachTable(comps);
  }
}

class LigatureComponentRecord {
  final List<AnchorPoint?> anchors;

  LigatureComponentRecord(this.anchors);

  static LigatureComponentRecord createFrom(
    ByteOrderSwappingBinaryReader reader,
    int beginAt,
    int classCount,
  ) {
    reader.seek(beginAt);
    final anchorOffsets = Utils.readUInt16Array(reader, classCount);
    final anchors = List<AnchorPoint?>.generate(classCount, (classIdx) {
      final off = anchorOffsets[classIdx];
      if (off == 0) return null;
      return AnchorPoint.createFrom(reader, beginAt + off);
    });
    return LigatureComponentRecord(anchors);
  }

  AnchorPoint? getAnchor(int classId) {
    if (classId < 0 || classId >= anchors.length) return null;
    return anchors[classId];
  }
}

class Mark2ArrayTable {
  final List<Mark2Record> records;

  Mark2ArrayTable(this.records);

  static Mark2ArrayTable createFrom(
    ByteOrderSwappingBinaryReader reader,
    int beginAt,
    int classCount,
  ) {
    reader.seek(beginAt);
    final mark2Count = reader.readUInt16();
    final offsets = Utils.readUInt16Array(reader, mark2Count * classCount);
    final recs = List<Mark2Record>.generate(mark2Count, (markIndex) {
      final anchors = List<AnchorPoint?>.generate(classCount, (classIdx) {
        final offset = offsets[markIndex * classCount + classIdx];
        if (offset == 0) return null;
        return AnchorPoint.createFrom(reader, beginAt + offset);
      });
      return Mark2Record(anchors);
    });
    return Mark2ArrayTable(recs);
  }

  Mark2Record getRecord(int index) => records[index];
}

class Mark2Record {
  final List<AnchorPoint?> anchors;

  Mark2Record(this.anchors);

  AnchorPoint? getAnchor(int classId) {
    if (classId < 0 || classId >= anchors.length) return null;
    return anchors[classId];
  }
}

class PosLookupRecord {
  final int sequenceIndex;
  final int lookupListIndex;

  PosLookupRecord(this.sequenceIndex, this.lookupListIndex);

  static PosLookupRecord createFrom(ByteOrderSwappingBinaryReader reader) {
    return PosLookupRecord(reader.readUInt16(), reader.readUInt16());
  }
}

// --- Type 7: Contextual Positioning ---

class LkSubTableType7Fmt1 extends LookupSubTable {
  final CoverageTable coverage;
  final List<RuleSet> ruleSets;

  LkSubTableType7Fmt1(LookupTable owner, this.coverage, this.ruleSets)
      : super(owner);

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    // TODO: Implement Contextual Positioning Format 1
  }
}

class RuleSet {
  final List<Rule> rules;
  RuleSet(this.rules);
}

class Rule {
  final List<int> input; // Glyphs
  final List<PosLookupRecord> lookupRecords;
  Rule(this.input, this.lookupRecords);
}

class LkSubTableType7Fmt2 extends LookupSubTable {
  final CoverageTable coverage;
  final ClassDefTable classDef;
  final List<ClassRuleSet> classRuleSets;

  LkSubTableType7Fmt2(
      LookupTable owner, this.coverage, this.classDef, this.classRuleSets)
      : super(owner);

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    // TODO: Implement Contextual Positioning Format 2
  }
}

class ClassRuleSet {
  final List<ClassRule> rules;
  ClassRuleSet(this.rules);
}

class ClassRule {
  final List<int> input; // Classes
  final List<PosLookupRecord> lookupRecords;
  ClassRule(this.input, this.lookupRecords);
}

class LkSubTableType7Fmt3 extends LookupSubTable {
  final List<CoverageTable> coverages;
  final List<PosLookupRecord> lookupRecords;

  LkSubTableType7Fmt3(LookupTable owner, this.coverages, this.lookupRecords)
      : super(owner);

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    // TODO: Implement Contextual Positioning Format 3
  }
}

// --- Type 8: Chaining Contextual Positioning ---

class LkSubTableType8Fmt1 extends LookupSubTable {
  final CoverageTable coverage;
  final List<ChainRuleSet> ruleSets;

  LkSubTableType8Fmt1(LookupTable owner, this.coverage, this.ruleSets)
      : super(owner);

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    // TODO: Implement Chaining Contextual Positioning Format 1
  }
}

class ChainRuleSet {
  final List<ChainRule> rules;
  ChainRuleSet(this.rules);
}

class ChainRule {
  final List<int> backtrack;
  final List<int> input;
  final List<int> lookahead;
  final List<PosLookupRecord> lookupRecords;
  ChainRule(this.backtrack, this.input, this.lookahead, this.lookupRecords);
}

class LkSubTableType8Fmt2 extends LookupSubTable {
  final CoverageTable coverage;
  final ClassDefTable backtrackClassDef;
  final ClassDefTable inputClassDef;
  final ClassDefTable lookaheadClassDef;
  final List<ChainClassRuleSet> ruleSets;

  LkSubTableType8Fmt2(
    LookupTable owner,
    this.coverage,
    this.backtrackClassDef,
    this.inputClassDef,
    this.lookaheadClassDef,
    this.ruleSets,
  ) : super(owner);

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    // TODO: Implement Chaining Contextual Positioning Format 2
  }
}

class ChainClassRuleSet {
  final List<ChainClassRule> rules;
  ChainClassRuleSet(this.rules);
}

class ChainClassRule {
  final List<int> backtrack;
  final List<int> input;
  final List<int> lookahead;
  final List<PosLookupRecord> lookupRecords;
  ChainClassRule(
      this.backtrack, this.input, this.lookahead, this.lookupRecords);
}

class LkSubTableType8Fmt3 extends LookupSubTable {
  final List<CoverageTable> backtrackCoverages;
  final List<CoverageTable> inputCoverages;
  final List<CoverageTable> lookaheadCoverages;
  final List<PosLookupRecord> lookupRecords;

  LkSubTableType8Fmt3(
    LookupTable owner,
    this.backtrackCoverages,
    this.inputCoverages,
    this.lookaheadCoverages,
    this.lookupRecords,
  ) : super(owner);

  @override
  void doGlyphPosition(IGlyphPositions glyphPositions, int startAt, int len) {
    // TODO: Implement Chaining Contextual Positioning Format 3
  }
}
