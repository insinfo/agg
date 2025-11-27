import '../../io/byte_order_swapping_reader.dart';
import 'table_entry.dart';

/// Grid-fitting And Scan-conversion Procedure Table
class Gasp extends TableEntry {
  static const String _N = "gasp";
  @override
  String get name => _N;

  // https://www.microsoft.com/typography/otspec/gasp.htm

  List<GaspRangeRecord>? _rangeRecords;

  List<GaspRangeRecord>? get rangeRecords => _rangeRecords;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    // version
    reader.readUInt16();
    final numRanges = reader.readUInt16();
    
    _rangeRecords = List<GaspRangeRecord>.generate(numRanges, (index) {
      return GaspRangeRecord(
        reader.readUInt16(),
        GaspRangeBehavior(reader.readUInt16()),
      );
    });
  }
}

class GaspRangeBehavior {
  final int value;

  GaspRangeBehavior(this.value);

  bool get isNeither => value == 0;
  bool get doGray => (value & 0x0002) != 0;
  bool get gridFit => (value & 0x0001) != 0;
  bool get symmetricGridFit => (value & 0x0004) != 0;
  bool get symmetricSmoothing => (value & 0x0008) != 0;
}

class GaspRangeRecord {
  final int rangeMaxPPEM;
  final GaspRangeBehavior rangeGaspBehavior;

  GaspRangeRecord(this.rangeMaxPPEM, this.rangeGaspBehavior);
}
