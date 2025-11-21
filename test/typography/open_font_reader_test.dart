import 'dart:typed_data';

import 'package:agg/src/typography/openfont/open_font_reader.dart';
import 'package:test/test.dart';

void main() {
  test('OpenFontReader reads minimal TrueType font', () {
    final fontBytes = _buildMinimalTrueTypeFont();
    final reader = OpenFontReader();
    final typeface = reader.read(fontBytes);

    expect(typeface, isNotNull);
    expect(typeface!.glyphCount, equals(1));
    expect(typeface.unitsPerEm, equals(1000));
    expect(typeface.name, equals('Test'));
  });
}

Uint8List _buildMinimalTrueTypeFont() {
  final tables = <String, Uint8List>{
    'head': _buildHeadTable(),
    'maxp': _buildMaxpTable(),
    'hhea': _buildHheaTable(),
    'hmtx': _buildHmtxTable(),
    'OS/2': _buildOs2Table(),
    'name': _buildNameTable(),
    'cmap': _buildCmapTable(),
    'loca': _buildLocaTable(),
    'glyf': Uint8List(0),
  };
  return _buildFontFile(tables);
}

Uint8List _buildHeadTable() {
  final data = ByteData(54);
  var offset = 0;
  data.setUint32(offset, 0x00010000, Endian.big);
  offset += 4;
  data.setUint32(offset, 0, Endian.big);
  offset += 4;
  data.setUint32(offset, 0, Endian.big);
  offset += 4;
  data.setUint32(offset, 0x5F0F3CF5, Endian.big);
  offset += 4;
  data.setUint16(offset, 0, Endian.big);
  offset += 2;
  data.setUint16(offset, 1000, Endian.big);
  offset += 2;
  data.setUint64(offset, 0, Endian.big);
  offset += 8;
  data.setUint64(offset, 0, Endian.big);
  offset += 8;
  data.setInt16(offset, 0, Endian.big); // xMin
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // yMin
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // xMax
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // yMax
  offset += 2;
  data.setUint16(offset, 0, Endian.big); // macStyle
  offset += 2;
  data.setUint16(offset, 8, Endian.big); // lowestRecPPEM
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // fontDirectionHint
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // indexToLocFormat
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // glyphDataFormat
  return data.buffer.asUint8List();
}

Uint8List _buildMaxpTable() {
  final data = ByteData(32);
  data.setUint32(0, 0x00010000, Endian.big);
  data.setUint16(4, 1, Endian.big); // glyphCount
  return data.buffer.asUint8List();
}

Uint8List _buildHheaTable() {
  final data = ByteData(36);
  var offset = 0;
  data.setUint32(offset, 0x00010000, Endian.big);
  offset += 4;
  data.setInt16(offset, 800, Endian.big); // ascent
  offset += 2;
  data.setInt16(offset, -200, Endian.big); // descent
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // lineGap
  offset += 2;
  data.setUint16(offset, 1000, Endian.big); // advanceWidthMax
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // min left side bearing
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // min right side bearing
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // max X extent
  offset += 2;
  data.setInt16(offset, 1, Endian.big); // caretSlopeRise
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // caretSlopeRun
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // caretOffset
  offset += 2;
  for (var i = 0; i < 4; i++) {
    data.setInt16(offset, 0, Endian.big);
    offset += 2;
  }
  data.setInt16(offset, 0, Endian.big); // metricDataFormat
  offset += 2;
  data.setUint16(offset, 1, Endian.big); // number of hMetrics
  return data.buffer.asUint8List();
}

Uint8List _buildHmtxTable() {
  final data = ByteData(4);
  data.setUint16(0, 500, Endian.big); // advance width
  data.setInt16(2, 0, Endian.big); // left side bearing
  return data.buffer.asUint8List();
}

Uint8List _buildOs2Table() {
  final data = ByteData(86);
  var offset = 0;
  data.setUint16(offset, 0, Endian.big); // version 0
  offset += 2;
  data.setInt16(offset, 500, Endian.big); // xAvgCharWidth
  offset += 2;
  data.setUint16(offset, 400, Endian.big); // weight
  offset += 2;
  data.setUint16(offset, 5, Endian.big); // width
  offset += 2;
  data.setUint16(offset, 0, Endian.big); // fsType
  offset += 2;
  // Subscript metrics (set to zero)
  for (var i = 0; i < 10; i++) {
    data.setInt16(offset, 0, Endian.big);
    offset += 2;
  }
  // Strikeout
  data.setInt16(offset, 0, Endian.big);
  offset += 2;
  data.setInt16(offset, 0, Endian.big);
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // sFamilyClass
  offset += 2;
  // Panose (10 bytes)
  for (var i = 0; i < 10; i++) {
    data.setUint8(offset++, 0);
  }
  // Unicode ranges
  for (var i = 0; i < 4; i++) {
    data.setUint32(offset, 0, Endian.big);
    offset += 4;
  }
  data.setUint32(offset, 0, Endian.big); // Vendor ID
  offset += 4;
  data.setUint16(offset, 0, Endian.big); // fsSelection
  offset += 2;
  data.setUint16(offset, 0, Endian.big); // usFirstCharIndex
  offset += 2;
  data.setUint16(offset, 255, Endian.big); // usLastCharIndex
  offset += 2;
  data.setInt16(offset, 800, Endian.big); // sTypoAscender
  offset += 2;
  data.setInt16(offset, -200, Endian.big); // sTypoDescender
  offset += 2;
  data.setInt16(offset, 0, Endian.big); // sTypoLineGap
  offset += 2;
  data.setUint16(offset, 900, Endian.big); // usWinAscent
  offset += 2;
  data.setUint16(offset, 200, Endian.big); // usWinDescent
  offset += 2;
  return data.buffer.asUint8List(0, offset);
}

Uint8List _buildNameTable() {
  final storageOffset = 6 + 12;
  final nameBytes = _encodeUtf16BE('Test');
  final builder = BytesBuilder();
  builder.add(_encodeUInt16(0)); // format
  builder.add(_encodeUInt16(1)); // count
  builder.add(_encodeUInt16(storageOffset));
  builder.add(_encodeUInt16(3)); // platform ID
  builder.add(_encodeUInt16(1)); // encoding ID
  builder.add(_encodeUInt16(0x0409)); // language ID
  builder.add(_encodeUInt16(1)); // name ID (font family)
  builder.add(_encodeUInt16(nameBytes.length));
  builder.add(_encodeUInt16(0)); // offset into storage
  builder.add(nameBytes);
  return builder.toBytes();
}

Uint8List _buildCmapTable() {
  final glyphArray = Uint8List(256);
  final format0 = BytesBuilder()
    ..add(_encodeUInt16(0)) // format
    ..add(_encodeUInt16(262)) // length
    ..add(_encodeUInt16(0)) // language
    ..add(glyphArray);

  final builder = BytesBuilder()
    ..add(_encodeUInt16(0)) // version
    ..add(_encodeUInt16(1)) // numTables
    ..add(_encodeUInt16(3)) // platform ID
    ..add(_encodeUInt16(1)) // encoding ID
    ..add(_encodeUInt32(12)) // offset to subtable
    ..add(format0.toBytes());
  return builder.toBytes();
}

Uint8List _buildLocaTable() {
  final data = ByteData(4);
  data.setUint16(0, 0, Endian.big);
  data.setUint16(2, 0, Endian.big);
  return data.buffer.asUint8List();
}

Uint8List _buildFontFile(Map<String, Uint8List> tables) {
  final tags = tables.keys.toList()..sort();
  final recordCount = tags.length;
  final headerSize = 12 + recordCount * 16;

  var currentOffset = headerSize;
  final records = <_TableRecord>[];
  for (final tag in tags) {
    currentOffset = _align4(currentOffset);
    final data = tables[tag]!;
    records.add(
      _TableRecord(
        tag,
        currentOffset,
        data.length,
        data,
      ),
    );
    currentOffset += _align4(data.length);
  }

  final totalSize = currentOffset;
  final bytes = Uint8List(totalSize);
  final bd = ByteData.view(bytes.buffer);

  var pos = 0;
  bd.setUint32(pos, 0x00010000, Endian.big);
  pos += 4;
  bd.setUint16(pos, recordCount, Endian.big);
  pos += 2;
  final searchRange = _calcSearchRange(recordCount);
  bd.setUint16(pos, searchRange, Endian.big);
  pos += 2;
  bd.setUint16(pos, _calcEntrySelector(recordCount), Endian.big);
  pos += 2;
  bd.setUint16(pos, recordCount * 16 - searchRange, Endian.big);
  pos += 2;

  for (final record in records) {
    for (var i = 0; i < 4; i++) {
      bd.setUint8(pos + i, record.tag.codeUnitAt(i));
    }
    pos += 4;
    bd.setUint32(pos, 0, Endian.big); // checksum unused
    pos += 4;
    bd.setUint32(pos, record.offset, Endian.big);
    pos += 4;
    bd.setUint32(pos, record.length, Endian.big);
    pos += 4;
  }

  for (final record in records) {
    bytes.setAll(record.offset, record.data);
    final pad = _align4(record.length) - record.length;
    if (pad > 0) {
      bytes.fillRange(record.offset + record.length,
          record.offset + record.length + pad, 0);
    }
  }

  return bytes;
}

int _align4(int value) => (value + 3) & ~3;

int _calcSearchRange(int numTables) {
  var value = 1;
  while (value * 2 <= numTables) {
    value *= 2;
  }
  return value * 16;
}

int _calcEntrySelector(int numTables) {
  var value = 1;
  var selector = 0;
  while (value * 2 <= numTables) {
    value *= 2;
    selector++;
  }
  return selector;
}

Uint8List _encodeUInt16(int value) {
  return Uint8List.fromList([(value >> 8) & 0xFF, value & 0xFF]);
}

Uint8List _encodeUInt32(int value) {
  return Uint8List.fromList([
    (value >> 24) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 8) & 0xFF,
    value & 0xFF,
  ]);
}

Uint8List _encodeUtf16BE(String value) {
  final builder = BytesBuilder();
  for (final unit in value.codeUnits) {
    builder.add(_encodeUInt16(unit));
  }
  return builder.toBytes();
}

class _TableRecord {
  _TableRecord(this.tag, this.offset, this.length, this.data);

  final String tag;
  final int offset;
  final int length;
  final Uint8List data;
}
