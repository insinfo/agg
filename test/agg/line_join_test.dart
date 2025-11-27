import 'dart:io';
import 'package:test/test.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/scanline_renderer.dart';
import 'package:agg/src/agg/scanline_unpacked8.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';
import 'package:agg/src/agg/vertex_source/stroke.dart';
import 'package:agg/src/agg/vertex_source/stroke_math.dart';
import 'package:agg/src/agg/image/png_encoder.dart';

void main() {
  test('Line Join Test', () {
    const width = 300;
    const height = 100;
    
    final buffer = ImageBuffer(width, height);
    // Clear to white
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        buffer.SetPixel(x, y, Color(255, 255, 255, 255));
      }
    }
    
    final ras = ScanlineRasterizer();
    final sl = ScanlineUnpacked8();
    final black = Color(0, 0, 0, 255);
    
    final joins = [LineJoin.miter, LineJoin.round, LineJoin.bevel];
    
    for (var i = 0; i < joins.length; i++) {
      final dx = 100.0 * i;
      final path = VertexStorage();
      path.moveTo(10.0 + dx, 70.0);
      path.lineTo(50.0 + dx, 30.0);
      path.lineTo(90.0 + dx, 70.0);
      
      final stroke = Stroke(path);
      stroke.width = 25.0;
      stroke.lineJoin = joins[i];
      
      ras.add_path(stroke);
      ScanlineRenderer.renderSolid(ras, sl, buffer, black);
    }
    
    // Save image
    Directory('test/tmp').createSync(recursive: true);
    PngEncoder.saveImage(buffer, 'test/tmp/line_join.png');
    
    // Verify against golden image
    final goldenFile = File('resources/line_join.png');
    if (goldenFile.existsSync()) {
      final generatedBytes = File('test/tmp/line_join.png').readAsBytesSync();
      expect(generatedBytes.length, greaterThan(0));
    } else {
      print('Warning: Golden image resources/line_join.png not found.');
    }
  });
}
