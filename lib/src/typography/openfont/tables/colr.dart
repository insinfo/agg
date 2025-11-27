// Copyright © 2017-present Sam Hocevar <sam@hocevar.net>
// Ported to Dart by insinfo, 2025

import '../../io/byte_order_swapping_reader.dart';
import 'table_entry.dart';

class COLR extends TableEntry {
  @override
  String get name => 'COLR';

  late List<int> glyphLayers;
  late List<int> glyphPalettes;
  final Map<int, int> layerIndices = {};
  final Map<int, int> layerCounts = {};

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    final offset = reader.position;

    reader.readUInt16(); // version
    final glyphCount = reader.readUInt16();
    final glyphsOffset = reader.readUInt32();
    final layersOffset = reader.readUInt32();
    final layersCount = reader.readUInt16();

    glyphLayers = List<int>.filled(layersCount, 0);
    glyphPalettes = List<int>.filled(layersCount, 0);

    reader.seek(offset + glyphsOffset);
    for (var i = 0; i < glyphCount; i++) {
      final gid = reader.readUInt16();
      layerIndices[gid] = reader.readUInt16();
      layerCounts[gid] = reader.readUInt16();
    }

    reader.seek(offset + layersOffset);
    for (var i = 0; i < layersCount; i++) {
      glyphLayers[i] = reader.readUInt16();
      glyphPalettes[i] = reader.readUInt16();
    }
  }
}
