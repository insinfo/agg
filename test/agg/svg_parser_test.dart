import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/svg/svg_parser.dart';
import 'package:agg/src/agg/svg/svg_paint.dart';
import 'package:test/test.dart';

void main() {
  test('parses simple path with move/line/close', () {
    final items = SvgParser.parseString('<path d="M 0 0 L 10 0 L 10 10 Z" fill="#ff0000"/>');
    expect(items, hasLength(1));
    expect(items.first.fill, isA<SvgPaintSolid>());
    expect((items.first.fill as SvgPaintSolid).color, equals(Color(255, 0, 0)));
    expect(items.first.vertices.count, greaterThan(0));
  });

  test('parses polygon points', () {
    final items = SvgParser.parseString('<polygon points="0,0 5,0 5,5 0,5" fill="#000000" />', flipY: true);
    expect(items, hasLength(1));
    // Check 3rd vertex (5,5) -> (5,-5)
    // Vertices might include close command, so index might vary if not careful, but usually it's direct.
    // VertexStorage stores commands and coords.
    // 0: MoveTo 0,0
    // 1: LineTo 5,0
    // 2: LineTo 5,5 -> 5,-5
    expect(items.first.vertices[2].y, equals(-5.0));
  });
}
