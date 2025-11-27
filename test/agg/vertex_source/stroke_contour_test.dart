import 'package:test/test.dart';
import 'package:agg/src/agg/vertex_source/stroke.dart';
import 'package:agg/src/agg/vertex_source/contour.dart';
import 'package:agg/src/agg/vertex_source/path_commands.dart';
import 'package:agg/src/agg/vertex_source/stroke_math.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';
import 'package:agg/src/shared/ref_param.dart';

void main() {
  group('Stroke', () {
    test('Stroke generates vertices', () {
      final vs = VertexStorage();
      vs.moveTo(10, 10);
      vs.lineTo(100, 10);
      vs.lineTo(100, 100);
      vs.lineTo(10, 100);
      vs.closePath();

      final stroke = Stroke(vs);
      stroke.width = 2.0;

      stroke.rewind(0);
      
      int count = 0;
      var x = RefParam<double>(0.0);
      var y = RefParam<double>(0.0);
      while (!ShapePath.isStop(stroke.vertex(x, y))) {
        count++;
      }

      // Stroke should generate more vertices than the original 4 (plus close)
      // because of caps and joins.
      expect(count, greaterThan(5));
    });
  });

  group('Contour', () {
    test('Contour generates vertices', () {
      final vs = VertexStorage();
      vs.moveTo(10, 10);
      vs.lineTo(100, 10);
      vs.lineTo(100, 100);
      vs.lineTo(10, 100);
      vs.closePath();

      final contour = Contour(vs);
      contour.width = 2.0;
      contour.lineJoin = LineJoin.round; // Ensure we get more vertices for corners

      contour.rewind(0);
      
      int count = 0;
      var x = RefParam<double>(0.0);
      var y = RefParam<double>(0.0);
      while (!ShapePath.isStop(contour.vertex(x, y))) {
        count++;
      }

      expect(count, greaterThan(5));
    });
  });
}
