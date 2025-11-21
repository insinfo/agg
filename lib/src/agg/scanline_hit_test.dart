import 'dart:typed_data';

import 'package:agg/src/agg/interfaces/iscanline.dart';

/// Simple scanline cache that only checks whether an x coordinate was hit.
class ScanlineHitTest implements IScanlineCache {
  final int _x;
  bool _hit = false;

  ScanlineHitTest(this._x);

  bool hit() => _hit;

  @override
  void add_cell(int x, int cover) {
    if (_x == x) _hit = true;
  }

  @override
  void add_span(int x, int len, int cover) {
    if (_x >= x && _x < x + len) _hit = true;
  }

  @override
  void add_cells(int x, int len, Uint8List covers, int coversIndex) {
    add_span(x, len, 0);
  }

  @override
  void finalize(int y) {}

  @override
  void reset(int min_x, int max_x) {}

  @override
  void resetSpans() {}

  @override
  int num_spans() => 1;

  @override
  ScanlineSpan begin() =>
      (ScanlineSpan()..x = _x..len = 1..cover_index = 0);

  @override
  ScanlineSpan getNextScanlineSpan() => begin();

  @override
  int y() => 0;

  @override
  Uint8List getCovers() => Uint8List(0);
}
