import 'package:agg/src/agg/primitives/color.dart';

abstract class ISpanGenerator {
  void prepare();
  void generate(List<Color> span, int spanIndex, int x, int y, int len);
}
