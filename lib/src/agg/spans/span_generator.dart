import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/primitives/color_f.dart';

/// Generates spans of colors for scanline rendering.
abstract class ISpanGenerator {
  void prepare();

  void generate(List<Color> span, int spanIndex, int x, int y, int len);
}

/// Floating-point variant mirroring AGG's span generator API.
abstract class ISpanGeneratorFloat {
  void prepare();

  void generate(List<ColorF> span, int spanIndex, int x, int y, int len);
}
