import 'package:agg/src/agg/graphics2D.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/rasterizer_compound_aa.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';
import 'package:test/test.dart';

VertexStorage _rectPath(double x1, double y1, double x2, double y2) {
  final path = VertexStorage()
    ..moveTo(x1, y1)
    ..lineTo(x2, y1)
    ..lineTo(x2, y2)
    ..lineTo(x1, y2)
    ..closePath();
  return path;
}

void main() {
  test('RasterizerCompoundAa emits each style in isolation', () {
    final img = ImageBuffer(4, 2);
    final compound = RasterizerCompoundAa()
      ..defineStyle(0, Color(255, 0, 0, 255))
      ..defineStyle(1, Color(0, 0, 255, 255));

    compound.addPath(_rectPath(0, 0, 1.5, 2), 0);
    compound.addPath(_rectPath(1.5, 0, 4, 2), 1);

    compound.render(img);

    expect(img.getPixel(0, 1).red, equals(255));
    expect(img.getPixel(0, 1).green, equals(0));
    expect(img.getPixel(3, 1).blue, equals(255));
  });

  test('RasterizerCompoundAa respects layer order', () {
    final img = ImageBuffer(2, 2);
    final compound = RasterizerCompoundAa()
      ..defineStyle(0, Color(255, 0, 0, 255))
      ..defineStyle(1, Color(0, 0, 255, 255));

    final overlay = _rectPath(0, 0, 2, 2);
    compound.addPath(overlay, 1);
    compound.addPath(overlay, 0);
    compound.layerOrder = CompoundLayerOrder.inverse;

    compound.render(img);
    expect(img.getPixel(1, 1).red, equals(255));
  });

  test('BasicGraphics2D renders compound shapes', () {
    final img = ImageBuffer(3, 3);
    final compound = RasterizerCompoundAa()
      ..defineStyle(0, Color(0, 255, 0, 255))
      ..addPath(_rectPath(0, 0, 3, 3), 0);

    final graphics = img.newGraphics2D();
    if (graphics is BasicGraphics2D) {
      graphics.renderCompound(compound);
    } else {
      compound.render(img);
    }

    expect(img.getPixel(1, 1).green, equals(255));
  });
}
