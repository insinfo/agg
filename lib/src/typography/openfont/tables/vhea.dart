// MIT, 2019-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../../io/byte_order_swapping_reader.dart';
import 'table_entry.dart';

/// vhea — Vertical Header Table
class VerticalHeader extends TableEntry {
  static const String _N = "vhea";
  @override
  String get name => _N;

  int versionMajor = 0;
  int versionMinor = 0;
  int vertTypoAscender = 0;
  int vertTypoDescender = 0;
  int vertTypoLineGap = 0;
  
  int advanceHeightMax = 0;
  int minTopSideBearing = 0;
  int minBottomSideBearing = 0;
  
  int yMaxExtend = 0;
  int caretSlopeRise = 0;
  int caretSlopeRun = 0;
  int caretOffset = 0;
  int numOfLongVerMetrics = 0;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    int version = reader.readUInt32();
    versionMajor = (version >> 16) & 0xFFFF;
    versionMinor = version & 0xFFFF;

    vertTypoAscender = reader.readInt16();
    vertTypoDescender = reader.readInt16();
    vertTypoLineGap = reader.readInt16();
    
    advanceHeightMax = reader.readInt16();
    minTopSideBearing = reader.readInt16();
    minBottomSideBearing = reader.readInt16();
    
    yMaxExtend = reader.readInt16();
    caretSlopeRise = reader.readInt16();
    caretSlopeRun = reader.readInt16();
    caretOffset = reader.readInt16();
    
    // skip 5 int16 =>  4 reserve field + 1 metricDataFormat            
    reader.skip(2 * (4 + 1)); // short = 2 byte
    
    numOfLongVerMetrics = reader.readUInt16();
  }
}
