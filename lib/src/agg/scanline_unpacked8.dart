import 'dart:typed_data';

import 'package:agg/src/agg/interfaces/iscanline.dart';

/// Unpacked scanline container with per-pixel covers (u8).
class ScanlineUnpacked8 implements IScanlineCache {
  int _minX = 0;
  int _lastX = 0x7FFFFFF0;
  int _y = 0;
  late Uint8List _covers;
  late List<ScanlineSpan> _spans;
  int _spanIndex = 0;
  int _iterIndex = 0;

  ScanlineUnpacked8() {
    _covers = Uint8List(1024);
    _spans = List<ScanlineSpan>.generate(1024, (_) => ScanlineSpan());
  }

  @override
  void reset(int min_x, int max_x) {
    final int maxLen = max_x - min_x + 2;
    if (maxLen > _spans.length) {
      _spans = List<ScanlineSpan>.generate(maxLen, (_) => ScanlineSpan());
      _covers = Uint8List(maxLen);
    }
    _lastX = 0x7FFFFFF0;
    _minX = min_x;
    _spanIndex = 0;
  }

  @override
  void add_cell(int x, int cover) {
    x -= _minX;
    _covers[x] = cover;
    if (x == _lastX + 1) {
      _spans[_spanIndex].len++;
    } else {
      _spanIndex++;
      _spans[_spanIndex].x = x + _minX;
      _spans[_spanIndex].len = 1;
      _spans[_spanIndex].cover_index = x;
    }
    _lastX = x;
  }

  @override
  void add_cells(int x, int len, Uint8List covers, int coversIndex) {
    x -= _minX;
    for (int i = 0; i < len; i++) {
      _covers[x + i] = covers[coversIndex + i];
    }
    if (x == _lastX + 1) {
      _spans[_spanIndex].len += len;
    } else {
      _spanIndex++;
      _spans[_spanIndex].x = x + _minX;
      _spans[_spanIndex].len = len;
      _spans[_spanIndex].cover_index = x;
    }
    _lastX = x + len - 1;
  }

  @override
  void add_span(int x, int len, int cover) {
    x -= _minX;
    for (int i = 0; i < len; i++) {
      _covers[x + i] = cover;
    }

    if (x == _lastX + 1) {
      _spans[_spanIndex].len += len;
    } else {
      _spanIndex++;
      _spans[_spanIndex].x = x + _minX;
      _spans[_spanIndex].len = len;
      _spans[_spanIndex].cover_index = x;
    }
    _lastX = x + len - 1;
  }

  @override
  void finalize(int y) {
    _y = y;
  }

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
  ScanlineSpan getNextScanlineSpan() {
    _iterIndex++;
    return _spans[_iterIndex - 1];
  }

  @override
  Uint8List getCovers() => _covers.sublist(0); // return backing covers
}
