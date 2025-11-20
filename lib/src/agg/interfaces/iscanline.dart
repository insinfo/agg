import 'dart:typed_data';

class ScanlineSpan {
  int x = 0;
  int len = 0;
  int cover_index = 0;
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
