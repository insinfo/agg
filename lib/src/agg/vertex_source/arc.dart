import 'dart:math' as math;
import '../primitives/point2d.dart';
import 'path_commands.dart';
import 'vertex_data.dart';
import 'vertex_source_legacy_support.dart';

enum ArcDirection {
  clockWise,
  counterClockWise,
}

class Arc extends VertexSourceLegacySupport {
  ArcDirection _direction = ArcDirection.counterClockWise;
  double _endAngle = 0.0;
  Point2D _origin = Point2D();
  Point2D _radius = Point2D();
  double resolutionScale = 1.0;
  double _startAngle = 0.0;
  int numSegments = 0;

  Arc([double originX = 0, double originY = 0, double radiusX = 0, double radiusY = 0, double startAngle = 0, double endAngle = 0, ArcDirection direction = ArcDirection.counterClockWise, int numSegments = 0]) {
    if (originX != 0 || originY != 0 || radiusX != 0 || radiusY != 0 || startAngle != 0 || endAngle != 0) {
      init(originX, originY, radiusX, radiusY, startAngle, endAngle, direction, numSegments);
    }
  }

  Arc.fromPoint(Point2D origin, Point2D radius, double startAngle, double endAngle, [ArcDirection direction = ArcDirection.counterClockWise, int numSegments = 0]) {
    initFromPoint(origin, radius, startAngle, endAngle, direction, numSegments);
  }

  Arc.fromCircle(Point2D origin, double radius, double startAngle, double endAngle, [ArcDirection direction = ArcDirection.counterClockWise]) {
    initFromPoint(origin, Point2D(radius, radius), startAngle, endAngle, direction);
  }

  void init(double originX, double originY, double radiusX, double radiusY, double startAngle, double endAngle, [ArcDirection direction = ArcDirection.counterClockWise, int numSegments = 0]) {
    initFromPoint(Point2D(originX, originY), Point2D(radiusX, radiusY), startAngle, endAngle, direction, numSegments);
  }

  void initFromPoint(Point2D origin, Point2D radius, double startAngle, double endAngle, [ArcDirection direction = ArcDirection.counterClockWise, int numSegments = 0]) {
    this.numSegments = numSegments;
    _origin = origin;
    _radius = radius;
    _startAngle = startAngle;
    _endAngle = endAngle;
    _direction = direction;
  }

  @override
  int getLongHashCode([int hash = 0xcbf29ce484222325]) {
    return hash;
  }

  @override
  Iterable<VertexData> vertices() {
    if (numSegments == 0) {
      return _deltaVertices();
    } else {
      return _stepVertices();
    }
  }

  Iterable<VertexData> _deltaVertices() sync* {
    double averageRadius = (_radius.x.abs() + _radius.y.abs()) / 2;
    var flattenedDeltaAngle = math.acos(averageRadius / (averageRadius + 0.125 / resolutionScale)) * 2;
    
    double currentEndAngle = _endAngle;
    while (currentEndAngle < _startAngle) {
      currentEndAngle += math.pi * 2.0;
    }

    if (_direction == ArcDirection.counterClockWise) {
      yield VertexData(FlagsAndCommand.commandMoveTo, _origin.x + math.cos(_startAngle) * _radius.x, _origin.y + math.sin(_startAngle) * _radius.y);

      double angle = _startAngle;
      int numSteps = ((currentEndAngle - _startAngle) / flattenedDeltaAngle).toInt();

      for (int i = 0; i <= numSteps; i++) {
        if (angle < currentEndAngle) {
          yield VertexData(FlagsAndCommand.commandLineTo, _origin.x + math.cos(angle) * _radius.x, _origin.y + math.sin(angle) * _radius.y);
          angle += flattenedDeltaAngle;
        }
      }

      yield VertexData(FlagsAndCommand.commandLineTo, _origin.x + math.cos(currentEndAngle) * _radius.x, _origin.y + math.sin(currentEndAngle) * _radius.y);
    } else {
      yield VertexData(FlagsAndCommand.commandMoveTo, _origin.x + math.cos(currentEndAngle) * _radius.x, _origin.y + math.sin(currentEndAngle) * _radius.y);

      double angle = currentEndAngle;
      int numSteps = ((currentEndAngle - _startAngle) / flattenedDeltaAngle).toInt();
      for (int i = 0; i <= numSteps; i++) {
        yield VertexData(FlagsAndCommand.commandLineTo, _origin.x + math.cos(angle) * _radius.x, _origin.y + math.sin(angle) * _radius.y);
        angle -= flattenedDeltaAngle;
      }

      yield VertexData(FlagsAndCommand.commandLineTo, _origin.x + math.cos(_startAngle) * _radius.x, _origin.y + math.sin(_startAngle) * _radius.y);
    }

    yield VertexData(FlagsAndCommand.commandStop, 0, 0);
  }

  Iterable<VertexData> _stepVertices() sync* {
    double currentEndAngle = _endAngle;
    while (currentEndAngle < _startAngle) {
      currentEndAngle += math.pi * 2.0;
    }

    var flattenedDeltaAngle = (currentEndAngle - _startAngle) / numSegments;

    if (_direction == ArcDirection.counterClockWise) {
      yield VertexData(FlagsAndCommand.commandMoveTo, _origin.x + math.cos(_startAngle) * _radius.x, _origin.y + math.sin(_startAngle) * _radius.y);

      double angle = _startAngle;

      for (int i = 0; i <= numSegments; i++) {
        if (angle < currentEndAngle) {
          yield VertexData(FlagsAndCommand.commandLineTo, _origin.x + math.cos(angle) * _radius.x, _origin.y + math.sin(angle) * _radius.y);
          angle += flattenedDeltaAngle;
        }
      }

      yield VertexData(FlagsAndCommand.commandLineTo, _origin.x + math.cos(currentEndAngle) * _radius.x, _origin.y + math.sin(currentEndAngle) * _radius.y);
    } else {
      yield VertexData(FlagsAndCommand.commandMoveTo, _origin.x + math.cos(currentEndAngle) * _radius.x, _origin.y + math.sin(currentEndAngle) * _radius.y);

      double angle = currentEndAngle;
      int numSteps = ((currentEndAngle - _startAngle) / flattenedDeltaAngle).toInt();
      for (int i = 0; i <= numSteps; i++) {
        yield VertexData(FlagsAndCommand.commandLineTo, _origin.x + math.cos(angle) * _radius.x, _origin.y + math.sin(angle) * _radius.y);
        angle -= flattenedDeltaAngle;
      }

      yield VertexData(FlagsAndCommand.commandLineTo, _origin.x + math.cos(_startAngle) * _radius.x, _origin.y + math.sin(_startAngle) * _radius.y);
    }

    yield VertexData(FlagsAndCommand.commandStop, 0, 0);
  }

  double get originX => _origin.x;
  double get originY => _origin.y;
  double get radiusX => _radius.x;
  double get radiusY => _radius.y;
}
