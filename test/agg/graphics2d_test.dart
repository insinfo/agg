import 'package:agg/src/agg/graphics2D.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:test/test.dart';
import 'dart:math' as math;

void main() {
  test('clear fills entire buffer', () {
    final img = ImageBuffer(4, 4);
    final g = img.newGraphics2D() as BasicGraphics2D;
    g.clear(Color(10, 20, 30, 255));
    for (int y = 0; y < img.height; y++) {
      for (int x = 0; x < img.width; x++) {
        final c = img.getPixel(x, y);
        expect(c.red, 10);
        expect(c.green, 20);
        expect(c.blue, 30);
        expect(c.alpha, 255);
      }
    }
  });

  test('fillRect paints interior', () {
    final img = ImageBuffer(6, 6);
    final g = img.newGraphics2D() as BasicGraphics2D;
    g.clear(Color.transparent);
    g.fillRect(1, 1, 4, 4, Color(0, 0, 255, 255));
    expect(img.getPixel(2, 2).blue, 255);
    expect(img.getPixel(0, 0).alpha, 0);
  });

  test('strokeRect draws outline', () {
    final img = ImageBuffer(6, 6);
    final g = img.newGraphics2D() as BasicGraphics2D;
    g.clear(Color.transparent);
    g.strokeRect(1, 1, 4, 4, Color(255, 0, 0, 255), thickness: 1.0);
    expect(img.getPixel(1, 1).alpha, greaterThan(0));
    expect(img.getPixel(4, 4).alpha, greaterThan(0));
    // Interior should remain transparent for stroke-only.
    expect(img.getPixel(3, 3).alpha, equals(0));
    expect(img.getPixel(0, 0).alpha, equals(0));
    expect(img.getPixel(5, 5).alpha, equals(0));
  });

  test('fillCircle paints center', () {
    final img = ImageBuffer(8, 8);
    final g = img.newGraphics2D() as BasicGraphics2D;
    g.clear(Color.transparent);
    g.fillCircle(4, 4, 2, Color(0, 255, 0, 255));
    expect(img.getPixel(4, 4).green, 255);
    expect(img.getPixel(0, 0).alpha, equals(0));
  });

  test('fillArc paints wedge only', () {
    final img = ImageBuffer(8, 8);
    final g = img.newGraphics2D() as BasicGraphics2D;
    g.clear(Color.transparent);
    // Quarter arc in top-right quadrant.
    g.fillArc(4, 4, 3, 3, 0, math.pi / 2, Color(0, 0, 255, 255));
    expect(img.getPixel(6, 6).alpha, greaterThan(0));
    expect(img.getPixel(2, 2).alpha, equals(0));
  });

  test('strokeCircle draws perimeter', () {
    final img = ImageBuffer(10, 10);
    final g = img.newGraphics2D() as BasicGraphics2D;
    g.clear(Color.transparent);
    g.strokeCircle(5, 5, 3, Color(255, 0, 0, 255), thickness: 2.0);
    expect(img.getPixel(8, 5).alpha, greaterThan(0));
    expect(img.getPixel(5, 5).alpha, equals(0)); // center remains empty
  });

  test('strokeArc draws segment', () {
    final img = ImageBuffer(10, 10);
    final g = img.newGraphics2D() as BasicGraphics2D;
    g.clear(Color.transparent);
    g.strokeArc(5, 5, 3, 3, math.pi, math.pi / 2, Color(0, 255, 0, 255), thickness: 1.5);
    expect(img.getPixel(2, 5).alpha, greaterThan(0)); // leftmost part
    expect(img.getPixel(5, 8).alpha, equals(0)); // bottom untouched
  });
}
