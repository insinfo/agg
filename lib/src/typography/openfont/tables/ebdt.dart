// MIT, 2019-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../../io/byte_order_swapping_reader.dart';
import 'table_entry.dart';

/// Embedded Bitmap Data Table
class EBDT extends TableEntry {
  static const String _N = "EBDT";
  @override
  String get name => _N;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    reader.readUInt16(); // majorVersion
    reader.readUInt16(); // minorVersion

    // The rest of the EBDT table is a collection of bitmap data.
    // The data can be in a number of possible formats,
    // indicated by information in the EBLC table.
  }
}
