import 'dart:typed_data';
import 'package:brotli/brotli.dart';
import 'package:agg/src/typography/io/byte_order_swapping_reader.dart';
import 'package:agg/src/typography/openfont/open_font_reader.dart';
import 'package:agg/src/typography/openfont/tables/table_entry.dart';
import 'package:agg/src/typography/openfont/tables/utils.dart';
import 'package:agg/src/typography/openfont/typeface.dart';
import 'package:agg/src/typography/openfont/tables/glyf.dart';
import 'package:agg/src/typography/openfont/tables/loca.dart';
import 'package:agg/src/typography/openfont/glyph.dart';
import 'package:agg/src/typography/openfont/webfont/woff2_utils.dart';
import 'package:agg/src/typography/openfont/tables/utils.dart' as utils;

class Woff2Header {
  late int flavor;
  late int length;
  late int numTables;
  late int totalSfntSize;
  late int totalCompressSize;
  late int majorVersion;
  late int minorVersion;
  late int metaOffset;
  late int metaLength;
  late int metaOriginalLength;
  late int privOffset;
  late int privLength;
}

class Woff2TableDirectory {
  late int origLength;
  late int transformLength;
  late String name;
  late int preprocessingTransformation;
  late int expectedStartAt;

  @override
  String toString() => '$name $preprocessingTransformation';
}

class Woff2Reader {
  Woff2Header? _header;

  static final List<String> _knownTableTags = [
    "cmap", "head", "hhea", "hmtx", "maxp", "name", "OS/2", "post", "cvt ",
    "fpgm", "glyf", "loca", "prep", "CFF ", "VORG", "EBDT", "EBLC", "gasp",
    "hdmx", "kern", "LTSH", "PCLT", "VDMX", "vhea", "vmtx", "BASE", "GDEF",
    "GPOS", "GSUB", "EBSC", "JSTF", "MATH", "CBDT", "CBLC", "COLR", "CPAL",
    "SVG ", "sbix", "acnt", "avar", "bdat", "bloc", "bsln", "cvar", "fdsc",
    "feat", "fmtx", "fvar", "gvar", "hsty", "just", "lcar", "mort", "morx",
    "opbd", "prop", "trak", "Zapf", "Silf", "Glat", "Gloc", "Feat", "Sill"
  ];

  Typeface? read(ByteOrderSwappingBinaryReader reader) {
    _header = _readHeader(reader);
    if (_header == null) return null;

    List<Woff2TableDirectory> woff2TableDirs = _readTableDirectories(reader);

    // Read compressed data
    Uint8List compressedBuffer = reader.readBytes(_header!.totalCompressSize);
    if (compressedBuffer.length != _header!.totalCompressSize) {
      return null;
    }

    try {
      final decompressedBuffer =
          brotli.decode(compressedBuffer); // brotli package
      final decompressedStream =
          ByteOrderSwappingBinaryReader(Uint8List.fromList(decompressedBuffer));

      TableEntryCollection tableEntryCollection =
          _createTableEntryCollection(woff2TableDirs);
      
      OpenFontReader openFontReader = OpenFontReader();
      return openFontReader.readTableEntryCollection(
          tableEntryCollection, decompressedStream);
    } catch (e) {
      // Decompression failed
      return null;
    }
  }

  Woff2Header? _readHeader(ByteOrderSwappingBinaryReader reader) {
    int b0 = reader.readByte();
    int b1 = reader.readByte();
    int b2 = reader.readByte();
    int b3 = reader.readByte();

    if (!(b0 == 0x77 && b1 == 0x4f && b2 == 0x46 && b3 == 0x32)) {
      return null;
    }

    final header = Woff2Header();
    header.flavor = reader.readUInt32();
    header.length = reader.readUInt32();
    header.numTables = reader.readUInt16();
    reader.readUInt16(); // reserved
    header.totalSfntSize = reader.readUInt32();
    header.totalCompressSize = reader.readUInt32();

    header.majorVersion = reader.readUInt16();
    header.minorVersion = reader.readUInt16();

    header.metaOffset = reader.readUInt32();
    header.metaLength = reader.readUInt32();
    header.metaOriginalLength = reader.readUInt32();

    header.privOffset = reader.readUInt32();
    header.privLength = reader.readUInt32();

    return header;
  }

  List<Woff2TableDirectory> _readTableDirectories(
      ByteOrderSwappingBinaryReader reader) {
    int tableCount = _header!.numTables;
    List<Woff2TableDirectory> tableDirs =
        List.generate(tableCount, (_) => Woff2TableDirectory());
    int expectedTableStartAt = 0;

    for (int i = 0; i < tableCount; ++i) {
      final table = tableDirs[i];
      int flags = reader.readByte();
      int knownTableIndex = flags & 0x1F;

      if (knownTableIndex < 63) {
        table.name = _knownTableTags[knownTableIndex];
      } else {
        table.name = Utils.tagToString(reader.readUInt32());
      }

      table.preprocessingTransformation = (flags >> 5) & 0x3;
      table.expectedStartAt = expectedTableStartAt;

      table.origLength = _readUIntBase128(reader);

      switch (table.preprocessingTransformation) {
        case 0:
          if (table.name == 'glyf' || table.name == 'loca') {
             table.transformLength = _readUIntBase128(reader);
             expectedTableStartAt += table.transformLength;
          } else {
             expectedTableStartAt += table.origLength;
          }
          break;
        default:
          expectedTableStartAt += table.origLength;
          break;
      }
    }
    return tableDirs;
  }

  int _readUIntBase128(ByteOrderSwappingBinaryReader reader) {
    int accum = 0;
    for (int i = 0; i < 5; ++i) {
      int dataByte = reader.readByte();
      if (i == 0 && dataByte == 0x80) throw Exception("Leading zeros in UIntBase128");
      if ((accum & 0xFE000000) != 0) throw Exception("UIntBase128 overflow");

      accum = (accum << 7) | (dataByte & 0x7F);
      if ((dataByte & 0x80) == 0) {
        return accum;
      }
    }
    throw Exception("UIntBase128 exceeds 5 bytes");
  }

  static int _tagFromString(String tag) {
    if (tag.length != 4) return 0;
    int val = 0;
    val |= tag.codeUnitAt(0) << 24;
    val |= tag.codeUnitAt(1) << 16;
    val |= tag.codeUnitAt(2) << 8;
    val |= tag.codeUnitAt(3);
    return val;
  }

  TableEntryCollection _createTableEntryCollection(
      List<Woff2TableDirectory> woffTableDirs) {
    final tableEntryCollection = TableEntryCollection();
    for (var woffTableDir in woffTableDirs) {
      UnreadTableEntry? unreadTableEntry;

      if (woffTableDir.name == 'glyf' &&
          woffTableDir.preprocessingTransformation == 0) {
        // Transformed glyf table
        TableHeader tableHeader = TableHeader(
            tag: _tagFromString(woffTableDir.name),
            checkSum: 0,
            offset: woffTableDir.expectedStartAt,
            length: woffTableDir.transformLength);
        unreadTableEntry = TransformedGlyf(tableHeader, woffTableDir);
      } else if (woffTableDir.name == 'loca' &&
          woffTableDir.preprocessingTransformation == 0) {
        // Transformed loca table
        TableHeader tableHeader = TableHeader(
            tag: _tagFromString(woffTableDir.name),
            checkSum: 0,
            offset: woffTableDir.expectedStartAt,
            length: woffTableDir.transformLength);
        unreadTableEntry = TransformedLoca(tableHeader, woffTableDir);
      } else {
        TableHeader tableHeader = TableHeader(
            tag: _tagFromString(woffTableDir.name),
            checkSum: 0,
            offset: woffTableDir.expectedStartAt,
            length: woffTableDir.origLength);
        unreadTableEntry = UnreadTableEntry(tableHeader);
      }
      tableEntryCollection.addEntry(unreadTableEntry);
    }
    return tableEntryCollection;
  }
}

class TransformedLoca extends UnreadTableEntry {
  final Woff2TableDirectory tableDir;
  TransformedLoca(TableHeader header, this.tableDir) : super(header) {
    hasCustomContentReader = true;
  }

  @override
  T createTableEntry<T extends TableEntry>(ByteOrderSwappingBinaryReader reader, T expectedResult) {
    if (expectedResult is GlyphLocations) {
      return expectedResult;
    }
    throw UnsupportedError("Expected GlyphLocations");
  }
}

class TransformedGlyf extends UnreadTableEntry {
  final Woff2TableDirectory tableDir;
  TransformedGlyf(TableHeader header, this.tableDir) : super(header) {
    hasCustomContentReader = true;
  }

  @override
  T createTableEntry<T extends TableEntry>(ByteOrderSwappingBinaryReader reader, T expectedResult) {
    if (expectedResult is Glyf) {
      _reconstructGlyfTable(reader, tableDir, expectedResult);
      return expectedResult;
    }
    throw UnsupportedError("Expected Glyf");
  }

  void _reconstructGlyfTable(ByteOrderSwappingBinaryReader reader,
      Woff2TableDirectory woff2TableDir, Glyf glyfTable) {
    reader.seek(woff2TableDir.expectedStartAt);

    // int version = reader.readUInt32(); // Unused
    reader.readUInt32();
    int numGlyphs = reader.readUInt16();
    // int indexFormatOffset = reader.readUInt16(); // Unused
    reader.readUInt16();

    int nContourStreamSize = reader.readUInt32();
    int nPointsStreamSize = reader.readUInt32();
    int flagStreamSize = reader.readUInt32();
    int glyphStreamSize = reader.readUInt32();
    int compositeStreamSize = reader.readUInt32();
    int bboxStreamSize = reader.readUInt32();
    reader.readUInt32(); // instructionStreamSize

    int expectedNCountStartAt = reader.position;
    int expectedNPointStartAt = expectedNCountStartAt + nContourStreamSize;
    int expectedFlagStreamStartAt = expectedNPointStartAt + nPointsStreamSize;
    int expectedGlyphStreamStartAt = expectedFlagStreamStartAt + flagStreamSize;
    int expectedCompositeStreamStartAt =
        expectedGlyphStreamStartAt + glyphStreamSize;
    int expectedBboxStreamStartAt =
        expectedCompositeStreamStartAt + compositeStreamSize;
    int expectedInstructionStreamStartAt =
        expectedBboxStreamStartAt + bboxStreamSize;

    List<Glyph?> glyphs = List.filled(numGlyphs, null);
    List<_TempGlyph> allGlyphs =
        List.generate(numGlyphs, (i) => _TempGlyph(i, 0));
    List<int> compositeGlyphs = [];
    int contourCount = 0;

    for (int i = 0; i < numGlyphs; ++i) {
      int numContour = reader.readInt16();
      allGlyphs[i] = _TempGlyph(i, numContour);
      if (numContour > 0) {
        contourCount += numContour;
      } else if (numContour < 0) {
        compositeGlyphs.add(i);
      }
    }

    // 1) nPoints stream
    reader.seek(expectedNPointStartAt);
    List<int> pntPerContours = List.filled(contourCount, 0);
    for (int i = 0; i < contourCount; ++i) {
      pntPerContours[i] = Woff2Utils.read255UInt16(reader);
    }

    // 2) flagStream
    reader.seek(expectedFlagStreamStartAt);
    Uint8List flagStream = reader.readBytes(flagStreamSize);

    // Check composite instructions
    reader.seek(expectedCompositeStreamStartAt);
    Uint8List compositeBytes = reader.readBytes(compositeStreamSize);
    ByteOrderSwappingBinaryReader compositeReader =
        ByteOrderSwappingBinaryReader(compositeBytes);

    for (int i = 0; i < compositeGlyphs.length; ++i) {
      int compositeGlyphIndex = compositeGlyphs[i];
      allGlyphs[compositeGlyphIndex].compositeHasInstructions =
          _compositeHasInstructions(compositeReader);
    }

    // Build simple glyphs
    reader.seek(expectedGlyphStreamStartAt);
    final emptyGlyph = Glyph.empty(0);

    var pntContourIndexRef = _Ref(0);
    var curFlagsIndexRef = _Ref(0);

    for (int i = 0; i < numGlyphs; ++i) {
       glyphs[i] = _buildSimpleGlyphStructure(
          reader,
          allGlyphs[i],
          emptyGlyph,
          pntPerContours,
          pntContourIndexRef,
          flagStream,
          curFlagsIndexRef);
    }

    // Build composite glyphs
    compositeReader.seek(0); // Reset composite reader
    
    for (int i = 0; i < compositeGlyphs.length; ++i) {
      int compositeGlyphIndex = compositeGlyphs[i];
      glyphs[compositeGlyphIndex] = _readCompositeGlyph(
          glyphs, compositeReader, compositeGlyphIndex, emptyGlyph);
    }

    // BBox stream
    reader.seek(expectedBboxStreamStartAt);
    int bitmapCount = (numGlyphs + 7) ~/ 8;
    Uint8List bboxBitmap = _expandBitmap(reader.readBytes(bitmapCount));
    
    for (int i = 0; i < numGlyphs; ++i) {
      Glyph? glyph = glyphs[i];
      if (glyph == null) continue;

      if (bboxBitmap[i] == 1) {
        glyph.bounds = Bounds(
            reader.readInt16(),
            reader.readInt16(),
            reader.readInt16(),
            reader.readInt16());
      } else {
        if (allGlyphs[i].numContour < 0) {
           throw UnsupportedError("Composite glyph missing bbox");
        } else if (allGlyphs[i].numContour > 0) {
           glyph.bounds = _findSimpleGlyphBounds(glyph);
        }
      }
    }

    // Instruction stream
    reader.seek(expectedInstructionStreamStartAt);
    for (int i = 0; i < numGlyphs; ++i) {
      _TempGlyph tempGlyph = allGlyphs[i];
      if (tempGlyph.instructionLen > 0) {
        glyphs[i]!.glyphInstructions = reader.readBytes(tempGlyph.instructionLen);
      }
    }

    glyfTable.glyphs = glyphs.cast<Glyph>();
  }

  bool _compositeHasInstructions(ByteOrderSwappingBinaryReader reader) {
    int flags;
    do {
      flags = reader.readUInt16();
      reader.readUInt16(); // glyphIndex
      
      // args
      if ((flags & 0x0001) != 0) { // ARG_1_AND_2_ARE_WORDS
        reader.readInt16();
        reader.readInt16();
      } else {
        reader.readUInt16();
      }

      // scale
      if ((flags & 0x0008) != 0) { // WE_HAVE_A_SCALE
        utils.Utils.readF2Dot14(reader);
      } else if ((flags & 0x0040) != 0) { // WE_HAVE_AN_X_AND_Y_SCALE
        utils.Utils.readF2Dot14(reader);
        utils.Utils.readF2Dot14(reader);
      } else if ((flags & 0x0080) != 0) { // WE_HAVE_A_TWO_BY_TWO
        utils.Utils.readF2Dot14(reader);
        utils.Utils.readF2Dot14(reader);
        utils.Utils.readF2Dot14(reader);
        utils.Utils.readF2Dot14(reader);
      }
    } while ((flags & 0x0020) != 0); // MORE_COMPONENTS

    return (flags & 0x0100) != 0; // WE_HAVE_INSTRUCTIONS
  }

  Glyph _buildSimpleGlyphStructure(
      ByteOrderSwappingBinaryReader reader,
      _TempGlyph tmpGlyph,
      Glyph emptyGlyph,
      List<int> pntPerContours,
      _Ref<int> pntContourIndex,
      Uint8List flagStream,
      _Ref<int> flagStreamIndex) {
    
    if (tmpGlyph.numContour == 0) return emptyGlyph;
    if (tmpGlyph.numContour < 0) {
      if (tmpGlyph.compositeHasInstructions) {
        tmpGlyph.instructionLen = Woff2Utils.read255UInt16(reader);
      }
      return emptyGlyph; // Placeholder, will be replaced
    }

    int curX = 0;
    int curY = 0;
    int numContour = tmpGlyph.numContour;
    List<int> endContours = List.filled(numContour, 0);
    int pointCount = 0;

    for (int i = 0; i < numContour; ++i) {
      int numPoint = pntPerContours[pntContourIndex.value++];
      pointCount += numPoint;
      endContours[i] = pointCount - 1;
    }

    List<GlyphPointF> glyphPoints = List.generate(pointCount, (_) => GlyphPointF(0,0,false));
    int n = 0;
    final encTable = TripleEncodingTable.getEncTable();

    for (int i = 0; i < numContour; ++i) {
      int endContour = endContours[i];
      for (; n <= endContour; ++n) {
        int f = flagStream[flagStreamIndex.value++];
        int xyFormat = f & 0x7F;
        bool onCurve = (f >> 7) == 0;

        TripleEncodingRecord enc = encTable[xyFormat];
        Uint8List packedXY = reader.readBytes(enc.byteCount - 1);

        int x = 0;
        int y = 0;

        if (enc.xBits == 0) {
           y = enc.ty(packedXY[0]);
        } else if (enc.xBits == 4) {
           x = enc.tx(packedXY[0] >> 4);
           y = enc.ty(packedXY[0] & 0xF);
        } else if (enc.xBits == 8) {
           x = enc.tx(packedXY[0]);
           y = (enc.yBits == 8) ? enc.ty(packedXY[1]) : 0;
        } else if (enc.xBits == 12) {
           x = enc.tx((packedXY[0] << 4) | (packedXY[1] >> 4));
           y = enc.ty(((packedXY[1] & 0xF) << 8) | packedXY[2]);
        } else if (enc.xBits == 16) {
           x = enc.tx((packedXY[0] << 8) | packedXY[1]);
           y = enc.ty((packedXY[2] << 8) | packedXY[3]);
        }

        curX += x;
        curY += y;
        glyphPoints[n] = GlyphPointF(curX.toDouble(), curY.toDouble(), onCurve);
      }
    }

    tmpGlyph.instructionLen = Woff2Utils.read255UInt16(reader);

    return Glyph.fromTrueType(
        glyphPoints: glyphPoints,
        contourEndPoints: endContours,
        bounds: Bounds.zero,
        glyphInstructions: null,
        glyphIndex: tmpGlyph.glyphIndex);
  }

  Glyph _readCompositeGlyph(List<Glyph?> createdGlyphs, ByteOrderSwappingBinaryReader reader, int compositeGlyphIndex, Glyph emptyGlyph) {
    Glyph? finalGlyph;
    int flags;
    
    do {
      flags = reader.readUInt16();
      int glyphIndex = reader.readUInt16();
      
      Glyph? componentGlyph = createdGlyphs[glyphIndex];
      if (componentGlyph == null) {
         throw UnsupportedError("Composite glyph dependency not met");
      }

      Glyph newGlyph = Glyph.clone(componentGlyph, compositeGlyphIndex);

      int arg1 = 0;
      int arg2 = 0;

      if ((flags & 0x0001) != 0) { // ARG_1_AND_2_ARE_WORDS
        arg1 = reader.readInt16();
        arg2 = reader.readInt16();
      } else {
        int val = reader.readUInt16();
        if ((flags & 0x0001) == 0) {
           arg1 = (val >> 8).toSigned(8);
           arg2 = (val & 0xFF).toSigned(8);
        }
      }

      double xscale = 1.0;
      double yscale = 1.0;
      double scale01 = 0.0;
      double scale10 = 0.0;
      bool hasScale = false;
      bool useMatrix = false;

      if ((flags & 0x0008) != 0) { // WE_HAVE_A_SCALE
        xscale = yscale = utils.Utils.readF2Dot14(reader);
        hasScale = true;
      } else if ((flags & 0x0040) != 0) { // WE_HAVE_AN_X_AND_Y_SCALE
        xscale = utils.Utils.readF2Dot14(reader);
        yscale = utils.Utils.readF2Dot14(reader);
        hasScale = true;
      } else if ((flags & 0x0080) != 0) { // WE_HAVE_A_TWO_BY_TWO
        xscale = utils.Utils.readF2Dot14(reader);
        scale01 = utils.Utils.readF2Dot14(reader);
        scale10 = utils.Utils.readF2Dot14(reader);
        yscale = utils.Utils.readF2Dot14(reader);
        hasScale = true;
        useMatrix = true;
      }

      if ((flags & 0x0002) != 0) { // ARGS_ARE_XY_VALUES
         if (useMatrix) {
            Glyph.transformNormalWith2x2Matrix(newGlyph, xscale, scale01, scale10, yscale);
            Glyph.offsetXY(newGlyph, arg1, arg2);
         } else {
            if (hasScale) {
               Glyph.transformNormalWith2x2Matrix(newGlyph, xscale, 0, 0, yscale);
               Glyph.offsetXY(newGlyph, arg1, arg2);
            } else {
               Glyph.offsetXY(newGlyph, arg1, arg2);
            }
         }
      }

      if (finalGlyph == null) {
        finalGlyph = newGlyph;
      } else {
        Glyph.appendGlyph(finalGlyph, newGlyph);
      }

    } while ((flags & 0x0020) != 0);

    return finalGlyph;
  }

  Uint8List _expandBitmap(Uint8List orgBBoxBitmap) {
    Uint8List expandArr = Uint8List(orgBBoxBitmap.length * 8);
    int index = 0;
    for (int i = 0; i < orgBBoxBitmap.length; ++i) {
      int b = orgBBoxBitmap[i];
      expandArr[index++] = (b >> 7) & 0x1;
      expandArr[index++] = (b >> 6) & 0x1;
      expandArr[index++] = (b >> 5) & 0x1;
      expandArr[index++] = (b >> 4) & 0x1;
      expandArr[index++] = (b >> 3) & 0x1;
      expandArr[index++] = (b >> 2) & 0x1;
      expandArr[index++] = (b >> 1) & 0x1;
      expandArr[index++] = (b >> 0) & 0x1;
    }
    return expandArr;
  }

  Bounds _findSimpleGlyphBounds(Glyph glyph) {
    double xmin = double.maxFinite;
    double ymin = double.maxFinite;
    double xmax = -double.maxFinite;
    double ymax = -double.maxFinite;

    if (glyph.glyphPoints != null) {
      for (var p in glyph.glyphPoints!) {
        if (p.x < xmin) xmin = p.x;
        if (p.x > xmax) xmax = p.x;
        if (p.y < ymin) ymin = p.y;
        if (p.y > ymax) ymax = p.y;
      }
    }
    
    if (xmin == double.maxFinite) return Bounds(0,0,0,0);

    return Bounds(
      xmin.round(),
      ymin.round(),
      xmax.round(),
      ymax.round()
    );
  }
}

class _TempGlyph {
  final int glyphIndex;
  final int numContour;
  int instructionLen = 0;
  bool compositeHasInstructions = false;

  _TempGlyph(this.glyphIndex, this.numContour);
}

class _Ref<T> {
  T value;
  _Ref(this.value);
}
