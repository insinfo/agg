// MIT, 2017-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../../io/byte_order_swapping_reader.dart';
import 'table_entry.dart';
import 'bitmap/bitmap_common.dart';
import '../glyph.dart';

/// EBLC : Embedded bitmap location data
class EBLC extends TableEntry {
  static const String _N = "EBLC";
  @override
  String get name => _N;

  // from https://docs.microsoft.com/en-us/typography/opentype/spec/eblc
  // EBLC - Embedded Bitmap Location Table

  List<BitmapSizeTable>? _bmpSizeTables;

  List<BitmapSizeTable>? get bitmapSizeTables => _bmpSizeTables;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    // load each strike table
    int eblcBeginPos = reader.position;
    //
    reader.readUInt16(); // versionMajor
    reader.readUInt16(); // versionMinor
    int numSizes = reader.readUInt32();

    if (numSizes > MAX_BITMAP_STRIKES) {
      throw Exception("Too many bitmap strikes in font.");
    }

    //----------------
    List<BitmapSizeTable> bmpSizeTables =
        List<BitmapSizeTable>.generate(numSizes, (index) {
      return BitmapSizeTable.readBitmapSizeTable(reader);
    });
    _bmpSizeTables = bmpSizeTables;

    //
    //-------
    // IndexSubTableArray
    // ...

    for (int n = 0; n < numSizes; ++n) {
      BitmapSizeTable bmpSizeTable = bmpSizeTables[n];
      int numberofIndexSubTables = bmpSizeTable.numberOfIndexSubTables;

      //
      List<IndexSubTableArray> indexSubTableArrs =
          List<IndexSubTableArray>.generate(numberofIndexSubTables, (index) {
        return IndexSubTableArray(
            reader.readUInt16(), // First glyph ID of this range.
            reader.readUInt16(), // Last glyph ID of this range (inclusive).
            reader.readUInt32()); // Add to indexSubTableArrayOffset to get offset from beginning of EBLC.
      });

      //---
      List<IndexSubTableBase> subTables = [];
      bmpSizeTable.indexSubTables = subTables;
      for (int i = 0; i < numberofIndexSubTables; ++i) {
        IndexSubTableArray indexSubTableArr = indexSubTableArrs[i];
        reader.seek(eblcBeginPos +
            bmpSizeTable.indexSubTableArrayOffset +
            indexSubTableArr.additionalOffsetToIndexSubtable);

        IndexSubTableBase? subTable =
            IndexSubTableBase.createFrom(bmpSizeTable, reader);
        if (subTable != null) {
          subTable.firstGlyphIndex = indexSubTableArr.firstGlyphIndex;
          subTable.lastGlyphIndex = indexSubTableArr.lastGlyphIndex;
          subTables.add(subTable);
        }
      }
    }
  }

  static const int MAX_BITMAP_STRIKES = 1024;

  List<Glyph> buildGlyphList() {
    List<Glyph> glyphs = [];
    if (_bmpSizeTables == null) return glyphs;

    int numSizes = _bmpSizeTables!.length;
    for (int n = 0; n < numSizes; ++n) {
      BitmapSizeTable bmpSizeTable = _bmpSizeTables![n];
      if (bmpSizeTable.indexSubTables != null) {
        for (var subTable in bmpSizeTable.indexSubTables!) {
          subTable.buildGlyphList(glyphs);
        }
      }
    }
    return glyphs;
  }
}
