import 'package:agg/src/agg/image/blender_bgra.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/scanline_renderer.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/scanline_unpacked8.dart';
import 'package:agg/src/agg/scanline_packed8.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';
import 'package:agg/src/agg/image/blender_premult_rgba.dart';
import 'package:agg/src/agg/image/blender_premult_bgra.dart';
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

  test('BlenderPremultRgba stores and blends premultiplied', () {
    final img = ImageBuffer(1, 1, blender: BlenderPremultRgba());
    img.SetPixel(0, 0, Color(200, 100, 50, 128));
    final buf = img.getBuffer();
    // Stored premultiplied.
    expect(buf[0], closeTo(200 * 128 / 255, 1));
    expect(buf[3], equals(128));

    // Blend another half-transparent pixel; alpha should increase.
    img.BlendPixel(0, 0, Color(0, 0, 255, 128), 255);
    expect(img.getPixel(0, 0).alpha, greaterThan(128));
  });

  test('BlenderPremultBgra stores BGRA premultiplied', () {
    final img = ImageBuffer(1, 1, blender: BlenderPremultBgra());
    img.SetPixel(0, 0, Color(10, 20, 30, 64));
    final buf = img.getBuffer();
    expect(buf[0], closeTo(30 * 64 / 255, 1)); // B premult
    expect(buf[2], closeTo(10 * 64 / 255, 1)); // R premult
    expect(buf[3], equals(64));
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

  test('packed scanline renders uniform cover spans', () {
    final img = ImageBuffer(2, 1);
    final ras = ScanlineRasterizer();
    final sl = ScanlineCachePacked8();
    final path = VertexStorage()
      ..moveTo(0, 0)
      ..lineTo(2, 0)
      ..lineTo(2, 1)
      ..lineTo(0, 1)
      ..closePath();
    ras.add_path(path);
    ScanlineRenderer.renderSolid(ras, sl, img, Color(0, 0, 0, 200));
    expect(img.getPixel(0, 0).alpha, greaterThan(0));
    expect(img.getPixel(1, 0).alpha, greaterThan(0));
  });
}
