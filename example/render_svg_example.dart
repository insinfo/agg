import 'package:agg/src/agg/agg_gamma_functions.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/image/png_encoder.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/scanline_packed8.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/scanline_renderer.dart';
import 'package:agg/src/agg/svg/svg_parser.dart';
import 'package:agg/src/agg/svg/svg_paint.dart';

void main() {
  // 1. Create Image
  final width = 800;
  final height = 600;
  final buffer = ImageBuffer(width, height);
  
  // Clear to white
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      buffer.SetPixel(x, y, Color(255, 255, 255));
    }
  }

  // 2. Setup Rasterizer with Gamma
  final ras = ScanlineRasterizer();
  ras.gamma(GammaPower(2.2)); // Standard gamma correction
  final sl = ScanlineCachePacked8();

  // 3. Parse SVG (Simple Tiger-like paths or similar)
  // Since we don't have a file, I'll embed a simple complex shape string.
  // This is a star shape.
  final svgContent = '''
    <path d="M 400 100 L 480 300 L 700 300 L 520 420 L 600 600 L 400 480 L 200 600 L 280 420 L 100 300 L 320 300 Z" fill="#FFD700" />
    <path d="M 400 200 L 440 300 L 550 300 L 460 360 L 500 450 L 400 390 L 300 450 L 340 360 L 250 300 L 360 300 Z" fill="#FF4500" />
  ''';

  final shapes = SvgParser.parseString(svgContent);

  // 4. Render Shapes
  for (final shape in shapes) {
    ras.add_path(shape.vertices);
    if (shape.fill is SvgPaintSolid) {
      ScanlineRenderer.renderSolid(ras, sl, buffer, (shape.fill as SvgPaintSolid).color);
    }
  }

  // 5. Save as PNG
  PngEncoder.saveImage(buffer, 'complex_shape.png');
}
