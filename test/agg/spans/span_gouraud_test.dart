import 'package:test/test.dart';
import 'package:agg/src/agg/spans/span_gouraud_rgba.dart';
import 'package:agg/src/agg/primitives/color.dart';

void main() {
  group('SpanGouraudRgba', () {
    test('Interpolates colors correctly', () {
      final c1 = Color(255, 0, 0, 255);
      final c2 = Color(0, 255, 0, 255);
      final c3 = Color(0, 0, 255, 255);
      
      // Triangle: (0,0) -> Red, (10,0) -> Green, (5,10) -> Blue
      final spanGen = SpanGouraudRgba(
        c1, c2, c3,
        0, 0,
        10, 0,
        5, 10,
        0
      );

      spanGen.prepare();

      // Generate a span at y=5.
      // At y=5, x ranges roughly from 2.5 to 7.5.
      // Let's generate from x=2 to x=8 (len 6).
      final len = 6;
      final span = List.generate(len, (_) => Color(0, 0, 0, 0));
      
      spanGen.generate(span, 0, 2, 5, len);

      // Check middle pixel (approx center of triangle)
      // Should be a mix of all colors.
      final midPixel = span[3];
      expect(midPixel.red, greaterThan(0));
      expect(midPixel.green, greaterThan(0));
      expect(midPixel.blue, greaterThan(0));
      expect(midPixel.alpha, equals(255));
    });
  });
}
