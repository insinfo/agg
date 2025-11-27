import 'dart:typed_data';
import '../../../typography/io/byte_order_swapping_reader.dart';
import 'table_entry.dart';

class PrepTable extends TableEntry {
  static const String tableName = 'prep';
  @override
  String get name => tableName;

  Uint8List? programBuffer;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    if (header != null) {
      programBuffer = reader.readBytes(header!.length);
    }
  }
}
