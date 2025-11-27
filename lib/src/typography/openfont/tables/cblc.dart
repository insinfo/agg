// MIT, 2019-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../../io/byte_order_swapping_reader.dart';
import 'eblc.dart';

/// CBLC : Color Bitmap Location Table
class CBLC extends EBLC {
  static const String _N = "CBLC";
  @override
  String get name => _N;

  // CBLC is structurally identical to EBLC, just different tag and version.
  // EBLC.readContentFrom handles the structure.
  // We might want to override readContentFrom if there are subtle differences,
  // but based on C# code, it uses the same BitmapSizeTable.ReadBitmapSizeTable.
  
  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
     super.readContentFrom(reader);
  }
}
