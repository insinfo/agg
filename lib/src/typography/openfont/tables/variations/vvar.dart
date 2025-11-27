// MIT, 2019-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../../../io/byte_order_swapping_reader.dart';
import '../table_entry.dart';
import 'item_variation_store.dart';

/// VVAR — Vertical Metrics Variations Table
class VVar extends TableEntry {
  static const String _N = "VVAR";
  @override
  String get name => _N;

  ItemVariationStore? itemVariationStore;
  
  int majorVersion = 0;
  int minorVersion = 0;
  int itemVariationStoreOffset = 0;
  int advanceHeightMappingOffset = 0;
  int tsbMappingOffset = 0;
  int bsbMappingOffset = 0;
  int vorgMappingOffset = 0;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    int beginAt = reader.position;

    // Vertical metrics variations table:
    // Type      Name                        Description
    // uint16    majorVersion                Major version number of the vertical metrics variations table — set to 1.
    // uint16    minorVersion                Minor version number of the vertical metrics variations table — set to 0.
    // Offset32  itemVariationStoreOffset    Offset in bytes from the start of this table to the item variation store table.
    // Offset32  advanceHeightMappingOffset  Offset in bytes from the start of this table to the delta-set index mapping for advance heights (may be NULL).
    // Offset32  tsbMappingOffset            Offset in bytes from the start of this table to the delta-set index mapping for top side bearings (may be NULL).
    // Offset32  bsbMappingOffset            Offset in bytes from the start of this table to the delta-set index mapping for bottom side bearings (may be NULL).
    // Offset32  vorgMappingOffset           Offset in bytes from the start of this table to the delta-set index mapping for vertical origins (may be NULL).

    majorVersion = reader.readUInt16();
    minorVersion = reader.readUInt16();
    itemVariationStoreOffset = reader.readUInt32();
    advanceHeightMappingOffset = reader.readUInt32();
    tsbMappingOffset = reader.readUInt32();
    bsbMappingOffset = reader.readUInt32();
    vorgMappingOffset = reader.readUInt32();

    // itemVariationStore
    if (itemVariationStoreOffset > 0) {
      reader.seek(beginAt + itemVariationStoreOffset);
      itemVariationStore = ItemVariationStore();
      itemVariationStore!.readContent(reader);
    }
    
    // TODO: Implement DeltaSetIndexMap for mappings
  }
}
