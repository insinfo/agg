import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:agg/src/typography/io/byte_order_swapping_reader.dart';
import 'package:agg/src/typography/openfont/open_font_reader.dart';
import 'package:agg/src/typography/openfont/tables/table_entry.dart';
import 'package:agg/src/typography/openfont/tables/utils.dart';
import 'package:agg/src/typography/openfont/typeface.dart';

class WoffHeader {
  late int flavor;
  late int length;
  late int numTables;
  late int totalSfntSize;
  late int majorVersion;
  late int minorVersion;
  late int metaOffset;
  late int metaLength;
  late int metaOriginalLength;
  late int privOffset;
  late int privLength;
}

class WoffTableDirectory {
  late int tag;
  late int offset;
  late int compLength;
  late int origLength;
  late int origChecksum;

  // Translated values
  late String name;
  late int expectedStartAt;

  @override
  String toString() => name;
}

class WoffReader {
  WoffHeader? _header;

  Typeface? read(ByteOrderSwappingBinaryReader reader) {
    _header = _readWoffHeader(reader);
    if (_header == null) {
      return null;
    }

    List<WoffTableDirectory>? woffTableDirs = _readTableDirectories(reader);
    if (woffTableDirs == null) {
      return null;
    }

    TableEntryCollection tableEntryCollection =
        _createTableEntryCollection(woffTableDirs);

    final outputBuffer = BytesBuilder();

    if (_extract(reader, woffTableDirs, outputBuffer)) {
      final decompressedBytes = outputBuffer.toBytes();
      final reader2 = ByteOrderSwappingBinaryReader(decompressedBytes);
      final openFontReader = OpenFontReader();
      return openFontReader.readTableEntryCollection(
          tableEntryCollection, reader2);
    }

    return null;
  }

  TableEntryCollection _createTableEntryCollection(
      List<WoffTableDirectory> woffTableDirs) {
    final tableEntryCollection = TableEntryCollection();
    for (var woffTableDir in woffTableDirs) {
      tableEntryCollection.addEntry(UnreadTableEntry(TableHeader(
        tag: woffTableDir.tag,
        checkSum: woffTableDir.origChecksum,
        offset: woffTableDir.expectedStartAt,
        length: woffTableDir.origLength,
      )));
    }
    return tableEntryCollection;
  }

  WoffHeader? _readWoffHeader(ByteOrderSwappingBinaryReader reader) {
    int b0 = reader.readByte();
    int b1 = reader.readByte();
    int b2 = reader.readByte();
    int b3 = reader.readByte();

    if (!(b0 == 0x77 && b1 == 0x4f && b2 == 0x46 && b3 == 0x46)) {
      return null;
    }

    final header = WoffHeader();
    header.flavor = reader.readUInt32();
    header.length = reader.readUInt32();
    header.numTables = reader.readUInt16();
    reader.readUInt16(); // reserved
    header.totalSfntSize = reader.readUInt32();

    header.majorVersion = reader.readUInt16();
    header.minorVersion = reader.readUInt16();

    header.metaOffset = reader.readUInt32();
    header.metaLength = reader.readUInt32();
    header.metaOriginalLength = reader.readUInt32();

    header.privOffset = reader.readUInt32();
    header.privLength = reader.readUInt32();

    return header;
  }

  List<WoffTableDirectory>? _readTableDirectories(
      ByteOrderSwappingBinaryReader reader) {
    int tableCount = _header!.numTables;
    int expectedStartAt = 0;
    List<WoffTableDirectory> tableDirs =
        List.generate(tableCount, (_) => WoffTableDirectory());

    for (int i = 0; i < tableCount; ++i) {
      final table = tableDirs[i];
      table.tag = reader.readUInt32();
      table.offset = reader.readUInt32();
      table.compLength = reader.readUInt32();
      table.origLength = reader.readUInt32();
      table.origChecksum = reader.readUInt32();

      table.expectedStartAt = expectedStartAt;
      table.name = Utils.tagToString(table.tag);

      expectedStartAt += table.origLength;
    }

    return tableDirs;
  }

  bool _extract(ByteOrderSwappingBinaryReader reader,
      List<WoffTableDirectory> tables, BytesBuilder outputBuffer) {
    for (int i = 0; i < tables.length; ++i) {
      final table = tables[i];
      reader.seek(table.offset);

      Uint8List compressedBuffer = reader.readBytes(table.compLength);

      if (table.compLength == table.origLength) {
        outputBuffer.add(compressedBuffer);
      } else {
        try {
          final decompressedBuffer =
              ZLibDecoder().decodeBytes(compressedBuffer);
          if (decompressedBuffer.length != table.origLength) {
             // Warning?
          }
          outputBuffer.add(decompressedBuffer);
        } catch (e) {
          return false;
        }
      }
    }
    return true;
  }
}
