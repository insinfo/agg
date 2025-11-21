import 'package:agg/src/agg/agg_pattern_filters_rgba.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/line_aa_basics.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:test/test.dart';

void main() {
  test('PatternFilterBilinearRGBA clamps at image edges', () {
    final img = ImageBuffer(1, 1);
    img.SetPixel(0, 0, Color(10, 20, 30, 255));

    final filter = PatternFilterBilinearRGBA();
    final dest = List<Color>.filled(1, Color(0, 0, 0, 0));

    // Sample outside top-left; accessor must clamp to the only pixel.
    filter.pixelHighRes(
      img,
      dest,
      0,
      -LineAABasics.line_subpixel_scale,
      -LineAABasics.line_subpixel_scale,
    );

    expect(dest[0].red, equals(10));
    expect(dest[0].green, equals(20));
    expect(dest[0].blue, equals(30));
    expect(dest[0].alpha, equals(255));
  });
}
