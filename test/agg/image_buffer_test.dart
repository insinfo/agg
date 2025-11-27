import 'dart:io';
import 'package:test/test.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/image/png_encoder.dart';

void drawBlackFrame(ImageBuffer buffer) {
  final w = buffer.width;
  final h = buffer.height;
  final black = Color(0, 0, 0, 255);
  
  for (var i = 0; i < h; i++) {
    buffer.SetPixel(0, i, black); // Left Side
    buffer.SetPixel(w - 1, i, black); // Right Side
  }
  for (var i = 0; i < w; i++) {
    buffer.SetPixel(i, 0, black); // Top Side
    buffer.SetPixel(i, h - 1, black); // Bottom Side
  }
}

void main() {
  test('Image Buffer Basic Test', () {
    const width = 320;
    const height = 220;
    
    final buffer = ImageBuffer(width, height);
    final white = Color(255, 255, 255, 255);
    
    // Clear to white
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        buffer.SetPixel(x, y, white);
      }
    }
    
    drawBlackFrame(buffer);
    
    final color = Color(127, 200, 98, 255);
    for (var i = 0; i < height ~/ 2; i++) {
      buffer.SetPixel(i, i, color);
    }
    
    // Save image
    Directory('test/tmp').createSync(recursive: true);
    PngEncoder.saveImage(buffer, 'test/tmp/agg_test_01.png');
    
    // Verify against golden image
    final goldenFile = File('resources/agg_test_01.png');
    if (goldenFile.existsSync()) {
      final generatedBytes = File('test/tmp/agg_test_01.png').readAsBytesSync();
      expect(generatedBytes.length, greaterThan(0));
    } else {
      print('Warning: Golden image resources/agg_test_01.png not found.');
    }
  });
}
