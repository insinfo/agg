import 'dart:typed_data';

import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/primitives/colorf.dart';

abstract class GoodInterfaceThinking // TODO: switch to an interface more like this for blenders.
{
  int get numPixelBits;

  Color PixelToColorRGBA_Bytes(Uint8List buffer, int bufferOffset);

  void setPixels(Uint8List buffer, int bufferOffset, Color sourceColor, int count);

  void setPixels2(Uint8List buffer, int bufferOffset, List<Color> sourceColors, int sourceColorsOffset, int count);

  void blendPixels(Uint8List buffer, int bufferOffset, Color sourceColor, int count);

  void blendPixels2(Uint8List buffer, int bufferOffset, List<Color> sourceColors, int sourceColorsOffset, int count);

  // and we need some that use coverage values
  void blendPixels3(
      Uint8List buffer, int bufferOffset, List<Color> sourceColors, int sourceColorsOffset, int sourceCover, int count);

  void blendPixels4(Uint8List buffer, int bufferOffset, List<Color> sourceColors, int sourceColorsOffset,
      Uint8List sourceCovers, int sourceCoversOffset, int count);
}

abstract class IRecieveBlenderByte {
  int get numPixelBits;

  Color pixelToColor(Uint8List buffer, int bufferOffset);

  void copyPixels(Uint8List buffer, int bufferOffset, Color sourceColor, int count);

  void blendPixel(Uint8List buffer, int bufferOffset, Color sourceColor);

  void blendPixels(Uint8List buffer, int bufferOffset, List<Color> sourceColors, int sourceColorsOffset,
      Uint8List sourceCovers, int sourceCoversOffset, bool firstCoverForAll, int count);

//BlenderExtensions
  // Compute a fixed color from a source and a target alpha
  Color blend(Color start, Color blend) {
    var result = <int>[start.blue, start.green, start.red, start.alpha];
    this.blendPixel(result, 0, blend);

    return new Color.fromRGBA(result[2], result[1], result[0], result[3]);
  }
}

abstract class IRecieveBlenderFloat {
  int get numPixelBits;

  ColorF PixelToColorRGBA_Floats(List<double> buffer, int bufferOffset);

  void CopyPixels(List<double> buffer, int bufferOffset, ColorF sourceColor, int count);

  void BlendPixel(List<double> buffer, int bufferOffset, ColorF sourceColor);

  void BlendPixels(List<double> buffer, int bufferOffset, List<ColorF> sourceColors, int sourceColorsOffset,
      Uint8List sourceCovers, int sourceCoversOffset, bool firstCoverForAll, int count);
}
