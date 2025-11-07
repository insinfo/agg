// Apache2, 2017-present, WinterDev
// Apache2, 2014-2016, Samuel Carlsson, WinterDev
// Ported to Dart by insinfo

import '../../../typography/io/byte_order_swapping_reader.dart';
import '../../../typography/openfont/tables/table_entry.dart';

/// Horizontal Metrics Table ('hmtx')
/// Contains metrics for horizontal layout of glyphs
/// 
/// For any glyph:
/// - xMax and xMin are in 'glyf' table
/// - lsb (left side bearing) and aw (advance width) are in 'hmtx' table
/// - rsb (right side bearing) = aw - (lsb + xMax - xMin)
class HorizontalMetrics extends TableEntry {
  static const String tableName = 'hmtx';

  @override
  String get name => tableName;

  final List<int> _advanceWidths = []; // in font design units
  final List<int> _leftSideBearings = []; // lsb, in font design units
  final int _numOfHMetrics;
  final int _numGlyphs;

  /// Create horizontal metrics table
  /// [numOfHMetrics] comes from the 'hhea' table
  /// [numGlyphs] comes from the 'maxp' table
  HorizontalMetrics(this._numOfHMetrics, this._numGlyphs);

  /// Get advance width for a glyph by index
  int getAdvanceWidth(int index) {
    if (index < 0 || index >= _advanceWidths.length) {
      return 0;
    }
    return _advanceWidths[index];
  }

  /// Get left side bearing for a glyph by index
  int getLeftSideBearing(int index) {
    if (index < 0 || index >= _leftSideBearings.length) {
      return 0;
    }
    return _leftSideBearings[index];
  }

  /// Get both horizontal metrics for a glyph
  /// Returns (advanceWidth, leftSideBearing)
  (int advanceWidth, int leftSideBearing) getHMetric(int index) {
    return (getAdvanceWidth(index), getLeftSideBearing(index));
  }

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    // 1. hMetrics: have both advance width and leftSideBearing (lsb)
    // Paired advance width and left side bearing values for each glyph.
    // If the font is monospaced, only one entry need be in the array,
    // but that entry is required. The last entry applies to all subsequent glyphs.
    
    for (var i = 0; i < _numOfHMetrics; i++) {
      _advanceWidths.add(reader.readUInt16());
      _leftSideBearings.add(reader.readInt16());
    }

    // 2. (only) LeftSideBearing: (same advanced width, vary only left side bearing)
    // Here the advanceWidth is assumed to be the same as the advanceWidth for the last entry above.
    // The number of entries in this array is derived from numGlyphs (from 'maxp' table) minus numberOfHMetrics.
    
    final nEntries = _numGlyphs - _numOfHMetrics;
    if (nEntries > 0 && _advanceWidths.isNotEmpty) {
      final advanceWidth = _advanceWidths[_numOfHMetrics - 1];
      
      for (var i = 0; i < nEntries; i++) {
        _advanceWidths.add(advanceWidth);
        _leftSideBearings.add(reader.readInt16());
      }
    }
  }

  /// Total number of glyphs with metrics
  int get glyphCount => _advanceWidths.length;

  @override
  String toString() => 'HorizontalMetrics(glyphs: $glyphCount, hMetrics: $_numOfHMetrics)';
}
