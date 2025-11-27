import 'package:test/test.dart';
import 'package:agg/src/agg/image/threshold_functions.dart';
import 'package:agg/src/agg/primitives/color.dart';

void main() {
  group('ThresholdFunctions', () {
    test('AlphaThresholdFunction', () {
      final func = AlphaThresholdFunction(0.2, 0.8);
      expect(func.threshold(Color(0, 0, 0, 0)), 0.0);
      expect(func.threshold(Color(0, 0, 0, 255)), 0.0); // > 0.8 -> 0
      expect(func.threshold(Color(0, 0, 0, 128)), closeTo(0.5, 0.01)); // ~0.5
    });

    test('HueThresholdFunction', () {
      final func = HueThresholdFunction(0.0, 1.0);
      // Red hue is 0 or 1.
      expect(func.transform(Color(255, 0, 0)), closeTo(0.0, 0.01));
      // Green hue is 1/3
      expect(func.transform(Color(0, 255, 0)), closeTo(1/3, 0.01));
      // Blue hue is 2/3
      expect(func.transform(Color(0, 0, 255)), closeTo(2/3, 0.01));
    });

    test('MapOnMaxIntensity', () {
      final func = MapOnMaxIntensity(0.0, 1.0);
      // White -> 1.0
      expect(func.transform(Color(255, 255, 255)), closeTo(1.0, 0.01));
      // Black -> 0.0
      expect(func.transform(Color(0, 0, 0)), closeTo(0.0, 0.01));
    });

    test('SilhouetteThresholdFunction', () {
      final func = SilhouetteThresholdFunction(0.0, 1.0);
      // White -> 0.0 (inverted)
      expect(func.transform(Color(255, 255, 255)), closeTo(0.0, 0.01));
      // Black -> 1.0 (inverted)
      expect(func.transform(Color(0, 0, 0)), closeTo(1.0, 0.01));
    });
  });
}
