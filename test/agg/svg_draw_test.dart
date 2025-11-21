import 'package:agg/src/agg/graphics2D.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:test/test.dart';

void main() {
  test('drawSvgString paints path', () {
    final img = ImageBuffer(4, 4);
    final g = img.newGraphics2D() as BasicGraphics2D;
    g.clear(Color.transparent);

    g.drawSvgString('<path d="M 0 0 L 3 0 L 0 3 Z" fill="#ff0000"/>');

    expect(img.getPixel(0, 0).alpha, greaterThan(0));
    expect(img.getPixel(3, 3).alpha, equals(0));
  });
}
