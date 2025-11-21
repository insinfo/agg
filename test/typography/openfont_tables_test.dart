// Test for Typography OpenFont Tables
// Ported to Dart by insinfo

import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:agg/src/typography/io/byte_order_swapping_reader.dart';
import 'package:agg/src/typography/openfont/glyph.dart';
import 'package:agg/src/typography/openfont/typeface.dart';
import 'package:agg/src/typography/openfont/tables/head.dart';
import 'package:agg/src/typography/openfont/tables/maxp.dart';
import 'package:agg/src/typography/openfont/tables/hhea.dart';
import 'package:agg/src/typography/openfont/tables/os2.dart';
import 'package:agg/src/typography/openfont/tables/hmtx.dart';
import 'package:agg/src/typography/openfont/tables/name_entry.dart';
import 'package:agg/src/typography/openfont/tables/cmap.dart';
import 'package:agg/src/typography/openfont/tables/loca.dart';
import 'package:agg/src/typography/openfont/tables/table_entry.dart';
import 'package:agg/src/typography/openfont/tables/utils.dart';
import 'package:agg/src/typography/openfont/tables/gdef.dart';

void main() {
  group('ByteOrderSwappingBinaryReader', () {
    test('reads big-endian uint16', () {
      final data = Uint8List.fromList([0x12, 0x34]);
      final reader = ByteOrderSwappingBinaryReader(data);
      expect(reader.readUInt16(), equals(0x1234));
    });

    test('reads big-endian uint32', () {
      final data = Uint8List.fromList([0x12, 0x34, 0x56, 0x78]);
      final reader = ByteOrderSwappingBinaryReader(data);
      expect(reader.readUInt32(), equals(0x12345678));
    });

    test('reads multiple values', () {
      final data = Uint8List.fromList([
        0x00, 0x01, // uint16: 1
        0x00, 0x00, 0x00, 0x02, // uint32: 2
        0xFF, // byte: 255
      ]);
      final reader = ByteOrderSwappingBinaryReader(data);
      expect(reader.readUInt16(), equals(1));
      expect(reader.readUInt32(), equals(2));
      expect(reader.readByte(), equals(255));
    });

    test('tracks position correctly', () {
      final data = Uint8List.fromList([0, 0, 0, 0, 0, 0]);
      final reader = ByteOrderSwappingBinaryReader(data);
      expect(reader.position, equals(0));
      reader.readUInt16();
      expect(reader.position, equals(2));
      reader.readUInt32();
      expect(reader.position, equals(6));
    });

    test('can seek to position', () {
      final data = Uint8List.fromList([0x11, 0x22, 0x33, 0x44]);
      final reader = ByteOrderSwappingBinaryReader(data);
      reader.seek(2);
      expect(reader.position, equals(2));
      expect(reader.readByte(), equals(0x33));
    });
  });

  group('Utils', () {
    test('readF2Dot14 converts fixed-point correctly', () {
      // 2.14 format: 1.0 = 0x4000 (16384 in decimal)
      final data = Uint8List.fromList([0x40, 0x00]); // 1.0
      final reader = ByteOrderSwappingBinaryReader(data);
      final value = Utils.readF2Dot14(reader);
      expect(value, closeTo(1.0, 0.0001));
    });

    test('readFixed converts 16.16 format correctly', () {
      // 16.16 format: 1.0 = 0x00010000
      final data = Uint8List.fromList([0x00, 0x01, 0x00, 0x00]); // 1.0
      final reader = ByteOrderSwappingBinaryReader(data);
      final value = Utils.readFixed(reader);
      expect(value, closeTo(1.0, 0.0001));
    });

    test('tagToString converts uint32 to string', () {
      // 'head' = 0x68656164
      final tag = Utils.tagToString(0x68656164);
      expect(tag, equals('head'));
    });

    test('readUInt24 reads 3 bytes correctly', () {
      final data = Uint8List.fromList([0x12, 0x34, 0x56]);
      final reader = ByteOrderSwappingBinaryReader(data);
      final value = Utils.readUInt24(reader);
      expect(value, equals(0x123456));
    });
  });

  group('Bounds', () {
    test('creates bounds correctly', () {
      final bounds = Bounds(10, 20, 100, 200);
      expect(bounds.xMin, equals(10));
      expect(bounds.yMin, equals(20));
      expect(bounds.xMax, equals(100));
      expect(bounds.yMax, equals(200));
    });

    test('calculates width and height', () {
      final bounds = Bounds(10, 20, 100, 200);
      expect(bounds.width, equals(90));
      expect(bounds.height, equals(180));
    });

    test('reads from binary data', () {
      final data = Uint8List.fromList([
        0x00, 0x0A, // xMin: 10
        0x00, 0x14, // yMin: 20
        0x00, 0x64, // xMax: 100
        0x00, 0xC8, // yMax: 200
      ]);
      final reader = ByteOrderSwappingBinaryReader(data);
      final bounds = Bounds.read(reader);
      expect(bounds.xMin, equals(10));
      expect(bounds.yMin, equals(20));
      expect(bounds.xMax, equals(100));
      expect(bounds.yMax, equals(200));
    });
  });

  group('Head Table', () {
    test('creates head table', () {
      final head = Head();
      expect(head.name, equals('head'));
    });

    test('reads head table data', () {
      // Minimal head table data
      final data = Uint8List.fromList([
        0x00, 0x01, 0x00, 0x00, // version: 1.0
        0x00, 0x01, 0x00, 0x00, // fontRevision
        0x00, 0x00, 0x00, 0x00, // checkSumAdjustment
        0x5F, 0x0F, 0x3C, 0xF5, // magicNumber (correct)
        0x00, 0x00, // flags
        0x08, 0x00, // unitsPerEm: 2048
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // created
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, // modified
        0x00, 0x00, // xMin
        0x00, 0x00, // yMin
        0x00, 0x00, // xMax
        0x00, 0x00, // yMax
        0x00, 0x00, // macStyle
        0x00, 0x08, // lowestRecPPEM
        0x00, 0x00, // fontDirectionHint
        0x00, 0x01, // indexToLocFormat: 1 (32-bit)
        0x00, 0x00, // glyphDataFormat
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final head = Head();
      head.readContentFrom(reader);

      expect(head.version, equals(0x00010000));
      expect(head.magicNumber, equals(0x5F0F3CF5));
      expect(head.unitsPerEm, equals(2048));
      expect(head.wideGlyphLocations, isTrue);
    });

    test('throws on invalid magic number', () {
      final data = Uint8List.fromList([
        0x00, 0x01, 0x00, 0x00, // version
        0x00, 0x01, 0x00, 0x00, // fontRevision
        0x00, 0x00, 0x00, 0x00, // checkSumAdjustment
        0x00, 0x00, 0x00, 0x00, // invalid magicNumber
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final head = Head();
      
      expect(
        () => head.readContentFrom(reader),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('MaxProfile Table', () {
    test('creates maxp table', () {
      final maxp = MaxProfile();
      expect(maxp.name, equals('maxp'));
    });

    test('reads maxp table version 1.0', () {
      final data = Uint8List.fromList([
        0x00, 0x01, 0x00, 0x00, // version: 1.0
        0x01, 0x00, // glyphCount: 256
        0x00, 0x64, // maxPointsPerGlyph: 100
        0x00, 0x0A, // maxContoursPerGlyph: 10
        0x00, 0xC8, // maxPointsPerCompositeGlyph: 200
        0x00, 0x14, // maxContoursPerCompositeGlyph: 20
        0x00, 0x02, // maxZones: 2
        0x00, 0x00, // maxTwilightPoints
        0x00, 0x40, // maxStorage: 64
        0x00, 0x10, // maxFunctionDefs: 16
        0x00, 0x08, // maxInstructionDefs: 8
        0x02, 0x00, // maxStackElements: 512
        0x00, 0xFF, // maxSizeOfInstructions: 255
        0x00, 0x05, // maxComponentElements: 5
        0x00, 0x03, // maxComponentDepth: 3
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final maxp = MaxProfile();
      maxp.readContentFrom(reader);

      expect(maxp.version, equals(0x00010000));
      expect(maxp.glyphCount, equals(256));
      expect(maxp.maxPointsPerGlyph, equals(100));
      expect(maxp.maxZones, equals(2));
    });

    test('reads maxp table version 0.5 (CFF)', () {
      final data = Uint8List.fromList([
        0x00, 0x00, 0x50, 0x00, // version: 0.5
        0x01, 0x00, // glyphCount: 256
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final maxp = MaxProfile();
      maxp.readContentFrom(reader);

      expect(maxp.version, equals(0x00005000));
      expect(maxp.glyphCount, equals(256));
      // Version 0.5 doesn't have additional fields
      expect(maxp.maxPointsPerGlyph, equals(0));
    });
  });

  group('HorizontalHeader Table', () {
    test('creates hhea table', () {
      final hhea = HorizontalHeader();
      expect(hhea.name, equals('hhea'));
    });

    test('reads hhea table data', () {
      final data = Uint8List.fromList([
        0x00, 0x01, 0x00, 0x00, // version: 1.0
        0x03, 0x00, // ascent: 768
        0xFD, 0x00, // descent: -768 (as signed)
        0x00, 0x64, // lineGap: 100
        0x04, 0x00, // advancedWidthMax: 1024
        0x00, 0x00, // minLeftSideBearing: 0
        0x00, 0x00, // minRightSideBearing: 0
        0x04, 0x00, // maxXExtent: 1024
        0x00, 0x01, // caretSlopeRise: 1
        0x00, 0x00, // caretSlopeRun: 0
        0x00, 0x00, // caretOffset: 0
        0x00, 0x00, // reserved
        0x00, 0x00, // reserved
        0x00, 0x00, // reserved
        0x00, 0x00, // reserved
        0x00, 0x00, // metricDataFormat: 0
        0x01, 0x00, // horizontalMetricsCount: 256
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final hhea = HorizontalHeader();
      hhea.readContentFrom(reader);

      expect(hhea.version, equals(0x00010000));
      expect(hhea.ascent, equals(768));
      expect(hhea.lineGap, equals(100));
      expect(hhea.horizontalMetricsCount, equals(256));
    });
  });

  group('OS2Table', () {
    test('creates OS/2 table', () {
      final os2 = OS2Table();
      expect(os2.name, equals('OS/2'));
    });

    test('reads OS/2 table version 0', () {
      final data = Uint8List.fromList([
        0x00, 0x00, // version: 0
        0x02, 0x00, // xAvgCharWidth: 512
        0x01, 0x90, // usWeightClass: 400 (normal)
        0x00, 0x05, // usWidthClass: 5 (medium)
        0x00, 0x00, // fsType: 0
        // Subscript metrics
        0x02, 0x80, 0x02, 0x80, 0x00, 0x00, 0x00, 0x00,
        // Superscript metrics  
        0x02, 0x80, 0x02, 0x80, 0x00, 0x00, 0x00, 0x00,
        // Strikeout
        0x00, 0x66, 0x01, 0x2C,
        // Family class
        0x00, 0x00,
        // PANOSE (10 bytes)
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        // Unicode ranges (4 x 4 bytes)
        0x00, 0x00, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00,
        // achVendID ('NONE' as hex)
        0x4E, 0x4F, 0x4E, 0x45,
        // fsSelection
        0x00, 0x40,
        // usFirstCharIndex, usLastCharIndex
        0x00, 0x20, 0x00, 0xFF,
        // Typo metrics
        0x03, 0x00, // sTypoAscender: 768
        0xFD, 0x00, // sTypoDescender: -768
        0x00, 0x64, // sTypoLineGap: 100
        // Win metrics
        0x03, 0x00, // usWinAscent: 768
        0x03, 0x00, // usWinDescent: 768
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final os2 = OS2Table();
      os2.readContentFrom(reader);

      expect(os2.version, equals(0));
      expect(os2.xAvgCharWidth, equals(512));
      expect(os2.usWeightClass, equals(400));
      expect(os2.usWidthClass, equals(5));
      expect(os2.sTypoAscender, equals(768));
      expect(os2.sTypoDescender, equals(-768));
      expect(os2.sTypoLineGap, equals(100));
    });

    test('reads OS/2 table version 2', () {
      // Version 2 adds code page ranges and x-height/cap-height
      final data = Uint8List(100); // Placeholder
      final buffer = ByteData.view(data.buffer);
      var offset = 0;
      
      buffer.setUint16(offset, 2, Endian.big); // version
      offset += 2;
      
      // Fill common fields (simplified)
      for (var i = 0; i < 38; i++) {
        buffer.setUint16(offset, 0, Endian.big);
        offset += 2;
      }
      
      // Code page ranges
      buffer.setUint32(offset, 0x00000001, Endian.big);
      offset += 4;
      buffer.setUint32(offset, 0x00000000, Endian.big);
      offset += 4;
      
      // x-height, cap-height
      buffer.setInt16(offset, 500, Endian.big);
      offset += 2;
      buffer.setInt16(offset, 700, Endian.big);
      offset += 2;
      
      // Default char, break char, max context
      buffer.setUint16(offset, 0, Endian.big);
      offset += 2;
      buffer.setUint16(offset, 32, Endian.big);
      offset += 2;
      buffer.setUint16(offset, 2, Endian.big);

      final reader = ByteOrderSwappingBinaryReader(data);
      final os2 = OS2Table();
      os2.readContentFrom(reader);

      expect(os2.version, equals(2));
      expect(os2.sxHeight, equals(500));
      expect(os2.sCapHeight, equals(700));
      expect(os2.usBreakChar, equals(32));
    });

    test('throws on unsupported version', () {
      final data = Uint8List.fromList([
        0x00, 0x06, // version: 6 (unsupported)
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final os2 = OS2Table();
      
      expect(
        () => os2.readContentFrom(reader),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('HorizontalMetrics Table', () {
    test('creates hmtx table', () {
      final hmtx = HorizontalMetrics(3, 5);
      expect(hmtx.name, equals('hmtx'));
    });

    test('reads proportional font metrics', () {
      // 3 hMetrics (full entries), 2 additional glyphs (lsb only)
      final data = Uint8List.fromList([
        // Glyph 0: aw=500, lsb=50
        0x01, 0xF4, 0x00, 0x32,
        // Glyph 1: aw=600, lsb=60
        0x02, 0x58, 0x00, 0x3C,
        // Glyph 2: aw=700, lsb=70
        0x02, 0xBC, 0x00, 0x46,
        // Glyph 3: lsb=80 (uses last aw=700)
        0x00, 0x50,
        // Glyph 4: lsb=90 (uses last aw=700)
        0x00, 0x5A,
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final hmtx = HorizontalMetrics(3, 5);
      hmtx.readContentFrom(reader);

      expect(hmtx.glyphCount, equals(5));
      
      // Check full hMetrics
      expect(hmtx.getAdvanceWidth(0), equals(500));
      expect(hmtx.getLeftSideBearing(0), equals(50));
      
      expect(hmtx.getAdvanceWidth(1), equals(600));
      expect(hmtx.getLeftSideBearing(1), equals(60));
      
      expect(hmtx.getAdvanceWidth(2), equals(700));
      expect(hmtx.getLeftSideBearing(2), equals(70));
      
      // Check glyphs with only lsb (reuse last advance width)
      expect(hmtx.getAdvanceWidth(3), equals(700));
      expect(hmtx.getLeftSideBearing(3), equals(80));
      
      expect(hmtx.getAdvanceWidth(4), equals(700));
      expect(hmtx.getLeftSideBearing(4), equals(90));
    });

    test('reads monospaced font metrics', () {
      // Monospaced: 1 hMetric, 4 additional glyphs (all same aw)
      final data = Uint8List.fromList([
        // Glyph 0: aw=600, lsb=50
        0x02, 0x58, 0x00, 0x32,
        // Glyphs 1-4: only lsb (all use aw=600)
        0x00, 0x3C, // lsb=60
        0x00, 0x46, // lsb=70
        0x00, 0x50, // lsb=80
        0x00, 0x5A, // lsb=90
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final hmtx = HorizontalMetrics(1, 5);
      hmtx.readContentFrom(reader);

      expect(hmtx.glyphCount, equals(5));
      
      // All glyphs should have the same advance width
      for (var i = 0; i < 5; i++) {
        expect(hmtx.getAdvanceWidth(i), equals(600), reason: 'Glyph $i');
      }
      
      // But different left side bearings
      expect(hmtx.getLeftSideBearing(0), equals(50));
      expect(hmtx.getLeftSideBearing(1), equals(60));
      expect(hmtx.getLeftSideBearing(2), equals(70));
      expect(hmtx.getLeftSideBearing(3), equals(80));
      expect(hmtx.getLeftSideBearing(4), equals(90));
    });

    test('getHMetric returns both values', () {
      final data = Uint8List.fromList([
        0x02, 0x00, 0x00, 0x64, // aw=512, lsb=100
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final hmtx = HorizontalMetrics(1, 1);
      hmtx.readContentFrom(reader);

      final (aw, lsb) = hmtx.getHMetric(0);
      expect(aw, equals(512));
      expect(lsb, equals(100));
    });

    test('handles invalid index gracefully', () {
      final data = Uint8List.fromList([
        0x02, 0x00, 0x00, 0x64,
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final hmtx = HorizontalMetrics(1, 1);
      hmtx.readContentFrom(reader);

      expect(hmtx.getAdvanceWidth(-1), equals(0));
      expect(hmtx.getAdvanceWidth(10), equals(0));
      expect(hmtx.getLeftSideBearing(-1), equals(0));
      expect(hmtx.getLeftSideBearing(10), equals(0));
    });
  });

  group('GDEF Table', () {
    test('fills glyph classes and mark classes', () {
      final builder = BytesBuilder();
      // Header
      builder.add(encodeUInt16(1)); // major
      builder.add(encodeUInt16(0)); // minor
      builder.add(encodeUInt16(12)); // glyphClassDef offset
      builder.add(encodeUInt16(0)); // attach list offset
      builder.add(encodeUInt16(0)); // lig caret list offset
      builder.add(encodeUInt16(22)); // mark attachment class offset

      // Glyph class definition (format 1)
      builder.add(encodeUInt16(1)); // format
      builder.add(encodeUInt16(1)); // start glyph
      builder.add(encodeUInt16(2)); // glyph count
      builder.add(encodeUInt16(1)); // glyph #1 => base
      builder.add(encodeUInt16(3)); // glyph #2 => mark

      // Mark attachment class definition (format 1)
      builder.add(encodeUInt16(1)); // format
      builder.add(encodeUInt16(2)); // start glyph
      builder.add(encodeUInt16(2)); // glyph count
      builder.add(encodeUInt16(1)); // glyph #2 => mark class 1
      builder.add(encodeUInt16(2)); // glyph #3 => mark class 2

      final data = Uint8List.fromList(builder.toBytes());
      final reader = ByteOrderSwappingBinaryReader(data);

      final gdef = GDEF();
      gdef.readContentFrom(reader);

      final glyphs =
          List<Glyph>.generate(6, (index) => Glyph.empty(index));
      gdef.fillGlyphData(glyphs);

      expect(glyphs[1].glyphClass, equals(GlyphClassKind.base));
      expect(glyphs[2].glyphClass, equals(GlyphClassKind.mark));
      expect(glyphs[2].markClassDef, equals(1));
      expect(glyphs[3].markClassDef, equals(2));
    });
  });

  group('NameEntry Table', () {
    test('creates name table', () {
      final name = NameEntry();
      expect(name.name, equals('name'));
    });

    test('reads name table with UTF-16BE strings', () {
      // Create a minimal name table with one UTF-16BE name record
      final stringData = 'Test Font'.codeUnits;
      final utf16Bytes = <int>[];
      for (final code in stringData) {
        utf16Bytes.add((code >> 8) & 0xFF); // High byte
        utf16Bytes.add(code & 0xFF); // Low byte
      }

      final data = Uint8List.fromList([
        0x00, 0x00, // format: 0
        0x00, 0x01, // nameCount: 1
        0x00, 0x12, // storageOffset: 18 (6 + 12)
        // Name Record 1: Font Family Name
        0x00, 0x03, // platformID: 3 (Windows)
        0x00, 0x01, // encodingID: 1 (Unicode)
        0x04, 0x09, // languageID: 0x0409 (English US)
        0x00, 0x01, // nameID: 1 (Font Family Name)
        ...encodeUInt16(utf16Bytes.length), // stringLength
        0x00, 0x00, // stringOffset: 0
        // String storage
        ...utf16Bytes,
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final nameEntry = NameEntry();
      nameEntry.header = TableHeader(
        tag: 0x6E616D65, // 'name'
        checkSum: 0,
        offset: 0,
        length: data.length,
      );
      nameEntry.readContentFrom(reader);

      expect(nameEntry.fontName, equals('Test Font'));
    });

    test('reads name table with multiple name IDs', () {
      // Font Family Name
      final familyBytes = _encodeUtf16BE('MyFont');
      // Font Subfamily Name
      final subfamilyBytes = _encodeUtf16BE('Regular');
      // Version String
      final versionBytes = _encodeUtf16BE('Version 1.0');

      final nameRecordSize = 12;
      final headerSize = 6;
      final storageStart = headerSize + (3 * nameRecordSize);

      final data = Uint8List.fromList([
        0x00, 0x00, // format: 0
        0x00, 0x03, // nameCount: 3
        ...encodeUInt16(storageStart), // storageOffset
        
        // Record 1: Font Family Name (ID=1)
        0x00, 0x03, // platformID: 3 (Windows)
        0x00, 0x01, // encodingID: 1
        0x04, 0x09, // languageID: English US
        0x00, 0x01, // nameID: 1
        ...encodeUInt16(familyBytes.length),
        0x00, 0x00, // stringOffset: 0
        
        // Record 2: Font Subfamily Name (ID=2)
        0x00, 0x03, // platformID: 3
        0x00, 0x01, // encodingID: 1
        0x04, 0x09, // languageID
        0x00, 0x02, // nameID: 2
        ...encodeUInt16(subfamilyBytes.length),
        ...encodeUInt16(familyBytes.length), // stringOffset
        
        // Record 3: Version String (ID=5)
        0x00, 0x03, // platformID: 3
        0x00, 0x01, // encodingID: 1
        0x04, 0x09, // languageID
        0x00, 0x05, // nameID: 5
        ...encodeUInt16(versionBytes.length),
        ...encodeUInt16(familyBytes.length + subfamilyBytes.length), // stringOffset
        
        // String storage
        ...familyBytes,
        ...subfamilyBytes,
        ...versionBytes,
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final nameEntry = NameEntry();
      nameEntry.header = TableHeader(
        tag: 0x6E616D65,
        checkSum: 0,
        offset: 0,
        length: data.length,
      );
      nameEntry.readContentFrom(reader);

      expect(nameEntry.fontName, equals('MyFont'));
      expect(nameEntry.fontSubFamily, equals('Regular'));
      expect(nameEntry.versionString, equals('Version 1.0'));
    });

    test('decodes UTF-16BE correctly', () {
      final testString = 'Héllo Wörld! 你好';
      final utf16Bytes = _encodeUtf16BE(testString);

      final data = Uint8List.fromList([
        0x00, 0x00, // format
        0x00, 0x01, // nameCount: 1
        0x00, 0x12, // storageOffset: 18
        // Name record
        0x00, 0x03, // platformID
        0x00, 0x01, // encodingID: 1 (UTF-16BE)
        0x04, 0x09, // languageID
        0x00, 0x04, // nameID: 4 (Full Font Name)
        ...encodeUInt16(utf16Bytes.length),
        0x00, 0x00, // stringOffset
        // String data
        ...utf16Bytes,
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final nameEntry = NameEntry();
      nameEntry.header = TableHeader(
        tag: 0x6E616D65,
        checkSum: 0,
        offset: 0,
        length: data.length,
      );
      nameEntry.readContentFrom(reader);

      expect(nameEntry.fullFontName, equals(testString));
    });
  });

  group('Cmap Table', () {
    test('creates cmap table', () {
      final cmap = Cmap();
      expect(cmap.name, equals('cmap'));
    });

    test('reads cmap format 4 (simple mapping)', () {
      // Create a simple format 4 cmap with a single segment
      // Maps A-Z (65-90) to glyphs 1-26
      final data = Uint8List.fromList([
        0x00, 0x00, // version: 0
        0x00, 0x01, // tableCount: 1
        // Encoding record
        0x00, 0x03, // platformID: 3 (Windows)
        0x00, 0x01, // encodingID: 1 (Unicode BMP)
        0x00, 0x00, 0x00, 0x0C, // offset: 12
        
        // Format 4 subtable at offset 12
        0x00, 0x04, // format: 4
        0x00, 0x20, // length: 32 bytes
        0x00, 0x00, // language: 0
        0x00, 0x04, // segCountX2: 4 (2 segments)
        0x00, 0x04, // searchRange
        0x00, 0x01, // entrySelector
        0x00, 0x00, // rangeShift
        
        // endCode array
        0x00, 0x5A, // 90 (Z)
        0xFF, 0xFF, // 0xFFFF (terminator)
        
        0x00, 0x00, // reserved
        
        // startCode array
        0x00, 0x41, // 65 (A)
        0xFF, 0xFF, // 0xFFFF
        
        // idDelta array
        0xFF, 0xC4, // -60 (to map A=65 to glyph 5: 65-60=5)
        0x00, 0x01, // +1
        
        // idRangeOffset array
        0x00, 0x00, // 0 (use delta)
        0x00, 0x00, // 0
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final cmap = Cmap();
      cmap.header = TableHeader(
        tag: 0x636D6170, // 'cmap'
        checkSum: 0,
        offset: 0,
        length: data.length,
      );
      cmap.readContentFrom(reader);

      // Test mapping A-Z
      expect(cmap.getGlyphIndex(65, 0), equals(5)); // A -> glyph 5
      expect(cmap.getGlyphIndex(66, 0), equals(6)); // B -> glyph 6
      expect(cmap.getGlyphIndex(90, 0), equals(30)); // Z -> glyph 30
      
      // Test unmapped character
      expect(cmap.getGlyphIndex(97, 0), equals(0)); // 'a' -> glyph 0 (unmapped)
    });

    test('reads cmap format 12 (full Unicode)', () {
      // Format 12 with sequential mapping groups
      final data = Uint8List.fromList([
        0x00, 0x00, // version: 0
        0x00, 0x01, // tableCount: 1
        // Encoding record
        0x00, 0x03, // platformID: 3
        0x00, 0x0A, // encodingID: 10 (Unicode UCS-4)
        0x00, 0x00, 0x00, 0x0C, // offset: 12
        
        // Format 12 subtable at offset 12
        0x00, 0x0C, // format: 12
        0x00, 0x00, // reserved
        0x00, 0x00, 0x00, 0x28, // length: 40 bytes
        0x00, 0x00, 0x00, 0x00, // language: 0
        0x00, 0x00, 0x00, 0x02, // numGroups: 2
        
        // Group 1: U+0041-U+005A (A-Z) -> glyphs 1-26
        0x00, 0x00, 0x00, 0x41, // startCharCode: 65
        0x00, 0x00, 0x00, 0x5A, // endCharCode: 90
        0x00, 0x00, 0x00, 0x01, // startGlyphId: 1
        
        // Group 2: U+0061-U+007A (a-z) -> glyphs 27-52
        0x00, 0x00, 0x00, 0x61, // startCharCode: 97
        0x00, 0x00, 0x00, 0x7A, // endCharCode: 122
        0x00, 0x00, 0x00, 0x1B, // startGlyphId: 27
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final cmap = Cmap();
      cmap.header = TableHeader(
        tag: 0x636D6170,
        checkSum: 0,
        offset: 0,
        length: data.length,
      );
      cmap.readContentFrom(reader);

      // Test group 1
      expect(cmap.getGlyphIndex(65, 0), equals(1)); // A -> glyph 1
      expect(cmap.getGlyphIndex(90, 0), equals(26)); // Z -> glyph 26
      
      // Test group 2
      expect(cmap.getGlyphIndex(97, 0), equals(27)); // a -> glyph 27
      expect(cmap.getGlyphIndex(122, 0), equals(52)); // z -> glyph 52
      
      // Test unmapped
      expect(cmap.getGlyphIndex(48, 0), equals(0)); // '0' -> glyph 0
    });

    test('caches glyph index lookups', () {
      final data = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x01, // version, tableCount
        0x00, 0x03, 0x00, 0x01, // platformID, encodingID
        0x00, 0x00, 0x00, 0x0C, // offset
        
        // Minimal format 4 cmap
        0x00, 0x04, 0x00, 0x20, 0x00, 0x00, 0x00, 0x04,
        0x00, 0x04, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x5A, 0xFF, 0xFF, 0x00, 0x00,
        0x00, 0x41, 0xFF, 0xFF,
        0xFF, 0xBF, 0x00, 0x01,
        0x00, 0x00, 0x00, 0x00,
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final cmap = Cmap();
      cmap.header = TableHeader(tag: 0x636D6170, checkSum: 0, offset: 0, length: data.length);
      cmap.readContentFrom(reader);

      // First lookup
      final glyph1 = cmap.getGlyphIndex(65, 0);
      // Second lookup should use cache
      final glyph2 = cmap.getGlyphIndex(65, 0);
      
      expect(glyph1, equals(glyph2));
    });
  });

  group('GlyphLocations Table', () {
    test('reads short version (16-bit offsets)', () {
      final data = Uint8List.fromList([
        0x00, 0x00, // offset 0 (0 * 2)
        0x00, 0x05, // offset 10 (5 * 2)
        0x00, 0x0A, // offset 20 (10 * 2)
        0x00, 0x0F, // offset 30 (15 * 2)
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final loca = GlyphLocations(3, false); // 3 glyphs, short version
      loca.header = TableHeader(tag: 0x6C6F6361, checkSum: 0, offset: 0, length: data.length);
      loca.readContentFrom(reader);

      expect(loca.glyphCount, equals(3));
      expect(loca.isLongVersion, isFalse);
      expect(loca.offsets[0], equals(0));
      expect(loca.offsets[1], equals(10));
      expect(loca.offsets[2], equals(20));
      expect(loca.offsets[3], equals(30));
    });

    test('reads long version (32-bit offsets)', () {
      final data = Uint8List.fromList([
        0x00, 0x00, 0x00, 0x00, // offset 0
        0x00, 0x00, 0x00, 0x64, // offset 100
        0x00, 0x00, 0x00, 0xC8, // offset 200
      ]);

      final reader = ByteOrderSwappingBinaryReader(data);
      final loca = GlyphLocations(2, true); // 2 glyphs, long version
      loca.header = TableHeader(tag: 0x6C6F6361, checkSum: 0, offset: 0, length: data.length);
      loca.readContentFrom(reader);

      expect(loca.glyphCount, equals(2));
      expect(loca.isLongVersion, isTrue);
      expect(loca.offsets[0], equals(0));
      expect(loca.offsets[1], equals(100));
      expect(loca.offsets[2], equals(200));
    });
  });

  group('Glyph and GlyphPointF', () {
    test('GlyphPointF stores coordinates and on-curve flag', () {
      final point = GlyphPointF(10.5, 20.5, true);
      
      expect(point.x, equals(10.5));
      expect(point.y, equals(20.5));
      expect(point.onCurve, isTrue);
    });

    test('GlyphPointF offset works correctly', () {
      final point = GlyphPointF(10.0, 20.0, true);
      final offsetPoint = point.offset(5, -3);
      
      expect(offsetPoint.x, equals(15.0));
      expect(offsetPoint.y, equals(17.0));
      expect(offsetPoint.onCurve, isTrue);
    });

    test('Glyph.empty creates an empty glyph', () {
      final glyph = Glyph.empty(5);
      
      expect(glyph.glyphIndex, equals(5));
      expect(glyph.glyphPoints, isEmpty);
      expect(glyph.contourEndPoints, isEmpty);
      expect(glyph.hasGlyphInstructions, isFalse);
    });

    test('Glyph.fromTrueType creates a glyph with data', () {
      final points = [
        GlyphPointF(0, 0, true),
        GlyphPointF(100, 0, true),
        GlyphPointF(100, 100, true),
        GlyphPointF(0, 100, true),
      ];
      final bounds = Bounds(0, 0, 100, 100);
      
      final glyph = Glyph.fromTrueType(
        glyphPoints: points,
        contourEndPoints: [3], // One contour ending at index 3
        bounds: bounds,
        glyphIndex: 10,
      );
      
      expect(glyph.glyphIndex, equals(10));
      expect(glyph.glyphPoints!.length, equals(4));
      expect(glyph.contourEndPoints, equals([3]));
      expect(glyph.minX, equals(0));
      expect(glyph.maxX, equals(100));
    });
  });

  group('Typeface', () {
    test('creates a typeface with all required tables', () {
      // Create minimal tables
      final nameEntry = NameEntry();
      nameEntry.fontName = 'Test Font';
      nameEntry.fontSubFamily = 'Regular';
      
      final bounds = Bounds(0, -200, 1000, 800);
      final unitsPerEm = 1000;
      
      final glyphs = [
        Glyph.empty(0),
        Glyph.fromTrueType(
          glyphPoints: [GlyphPointF(0, 0, true)],
          contourEndPoints: [0],
          bounds: Bounds(0, 0, 100, 100),
          glyphIndex: 1,
        ),
      ];
      
      final hmtx = HorizontalMetrics(2, 2);
      final os2 = OS2Table();
      os2.sTypoAscender = 800;
      os2.sTypoDescender = -200;
      os2.sTypoLineGap = 100;
      os2.usWinAscent = 900;
      os2.usWinDescent = 300;
      
      final typeface = Typeface.fromTrueType(
        nameEntry: nameEntry,
        bounds: bounds,
        unitsPerEm: unitsPerEm,
        glyphs: glyphs,
        horizontalMetrics: hmtx,
        os2Table: os2,
      );
      
      expect(typeface.name, equals('Test Font'));
      expect(typeface.fontSubFamily, equals('Regular'));
      expect(typeface.glyphCount, equals(2));
      expect(typeface.unitsPerEm, equals(1000));
      expect(typeface.ascender, equals(800));
      expect(typeface.descender, equals(-200));
      expect(typeface.lineGap, equals(100));
    });

    test('calculates scale to pixel correctly', () {
      final nameEntry = NameEntry();
      final bounds = Bounds(0, 0, 1000, 1000);
      final glyphs = [Glyph.empty(0)];
      final hmtx = HorizontalMetrics(1, 1);
      final os2 = OS2Table();
      
      final typeface = Typeface.fromTrueType(
        nameEntry: nameEntry,
        bounds: bounds,
        unitsPerEm: 1000,
        glyphs: glyphs,
        horizontalMetrics: hmtx,
        os2Table: os2,
      );
      
      // For 16px target with 1000 units per em
      // scale should be 16/1000 = 0.016
      expect(typeface.calculateScaleToPixel(16), equals(0.016));
      
      // For 12pt at 96 DPI: 12 * 96 / 72 = 16px
      // Then 16 / 1000 = 0.016
      expect(typeface.calculateScaleToPixelFromPointSize(12, 96), equals(0.016));
    });

    test('converts points to pixels', () {
      // 12pt at 96 DPI = 12 * 96 / 72 = 16px
      expect(Typeface.convertPointsToPixels(12, 96), equals(16.0));
      
      // 10pt at 72 DPI = 10 * 72 / 72 = 10px
      expect(Typeface.convertPointsToPixels(10, 72), equals(10.0));
    });

    test('retrieves glyphs by index and codepoint', () {
      final nameEntry = NameEntry();
      final bounds = Bounds(0, 0, 1000, 1000);
      final glyphs = [
        Glyph.empty(0),
        Glyph.empty(1),
      ];
      final hmtx = HorizontalMetrics(2, 2);
      final os2 = OS2Table();
      
      final cmap = Cmap();
      // Mock cmap to return glyph index 1 for codepoint 65 ('A')
      // (In real usage, this would be set up properly)
      
      final typeface = Typeface.fromTrueType(
        nameEntry: nameEntry,
        bounds: bounds,
        unitsPerEm: 1000,
        glyphs: glyphs,
        horizontalMetrics: hmtx,
        os2Table: os2,
        cmapTable: cmap,
      );
      
      // Get glyph by index
      final glyph = typeface.getGlyph(1);
      expect(glyph.glyphIndex, equals(1));
      
      // Invalid index should return first glyph
      final invalidGlyph = typeface.getGlyph(999);
      expect(invalidGlyph.glyphIndex, equals(0));
    });
  });
}

// Helper function to encode a 16-bit unsigned integer as big-endian bytes
List<int> encodeUInt16(int value) {
  return [(value >> 8) & 0xFF, value & 0xFF];
}

List<int> encodeUInt32(int value) {
  return [
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ];
}

// Helper function to encode a string as UTF-16 Big Endian
List<int> _encodeUtf16BE(String text) {
  final bytes = <int>[];
  for (final unit in text.codeUnits) {
    bytes.add((unit >> 8) & 0xFF);
    bytes.add(unit & 0xFF);
  }
  return bytes;
}
