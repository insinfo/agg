// Copyright © 2017-present Sam Hocevar <sam@hocevar.net>, WinterDev
// Ported to Dart by insinfo, 2025

import 'dart:typed_data';
import '../../io/byte_order_swapping_reader.dart';
import 'table_entry.dart';
import 'utils.dart';

class CPAL extends TableEntry {
  @override
  String get name => 'CPAL';

  late Uint8List _colorBGRABuffer;
  late List<int> palettes;
  int colorCount = 0;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    final offset = reader.position;

    reader.readUInt16(); // version
    reader.readUInt16(); // entryCount (unused)
    final paletteCount = reader.readUInt16();
    colorCount = reader.readUInt16();
    final colorsOffset = reader.readUInt32();

    palettes = Utils.readUInt16Array(reader, paletteCount);

    reader.seek(offset + colorsOffset);
    _colorBGRABuffer = reader.readBytes(4 * colorCount);
  }

  /// Get color at [colorIndex].
  /// Returns a list [r, g, b, a].
  List<int> getColor(int colorIndex) {
    // Each color record has BGRA values. The color space for these values is sRGB.
    // Type    Name    Description
    // uint8   blue    Blue value(B0).
    // uint8   green   Green value(B1).
    // uint8   red     Red value(B2).
    // uint8   alpha   Alpha value(B3).

    final startAt = colorIndex * 4;
    final b = _colorBGRABuffer[startAt];
    final g = _colorBGRABuffer[startAt + 1];
    final r = _colorBGRABuffer[startAt + 2];
    final a = _colorBGRABuffer[startAt + 3];
    return [r, g, b, a];
  }
}
