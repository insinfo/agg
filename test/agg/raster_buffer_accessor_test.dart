import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/image/raster_buffer_accessors.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/shared/ref_param.dart';
import 'package:test/test.dart';

void main() {
  test('ImageBufferAccessorCommon walks spans and offsets', () {
    final img = ImageBuffer(2, 1);
    img.SetPixel(0, 0, Color(1, 2, 3, 255));
    img.SetPixel(1, 0, Color(4, 5, 6, 255));

    final acc = ImageBufferAccessorCommon(img);
    final offset = RefParam<int>(0);

    final buf = acc.span(0, 0, 2, offset);
    expect(offset.value, equals(0)); // first pixel
    expect(buf[offset.value], equals(1));

    final bufNext = acc.nextX(offset);
    expect(bufNext, same(buf)); // contiguous access
    expect(offset.value, equals(img.getBufferOffsetXY(1, 0)));
    expect(bufNext[offset.value], equals(4));
  });

  test('ImageBufferAccessorClip returns fallback for out-of-bounds', () {
    final img = ImageBuffer(2, 2);
    final acc = ImageBufferAccessorClip(img, Color(9, 8, 7, 255));
    final offset = RefParam<int>(0);

    final outside = acc.span(-1, 0, 1, offset);
    expect(outside, isNot(equals(img.getBuffer())));
    expect(outside[0], equals(9));
    expect(offset.value, equals(0));

    final inside = acc.nextX(offset);
    expect(inside, same(img.getBuffer()));
    expect(offset.value, equals(img.getBufferOffsetXY(0, 0)));
  });
}
