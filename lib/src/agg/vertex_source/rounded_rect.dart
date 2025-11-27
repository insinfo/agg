import 'dart:math' as math;
import '../primitives/point2d.dart';
import '../primitives/rectangle_double.dart';
import 'arc.dart';
import 'path_commands.dart';
import 'vertex_data.dart';
import 'vertex_source_legacy_support.dart';

class RoundedRect extends VertexSourceLegacySupport {
  RectangleDouble bounds = RectangleDouble(0, 0, 0, 0);
  Point2D leftBottomRadius = Point2D();
  Point2D rightBottomRadius = Point2D();
  Point2D rightTopRadius = Point2D();
  Point2D leftTopRadius = Point2D();
  double resolutionScale = 1.0;
  int numSegments = 0;

  RoundedRect(double left, double bottom, double right, double top, [double radius = 0]) {
    bounds = RectangleDouble(left, bottom, right, top);
    leftBottomRadius = Point2D(radius, radius);
    rightBottomRadius = Point2D(radius, radius);
    rightTopRadius = Point2D(radius, radius);
    leftTopRadius = Point2D(radius, radius);

    if (left > right) {
      bounds.left = right;
      bounds.right = left;
    }

    if (bottom > top) {
      bounds.bottom = top;
      bounds.top = bottom;
    }
  }

  RoundedRect.fromRect(RectangleDouble bounds, double r) : this(bounds.left, bounds.bottom, bounds.right, bounds.top, r);

  void rect(double left, double bottom, double right, double top) {
    bounds = RectangleDouble(left, bottom, right, top);
    if (left > right) {
      bounds.left = right;
      bounds.right = left;
    }
    if (bottom > top) {
      bounds.bottom = top;
      bounds.top = bottom;
    }
  }

  void radius(double r) {
    leftBottomRadius = Point2D(r, r);
    rightBottomRadius = Point2D(r, r);
    rightTopRadius = Point2D(r, r);
    leftTopRadius = Point2D(r, r);
  }

  void radiusXY(double rx, double ry) {
    leftBottomRadius = Point2D(rx, ry);
    rightBottomRadius = Point2D(rx, ry);
    rightTopRadius = Point2D(rx, ry);
    leftTopRadius = Point2D(rx, ry);
  }

  void radiusIndividual(double lb, double rb, double rt, double lt) {
    leftBottomRadius = Point2D(lb, lb);
    rightBottomRadius = Point2D(rb, rb);
    rightTopRadius = Point2D(rt, rt);
    leftTopRadius = Point2D(lt, lt);
  }

  void radiusIndividualXY(double rx1, double ry1, double rx2, double ry2, double rx3, double ry3, double rx4, double ry4) {
    leftBottomRadius = Point2D(rx1, ry1);
    rightBottomRadius = Point2D(rx2, ry2);
    rightTopRadius = Point2D(rx3, ry3);
    leftTopRadius = Point2D(rx4, ry4);
  }

  void normalizeRadius() {
    double dx = (bounds.top - bounds.bottom).abs();
    double dy = (bounds.right - bounds.left).abs();

    double k = 1.0;
    double t;
    t = dx / (leftBottomRadius.x + rightBottomRadius.x); if (t < k) k = t;
    t = dx / (rightTopRadius.x + leftTopRadius.x); if (t < k) k = t;
    t = dy / (leftBottomRadius.y + rightBottomRadius.y); if (t < k) k = t;
    t = dy / (rightTopRadius.y + leftTopRadius.y); if (t < k) k = t;

    if (k < 1.0) {
      leftBottomRadius.x *= k; leftBottomRadius.y *= k;
      rightBottomRadius.x *= k; rightBottomRadius.y *= k;
      rightTopRadius.x *= k; rightTopRadius.y *= k;
      leftTopRadius.x *= k; leftTopRadius.y *= k;
    }
  }

  @override
  Iterable<VertexData> vertices() sync* {
    // 1. Left Bottom
    if (leftBottomRadius.x == 0 && leftBottomRadius.y == 0) {
      yield VertexData(FlagsAndCommand.commandMoveTo, bounds.left, bounds.bottom);
    } else {
      var arc = Arc(bounds.left + leftBottomRadius.x, bounds.bottom + leftBottomRadius.y, 
          leftBottomRadius.x, leftBottomRadius.y, math.pi, math.pi + math.pi * 0.5, ArcDirection.counterClockWise, numSegments);
      arc.resolutionScale = resolutionScale;
      yield* arc.vertices().takeWhile((v) => !v.command.isStop);
    }

    // 2. Right Bottom
    if (rightBottomRadius.x == 0 && rightBottomRadius.y == 0) {
      yield VertexData(FlagsAndCommand.commandLineTo, bounds.right, bounds.bottom);
    } else {
      var arc = Arc(bounds.right - rightBottomRadius.x, bounds.bottom + rightBottomRadius.y, 
          rightBottomRadius.x, rightBottomRadius.y, math.pi + math.pi * 0.5, 0.0, ArcDirection.counterClockWise, numSegments);
      arc.resolutionScale = resolutionScale;
      bool first = true;
      for (var v in arc.vertices()) {
        if (v.command.isStop) break;
        if (first) {
          yield VertexData(FlagsAndCommand.commandLineTo, v.x, v.y);
          first = false;
        } else {
          yield v;
        }
      }
    }

    // 3. Right Top
    if (rightTopRadius.x == 0 && rightTopRadius.y == 0) {
      yield VertexData(FlagsAndCommand.commandLineTo, bounds.right, bounds.top);
    } else {
      var arc = Arc(bounds.right - rightTopRadius.x, bounds.top - rightTopRadius.y, 
          rightTopRadius.x, rightTopRadius.y, 0.0, math.pi * 0.5, ArcDirection.counterClockWise, numSegments);
      arc.resolutionScale = resolutionScale;
      bool first = true;
      for (var v in arc.vertices()) {
        if (v.command.isStop) break;
        if (first) {
          yield VertexData(FlagsAndCommand.commandLineTo, v.x, v.y);
          first = false;
        } else {
          yield v;
        }
      }
    }

    // 4. Left Top
    if (leftTopRadius.x == 0 && leftTopRadius.y == 0) {
      yield VertexData(FlagsAndCommand.commandLineTo, bounds.left, bounds.top);
    } else {
      var arc = Arc(bounds.left + leftTopRadius.x, bounds.top - leftTopRadius.y, 
          leftTopRadius.x, leftTopRadius.y, math.pi * 0.5, math.pi, ArcDirection.counterClockWise, numSegments);
      arc.resolutionScale = resolutionScale;
      bool first = true;
      for (var v in arc.vertices()) {
        if (v.command.isStop) break;
        if (first) {
          yield VertexData(FlagsAndCommand.commandLineTo, v.x, v.y);
          first = false;
        } else {
          yield v;
        }
      }
    }

    yield VertexData(FlagsAndCommand.commandEndPoly | FlagsAndCommand.flagClose | FlagsAndCommand.flagCCW, 0, 0);
    yield VertexData(FlagsAndCommand.commandStop, 0, 0);
  }

  @override
  int getLongHashCode([int hash = 0xcbf29ce484222325]) {
    hash ^= bounds.left.hashCode;
    hash *= 1099511628211;
    hash ^= bounds.bottom.hashCode;
    hash *= 1099511628211;
    hash ^= bounds.right.hashCode;
    hash *= 1099511628211;
    hash ^= bounds.top.hashCode;
    hash *= 1099511628211;
    hash ^= leftBottomRadius.x.hashCode;
    hash *= 1099511628211;
    hash ^= leftBottomRadius.y.hashCode;
    hash *= 1099511628211;
    hash ^= rightBottomRadius.x.hashCode;
    hash *= 1099511628211;
    hash ^= rightBottomRadius.y.hashCode;
    hash *= 1099511628211;
    hash ^= rightTopRadius.x.hashCode;
    hash *= 1099511628211;
    hash ^= rightTopRadius.y.hashCode;
    hash *= 1099511628211;
    hash ^= leftTopRadius.x.hashCode;
    hash *= 1099511628211;
    hash ^= leftTopRadius.y.hashCode;
    hash *= 1099511628211;
    return hash;
  }

  double get left => bounds.left;
  double get bottom => bounds.bottom;
  double get right => bounds.right;
  double get top => bounds.top;
}
