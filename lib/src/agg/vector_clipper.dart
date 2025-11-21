import 'package:agg/src/agg/agg_basics.dart';
import 'package:agg/src/agg/agg_clip_liang_barsky.dart';
import 'package:agg/src/agg/rasterizer_cells_aa.dart';
import 'package:agg/src/agg/primitives/rectangle_int.dart';

/// Clip utility mirroring AGG's vector clipper (Liang–Barsky).
class VectorClipper {
  RectangleInt clipBox = RectangleInt(0, 0, 0, 0);
  int _x1 = 0;
  int _y1 = 0;
  int _f1 = 0;
  bool _clipping = false;

  int upscale(double v) =>
      Agg_basics.iround(v * poly_subpixel_scale_e.poly_subpixel_scale);

  int downscale(int v) => v ~/ poly_subpixel_scale_e.poly_subpixel_scale;

  void reset_clipping() {
    _clipping = false;
  }

  void clip_box(int x1, int y1, int x2, int y2) {
    clipBox = RectangleInt(x1, y1, x2, y2)..normalize();
    _clipping = true;
  }

  void move_to(int x1, int y1) {
    _x1 = x1;
    _y1 = y1;
    if (_clipping) {
      _f1 = ClipLiangBarsky.clippingFlags(x1, y1, clipBox);
    }
  }

  void _lineClipY(
    RasterizerCellsAa ras,
    int x1,
    int y1,
    int x2,
    int y2,
    int f1,
    int f2,
  ) {
    f1 &= 10; // keep only y bits
    f2 &= 10;
    if ((f1 | f2) == 0) {
      ras.line(x1, y1, x2, y2);
      return;
    }
    if (f1 == f2) return; // fully clipped by Y

    int tx1 = x1;
    int ty1 = y1;
    int tx2 = x2;
    int ty2 = y2;

    if ((f1 & 8) != 0) {
      // y1 < clip.bottom
      tx1 = x1 + _mulDiv(clipBox.bottom - y1, x2 - x1, y2 - y1);
      ty1 = clipBox.bottom;
    }
    if ((f1 & 2) != 0) {
      // y1 > clip.top
      tx1 = x1 + _mulDiv(clipBox.top - y1, x2 - x1, y2 - y1);
      ty1 = clipBox.top;
    }
    if ((f2 & 8) != 0) {
      tx2 = x1 + _mulDiv(clipBox.bottom - y1, x2 - x1, y2 - y1);
      ty2 = clipBox.bottom;
    }
    if ((f2 & 2) != 0) {
      tx2 = x1 + _mulDiv(clipBox.top - y1, x2 - x1, y2 - y1);
      ty2 = clipBox.top;
    }
    ras.line(tx1, ty1, tx2, ty2);
  }

  void line_to(RasterizerCellsAa ras, int x2, int y2) {
    if (_clipping) {
      final int f2 = ClipLiangBarsky.clippingFlags(x2, y2, clipBox);

      if ((_f1 & 10) == (f2 & 10) && (_f1 & 10) != 0) {
        // Invisible by Y, skip quickly
        _x1 = x2;
        _y1 = y2;
        _f1 = f2;
        return;
      }

      int x1 = _x1;
      int y1 = _y1;
      int f1 = _f1;
      late int y3, y4, f3, f4;

      switch (((f1 & 5) << 1) | (f2 & 5)) {
        case 0: // visible by X
          _lineClipY(ras, x1, y1, x2, y2, f1, f2);
          break;
        case 1: // x2 > clip.right
          y3 = y1 + _mulDiv(clipBox.right - x1, y2 - y1, x2 - x1);
          f3 = ClipLiangBarsky.clippingFlagsY(y3, clipBox);
          _lineClipY(ras, x1, y1, clipBox.right, y3, f1, f3);
          _lineClipY(ras, clipBox.right, y3, clipBox.right, y2, f3, f2);
          break;
        case 2: // x1 > clip.right
          y3 = y1 + _mulDiv(clipBox.right - x1, y2 - y1, x2 - x1);
          f3 = ClipLiangBarsky.clippingFlagsY(y3, clipBox);
          _lineClipY(ras, clipBox.right, y1, clipBox.right, y3, f1, f3);
          _lineClipY(ras, clipBox.right, y3, x2, y2, f3, f2);
          break;
        case 3: // x1 > clip.right && x2 > clip.right
          _lineClipY(ras, clipBox.right, y1, clipBox.right, y2, f1, f2);
          break;
        case 4: // x2 < clip.left
          y3 = y1 + _mulDiv(clipBox.left - x1, y2 - y1, x2 - x1);
          f3 = ClipLiangBarsky.clippingFlagsY(y3, clipBox);
          _lineClipY(ras, x1, y1, clipBox.left, y3, f1, f3);
          _lineClipY(ras, clipBox.left, y3, clipBox.left, y2, f3, f2);
          break;
        case 6: // x1 > clip.right && x2 < clip.left
          y3 = y1 + _mulDiv(clipBox.right - x1, y2 - y1, x2 - x1);
          y4 = y1 + _mulDiv(clipBox.left - x1, y2 - y1, x2 - x1);
          f3 = ClipLiangBarsky.clippingFlagsY(y3, clipBox);
          f4 = ClipLiangBarsky.clippingFlagsY(y4, clipBox);
          _lineClipY(ras, clipBox.right, y1, clipBox.right, y3, f1, f3);
          _lineClipY(ras, clipBox.right, y3, clipBox.left, y4, f3, f4);
          _lineClipY(ras, clipBox.left, y4, clipBox.left, y2, f4, f2);
          break;
        case 8: // x1 < clip.left
          y3 = y1 + _mulDiv(clipBox.left - x1, y2 - y1, x2 - x1);
          f3 = ClipLiangBarsky.clippingFlagsY(y3, clipBox);
          _lineClipY(ras, clipBox.left, y1, clipBox.left, y3, f1, f3);
          _lineClipY(ras, clipBox.left, y3, x2, y2, f3, f2);
          break;
        case 9: // x1 < clip.left && x2 > clip.right
          y3 = y1 + _mulDiv(clipBox.left - x1, y2 - y1, x2 - x1);
          y4 = y1 + _mulDiv(clipBox.right - x1, y2 - y1, x2 - x1);
          f3 = ClipLiangBarsky.clippingFlagsY(y3, clipBox);
          f4 = ClipLiangBarsky.clippingFlagsY(y4, clipBox);
          _lineClipY(ras, clipBox.left, y1, clipBox.left, y3, f1, f3);
          _lineClipY(ras, clipBox.left, y3, clipBox.right, y4, f3, f4);
          _lineClipY(ras, clipBox.right, y4, clipBox.right, y2, f4, f2);
          break;
        case 12: // x1 < clip.left && x2 < clip.left
          _lineClipY(ras, clipBox.left, y1, clipBox.left, y2, f1, f2);
          break;
      }
      _f1 = f2;
    } else {
      ras.line(_x1, _y1, x2, y2);
    }

    _x1 = x2;
    _y1 = y2;
  }

  int _mulDiv(int a, int b, int c) => Agg_basics.iround(a * b / c);
}
