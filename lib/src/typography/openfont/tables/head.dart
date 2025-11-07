// Apache2, 2017-present, WinterDev
// Apache2, 2014-2016, Samuel Carlsson, WinterDev
// Ported to Dart by insinfo

import '../../../typography/io/byte_order_swapping_reader.dart';
import '../../../typography/openfont/tables/table_entry.dart';
import '../../../typography/openfont/tables/utils.dart';

/// Font Header Table ('head')
/// This table gives global information about the font
class Head extends TableEntry {
  static const String tableName = 'head';

  @override
  String get name => tableName;

  int version = 0;
  int fontRevision = 0;
  int checkSumAdjustment = 0;
  int magicNumber = 0;
  int flags = 0;
  int unitsPerEm = 0;
  int created = 0;
  int modified = 0;
  Bounds bounds = const Bounds(0, 0, 0, 0);
  int macStyle = 0;
  int lowestRecPPEM = 0;
  int fontDirectionHint = 0;
  int indexToLocFormat = 0;
  int glyphDataFormat = 0;

  Head();

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    version = reader.readUInt32(); // 0x00010000 for version 1.0
    fontRevision = reader.readUInt32();
    checkSumAdjustment = reader.readUInt32();
    magicNumber = reader.readUInt32();
    
    if (magicNumber != 0x5F0F3CF5) {
      throw FormatException(
        'Invalid magic number: 0x${magicNumber.toRadixString(16)}',
      );
    }

    flags = reader.readUInt16();
    unitsPerEm = reader.readUInt16(); // valid is 16 to 16384
    created = reader.readUInt64(); // International date
    modified = reader.readUInt64();
    
    // Bounding box for all glyphs
    bounds = Bounds.read(reader);
    
    macStyle = reader.readUInt16();
    lowestRecPPEM = reader.readUInt16();
    fontDirectionHint = reader.readInt16();
    indexToLocFormat = reader.readInt16(); // 0 for 16-bit offsets, 1 for 32-bit
    glyphDataFormat = reader.readInt16(); // 0
  }

  /// Whether to use wide (32-bit) glyph locations
  bool get wideGlyphLocations => indexToLocFormat > 0;

  @override
  String toString() => 'Head(unitsPerEm: $unitsPerEm, bounds: $bounds)';
}
