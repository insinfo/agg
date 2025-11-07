// Apache2, 2017-present, WinterDev
// Apache2, 2014-2016, Samuel Carlsson, WinterDev
// Ported to Dart by insinfo

import '../../../typography/io/byte_order_swapping_reader.dart';
import '../../../typography/openfont/tables/table_entry.dart';

/// Horizontal Header Table ('hhea')
/// This table contains information for horizontal layout
class HorizontalHeader extends TableEntry {
  static const String tableName = 'hhea';

  @override
  String get name => tableName;

  int version = 0;
  int ascent = 0;
  int descent = 0;
  int lineGap = 0;
  int advancedWidthMax = 0;
  int minLeftSideBearing = 0;
  int minRightSideBearing = 0;
  int maxXExtent = 0;
  int caretSlopeRise = 0;
  int caretSlopeRun = 0;
  int metricDataFormat = 0;
  int horizontalMetricsCount = 0;

  HorizontalHeader();

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    version = reader.readUInt32(); // Major + minor version
    ascent = reader.readInt16(); // Typographic ascent
    descent = reader.readInt16(); // Typographic descent
    lineGap = reader.readInt16(); // Typographic line gap
    advancedWidthMax = reader.readUInt16(); // Maximum advance width value in 'hmtx' table
    minLeftSideBearing = reader.readInt16(); // Minimum left sidebearing value in 'hmtx' table
    minRightSideBearing = reader.readInt16(); // Minimum right sidebearing value
    maxXExtent = reader.readInt16(); // Max(lsb + (xMax - xMin))
    caretSlopeRise = reader.readInt16(); // Used to calculate the slope of the cursor
    caretSlopeRun = reader.readInt16(); // 0 for vertical
    
    // Caret offset - amount by which a slanted highlight needs to be shifted
    reader.readInt16(); // caretOffset
    
    // Reserved fields (should be 0)
    reader.readInt16(); // reserved
    reader.readInt16(); // reserved
    reader.readInt16(); // reserved
    reader.readInt16(); // reserved
    
    metricDataFormat = reader.readInt16(); // 0 for current format
    horizontalMetricsCount = reader.readUInt16(); // Number of hMetric entries in 'hmtx' table
  }

  @override
  String toString() => 'HorizontalHeader(ascent: $ascent, descent: $descent, lineGap: $lineGap)';
}
