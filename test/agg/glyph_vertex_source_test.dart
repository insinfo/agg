import 'package:agg/src/shared/ref_param.dart';
import 'package:test/test.dart';
import 'package:agg/src/typography/openfont/glyph.dart';
import 'package:agg/src/typography/openfont/tables/utils.dart';
import 'package:agg/src/agg/vertex_source/glyph_vertex_source.dart';
import 'package:agg/src/agg/vertex_source/path_commands.dart';

void main() {
  group('GlyphVertexSource', () {
    test('Simple Square (All OnCurve)', () {
      // 0,0 -> 100,0 -> 100,100 -> 0,100
      final glyph = Glyph.fromTrueType(
        glyphPoints: [
          GlyphPointF(0, 0, true),
          GlyphPointF(100, 0, true),
          GlyphPointF(100, 100, true),
          GlyphPointF(0, 100, true),
        ],
        contourEndPoints: [3],
        bounds: Bounds(0, 0, 100, 100),
        glyphIndex: 1,
      );

      final source = GlyphVertexSource(glyph);
      final x = RefParam(0.0);
      final y = RefParam(0.0);
      final commands = <FlagsAndCommand>[];
      final points = <({double x, double y})>[];

      source.rewind();
      while (true) {
        final cmd = source.vertex(x, y);
        if (cmd.isStop) break;
        commands.add(cmd);
        points.add((x: x.value, y: y.value));
      }

      // Expected: MoveTo(0,0), LineTo(100,0), LineTo(100,100), LineTo(0,100), ClosePoly
      expect(commands.length, 5);
      expect(commands[0].isMoveTo, isTrue);
      expect(points[0], (x: 0.0, y: 0.0));
      
      expect(commands[1].isLineTo, isTrue);
      expect(points[1], (x: 100.0, y: 0.0));
      
      expect(commands[2].isLineTo, isTrue);
      expect(points[2], (x: 100.0, y: 100.0));
      
      expect(commands[3].isLineTo, isTrue);
      expect(points[3], (x: 0.0, y: 100.0));
      
      expect(commands[4].isEndPoly, isTrue);
      expect(commands[4].isClose, isTrue);
    });

    test('Simple Curve (On, Off, On)', () {
      // 0,0 -> (50,50 off) -> 100,0
      final glyph = Glyph.fromTrueType(
        glyphPoints: [
          GlyphPointF(0, 0, true),
          GlyphPointF(50, 50, false),
          GlyphPointF(100, 0, true),
        ],
        contourEndPoints: [2],
        bounds: Bounds(0, 0, 100, 50),
        glyphIndex: 1,
      );

      final source = GlyphVertexSource(glyph);
      final x = RefParam(0.0);
      final y = RefParam(0.0);
      final commands = <FlagsAndCommand>[];
      final points = <({double x, double y})>[];

      source.rewind();
      while (true) {
        final cmd = source.vertex(x, y);
        if (cmd.isStop) break;
        commands.add(cmd);
        points.add((x: x.value, y: y.value));
      }

      // Expected: MoveTo(0,0), Curve3(50,50), Curve3(100,0), ClosePoly
      // Note: Curve3 is emitted twice (control, end)
      expect(commands.length, 4);
      expect(commands[0].isMoveTo, isTrue);
      expect(points[0], (x: 0.0, y: 0.0));
      
      expect(commands[1].isCurve3, isTrue);
      expect(points[1], (x: 50.0, y: 50.0)); // Control
      
      expect(commands[2].isCurve3, isTrue);
      expect(points[2], (x: 100.0, y: 0.0)); // End
      
      expect(commands[3].isEndPoly, isTrue);
    });

    test('Implicit OnCurve (On, Off, Off, On)', () {
      // 0,0 -> (25,50 off) -> (75,50 off) -> 100,0
      // Should produce:
      // MoveTo(0,0)
      // Curve3(25,50), Curve3(50,50) (Midpoint of 25,50 and 75,50)
      // Curve3(75,50), Curve3(100,0)
      
      final glyph = Glyph.fromTrueType(
        glyphPoints: [
          GlyphPointF(0, 0, true),
          GlyphPointF(25, 50, false),
          GlyphPointF(75, 50, false),
          GlyphPointF(100, 0, true),
        ],
        contourEndPoints: [3],
        bounds: Bounds(0, 0, 100, 50),
        glyphIndex: 1,
      );

      final source = GlyphVertexSource(glyph);
      final x = RefParam(0.0);
      final y = RefParam(0.0);
      final commands = <FlagsAndCommand>[];
      final points = <({double x, double y})>[];

      source.rewind();
      while (true) {
        final cmd = source.vertex(x, y);
        if (cmd.isStop) break;
        commands.add(cmd);
        points.add((x: x.value, y: y.value));
      }

      expect(commands.length, 6);
      expect(commands[0].isMoveTo, isTrue);
      expect(points[0], (x: 0.0, y: 0.0));
      
      // First curve segment
      expect(commands[1].isCurve3, isTrue);
      expect(points[1], (x: 25.0, y: 50.0)); // Control 1
      
      expect(commands[2].isCurve3, isTrue);
      expect(points[2], (x: 50.0, y: 50.0)); // Midpoint (Implicit OnCurve)
      
      // Second curve segment
      expect(commands[3].isCurve3, isTrue);
      expect(points[3], (x: 75.0, y: 50.0)); // Control 2
      
      expect(commands[4].isCurve3, isTrue);
      expect(points[4], (x: 100.0, y: 0.0)); // End
      
      expect(commands[5].isEndPoly, isTrue);
    });
    
    test('Start with OffCurve', () {
      // (0,50 off) -> (50,0 on) -> (100,50 off) -> (50,100 on)
      // Start point should be midpoint of last(50,100) and first(0,50)?
      // No, start point logic:
      // Start is OffCurve(0,50). End is OnCurve(50,100).
      // So logical start is End(50,100).
      // MoveTo(50,100).
      // Then process points starting from index 0.
      // Point 0 is OffCurve(0,50). Next is OnCurve(50,0).
      // Curve3(0,50), Curve3(50,0).
      // Point 2 is OffCurve(100,50). Next is OnCurve(50,100).
      // Curve3(100,50), Curve3(50,100).
      
      final glyph = Glyph.fromTrueType(
        glyphPoints: [
          GlyphPointF(0, 50, false),
          GlyphPointF(50, 0, true),
          GlyphPointF(100, 50, false),
          GlyphPointF(50, 100, true),
        ],
        contourEndPoints: [3],
        bounds: Bounds(0, 0, 100, 100),
        glyphIndex: 1,
      );

      final source = GlyphVertexSource(glyph);
      final x = RefParam(0.0);
      final y = RefParam(0.0);
      final commands = <FlagsAndCommand>[];
      final points = <({double x, double y})>[];

      source.rewind();
      while (true) {
        final cmd = source.vertex(x, y);
        if (cmd.isStop) break;
        commands.add(cmd);
        points.add((x: x.value, y: y.value));
      }

      expect(commands.length, 6);
      
      // MoveTo logical start (End point because it is OnCurve)
      expect(commands[0].isMoveTo, isTrue);
      expect(points[0], (x: 50.0, y: 100.0));
      
      // First curve (using point 0 as control)
      expect(commands[1].isCurve3, isTrue);
      expect(points[1], (x: 0.0, y: 50.0));
      expect(commands[2].isCurve3, isTrue);
      expect(points[2], (x: 50.0, y: 0.0));
      
      // Second curve (using point 2 as control)
      expect(commands[3].isCurve3, isTrue);
      expect(points[3], (x: 100.0, y: 50.0));
      expect(commands[4].isCurve3, isTrue);
      expect(points[4], (x: 50.0, y: 100.0));
      
      expect(commands[5].isEndPoly, isTrue);
    });
  });
}
