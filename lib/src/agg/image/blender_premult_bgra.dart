import 'dart:typed_data';

import 'package:agg/src/agg/image/rgba.dart';
import 'package:agg/src/agg/primitives/color.dart';

/// Premultiplied alpha BGRA blender writing into byte buffers.
class BlenderPremultBgra implements IRecieveBlenderByte {
  @override
  int get numPixelBits => 32;

  int _premul(int c, int a) => (c * a + 127) ~/ 255;

  @override
  Color pixelToColor(Uint8List buffer, int bufferOffset) {
    final int b = buffer[bufferOffset];
    final int g = buffer[bufferOffset + 1];
    final int r = buffer[bufferOffset + 2];
    final int a = buffer[bufferOffset + 3];
    if (a == 0) return Color(0, 0, 0, 0);
    final invA = 255 * 255 ~/ a;
    return Color.fromRgba(
      (r * invA + 127) ~/ 255,
      (g * invA + 127) ~/ 255,
      (b * invA + 127) ~/ 255,
      a,
    );
  }

  @override
  void copyPixels(Uint8List buffer, int bufferOffset, Color sourceColor, int count) {
    final int sa = sourceColor.alpha;
    final int sr = _premul(sourceColor.red, sa);
    final int sg = _premul(sourceColor.green, sa);
    final int sb = _premul(sourceColor.blue, sa);
    for (int i = 0; i < count; i++) {
      final int o = bufferOffset + i * 4;
      buffer[o] = sb;
      buffer[o + 1] = sg;
      buffer[o + 2] = sr;
      buffer[o + 3] = sa;
    }
  }

  @override
  void blendPixel(Uint8List buffer, int bufferOffset, Color sourceColor) {
    final int sa = sourceColor.alpha;
    if (sa == 255) {
      buffer[bufferOffset] = sourceColor.blue;
      buffer[bufferOffset + 1] = sourceColor.green;
      buffer[bufferOffset + 2] = sourceColor.red;
      buffer[bufferOffset + 3] = 255;
      return;
    }
    final int da = buffer[bufferOffset + 3];
    final int db = buffer[bufferOffset];
    final int dg = buffer[bufferOffset + 1];
    final int dr = buffer[bufferOffset + 2];
    final int sr = _premul(sourceColor.red, sa);
    final int sg = _premul(sourceColor.green, sa);
    final int sb = _premul(sourceColor.blue, sa);

    final int invA = 255 - sa;
    final int outA = sa + ((da * invA + 127) ~/ 255);
    buffer[bufferOffset] = sb + ((db * invA + 127) ~/ 255);
    buffer[bufferOffset + 1] = sg + ((dg * invA + 127) ~/ 255);
    buffer[bufferOffset + 2] = sr + ((dr * invA + 127) ~/ 255);
    buffer[bufferOffset + 3] = outA;
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
        final int sa = (c.alpha * cover + 127) ~/ 255;
        final int sr = _premul(c.red, sa);
        final int sg = _premul(c.green, sa);
        final int sb = _premul(c.blue, sa);
        _blendOne(buffer, bufferOffset + i * 4, sr, sg, sb, sa);
      }
    } else {
      for (int i = 0; i < count; i++) {
        final c = sourceColors[sourceColorsOffset + i];
        final int sa = (c.alpha * sourceCovers[sourceCoversOffset + i] + 127) ~/ 255;
        final int sr = _premul(c.red, sa);
        final int sg = _premul(c.green, sa);
        final int sb = _premul(c.blue, sa);
        _blendOne(buffer, bufferOffset + i * 4, sr, sg, sb, sa);
      }
    }
  }

  void _blendOne(Uint8List buffer, int o, int sr, int sg, int sb, int sa) {
    final int da = buffer[o + 3];
    final int db = buffer[o];
    final int dg = buffer[o + 1];
    final int dr = buffer[o + 2];
    final int invA = 255 - sa;
    final int outA = sa + ((da * invA + 127) ~/ 255);
    buffer[o] = sb + ((db * invA + 127) ~/ 255);
    buffer[o + 1] = sg + ((dg * invA + 127) ~/ 255);
    buffer[o + 2] = sr + ((dr * invA + 127) ~/ 255);
    buffer[o + 3] = outA;
  }

  @override
  Color blend(Color start, Color blend) {
    final temp = Uint8List.fromList([
      _premul(start.blue, start.alpha),
      _premul(start.green, start.alpha),
      _premul(start.red, start.alpha),
      start.alpha
    ]);
    _blendOne(temp, 0, _premul(blend.red, blend.alpha), _premul(blend.green, blend.alpha),
        _premul(blend.blue, blend.alpha), blend.alpha);
    final a = temp[3];
    if (a == 0) return Color(0, 0, 0, 0);
    final invA = 255 * 255 ~/ a;
    return Color.fromRgba(
      (temp[2] * invA + 127) ~/ 255,
      (temp[1] * invA + 127) ~/ 255,
      (temp[0] * invA + 127) ~/ 255,
      a,
    );
  }
}
