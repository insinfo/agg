import '../../../typography/io/byte_order_swapping_reader.dart';
import 'table_entry.dart';
import 'utils.dart';

/// BASE - Baseline Table
///
/// The Baseline table (BASE) provides information used to align glyphs of different scripts and sizes in a line of text,
/// whether the glyphs are in the same font or in different fonts.
/// To improve text layout, the Baseline table also provides minimum (min) and maximum (max) glyph extent values for each script,
/// language system, or feature in a font.
class BASE extends TableEntry {
  static const String tableName = 'BASE';
  @override
  String get name => tableName;

  AxisTable? horizontalAxis;
  AxisTable? verticalAxis;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    final tableStartAt = reader.position;

    reader.readUInt16(); // majorVersion
    final minorVersion = reader.readUInt16();
    final horizAxisOffset = reader.readUInt16();
    final vertAxisOffset = reader.readUInt16();
    int itemVarStoreOffset = 0;

    if (minorVersion == 1) {
      itemVarStoreOffset = reader.readUInt32();
    }

    if (horizAxisOffset > 0) {
      reader.seek(tableStartAt + horizAxisOffset);
      horizontalAxis = _readAxisTable(reader);
      horizontalAxis!.isVerticalAxis = false;
    }

    if (vertAxisOffset > 0) {
      reader.seek(tableStartAt + vertAxisOffset);
      verticalAxis = _readAxisTable(reader);
      verticalAxis!.isVerticalAxis = true;
    }

    if (itemVarStoreOffset > 0) {
      Utils.warnUnimplemented('BASE ItemVarStore not yet implemented');
    }
  }

  AxisTable _readAxisTable(ByteOrderSwappingBinaryReader reader) {
    final axisTableStartAt = reader.position;

    final baseTagListOffset = reader.readUInt16();
    final baseScriptListOffset = reader.readUInt16();

    final axisTable = AxisTable();

    if (baseTagListOffset > 0) {
      reader.seek(axisTableStartAt + baseTagListOffset);
      axisTable.baseTagList = _readBaseTagList(reader);
    }

    if (baseScriptListOffset > 0) {
      reader.seek(axisTableStartAt + baseScriptListOffset);
      axisTable.baseScripts = _readBaseScriptList(reader);
    }

    return axisTable;
  }

  List<String> _readBaseTagList(ByteOrderSwappingBinaryReader reader) {
    final baseTagCount = reader.readUInt16();
    final baselineTags = <String>[];
    for (var i = 0; i < baseTagCount; ++i) {
      baselineTags.add(Utils.tagToString(reader.readUInt32()));
    }
    return baselineTags;
  }

  List<BaseScript> _readBaseScriptList(ByteOrderSwappingBinaryReader reader) {
    final baseScriptListStartAt = reader.position;
    final baseScriptCount = reader.readUInt16();

    final baseScriptRecordOffsets = <_BaseScriptRecord>[];
    for (var i = 0; i < baseScriptCount; ++i) {
      baseScriptRecordOffsets.add(_BaseScriptRecord(
        Utils.tagToString(reader.readUInt32()),
        reader.readUInt16(),
      ));
    }

    final baseScripts = <BaseScript>[];
    for (var i = 0; i < baseScriptCount; ++i) {
      final record = baseScriptRecordOffsets[i];
      reader.seek(baseScriptListStartAt + record.baseScriptOffset);
      final baseScript = _readBaseScriptTable(reader);
      baseScript.scriptIdenTag = record.baseScriptTag;
      baseScripts.add(baseScript);
    }
    return baseScripts;
  }

  BaseScript _readBaseScriptTable(ByteOrderSwappingBinaryReader reader) {
    final baseScriptTableStartAt = reader.position;

    final baseValueOffset = reader.readUInt16();
    final defaultMinMaxOffset = reader.readUInt16();
    final baseLangSysCount = reader.readUInt16();

    List<BaseLangSysRecord>? baseLangSysRecords;
    if (baseLangSysCount > 0) {
      baseLangSysRecords = [];
      for (var i = 0; i < baseLangSysCount; ++i) {
        baseLangSysRecords.add(BaseLangSysRecord(
          Utils.tagToString(reader.readUInt32()),
          reader.readUInt16(),
        ));
      }
    }

    final baseScript = BaseScript();
    baseScript.baseLangSysRecords = baseLangSysRecords;

    if (baseValueOffset > 0) {
      reader.seek(baseScriptTableStartAt + baseValueOffset);
      baseScript.baseValues = _readBaseValues(reader);
    }

    if (defaultMinMaxOffset > 0) {
      reader.seek(baseScriptTableStartAt + defaultMinMaxOffset);
      baseScript.minMax = _readMinMaxTable(reader);
    }

    return baseScript;
  }

  BaseValues _readBaseValues(ByteOrderSwappingBinaryReader reader) {
    final baseValueTableStartAt = reader.position;

    final defaultBaselineIndex = reader.readUInt16();
    final baseCoordCount = reader.readUInt16();
    final baseCoordsOffsets = Utils.readUInt16Array(reader, baseCoordCount);

    final baseCoords = <BaseCoord>[];
    for (var i = 0; i < baseCoordCount; ++i) {
      reader.seek(baseValueTableStartAt + baseCoordsOffsets[i]);
      baseCoords.add(_readBaseCoordTable(reader));
    }

    return BaseValues(defaultBaselineIndex, baseCoords);
  }

  BaseCoord _readBaseCoordTable(ByteOrderSwappingBinaryReader reader) {
    final baseCoordFormat = reader.readUInt16();
    switch (baseCoordFormat) {
      case 1:
        return BaseCoord(1, reader.readInt16());
      case 2:
        return BaseCoord(
          2,
          reader.readInt16(),
          referenceGlyph: reader.readUInt16(),
          baseCoordPoint: reader.readUInt16(),
        );
      case 3:
        // TODO: Implement BaseCoord Format 3 (Device Table / Variation Index)
        return BaseCoord(3, reader.readInt16());
      default:
        throw FormatException('Unknown BaseCoord format: $baseCoordFormat');
    }
  }

  MinMax _readMinMaxTable(ByteOrderSwappingBinaryReader reader) {
    final startMinMaxTableAt = reader.position;

    final minCoordOffset = reader.readUInt16();
    final maxCoordOffset = reader.readUInt16();
    final featMinMaxCount = reader.readUInt16();

    List<_FeatureMinMaxOffset>? minMaxFeatureOffsets;
    if (featMinMaxCount > 0) {
      minMaxFeatureOffsets = [];
      for (var i = 0; i < featMinMaxCount; ++i) {
        minMaxFeatureOffsets.add(_FeatureMinMaxOffset(
          Utils.tagToString(reader.readUInt32()),
          reader.readUInt16(),
          reader.readUInt16(),
        ));
      }
    }

    final minMax = MinMax();

    if (minCoordOffset > 0) {
      reader.seek(startMinMaxTableAt + minCoordOffset);
      minMax.minCoord = _readBaseCoordTable(reader);
    }

    if (maxCoordOffset > 0) {
      reader.seek(startMinMaxTableAt + maxCoordOffset);
      minMax.maxCoord = _readBaseCoordTable(reader);
    }

    if (minMaxFeatureOffsets != null) {
      minMax.featureMinMaxRecords = [];
      for (final offset in minMaxFeatureOffsets) {
        final featureMinMax = FeatureMinMax();
        featureMinMax.featureTableTag = offset.featureTableTag;

        if (offset.minCoord > 0) {
          reader.seek(startMinMaxTableAt + offset.minCoord);
          featureMinMax.minCoord = _readBaseCoordTable(reader);
        }

        if (offset.maxCoord > 0) {
          reader.seek(startMinMaxTableAt + offset.maxCoord);
          featureMinMax.maxCoord = _readBaseCoordTable(reader);
        }

        minMax.featureMinMaxRecords!.add(featureMinMax);
      }
    }

    return minMax;
  }
}

class AxisTable {
  bool isVerticalAxis = false;
  List<String>? baseTagList;
  List<BaseScript>? baseScripts;

  @override
  String toString() => isVerticalAxis ? "vertical_axis" : "horizontal_axis";
}

class _BaseScriptRecord {
  final String baseScriptTag;
  final int baseScriptOffset;
  _BaseScriptRecord(this.baseScriptTag, this.baseScriptOffset);
}

class BaseLangSysRecord {
  final String baseScriptTag;
  final int baseScriptOffset;
  BaseLangSysRecord(this.baseScriptTag, this.baseScriptOffset);
}

class BaseScript {
  String? scriptIdenTag;
  BaseValues? baseValues;
  List<BaseLangSysRecord>? baseLangSysRecords;
  MinMax? minMax;

  @override
  String toString() => scriptIdenTag ?? super.toString();
}

class BaseValues {
  final int defaultBaseLineIndex;
  final List<BaseCoord> baseCoords;

  BaseValues(this.defaultBaseLineIndex, this.baseCoords);
}

class BaseCoord {
  final int baseCoordFormat;
  final int coord;
  final int referenceGlyph;
  final int baseCoordPoint;

  BaseCoord(
    this.baseCoordFormat,
    this.coord, {
    this.referenceGlyph = 0,
    this.baseCoordPoint = 0,
  });

  @override
  String toString() => "format:$baseCoordFormat,coord=$coord";
}

class MinMax {
  BaseCoord? minCoord;
  BaseCoord? maxCoord;
  List<FeatureMinMax>? featureMinMaxRecords;
}

class FeatureMinMax {
  String? featureTableTag;
  BaseCoord? minCoord;
  BaseCoord? maxCoord;
}

class _FeatureMinMaxOffset {
  final String featureTableTag;
  final int minCoord;
  final int maxCoord;
  _FeatureMinMaxOffset(this.featureTableTag, this.minCoord, this.maxCoord);
}
