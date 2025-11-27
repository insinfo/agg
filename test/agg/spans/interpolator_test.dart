import 'package:test/test.dart';
import 'package:agg/src/agg/spans/agg_span_interpolator_linear.dart';
import 'package:agg/src/agg/spans/agg_span_interpolator_persp.dart';
import 'package:agg/src/agg/transform/affine.dart';


void main() {
  group('SpanInterpolatorLinear', () {
    test('Interpolates linearly', () {
      final trans = Affine.translation(10, 20);
      final interp = SpanInterpolatorLinear(trans);
      interp.begin(0, 0, 10);
      
      final xy = [0, 0];
      interp.coordinates(xy);
      // (0,0) translated by (10,20) -> (10,20)
      // Subpixel scale is 256.
      expect(xy[0], 10 * 256);
      expect(xy[1], 20 * 256);

      interp.next();
      interp.coordinates(xy);
      // Next pixel in x direction.
      // (1,0) translated -> (11,20)
      expect(xy[0], 11 * 256);
      expect(xy[1], 20 * 256);
    });
  });

  group('SpanInterpolatorPerspLerp', () {
    test('Interpolates perspective', () {
      // Identity perspective
      final interp = SpanInterpolatorPerspLerp.rectToQuad(
        0, 0, 100, 100,
        [0, 0, 100, 0, 100, 100, 0, 100]
      );
      
      interp.begin(0, 0, 10);
      final xy = [0, 0];
      interp.coordinates(xy);
      expect(xy[0], 0);
      expect(xy[1], 0);

      interp.next();
      interp.coordinates(xy);
      expect(xy[0], 1 * 256);
      expect(xy[1], 0);
    });
  });
}
