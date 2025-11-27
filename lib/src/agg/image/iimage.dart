import 'dart:typed_data';

import 'package:agg/src/agg/image/rgba.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/primitives/color_f.dart';
import 'package:agg/src/agg/primitives/rectangle_int.dart';
import 'package:agg/src/vector_math/vector2.dart';

import '../graphics2D.dart';

abstract class IImage {
  int get bitDepth;

  Vector2 get originOffset;
  set originOffset(Vector2 v);

  int get width;
  int get height;

  RectangleInt getBounds();

  int getBufferOffsetY(int y);

  int getBufferOffsetXY(int x, int y);

  Graphics2D newGraphics2D();

  void markImageChanged();
}

/*
Em Java: byte[] => Em Dart: Uint8List que equivale a List<int> so que mais eficiente
 */
abstract class IImageByte extends IImage {
  int strideInBytes();

  int strideInBytesAbs();

  IRecieveBlenderByte getRecieveBlender();

  void setRecieveBlender(IRecieveBlenderByte value);

  int getBytesBetweenPixelsInclusive();

  Uint8List getBuffer();

  Color getPixel(int x, int y);

  void copy_pixel(int x, int y, Uint8List c, int ByteOffset);

  void CopyFrom(IImageByte sourceImage);

  void CopyFrom2(IImageByte sourceImage, RectangleInt sourceImageRect, int destXOffset, int destYOffset);

  void SetPixel(int x, int y, Color color);

  void BlendPixel(int x, int y, Color sourceColor, int cover);

  // line stuff
  void copy_hline(int x, int y, int len, Color sourceColor);

  void copy_vline(int x, int y, int len, Color sourceColor);

  void blend_hline(int x, int y, int x2, Color sourceColor, int cover);

  void blend_vline(int x, int y1, int y2, Color sourceColor, int cover);

  // color stuff
  void copy_color_hspan(int x, int y, int len, List<Color> colors, int colorIndex);

  void copy_color_vspan(int x, int y, int len, List<Color> colors, int colorIndex);

  void blend_solid_hspan(int x, int y, int len, Color sourceColor, Uint8List covers, int coversIndex);

  void blend_solid_vspan(int x, int y, int len, Color sourceColor, Uint8List covers, int coversIndex);

  void blend_color_hspan(int x, int y, int len, List<Color> colors, int colorsIndex, Uint8List covers, int coversIndex,
      bool firstCoverForAll);

  void blend_color_vspan(int x, int y, int len, List<Color> colors, int colorsIndex, Uint8List covers, int coversIndex,
      bool firstCoverForAll);
}

abstract class IImageFloat extends IImage {
  int strideInFloats();

  int strideInFloatsAbs();

  IRecieveBlenderFloat getBlender();

  void setRecieveBlender(IRecieveBlenderFloat value);

  int getFloatsBetweenPixelsInclusive();

  Float32List getBuffer();

  ColorF getPixel(int x, int y);

  void copy_pixel(int x, int y, Float32List c, int floatOffset);

  void CopyFrom(IImageFloat sourceImage);

  void CopyFrom2(IImageFloat sourceImage, RectangleInt sourceImageRect, int destXOffset, int destYOffset);

  void SetPixel(int x, int y, ColorF color);

  void BlendPixel(int x, int y, ColorF sourceColor, int cover);

  // line stuff
  void copy_hline(int x, int y, int len, ColorF sourceColor);

  void copy_vline(int x, int y, int len, ColorF sourceColor);

  void blend_hline(int x, int y, int x2, ColorF sourceColor, int cover);

  void blend_vline(int x, int y1, int y2, ColorF sourceColor, int cover);

  // color stuff
  void copy_color_hspan(int x, int y, int len, List<ColorF> colors, int colorIndex);

  void copy_color_vspan(int x, int y, int len, List<ColorF> colors, int colorIndex);

  void blend_solid_hspan(int x, int y, int len, ColorF sourceColor, Uint8List covers, int coversIndex);

  void blend_solid_vspan(int x, int y, int len, ColorF sourceColor, Uint8List covers, int coversIndex);

  void blend_color_hspan(int x, int y, int len, List<ColorF> colors, int colorsIndex, Uint8List covers, int coversIndex,
      bool firstCoverForAll);

  void blend_color_vspan(int x, int y, int len, List<ColorF> colors, int colorsIndex, Uint8List covers, int coversIndex,
      bool firstCoverForAll);
}
