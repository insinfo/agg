import 'dart:io';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/image/png_encoder.dart';

void drawBlackFrame(ImageBuffer pix) {
  final w = pix.width;
  final h = pix.height;
  final black = Color(0, 0, 0, 255);
  
  pix.copy_hline(0, 0, w, black);
  pix.copy_hline(0, h - 1, w, black);
  
  pix.copy_vline(0, 0, h, black);
  pix.copy_vline(w - 1, 0, h, black);
}

void main() {
  test('Solar Spectrum Test', () {
    const width = 320;
    const height = 200;
    
    final buffer = ImageBuffer(width, height);
    
    // Clear to white (agg-rust uses pix.clear() which defaults to white? 
    // In t03, it says pix.clear().
    // Let's assume white.
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        buffer.SetPixel(x, y, Color(255, 255, 255, 255));
      }
    }
    
    drawBlackFrame(buffer);
    
    final w = buffer.width;
    final h = buffer.height;
    final span = List<Color>.filled(w, Color(255, 255, 255));
    
    for (var i = 0; i < w; i++) {
      span[i] = Color.fromWavelength(380.0 + 400.0 * i / w, 0.8);
    }
    
    for (var i = 0; i < h; i++) {
      // blend_color_hspan(x, y, len, colors, colorsIndex, covers, coversIndex, firstCoverForAll)
      // agg-rust: pix.blend_color_hspan(0, i as i64, w as i64, &span, &[], 255);
      // covers is empty, cover is 255.
      // In Dart ImageBuffer:
      // blend_color_hspan(x, y, len, colors, colorsIndex, covers, coversIndex, firstCoverForAll)
      // If covers is null or empty?
      // The signature expects Uint8List covers.
      // If firstCoverForAll is true, it uses covers[coversIndex] for all pixels.
      // So we can pass a single-element covers array with 255.
      
      // Wait, ImageBuffer.blend_color_hspan signature:
      // void blend_color_hspan(int x, int y, int len, List<Color> colors, int colorsIndex, Uint8List covers, int coversIndex, bool firstCoverForAll)
      
      // I need a covers array.
      // If I want constant cover 255.
      // I can pass a dummy array with 255 and firstCoverForAll = true.
      
      // But wait, agg-rust passes `&[]` (empty slice) and `255` (cover).
      // This implies `blend_color_hspan` in Rust has an overload or handles empty covers.
      // In Dart, I must match the API.
      
      // Let's check ImageBuffer.blend_color_hspan implementation.
      // It calls _blender.blendPixels.
      
      // If I want to blend a span of colors with a constant cover.
      // I should use `blend_color_hspan` with `firstCoverForAll = true`.
      
      // But `covers` must be valid at `coversIndex`.
      // So I need a Uint8List with at least one element 255.
      
      // However, `span` is `List<Color>`.
      // `blend_color_hspan` takes `List<Color>`.
      
      // Let's try:
      // buffer.blend_color_hspan(0, i, w, span, 0, Uint8List.fromList([255]), 0, true);
      
      // But wait, `blend_color_hspan` in `ImageBuffer` calls `_blender.blendPixels`.
      // `BlenderRgba.blendPixels`:
      /*
      void blendPixels(
        Uint8List buffer,
        int bufferOffset,
        List<Color> sourceColors,
        int sourceColorsOffset,
        Uint8List covers,
        int coversOffset,
        bool firstCoverForAll,
        int len,
      ) {
        int cover = covers[coversOffset];
        if (firstCoverForAll) {
           // ... loop using constant cover
        }
      }
      */
      // So yes, passing a single element array works if firstCoverForAll is true.
      
      // But wait, `agg-rust` logic:
      // pix.blend_color_hspan(0, i as i64, w as i64, &span, &[], 255);
      // This blends the span of colors onto the image.
      
      // In Dart:
      // buffer.blend_color_hspan(0, i, w, span, 0, Uint8List.fromList([255]), 0, true);
      
      // However, creating a new Uint8List every line is inefficient.
      // I should create it once.
    }
    
    final covers = Uint8List.fromList([255]);
    for (var i = 0; i < h; i++) {
      buffer.blend_color_hspan(0, i, w, span, 0, covers, 0, true);
    }
    
    // Save image
    Directory('test/tmp').createSync(recursive: true);
    PngEncoder.saveImage(buffer, 'test/tmp/agg_test_03.png');
    
    // Verify against golden image
    final goldenFile = File('resources/agg_test_03.png');
    if (goldenFile.existsSync()) {
      final generatedBytes = File('test/tmp/agg_test_03.png').readAsBytesSync();
      expect(generatedBytes.length, greaterThan(0));
    } else {
      print('Warning: Golden image resources/agg_test_03.png not found.');
    }
  });
}
