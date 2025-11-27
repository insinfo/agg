import 'dart:typed_data';
import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/image/image_proxy.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/primitives/rectangle_int.dart';

class ImageClippingProxy extends ImageProxy {
  late RectangleInt m_ClippingRect;

  static const int coverFull = 255;

  ImageClippingProxy(IImageByte ren) : super(ren) {
    m_ClippingRect = RectangleInt(0, 0, ren.width - 1, ren.height - 1);
  }

  @override
  void linkToImage(IImageByte ren) {
    super.linkToImage(ren);
    m_ClippingRect = RectangleInt(0, 0, ren.width - 1, ren.height - 1);
  }

  bool setClippingBox(int x1, int y1, int x2, int y2) {
    RectangleInt cb = RectangleInt(x1, y1, x2, y2);
    cb.normalize();
    if (cb.clip(RectangleInt(0, 0, width - 1, height - 1))) {
      m_ClippingRect = cb;
      return true;
    }
    m_ClippingRect.left = 1;
    m_ClippingRect.bottom = 1;
    m_ClippingRect.right = 0;
    m_ClippingRect.top = 0;
    return false;
  }

  void resetClipping(bool visibility) {
    if (visibility) {
      m_ClippingRect.left = 0;
      m_ClippingRect.bottom = 0;
      m_ClippingRect.right = width - 1;
      m_ClippingRect.top = height - 1;
    } else {
      m_ClippingRect.left = 1;
      m_ClippingRect.bottom = 1;
      m_ClippingRect.right = 0;
      m_ClippingRect.top = 0;
    }
  }

  bool inbox(int x, int y) {
    return x >= m_ClippingRect.left && y >= m_ClippingRect.bottom &&
           x <= m_ClippingRect.right && y <= m_ClippingRect.top;
  }

  RectangleInt clipBox() {
    return m_ClippingRect;
  }

  int xmin() => m_ClippingRect.left;
  int ymin() => m_ClippingRect.bottom;
  int xmax() => m_ClippingRect.right;
  int ymax() => m_ClippingRect.top;

  void clear(Color in_c) {
    if (width != 0) {
      for (int y = 0; y < height; y++) {
        super.copy_hline(0, y, width, in_c);
      }
    }
  }

  @override
  void copy_pixel(int x, int y, Uint8List c, int ByteOffset) {
    if (inbox(x, y)) {
      super.copy_pixel(x, y, c, ByteOffset);
    }
  }

  @override
  Color getPixel(int x, int y) {
    return inbox(x, y) ? super.getPixel(x, y) : Color(0, 0, 0, 0);
  }

  @override
  void copy_hline(int x1, int y, int x2, Color c) {
    if (x1 > x2) { int t = x2; x2 = x1; x1 = t; }
    if (y > ymax()) return;
    if (y < ymin()) return;
    if (x1 > xmax()) return;
    if (x2 < xmin()) return;

    if (x1 < xmin()) x1 = xmin();
    if (x2 > xmax()) x2 = xmax();

    super.copy_hline(x1, y, (x2 - x1 + 1), c);
  }

  @override
  void copy_vline(int x, int y1, int y2, Color c) {
    if (y1 > y2) { int t = y2; y2 = y1; y1 = t; }
    if (x > xmax()) return;
    if (x < xmin()) return;
    if (y1 > ymax()) return;
    if (y2 < ymin()) return;

    if (y1 < ymin()) y1 = ymin();
    if (y2 > ymax()) y2 = ymax();

    super.copy_vline(x, y1, (y2 - y1 + 1), c);
  }

  @override
  void blend_hline(int x1, int y, int x2, Color c, int cover) {
    if (x1 > x2) { int t = x2; x2 = x1; x1 = t; }
    if (y > ymax()) return;
    if (y < ymin()) return;
    if (x1 > xmax()) return;
    if (x2 < xmin()) return;

    if (x1 < xmin()) x1 = xmin();
    if (x2 > xmax()) x2 = xmax();

    super.blend_hline(x1, y, x2, c, cover);
  }

  @override
  void blend_vline(int x, int y1, int y2, Color c, int cover) {
    if (y1 > y2) { int t = y2; y2 = y1; y1 = t; }
    if (x > xmax()) return;
    if (x < xmin()) return;
    if (y1 > ymax()) return;
    if (y2 < ymin()) return;

    if (y1 < ymin()) y1 = ymin();
    if (y2 > ymax()) y2 = ymax();

    super.blend_vline(x, y1, y2, c, cover);
  }

  @override
  void blend_solid_hspan(int x, int y, int len, Color c, Uint8List covers, int coversIndex) {
    if (y > ymax()) return;
    if (y < ymin()) return;

    if (x < xmin()) {
      len -= xmin() - x;
      if (len <= 0) return;
      coversIndex += xmin() - x;
      x = xmin();
    }
    if (x + len > xmax()) {
      len = xmax() - x + 1;
      if (len <= 0) return;
    }
    super.blend_solid_hspan(x, y, len, c, covers, coversIndex);
  }

  @override
  void blend_solid_vspan(int x, int y, int len, Color c, Uint8List covers, int coversIndex) {
    if (x > xmax()) return;
    if (x < xmin()) return;

    if (y < ymin()) {
      len -= (ymin() - y);
      if (len <= 0) return;
      coversIndex += ymin() - y;
      y = ymin();
    }
    if (y + len > ymax()) {
      len = (ymax() - y + 1);
      if (len <= 0) return;
    }
    super.blend_solid_vspan(x, y, len, c, covers, coversIndex);
  }

  @override
  void copy_color_hspan(int x, int y, int len, List<Color> colors, int colorsIndex) {
    if (y > ymax()) return;
    if (y < ymin()) return;

    if (x < xmin()) {
      int d = xmin() - x;
      len -= d;
      if (len <= 0) return;
      colorsIndex += d;
      x = xmin();
    }
    if (x + len > xmax()) {
      len = (xmax() - x + 1);
      if (len <= 0) return;
    }
    super.copy_color_hspan(x, y, len, colors, colorsIndex);
  }

  @override
  void copy_color_vspan(int x, int y, int len, List<Color> colors, int colorsIndex) {
    if (x > xmax()) return;
    if (x < xmin()) return;

    if (y < ymin()) {
      int d = ymin() - y;
      len -= d;
      if (len <= 0) return;
      colorsIndex += d;
      y = ymin();
    }
    if (y + len > ymax()) {
      len = (ymax() - y + 1);
      if (len <= 0) return;
    }
    super.copy_color_vspan(x, y, len, colors, colorsIndex);
  }

  @override
  void blend_color_hspan(int x, int y, int in_len, List<Color> colors, int colorsIndex, Uint8List covers, int coversIndex, bool firstCoverForAll) {
    int len = in_len;
    if (y > ymax()) return;
    if (y < ymin()) return;

    if (x < xmin()) {
      int d = xmin() - x;
      len -= d;
      if (len <= 0) return;
      coversIndex += d;
      colorsIndex += d;
      x = xmin();
    }
    if (x + len - 1 > xmax()) {
      len = xmax() - x + 1;
      if (len <= 0) return;
    }

    super.blend_color_hspan(x, y, len, colors, colorsIndex, covers, coversIndex, firstCoverForAll);
  }

  @override
  void blend_color_vspan(int x, int y, int len, List<Color> colors, int colorsIndex, Uint8List covers, int coversIndex, bool firstCoverForAll) {
    if (x > xmax()) return;
    if (x < xmin()) return;

    if (y < ymin()) {
      int d = ymin() - y;
      len -= d;
      if (len <= 0) return;
      coversIndex += d;
      colorsIndex += d;
      y = ymin();
    }
    if (y + len > ymax()) {
      len = (ymax() - y + 1);
      if (len <= 0) return;
    }
    super.blend_color_vspan(x, y, len, colors, colorsIndex, covers, coversIndex, firstCoverForAll);
  }

  void copyFrom(IImageByte src) {
    CopyFrom2(src, RectangleInt(0, 0, src.width, src.height), 0, 0);
  }

  @override
  void SetPixel(int x, int y, Color color) {
    if (x >= 0 && x < width && y >= 0 && y < height) {
      super.SetPixel(x, y, color);
    }
  }

  @override
  void CopyFrom2(IImageByte sourceImage, RectangleInt sourceImageRect, int destXOffset, int destYOffset) {
    RectangleInt destRect = sourceImageRect;
    destRect.Offset(destXOffset, destYOffset);

    RectangleInt clippedSourceRect = RectangleInt(0,0,0,0);
    if (clippedSourceRect.IntersectRectangles(destRect, m_ClippingRect)) {
      // move it back relative to the source
      clippedSourceRect.Offset(-destXOffset, -destYOffset);

      super.CopyFrom2(sourceImage, clippedSourceRect, destXOffset, destYOffset);
    }
  }
}
