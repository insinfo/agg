import 'dart:typed_data';

class ScanlineSpan {
  int x;
  int len;
  int cover_index;
}

abstract class IScanlineCache {
  void finalize(int y);

  void reset(int min_x, int max_x);

  void resetSpans();

  int num_spans();

  ScanlineSpan begin();

  ScanlineSpan getNextScanlineSpan();

  int y();

  ///byte[] GetCovers();
  Uint8List getCovers();

  void add_cell(int x, int cover);

  void add_span(int x, int len, int cover);
}
