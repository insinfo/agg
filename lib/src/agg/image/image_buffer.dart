import 'dart:typed_data';

import 'package:agg/src/agg/graphics2D.dart';
import 'package:agg/src/agg/image/blender_rgba.dart';
import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/image/rgba.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/primitives/rectangle_int.dart';
import 'package:agg/src/vector_math/vector2.dart';

/// Simple RGBA8888 image buffer with basic blending operations.
class ImageBuffer implements IImageByte {
  @override
  final int bitDepth = 32;

  @override
  Vector2 originOffset = Vector2.zero;

  @override
  final int width;
  @override
  final int height;
  final Uint8List _buffer;
  final int _stride;
  IRecieveBlenderByte _blender = BlenderRgba();

  ImageBuffer(this.width, this.height, {IRecieveBlenderByte? blender})
      : _stride = width * 4,
        _buffer = Uint8List(width * height * 4) {
    _blender = blender ?? BlenderRgba();
  }

  @override
  RectangleInt getBounds() => RectangleInt(0, 0, width - 1, height - 1);

  @override
  int getBufferOffsetY(int y) => y * _stride;

  @override
  int getBufferOffsetXY(int x, int y) => getBufferOffsetY(y) + x * 4;

  @override
  Graphics2D newGraphics2D() {
    throw UnimplementedError();
  }

  @override
  void markImageChanged() {}

  @override
  int strideInBytes() => _stride;

  @override
  int strideInBytesAbs() => _stride.abs();

  @override
  IRecieveBlenderByte getRecieveBlender() => _blender;

  @override
  void setRecieveBlender(IRecieveBlenderByte value) {
    _blender = value;
  }

  @override
  int getBytesBetweenPixelsInclusive() => 4;

  @override
  Uint8List getBuffer() => _buffer;

  @override
  Color getPixel(int x, int y) => _blender.pixelToColor(_buffer, getBufferOffsetXY(x, y));

  @override
  void copy_pixel(int x, int y, Uint8List c, int byteOffset) {
    final int o = getBufferOffsetXY(x, y);
    _buffer[o] = c[byteOffset];
    _buffer[o + 1] = c[byteOffset + 1];
    _buffer[o + 2] = c[byteOffset + 2];
    _buffer[o + 3] = c[byteOffset + 3];
  }

  @override
  void CopyFrom(IImageByte sourceImage) {
    _buffer.setAll(0, sourceImage.getBuffer());
  }

  @override
  void CopyFrom2(IImageByte sourceImage, RectangleInt srcRect, int destXOffset, int destYOffset) {
    for (int y = 0; y <= srcRect.top - srcRect.bottom; y++) {
      for (int x = 0; x <= srcRect.right - srcRect.left; x++) {
        final color = sourceImage.getPixel(srcRect.left + x, srcRect.bottom + y);
        SetPixel(destXOffset + x, destYOffset + y, color);
      }
    }
  }

  @override
  void SetPixel(int x, int y, Color color) {
    _blender.copyPixels(_buffer, getBufferOffsetXY(x, y), color, 1);
  }

  @override
  void BlendPixel(int x, int y, Color sourceColor, int cover) {
    final c = Color.fromColor(sourceColor)..alpha = (sourceColor.alpha * cover + 127) ~/ 255;
    _blender.blendPixel(_buffer, getBufferOffsetXY(x, y), c);
  }

  @override
  void copy_hline(int x, int y, int len, Color sourceColor) {
    _blender.copyPixels(_buffer, getBufferOffsetXY(x, y), sourceColor, len);
  }

  @override
  void copy_vline(int x, int y, int len, Color sourceColor) {
    for (int i = 0; i < len; i++) {
      SetPixel(x, y + i, sourceColor);
    }
  }

  @override
  void blend_hline(int x, int y, int x2, Color sourceColor, int cover) {
    final int len = x2 - x + 1;
    final c = Color.fromColor(sourceColor)..alpha = (sourceColor.alpha * cover + 127) ~/ 255;
    _blender.copyPixels(_buffer, getBufferOffsetXY(x, y), c, len);
  }

  @override
  void blend_vline(int x, int y1, int y2, Color sourceColor, int cover) {
    final c = Color.fromColor(sourceColor)..alpha = (sourceColor.alpha * cover + 127) ~/ 255;
    for (int y = y1; y <= y2; y++) {
      _blender.blendPixel(_buffer, getBufferOffsetXY(x, y), c);
    }
  }

  @override
  void copy_color_hspan(int x, int y, int len, List<Color> colors, int colorIndex) {
    for (int i = 0; i < len; i++) {
      SetPixel(x + i, y, colors[colorIndex + i]);
    }
  }

  @override
  void copy_color_vspan(int x, int y, int len, List<Color> colors, int colorIndex) {
    for (int i = 0; i < len; i++) {
      SetPixel(x, y + i, colors[colorIndex + i]);
    }
  }

  @override
  void blend_solid_hspan(int x, int y, int len, Color sourceColor, Uint8List covers, int coversIndex) {
    for (int i = 0; i < len; i++) {
      BlendPixel(x + i, y, sourceColor, covers[coversIndex + i]);
    }
  }

  @override
  void blend_solid_vspan(int x, int y, int len, Color sourceColor, Uint8List covers, int coversIndex) {
    for (int i = 0; i < len; i++) {
      BlendPixel(x, y + i, sourceColor, covers[coversIndex + i]);
    }
  }

  @override
  void blend_color_hspan(
    int x,
    int y,
    int len,
    List<Color> colors,
    int colorsIndex,
    Uint8List covers,
    int coversIndex,
    bool firstCoverForAll,
  ) {
    _blender.blendPixels(
      _buffer,
      getBufferOffsetXY(x, y),
      colors,
      colorsIndex,
      covers,
      coversIndex,
      firstCoverForAll,
      len,
    );
  }

  @override
  void blend_color_vspan(
    int x,
    int y,
    int len,
    List<Color> colors,
    int colorsIndex,
    Uint8List covers,
    int coversIndex,
    bool firstCoverForAll,
  ) {
    for (int i = 0; i < len; i++) {
      _blender.blendPixels(
        _buffer,
        getBufferOffsetXY(x, y + i),
        colors,
        colorsIndex + i,
        covers,
        coversIndex + (firstCoverForAll ? 0 : i),
        firstCoverForAll,
        1,
      );
    }
  }
}
