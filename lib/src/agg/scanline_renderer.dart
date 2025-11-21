import 'dart:typed_data';

import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/interfaces/iscanline.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/spans/span_allocator.dart';
import 'package:agg/src/agg/spans/span_generator.dart';

/// Helpers to render scanlines into an image buffer.
class ScanlineRenderer {
  static void renderSolid(IRasterizer ras, IScanlineCache sl, IImageByte img, Color color) {
    if (!ras.rewind_scanlines()) return;
    sl.reset(ras.min_x(), ras.max_x());
    while (ras.sweep_scanline(sl)) {
      _renderSolidSingleScanline(sl, img, color);
    }
  }

  /// Generates spans via [generator] and blends them into [img].
  static void generateAndRender(
    IRasterizer ras,
    IScanlineCache sl,
    IImageByte img,
    SpanAllocator alloc,
    ISpanGenerator generator,
  ) {
    if (!ras.rewind_scanlines()) return;
    sl.reset(ras.min_x(), ras.max_x());
    generator.prepare();
    while (ras.sweep_scanline(sl)) {
      _generateAndRenderSingleScanline(sl, img, alloc, generator);
    }
  }

  static void _renderSolidSingleScanline(IScanlineCache sl, IImageByte img, Color color) {
    final int y = sl.y();
    if (y < 0 || y >= img.height) return;

    final Uint8List covers = sl.getCovers();
    ScanlineSpan span = sl.begin();
    int remaining = sl.num_spans();
    while (true) {
      final int spanLen = span.len;
      if (spanLen > 0) {
        _blendClippedSolidSpan(img, color, covers, span.x, spanLen, span.cover_index, y);
      } else if (spanLen < 0) {
        _blendClippedHLine(img, color, covers[span.cover_index], span.x, -spanLen, y);
      }

      if (--remaining == 0) break;
      span = sl.getNextScanlineSpan();
    }
  }

  static void _blendClippedSolidSpan(
    IImageByte img,
    Color color,
    Uint8List covers,
    int x,
    int len,
    int coverIndex,
    int y,
  ) {
    if (len <= 0 || x >= img.width || y < 0 || y >= img.height) return;
    int startX = x;
    int startCover = coverIndex;
    if (startX < 0) {
      startCover -= startX;
      len += startX;
      startX = 0;
    }
    if (startX >= img.width) return;
    int maxLen = img.width - startX;
    if (len > maxLen) len = maxLen;
    if (len > 0) {
      img.blend_solid_hspan(startX, y, len, color, covers, startCover);
    }
  }

  static void _blendClippedHLine(IImageByte img, Color color, int cover, int x, int len, int y) {
    if (len <= 0 || x >= img.width || y < 0 || y >= img.height) return;
    int startX = x;
    int endX = x + len - 1;
    if (startX < 0) startX = 0;
    if (endX >= img.width) endX = img.width - 1;
    if (endX >= startX) img.blend_hline(startX, y, endX, color, cover);
  }

  static void _generateAndRenderSingleScanline(
    IScanlineCache sl,
    IImageByte img,
    SpanAllocator alloc,
    ISpanGenerator generator,
  ) {
    final int y = sl.y();
    if (y < 0 || y >= img.height) return;

    final Uint8List covers = sl.getCovers();
    ScanlineSpan span = sl.begin();
    int remaining = sl.num_spans();
    while (true) {
      int x = span.x;
      int len = span.len;
      final bool firstCoverForAll = len < 0;
      if (len < 0) len = -len;

      if (len > 0) {
        final List<Color> colors = alloc.allocate(len);
        generator.generate(colors, 0, x, y, len);
        _blendGeneratedSpan(img, colors, covers, x, y, len, span.cover_index, firstCoverForAll);
      }

      if (--remaining == 0) break;
      span = sl.getNextScanlineSpan();
    }
  }

  static void _blendGeneratedSpan(
    IImageByte img,
    List<Color> colors,
    Uint8List covers,
    int x,
    int y,
    int len,
    int coverIndex,
    bool firstCoverForAll,
  ) {
    if (y < 0 || y >= img.height || len <= 0) return;

    int startX = x;
    int startCoverIndex = coverIndex;
    if (startX < 0) {
      len += startX;
      startCoverIndex -= startX;
      startX = 0;
    }
    if (startX >= img.width) return;
    int maxLen = img.width - startX;
    if (len > maxLen) len = maxLen;
    if (len <= 0) return;

    img.blend_color_hspan(startX, y, len, colors, 0, covers, startCoverIndex, firstCoverForAll);
  }
}
