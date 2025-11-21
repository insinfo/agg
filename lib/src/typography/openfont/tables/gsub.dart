import '../../../typography/io/byte_order_swapping_reader.dart';
import '../glyph.dart';
import 'coverage_table.dart';
import 'gdef.dart';
import 'glyph_shaping_table_entry.dart';
import 'i_glyph_index_list.dart';
import 'utils.dart';

typedef GlyphClassResolver = GlyphClassKind Function(int glyphIndex);
typedef GlyphMarkClassResolver = int Function(int glyphIndex);

class GSUB extends GlyphShapingTableEntry {
  static const String _N = "GSUB";
  @override
  String get name => _N;

  List<LookupTable> _lookupList = [];
  List<LookupTable> get lookupList => _lookupList;
  MarkGlyphSetsTable? _markGlyphSets;
  GlyphClassResolver? _glyphClassResolver;
  GlyphMarkClassResolver? _markAttachmentClassResolver;

  @override
  void readLookupTable(
      ByteOrderSwappingBinaryReader reader,
      int lookupTablePos,
      int lookupType,
      int lookupFlags,
      List<int> subTableOffsets,
      int markFilteringSet) {
    final lookupTable = LookupTable(lookupType, lookupFlags, markFilteringSet)
      ..markGlyphSets = _markGlyphSets
      ..glyphClassResolver = _glyphClassResolver
      ..markClassResolver = _markAttachmentClassResolver;
    for (int subTableOffset in subTableOffsets) {
      LookupSubTable subTable =
          lookupTable.readSubTable(reader, lookupTablePos + subTableOffset);
      subTable.ownerGSub = this;
      lookupTable.subTables.add(subTable);
    }

    _lookupList.add(lookupTable);
  }

  @override
  void readFeatureVariations(
      ByteOrderSwappingBinaryReader reader, int featureVariationsBeginAt) {
    Utils.warnUnimplemented("GSUB feature variations");
  }

  void setMarkGlyphSets(MarkGlyphSetsTable? markGlyphSets) {
    _markGlyphSets = markGlyphSets;
    for (final lookup in _lookupList) {
      lookup.markGlyphSets = markGlyphSets;
    }
  }

  void setGlyphClassResolver(GlyphClassResolver? resolver) {
    _glyphClassResolver = resolver;
    for (final lookup in _lookupList) {
      lookup.glyphClassResolver = resolver;
    }
  }

  void setMarkAttachmentClassResolver(GlyphMarkClassResolver? resolver) {
    _markAttachmentClassResolver = resolver;
    for (final lookup in _lookupList) {
      lookup.markClassResolver = resolver;
    }
  }
}

abstract class LookupSubTable {
  GSUB? ownerGSub;

  bool doSubstitutionAt(IGlyphIndexList glyphIndices, int pos, int len);

  void collectAssociatedSubstitutionGlyphs(List<int> outputAssocGlyphs);
}

class UnImplementedLookupSubTable extends LookupSubTable {
  final String _message;
  UnImplementedLookupSubTable(this._message) {
    Utils.warnUnimplemented(_message);
  }

  @override
  String toString() => _message;

  @override
  bool doSubstitutionAt(IGlyphIndexList glyphIndices, int pos, int len) {
    return false;
  }

  @override
  void collectAssociatedSubstitutionGlyphs(List<int> outputAssocGlyphs) {
    Utils.warnUnimplemented("collect-assoc-sub-glyph: $this");
  }
}

class LookupTable {
  int lookupType;
  final int lookupFlags;
  final int markFilteringSet;

  final List<LookupSubTable> _subTables = [];
  List<LookupSubTable> get subTables => _subTables;

  static const int _flagIgnoreBaseGlyphs = 0x0002;
  static const int _flagIgnoreLigatures = 0x0004;
  static const int _flagIgnoreMarks = 0x0008;
  static const int _flagUseMarkFilteringSet = 0x0010;

  MarkGlyphSetsTable? markGlyphSets;
  GlyphClassResolver? glyphClassResolver;
  GlyphMarkClassResolver? markClassResolver;

  LookupTable(this.lookupType, this.lookupFlags, this.markFilteringSet);

  bool doSubstitutionAt(IGlyphIndexList inputGlyphs, int pos, int len) {
    if (!_shouldProcessGlyph(inputGlyphs[pos])) {
      return false;
    }
    for (LookupSubTable subTable in _subTables) {
      // We return after the first substitution, as explained in the spec:
      // "A lookup is finished for a glyph after the client locates the target
      // glyph or glyph context and performs a substitution, if specified."
      if (subTable.doSubstitutionAt(inputGlyphs, pos, len)) {
        return true;
      }
    }
    return false;
  }

  void collectAssociatedSubstitutionGlyph(List<int> outputAssocGlyphs) {
    for (LookupSubTable subTable in _subTables) {
      subTable.collectAssociatedSubstitutionGlyphs(outputAssocGlyphs);
    }
  }

  @override
  String toString() => lookupType.toString();

  LookupSubTable readSubTable(
      ByteOrderSwappingBinaryReader reader, int subTableStartAt) {
    switch (lookupType) {
      case 1:
        return _readLookupType1(reader, subTableStartAt);
      case 2:
        return _readLookupType2(reader, subTableStartAt);
      case 3:
        return _readLookupType3(reader, subTableStartAt);
      case 4:
        return _readLookupType4(reader, subTableStartAt);
      // case 5: return _readLookupType5(reader, subTableStartAt);
      // case 6: return _readLookupType6(reader, subTableStartAt);
      // case 7: return _readLookupType7(reader, subTableStartAt);
      // case 8: return _readLookupType8(reader, subTableStartAt);
    }
    return UnImplementedLookupSubTable("GSUB Lookup Type $lookupType");
  }

  bool _shouldProcessGlyph(int glyphIndex) {
    final resolver = glyphClassResolver;
    GlyphClassKind? glyphClass;
    if (resolver != null) {
      glyphClass = resolver(glyphIndex);
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
    }

    if (glyphClass == GlyphClassKind.mark &&
        (lookupFlags & _flagUseMarkFilteringSet) != 0) {
      final markSets = markGlyphSets;
      if (markSets == null ||
          !markSets.containsGlyph(markFilteringSet, glyphIndex)) {
        return false;
      }
    }

    if (glyphClass == GlyphClassKind.mark) {
      final markAttachmentType = (lookupFlags >> 8) & 0xFF;
      if (markAttachmentType != 0) {
        final resolverMark = markClassResolver;
        final glyphMarkClass =
            resolverMark != null ? resolverMark(glyphIndex) : 0;
        if (glyphMarkClass != markAttachmentType) {
          return false;
        }
      }
    }

    return true;
  }

  // LookupType 1: Single Substitution Subtable
  LookupSubTable _readLookupType1(
      ByteOrderSwappingBinaryReader reader, int subTableStartAt) {
    reader.seek(subTableStartAt);
    int format = reader.readUInt16();
    int coverage = reader.readUInt16();

    switch (format) {
      case 1:
        {
          int deltaGlyph = reader.readUInt16();
          CoverageTable coverageTable =
              CoverageTable.createFrom(reader, subTableStartAt + coverage);
          return LkSubTableT1Fmt1(coverageTable, deltaGlyph);
        }
      case 2:
        {
          int glyphCount = reader.readUInt16();
          List<int> substituteGlyphs =
              Utils.readUInt16Array(reader, glyphCount);
          CoverageTable coverageTable =
              CoverageTable.createFrom(reader, subTableStartAt + coverage);
          return LkSubTableT1Fmt2(coverageTable, substituteGlyphs);
        }
      default:
        throw UnsupportedError("LookupType 1 Format $format not supported");
    }
  }

  // LookupType 2: Multiple Substitution Subtable
  LookupSubTable _readLookupType2(
      ByteOrderSwappingBinaryReader reader, int subTableStartAt) {
    reader.seek(subTableStartAt);
    int format = reader.readUInt16();
    switch (format) {
      case 1:
        {
          int coverageOffset = reader.readUInt16();
          int seqCount = reader.readUInt16();
          List<int> seqOffsets = Utils.readUInt16Array(reader, seqCount);

          var subTable = LkSubTableT2();
          subTable.seqTables = List<SequenceTable>.generate(seqCount, (n) {
            reader.seek(subTableStartAt + seqOffsets[n]);
            int glyphCount = reader.readUInt16();
            return SequenceTable(Utils.readUInt16Array(reader, glyphCount));
          });

          subTable.coverageTable = CoverageTable.createFrom(
              reader, subTableStartAt + coverageOffset);
          return subTable;
        }
      default:
        throw UnsupportedError("LookupType 2 Format $format not supported");
    }
  }

  // LookupType 3: Alternate Substitution Subtable
  LookupSubTable _readLookupType3(
      ByteOrderSwappingBinaryReader reader, int subTableStartAt) {
    reader.seek(subTableStartAt);
    int format = reader.readUInt16();
    switch (format) {
      case 1:
        {
          int coverageOffset = reader.readUInt16();
          int alternativeSetCount = reader.readUInt16();
          List<int> alternativeTableOffsets =
              Utils.readUInt16Array(reader, alternativeSetCount);

          var subTable = LkSubTableT3();
          subTable.alternativeSetTables =
              List<AlternativeSetTable>.generate(alternativeSetCount, (n) {
            return AlternativeSetTable.createFrom(
                reader, subTableStartAt + alternativeTableOffsets[n]);
          });

          subTable.coverageTable = CoverageTable.createFrom(
              reader, subTableStartAt + coverageOffset);
          return subTable;
        }
      default:
        throw UnsupportedError("LookupType 3 Format $format not supported");
    }
  }

  // LookupType 4: Ligature Substitution Subtable
  LookupSubTable _readLookupType4(
      ByteOrderSwappingBinaryReader reader, int subTableStartAt) {
    reader.seek(subTableStartAt);
    int format = reader.readUInt16();
    switch (format) {
      case 1:
        {
          int coverageOffset = reader.readUInt16();
          int ligSetCount = reader.readUInt16();
          List<int> ligSetOffsets = Utils.readUInt16Array(reader, ligSetCount);

          var subTable = LkSubTableT4();
          subTable.ligatureSetTables =
              List<LigatureSetTable>.generate(ligSetCount, (n) {
            return LigatureSetTable.createFrom(
                reader, subTableStartAt + ligSetOffsets[n]);
          });

          subTable.coverageTable = CoverageTable.createFrom(
              reader, subTableStartAt + coverageOffset);
          return subTable;
        }
      default:
        throw UnsupportedError("LookupType 4 Format $format not supported");
    }
  }
}

// --- SubTable Implementations ---

class LkSubTableT1Fmt1 extends LookupSubTable {
  final CoverageTable coverageTable;
  final int deltaGlyph;

  LkSubTableT1Fmt1(this.coverageTable, this.deltaGlyph);

  @override
  bool doSubstitutionAt(IGlyphIndexList glyphIndices, int pos, int len) {
    int glyphIndex = glyphIndices[pos];
    if (coverageTable.findPosition(glyphIndex) > -1) {
      glyphIndices.replace(pos, (glyphIndex + deltaGlyph) & 0xFFFF);
      return true;
    }
    return false;
  }

  @override
  void collectAssociatedSubstitutionGlyphs(List<int> outputAssocGlyphs) {
    for (int glyphIndex in coverageTable.getExpandedValueIter()) {
      outputAssocGlyphs.add((glyphIndex + deltaGlyph) & 0xFFFF);
    }
  }
}

class LkSubTableT1Fmt2 extends LookupSubTable {
  final CoverageTable coverageTable;
  final List<int> substituteGlyphs;

  LkSubTableT1Fmt2(this.coverageTable, this.substituteGlyphs);

  @override
  bool doSubstitutionAt(IGlyphIndexList glyphIndices, int pos, int len) {
    int foundAt = coverageTable.findPosition(glyphIndices[pos]);
    if (foundAt > -1) {
      glyphIndices.replace(pos, substituteGlyphs[foundAt]);
      return true;
    }
    return false;
  }

  @override
  void collectAssociatedSubstitutionGlyphs(List<int> outputAssocGlyphs) {
    for (int glyphIndex in coverageTable.getExpandedValueIter()) {
      int foundAt = coverageTable.findPosition(glyphIndex);
      outputAssocGlyphs.add(substituteGlyphs[foundAt]);
    }
  }
}

class LkSubTableT2 extends LookupSubTable {
  late CoverageTable coverageTable;
  late List<SequenceTable> seqTables;

  @override
  bool doSubstitutionAt(IGlyphIndexList glyphIndices, int pos, int len) {
    int foundPos = coverageTable.findPosition(glyphIndices[pos]);
    if (foundPos > -1) {
      SequenceTable seqTable = seqTables[foundPos];
      glyphIndices.replaceWithMultiple(pos, seqTable.substituteGlyphs);
      return true;
    }
    return false;
  }

  @override
  void collectAssociatedSubstitutionGlyphs(List<int> outputAssocGlyphs) {
    for (int glyphIndex in coverageTable.getExpandedValueIter()) {
      int pos = coverageTable.findPosition(glyphIndex);
      outputAssocGlyphs.addAll(seqTables[pos].substituteGlyphs);
    }
  }
}

class SequenceTable {
  final List<int> substituteGlyphs;
  SequenceTable(this.substituteGlyphs);
}

class LkSubTableT3 extends LookupSubTable {
  late CoverageTable coverageTable;
  late List<AlternativeSetTable> alternativeSetTables;

  @override
  bool doSubstitutionAt(IGlyphIndexList glyphIndices, int pos, int len) {
    // int iscovered = coverageTable.findPosition(glyphIndices[pos]);
    Utils.warnUnimplemented("Lookup Subtable Type 3");
    return false;
  }

  @override
  void collectAssociatedSubstitutionGlyphs(List<int> outputAssocGlyphs) {
    Utils.warnUnimplemented("collect-assoc-sub-glyph: $this");
  }
}

class AlternativeSetTable {
  late List<int> alternativeGlyphIds;

  static AlternativeSetTable createFrom(
      ByteOrderSwappingBinaryReader reader, int beginAt) {
    reader.seek(beginAt);
    var altTable = AlternativeSetTable();
    int glyphCount = reader.readUInt16();
    altTable.alternativeGlyphIds = Utils.readUInt16Array(reader, glyphCount);
    return altTable;
  }
}

class LkSubTableT4 extends LookupSubTable {
  late CoverageTable coverageTable;
  late List<LigatureSetTable> ligatureSetTables;

  @override
  bool doSubstitutionAt(IGlyphIndexList glyphIndices, int pos, int len) {
    //check coverage
    int glyphIndex = glyphIndices[pos];
    int foundPos = coverageTable.findPosition(glyphIndex);
    if (foundPos > -1) {
      LigatureSetTable ligTable = ligatureSetTables[foundPos];
      for (LigatureTable lig in ligTable.ligatures) {
        int remainingLen = len - 1;
        int compLen = lig.componentGlyphs.length;
        if (compLen > remainingLen) {
          // skip tp next component
          continue;
        }
        bool allMatched = true;
        int tmp_i = pos + 1;
        for (int p = 0; p < compLen; ++p) {
          if (glyphIndices[tmp_i + p] != lig.componentGlyphs[p]) {
            allMatched = false;
            break; //exit from loop
          }
        }
        if (allMatched) {
          // remove all matches and replace with selected glyph
          // replaceRange(index, removeLen, newGlyph)
          // removeLen is compLen (components after first) + 1 (first glyph) - wait.
          // Ligature components start with second component.
          // So total glyphs to replace = 1 (first) + compLen.
          // Wait, replaceRange takes removeLen.
          // If compLen is number of components AFTER first, then total to remove is 1 + compLen.
          // But `compLen` here is `lig.componentGlyphs.length`.
          // `lig.componentGlyphs` array of component GlyphIDs-start with the second component.
          // So yes, total removed is 1 + compLen.

          glyphIndices.replaceRange(pos, compLen + 1, lig.glyphId);
          return true;
        }
      }
    }
    return false;
  }

  @override
  void collectAssociatedSubstitutionGlyphs(List<int> outputAssocGlyphs) {
    for (int glyphIndex in coverageTable.getExpandedValueIter()) {
      int foundPos = coverageTable.findPosition(glyphIndex);
      LigatureSetTable ligTable = ligatureSetTables[foundPos];
      for (LigatureTable lig in ligTable.ligatures) {
        outputAssocGlyphs.add(lig.glyphId);
      }
    }
  }
}

class LigatureSetTable {
  late List<LigatureTable> ligatures;

  static LigatureSetTable createFrom(
      ByteOrderSwappingBinaryReader reader, int beginAt) {
    var ligSetTable = LigatureSetTable();
    reader.seek(beginAt);
    int ligCount = reader.readUInt16();
    List<int> ligOffsets = Utils.readUInt16Array(reader, ligCount);

    ligSetTable.ligatures = List<LigatureTable>.generate(ligCount, (i) {
      return LigatureTable.createFrom(reader, beginAt + ligOffsets[i]);
    });
    return ligSetTable;
  }
}

class LigatureTable {
  late int glyphId;
  late List<int> componentGlyphs;

  static LigatureTable createFrom(
      ByteOrderSwappingBinaryReader reader, int beginAt) {
    reader.seek(beginAt);
    var ligTable = LigatureTable();
    ligTable.glyphId = reader.readUInt16();
    int compCount = reader.readUInt16();
    ligTable.componentGlyphs = Utils.readUInt16Array(reader, compCount - 1);
    return ligTable;
  }

  @override
  String toString() {
    return "output:$glyphId,{${componentGlyphs.join(',')}}";
  }
}
