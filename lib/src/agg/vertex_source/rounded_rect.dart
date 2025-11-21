import 'dart:math' as math;
import 'i_vertex_source.dart';
import 'path_commands.dart';
import 'vertex_data.dart';
import 'arc.dart';

/// Rounded rectangle vertex source
class RoundedRect implements IVertexSource {
  double left;
  double bottom;
  double right;
  double top;

  double leftBottomRadiusX;
  double leftBottomRadiusY;
  double rightBottomRadiusX;
  double rightBottomRadiusY;
  double rightTopRadiusX;
  double rightTopRadiusY;
  double leftTopRadiusX;
  double leftTopRadiusY;

  int _currentStep = 0;
  Arc? _currentArc;

  RoundedRect(this.left, this.bottom, this.right, this.top, double radius)
      : leftBottomRadiusX = radius,
        leftBottomRadiusY = radius,
        rightBottomRadiusX = radius,
        rightBottomRadiusY = radius,
        rightTopRadiusX = radius,
        rightTopRadiusY = radius,
        leftTopRadiusX = radius,
        leftTopRadiusY = radius {
    _normalizeRadius();
  }

  RoundedRect.withRadii(
    this.left,
    this.bottom,
    this.right,
    this.top, {
    double radiusX = 0,
    double radiusY = 0,
  })  : leftBottomRadiusX = radiusX,
        leftBottomRadiusY = radiusY,
        rightBottomRadiusX = radiusX,
        rightBottomRadiusY = radiusY,
        rightTopRadiusX = radiusX,
        rightTopRadiusY = radiusY,
        leftTopRadiusX = radiusX,
        leftTopRadiusY = radiusY {
    _normalizeRadius();
  }

  RoundedRect.withCorners(
    this.left,
    this.bottom,
    this.right,
    this.top, {
    double leftBottom = 0,
    double rightBottom = 0,
    double rightTop = 0,
    double leftTop = 0,
  })  : leftBottomRadiusX = leftBottom,
        leftBottomRadiusY = leftBottom,
        rightBottomRadiusX = rightBottom,
        rightBottomRadiusY = rightBottom,
        rightTopRadiusX = rightTop,
        rightTopRadiusY = rightTop,
        leftTopRadiusX = leftTop,
        leftTopRadiusY = leftTop {
    _normalizeRadius();
  }

  void setRect(double l, double b, double r, double t) {
    left = l;
    bottom = b;
    right = r;
    top = t;
    if (left > right) {
      double temp = left;
      left = right;
      right = temp;
    }
    if (bottom > top) {
      double temp = bottom;
      bottom = top;
      top = temp;
    }
  }

  void setRadius(double r) {
    leftBottomRadiusX = leftBottomRadiusY = r;
    rightBottomRadiusX = rightBottomRadiusY = r;
    rightTopRadiusX = rightTopRadiusY = r;
    leftTopRadiusX = leftTopRadiusY = r;
    _normalizeRadius();
  }

  void _normalizeRadius() {
    double dx = (right - left).abs();
    double dy = (top - bottom).abs();

    double k = 1.0;
    double t;
    t = dx / (leftBottomRadiusX + rightBottomRadiusX);
    if (t < k) k = t;
    t = dx / (rightTopRadiusX + leftTopRadiusX);
    if (t < k) k = t;
    t = dy / (leftBottomRadiusY + leftTopRadiusY);
    if (t < k) k = t;
    t = dy / (rightBottomRadiusY + rightTopRadiusY);
    if (t < k) k = t;

    if (k < 1.0) {
      leftBottomRadiusX *= k;
      leftBottomRadiusY *= k;
      rightBottomRadiusX *= k;
      rightBottomRadiusY *= k;
      rightTopRadiusX *= k;
      rightTopRadiusY *= k;
      leftTopRadiusX *= k;
      leftTopRadiusY *= k;
    }
  }

  @override
  void rewind([int pathId = 0]) {
    _currentStep = 0;
    _currentArc = null;
  }

  @override
  FlagsAndCommand vertex(VertexOutput output) {
    FlagsAndCommand cmd = FlagsAndCommand.commandStop;
    while (true) {
      switch (_currentStep) {
        case 0:
          _currentArc = Arc(
            right - rightBottomRadiusX,
            bottom + rightBottomRadiusY,
            rightBottomRadiusX,
            rightBottomRadiusY,
            math.pi * 1.5,
            math.pi * 2.0,
            direction: Direction.clockwise,
          );
          _currentArc!.rewind();
          _currentStep++;
          return FlagsAndCommand.commandMoveTo;

        case 1:
          cmd = _currentArc!.vertex(output);
          if (cmd.isStop) {
            _currentStep++;
            continue;
          }
          return cmd;

        case 2:
          output.set(right, top - rightTopRadiusY);
          _currentStep++;
          return FlagsAndCommand.commandLineTo;

        case 3:
          _currentArc = Arc(
            right - rightTopRadiusX,
            top - rightTopRadiusY,
            rightTopRadiusX,
            rightTopRadiusY,
            0.0,
            math.pi * 0.5,
            direction: Direction.clockwise,
          );
          _currentArc!.rewind();
          _currentStep++;
          cmd = _currentArc!.vertex(output);
          if (cmd.isStop) {
            continue;
          }
          return cmd;

        case 4:
          cmd = _currentArc!.vertex(output);
          if (cmd.isStop) {
            _currentStep++;
            continue;
          }
          return cmd;

        case 5:
          output.set(left + leftTopRadiusX, top);
          _currentStep++;
          return FlagsAndCommand.commandLineTo;

        case 6:
          _currentArc = Arc(
            left + leftTopRadiusX,
            top - leftTopRadiusY,
            leftTopRadiusX,
            leftTopRadiusY,
            math.pi * 0.5,
            math.pi,
            direction: Direction.clockwise,
          );
          _currentArc!.rewind();
          _currentStep++;
          cmd = _currentArc!.vertex(output);
          if (cmd.isStop) {
            continue;
          }
          return cmd;

        case 7:
          cmd = _currentArc!.vertex(output);
          if (cmd.isStop) {
            _currentStep++;
            continue;
          }
          return cmd;

        case 8:
          output.set(left, bottom + leftBottomRadiusY);
          _currentStep++;
          return FlagsAndCommand.commandLineTo;

        case 9:
          _currentArc = Arc(
            left + leftBottomRadiusX,
            bottom + leftBottomRadiusY,
            leftBottomRadiusX,
            leftBottomRadiusY,
            math.pi,
            math.pi * 1.5,
            direction: Direction.clockwise,
          );
          _currentArc!.rewind();
          _currentStep++;
          cmd = _currentArc!.vertex(output);
          if (cmd.isStop) {
            continue;
          }
          return cmd;

        case 10:
          cmd = _currentArc!.vertex(output);
          if (cmd.isStop) {
            _currentStep++;
            continue;
          }
          return cmd;

        case 11:
          output.set(0, 0);
          _currentStep++;
          return FlagsAndCommand.commandEndPoly | FlagsAndCommand.flagClose;

        default:
          output.set(0, 0);
          return FlagsAndCommand.commandStop;
      }
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
    hash ^= left.hashCode;
    hash *= 1099511628211;
    hash ^= bottom.hashCode;
    hash *= 1099511628211;
    hash ^= right.hashCode;
    hash *= 1099511628211;
    hash ^= top.hashCode;
    hash *= 1099511628211;
    return hash;
  }
}
