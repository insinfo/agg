// MIT, 2019-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../../../io/byte_order_swapping_reader.dart';
import '../table_entry.dart';
import '../utils.dart';

/// STAT — Style Attributes Table
class STAT extends TableEntry {
  static const String _N = "STAT";
  @override
  String get name => _N;

  List<AxisRecord>? axisRecords;
  List<AxisValueTableBase>? axisValueTables;
  int elidedFallbackNameID = 0;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    int beginPos = reader.position;

    // Style Attributes Header
    int majorVersion = reader.readUInt16();
    int minorVersion = reader.readUInt16();
    int designAxisSize = reader.readUInt16();
    int designAxisCount = reader.readUInt16();
    int designAxesOffset = reader.readUInt32();
    int axisValueCount = reader.readUInt16();
    int offsetToAxisValueOffsets = reader.readUInt32();

    if (minorVersion != 0) {
      elidedFallbackNameID = reader.readUInt16();
    } else {
      elidedFallbackNameID = 0;
    }

    // Suppress unused warnings
    if (majorVersion == 0) {}

    // Read Axis Records
    // We need to seek to designAxesOffset from the beginning of the table
    if (designAxisCount > 0 && designAxesOffset > 0) {
      reader.seek(beginPos + designAxesOffset);
      axisRecords = List<AxisRecord>.generate(designAxisCount, (index) {
        int recordStart = reader.position;
        AxisRecord record = AxisRecord();
        record.axisTagName = Utils.tagToString(reader.readUInt32());
        record.axisNameId = reader.readUInt16();
        record.axisOrdering = reader.readUInt16();

        // Skip extra bytes if designAxisSize > 8
        if (designAxisSize > 8) {
          reader.seek(recordStart + designAxisSize);
        }
        return record;
      });
    }

    // Read Axis Value Offsets
    if (axisValueCount > 0 && offsetToAxisValueOffsets > 0) {
      reader.seek(beginPos + offsetToAxisValueOffsets);
      int axisValueOffsetsBeginPos = reader.position;
      List<int> axisValueOffsets = Utils.readUInt16Array(reader, axisValueCount);

      axisValueTables = List<AxisValueTableBase>.generate(axisValueCount, (index) {
        int offset = axisValueOffsets[index];
        reader.seek(axisValueOffsetsBeginPos + offset);

        int format = reader.readUInt16();
        AxisValueTableBase table;

        switch (format) {
          case 1:
            table = AxisValueTableFmt1();
            break;
          case 2:
            table = AxisValueTableFmt2();
            break;
          case 3:
            table = AxisValueTableFmt3();
            break;
          case 4:
            table = AxisValueTableFmt4();
            break;
          default:
            throw UnsupportedError("STAT Axis Value Table format $format not supported");
        }
        table.readContent(reader);
        return table;
      });
    }
  }
}

class AxisRecord {
  String axisTagName = "";
  int axisNameId = 0;
  int axisOrdering = 0;

  @override
  String toString() => axisTagName;
}

abstract class AxisValueTableBase {
  int get format;
  void readContent(ByteOrderSwappingBinaryReader reader);
}

class AxisValueTableFmt1 extends AxisValueTableBase {
  @override
  int get format => 1;

  int axisIndex = 0;
  int flags = 0;
  int valueNameId = 0;
  double value = 0;

  @override
  void readContent(ByteOrderSwappingBinaryReader reader) {
    axisIndex = reader.readUInt16();
    flags = reader.readUInt16();
    valueNameId = reader.readUInt16();
    value = Utils.readFixed(reader);
  }
}

class AxisValueTableFmt2 extends AxisValueTableBase {
  @override
  int get format => 2;

  int axisIndex = 0;
  int flags = 0;
  int valueNameId = 0;
  double nominalValue = 0;
  double rangeMinValue = 0;
  double rangeMaxValue = 0;

  @override
  void readContent(ByteOrderSwappingBinaryReader reader) {
    axisIndex = reader.readUInt16();
    flags = reader.readUInt16();
    valueNameId = reader.readUInt16();
    nominalValue = Utils.readFixed(reader);
    rangeMinValue = Utils.readFixed(reader);
    rangeMaxValue = Utils.readFixed(reader);
  }
}

class AxisValueTableFmt3 extends AxisValueTableBase {
  @override
  int get format => 3;

  int axisIndex = 0;
  int flags = 0;
  int valueNameId = 0;
  double value = 0;
  double linkedValue = 0;

  @override
  void readContent(ByteOrderSwappingBinaryReader reader) {
    axisIndex = reader.readUInt16();
    flags = reader.readUInt16();
    valueNameId = reader.readUInt16();
    value = Utils.readFixed(reader);
    linkedValue = Utils.readFixed(reader);
  }
}

class AxisValueTableFmt4 extends AxisValueTableBase {
  @override
  int get format => 4;

  List<AxisValueRecord>? axisValueRecords;
  int flags = 0;
  int valueNameId = 0;

  @override
  void readContent(ByteOrderSwappingBinaryReader reader) {
    int axisCount = reader.readUInt16();
    flags = reader.readUInt16();
    valueNameId = reader.readUInt16();
    axisValueRecords = List<AxisValueRecord>.generate(axisCount, (index) {
      return AxisValueRecord(
        reader.readUInt16(),
        Utils.readFixed(reader),
      );
    });
  }
}

class AxisValueRecord {
  final int axisIndex;
  final double value;

  AxisValueRecord(this.axisIndex, this.value);
}
