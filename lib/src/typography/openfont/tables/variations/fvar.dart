// MIT, 2019-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../../../io/byte_order_swapping_reader.dart';
import '../table_entry.dart';
import '../utils.dart';

/// fvar font variations
class FVar extends TableEntry {
  static const String _N = "fvar";
  @override
  String get name => _N;

  List<VariableAxisRecord>? variableAxisRecords;
  List<InstanceRecord>? instanceRecords;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    // Font variations header:
    // Type      Name            Description
    // uint16    majorVersion    Major version number of the font variations table — set to 1.
    // uint16    minorVersion    Minor version number of the font variations table — set to 0.
    // Offset16  axesArrayOffset Offset in bytes from the beginning of the table to the start of the VariationAxisRecord array.
    // uint16    (reserved)      This field is permanently reserved. Set to 2.
    // uint16    axisCount       The number of variation axes in the font (the number of records in the axes array).
    // uint16    axisSize        The size in bytes of each VariationAxisRecord — set to 20 (0x0014) for this version.
    // uint16    instanceCount   The number of named instances defined in the font (the number of records in the instances array).
    // uint16    instanceSize    The size in bytes of each InstanceRecord — set to either axisCount * sizeof(Fixed) + 4,
    //                          or to axisCount * sizeof(Fixed) + 6.

    int startPos = reader.position;
    int majorVersion = reader.readUInt16();
    int minorVersion = reader.readUInt16();
    int axesArrayOffset = reader.readUInt16();
    int reserved = reader.readUInt16(); // set to 2
    int axisCount = reader.readUInt16();
    int axisSize = reader.readUInt16();
    int instanceCount = reader.readUInt16();
    int instanceSize = reader.readUInt16();

    // Use variables to suppress warnings
    if (majorVersion == 0 && minorVersion == 0 && reserved == 0) {}

    // Seek to axes array
    if (axesArrayOffset > 0) {
       // axesArrayOffset is from start of table
       // We assume reader was at start of table when called
       // But wait, reader.position is absolute.
       // If we assume startPos is the start of the table.
       int absoluteAxesOffset = startPos + axesArrayOffset;
       // Only seek if we are not already there (e.g. if axesArrayOffset points to right after header)
       // Header size is 16.
       if (reader.position != absoluteAxesOffset) {
         reader.seek(absoluteAxesOffset);
       }
    }

    variableAxisRecords = List<VariableAxisRecord>.generate(axisCount, (index) {
      int pos = reader.position;
      VariableAxisRecord varAxisRecord = VariableAxisRecord();
      varAxisRecord.readContent(reader);
      
      if (reader.position != pos + axisSize) {
        reader.seek(pos + axisSize);
      }
      return varAxisRecord;
    });

    instanceRecords = List<InstanceRecord>.generate(instanceCount, (index) {
      int pos = reader.position;

      InstanceRecord instanceRec = InstanceRecord();
      instanceRec.readContent(reader, axisCount, instanceSize);

      if (reader.position != pos + instanceSize) {
        reader.seek(pos + instanceSize);
      }
      return instanceRec;
    });
  }
}

class VariableAxisRecord {
  // VariationAxisRecord
  // Type      Name        Description
  // Tag       axisTag     Tag identifying the design variation for the axis.
  // Fixed     minValue    The minimum coordinate value for the axis.
  // Fixed     defaultValue    The default coordinate value for the axis.
  // Fixed     maxValue        The maximum coordinate value for the axis.
  // uint16    flags           Axis qualifiers — see details below.
  // uint16    axisNameID      The name ID for entries in the 'name' table that provide a display name for this axis.

  String axisTag = "";
  double minValue = 0;
  double defaultValue = 0;
  double maxValue = 0;
  int flags = 0;
  int axisNameID = 0;

  void readContent(ByteOrderSwappingBinaryReader reader) {
    axisTag = Utils.tagToString(reader.readUInt32()); // 4
    minValue = Utils.readFixed(reader); // 4
    defaultValue = Utils.readFixed(reader); // 4
    maxValue = Utils.readFixed(reader); // 4
    flags = reader.readUInt16(); // 2
    axisNameID = reader.readUInt16(); // 2
  }
}

class InstanceRecord {
  // InstanceRecord
  // Type      Name                Description
  // uint16    subfamilyNameID     The name ID for entries in the 'name' table that provide subfamily names for this instance.
  // uint16    flags               Reserved for future use — set to 0.
  // Tuple     coordinates         The coordinates array for this instance.
  // uint16    postScriptNameID    Optional. The name ID for entries in the 'name' table that provide PostScript names for this instance.

  int subfamilyNameID = 0;
  int flags = 0;
  List<double>? coordinates; // tuple record
  int postScriptNameID = 0;

  void readContent(ByteOrderSwappingBinaryReader reader, int axisCount,
      int instanceRecordSize) {
    // int expectedEndPos = reader.position + instanceRecordSize;
    subfamilyNameID = reader.readUInt16();
    flags = reader.readUInt16();
    coordinates = List<double>.generate(axisCount, (index) {
      return Utils.readFixed(reader);
    });

    // Check if we have room for postScriptNameID (optional)
    // The size of fixed part is 2 + 2 + axisCount * 4
    // If instanceRecordSize > that, we have postScriptNameID
    int currentSize = 2 + 2 + (axisCount * 4);
    
    if (currentSize < instanceRecordSize) {
      // optional field
      postScriptNameID = reader.readUInt16();
    }
  }
}
