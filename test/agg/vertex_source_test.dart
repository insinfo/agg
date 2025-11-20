import 'package:test/test.dart';
import 'package:agg/src/agg/vertex_source/vertex_source.dart';

void main() {
  group('VertexStorage', () {
    test('should create empty storage', () {
      final storage = VertexStorage();
      expect(storage.isEmpty, isTrue);
      expect(storage.count, equals(0));
    });

    test('should add vertices', () {
      final storage = VertexStorage();
      storage.moveTo(10, 20);
      storage.lineTo(30, 40);
      storage.lineTo(50, 60);

      expect(storage.count, equals(3));
      expect(storage.isEmpty, isFalse);
    });

    test('should iterate vertices', () {
      final storage = VertexStorage();
      storage.moveTo(10, 20);
      storage.lineTo(30, 40);
      storage.closePath();

      final vertices = storage.vertices().toList();
      expect(vertices.length, equals(3));
      expect(vertices[0].isMoveTo, isTrue);
      expect(vertices[1].isLineTo, isTrue);
      expect(vertices[2].isEndPoly, isTrue);
      expect(vertices[2].isClose, isTrue);
    });

    test('should clear storage', () {
      final storage = VertexStorage();
      storage.moveTo(10, 20);
      storage.lineTo(30, 40);
      storage.clear();

      expect(storage.isEmpty, isTrue);
      expect(storage.count, equals(0));
    });
  });

  group('Arc', () {
    test('should create arc', () {
      final arc = Arc(100, 100, 50, 50, 0, 3.14159);
      expect(arc.originX, equals(100));
      expect(arc.originY, equals(100));
      expect(arc.radiusX, equals(50));
      expect(arc.radiusY, equals(50));
    });

    test('should generate vertices', () {
      final arc = Arc(0, 0, 10, 10, 0, 1.5708); // 90 degrees
      final vertices = arc.vertices().toList();

      expect(vertices.isNotEmpty, isTrue);
      expect(vertices.first.isMoveTo, isTrue);
      expect(vertices.skip(1).every((v) => v.isLineTo), isTrue);
    });
  });

  group('Ellipse', () {
    test('should create ellipse', () {
      final ellipse = Ellipse(100, 100, 50, 30);
      expect(ellipse.originX, equals(100));
      expect(ellipse.originY, equals(100));
      expect(ellipse.radiusX, equals(50));
      expect(ellipse.radiusY, equals(30));
    });

    test('should create circle', () {
      final circle = Ellipse.circle(100, 100, 50);
      expect(circle.radiusX, equals(50));
      expect(circle.radiusY, equals(50));
    });

    test('should generate closed path', () {
      final ellipse = Ellipse(0, 0, 10, 10);
      final vertices = ellipse.vertices().toList();

      expect(vertices.isNotEmpty, isTrue);
      expect(vertices.first.isMoveTo, isTrue);
      expect(vertices.last.isEndPoly, isTrue);
      expect(vertices.last.isClose, isTrue);
    });
  });

  group('RoundedRect', () {
    test('should create rounded rectangle', () {
      final rect = RoundedRect(0, 0, 100, 100, 10);
      expect(rect.left, equals(0));
      expect(rect.bottom, equals(0));
      expect(rect.right, equals(100));
      expect(rect.top, equals(100));
    });

    test('should generate vertices with rounded corners', () {
      final rect = RoundedRect(0, 0, 100, 100, 10);
      final vertices = rect.vertices().toList();

      expect(vertices.isNotEmpty, isTrue);
      expect(vertices.first.isMoveTo, isTrue);
      expect(vertices.any((v) => v.isEndPoly && v.isClose), isTrue);
    });

    test('should normalize radius', () {
      // Radius larger than half the rectangle should be normalized
      final rect = RoundedRect(0, 0, 100, 100, 60);
      final vertices = rect.vertices().toList();

      // Should still generate valid vertices
      expect(vertices.isNotEmpty, isTrue);
    });
  });

  group('PathCommands', () {
    test('should identify command types', () {
      expect(FlagsAndCommand.commandMoveTo.isMoveTo, isTrue);
      expect(FlagsAndCommand.commandLineTo.isLineTo, isTrue);
      expect(FlagsAndCommand.commandCurve3.isCurve3, isTrue);
      expect(FlagsAndCommand.commandCurve4.isCurve4, isTrue);
      expect(FlagsAndCommand.commandStop.isStop, isTrue);
    });

    test('should combine flags', () {
      final cmd = FlagsAndCommand.commandEndPoly | FlagsAndCommand.flagClose;
      expect(cmd.isEndPoly, isTrue);
      expect(cmd.isClose, isTrue);
    });
  });

  group('VertexData', () {
    test('should create vertex data', () {
      final vertex = VertexData(FlagsAndCommand.commandMoveTo, 10, 20);
      expect(vertex.x, equals(10));
      expect(vertex.y, equals(20));
      expect(vertex.isMoveTo, isTrue);
    });

    test('should have position getter', () {
      final vertex = VertexData(FlagsAndCommand.commandLineTo, 30, 40);
      final pos = vertex.position;
      expect(pos.x, equals(30));
      expect(pos.y, equals(40));
    });
  });
}
