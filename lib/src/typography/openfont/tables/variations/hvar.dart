// MIT, 2019-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../../../io/byte_order_swapping_reader.dart';
import '../table_entry.dart';
import 'item_variation_store.dart';

/// HVAR — Horizontal Metrics Variations Table
class HVar extends TableEntry {
  static const String _N = "HVAR";
  @override
  String get name => _N;

  ItemVariationStore? itemVariationStore;
  
  int majorVersion = 0;
  int minorVersion = 0;
  int itemVariationStoreOffset = 0;
  int advanceWidthMappingOffset = 0;
  int lsbMappingOffset = 0;
  int rsbMappingOffset = 0;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    int beginAt = reader.position;

    // Horizontal metrics variations table:
    // Type      Name                        Description
    // uint16    majorVersion                Major version number of the horizontal metrics variations table — set to 1.
    // uint16    minorVersion                Minor version number of the horizontal metrics variations table — set to 0.
    // Offset32  itemVariationStoreOffset    Offset in bytes from the start of this table to the item variation store table.
    // Offset32  advanceWidthMappingOffset   Offset in bytes from the start of this table to the delta-set index mapping for advance widths (may be NULL).
    // Offset32  lsbMappingOffset            Offset in bytes from the start of this table to the delta - set index mapping for left side bearings(may be NULL).
    // Offset32  rsbMappingOffset            Offset in bytes from the start of this table to the delta - set index mapping for right side bearings(may be NULL).            

    majorVersion = reader.readUInt16();
    minorVersion = reader.readUInt16();
    itemVariationStoreOffset = reader.readUInt32();
    advanceWidthMappingOffset = reader.readUInt32();
    lsbMappingOffset = reader.readUInt32();
    rsbMappingOffset = reader.readUInt32();

    // itemVariationStore
    if (itemVariationStoreOffset > 0) {
      reader.seek(beginAt + itemVariationStoreOffset);
      itemVariationStore = ItemVariationStore();
      itemVariationStore!.readContent(reader);
    }
    
    // TODO: Implement DeltaSetIndexMap for advanceWidthMappingOffset, lsbMappingOffset, rsbMappingOffset
  }
}
