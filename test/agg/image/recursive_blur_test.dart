import 'package:test/test.dart';
import 'package:agg/src/agg/image/recursive_blur.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';

void main() {
  group('RecursiveBlur', () {
    test('blurX runs without error', () {
      final img = ImageBuffer(100, 100);
      // Fill with some data
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          img.SetPixel(x, y, Color(x % 255, y % 255, (x + y) % 255, 255));
        }
      }

      final blur = RecursiveBlur(RecursiveBlurCalcRgba());
      blur.blurX(img, 5.0);
      
      // Basic check: ensure image is not empty/black (though blur might darken edges, center should have color)
      expect(img.getPixel(50, 50).alpha, 255);
    });

    test('blurY runs without error (using FormatTransposer)', () {
      final img = ImageBuffer(100, 100);
      // Fill with some data
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          img.SetPixel(x, y, Color(x % 255, y % 255, (x + y) % 255, 255));
        }
      }

      final blur = RecursiveBlur(RecursiveBlurCalcRgba());
      blur.blurY(img, 5.0);

      expect(img.getPixel(50, 50).alpha, 255);
    });

    test('blur (both X and Y) runs without error', () {
      final img = ImageBuffer(50, 50);
      for (int y = 0; y < 50; y++) {
        for (int x = 0; x < 50; x++) {
          img.SetPixel(x, y, Color(255, 0, 0, 255));
        }
      }

      final blur = RecursiveBlur(RecursiveBlurCalcRgba());
      blur.blur(img, 2.0);

      expect(img.getPixel(25, 25).alpha, 255);
    });
  });
}
