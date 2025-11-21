import 'dart:typed_data';

import 'package:agg/src/agg/graphics2D.dart';
import 'package:agg/src/agg/image/iimage_float.dart';
import 'package:agg/src/agg/image/raster_buffer_accessors.dart';
import 'package:agg/src/agg/primitives/color_f.dart';
import 'package:agg/src/agg/primitives/rectangle_int.dart';
import 'package:agg/src/vector_math/vector2.dart';
import 'package:test/test.dart';
import 'package:agg/src/shared/ref_param.dart';

class _FloatImage implements IImageFloat {
  @override
  final int width;
  @override
  final int height;
  final Float32List _buffer;
  final int _stride;

  _FloatImage(this.width, this.height)
      : _buffer = Float32List(width * height * 4),
        _stride = width * 4;

  @override
  int get bitDepth => 128;

  @override
  Vector2 originOffset = Vector2.zero;

  @override
  RectangleInt getBounds() => RectangleInt(0, 0, width - 1, height - 1);

  @override
  int getBufferOffsetY(int y) => y * _stride;

  @override
  int getBufferOffsetXY(int x, int y) => getBufferOffsetY(y) + x * 4;

  @override
  Float32List getBuffer() => _buffer;

  @override
  int getFloatsBetweenPixelsInclusive() => 4;

  @override
  Graphics2D newGraphics2D() =>
      throw UnimplementedError('Not needed for accessor tests');

  @override
  void markImageChanged() {}
}

void main() {
  test('ImageBufferAccessorCommonFloat returns contiguous spans', () {
    final img = _FloatImage(2, 1);
    img.getBuffer().setAll(0, [0.1, 0.2, 0.3, 1.0, 0.4, 0.5, 0.6, 1.0]);

    final acc = ImageBufferAccessorCommonFloat(img);
    final offset = RefParam<int>(0);

    final buf = acc.span(0, 0, 2, offset);
    expect(offset.value, equals(0));
    expect(buf[1], closeTo(0.2, 1e-6));

    final bufNext = acc.nextX(offset);
    expect(bufNext, same(buf));
    expect(offset.value, equals(img.getBufferOffsetXY(1, 0)));
    expect(bufNext[offset.value], closeTo(0.4, 1e-6));
  });

  test('ImageBufferAccessorClipFloat uses background outside bounds', () {
    final img = _FloatImage(1, 1);
    img.getBuffer().setAll(0, [0.2, 0.2, 0.2, 1.0]);
    final acc = ImageBufferAccessorClipFloat(img, ColorF(0.9, 0.8, 0.7, 0.5));
    final offset = RefParam<int>(0);

    final outside = acc.span(-1, -1, 1, offset);
    expect(outside[0], closeTo(0.9, 1e-6));
    expect(outside[3], closeTo(0.5, 1e-6));
    expect(offset.value, equals(0));

    final inside = acc.span(0, 0, 1, offset);
    expect(inside, same(img.getBuffer()));
    expect(offset.value, equals(img.getBufferOffsetXY(0, 0)));
  });
}
