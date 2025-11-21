import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/rasterizer_outline_aa.dart';
import 'package:agg/src/agg/scanline_renderer.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/scanline_unpacked8.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';
import 'package:agg/src/agg/outline_image_renderer.dart';
import 'package:agg/src/agg/line_aa_basics.dart';
import 'package:test/test.dart';

void main() {
  test('scanline renderer fills rectangle', () {
    final img = ImageBuffer(4, 4);
    final ras = ScanlineRasterizer();
    final sl = ScanlineUnpacked8();

    final path = VertexStorage()
      ..moveTo(0, 0)
      ..lineTo(3, 0)
      ..lineTo(3, 3)
      ..lineTo(0, 3)
      ..closePath();

    ras.add_path(path);
    ScanlineRenderer.renderSolid(ras, sl, img, Color(255, 0, 0));

    expect(img.getPixel(1, 1).red, greaterThan(0));
    expect(img.getPixel(1, 1).alpha, equals(255));
    // Border pixels should also be drawn by the fill.
    expect(img.getPixel(0, 0).alpha, greaterThan(0));
  });

  test('outline AA renderer draws anti-aliased line', () {
    final img = ImageBuffer(6, 6);
    final renderer = ImageLineRenderer(img, color: Color(0, 0, 0, 255));
    final outline = RasterizerOutlineAA(renderer);

    outline.moveTo(0, 0);
    outline.lineTo(
      5 * LineAABasics.line_subpixel_scale,
      5 * LineAABasics.line_subpixel_scale,
    );
    outline.render();

    // Should mark some pixels with nonzero alpha.
    int touched = 0;
    for (int y = 0; y < img.height; y++) {
      for (int x = 0; x < img.width; x++) {
        if (img.getPixel(x, y).alpha > 0) touched++;
      }
    }
    expect(touched, greaterThanOrEqualTo(2));
  });

  test('thick line touches multiple rows', () {
    final img = ImageBuffer(8, 8);
    final renderer = ImageLineRenderer(img, color: Color(0, 0, 0, 255), thickness: 3.0);
    final outline = RasterizerOutlineAA(renderer);

    outline.moveTo(0, 2 * LineAABasics.line_subpixel_scale);
    outline.lineTo(7 * LineAABasics.line_subpixel_scale, 2 * LineAABasics.line_subpixel_scale);
    outline.render();

    // Ensure multiple rows have coverage due to thickness.
    final rowsTouched = <int>{};
    for (int y = 0; y < img.height; y++) {
      for (int x = 0; x < img.width; x++) {
        if (img.getPixel(x, y).alpha > 0) rowsTouched.add(y);
      }
    }
    expect(rowsTouched.length, greaterThanOrEqualTo(3));
  });

  test('round caps extend footprint', () {
    final img = ImageBuffer(8, 8);
    final renderer = ImageLineRenderer(
      img,
      color: Color(0, 0, 0, 255),
      thickness: 3.0,
      cap: CapStyle.round,
    );
    final outline = RasterizerOutlineAA(renderer);

    outline.moveTo(2 * LineAABasics.line_subpixel_scale, 4 * LineAABasics.line_subpixel_scale);
    outline.lineTo(5 * LineAABasics.line_subpixel_scale, 4 * LineAABasics.line_subpixel_scale);
    outline.render();

    // Caps should extend beyond the main span: check a pixel just before start.
    bool leftHit = false;
    bool rightHit = false;
    for (int x = 0; x < img.width; x++) {
      final a = img.getPixel(x, 4).alpha;
      if (x < 2 && a > 0) leftHit = true;
      if (x > 5 && a > 0) rightHit = true;
    }
    expect(leftHit, isTrue);
    expect(rightHit, isTrue);
  });
}
