import 'dart:typed_data';

import 'package:agg/src/agg/image/rgba.dart';
import 'package:agg/src/agg/primitives/color.dart';

/// Straight alpha RGBA blender writing into byte buffers.
class BlenderRgba implements IRecieveBlenderByte {
  @override
  int get numPixelBits => 32;

  @override
  Color pixelToColor(Uint8List buffer, int bufferOffset) {
    final int r = buffer[bufferOffset];
    final int g = buffer[bufferOffset + 1];
    final int b = buffer[bufferOffset + 2];
    final int a = buffer[bufferOffset + 3];
    return Color.fromRgba(r, g, b, a);
  }

  @override
  void copyPixels(Uint8List buffer, int bufferOffset, Color sourceColor, int count) {
    for (int i = 0; i < count; i++) {
      final int o = bufferOffset + i * 4;
      buffer[o] = sourceColor.red;
      buffer[o + 1] = sourceColor.green;
      buffer[o + 2] = sourceColor.blue;
      buffer[o + 3] = sourceColor.alpha;
    }
  }

  @override
  void blendPixel(Uint8List buffer, int bufferOffset, Color sourceColor) {
    _blendOne(buffer, bufferOffset, sourceColor.red, sourceColor.green, sourceColor.blue, sourceColor.alpha);
  }

  void _blendOne(Uint8List buffer, int o, int sr, int sg, int sb, int sa) {
    if (sa == 255) {
      buffer[o] = sr;
      buffer[o + 1] = sg;
      buffer[o + 2] = sb;
      buffer[o + 3] = 255;
      return;
    }
    final int da = buffer[o + 3];
    final int dr = buffer[o];
    final int dg = buffer[o + 1];
    final int db = buffer[o + 2];
    final int invA = 255 - sa;
    final int outA = sa + ((da * invA + 127) ~/ 255);
    buffer[o] = ((sr * sa + dr * invA + 127) ~/ 255);
    buffer[o + 1] = ((sg * sa + dg * invA + 127) ~/ 255);
    buffer[o + 2] = ((sb * sa + db * invA + 127) ~/ 255);
    buffer[o + 3] = outA;
  }

  @override
  void blendPixels(
    Uint8List buffer,
    int bufferOffset,
    List<Color> sourceColors,
    int sourceColorsOffset,
    Uint8List sourceCovers,
    int sourceCoversOffset,
    bool firstCoverForAll,
    int count,
  ) {
    if (firstCoverForAll) {
      final int cover = sourceCovers[sourceCoversOffset];
      for (int i = 0; i < count; i++) {
        final c = sourceColors[sourceColorsOffset + i];
        _blendOne(buffer, bufferOffset + i * 4, c.red, c.green, c.blue, (c.alpha * cover + 127) ~/ 255);
      }
    } else {
      for (int i = 0; i < count; i++) {
        final c = sourceColors[sourceColorsOffset + i];
        final int cover = sourceCovers[sourceCoversOffset + i];
        _blendOne(buffer, bufferOffset + i * 4, c.red, c.green, c.blue, (c.alpha * cover + 127) ~/ 255);
      }
    }
  }

  @override
  Color blend(Color start, Color blend) {
    final temp = Uint8List.fromList([start.red, start.green, start.blue, start.alpha]);
    _blendOne(temp, 0, blend.red, blend.green, blend.blue, blend.alpha);
    return Color.fromRgba(temp[0], temp[1], temp[2], temp[3]);
  }
}
