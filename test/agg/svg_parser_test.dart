import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/svg/svg_parser.dart';
import 'package:test/test.dart';

void main() {
  test('parses simple path with move/line/close', () {
    final items = SvgParser.parseString('<path d="M 0 0 L 10 0 L 10 10 Z" fill="#ff0000"/>');
    expect(items, hasLength(1));
    expect(items.first.fill, equals(Color(255, 0, 0)));
    expect(items.first.vertices.count, greaterThan(0));
  });

  test('parses polygon points', () {
    final items = SvgParser.parseString('<polygon points="0,0 5,0 5,5 0,5" />', flipY: true);
    expect(items, hasLength(1));
    // First vertex Y should be flipped negative.
    expect(items.first.vertices[0].y.isNegative, isTrue);
  });
}
