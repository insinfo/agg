import 'dart:typed_data';
import '../../../typography/io/byte_order_swapping_reader.dart';
import 'table_entry.dart';

class CvtTable extends TableEntry {
  static const String tableName = 'cvt ';
  @override
  String get name => tableName;

  Int16List? controlValues;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    if (header != null) {
      int count = header!.length ~/ 2;
      controlValues = Int16List(count);
      for (int i = 0; i < count; i++) {
        controlValues![i] = reader.readInt16();
      }
    }
  }
}
