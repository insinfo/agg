import 'dart:typed_data';

import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/line_aa_basics.dart';

abstract class IPatternFilter {
  int dilation();
  void pixelHighRes(ImageBuffer sourceImage, List<Color> destBuffer,
      int destBufferOffset, int x, int y);
}

class PatternFilterBilinearRGBA implements IPatternFilter {
  @override
  int dilation() => 1;

  void pixelLowRes(
      List<List<Color>> buf, List<Color> p, int offset, int x, int y) {
    p[offset] = buf[y][x];
  }

  @override
  void pixelHighRes(ImageBuffer sourceImage, List<Color> destBuffer,
      int destBufferOffset, int x, int y) {
    int r = 0, g = 0, b = 0, a = 0;
    r = g = b = a = LineAABasics.line_subpixel_scale *
        LineAABasics.line_subpixel_scale ~/
        2;

    int weight;
    int xLr = x >> LineAABasics.line_subpixel_shift;
    int yLr = y >> LineAABasics.line_subpixel_shift;

    x &= LineAABasics.line_subpixel_mask;
    y &= LineAABasics.line_subpixel_mask;

    final Uint8List buffer = sourceImage.getBuffer();
    int sourceOffset = sourceImage.getBufferOffsetXY(xLr, yLr);
    final int bytesBetweenPixels = sourceImage.getBytesBetweenPixelsInclusive();

    // Assume RGBA order
    const int orderR = 0;
    const int orderG = 1;
    const int orderB = 2;
    const int orderA = 3;

    weight = (LineAABasics.line_subpixel_scale - x) *
        (LineAABasics.line_subpixel_scale - y);
    r += weight * buffer[sourceOffset + orderR];
    g += weight * buffer[sourceOffset + orderG];
    b += weight * buffer[sourceOffset + orderB];
    a += weight * buffer[sourceOffset + orderA];

    sourceOffset += bytesBetweenPixels;

    weight = x * (LineAABasics.line_subpixel_scale - y);
    r += weight * buffer[sourceOffset + orderR];
    g += weight * buffer[sourceOffset + orderG];
    b += weight * buffer[sourceOffset + orderB];
    a += weight * buffer[sourceOffset + orderA];

    sourceOffset = sourceImage.getBufferOffsetXY(xLr, yLr + 1);

    weight = (LineAABasics.line_subpixel_scale - x) * y;
    r += weight * buffer[sourceOffset + orderR];
    g += weight * buffer[sourceOffset + orderG];
    b += weight * buffer[sourceOffset + orderB];
    a += weight * buffer[sourceOffset + orderA];

    sourceOffset += bytesBetweenPixels;

    weight = x * y;
    r += weight * buffer[sourceOffset + orderR];
    g += weight * buffer[sourceOffset + orderG];
    b += weight * buffer[sourceOffset + orderB];
    a += weight * buffer[sourceOffset + orderA];

    destBuffer[destBufferOffset] = Color(
      r >> (LineAABasics.line_subpixel_shift * 2),
      g >> (LineAABasics.line_subpixel_shift * 2),
      b >> (LineAABasics.line_subpixel_shift * 2),
      a >> (LineAABasics.line_subpixel_shift * 2),
    );
  }
}
