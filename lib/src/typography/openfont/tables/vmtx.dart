// MIT, 2019-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../../io/byte_order_swapping_reader.dart';
import 'table_entry.dart';

/// vmtx - Vertical Metrics Table
class VerticalMetrics extends TableEntry {
  static const String _N = "vmtx";
  @override
  String get name => _N;

  final int _numOfLongVerMetrics;
  final int _numGlyphs;
  
  List<AdvanceHeightAndTopSideBearing>? _advHeightAndTopSideBearings;
  List<int>? _topSideBearings;

  VerticalMetrics(this._numOfLongVerMetrics, this._numGlyphs);

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    _advHeightAndTopSideBearings = List<AdvanceHeightAndTopSideBearing>.generate(
      _numOfLongVerMetrics,
      (index) => AdvanceHeightAndTopSideBearing(
        reader.readUInt16(),
        reader.readInt16(),
      ),
    );

    // Read remaining top side bearings
    int remainingGlyphs = _numGlyphs - _numOfLongVerMetrics;
    if (remainingGlyphs > 0) {
      _topSideBearings = List<int>.generate(
        remainingGlyphs,
        (index) => reader.readInt16(),
      );
    }
  }

  int getAdvanceHeight(int glyphIndex) {
    if (_advHeightAndTopSideBearings == null) return 0;
    
    if (glyphIndex < _numOfLongVerMetrics) {
      return _advHeightAndTopSideBearings![glyphIndex].advanceHeight;
    }
    
    // For glyphs beyond numOfLongVerMetrics, use the advance height of the last entry
    if (_numOfLongVerMetrics > 0) {
      return _advHeightAndTopSideBearings![_numOfLongVerMetrics - 1].advanceHeight;
    }
    
    return 0;
  }

  int getTopSideBearing(int glyphIndex) {
    if (_advHeightAndTopSideBearings == null) return 0;

    if (glyphIndex < _numOfLongVerMetrics) {
      return _advHeightAndTopSideBearings![glyphIndex].topSideBearing;
    }

    // For glyphs beyond numOfLongVerMetrics, look in the second array
    if (_topSideBearings != null) {
      int index = glyphIndex - _numOfLongVerMetrics;
      if (index < _topSideBearings!.length) {
        return _topSideBearings![index];
      }
    }

    return 0;
  }
}

class AdvanceHeightAndTopSideBearing {
  final int advanceHeight;
  final int topSideBearing;

  AdvanceHeightAndTopSideBearing(this.advanceHeight, this.topSideBearing);

  @override
  String toString() => '$advanceHeight,$topSideBearing';
}
