import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:agg/src/typography/io/byte_order_swapping_reader.dart';
import 'package:agg/src/typography/openfont/tables/base.dart';

void main() {
  group('BASE Table', () {
    test('creates BASE table', () {
      final base = BASE();
      expect(base.name, equals('BASE'));
    });

    test('reads BASE table version 1.0', () {
      // Construct a minimal BASE table
      final builder = BytesBuilder();
      
      // Header 1.0
      builder.add(_encodeUInt16(1)); // major
      builder.add(_encodeUInt16(0)); // minor
      builder.add(_encodeUInt16(8)); // horizAxisOffset (points to after header)
      builder.add(_encodeUInt16(0)); // vertAxisOffset (null)

      // Horizontal Axis Table (at offset 8)
      // baseTagListOffset (null)
      builder.add(_encodeUInt16(0)); 
      // baseScriptListOffset (points to after axis table header)
      builder.add(_encodeUInt16(4)); 

      // BaseScriptList Table (at offset 8 + 4 = 12)
      builder.add(_encodeUInt16(1)); // baseScriptCount
      
      // BaseScriptRecord 1
      builder.add(_encodeTag('latn')); // tag
      builder.add(_encodeUInt16(8)); // offset (relative to BaseScriptList start: 2 + 6 = 8)

      // BaseScript Table (at offset 12 + 8 = 20)
      // baseValuesOffset (null)
      builder.add(_encodeUInt16(0));
      // defaultMinMaxOffset (null)
      builder.add(_encodeUInt16(0));
      // baseLangSysCount
      builder.add(_encodeUInt16(0));

      final data = Uint8List.fromList(builder.toBytes());
      final reader = ByteOrderSwappingBinaryReader(data);
      
      final base = BASE();
      base.readContentFrom(reader);

      expect(base.horizontalAxis, isNotNull);
      expect(base.verticalAxis, isNull);
      expect(base.horizontalAxis!.isVerticalAxis, isFalse);
      
      final scripts = base.horizontalAxis!.baseScripts;
      expect(scripts, isNotNull);
      expect(scripts!.length, equals(1));
      expect(scripts[0].scriptIdenTag, equals('latn'));
    });

    test('reads BaseValues and BaseCoord', () {
      final builder = BytesBuilder();
      
      // Header
      builder.add(_encodeUInt16(1));
      builder.add(_encodeUInt16(0));
      builder.add(_encodeUInt16(8)); // horiz
      builder.add(_encodeUInt16(0)); // vert

      // Axis Table
      builder.add(_encodeUInt16(0)); // tag list
      builder.add(_encodeUInt16(4)); // script list

      // Script List
      builder.add(_encodeUInt16(1));
      builder.add(_encodeTag('latn'));
      builder.add(_encodeUInt16(8));

      // BaseScript Table
      builder.add(_encodeUInt16(6)); // baseValuesOffset (relative to BaseScript start)
      builder.add(_encodeUInt16(0)); // minMax
      builder.add(_encodeUInt16(0)); // langSys

      // BaseValues Table (at offset 6 from BaseScript start)
      builder.add(_encodeUInt16(0)); // defaultBaselineIndex
      builder.add(_encodeUInt16(1)); // baseCoordCount
      builder.add(_encodeUInt16(6)); // baseCoordOffset (relative to BaseValues start)

      // BaseCoord Table (at offset 6 from BaseValues start)
      builder.add(_encodeUInt16(1)); // format 1
      builder.add(_encodeInt16(-200)); // coord

      final data = Uint8List.fromList(builder.toBytes());
      final reader = ByteOrderSwappingBinaryReader(data);
      
      final base = BASE();
      base.readContentFrom(reader);

      final script = base.horizontalAxis!.baseScripts![0];
      expect(script.baseValues, isNotNull);
      expect(script.baseValues!.defaultBaseLineIndex, equals(0));
      expect(script.baseValues!.baseCoords.length, equals(1));
      
      final coord = script.baseValues!.baseCoords[0];
      expect(coord.baseCoordFormat, equals(1));
      expect(coord.coord, equals(-200));
    });
  });
}

List<int> _encodeUInt16(int value) {
  return [(value >> 8) & 0xFF, value & 0xFF];
}

List<int> _encodeInt16(int value) {
  return [(value >> 8) & 0xFF, value & 0xFF];
}

List<int> _encodeTag(String tag) {
  final bytes = <int>[];
  for (final unit in tag.codeUnits) {
    bytes.add(unit);
  }
  return bytes;
}
