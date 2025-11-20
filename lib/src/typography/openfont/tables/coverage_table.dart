import '../../../typography/io/byte_order_swapping_reader.dart';
import 'utils.dart';

// https://www.microsoft.com/typography/otspec/chapter2.htm
abstract class CoverageTable {
  int findPosition(int glyphIndex);
  Iterable<int> getExpandedValueIter();

  static CoverageTable createFrom(
      ByteOrderSwappingBinaryReader reader, int beginAt) {
    reader.seek(beginAt);
    int format = reader.readUInt16();
    switch (format) {
      case 1:
        return CoverageFmt1.createFrom(reader);
      case 2:
        return CoverageFmt2.createFrom(reader);
      default:
        throw UnsupportedError('CoverageTable format $format not supported');
    }
  }

  static List<CoverageTable> createMultipleCoverageTables(
      int initPos, List<int> offsets, ByteOrderSwappingBinaryReader reader) {
    return offsets
        .map((offset) => CoverageTable.createFrom(reader, initPos + offset))
        .toList();
  }
}

class CoverageFmt1 extends CoverageTable {
  late List<int> _orderedGlyphIdList;

  static CoverageFmt1 createFrom(ByteOrderSwappingBinaryReader reader) {
    // CoverageFormat1 table: Individual glyph indices
    // Type      Name                     Description
    // uint16    CoverageFormat           Format identifier-format = 1
    // uint16    GlyphCount               Number of glyphs in the GlyphArray
    // uint16    GlyphArray[GlyphCount]   Array of glyph IDs — in numerical order

    int glyphCount = reader.readUInt16();
    List<int> glyphs = Utils.readUInt16Array(reader, glyphCount);
    var table = CoverageFmt1();
    table._orderedGlyphIdList = glyphs;
    return table;
  }

  @override
  int findPosition(int glyphIndex) {
    // "The glyph indices must be in numerical order for binary searching of the list"
    // (https://www.microsoft.com/typography/otspec/chapter2.htm#coverageFormat1)
    int n = _binarySearch(_orderedGlyphIdList, glyphIndex);
    return n < 0 ? -1 : n;
  }

  @override
  Iterable<int> getExpandedValueIter() {
    return _orderedGlyphIdList;
  }

  @override
  String toString() {
    return "CoverageFmt1: ${_orderedGlyphIdList.join(',')}";
  }
}

class CoverageFmt2 extends CoverageTable {
  late List<int> _startIndices;
  late List<int> _endIndices;
  late List<int> _coverageIndices;

  int get rangeCount => _startIndices.length;

  @override
  int findPosition(int glyphIndex) {
    // Ranges must be in glyph ID order, and they must be distinct, with no overlapping.
    // [...] quick calculation of the Coverage Index for any glyph in any range using the
    // formula: Coverage Index (glyphID) = startCoverageIndex + glyphID - startGlyphID.
    // (https://www.microsoft.com/typography/otspec/chapter2.htm#coverageFormat2)

    // We search in _endIndices to find the first range where end >= glyphIndex
    int n = _binarySearch(_endIndices, glyphIndex);

    // If exact match found, n is index.
    // If not found, n is bitwise complement of insertion point.
    // In C#, ~n is the index of the first element that is larger than value.
    // If value is larger than all elements, ~n is length.

    // Wait, C# BinarySearch returns index if found.
    // If not found, returns bitwise complement of the index of the next element that is larger than value.

    // My _binarySearch implementation below mimics C# Array.BinarySearch behavior.

    n = n < 0 ? ~n : n;

    if (n >= rangeCount || glyphIndex < _startIndices[n]) {
      return -1;
    }
    return _coverageIndices[n] + glyphIndex - _startIndices[n];
  }

  @override
  Iterable<int> getExpandedValueIter() sync* {
    for (int i = 0; i < rangeCount; ++i) {
      for (int n = _startIndices[i]; n <= _endIndices[i]; ++n) {
        yield n;
      }
    }
  }

  static CoverageFmt2 createFrom(ByteOrderSwappingBinaryReader reader) {
    // CoverageFormat2 table: Range of glyphs
    // Type      Name                     Description
    // uint16    CoverageFormat           Format identifier-format = 2
    // uint16    RangeCount               Number of RangeRecords
    // struct    RangeRecord[RangeCount]  Array of glyph ranges — ordered by StartGlyphID.
    //
    // RangeRecord
    // Type      Name                Description
    // uint16    StartGlyphID        First glyph ID in the range
    // uint16    EndGlyphID          Last glyph ID in the range
    // uint16    StartCoverageIndex  Coverage Index of first glyph ID in range

    int rangeCount = reader.readUInt16();
    List<int> startIndices = List<int>.filled(rangeCount, 0);
    List<int> endIndices = List<int>.filled(rangeCount, 0);
    List<int> coverageIndices = List<int>.filled(rangeCount, 0);

    for (int i = 0; i < rangeCount; ++i) {
      startIndices[i] = reader.readUInt16();
      endIndices[i] = reader.readUInt16();
      coverageIndices[i] = reader.readUInt16();
    }

    var table = CoverageFmt2();
    table._startIndices = startIndices;
    table._endIndices = endIndices;
    table._coverageIndices = coverageIndices;
    return table;
  }

  @override
  String toString() {
    List<String> stringList = [];
    for (int i = 0; i < rangeCount; ++i) {
      stringList.add("${_startIndices[i]}-${_endIndices[i]}");
    }
    return "CoverageFmt2: ${stringList.join(',')}";
  }
}

/// Helper for binary search mimicking C# Array.BinarySearch
int _binarySearch(List<int> list, int value) {
  int min = 0;
  int max = list.length - 1;
  while (min <= max) {
    int mid = min + ((max - min) >> 1);
    int element = list[mid];
    if (element == value) {
      return mid;
    }
    if (element < value) {
      min = mid + 1;
    } else {
      max = mid - 1;
    }
  }
  return ~min;
}
