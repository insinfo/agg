// MIT, 2018-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../../io/byte_order_swapping_reader.dart';
import 'coverage_table.dart';
import 'table_entry.dart';
import 'utils.dart';

class MathValueRecord {
  final int value;
  final int deviceTable;

  MathValueRecord(this.value, this.deviceTable);

  @override
  String toString() {
    if (deviceTable == 0) {
      return value.toString();
    } else {
      return '$value,$deviceTable';
    }
  }
}

class MathConstants {
  int scriptPercentScaleDown = 0;
  int scriptScriptPercentScaleDown = 0;
  int delimitedSubFormulaMinHeight = 0;
  int displayOperatorMinHeight = 0;

  late MathValueRecord mathLeading;
  late MathValueRecord axisHeight;
  late MathValueRecord accentBaseHeight;
  late MathValueRecord flattenedAccentBaseHeight;

  late MathValueRecord subscriptShiftDown;
  late MathValueRecord subscriptTopMax;
  late MathValueRecord subscriptBaselineDropMin;

  late MathValueRecord superscriptShiftUp;
  late MathValueRecord superscriptShiftUpCramped;
  late MathValueRecord superscriptBottomMin;
  late MathValueRecord superscriptBaselineDropMax;

  late MathValueRecord subSuperscriptGapMin;
  late MathValueRecord superscriptBottomMaxWithSubscript;
  late MathValueRecord spaceAfterScript;

  late MathValueRecord upperLimitGapMin;
  late MathValueRecord upperLimitBaselineRiseMin;
  late MathValueRecord lowerLimitGapMin;
  late MathValueRecord lowerLimitBaselineDropMin;

  late MathValueRecord stackTopShiftUp;
  late MathValueRecord stackTopDisplayStyleShiftUp;
  late MathValueRecord stackBottomShiftDown;
  late MathValueRecord stackBottomDisplayStyleShiftDown;
  late MathValueRecord stackGapMin;
  late MathValueRecord stackDisplayStyleGapMin;

  late MathValueRecord stretchStackTopShiftUp;
  late MathValueRecord stretchStackBottomShiftDown;
  late MathValueRecord stretchStackGapAboveMin;
  late MathValueRecord stretchStackGapBelowMin;

  late MathValueRecord fractionNumeratorShiftUp;
  late MathValueRecord fractionNumeratorDisplayStyleShiftUp;
  late MathValueRecord fractionDenominatorShiftDown;
  late MathValueRecord fractionDenominatorDisplayStyleShiftDown;
  late MathValueRecord fractionNumeratorGapMin;
  late MathValueRecord fractionNumDisplayStyleGapMin;
  late MathValueRecord fractionRuleThickness;
  late MathValueRecord fractionDenominatorGapMin;
  late MathValueRecord fractionDenomDisplayStyleGapMin;

  late MathValueRecord skewedFractionHorizontalGap;
  late MathValueRecord skewedFractionVerticalGap;

  late MathValueRecord overbarVerticalGap;
  late MathValueRecord overbarRuleThickness;
  late MathValueRecord overbarExtraAscender;

  late MathValueRecord underbarVerticalGap;
  late MathValueRecord underbarRuleThickness;
  late MathValueRecord underbarExtraDescender;

  late MathValueRecord radicalVerticalGap;
  late MathValueRecord radicalDisplayStyleVerticalGap;
  late MathValueRecord radicalRuleThickness;
  late MathValueRecord radicalExtraAscender;
  late MathValueRecord radicalKernBeforeDegree;
  late MathValueRecord radicalKernAfterDegree;
  int radicalDegreeBottomRaisePercent = 0;

  int minConnectorOverlap = 0;
}

class MathGlyphInfo {
  final int glyphIndex;
  MathGlyphInfo(this.glyphIndex);

  MathValueRecord? italicCorrection;
  MathValueRecord? topAccentAttachment;
  bool isShapeExtensible = false;

  MathKern? get topLeftMathKern => _mathKernRec?.topLeft;
  MathKern? get topRightMathKern => _mathKernRec?.topRight;
  MathKern? get bottomLeftMathKern => _mathKernRec?.bottomLeft;
  MathKern? get bottomRightMathKern => _mathKernRec?.bottomRight;
  bool hasSomeMathKern = false;

  MathKernInfoRecord? _mathKernRec;
  void setMathKerns(MathKernInfoRecord mathKernRec) {
    _mathKernRec = mathKernRec;
    hasSomeMathKern = true;
  }

  MathGlyphConstruction? vertGlyphConstruction;
  MathGlyphConstruction? horiGlyphConstruction;
}

class MathGlyphConstruction {
  late MathValueRecord glyphAsmItalicCorrection;
  List<GlyphPartRecord>? glyphAsmGlyphPartRecords;
  List<MathGlyphVariantRecord>? glyphVariantRecords;
}

class GlyphPartRecord {
  final int glyphId;
  final int startConnectorLength;
  final int endConnectorLength;
  final int fullAdvance;
  final int partFlags;

  bool get isExtender => (partFlags & 0x0001) != 0;

  GlyphPartRecord(
    this.glyphId,
    this.startConnectorLength,
    this.endConnectorLength,
    this.fullAdvance,
    this.partFlags,
  );

  @override
  String toString() => "glyph_id:$glyphId";
}

class MathGlyphVariantRecord {
  final int variantGlyph;
  final int advanceMeasurement;

  MathGlyphVariantRecord(this.variantGlyph, this.advanceMeasurement);

  @override
  String toString() => "variant_glyph_id:$variantGlyph, adv:$advanceMeasurement";
}

class MathKern {
  final int heightCount;
  final List<MathValueRecord> correctionHeights;
  final List<MathValueRecord> kernValues;

  MathKern(this.heightCount, this.correctionHeights, this.kernValues);

  @override
  String toString() => heightCount.toString();
}

class MathKernInfoRecord {
  final MathKern? topRight;
  final MathKern? topLeft;
  final MathKern? bottomRight;
  final MathKern? bottomLeft;

  MathKernInfoRecord(
    this.topRight,
    this.topLeft,
    this.bottomRight,
    this.bottomLeft,
  );
}

class MathItalicsCorrectonInfoTable {
  List<MathValueRecord>? italicCorrections;
  CoverageTable? coverageTable;
}

class MathTopAccentAttachmentTable {
  List<MathValueRecord>? topAccentAttachment;
  CoverageTable? coverageTable;
}

class MathVariantsTable {
  int minConnectorOverlap = 0;
  CoverageTable? vertCoverage;
  CoverageTable? horizCoverage;
  List<MathGlyphConstruction>? vertConstructionTables;
  List<MathGlyphConstruction>? horizConstructionTables;
}

class MathTable extends TableEntry {
  @override
  String get name => 'MATH';

  late MathConstants mathConstTable;
  late MathItalicsCorrectonInfoTable _mathItalicCorrectionInfo;
  late MathTopAccentAttachmentTable _mathTopAccentAttachmentTable;
  CoverageTable? extendedShapeCoverageTable;
  CoverageTable? mathKernInfoCoverage;
  List<MathKernInfoRecord>? mathKernInfoRecords;
  late MathVariantsTable _mathVariantsTable;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    final beginAt = reader.position;

    reader.readUInt16(); // majorVersion
    reader.readUInt16(); // minorVersion
    final mathConstantsOffset = reader.readUInt16();
    final mathGlyphInfoOffset = reader.readUInt16();
    final mathVariantsOffset = reader.readUInt16();

    // (1) MathConstants
    reader.seek(beginAt + mathConstantsOffset);
    _readMathConstantsTable(reader);

    // (2) MathGlyphInfo
    reader.seek(beginAt + mathGlyphInfoOffset);
    _readMathGlyphInfoTable(reader);

    // (3) MathVariants
    reader.seek(beginAt + mathVariantsOffset);
    _readMathVariantsTable(reader);

    // Expose MinConnectorOverlap via mathConstTable
    mathConstTable.minConnectorOverlap = _mathVariantsTable.minConnectorOverlap;
  }

  void _readMathConstantsTable(ByteOrderSwappingBinaryReader reader) {
    final mc = MathConstants();
    mc.scriptPercentScaleDown = reader.readInt16();
    mc.scriptScriptPercentScaleDown = reader.readInt16();
    mc.delimitedSubFormulaMinHeight = reader.readUInt16();
    mc.displayOperatorMinHeight = reader.readUInt16();

    mc.mathLeading = _readMathValueRecord(reader);
    mc.axisHeight = _readMathValueRecord(reader);
    mc.accentBaseHeight = _readMathValueRecord(reader);
    mc.flattenedAccentBaseHeight = _readMathValueRecord(reader);

    mc.subscriptShiftDown = _readMathValueRecord(reader);
    mc.subscriptTopMax = _readMathValueRecord(reader);
    mc.subscriptBaselineDropMin = _readMathValueRecord(reader);

    mc.superscriptShiftUp = _readMathValueRecord(reader);
    mc.superscriptShiftUpCramped = _readMathValueRecord(reader);
    mc.superscriptBottomMin = _readMathValueRecord(reader);
    mc.superscriptBaselineDropMax = _readMathValueRecord(reader);

    mc.subSuperscriptGapMin = _readMathValueRecord(reader);
    mc.superscriptBottomMaxWithSubscript = _readMathValueRecord(reader);
    mc.spaceAfterScript = _readMathValueRecord(reader);

    mc.upperLimitGapMin = _readMathValueRecord(reader);
    mc.upperLimitBaselineRiseMin = _readMathValueRecord(reader);
    mc.lowerLimitGapMin = _readMathValueRecord(reader);
    mc.lowerLimitBaselineDropMin = _readMathValueRecord(reader);

    mc.stackTopShiftUp = _readMathValueRecord(reader);
    mc.stackTopDisplayStyleShiftUp = _readMathValueRecord(reader);
    mc.stackBottomShiftDown = _readMathValueRecord(reader);
    mc.stackBottomDisplayStyleShiftDown = _readMathValueRecord(reader);
    mc.stackGapMin = _readMathValueRecord(reader);
    mc.stackDisplayStyleGapMin = _readMathValueRecord(reader);

    mc.stretchStackTopShiftUp = _readMathValueRecord(reader);
    mc.stretchStackBottomShiftDown = _readMathValueRecord(reader);
    mc.stretchStackGapAboveMin = _readMathValueRecord(reader);
    mc.stretchStackGapBelowMin = _readMathValueRecord(reader);

    mc.fractionNumeratorShiftUp = _readMathValueRecord(reader);
    mc.fractionNumeratorDisplayStyleShiftUp = _readMathValueRecord(reader);
    mc.fractionDenominatorShiftDown = _readMathValueRecord(reader);
    mc.fractionDenominatorDisplayStyleShiftDown = _readMathValueRecord(reader);
    mc.fractionNumeratorGapMin = _readMathValueRecord(reader);
    mc.fractionNumDisplayStyleGapMin = _readMathValueRecord(reader);
    mc.fractionRuleThickness = _readMathValueRecord(reader);
    mc.fractionDenominatorGapMin = _readMathValueRecord(reader);
    mc.fractionDenomDisplayStyleGapMin = _readMathValueRecord(reader);

    mc.skewedFractionHorizontalGap = _readMathValueRecord(reader);
    mc.skewedFractionVerticalGap = _readMathValueRecord(reader);

    mc.overbarVerticalGap = _readMathValueRecord(reader);
    mc.overbarRuleThickness = _readMathValueRecord(reader);
    mc.overbarExtraAscender = _readMathValueRecord(reader);

    mc.underbarVerticalGap = _readMathValueRecord(reader);
    mc.underbarRuleThickness = _readMathValueRecord(reader);
    mc.underbarExtraDescender = _readMathValueRecord(reader);

    mc.radicalVerticalGap = _readMathValueRecord(reader);
    mc.radicalDisplayStyleVerticalGap = _readMathValueRecord(reader);
    mc.radicalRuleThickness = _readMathValueRecord(reader);
    mc.radicalExtraAscender = _readMathValueRecord(reader);
    mc.radicalKernBeforeDegree = _readMathValueRecord(reader);
    mc.radicalKernAfterDegree = _readMathValueRecord(reader);
    mc.radicalDegreeBottomRaisePercent = reader.readInt16();

    mathConstTable = mc;
  }

  void _readMathGlyphInfoTable(ByteOrderSwappingBinaryReader reader) {
    final startAt = reader.position;
    final offsetToMathItalicsCorrectionInfoTable = reader.readUInt16();
    final offsetToMathTopAccentAttachmentTable = reader.readUInt16();
    final offsetToExtendedShapeCoverageTable = reader.readUInt16();
    final offsetToMathKernInfoTable = reader.readUInt16();

    // (2.1)
    reader.seek(startAt + offsetToMathItalicsCorrectionInfoTable);
    _readMathItalicCorrectionInfoTable(reader);

    // (2.2)
    reader.seek(startAt + offsetToMathTopAccentAttachmentTable);
    _readMathTopAccentAttachment(reader);

    // (2.3)
    if (offsetToExtendedShapeCoverageTable > 0) {
      extendedShapeCoverageTable = CoverageTable.createFrom(reader, startAt + offsetToExtendedShapeCoverageTable);
    }

    // (2.4)
    if (offsetToMathKernInfoTable > 0) {
      reader.seek(startAt + offsetToMathKernInfoTable);
      _readMathKernInfoTable(reader);
    }
  }

  void _readMathItalicCorrectionInfoTable(ByteOrderSwappingBinaryReader reader) {
    final beginAt = reader.position;
    _mathItalicCorrectionInfo = MathItalicsCorrectonInfoTable();

    final coverageOffset = reader.readUInt16();
    final italicCorrectionCount = reader.readUInt16();
    _mathItalicCorrectionInfo.italicCorrections = _readMathValueRecords(reader, italicCorrectionCount);

    if (coverageOffset > 0) {
      _mathItalicCorrectionInfo.coverageTable = CoverageTable.createFrom(reader, beginAt + coverageOffset);
    }
  }

  void _readMathTopAccentAttachment(ByteOrderSwappingBinaryReader reader) {
    final beginAt = reader.position;
    _mathTopAccentAttachmentTable = MathTopAccentAttachmentTable();

    final coverageOffset = reader.readUInt16();
    final topAccentAttachmentCount = reader.readUInt16();
    _mathTopAccentAttachmentTable.topAccentAttachment = _readMathValueRecords(reader, topAccentAttachmentCount);

    if (coverageOffset > 0) {
      _mathTopAccentAttachmentTable.coverageTable = CoverageTable.createFrom(reader, beginAt + coverageOffset);
    }
  }

  void _readMathKernInfoTable(ByteOrderSwappingBinaryReader reader) {
    final beginAt = reader.position;

    final mathKernCoverageOffset = reader.readUInt16();
    final mathKernCount = reader.readUInt16();

    final allKernRecOffset = Utils.readUInt16Array(reader, 4 * mathKernCount);

    mathKernInfoRecords = List<MathKernInfoRecord>.generate(mathKernCount, (i) {
      final index = i * 4;
      
      // top-right
      var mKernOffset = allKernRecOffset[index];
      MathKern? topRight;
      if (mKernOffset > 0) {
        reader.seek(beginAt + mKernOffset);
        topRight = _readMathKernTable(reader);
      }

      // top-left
      mKernOffset = allKernRecOffset[index + 1];
      MathKern? topLeft;
      if (mKernOffset > 0) {
        reader.seek(beginAt + mKernOffset);
        topLeft = _readMathKernTable(reader);
      }

      // bottom-right
      mKernOffset = allKernRecOffset[index + 2];
      MathKern? bottomRight;
      if (mKernOffset > 0) {
        reader.seek(beginAt + mKernOffset);
        bottomRight = _readMathKernTable(reader);
      }

      // bottom-left
      mKernOffset = allKernRecOffset[index + 3];
      MathKern? bottomLeft;
      if (mKernOffset > 0) {
        reader.seek(beginAt + mKernOffset);
        bottomLeft = _readMathKernTable(reader);
      }

      return MathKernInfoRecord(topRight, topLeft, bottomRight, bottomLeft);
    });

    mathKernInfoCoverage = CoverageTable.createFrom(reader, beginAt + mathKernCoverageOffset);
  }

  MathKern _readMathKernTable(ByteOrderSwappingBinaryReader reader) {
    final heightCount = reader.readUInt16();
    return MathKern(
      heightCount,
      _readMathValueRecords(reader, heightCount),
      _readMathValueRecords(reader, heightCount + 1),
    );
  }

  void _readMathVariantsTable(ByteOrderSwappingBinaryReader reader) {
    _mathVariantsTable = MathVariantsTable();
    final beginAt = reader.position;

    _mathVariantsTable.minConnectorOverlap = reader.readUInt16();
    final vertGlyphCoverageOffset = reader.readUInt16();
    final horizGlyphCoverageOffset = reader.readUInt16();
    final vertGlyphCount = reader.readUInt16();
    final horizGlyphCount = reader.readUInt16();
    final vertGlyphConstructions = Utils.readUInt16Array(reader, vertGlyphCount);
    final horizonGlyphConstructions = Utils.readUInt16Array(reader, horizGlyphCount);

    _mathVariantsTable.vertCoverage = CoverageTable.createFrom(reader, beginAt + vertGlyphCoverageOffset);

    if (horizGlyphCoverageOffset > 0) {
      _mathVariantsTable.horizCoverage = CoverageTable.createFrom(reader, beginAt + horizGlyphCoverageOffset);
    }

    // (3.1) vertical
    _mathVariantsTable.vertConstructionTables = List<MathGlyphConstruction>.generate(vertGlyphCount, (i) {
      reader.seek(beginAt + vertGlyphConstructions[i]);
      return _readMathGlyphConstructionTable(reader);
    });

    // (3.2) horizontal
    _mathVariantsTable.horizConstructionTables = List<MathGlyphConstruction>.generate(horizGlyphCount, (i) {
      reader.seek(beginAt + horizonGlyphConstructions[i]);
      return _readMathGlyphConstructionTable(reader);
    });
  }

  MathGlyphConstruction _readMathGlyphConstructionTable(ByteOrderSwappingBinaryReader reader) {
    final beginAt = reader.position;
    final glyphConstructionTable = MathGlyphConstruction();

    final glyphAsmOffset = reader.readUInt16();
    final variantCount = reader.readUInt16();

    glyphConstructionTable.glyphVariantRecords = List<MathGlyphVariantRecord>.generate(variantCount, (i) {
      return MathGlyphVariantRecord(reader.readUInt16(), reader.readUInt16());
    });

    if (glyphAsmOffset > 0) {
      reader.seek(beginAt + glyphAsmOffset);
      _fillGlyphAssemblyInfo(reader, glyphConstructionTable);
    }

    return glyphConstructionTable;
  }

  void _fillGlyphAssemblyInfo(ByteOrderSwappingBinaryReader reader, MathGlyphConstruction glyphConstruction) {
    glyphConstruction.glyphAsmItalicCorrection = _readMathValueRecord(reader);
    final partCount = reader.readUInt16();
    glyphConstruction.glyphAsmGlyphPartRecords = List<GlyphPartRecord>.generate(partCount, (i) {
      return GlyphPartRecord(
        reader.readUInt16(),
        reader.readUInt16(),
        reader.readUInt16(),
        reader.readUInt16(),
        reader.readUInt16(),
      );
    });
  }

  MathValueRecord _readMathValueRecord(ByteOrderSwappingBinaryReader reader) {
    return MathValueRecord(reader.readInt16(), reader.readUInt16());
  }

  List<MathValueRecord> _readMathValueRecords(ByteOrderSwappingBinaryReader reader, int count) {
    return List<MathValueRecord>.generate(count, (i) => _readMathValueRecord(reader));
  }
}
