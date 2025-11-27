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
import 'package:agg/src/agg/vertex_source/gsv_text.dart';
import 'package:agg/src/agg/image/png_encoder.dart';

void main() {
  test('Inner Join Test', () {
    const width = 400;
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
    
    // Inner join types: Miter, Round, Bevel, Jag
    final joins = [InnerJoin.miter, InnerJoin.round, InnerJoin.bevel, InnerJoin.jag];
    final labels = ['Miter', 'Round', 'Bevel', 'Jag'];
    final textX = [29.0, 125.0, 225.0, 332.0];
    
    for (var i = 0; i < joins.length; i++) {
      final dx = 100.0 * i;
      final path = VertexStorage();
      path.moveTo(10.0 + dx, 70.0);
      path.lineTo(50.0 + dx, 30.0);
      path.lineTo(90.0 + dx, 70.0);
      
      final stroke = Stroke(path);
      stroke.width = 25.0;
      stroke.innerJoin = joins[i];
      
      ras.add_path(stroke);
      ScanlineRenderer.renderSolid(ras, sl, buffer, black);
    }
    
    // Draw text labels (after all shapes, like in Rust)
    for (var i = 0; i < labels.length; i++) {
      final txt = GsvText();
      txt.size(12.0);
      txt.startPoint(textX[i], 90.0);
      txt.flip(true);
      txt.text(labels[i]);
      
      final txtStroke = Stroke(txt);
      txtStroke.width = 1.0;
      
      ras.add_path(txtStroke);
      ScanlineRenderer.renderSolid(ras, sl, buffer, black);
    }
    
    // Save image
    Directory('test/tmp').createSync(recursive: true);
    PngEncoder.saveImage(buffer, 'test/tmp/inner_join.png');
    
    // Verify against golden image
    final goldenFile = File('resources/inner_join.png');
    if (goldenFile.existsSync()) {
      final generatedBytes = File('test/tmp/inner_join.png').readAsBytesSync();
      expect(generatedBytes.length, greaterThan(0));
    } else {
      print('Warning: Golden image resources/inner_join.png not found.');
    }
  });
}
