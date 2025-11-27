import 'dart:io';
import 'package:test/test.dart';
import 'package:agg/src/agg/vertex_source/ellipse.dart';
import 'package:agg/src/agg/vertex_source/rounded_rect.dart';
import 'package:agg/src/agg/vertex_source/stroke.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/scanline_renderer.dart';
import 'package:agg/src/agg/scanline_unpacked8.dart';
import 'package:agg/src/agg/image/png_encoder.dart';

void main() {
  test('Rounded Rect Rendering Test', () {
    const width = 600;
    const height = 400;
    
    final buffer = ImageBuffer(width, height);
    // Clear to white
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        buffer.SetPixel(x, y, Color(255, 255, 255, 255));
      }
    }
    
    final ras = ScanlineRasterizer();
    final sl = ScanlineUnpacked8();
    
    final mX = [100.0, 500.0];
    final mY = [100.0, 350.0];
    
    // Draw ellipses
    for (var i = 0; i < 2; i++) {
      final e = Ellipse(mX[i], mY[i], 3.0, 3.0, 16);
      ras.add_path(e);
      ScanlineRenderer.renderSolid(ras, sl, buffer, Color(54, 54, 54, 255));
    }
    
    // Draw rounded rect
    final d = 0.0;
    final r = RoundedRect(mX[0] + d, mY[0] + d, mX[1] + d, mY[1] + d, 36.0);
    r.normalizeRadius();
    // r.calc(); // Not needed in Dart implementation usually, or handled internally?
    // Let's check RoundedRect implementation.
    
    final stroke = Stroke(r);
    stroke.width = 7.0;
    
    ras.add_path(stroke);
    ScanlineRenderer.renderSolid(ras, sl, buffer, Color(0, 0, 0, 255));
    
    // Save image
    Directory('test/tmp').createSync(recursive: true);
    PngEncoder.saveImage(buffer, 'test/tmp/rounded_rect.png');
    
    // Verify file exists
    expect(File('test/tmp/rounded_rect.png').existsSync(), isTrue);
  });
}
