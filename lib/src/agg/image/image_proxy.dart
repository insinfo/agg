import 'dart:typed_data';
import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/image/rgba.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/primitives/rectangle_int.dart';
import 'package:agg/src/vector_math/vector2.dart';
import '../graphics2D.dart';

abstract class ImageProxy extends IImageByte {
  IImageByte linkedImage;

  ImageProxy(this.linkedImage);

  void linkToImage(IImageByte linkedImage) {
    this.linkedImage = linkedImage;
  }

  @override
  int get bitDepth => linkedImage.bitDepth;

  @override
  Vector2 get originOffset => linkedImage.originOffset;

  @override
  set originOffset(Vector2 v) => linkedImage.originOffset = v;

  @override
  int get width => linkedImage.width;

  @override
  int get height => linkedImage.height;

  @override
  RectangleInt getBounds() => linkedImage.getBounds();

  @override
  int getBufferOffsetY(int y) => linkedImage.getBufferOffsetY(y);

  @override
  int getBufferOffsetXY(int x, int y) => linkedImage.getBufferOffsetXY(x, y);

  @override
  Graphics2D newGraphics2D() => linkedImage.newGraphics2D();

  @override
  void markImageChanged() => linkedImage.markImageChanged();

  @override
  int strideInBytes() => linkedImage.strideInBytes();

  @override
  int strideInBytesAbs() => linkedImage.strideInBytesAbs();

  @override
  IRecieveBlenderByte getRecieveBlender() => linkedImage.getRecieveBlender();

  @override
  void setRecieveBlender(IRecieveBlenderByte value) => linkedImage.setRecieveBlender(value);

  @override
  int getBytesBetweenPixelsInclusive() => linkedImage.getBytesBetweenPixelsInclusive();

  @override
  Uint8List getBuffer() => linkedImage.getBuffer();

  @override
  Color getPixel(int x, int y) => linkedImage.getPixel(x, y);

  @override
  void copy_pixel(int x, int y, Uint8List c, int ByteOffset) => linkedImage.copy_pixel(x, y, c, ByteOffset);

  @override
  void CopyFrom(IImageByte sourceImage) => linkedImage.CopyFrom(sourceImage);

  @override
  void CopyFrom2(IImageByte sourceImage, RectangleInt sourceImageRect, int destXOffset, int destYOffset) => linkedImage.CopyFrom2(sourceImage, sourceImageRect, destXOffset, destYOffset);

  @override
  void SetPixel(int x, int y, Color color) => linkedImage.SetPixel(x, y, color);

  @override
  void BlendPixel(int x, int y, Color sourceColor, int cover) => linkedImage.BlendPixel(x, y, sourceColor, cover);

  @override
  void copy_hline(int x, int y, int len, Color sourceColor) => linkedImage.copy_hline(x, y, len, sourceColor);

  @override
  void copy_vline(int x, int y, int len, Color sourceColor) => linkedImage.copy_vline(x, y, len, sourceColor);

  @override
  void blend_hline(int x, int y, int x2, Color sourceColor, int cover) => linkedImage.blend_hline(x, y, x2, sourceColor, cover);

  @override
  void blend_vline(int x, int y1, int y2, Color sourceColor, int cover) => linkedImage.blend_vline(x, y1, y2, sourceColor, cover);

  @override
  void copy_color_hspan(int x, int y, int len, List<Color> colors, int colorIndex) => linkedImage.copy_color_hspan(x, y, len, colors, colorIndex);

  @override
  void copy_color_vspan(int x, int y, int len, List<Color> colors, int colorIndex) => linkedImage.copy_color_vspan(x, y, len, colors, colorIndex);

  @override
  void blend_solid_hspan(int x, int y, int len, Color sourceColor, Uint8List covers, int coversIndex) => linkedImage.blend_solid_hspan(x, y, len, sourceColor, covers, coversIndex);

  @override
  void blend_solid_vspan(int x, int y, int len, Color sourceColor, Uint8List covers, int coversIndex) => linkedImage.blend_solid_vspan(x, y, len, sourceColor, covers, coversIndex);

  @override
  void blend_color_hspan(int x, int y, int len, List<Color> colors, int colorsIndex, Uint8List covers, int coversIndex, bool firstCoverForAll) => linkedImage.blend_color_hspan(x, y, len, colors, colorsIndex, covers, coversIndex, firstCoverForAll);

  @override
  void blend_color_vspan(int x, int y, int len, List<Color> colors, int colorsIndex, Uint8List covers, int coversIndex, bool firstCoverForAll) => linkedImage.blend_color_vspan(x, y, len, colors, colorsIndex, covers, coversIndex, firstCoverForAll);
}
