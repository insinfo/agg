import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/image/raster_buffer_accessors.dart';
import 'package:agg/src/agg/line_aa_basics.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/shared/ref_param.dart';

abstract class IPatternFilter {
  int dilation();
  void pixelHighRes(ImageBuffer sourceImage, List<Color> destBuffer,
      int destBufferOffset, int x, int y);
}

class PatternFilterBilinearRGBA implements IPatternFilter {
  @override
  int dilation() => 1;
  ImageBufferAccessorClamp? _clamp;

  @override
  void pixelHighRes(ImageBuffer sourceImage, List<Color> destBuffer,
      int destBufferOffset, int x, int y) {
    _clamp ??= ImageBufferAccessorClamp(sourceImage);

    int r = 0, g = 0, b = 0, a = 0;
    r = g = b = a = LineAABasics.line_subpixel_scale *
        LineAABasics.line_subpixel_scale ~/
        2;

    int weight;
    int xLr = x >> LineAABasics.line_subpixel_shift;
    int yLr = y >> LineAABasics.line_subpixel_shift;

    x &= LineAABasics.line_subpixel_mask;
    y &= LineAABasics.line_subpixel_mask;

    // Clamp sampling near the edges using the accessor.
    final xr = RefParam<int>(0);
    final buf00 = _clamp!.span(xLr, yLr, 1, xr);
    final int off00 = xr.value;

    final buf01 = _clamp!.nextX(xr);
    final int off01 = xr.value;

    final buf10 = _clamp!.span(xLr, yLr + 1, 1, xr);
    final int off10 = xr.value;

    final buf11 = _clamp!.nextX(xr);
    final int off11 = xr.value;

    // Assume RGBA order
    const int orderR = 0;
    const int orderG = 1;
    const int orderB = 2;
    const int orderA = 3;

    weight = (LineAABasics.line_subpixel_scale - x) *
        (LineAABasics.line_subpixel_scale - y);
    r += weight * buf00[off00 + orderR];
    g += weight * buf00[off00 + orderG];
    b += weight * buf00[off00 + orderB];
    a += weight * buf00[off00 + orderA];

    weight = x * (LineAABasics.line_subpixel_scale - y);
    r += weight * buf01[off01 + orderR];
    g += weight * buf01[off01 + orderG];
    b += weight * buf01[off01 + orderB];
    a += weight * buf01[off01 + orderA];

    weight = (LineAABasics.line_subpixel_scale - x) * y;
    r += weight * buf10[off10 + orderR];
    g += weight * buf10[off10 + orderG];
    b += weight * buf10[off10 + orderB];
    a += weight * buf10[off10 + orderA];

    weight = x * y;
    r += weight * buf11[off11 + orderR];
    g += weight * buf11[off11 + orderG];
    b += weight * buf11[off11 + orderB];
    a += weight * buf11[off11 + orderA];

    destBuffer[destBufferOffset] = Color(
      r >> (LineAABasics.line_subpixel_shift * 2),
      g >> (LineAABasics.line_subpixel_shift * 2),
      b >> (LineAABasics.line_subpixel_shift * 2),
      a >> (LineAABasics.line_subpixel_shift * 2),
    );
  }
}
