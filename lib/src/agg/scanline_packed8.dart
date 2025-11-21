import 'dart:typed_data';

import 'package:agg/src/agg/interfaces/iscanline.dart';

/// General-purpose scanline container with packed spans and covers (u8).
class ScanlineCachePacked8 implements IScanlineCache {
  int _lastX = 0x7FFFFFF0;
  int _y = 0;
  late Uint8List _covers;
  late List<ScanlineSpan> _spans;
  int _coverIndex = 0;
  int _spanIndex = 0;
  int _iterIndex = 0;

  ScanlineCachePacked8() {
    _covers = Uint8List(1024);
    _spans = List<ScanlineSpan>.generate(1024, (_) => ScanlineSpan());
  }

  @override
  void reset(int min_x, int max_x) {
    final int maxLen = max_x - min_x + 3;
    if (maxLen > _spans.length) {
      _spans = List<ScanlineSpan>.generate(maxLen, (_) => ScanlineSpan());
      _covers = Uint8List(maxLen);
    }
    _lastX = 0x7FFFFFF0;
    _coverIndex = 0;
    _spanIndex = 0;
    _spans[_spanIndex].len = 0;
  }

  @override
  void add_cell(int x, int cover) {
    _covers[_coverIndex] = cover;
    if (x == _lastX + 1 && _spans[_spanIndex].len > 0) {
      _spans[_spanIndex].len++;
    } else {
      _spanIndex++;
      _spans[_spanIndex].cover_index = _coverIndex;
      _spans[_spanIndex].x = x;
      _spans[_spanIndex].len = 1;
    }
    _lastX = x;
    _coverIndex++;
  }

  @override
  void add_cells(int x, int len, Uint8List covers, int coversIndex) {
    for (int i = 0; i < len; i++) {
      _covers[_coverIndex + i] = covers[coversIndex + i];
    }

    if (x == _lastX + 1 && _spans[_spanIndex].len > 0) {
      _spans[_spanIndex].len += len;
    } else {
      _spanIndex++;
      _spans[_spanIndex].cover_index = _coverIndex;
      _spans[_spanIndex].x = x;
      _spans[_spanIndex].len = len;
    }

    _coverIndex += len;
    _lastX = x + len - 1;
  }

  @override
  void add_span(int x, int len, int cover) {
    _covers[_coverIndex] = cover;
    _spanIndex++;
    _spans[_spanIndex].cover = cover;
    _spans[_spanIndex].cover_index = _coverIndex;
    _spans[_spanIndex].x = x;
    _spans[_spanIndex].len = -len;
    _coverIndex++;
    _lastX = x + len - 1;
  }

  @override
  void finalize(int y) {
    _y = y;
  }

  @override
  void resetSpans() {
    _lastX = 0x7FFFFFF0;
    _coverIndex = 0;
    _spanIndex = 0;
    _spans[_spanIndex].len = 0;
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
  ScanlineSpan getNextScanlineSpan() {
    _iterIndex++;
    return _spans[_iterIndex - 1];
  }

  @override
  Uint8List getCovers() => _covers;
}
