import 'dart:math' as math;
import 'i_vertex_source.dart';
import 'path_commands.dart';
import 'vertex_data.dart';

/// Ellipse vertex source
class Ellipse implements IVertexSource {
  double originX;
  double originY;
  double radiusX;
  double radiusY;
  int numSteps;
  bool isCw;

  int _currentStep = 0;

  Ellipse(
    this.originX,
    this.originY,
    this.radiusX,
    this.radiusY, {
    int numSteps = 0,
    this.isCw = false,
  }) : numSteps =
            numSteps == 0 ? _calculateNumSteps(radiusX, radiusY) : numSteps;

  void init(double x, double y, double rx, double ry,
      {int steps = 0, bool cw = false}) {
    originX = x;
    originY = y;
    radiusX = rx;
    radiusY = ry;
    isCw = cw;
    numSteps = steps == 0 ? _calculateNumSteps(rx, ry) : steps;
  }

  static int _calculateNumSteps(double rx, double ry) {
    double ra = (rx.abs() + ry.abs()) / 2.0;
    double da = math.acos(ra / (ra + 0.125)) * 2.0;
    int steps = (2.0 * math.pi / da).round();
    return steps < 4 ? 4 : steps;
  }

  @override
  void rewind([int pathId = 0]) {
    _currentStep = 0;
  }

  @override
  FlagsAndCommand vertex(VertexOutput output) {
    if (_currentStep > numSteps) {
      output.set(0, 0);
      return FlagsAndCommand.commandStop;
    }

    double angle;
    if (isCw) {
      angle = 2.0 * math.pi - (2.0 * math.pi * _currentStep / numSteps);
    } else {
      angle = 2.0 * math.pi * _currentStep / numSteps;
    }

    output.set(
      originX + math.cos(angle) * radiusX,
      originY + math.sin(angle) * radiusY,
    );

    _currentStep++;

    if (_currentStep == 1) {
      return FlagsAndCommand.commandMoveTo;
    } else if (_currentStep == numSteps + 1) {
      return FlagsAndCommand.commandEndPoly | FlagsAndCommand.flagClose;
    } else {
      return FlagsAndCommand.commandLineTo;
    }
  }

  @override
  Iterable<VertexData> vertices() sync* {
    rewind();
    var output = VertexOutput();

    while (true) {
      var cmd = vertex(output);
      if (cmd.isStop) break;
      yield VertexData(cmd, output.x, output.y);
    }
  }

  @override
  int getLongHashCode([int hash = 0xcbf29ce484222325]) {
    hash ^= originX.hashCode;
    hash *= 1099511628211;
    hash ^= originY.hashCode;
    hash *= 1099511628211;
    hash ^= radiusX.hashCode;
    hash *= 1099511628211;
    hash ^= radiusY.hashCode;
    hash *= 1099511628211;
    hash ^= numSteps.hashCode;
    hash *= 1099511628211;
    return hash;
  }

  /// Create a circle
  factory Ellipse.circle(double x, double y, double radius,
      {int numSteps = 0, bool cw = false}) {
    return Ellipse(x, y, radius, radius, numSteps: numSteps, isCw: cw);
  }
}
