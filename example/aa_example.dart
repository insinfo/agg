import 'dart:io';
import 'package:agg/agg.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/scanline_packed8.dart';
import 'package:agg/src/agg/scanline_renderer.dart';
import 'package:agg/src/agg/vertex_source/ellipse.dart';
import 'package:agg/src/agg/vertex_source/rounded_rect.dart';
import 'package:agg/src/agg/vertex_source/stroke.dart';
import 'package:agg/src/agg/image/png_encoder.dart';

void main() {
  const width = 480;
  const height = 350;
  
  final buffer = ImageBuffer(width, height);
  // Clear to black
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      buffer.SetPixel(x, y, Color(0, 0, 0, 255));
    }
  }
  
  final ras = ScanlineRasterizer();
  final sl = ScanlineCachePacked8();
  
  // Control points
  final x1 = 100.0;
  final y1 = 100.0;
  final x2 = 500.0; 
  final y2 = 350.0;
  
  // Render control circles
  final e = Ellipse();
  e.init(x1, y1, 3, 3, 16);
  ras.add_path(e);
  ScanlineRenderer.renderSolid(ras, sl, buffer, Color(127, 127, 127));
  
  e.init(x2, y2, 3, 3, 16);
  ras.add_path(e);
  ScanlineRenderer.renderSolid(ras, sl, buffer, Color(127, 127, 127));
  
  // Rounded Rectangle
  final r = RoundedRect(x1, y1, x2, y2, 10);
  r.normalizeRadius();
  
  // Outline
  final p = Stroke(r);
  p.width = 1.0;
  ras.add_path(p);
  
  // Render with red color
  ScanlineRenderer.renderSolid(ras, sl, buffer, Color(255, 1, 1));
  
  // Save image
  final filename = 'aa_test.png';
  PngEncoder.saveImage(buffer, filename);
  print('Saved $filename');
}
