// Apache2, 2017-present, WinterDev
// Apache2, 2014-2016, Samuel Carlsson, WinterDev
// Ported to Dart by insinfo

import '../../../typography/io/byte_order_swapping_reader.dart';
import '../../../typography/openfont/tables/table_entry.dart';
import '../../../typography/openfont/tables/utils.dart';

/// Character to Glyph Index Mapping Table ('cmap')
/// Defines the mapping of character codes to glyph index values
class Cmap extends TableEntry {
  static const String tableName = 'cmap';

  @override
  String get name => tableName;

  final List<CharacterMap> _charMaps = [];
  final Map<int, int> _codepointToGlyphs = {};

  Cmap();

  /// Find glyph index from given codepoint
  /// Returns glyph index (0 for unmapped characters)
  int getGlyphIndex(int codepoint, int nextCodepoint, {bool? skipNextCodepoint}) {
    // Character codes that do not correspond to any glyph should map to 0
    skipNextCodepoint = false;

    if (!_codepointToGlyphs.containsKey(codepoint)) {
      var found = 0;

      for (final cmap in _charMaps) {
        if (found == 0) {
          found = cmap.getGlyphIndex(codepoint);
        } else if (cmap.platformId == 3 && cmap.encodingId == 1) {
          // When building a Unicode font for Windows,
          // the platform ID should be 3 and the encoding ID should be 1
          final gid = cmap.getGlyphIndex(codepoint);
          if (gid != 0) {
            found = gid;
          }
        }
      }

      _codepointToGlyphs[codepoint] = found;
    }

    return _codepointToGlyphs[codepoint]!;
  }

  /// Collect all Unicode codepoints available in this font
  void collectUnicode(List<int> unicodes) {
    for (final cmap in _charMaps) {
      cmap.collectUnicode(unicodes);
    }
  }

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    final beginAt = reader.position;

    reader.readUInt16(); // version (0)
    final tableCount = reader.readUInt16();

    final platformIds = <int>[];
    final encodingIds = <int>[];
    final offsets = <int>[];

    for (var i = 0; i < tableCount; i++) {
      platformIds.add(reader.readUInt16());
      encodingIds.add(reader.readUInt16());
      offsets.add(reader.readUInt32());
    }

    for (var i = 0; i < tableCount; i++) {
      reader.seek(beginAt + offsets[i]);
      final cmap = _readCharacterMap(reader);
      cmap.platformId = platformIds[i];
      cmap.encodingId = encodingIds[i];
      _charMaps.add(cmap);
    }
  }

  CharacterMap _readCharacterMap(ByteOrderSwappingBinaryReader reader) {
    final format = reader.readUInt16();

    switch (format) {
      case 0:
        return _readFormat0(reader);
      case 4:
        return _readFormat4(reader);
      case 12:
        return _readFormat12(reader);
      default:
        Utils.warnUnimplemented('cmap format $format not supported');
        return NullCharMap();
    }
  }

  CharacterMap _readFormat0(ByteOrderSwappingBinaryReader reader) {
    reader.readUInt16(); // length
    reader.readUInt16(); // language

    final glyphIds = reader.readBytes(256);
    final glyphIdArray = List<int>.generate(256, (i) => glyphIds[i]);

    // Convert to format 4 structure
    return CharMapFormat4(
      startCode: [0, 0xFFFF],
      endCode: [255, 0xFFFF],
      idDelta: [0, 1],
      idRangeOffset: [4, 0],
      glyphIdArray: glyphIdArray,
    );
  }

  CharMapFormat4 _readFormat4(ByteOrderSwappingBinaryReader reader) {
    final length = reader.readUInt16();
    // length includes the format field (2 bytes) already read in _readCharacterMap
    // and the length field (2 bytes) we just read
    final tableStart = reader.position - 4; // -4 for format + length already read
    final tableEnd = tableStart + length;

    reader.readUInt16(); // language

    final segCountX2 = reader.readUInt16();
    reader.readUInt16(); // searchRange
    reader.readUInt16(); // entrySelector
    reader.readUInt16(); // rangeShift

    final segCount = segCountX2 ~/ 2;

    final endCode = Utils.readUInt16Array(reader, segCount);
    reader.readUInt16(); // reserved (always 0)
    final startCode = Utils.readUInt16Array(reader, segCount);
    final idDelta = Utils.readUInt16Array(reader, segCount);
    final idRangeOffset = Utils.readUInt16Array(reader, segCount);

    final remainingLen = tableEnd - reader.position;
    final glyphIdArrayLen = remainingLen ~/ 2;
    final glyphIdArray = glyphIdArrayLen > 0 
        ? Utils.readUInt16Array(reader, glyphIdArrayLen) 
        : <int>[];

    return CharMapFormat4(
      startCode: startCode,
      endCode: endCode,
      idDelta: idDelta,
      idRangeOffset: idRangeOffset,
      glyphIdArray: glyphIdArray,
    );
  }

  CharMapFormat12 _readFormat12(ByteOrderSwappingBinaryReader reader) {
    reader.readUInt16(); // reserved
    reader.readUInt32(); // length
    reader.readUInt32(); // language
    final numGroups = reader.readUInt32();

    final groups = <SequentialMapGroup>[];
    for (var i = 0; i < numGroups; i++) {
      groups.add(SequentialMapGroup(
        startCharCode: reader.readUInt32(),
        endCharCode: reader.readUInt32(),
        startGlyphId: reader.readUInt32(),
      ));
    }

    return CharMapFormat12(groups);
  }

  @override
  String toString() => 'Cmap(maps: ${_charMaps.length})';
}

/// Base class for character maps
abstract class CharacterMap {
  int platformId = 0;
  int encodingId = 0;

  int getGlyphIndex(int codepoint);
  void collectUnicode(List<int> unicodes) {}
}

/// Null character map (for unsupported formats)
class NullCharMap extends CharacterMap {
  @override
  int getGlyphIndex(int codepoint) => 0;
}

/// Character Map Format 4 (most common format)
class CharMapFormat4 extends CharacterMap {
  final List<int> startCode;
  final List<int> endCode;
  final List<int> idDelta;
  final List<int> idRangeOffset;
  final List<int> glyphIdArray;

  CharMapFormat4({
    required this.startCode,
    required this.endCode,
    required this.idDelta,
    required this.idRangeOffset,
    required this.glyphIdArray,
  });

  @override
  int getGlyphIndex(int codepoint) {
    // Binary search for the segment
    for (var i = 0; i < startCode.length; i++) {
      if (codepoint >= startCode[i] && codepoint <= endCode[i]) {
        if (idRangeOffset[i] == 0) {
          // Simple delta mapping
          return (codepoint + idDelta[i]) & 0xFFFF;
        } else {
          // Index into glyphIdArray
          final offset = idRangeOffset[i] ~/ 2 + (codepoint - startCode[i]) - (startCode.length - i);
          if (offset >= 0 && offset < glyphIdArray.length) {
            final glyphId = glyphIdArray[offset];
            if (glyphId != 0) {
              return (glyphId + idDelta[i]) & 0xFFFF;
            }
          }
        }
        return 0;
      }
    }
    return 0;
  }

  @override
  void collectUnicode(List<int> unicodes) {
    for (var i = 0; i < startCode.length; i++) {
      for (var code = startCode[i]; code <= endCode[i]; code++) {
        if (code != 0xFFFF) {
          final glyphId = getGlyphIndex(code);
          if (glyphId != 0) {
            unicodes.add(code);
          }
        }
      }
    }
  }
}

/// Sequential Map Group for Format 12
class SequentialMapGroup {
  final int startCharCode;
  final int endCharCode;
  final int startGlyphId;

  SequentialMapGroup({
    required this.startCharCode,
    required this.endCharCode,
    required this.startGlyphId,
  });
}

/// Character Map Format 12 (for Unicode supplementary characters)
class CharMapFormat12 extends CharacterMap {
  final List<SequentialMapGroup> groups;

  CharMapFormat12(this.groups);

  @override
  int getGlyphIndex(int codepoint) {
    for (final group in groups) {
      if (codepoint >= group.startCharCode && codepoint <= group.endCharCode) {
        return group.startGlyphId + (codepoint - group.startCharCode);
      }
    }
    return 0;
  }

  @override
  void collectUnicode(List<int> unicodes) {
    for (final group in groups) {
      for (var code = group.startCharCode; code <= group.endCharCode; code++) {
        unicodes.add(code);
      }
    }
  }
}
