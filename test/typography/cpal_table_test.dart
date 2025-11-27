import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:agg/src/typography/io/byte_order_swapping_reader.dart';
import 'package:agg/src/typography/openfont/tables/cpal.dart';

void main() {
  group('CPAL Table', () {
    test('creates CPAL table', () {
      final cpal = CPAL();
      expect(cpal.name, equals('CPAL'));
    });

    test('reads CPAL table', () {
      final builder = BytesBuilder();

      // Header
      builder.add(_encodeUInt16(0)); // Version
      builder.add(_encodeUInt16(2)); // NumPaletteEntries (unused in logic but part of spec)
      builder.add(_encodeUInt16(1)); // NumPalettes
      builder.add(_encodeUInt16(2)); // NumColorRecords
      builder.add(_encodeUInt32(14)); // ColorRecordsArrayOffset (12 + 2)

      // ColorRecordIndices (1 palette)
      builder.add(_encodeUInt16(0)); // Index of first color record for palette 0

      // ColorRecords (2 records, BGRA)
      // Color 0: Blue (B=255, G=0, R=0, A=255)
      builder.addByte(255);
      builder.addByte(0);
      builder.addByte(0);
      builder.addByte(255);

      // Color 1: Green (B=0, G=255, R=0, A=255)
      builder.addByte(0);
      builder.addByte(255);
      builder.addByte(0);
      builder.addByte(255);

      final data = Uint8List.fromList(builder.toBytes());
      final reader = ByteOrderSwappingBinaryReader(data);

      final cpal = CPAL();
      cpal.readContentFrom(reader);

      expect(cpal.colorCount, equals(2));
      expect(cpal.palettes.length, equals(1));
      expect(cpal.palettes[0], equals(0));

      final color0 = cpal.getColor(0);
      expect(color0, equals([0, 0, 255, 255])); // RGBA

      final color1 = cpal.getColor(1);
      expect(color1, equals([0, 255, 0, 255])); // RGBA
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
