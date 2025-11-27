import 'dart:typed_data';
import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/image/image_proxy.dart';
import 'package:agg/src/agg/primitives/color.dart';

class FormatTransposer extends ImageProxy {
  FormatTransposer(IImageByte linkedImage) : super(linkedImage);

  @override
  int get width => linkedImage.height;

  @override
  int get height => linkedImage.width;

  @override
  Color getPixel(int x, int y) {
    return linkedImage.getPixel(y, x);
  }

  @override
  void copy_pixel(int x, int y, Uint8List c, int ByteOffset) {
    linkedImage.copy_pixel(y, x, c, ByteOffset);
  }

  @override
  void copy_hline(int x, int y, int len, Color c) {
    linkedImage.copy_vline(y, x, len, c);
  }

  @override
  void copy_vline(int x, int y, int len, Color c) {
    linkedImage.copy_hline(y, x, len, c);
  }

  @override
  void blend_hline(int x1, int y, int x2, Color c, int cover) {
    linkedImage.blend_vline(y, x1, x2, c, cover);
  }

  @override
  void blend_vline(int x, int y1, int y2, Color c, int cover) {
    linkedImage.blend_hline(y1, x, y2, c, cover);
  }

  @override
  void blend_solid_hspan(int x, int y, int len, Color c, Uint8List covers, int coversIndex) {
    linkedImage.blend_solid_vspan(y, x, len, c, covers, coversIndex);
  }

  @override
  void blend_solid_vspan(int x, int y, int len, Color c, Uint8List covers, int coversIndex) {
    linkedImage.blend_solid_hspan(y, x, len, c, covers, coversIndex);
  }

  @override
  void copy_color_hspan(int x, int y, int len, List<Color> colors, int colorsIndex) {
    linkedImage.copy_color_vspan(y, x, len, colors, colorsIndex);
  }

  @override
  void copy_color_vspan(int x, int y, int len, List<Color> colors, int colorsIndex) {
    linkedImage.copy_color_hspan(y, x, len, colors, colorsIndex);
  }

  @override
  void blend_color_hspan(int x, int y, int len, List<Color> colors, int colorsIndex, Uint8List covers, int coversIndex, bool firstCoverForAll) {
    linkedImage.blend_color_vspan(y, x, len, colors, colorsIndex, covers, coversIndex, firstCoverForAll);
  }

  @override
  void blend_color_vspan(int x, int y, int len, List<Color> colors, int colorsIndex, Uint8List covers, int coversIndex, bool firstCoverForAll) {
    linkedImage.blend_color_hspan(y, x, len, colors, colorsIndex, covers, coversIndex, firstCoverForAll);
  }
}
