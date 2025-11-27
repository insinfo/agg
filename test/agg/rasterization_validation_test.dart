import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/scanline_renderer.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/scanline_unpacked8.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';
import 'package:agg/src/agg/vertex_source/ellipse.dart';
import 'package:agg/src/agg/vertex_source/rounded_rect.dart';
import 'package:agg/src/agg/rasterizer_outline_aa.dart';
import 'package:agg/src/agg/outline_renderer.dart';
import 'package:agg/src/agg/line_profile_aa.dart';
import 'package:agg/src/agg/agg_gamma_functions.dart';
import 'package:agg/src/agg/line_aa_basics.dart';
import 'package:test/test.dart';

void main() {
  group('Rasterization Validation', () {
    test('render filled rectangle', () {
      final img = ImageBuffer(100, 100);
      final ras = ScanlineRasterizer();
      final sl = ScanlineUnpacked8();

      // Clear background to white
      for (int y = 0; y < img.height; y++) {
        for (int x = 0; x < img.width; x++) {
          img.SetPixel(x, y, Color(255, 255, 255, 255));
        }
      }

      // Draw a red filled rectangle
      final path = VertexStorage()
        ..moveTo(20, 20)
        ..lineTo(80, 20)
        ..lineTo(80, 80)
        ..lineTo(20, 80)
        ..closePath();

      ras.add_path(path);
      ScanlineRenderer.renderSolid(ras, sl, img, Color(255, 0, 0, 255));

      // Verify the rectangle was rendered
      final centerPixel = img.getPixel(50, 50);
      expect(centerPixel.red, equals(255));
      expect(centerPixel.green, equals(0));
      expect(centerPixel.blue, equals(0));
      expect(centerPixel.alpha, equals(255));

      // Verify outside the rectangle is still white
      final outsidePixel = img.getPixel(10, 10);
      expect(outsidePixel.red, equals(255));
      expect(outsidePixel.green, equals(255));
      expect(outsidePixel.blue, equals(255));
    });

    test('render filled ellipse', () {
      final img = ImageBuffer(100, 100);
      final ras = ScanlineRasterizer();
      final sl = ScanlineUnpacked8();

      // Clear to white
      for (int y = 0; y < img.height; y++) {
        for (int x = 0; x < img.width; x++) {
          img.SetPixel(x, y, Color(255, 255, 255, 255));
        }
      }

      // Draw a blue filled circle
      final ellipse = Ellipse(50, 50, 30, 30);
      ras.add_path(ellipse);
      ScanlineRenderer.renderSolid(ras, sl, img, Color(0, 0, 255, 255));

      // Verify center is blue
      final centerPixel = img.getPixel(50, 50);
      expect(centerPixel.blue, equals(255));
      expect(centerPixel.red, equals(0));

      // Verify a point outside is white
      final outsidePixel = img.getPixel(10, 10);
      expect(outsidePixel.red, equals(255));
      expect(outsidePixel.green, equals(255));
      expect(outsidePixel.blue, equals(255));
    });

    test('render filled rounded rectangle', () {
      final img = ImageBuffer(100, 100);
      final ras = ScanlineRasterizer();
      final sl = ScanlineUnpacked8();

      // Clear to white
      for (int y = 0; y < img.height; y++) {
        for (int x = 0; x < img.width; x++) {
          img.SetPixel(x, y, Color(255, 255, 255, 255));
        }
      }

      // Draw a green filled rounded rectangle
      final roundedRect = RoundedRect(20, 20, 80, 80, 10);
      ras.add_path(roundedRect);
      ScanlineRenderer.renderSolid(ras, sl, img, Color(0, 255, 0, 255));

      // Verify center is green
      final centerPixel = img.getPixel(50, 50);
      expect(centerPixel.green, equals(255));
      expect(centerPixel.red, equals(0));
      expect(centerPixel.blue, equals(0));
    });

    test('render anti-aliased outlined rectangle', () {
      final img = ImageBuffer(100, 100);

      // Clear to white
      for (int y = 0; y < img.height; y++) {
        for (int x = 0; x < img.width; x++) {
          img.SetPixel(x, y, Color(255, 255, 255, 255));
        }
      }

      // Draw an anti-aliased outlined rectangle
      final profile = LineProfileAA.withWidth(2.0, GammaNone());
      final renderer = OutlineRenderer(img, profile, Color(0, 0, 0, 255));
      final outline = RasterizerOutlineAA(renderer);

      final scale = LineAABasics.line_subpixel_scale;
      outline.moveTo(20 * scale, 20 * scale);
      outline.lineTo(80 * scale, 20 * scale);
      outline.lineTo(80 * scale, 80 * scale);
      outline.lineTo(20 * scale, 80 * scale);
      outline.lineTo(20 * scale, 20 * scale);
      outline.render();

      // Verify that the edges have some black pixels
      int blackPixels = 0;
      for (int x = 18; x <= 82; x++) {
        if (img.getPixel(x, 20).alpha > 0 && img.getPixel(x, 20).red < 200) {
          blackPixels++;
        }
      }
      expect(blackPixels, greaterThan(10)); // Should have drawn a line
    });

    test('render multiple overlapping shapes with transparency', () {
      final img = ImageBuffer(100, 100);
      final ras = ScanlineRasterizer();
      final sl = ScanlineUnpacked8();

      // Clear to white
      for (int y = 0; y < img.height; y++) {
        for (int x = 0; x < img.width; x++) {
          img.SetPixel(x, y, Color(255, 255, 255, 255));
        }
      }

      // Draw a semi-transparent red rectangle
      final rect1 = VertexStorage()
        ..moveTo(20, 20)
        ..lineTo(60, 20)
        ..lineTo(60, 60)
        ..lineTo(20, 60)
        ..closePath();

      ras.add_path(rect1);
      ScanlineRenderer.renderSolid(ras, sl, img, Color(255, 0, 0, 128));

      // Draw a semi-transparent blue rectangle overlapping
      ras.reset();
      final rect2 = VertexStorage()
        ..moveTo(40, 40)
        ..lineTo(80, 40)
        ..lineTo(80, 80)
        ..lineTo(40, 80)
        ..closePath();

      ras.add_path(rect2);
      ScanlineRenderer.renderSolid(ras, sl, img, Color(0, 0, 255, 128));

      // Check the overlap area - should have both red and blue components
      final overlapPixel = img.getPixel(50, 50);
      expect(overlapPixel.red, greaterThan(0));
      expect(overlapPixel.blue, greaterThan(0));

      // Check red-only area
      final redOnlyPixel = img.getPixel(30, 30);
      expect(redOnlyPixel.red, greaterThan(0));
      expect(redOnlyPixel.blue, lessThan(redOnlyPixel.red));

      // Check blue-only area
      final blueOnlyPixel = img.getPixel(70, 70);
      expect(blueOnlyPixel.blue, greaterThan(0));
      expect(blueOnlyPixel.red, lessThan(blueOnlyPixel.blue));
    });

    test('render complex path with curves approximation', () {
      final img = ImageBuffer(200, 200);
      final ras = ScanlineRasterizer();
      final sl = ScanlineUnpacked8();

      // Clear to white
      for (int y = 0; y < img.height; y++) {
        for (int x = 0; x < img.width; x++) {
          img.SetPixel(x, y, Color(255, 255, 255, 255));
        }
      }

      // Draw a star shape using straight lines
      final star = VertexStorage();
      final cx = 100.0;
      final cy = 100.0;
      final outerRadius = 80.0;
      final innerRadius = 30.0;
      final points = 5;

      for (int i = 0; i < points * 2; i++) {
        final angle = (i * 3.14159265359) / points;
        final radius = (i % 2 == 0) ? outerRadius : innerRadius;
        final x = cx + radius * cos(angle);
        final y = cy + radius * sin(angle);

        if (i == 0) {
          star.moveTo(x, y);
        } else {
          star.lineTo(x, y);
        }
      }
      star.closePath();

      ras.add_path(star);
      ScanlineRenderer.renderSolid(
          ras, sl, img, Color(255, 215, 0, 255)); // Gold color

      // Verify center is filled
      final centerPixel = img.getPixel(100, 100);
      expect(centerPixel.red, equals(255));
      expect(centerPixel.green, equals(215));
      expect(centerPixel.blue, equals(0));
    });
  });

  group('PNG Export (Visual Validation)', () {
    test('export rasterized shapes to PNG for visual inspection', () {
      final img = ImageBuffer(400, 300);
      final ras = ScanlineRasterizer();
      final sl = ScanlineUnpacked8();

      // Clear to light gray background
      for (int y = 0; y < img.height; y++) {
        for (int x = 0; x < img.width; x++) {
          img.SetPixel(x, y, Color(240, 240, 240, 255));
        }
      }

      // Draw various shapes
      // 1. Filled rectangle
      final rect = VertexStorage()
        ..moveTo(20, 20)
        ..lineTo(120, 20)
        ..lineTo(120, 120)
        ..lineTo(20, 120)
        ..closePath();
      ras.add_path(rect);
      ScanlineRenderer.renderSolid(ras, sl, img, Color(255, 0, 0, 255));

      // 2. Filled ellipse
      ras.reset();
      final ellipse = Ellipse(220, 70, 50, 50);
      ras.add_path(ellipse);
      ScanlineRenderer.renderSolid(ras, sl, img, Color(0, 255, 0, 255));

      // 3. Rounded rectangle
      ras.reset();
      final roundedRect = RoundedRect(280, 20, 380, 120, 15);
      ras.add_path(roundedRect);
      ScanlineRenderer.renderSolid(ras, sl, img, Color(0, 0, 255, 255));

      // 4. Triangle
      ras.reset();
      final triangle = VertexStorage()
        ..moveTo(70, 200)
        ..lineTo(120, 150)
        ..lineTo(20, 150)
        ..closePath();
      ras.add_path(triangle);
      ScanlineRenderer.renderSolid(ras, sl, img, Color(255, 0, 255, 255));

      // 5. Outlined rectangle with AA
      final profile = LineProfileAA.withWidth(3.0, GammaNone());
      final renderer = OutlineRenderer(img, profile, Color(0, 0, 0, 255));
      final outline = RasterizerOutlineAA(renderer);

      final scale = LineAABasics.line_subpixel_scale;
      outline.moveTo(150 * scale, 150 * scale);
      outline.lineTo(280 * scale, 150 * scale);
      outline.lineTo(280 * scale, 280 * scale);
      outline.lineTo(150 * scale, 280 * scale);
      outline.lineTo(150 * scale, 150 * scale);
      outline.render();

      // Save to PNG (we'll create a simple PNG encoder or skip this in test)
      // For now, just verify that pixels were written
      int nonBackgroundPixels = 0;
      for (int y = 0; y < img.height; y++) {
        for (int x = 0; x < img.width; x++) {
          final pixel = img.getPixel(x, y);
          if (pixel.red != 240 || pixel.green != 240 || pixel.blue != 240) {
            nonBackgroundPixels++;
          }
        }
      }

      expect(nonBackgroundPixels,
          greaterThan(1000)); // Should have drawn many pixels
      print('Rendered $nonBackgroundPixels non-background pixels');
    });
  });
}

// Simple cosine approximation for star test
double cos(double radians) {
  // Taylor series approximation for cos(x)
  final x = radians;
  final x2 = x * x;
  return 1 - x2 / 2 + (x2 * x2) / 24 - (x2 * x2 * x2) / 720;
}

// Simple sine approximation for star test
double sin(double radians) {
  // Taylor series approximation for sin(x)
  final x = radians;
  final x2 = x * x;
  return x - (x * x2) / 6 + (x * x2 * x2) / 120 - (x * x2 * x2 * x2) / 5040;
}
