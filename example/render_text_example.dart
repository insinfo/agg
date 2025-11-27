import 'package:agg/src/agg/agg_gamma_functions.dart';
import 'package:agg/src/agg/image/png_encoder.dart';
import 'package:agg/src/agg/transform/affine.dart';
import 'package:agg/src/agg/vertex_source/apply_transform.dart';
import 'package:agg/src/agg/vertex_source/glyph_vertex_source.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/scanline_renderer.dart';
import 'package:agg/src/agg/scanline_packed8.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/typography/text_layout/glyph_layout.dart';
import 'package:agg/src/typography/openfont/open_font_reader.dart';
import 'dart:io';

void main() async {
  // 1. Load Font
  final fontPath = 'agg-sharp/liberation-fonts-ttf-1.07.0/LiberationSans-Regular.ttf';
  final file = File(fontPath);
  if (!file.existsSync()) {
    print('Font file not found: $fontPath');
    // Try to find it relative to current dir if running from root
    return;
  }
  
  final bytes = await file.readAsBytes();
  final reader = OpenFontReader();
  final typeface = reader.read(bytes);
  
  if (typeface == null) {
    print('Failed to load typeface');
    return;
  }
  
  print('Loaded font: ${typeface.name}');
  
  // 2. Layout Text
  final text = "Hello World!";
  final fontSize = 48.0;
  final scale = typeface.calculateScaleToPixel(fontSize);
  
  final layout = GlyphLayout();
  layout.typeface = typeface;
  layout.layout(text);
  final scaledPlans = layout.generateGlyphPlans(scale);
  
  print('Layout: "$text" (${scaledPlans.count} glyphs)');
  
  // 3. Setup AGG
  final width = 400;
  final height = 100;
  final buffer = ImageBuffer(width, height);
  
  // Clear to white
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      buffer.SetPixel(x, y, Color(255, 255, 255));
    }
  }
  
  final ras = ScanlineRasterizer();
  ras.gamma(GammaPower(2.0)); // Apply gamma correction
  final sl = ScanlineCachePacked8(); 
  
  // 4. Render
  final startX = 20.0;
  final startY = 70.0; // Baseline
  
  for (var i = 0; i < scaledPlans.count; i++) {
    final plan = scaledPlans[i];
    final glyph = typeface.getGlyph(plan.glyphIndex);
    
    final glyphSource = GlyphVertexSource(glyph);
    
    // Transform: Scale -> Translate
    final mtx = Affine.identity();
    // Scale font units to pixels and flip Y (because image Y is down)
    mtx.scale(scale, -scale);
    
    // Position
    // plan.x is relative to start of text.
    // plan.y is offset from baseline.
    mtx.translate(startX + plan.x, startY - plan.y);
    
    final transSource = ApplyTransform(glyphSource, mtx);
    
    ras.add_path(transSource);
    
    // Render to scanlines (Black text)
    ScanlineRenderer.renderSolid(ras, sl, buffer, Color(0, 0, 0));
  }
  
  // 5. Save
  PngEncoder.saveImage(buffer, 'hello_world.png');
}
