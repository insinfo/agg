import 'dart:math' as math;
import 'i_vertex_source.dart';
import 'path_commands.dart';
import 'vertex_data.dart';

/// Direction for arc drawing
enum Direction {
  clockwise,
  counterClockwise,
}

/// Arc vertex source
class Arc implements IVertexSource {
  double originX;
  double originY;
  double radiusX;
  double radiusY;
  double startAngle;
  double endAngle;
  Direction direction;
  double scale;

  int _currentStep = 0;
  int _numSteps = 0;

  Arc(
    this.originX,
    this.originY,
    this.radiusX,
    this.radiusY,
    this.startAngle,
    this.endAngle, {
    this.direction = Direction.counterClockwise,
    this.scale = 1.0,
  }) {
    _calculateNumSteps();
  }

  void init(double x, double y, double rx, double ry, double start, double end,
      {Direction dir = Direction.counterClockwise}) {
    originX = x;
    originY = y;
    radiusX = rx;
    radiusY = ry;
    startAngle = start;
    endAngle = end;
    direction = dir;
    _calculateNumSteps();
  }

  void _calculateNumSteps() {
    double da = (endAngle - startAngle).abs();
    if (da >= math.pi * 2.0 - 0.01) {
      da = math.pi * 2.0;
    }

    // Calculate number of steps based on arc length and scale
    double radius = math.max(radiusX, radiusY);
    _numSteps = (da / (2.0 * math.acos(1.0 - 0.125 / (radius * scale)))).ceil();
    if (_numSteps < 4) _numSteps = 4;
  }

  @override
  void rewind([int pathId = 0]) {
    _currentStep = 0;
  }

  @override
  FlagsAndCommand vertex(VertexOutput output) {
    if (_currentStep == 0) {
      double angle = startAngle;
      output.set(
        originX + math.cos(angle) * radiusX,
        originY + math.sin(angle) * radiusY,
      );
      _currentStep++;
      return FlagsAndCommand.commandMoveTo;
    }

    if (_currentStep > _numSteps) {
      output.set(0, 0);
      return FlagsAndCommand.commandStop;
    }

    double angle;
    if (direction == Direction.counterClockwise) {
      angle = startAngle + (endAngle - startAngle) * _currentStep / _numSteps;
    } else {
      angle = startAngle - (startAngle - endAngle) * _currentStep / _numSteps;
    }

    output.set(
      originX + math.cos(angle) * radiusX,
      originY + math.sin(angle) * radiusY,
    );
    _currentStep++;
    return FlagsAndCommand.commandLineTo;
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
    hash ^= startAngle.hashCode;
    hash *= 1099511628211;
    hash ^= endAngle.hashCode;
    hash *= 1099511628211;
    return hash;
  }
}
