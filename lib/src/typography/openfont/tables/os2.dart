// Apache2, 2016-present, WinterDev
// Ported to Dart by insinfo

import 'dart:typed_data';
import '../../../typography/io/byte_order_swapping_reader.dart';
import '../../../typography/openfont/tables/table_entry.dart';

/// OS/2 and Windows Metrics Table
/// Contains metrics and other data required in OpenType fonts
/// Supports versions 0-5
class OS2Table extends TableEntry {
  static const String tableName = 'OS/2';

  @override
  String get name => tableName;

  // Version and basic metrics
  int version = 0;
  int xAvgCharWidth = 0;
  int usWeightClass = 0; // 0-1000, degree of blackness/thickness
  int usWidthClass = 0; // Relative aspect ratio change
  int fsType = 0; // Embedding licensing rights

  // Subscript metrics
  int ySubscriptXSize = 0;
  int ySubscriptYSize = 0;
  int ySubscriptXOffset = 0;
  int ySubscriptYOffset = 0;

  // Superscript metrics
  int ySuperscriptXSize = 0;
  int ySuperscriptYSize = 0;
  int ySuperscriptXOffset = 0;
  int ySuperscriptYOffset = 0;

  // Strikeout metrics
  int yStrikeoutSize = 0;
  int yStrikeoutPosition = 0;

  // Font classification
  int sFamilyClass = 0;

  // PANOSE classification (10 bytes)
  Uint8List panose = Uint8List(10);

  // Unicode ranges (128 bits total)
  int ulUnicodeRange1 = 0; // Bits 0-31
  int ulUnicodeRange2 = 0; // Bits 32-63
  int ulUnicodeRange3 = 0; // Bits 64-95
  int ulUnicodeRange4 = 0; // Bits 96-127

  // Vendor ID (4 character tag)
  int achVendID = 0;

  // Selection flags and character indices
  int fsSelection = 0;
  int usFirstCharIndex = 0;
  int usLastCharIndex = 0;

  // Typography metrics
  int sTypoAscender = 0;
  int sTypoDescender = 0;
  int sTypoLineGap = 0;

  // Windows metrics
  int usWinAscent = 0;
  int usWinDescent = 0;

  // Code page ranges (version 1+)
  int ulCodePageRange1 = 0; // Bits 0-31
  int ulCodePageRange2 = 0; // Bits 32-63

  // Version 2+ fields
  int sxHeight = 0;
  int sCapHeight = 0;
  int usDefaultChar = 0;
  int usBreakChar = 0;
  int usMaxContext = 0;

  // Version 5+ fields
  int usLowerOpticalPointSize = 0;
  int usUpperOpticalPointSize = 0;

  OS2Table();

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    version = reader.readUInt16();

    switch (version) {
      case 0:
        _readVersion0(reader);
        break;
      case 1:
        _readVersion1(reader);
        break;
      case 2:
        _readVersion2(reader);
        break;
      case 3:
        _readVersion3(reader);
        break;
      case 4:
        _readVersion4(reader);
        break;
      case 5:
        _readVersion5(reader);
        break;
      default:
        throw FormatException('Unsupported OS/2 table version: $version');
    }
  }

  /// Read common fields present in all versions
  void _readCommonFields(ByteOrderSwappingBinaryReader reader) {
    xAvgCharWidth = reader.readInt16();
    usWeightClass = reader.readUInt16();
    usWidthClass = reader.readUInt16();
    fsType = reader.readUInt16();

    ySubscriptXSize = reader.readInt16();
    ySubscriptYSize = reader.readInt16();
    ySubscriptXOffset = reader.readInt16();
    ySubscriptYOffset = reader.readInt16();

    ySuperscriptXSize = reader.readInt16();
    ySuperscriptYSize = reader.readInt16();
    ySuperscriptXOffset = reader.readInt16();
    ySuperscriptYOffset = reader.readInt16();

    yStrikeoutSize = reader.readInt16();
    yStrikeoutPosition = reader.readInt16();
    sFamilyClass = reader.readInt16();

    panose = reader.readBytes(10);

    ulUnicodeRange1 = reader.readUInt32();
    ulUnicodeRange2 = reader.readUInt32();
    ulUnicodeRange3 = reader.readUInt32();
    ulUnicodeRange4 = reader.readUInt32();

    achVendID = reader.readUInt32();

    fsSelection = reader.readUInt16();
    usFirstCharIndex = reader.readUInt16();
    usLastCharIndex = reader.readUInt16();

    sTypoAscender = reader.readInt16();
    sTypoDescender = reader.readInt16();
    sTypoLineGap = reader.readInt16();

    usWinAscent = reader.readUInt16();
    usWinDescent = reader.readUInt16();
  }

  void _readVersion0(ByteOrderSwappingBinaryReader reader) {
    _readCommonFields(reader);
  }

  void _readVersion1(ByteOrderSwappingBinaryReader reader) {
    _readCommonFields(reader);
    ulCodePageRange1 = reader.readUInt32();
    ulCodePageRange2 = reader.readUInt32();
  }

  void _readVersion2(ByteOrderSwappingBinaryReader reader) {
    _readCommonFields(reader);
    ulCodePageRange1 = reader.readUInt32();
    ulCodePageRange2 = reader.readUInt32();
    sxHeight = reader.readInt16();
    sCapHeight = reader.readInt16();
    usDefaultChar = reader.readUInt16();
    usBreakChar = reader.readUInt16();
    usMaxContext = reader.readUInt16();
  }

  void _readVersion3(ByteOrderSwappingBinaryReader reader) {
    _readVersion2(reader);
  }

  void _readVersion4(ByteOrderSwappingBinaryReader reader) {
    _readVersion2(reader);
  }

  void _readVersion5(ByteOrderSwappingBinaryReader reader) {
    _readCommonFields(reader);
    ulCodePageRange1 = reader.readUInt32();
    ulCodePageRange2 = reader.readUInt32();
    sxHeight = reader.readInt16();
    sCapHeight = reader.readInt16();
    usDefaultChar = reader.readUInt16();
    usBreakChar = reader.readUInt16();
    usMaxContext = reader.readUInt16();
    usLowerOpticalPointSize = reader.readUInt16();
    usUpperOpticalPointSize = reader.readUInt16();
  }

  @override
  String toString() => 'OS2Table(version: $version, weight: $usWeightClass)';
}
