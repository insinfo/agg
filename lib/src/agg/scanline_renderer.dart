import 'package:agg/src/agg/interfaces/iscanline.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/image/iimage.dart';

/// Helpers to render scanlines into an image buffer.
class ScanlineRenderer {
  static void renderSolid(IRasterizer ras, IScanlineCache sl, IImageByte img, Color color) {
    ras.rewind_scanlines();
    sl.reset(ras.min_x(), ras.max_x());
    while (ras.sweep_scanline(sl)) {
      final int y = sl.y();
      if (y < 0 || y >= img.height) continue;
      final covers = sl.getCovers();
      var span = sl.begin();
      for (int i = 0; i < sl.num_spans(); i++) {
        if (span.len > 0) {
          int x0 = span.x;
          int len = span.len;
          int coverIndex = span.cover_index;
          if (x0 < 0) {
            coverIndex += -x0;
            len += x0;
            x0 = 0;
          }
          if (x0 + len > img.width) {
            len = img.width - x0;
          }
          if (len > 0) {
            img.blend_solid_hspan(x0, y, len, color, covers, coverIndex);
          }
        }
        if (i + 1 < sl.num_spans()) {
          span = sl.getNextScanlineSpan();
        }
      }
    }
  }
}
