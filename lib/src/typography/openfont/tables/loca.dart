// MIT, 2018-present, WinterDev
// Apache2, 2014-2016, Samuel Carlsson, WinterDev
// Ported to Dart by insinfo, 2025
// https://www.microsoft.com/typography/otspec/loca.htm

import '../../io/byte_order_swapping_reader.dart';
import 'table_entry.dart';

/// loca - Index to Location
/// 
/// The indexToLoc table stores the offsets to the locations of the glyphs
/// in the font, relative to the beginning of the glyphData table.
/// In order to compute the length of the last glyph element,
/// there is an extra entry after the last valid index.
/// 
/// By definition, index zero points to the "missing character,"
/// which is the character that appears if a character is not found in the font.
/// The missing character is commonly represented by a blank box or a space.
/// If the font does not contain an outline for the missing character,
/// then the first and second offsets should have the same value.
/// This also applies to any other characters without an outline, such as the space character.
/// If a glyph has no outline, then loca[n] = loca[n+1].
/// 
/// There are two versions of this table, the short and the long.
/// The version is specified in the indexToLocFormat entry in the 'head' table.
class GlyphLocations extends TableEntry {
  static const String tableName = 'loca';

  List<int> _offsets = [];
  final bool isLongVersion;

  GlyphLocations(int glyphCount, this.isLongVersion) {
    _offsets = List<int>.filled(glyphCount + 1, 0);
  }

  @override
  String get name => tableName;

  /// The offsets to each glyph
  List<int> get offsets => _offsets;

  /// The number of glyphs (excludes the extra entry)
  int get glyphCount => _offsets.length - 1;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    /// Short version:
    /// Type: USHORT offsets[n]
    /// The actual local offset divided by 2 is stored.
    /// The value of n is numGlyphs + 1.
    /// 
    /// Long version:
    /// Type: ULONG offsets[n]
    /// The actual local offset is stored.
    /// The value of n is numGlyphs + 1.
    /// 
    /// Note that the local offsets should be long-aligned, i.e., multiples of 4.
    /// Offsets which are not long-aligned may seriously degrade performance.

    final lim = glyphCount + 1;
    _offsets = List<int>.filled(lim, 0);

    if (isLongVersion) {
      // Long version - 32-bit offsets
      for (var i = 0; i < lim; i++) {
        _offsets[i] = reader.readUInt32();
      }
    } else {
      // Short version - 16-bit offsets multiplied by 2
      for (var i = 0; i < lim; i++) {
        _offsets[i] = reader.readUInt16() << 1; // = * 2
      }
    }
  }

  @override
  String toString() {
    return 'GlyphLocations(glyphCount: $glyphCount, '
        'isLongVersion: $isLongVersion)';
  }
}
