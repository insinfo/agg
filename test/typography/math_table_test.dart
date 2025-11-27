import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:agg/src/typography/io/byte_order_swapping_reader.dart';
import 'package:agg/src/typography/openfont/tables/math.dart';

void main() {
  group('MATH Table', () {
    test('creates MATH table', () {
      final math = MathTable();
      expect(math.name, equals('MATH'));
    });

    test('reads MATH table with Constants and Variants', () {
      final builder = BytesBuilder();

      // Header
      builder.add(_encodeUInt16(1)); // Major
      builder.add(_encodeUInt16(0)); // Minor
      builder.add(_encodeUInt16(10)); // MathConstants Offset
      builder.add(_encodeUInt16(234)); // MathGlyphInfo Offset (224 + 10)
      builder.add(_encodeUInt16(224)); // MathVariants Offset (10 + 214)

      // MathConstants (at 10)
      builder.add(_encodeInt16(80)); // ScriptPercentScaleDown
      builder.add(_encodeInt16(60)); // ScriptScriptPercentScaleDown
      builder.add(_encodeUInt16(100)); // DelimitedSubFormulaMinHeight
      builder.add(_encodeUInt16(200)); // DisplayOperatorMinHeight

      // 51 MathValueRecords
      for (var i = 0; i < 51; i++) {
        builder.add(_encodeInt16(i + 1)); // Value
        builder.add(_encodeUInt16(0)); // DeviceTable Offset
      }

      builder.add(_encodeInt16(50)); // RadicalDegreeBottomRaisePercent

      // MathVariants (at 224)
      builder.add(_encodeUInt16(123)); // MinConnectorOverlap
      builder.add(_encodeUInt16(26)); // VertGlyphCoverage Offset (relative to 224 -> 250)
      builder.add(_encodeUInt16(0)); // HorizGlyphCoverage Offset
      builder.add(_encodeUInt16(0)); // VertGlyphCount
      builder.add(_encodeUInt16(0)); // HorizGlyphCount

      // MathGlyphInfo (at 234)
      builder.add(_encodeUInt16(8)); // MathItalicsCorrectionInfo Offset (relative to 234 -> 242)
      builder.add(_encodeUInt16(12)); // MathTopAccentAttachment Offset (relative to 234 -> 246)
      builder.add(_encodeUInt16(0)); // ExtendedShapeCoverage Offset
      builder.add(_encodeUInt16(0)); // MathKernInfo Offset

      // MathItalicsCorrectionInfo (at 242)
      builder.add(_encodeUInt16(0)); // Coverage Offset
      builder.add(_encodeUInt16(0)); // ItalicsCorrectionCount

      // MathTopAccentAttachment (at 246)
      builder.add(_encodeUInt16(0)); // Coverage Offset
      builder.add(_encodeUInt16(0)); // TopAccentAttachmentCount

      // Coverage Table (at 250)
      builder.add(_encodeUInt16(1)); // Format 1
      builder.add(_encodeUInt16(0)); // GlyphCount

      final data = Uint8List.fromList(builder.toBytes());
      final reader = ByteOrderSwappingBinaryReader(data);

      final math = MathTable();
      math.readContentFrom(reader);

      // Check Constants
      expect(math.mathConstTable.scriptPercentScaleDown, equals(80));
      expect(math.mathConstTable.scriptScriptPercentScaleDown, equals(60));
      expect(math.mathConstTable.delimitedSubFormulaMinHeight, equals(100));
      expect(math.mathConstTable.displayOperatorMinHeight, equals(200));
      
      // Check first MathValueRecord (MathLeading)
      expect(math.mathConstTable.mathLeading.value, equals(1));
      
      // Check last MathValueRecord (RadicalKernAfterDegree) - index 50 (value 51)
      expect(math.mathConstTable.radicalKernAfterDegree.value, equals(51));

      expect(math.mathConstTable.radicalDegreeBottomRaisePercent, equals(50));

      // Check Variants
      expect(math.mathConstTable.minConnectorOverlap, equals(123));
    });
  });
}

List<int> _encodeUInt16(int value) {
  return [(value >> 8) & 0xFF, value & 0xFF];
}

List<int> _encodeInt16(int value) {
  return [(value >> 8) & 0xFF, value & 0xFF];
}
