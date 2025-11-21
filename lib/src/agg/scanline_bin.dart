import 'dart:typed_data';

import 'package:agg/src/agg/interfaces/iscanline.dart';

/// Binary scanline cache (no cover values) mirroring AGG scanline_bin.
class ScanlineBin implements IScanlineCache {
  int _lastX = 0x7FFFFFF0;
  int _y = 0;
  final List<ScanlineSpan> _spans = List<ScanlineSpan>.filled(1024, ScanlineSpan());
  int _spanIndex = 0;
  int _iterIndex = 0;

  @override
  void reset(int min_x, int max_x) {
    final int maxLen = max_x - min_x + 3;
    if (maxLen > _spans.length) {
      _spans.length = maxLen;
      for (int i = 0; i < _spans.length; i++) {
        _spans[i] = ScanlineSpan();
      }
    }
    _lastX = 0x7FFFFFF0;
    _spanIndex = 0;
  }

  @override
  void add_cell(int x, int cover) {
    if (x == _lastX + 1) {
      _spans[_spanIndex].len++;
    } else {
      _spanIndex++;
      _spans[_spanIndex].x = x;
      _spans[_spanIndex].len = 1;
    }
    _lastX = x;
  }

  @override
  void add_cells(int x, int len, Uint8List covers, int coversIndex) {
    add_span(x, len, 0);
  }

  @override
  void add_span(int x, int len, int cover) {
    if (x == _lastX + 1) {
      _spans[_spanIndex].len += len;
    } else {
      _spanIndex++;
      _spans[_spanIndex].x = x;
      _spans[_spanIndex].len = len;
      _spans[_spanIndex].cover = cover;
    }
    _lastX = x + len - 1;
  }

  @override
  void finalize(int y) {
    _y = y;
  }

  @override
  @override
  void resetSpans() {
    _lastX = 0x7FFFFFF0;
    _spanIndex = 0;
  }

  @override
  int y() => _y;

  @override
  int num_spans() => _spanIndex;

  @override
  ScanlineSpan begin() {
    _iterIndex = 1;
    return getNextScanlineSpan();
  }

  @override
  @override
  ScanlineSpan getNextScanlineSpan() {
    _iterIndex++;
    return _spans[_iterIndex - 1];
  }

  @override
  Uint8List getCovers() => Uint8List(0);
}
