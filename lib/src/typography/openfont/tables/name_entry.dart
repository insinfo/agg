// Apache2, 2017-present, WinterDev
// Apache2, 2014-2016, Samuel Carlsson, WinterDev
// Ported to Dart by insinfo

import 'dart:convert';
import 'dart:typed_data';
import '../../../typography/io/byte_order_swapping_reader.dart';
import '../../../typography/openfont/tables/table_entry.dart';

/// Name ID enumeration
/// Identifies the type of name stored
enum NameIdKind {
  copyRightNotice(0),
  fontFamilyName(1), // Font Family name
  fontSubfamilyName(2), // Font Subfamily name (Regular, Bold, etc.)
  uniqueFontIden(3), // Unique font identifier
  fullFontName(4), // Full font name
  versionString(5), // Version string
  postScriptName(6), // PostScript name
  trademark(7),
  manufacturerName(8),
  designer(9),
  description(10),
  urlVendor(11),
  urlDesigner(12),
  licenseDescription(13),
  licenseInfoUrl(14),
  reserved(15),
  typographicFamilyName(16), // Typographic Family name
  typographyicSubfamilyName(17), // Typographic Subfamily name
  compatibleFull(18),
  sampleText(19),
  postScriptCIDFindfontName(20),
  wwsFamilyName(21),
  wwsSubfamilyName(22),
  lightBackgroundPalette(23),
  darkBackgroundPalette(24),
  variationsPostScriptNamePrefix(25);

  final int value;
  const NameIdKind(this.value);

  static NameIdKind? fromValue(int value) {
    for (final kind in NameIdKind.values) {
      if (kind.value == value) return kind;
    }
    return null;
  }
}

/// Name Record structure
class _NameRecord {
  final int platformID;
  final int encodingID;
  final int languageID;
  final int nameID;
  final int stringLength;
  final int stringOffset;

  _NameRecord({
    required this.platformID,
    required this.encodingID,
    required this.languageID,
    required this.nameID,
    required this.stringLength,
    required this.stringOffset,
  });
}

/// Name Table ('name')
/// Contains strings for font names, copyright, version, etc.
class NameEntry extends TableEntry {
  static const String tableName = 'name';

  @override
  String get name => tableName;

  // Font names
  String fontName = '';
  String fontSubFamily = '';
  String uniqueFontIden = '';
  String fullFontName = '';
  String versionString = '';
  String postScriptName = '';
  String postScriptCIDFindfontName = '';
  String typographicFamilyName = '';
  String typographyicSubfamilyName = '';

  NameEntry();

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    reader.readUInt16(); // Format selector (0 or 1)
    final nameCount = reader.readUInt16(); // Number of name records
    final storageOffset = reader.readUInt16(); // Offset to start of string storage

    final tableOffset = header?.offset ?? 0;

    // Read all name records
    for (var i = 0; i < nameCount; i++) {
      final record = _NameRecord(
        platformID: reader.readUInt16(),
        encodingID: reader.readUInt16(),
        languageID: reader.readUInt16(),
        nameID: reader.readUInt16(),
        stringLength: reader.readUInt16(),
        stringOffset: reader.readUInt16(),
      );

      // Save current position
      final currentPos = reader.position;

      // Seek to string data
      reader.seek(tableOffset + record.stringOffset + storageOffset);

      // Read string bytes
      final stringBytes = reader.readBytes(record.stringLength);

      // Decode string based on encoding
      String decodedString;
      if (record.encodingID == 3 || record.encodingID == 1) {
        // Big-endian Unicode (UTF-16BE)
        decodedString = _decodeUtf16BE(stringBytes);
      } else {
        // UTF-8 or ASCII
        decodedString = utf8.decode(stringBytes, allowMalformed: true);
      }

      // Store string based on name ID
      final nameKind = NameIdKind.fromValue(record.nameID);
      if (nameKind != null) {
        _storeNameString(nameKind, decodedString);
      }

      // Restore position for next record
      reader.seek(currentPos);
    }
  }

  /// Decode UTF-16 Big Endian string
  String _decodeUtf16BE(Uint8List bytes) {
    if (bytes.length % 2 != 0) {
      // Odd length, pad with zero
      final padded = Uint8List(bytes.length + 1);
      padded.setRange(0, bytes.length, bytes);
      bytes = padded;
    }

    final units = <int>[];
    for (var i = 0; i < bytes.length; i += 2) {
      final high = bytes[i];
      final low = bytes[i + 1];
      units.add((high << 8) | low);
    }

    return String.fromCharCodes(units);
  }

  /// Store name string in appropriate field
  void _storeNameString(NameIdKind kind, String value) {
    switch (kind) {
      case NameIdKind.fontFamilyName:
        fontName = value;
        break;
      case NameIdKind.fontSubfamilyName:
        fontSubFamily = value;
        break;
      case NameIdKind.uniqueFontIden:
        uniqueFontIden = value;
        break;
      case NameIdKind.fullFontName:
        fullFontName = value;
        break;
      case NameIdKind.versionString:
        versionString = value;
        break;
      case NameIdKind.postScriptName:
        postScriptName = value;
        break;
      case NameIdKind.postScriptCIDFindfontName:
        postScriptCIDFindfontName = value;
        break;
      case NameIdKind.typographicFamilyName:
        typographicFamilyName = value;
        break;
      case NameIdKind.typographyicSubfamilyName:
        typographyicSubfamilyName = value;
        break;
      default:
        // Ignore other name IDs
        break;
    }
  }

  @override
  String toString() => 'NameEntry(font: $fontName, subfamily: $fontSubFamily)';
}
