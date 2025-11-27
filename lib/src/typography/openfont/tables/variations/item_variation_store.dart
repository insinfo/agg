// MIT, 2019-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../../../io/byte_order_swapping_reader.dart';
import '../utils.dart';

class ItemVariationStore {
  VariationRegionList? variationRegionList;
  List<ItemVariationData>? itemVariationData;

  void readContent(ByteOrderSwappingBinaryReader reader) {
    // The Item Variation Store table consists of a header,
    // followed by a variation region list and an array of item variation data sub-tables.

    // Type      Name                Description
    // uint16    format              Format — set to 1.
    // Offset32  variationRegionListOffset Offset in bytes from the start of the ItemVariationStore to the VariationRegionList.
    // uint16    itemVariationDataCount The number of ItemVariationData sub-tables.
    // Offset32  itemVariationDataOffsets[itemVariationDataCount] Offsets in bytes from the start of the ItemVariationStore to each ItemVariationData sub-table.

    int startPos = reader.position;
    int format = reader.readUInt16();
    if (format == 1) {} // Suppress unused warning
    int variationRegionListOffset = reader.readUInt32();
    int itemVariationDataCount = reader.readUInt16();

    List<int> itemVariationDataOffsets =
        Utils.readUInt32Array(reader, itemVariationDataCount);

    // Read Variation Region List
    reader.seek(startPos + variationRegionListOffset);
    variationRegionList = VariationRegionList();
    variationRegionList!.readContent(reader);

    // Read Item Variation Data
    itemVariationData = List<ItemVariationData>.generate(itemVariationDataCount, (index) {
      reader.seek(startPos + itemVariationDataOffsets[index]);
      ItemVariationData data = ItemVariationData();
      data.readContent(reader);
      return data;
    });
  }
}

class VariationRegionList {
  // Type      Name            Description
  // uint16    axisCount       The number of variation axes for this font. This must be the same number as axisCount in the 'fvar' table.
  // uint16    regionCount     The number of variation regions in the list.
  // VariationRegion variationRegions[regionCount] Array of variation regions.

  int axisCount = 0;
  int regionCount = 0;
  List<VariationRegion>? variationRegions;

  void readContent(ByteOrderSwappingBinaryReader reader) {
    axisCount = reader.readUInt16();
    regionCount = reader.readUInt16();
    variationRegions = List<VariationRegion>.generate(regionCount, (index) {
      VariationRegion region = VariationRegion();
      region.readContent(reader, axisCount);
      return region;
    });
  }
}

class VariationRegion {
  // VariationRegion
  // Type      Name            Description
  // RegionAxisCoordinates regionAxes[axisCount] Array of region axis coordinates records.

  List<VariationAxis>? regionAxes;

  void readContent(ByteOrderSwappingBinaryReader reader, int axisCount) {
    regionAxes = List<VariationAxis>.generate(axisCount, (index) {
      VariationAxis axis = VariationAxis();
      axis.readContent(reader);
      return axis;
    });
  }

  List<double> getRegionCoords() {
    // TODO: check this implementation
    // In C# it returns float[]
    // But what does it return? Start, Peak, End for each axis?
    // The C# code just returns the array of VariationAxis structs? No.
    // Wait, the C# code for VariationRegion doesn't have GetRegionCoords.
    // Ah, I might have misread the C# code or it was in a different place.
    // Let's stick to the data structure.
    return [];
  }
}

class VariationAxis {
  // RegionAxisCoordinates
  // Type      Name        Description
  // F2DOT14   startCoord  The start coordinate value for the region axis.
  // F2DOT14   peakCoord   The peak coordinate value for the region axis.
  // F2DOT14   endCoord    The end coordinate value for the region axis.

  double startCoord = 0;
  double peakCoord = 0;
  double endCoord = 0;

  void readContent(ByteOrderSwappingBinaryReader reader) {
    startCoord = Utils.readF2Dot14(reader);
    peakCoord = Utils.readF2Dot14(reader);
    endCoord = Utils.readF2Dot14(reader);
  }
}

class ItemVariationData {
  // ItemVariationData
  // Type      Name            Description
  // uint16    itemCount       The number of delta sets for distinct items.
  // uint16    shortDeltaCount The number of short deltas in each delta set.
  // uint16    regionIndexCount The number of regions referenced.
  // uint16    regionIndices[regionIndexCount] Array of indices into the variation region list for the regions referenced by this ItemVariationData table.
  // uint8     deltaSets[]     Delta sets.

  int itemCount = 0;
  int shortDeltaCount = 0;
  int regionIndexCount = 0;
  List<int>? regionIndices;
  
  // We store the raw delta sets data or parsed?
  // C# implementation parses them on demand or stores them.
  // Let's store them as a list of DeltaSet for now, or just raw bytes if it's too complex.
  // The C# code seems to have `GetDeltaSet(int index)`.
  // Let's read all delta sets into memory.

  List<List<int>>? deltaSets;

  void readContent(ByteOrderSwappingBinaryReader reader) {
    itemCount = reader.readUInt16();
    shortDeltaCount = reader.readUInt16();
    regionIndexCount = reader.readUInt16();
    regionIndices = Utils.readUInt16Array(reader, regionIndexCount);

    // Read Delta Sets
    // The data is a sequence of (shortDeltaCount + (regionIndexCount - shortDeltaCount)) values per item.
    // shortDeltaCount values are int16, the rest are int8.
    // Wait, let's check the spec/C# code.
    
    // C# code:
    // for (int i = 0; i < itemCount; i++) {
    //    short[] deltas = new short[regionIndexCount];
    //    for (int j = 0; j < regionIndexCount; j++) {
    //        if (j < shortDeltaCount) deltas[j] = reader.ReadInt16();
    //        else deltas[j] = reader.ReadSByte();
    //    }
    // }

    deltaSets = List<List<int>>.generate(itemCount, (index) {
      List<int> deltas = List<int>.filled(regionIndexCount, 0);
      for (int j = 0; j < regionIndexCount; j++) {
        if (j < shortDeltaCount) {
          deltas[j] = reader.readInt16();
        } else {
          deltas[j] = reader.readSByte();
        }
      }
      return deltas;
    });
  }

  List<int> getDeltaSet(int index) {
    if (deltaSets != null && index >= 0 && index < deltaSets!.length) {
      return deltaSets![index];
    }
    return [];
  }
}
