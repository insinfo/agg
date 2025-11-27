import 'dart:math' as math;
import '../primitives/point2d.dart';
import 'path_commands.dart';
import 'vertex_data.dart';
import 'vertex_source_legacy_support.dart';

class Ellipse extends VertexSourceLegacySupport {
  double originX = 0.0;
  double originY = 0.0;
  double radiusX = 1.0;
  double radiusY = 1.0;
  double _resolutionScale = 1.0;
  int numSteps = 4;
  bool isCw = false;

  Ellipse([double originX = 0, double originY = 0, double radiusX = 1, double radiusY = 1, int numSteps = 0, bool cw = false]) {
    init(originX, originY, radiusX, radiusY, numSteps, cw);
  }

  Ellipse.fromPoint(Point2D origin, double radiusX, double radiusY, [int numSteps = 0, bool cw = false]) {
    init(origin.x, origin.y, radiusX, radiusY, numSteps, cw);
  }

  Ellipse.fromCircle(Point2D origin, double radius, [int numSteps = 0, bool cw = false]) {
    init(origin.x, origin.y, radius, radius, numSteps, cw);
  }

  double get resolutionScale => _resolutionScale;
  set resolutionScale(double value) {
    _resolutionScale = value;
    _calcNumSteps();
  }

  void init(double originX, double originY, double radiusX, double radiusY, [int numSteps = 0, bool cw = false]) {
    this.originX = originX;
    this.originY = originY;
    this.radiusX = radiusX;
    this.radiusY = radiusY;
    this.numSteps = numSteps;
    this.isCw = cw;
    if (this.numSteps == 0) {
      _calcNumSteps();
    }
  }

  void _calcNumSteps() {
    double ra = (radiusX.abs() + radiusY.abs()) / 2;
    double da = math.acos(ra / (ra + 0.125 / _resolutionScale)) * 2;
    numSteps = (2 * math.pi / da).round();
  }

  @override
  int getLongHashCode([int hash = 0xcbf29ce484222325]) {
    return hash;
  }

  @override
  Iterable<VertexData> vertices() sync* {
    yield VertexData(FlagsAndCommand.commandMoveTo, originX + radiusX, originY);

    double anglePerStep = (2 * math.pi) / numSteps;
    double angle = 0;
    
    for (int i = 1; i < numSteps; i++) {
      angle += anglePerStep;

      if (isCw) {
        yield VertexData(FlagsAndCommand.commandLineTo, 
          originX + math.cos(2 * math.pi - angle) * radiusX,
          originY + math.sin(2 * math.pi - angle) * radiusY
        );
      } else {
        yield VertexData(FlagsAndCommand.commandLineTo, 
          originX + math.cos(angle) * radiusX,
          originY + math.sin(angle) * radiusY
        );
      }
    }

    yield VertexData(FlagsAndCommand.commandEndPoly | FlagsAndCommand.flagClose | FlagsAndCommand.flagCCW, 0, 0);
    yield VertexData(FlagsAndCommand.commandStop, 0, 0);
  }
}
