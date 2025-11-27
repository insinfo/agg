import '../../io/byte_order_swapping_reader.dart';
import 'table_entry.dart';

/// Kerning Table
class Kern extends TableEntry {
  static const String _N = "kern";
  @override
  String get name => _N;

  // https://www.microsoft.com/typography/otspec/kern.htm

  final List<KerningSubTable> _kernSubTables = [];

  int getKerningDistance(int left, int right) {
    if (_kernSubTables.isEmpty) {
      return 0;
    }
    // use kern sub table 0
    // TODO: review if have more than 1 table
    return _kernSubTables[0].getKernDistance(left, right);
  }

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    // version
    reader.readUInt16();
    final nTables = reader.readUInt16(); // subtable count

    // TODO: review here
    // if (nTables > 1) {
    //   print("Support for $nTables kerning tables");
    // }

    for (var i = 0; i < nTables; ++i) {
      // subTableVersion
      reader.readUInt16();
      final len = reader.readUInt16(); // Length of the subtable, in bytes (including this header).
      final kerCoverage = KernCoverage(reader.readUInt16()); // What type of information is contained in this table.

      // The coverage field is divided into the following sub-fields, with sizes given in bits:
      // ----------------------------------------------
      // Format of the subtable.
      // Only formats 0 and 2 have been defined.
      // Formats 1 and 3 through 255 are reserved for future use.

      switch (kerCoverage.format) {
        case 0:
          _readSubTableFormat0(reader, len - (3 * 2)); // 3 header field * 2 byte each
          break;
        case 2:
          // TODO: implement
          // Skip the rest of the table
          reader.readBytes(len - (3 * 2));
          break;
        default:
          // print("Kerning Coverage Format ${kerCoverage.format}");
          // Skip the rest of the table
          reader.readBytes(len - (3 * 2));
          break;
      }
    }
  }

  void _readSubTableFormat0(ByteOrderSwappingBinaryReader reader, int remainingBytes) {
    var npairs = reader.readUInt16();
    // searchRange
    reader.readUInt16();
    // entrySelector
    reader.readUInt16();
    // rangeShift
    reader.readUInt16();
    // ----------------------------------------------
    final ksubTable = KerningSubTable(npairs);
    _kernSubTables.add(ksubTable);
    while (npairs > 0) {
      ksubTable.addKernPair(
        reader.readUInt16(), // left
        reader.readUInt16(), // right
        reader.readInt16(), // value
      );
      npairs--;
    }
  }
}

class KerningPair {
  /// left glyph index
  final int left;

  /// right glyph index
  final int right;

  /// n FUnits. If this value is greater than zero, the characters will be moved apart.
  /// If this value is less than zero, the character will be moved closer together.
  final int value;

  KerningPair(this.left, this.right, this.value);

  @override
  String toString() {
    return "$left $right";
  }
}

class KernCoverage {
  final int coverage;
  late final bool horizontal;
  late final bool hasMinimum;
  late final bool crossStream;
  late final bool override;
  late final int format;

  KernCoverage(this.coverage) {
    // bit 0,len 1, 1 if table has horizontal data, 0 if vertical.
    horizontal = (coverage & 0x1) == 1;
    // bit 1,len 1, If this bit is set to 1, the table has minimum values. If set to 0, the table has kerning values.
    hasMinimum = ((coverage >> 1) & 0x1) == 1;
    // bit 2,len 1, If set to 1, kerning is perpendicular to the flow of the text.
    crossStream = ((coverage >> 2) & 0x1) == 1;
    // bit 3,len 1, If this bit is set to 1 the value in this table should replace the value currently being accumulated.
    override = ((coverage >> 3) & 0x1) == 1;
    // bit 4-7 => Reserved. This should be set to zero.
    format = (coverage >> 8) & 0xff;
  }
}

class KerningSubTable {
  final List<KerningPair> _kernPairs;
  final Map<int, int> _kernDic;

  KerningSubTable(int capacity)
      : _kernPairs = <KerningPair>[],
        _kernDic = <int, int>{};

  void addKernPair(int left, int right, int value) {
    _kernPairs.add(KerningPair(left, right, value));
    // may has duplicate key ?
    // TODO: review here
    final key = (left << 16) | right;
    _kernDic[key] = value; // just replace?
  }

  int getKernDistance(int left, int right) {
    // find if we have this left & right ?
    final key = (left << 16) | right;
    return _kernDic[key] ?? 0;
  }
}
