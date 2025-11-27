// MIT, 2019-present, WinterDev
// Ported to Dart by insinfo, 2025

import 'dart:typed_data';
import '../../../io/byte_order_swapping_reader.dart';
import '../utils.dart';
import '../../glyph.dart';

class SbitLineMetrics {
  int ascender = 0;
  int descender = 0;
  int widthMax = 0;

  int caretSlopeNumerator = 0;
  int caretSlopeDenominator = 0;
  int caretOffset = 0;

  int minOriginSB = 0;
  int minAdvanceSB = 0;

  int maxBeforeBL = 0;
  int minAfterBL = 0;

  int pad1 = 0;
  int pad2 = 0;
}

class BitmapSizeTable {
  int indexSubTableArrayOffset = 0;
  int indexTablesSize = 0;
  int numberOfIndexSubTables = 0;
  int colorRef = 0;

  SbitLineMetrics hori = SbitLineMetrics();
  SbitLineMetrics vert = SbitLineMetrics();

  int startGlyphIndex = 0;
  int endGlyphIndex = 0;

  int ppemX = 0;
  int ppemY = 0;
  int bitDepth = 0;

  int flags = 0;

  List<IndexSubTableBase>? indexSubTables;

  static void readSbitLineMetrics(
      ByteOrderSwappingBinaryReader reader, SbitLineMetrics lineMetric) {
    lineMetric.ascender = reader.readSByte();
    lineMetric.descender = reader.readSByte();
    lineMetric.widthMax = reader.readByte();

    lineMetric.caretSlopeNumerator = reader.readSByte();
    lineMetric.caretSlopeDenominator = reader.readSByte();
    lineMetric.caretOffset = reader.readSByte();

    lineMetric.minOriginSB = reader.readSByte();
    lineMetric.minAdvanceSB = reader.readSByte();

    lineMetric.maxBeforeBL = reader.readSByte();
    lineMetric.minAfterBL = reader.readSByte();

    lineMetric.pad1 = reader.readSByte();
    lineMetric.pad2 = reader.readSByte();
  }

  static BitmapSizeTable readBitmapSizeTable(
      ByteOrderSwappingBinaryReader reader) {
    BitmapSizeTable bmpSizeTable = BitmapSizeTable();

    bmpSizeTable.indexSubTableArrayOffset = reader.readUInt32();
    bmpSizeTable.indexTablesSize = reader.readUInt32();
    bmpSizeTable.numberOfIndexSubTables = reader.readUInt32();
    bmpSizeTable.colorRef = reader.readUInt32();

    readSbitLineMetrics(reader, bmpSizeTable.hori);
    readSbitLineMetrics(reader, bmpSizeTable.vert);

    bmpSizeTable.startGlyphIndex = reader.readUInt16();
    bmpSizeTable.endGlyphIndex = reader.readUInt16();
    bmpSizeTable.ppemX = reader.readByte();
    bmpSizeTable.ppemY = reader.readByte();
    bmpSizeTable.bitDepth = reader.readByte();
    bmpSizeTable.flags = reader.readSByte();

    return bmpSizeTable;
  }
}

class IndexSubTableArray {
  final int firstGlyphIndex;
  final int lastGlyphIndex;
  final int additionalOffsetToIndexSubtable;

  IndexSubTableArray(this.firstGlyphIndex, this.lastGlyphIndex,
      this.additionalOffsetToIndexSubtable);

  @override
  String toString() {
    return "[$firstGlyphIndex-$lastGlyphIndex]";
  }
}

class IndexSubHeader {
  final int indexFormat;
  final int imageFormat;
  final int imageDataOffset;

  IndexSubHeader(this.indexFormat, this.imageFormat, this.imageDataOffset);

  @override
  String toString() {
    return "$indexFormat,$imageFormat";
  }
}

abstract class IndexSubTableBase {
  late IndexSubHeader header;

  int get subTypeNo;
  int firstGlyphIndex = 0;
  int lastGlyphIndex = 0;

  static IndexSubTableBase? createFrom(
      BitmapSizeTable bmpSizeTable, ByteOrderSwappingBinaryReader reader) {
    IndexSubHeader header = IndexSubHeader(
      reader.readUInt16(),
      reader.readUInt16(),
      reader.readUInt32(),
    );

    switch (header.indexFormat) {
      case 1:
        {
          int nElem =
              (bmpSizeTable.endGlyphIndex - bmpSizeTable.startGlyphIndex + 1);
          Uint32List offsetArray =
              Uint32List.fromList(Utils.readUInt32Array(reader, nElem));
          IndexSubTable1 subTable = IndexSubTable1();
          subTable.header = header;
          subTable.offsetArray = offsetArray;
          return subTable;
        }
      case 2:
        {
          IndexSubTable2 subtable = IndexSubTable2();
          subtable.header = header;
          subtable.imageSize = reader.readUInt32();
          BigGlyphMetrics.readBigGlyphMetric(
              reader, subtable.bigGlyphMetrics);
          return subtable;
        }

      case 3:
        {
          int nElem =
              (bmpSizeTable.endGlyphIndex - bmpSizeTable.startGlyphIndex + 1);
          Uint16List offsetArray =
              Uint16List.fromList(Utils.readUInt16Array(reader, nElem));
          IndexSubTable3 subTable = IndexSubTable3();
          subTable.header = header;
          subTable.offsetArray = offsetArray;
          return subTable;
        }
      case 4:
        {
          IndexSubTable4 subTable = IndexSubTable4();
          subTable.header = header;

          int numGlyphs = reader.readUInt32();
          List<GlyphIdOffsetPair> glyphArray =
              List<GlyphIdOffsetPair>.generate(numGlyphs + 1, (index) {
            return GlyphIdOffsetPair(reader.readUInt16(), reader.readUInt16());
          });
          subTable.glyphArray = glyphArray;
          return subTable;
        }
      case 5:
        {
          IndexSubTable5 subTable = IndexSubTable5();
          subTable.header = header;

          subTable.imageSize = reader.readUInt32();
          BigGlyphMetrics.readBigGlyphMetric(
              reader, subTable.bigGlyphMetrics);
          subTable.glyphIdArray = Uint16List.fromList(
              Utils.readUInt16Array(reader, reader.readUInt32()));
          return subTable;
        }
    }
    return null;
  }

  void buildGlyphList(List<Glyph> glyphList);
}

class IndexSubTable1 extends IndexSubTableBase {
  @override
  int get subTypeNo => 1;
  late Uint32List offsetArray;

  @override
  void buildGlyphList(List<Glyph> glyphList) {
    int n = 0;
    for (int i = firstGlyphIndex; i <= lastGlyphIndex; ++i) {
      glyphList.add(Glyph.bitmap(
          glyphIndex: i,
          bitmapOffset: header.imageDataOffset + offsetArray[n],
          bitmapLength: 0,
          bitmapFormat: header.imageFormat));
      n++;
    }
  }
}

class IndexSubTable2 extends IndexSubTableBase {
  @override
  int get subTypeNo => 2;
  int imageSize = 0;
  BigGlyphMetrics bigGlyphMetrics = BigGlyphMetrics();

  @override
  void buildGlyphList(List<Glyph> glyphList) {
    int incrementalOffset = 0;
    for (int n = firstGlyphIndex; n <= lastGlyphIndex; ++n) {
      glyphList.add(Glyph.bitmap(
          glyphIndex: n,
          bitmapOffset: header.imageDataOffset + incrementalOffset,
          bitmapLength: imageSize,
          bitmapFormat: header.imageFormat));
      incrementalOffset += imageSize;
    }
  }
}

class IndexSubTable3 extends IndexSubTableBase {
  @override
  int get subTypeNo => 3;
  late Uint16List offsetArray;

  @override
  void buildGlyphList(List<Glyph> glyphList) {
    int n = 0;
    for (int i = firstGlyphIndex; i <= lastGlyphIndex; ++i) {
      glyphList.add(Glyph.bitmap(
          glyphIndex: i,
          bitmapOffset: header.imageDataOffset + offsetArray[n++],
          bitmapLength: 0,
          bitmapFormat: header.imageFormat));
    }
  }
}

class IndexSubTable4 extends IndexSubTableBase {
  @override
  int get subTypeNo => 4;
  late List<GlyphIdOffsetPair> glyphArray;

  @override
  void buildGlyphList(List<Glyph> glyphList) {
    for (int i = 0; i < glyphArray.length; ++i) {
      GlyphIdOffsetPair pair = glyphArray[i];
      glyphList.add(Glyph.bitmap(
          glyphIndex: pair.glyphId,
          bitmapOffset: header.imageDataOffset + pair.offset,
          bitmapLength: 0,
          bitmapFormat: header.imageFormat));
    }
  }
}

class IndexSubTable5 extends IndexSubTableBase {
  @override
  int get subTypeNo => 5;
  int imageSize = 0;
  BigGlyphMetrics bigGlyphMetrics = BigGlyphMetrics();

  late Uint16List glyphIdArray;

  @override
  void buildGlyphList(List<Glyph> glyphList) {
    int incrementalOffset = 0;
    for (int i = 0; i < glyphIdArray.length; ++i) {
      glyphList.add(Glyph.bitmap(
          glyphIndex: glyphIdArray[i],
          bitmapOffset: header.imageDataOffset + incrementalOffset,
          bitmapLength: imageSize,
          bitmapFormat: header.imageFormat));
      incrementalOffset += imageSize;
    }
  }
}

class GlyphIdOffsetPair {
  final int glyphId;
  final int offset;
  GlyphIdOffsetPair(this.glyphId, this.offset);
}

class BigGlyphMetrics {
  int height = 0;
  int width = 0;

  int horiBearingX = 0;
  int horiBearingY = 0;
  int horiAdvance = 0;

  int vertBearingX = 0;
  int vertBearingY = 0;
  int vertAdvance = 0;

  static const int size = 8;

  static void readBigGlyphMetric(
      ByteOrderSwappingBinaryReader reader, BigGlyphMetrics output) {
    output.height = reader.readByte();
    output.width = reader.readByte();

    output.horiBearingX = reader.readSByte();
    output.horiBearingY = reader.readSByte();
    output.horiAdvance = reader.readByte();

    output.vertBearingX = reader.readSByte();
    output.vertBearingY = reader.readSByte();
    output.vertAdvance = reader.readByte();
  }
}

class SmallGlyphMetrics {
  int height = 0;
  int width = 0;
  int bearingX = 0;
  int bearingY = 0;
  int advance = 0;

  static const int size = 5;

  static void readSmallGlyphMetric(
      ByteOrderSwappingBinaryReader reader, SmallGlyphMetrics output) {
    output.height = reader.readByte();
    output.width = reader.readByte();

    output.bearingX = reader.readSByte();
    output.bearingY = reader.readSByte();
    output.advance = reader.readByte();
  }
}

abstract class GlyphBitmapDataFormatBase {
  int get formatNumber;
  void fillGlyphInfo(ByteOrderSwappingBinaryReader reader, Glyph bitmapGlyph);
  // void readRawBitmap(ByteOrderSwappingBinaryReader reader, Glyph bitmapGlyph, Stream outputStream);
}

class GlyphBitmapDataFmt1 extends GlyphBitmapDataFormatBase {
  @override
  int get formatNumber => 1;
  SmallGlyphMetrics smallGlyphMetrics = SmallGlyphMetrics();

  @override
  void fillGlyphInfo(ByteOrderSwappingBinaryReader reader, Glyph bitmapGlyph) {
    throw UnimplementedError();
  }
}

class GlyphBitmapDataFmt2 extends GlyphBitmapDataFormatBase {
  @override
  int get formatNumber => 2;

  @override
  void fillGlyphInfo(ByteOrderSwappingBinaryReader reader, Glyph bitmapGlyph) {
    throw UnimplementedError();
  }
}

class GlyphBitmapDataFmt5 extends GlyphBitmapDataFormatBase {
  @override
  int get formatNumber => 5;

  @override
  void fillGlyphInfo(ByteOrderSwappingBinaryReader reader, Glyph bitmapGlyph) {
    throw UnimplementedError();
  }
}

class GlyphBitmapDataFmt6 extends GlyphBitmapDataFormatBase {
  @override
  int get formatNumber => 6;
  BigGlyphMetrics bigMetrics = BigGlyphMetrics();

  @override
  void fillGlyphInfo(ByteOrderSwappingBinaryReader reader, Glyph bitmapGlyph) {
    throw UnimplementedError();
  }
}

class GlyphBitmapDataFmt7 extends GlyphBitmapDataFormatBase {
  @override
  int get formatNumber => 7;
  BigGlyphMetrics bigMetrics = BigGlyphMetrics();

  @override
  void fillGlyphInfo(ByteOrderSwappingBinaryReader reader, Glyph bitmapGlyph) {
    throw UnimplementedError();
  }
}

class EbdtComponent {
  int glyphID = 0;
  int xOffset = 0;
  int yOffset = 0;
}

class GlyphBitmapDataFmt8 extends GlyphBitmapDataFormatBase {
  @override
  int get formatNumber => 8;

  SmallGlyphMetrics smallMetrics = SmallGlyphMetrics();
  int pad = 0;
  List<EbdtComponent>? components;

  @override
  void fillGlyphInfo(ByteOrderSwappingBinaryReader reader, Glyph bitmapGlyph) {
    throw UnimplementedError();
  }
}

class GlyphBitmapDataFmt9 extends GlyphBitmapDataFormatBase {
  @override
  int get formatNumber => 9;
  BigGlyphMetrics bigMetrics = BigGlyphMetrics();
  List<EbdtComponent>? components;

  @override
  void fillGlyphInfo(ByteOrderSwappingBinaryReader reader, Glyph bitmapGlyph) {
    throw UnimplementedError();
  }
}

class GlyphBitmapDataFmt17 extends GlyphBitmapDataFormatBase {
  @override
  int get formatNumber => 17;

  @override
  void fillGlyphInfo(ByteOrderSwappingBinaryReader reader, Glyph bitmapGlyph) {
    SmallGlyphMetrics smallGlyphMetric = SmallGlyphMetrics();
    SmallGlyphMetrics.readSmallGlyphMetric(reader, smallGlyphMetric);
    // int dataLen = reader.readUInt32();
    reader.readUInt32(); // skip dataLen
    bitmapGlyph.originalAdvanceWidth = smallGlyphMetric.advance;
    bitmapGlyph.bounds = Bounds(0, 0, smallGlyphMetric.width, smallGlyphMetric.height);
  }
}

class GlyphBitmapDataFmt18 extends GlyphBitmapDataFormatBase {
  @override
  int get formatNumber => 18;

  @override
  void fillGlyphInfo(ByteOrderSwappingBinaryReader reader, Glyph bitmapGlyph) {
    BigGlyphMetrics bigGlyphMetric = BigGlyphMetrics();
    BigGlyphMetrics.readBigGlyphMetric(reader, bigGlyphMetric);
    // int dataLen = reader.readUInt32();
    reader.readUInt32(); // skip dataLen

    bitmapGlyph.originalAdvanceWidth = bigGlyphMetric.horiAdvance;
    bitmapGlyph.bounds = Bounds(0, 0, bigGlyphMetric.width, bigGlyphMetric.height);
  }
}

class GlyphBitmapDataFmt19 extends GlyphBitmapDataFormatBase {
  @override
  int get formatNumber => 19;
  @override
  void fillGlyphInfo(ByteOrderSwappingBinaryReader reader, Glyph bitmapGlyph) {
    //no glyph info to fill
  }
}
