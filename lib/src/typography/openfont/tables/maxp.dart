// Apache2, 2017-present, WinterDev
// Apache2, 2014-2016, Samuel Carlsson, WinterDev
// Ported to Dart by insinfo

import '../../../typography/io/byte_order_swapping_reader.dart';
import '../../../typography/openfont/tables/table_entry.dart';

/// Maximum Profile Table ('maxp')
/// This table establishes the memory requirements for the font.
/// Fonts with CFF data use Version 0.5 (only numGlyphs field).
/// Fonts with TrueType outlines use Version 1.0 (all data required).
class MaxProfile extends TableEntry {
  static const String tableName = 'maxp';

  @override
  String get name => tableName;

  int version = 0;
  int glyphCount = 0;
  int maxPointsPerGlyph = 0;
  int maxContoursPerGlyph = 0;
  int maxPointsPerCompositeGlyph = 0;
  int maxContoursPerCompositeGlyph = 0;
  int maxZones = 0;
  int maxTwilightPoints = 0;
  int maxStorage = 0;
  int maxFunctionDefs = 0;
  int maxInstructionDefs = 0;
  int maxStackElements = 0;
  int maxSizeOfInstructions = 0;
  int maxComponentElements = 0;
  int maxComponentDepth = 0;

  MaxProfile();

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    version = reader.readUInt32(); // 0x00010000 for version 1.0 or 0x00005000 for 0.5
    glyphCount = reader.readUInt16();

    // Version 1.0 has additional fields
    if (version >= 0x00010000) {
      maxPointsPerGlyph = reader.readUInt16();
      maxContoursPerGlyph = reader.readUInt16();
      maxPointsPerCompositeGlyph = reader.readUInt16();
      maxContoursPerCompositeGlyph = reader.readUInt16();
      maxZones = reader.readUInt16();
      maxTwilightPoints = reader.readUInt16();
      maxStorage = reader.readUInt16();
      maxFunctionDefs = reader.readUInt16();
      maxInstructionDefs = reader.readUInt16();
      maxStackElements = reader.readUInt16();
      maxSizeOfInstructions = reader.readUInt16();
      maxComponentElements = reader.readUInt16();
      maxComponentDepth = reader.readUInt16();
    }
  }

  @override
  String toString() => 'MaxProfile(glyphCount: $glyphCount, version: 0x${version.toRadixString(16)})';
}
