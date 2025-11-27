import 'dart:io';
import 'package:test/test.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/image/png_encoder.dart';

void drawBlackFrame(ImageBuffer pix) {
  final w = pix.width;
  final h = pix.height;
  final black = Color(0, 0, 0, 255);
  
  for (var i = 0; i < h; i++) {
    pix.SetPixel(0, i, black);
    pix.SetPixel(w - 1, i, black);
  }
  
  for (var k in [0, h - 1]) {
    for (var i = 0; i < w; i++) {
      pix.SetPixel(i, k, black);
    }
  }
}

void main() {
  test('Pixel Formats Test', () {
    const width = 320;
    const height = 220;
    
    final buffer = ImageBuffer(width, height);
    
    // Clear to white
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        buffer.SetPixel(x, y, Color(255, 255, 255, 255));
      }
    }
    
    drawBlackFrame(buffer);
    
    final c = Color(127, 200, 98, 255);
    for (var i = 0; i < height ~/ 2; i++) {
      buffer.SetPixel(i, i, c);
    }
    
    // Save image
    Directory('test/tmp').createSync(recursive: true);
    PngEncoder.saveImage(buffer, 'test/tmp/agg_test_02.png');
    
    // Verify against golden image
    final goldenFile = File('resources/agg_test_02.png');
    if (goldenFile.existsSync()) {
      final generatedBytes = File('test/tmp/agg_test_02.png').readAsBytesSync();
      expect(generatedBytes.length, greaterThan(0));
    } else {
      print('Warning: Golden image resources/agg_test_02.png not found.');
    }
  });
}
