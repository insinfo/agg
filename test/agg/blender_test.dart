import 'package:agg/src/agg/image/blender_bgra.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/scanline_renderer.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/scanline_unpacked8.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';
import 'package:test/test.dart';

void main() {
  test('BlenderBGRA writes channel order correctly', () {
    final img = ImageBuffer(1, 1, blender: BlenderBgra());
    img.SetPixel(0, 0, Color(255, 0, 128, 200)); // R=255,G=0,B=128,A=200
    final buf = img.getBuffer();
    expect(buf[0], equals(128)); // B
    expect(buf[1], equals(0)); // G
    expect(buf[2], equals(255)); // R
    expect(buf[3], equals(200)); // A
  });

  test('Scanline renderer clips spans to image bounds', () {
    // Draw a 4x4 rect starting at -2,-2 should only fill inside image.
    final img = ImageBuffer(4, 4);
    final ras = ScanlineRasterizer();
    final sl = ScanlineUnpacked8();
    final path = VertexStorage()
      ..moveTo(-2, -2)
      ..lineTo(3, -2)
      ..lineTo(3, 3)
      ..lineTo(-2, 3)
      ..closePath();
    ras.add_path(path);
    ScanlineRenderer.renderSolid(ras, sl, img, Color(0, 0, 0, 255));
    int filled = 0;
    for (int y = 0; y < 4; y++) {
      for (int x = 0; x < 4; x++) {
        if (img.getPixel(x, y).alpha > 0) filled++;
      }
    }
    expect(filled, greaterThan(0)); // clipped draw didn't crash and touched pixels
  });
}
