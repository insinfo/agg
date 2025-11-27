import 'package:agg/src/typography/io/byte_order_swapping_reader.dart';

class Woff2Utils {
  static const int oneMoreByteCode1 = 255;
  static const int oneMoreByteCode2 = 254;
  static const int wordCode = 253;
  static const int lowestUCode = 253;

  static List<int> readInt16Array(ByteOrderSwappingBinaryReader reader, int count) {
    List<int> arr = List.filled(count, 0);
    for (int i = 0; i < count; ++i) {
      arr[i] = reader.readInt16();
    }
    return arr;
  }

  static int read255UInt16(ByteOrderSwappingBinaryReader reader) {
    int code = reader.readByte();
    if (code == wordCode) {
      int value = reader.readByte();
      value <<= 8;
      value &= 0xff00;
      int value2 = reader.readByte();
      value |= value2 & 0x00ff;
      return value;
    } else if (code == oneMoreByteCode1) {
      return reader.readByte() + lowestUCode;
    } else if (code == oneMoreByteCode2) {
      return reader.readByte() + (lowestUCode * 2);
    } else {
      return code;
    }
  }
}

class TripleEncodingRecord {
  final int byteCount;
  final int xBits;
  final int yBits;
  final int deltaX;
  final int deltaY;
  final int xSign;
  final int ySign;

  TripleEncodingRecord(this.byteCount, this.xBits, this.yBits, this.deltaX,
      this.deltaY, this.xSign, this.ySign);

  int tx(int orgX) => (orgX + deltaX) * xSign;
  int ty(int orgY) => (orgY + deltaY) * ySign;
}

class TripleEncodingTable {
  static TripleEncodingTable? _instance;
  final List<TripleEncodingRecord> _records = [];

  static TripleEncodingTable getEncTable() {
    _instance ??= TripleEncodingTable._();
    return _instance!;
  }

  TripleEncodingTable._() {
    _buildTable();
  }

  TripleEncodingRecord operator [](int index) => _records[index];

  void _buildTable() {
    // (set 1.1)
    _buildRecords(2, 0, 8, null, [0, 256, 512, 768, 1024]);
    // (set 1.2)
    _buildRecords(2, 8, 0, [0, 256, 512, 768, 1024], null);
    // (set 2.1)
    _buildRecords(2, 4, 4, [1], [1, 17, 33, 49]);
    // (set 2.2)
    _buildRecords(2, 4, 4, [17], [1, 17, 33, 49]);
    // (set 2.3)
    _buildRecords(2, 4, 4, [33], [1, 17, 33, 49]);
    // (set 2.4)
    _buildRecords(2, 4, 4, [49], [1, 17, 33, 49]);
    // (set 3.1)
    _buildRecords(3, 8, 8, [1], [1, 257, 513]);
    // (set 3.2)
    _buildRecords(3, 8, 8, [257], [1, 257, 513]);
    // (set 3.3)
    _buildRecords(3, 8, 8, [513], [1, 257, 513]);
    // (set 4)
    _buildRecords(4, 12, 12, [0], [0]);
    // (set 5)
    _buildRecords(5, 16, 16, [0], [0]);
  }

  void _addRecord(int byteCount, int xBits, int yBits, int deltaX, int deltaY,
      int xSign, int ySign) {
    _records.add(TripleEncodingRecord(
        byteCount, xBits, yBits, deltaX, deltaY, xSign, ySign));
  }

  void _buildRecords(int byteCount, int xBits, int yBits, List<int>? deltaXs,
      List<int>? deltaYs) {
    if (deltaXs == null && deltaYs != null) {
      for (int y = 0; y < deltaYs.length; ++y) {
        _addRecord(byteCount, xBits, yBits, 0, deltaYs[y], 0, -1);
        _addRecord(byteCount, xBits, yBits, 0, deltaYs[y], 0, 1);
      }
    } else if (deltaYs == null && deltaXs != null) {
      for (int x = 0; x < deltaXs.length; ++x) {
        _addRecord(byteCount, xBits, yBits, deltaXs[x], 0, -1, 0);
        _addRecord(byteCount, xBits, yBits, deltaXs[x], 0, 1, 0);
      }
    } else if (deltaXs != null && deltaYs != null) {
      for (int x = 0; x < deltaXs.length; ++x) {
        int deltaX = deltaXs[x];
        for (int y = 0; y < deltaYs.length; ++y) {
          int deltaY = deltaYs[y];
          _addRecord(byteCount, xBits, yBits, deltaX, deltaY, -1, -1);
          _addRecord(byteCount, xBits, yBits, deltaX, deltaY, 1, -1);
          _addRecord(byteCount, xBits, yBits, deltaX, deltaY, -1, 1);
          _addRecord(byteCount, xBits, yBits, deltaX, deltaY, 1, 1);
        }
      }
    }
  }
}
