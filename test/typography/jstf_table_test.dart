import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:agg/src/typography/io/byte_order_swapping_reader.dart';
import 'package:agg/src/typography/openfont/tables/jstf.dart';

void main() {
  group('JSTF Table', () {
    test('creates JSTF table', () {
      final jstf = JSTF();
      expect(jstf.name, equals('JSTF'));
    });

    test('reads JSTF table', () {
      final builder = BytesBuilder();
      
      // JSTF Header
      builder.add(_encodeUInt16(1)); // major
      builder.add(_encodeUInt16(0)); // minor
      builder.add(_encodeUInt16(1)); // scriptCount
      
      // JstfScriptRecord
      builder.add(_encodeTag('latn'));
      builder.add(_encodeUInt16(12)); // offset (relative to start of JSTF)
      // Header size: 2+2+2 = 6. Record size: 4+2 = 6. Total 12.
      // So JstfScriptTable starts at 12.

      // JstfScriptTable (at 12)
      builder.add(_encodeUInt16(0)); // extenderGlyphOffset
      builder.add(_encodeUInt16(6)); // defJstfLangSysOffset (relative to JstfScriptTable start)
      builder.add(_encodeUInt16(0)); // jstfLangSysCount
      // Size: 6 bytes.
      // JstfLangSysTable starts at 12 + 6 = 18.

      // JstfLangSysTable (at 18)
      builder.add(_encodeUInt16(1)); // priorityCount
      builder.add(_encodeUInt16(4)); // priorityOffset (relative to JstfLangSysTable start)
      // Size: 4 bytes.
      // JstfPriority starts at 18 + 4 = 22.

      // JstfPriority (at 22)
      builder.add(_encodeUInt16(1)); // shrinkageEnableGSUB
      builder.add(_encodeUInt16(0));
      builder.add(_encodeUInt16(0));
      builder.add(_encodeUInt16(0));
      builder.add(_encodeUInt16(0));
      builder.add(_encodeUInt16(0));
      builder.add(_encodeUInt16(0));
      builder.add(_encodeUInt16(0));
      builder.add(_encodeUInt16(0));
      builder.add(_encodeUInt16(0));

      final data = Uint8List.fromList(builder.toBytes());
      final reader = ByteOrderSwappingBinaryReader(data);
      
      final jstf = JSTF();
      jstf.readContentFrom(reader);

      expect(jstf.jstfScriptTables, isNotNull);
      expect(jstf.jstfScriptTables!.length, equals(1));
      
      final script = jstf.jstfScriptTables![0];
      expect(script.scriptTag, equals('latn'));
      expect(script.defaultLangSys, isNotNull);
      
      final langSys = script.defaultLangSys!;
      expect(langSys.jstfPriority.length, equals(1));
      
      final priority = langSys.jstfPriority[0];
      expect(priority.shrinkageEnableGSUB, equals(1));
    });
  });
}

List<int> _encodeUInt16(int value) {
  return [(value >> 8) & 0xFF, value & 0xFF];
}

List<int> _encodeTag(String tag) {
  final bytes = <int>[];
  for (final unit in tag.codeUnits) {
    bytes.add(unit);
  }
  return bytes;
}
