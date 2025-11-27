import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:agg/src/typography/io/byte_order_swapping_reader.dart';
import 'package:agg/src/typography/openfont/tables/colr.dart';

void main() {
  group('COLR Table', () {
    test('creates COLR table', () {
      final colr = COLR();
      expect(colr.name, equals('COLR'));
    });

    test('reads COLR table', () {
      final builder = BytesBuilder();

      // Header
      builder.add(_encodeUInt16(0)); // Version
      builder.add(_encodeUInt16(1)); // NumBaseGlyphRecords
      builder.add(_encodeUInt32(14)); // BaseGlyphRecordsOffset
      builder.add(_encodeUInt32(20)); // LayerRecordsOffset
      builder.add(_encodeUInt16(2)); // NumLayerRecords

      // BaseGlyphRecords (at 14)
      builder.add(_encodeUInt16(10)); // GlyphID
      builder.add(_encodeUInt16(0)); // FirstLayerIndex
      builder.add(_encodeUInt16(2)); // NumLayers

      // LayerRecords (at 20)
      // Layer 0
      builder.add(_encodeUInt16(100)); // GlyphID
      builder.add(_encodeUInt16(1)); // PaletteIndex
      // Layer 1
      builder.add(_encodeUInt16(101)); // GlyphID
      builder.add(_encodeUInt16(2)); // PaletteIndex

      final data = Uint8List.fromList(builder.toBytes());
      final reader = ByteOrderSwappingBinaryReader(data);

      final colr = COLR();
      colr.readContentFrom(reader);

      expect(colr.layerIndices.containsKey(10), isTrue);
      expect(colr.layerIndices[10], equals(0));
      expect(colr.layerCounts[10], equals(2));

      expect(colr.glyphLayers.length, equals(2));
      expect(colr.glyphLayers[0], equals(100));
      expect(colr.glyphLayers[1], equals(101));

      expect(colr.glyphPalettes.length, equals(2));
      expect(colr.glyphPalettes[0], equals(1));
      expect(colr.glyphPalettes[1], equals(2));
    });
  });
}

List<int> _encodeUInt16(int value) {
  return [(value >> 8) & 0xFF, value & 0xFF];
}

List<int> _encodeUInt32(int value) {
  return [
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF
  ];
}
