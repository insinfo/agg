import 'package:agg/src/shared/ref_param.dart';
import 'ivertex_source.dart';
import 'path_commands.dart';
import 'vertex_data.dart';

/// A container for storing vertex data
class VertexStorage implements IVertexSource {
  List<VertexData> _vertices = [];
  int _iteratorIndex = 0;

  VertexStorage();

  /// Get the number of vertices
  int get count => _vertices.length;

  /// Check if storage is empty
  bool get isEmpty => _vertices.isEmpty;

  /// Clear all vertices
  void clear() {
    _vertices.clear();
    _iteratorIndex = 0;
  }

  /// Add a vertex
  void addVertex(double x, double y, FlagsAndCommand command) {
    _vertices.add(VertexData(command, x, y));
  }

  /// Move to a point
  void moveTo(double x, double y) {
    addVertex(x, y, FlagsAndCommand.commandMoveTo);
  }

  /// Line to a point
  void lineTo(double x, double y) {
    addVertex(x, y, FlagsAndCommand.commandLineTo);
  }

  /// Curve3 (quadratic bezier) control point
  void curve3(double ctrlX, double ctrlY, double toX, double toY) {
    addVertex(ctrlX, ctrlY, FlagsAndCommand.commandCurve3);
    addVertex(toX, toY, FlagsAndCommand.commandCurve3);
  }

  /// Curve4 (cubic bezier) control points
  void curve4(double ctrl1X, double ctrl1Y, double ctrl2X, double ctrl2Y,
      double toX, double toY) {
    addVertex(ctrl1X, ctrl1Y, FlagsAndCommand.commandCurve4);
    addVertex(ctrl2X, ctrl2Y, FlagsAndCommand.commandCurve4);
    addVertex(toX, toY, FlagsAndCommand.commandCurve4);
  }

  /// Close the current polygon
  void closePath() {
    if (_vertices.isNotEmpty) {
      _vertices.add(VertexData(
        FlagsAndCommand.commandEndPoly | FlagsAndCommand.flagClose,
        0,
        0,
      ));
    }
  }

  /// End the current polygon without closing
  void endPoly([FlagsAndCommand flags = FlagsAndCommand.flagNone]) {
    if (_vertices.isNotEmpty) {
      _vertices.add(VertexData(
        FlagsAndCommand.commandEndPoly | flags,
        0,
        0,
      ));
    }
  }

  /// Get vertex at index
  VertexData operator [](int index) => _vertices[index];

  /// Set vertex at index
  void operator []=(int index, VertexData value) {
    _vertices[index] = value;
  }

  /// Modify the command of the last vertex
  void modifyCommand(FlagsAndCommand command) {
    if (_vertices.isNotEmpty) {
      _vertices[_vertices.length - 1].command = command;
    }
  }

  /// Get the last vertex
  VertexData? get lastVertex => _vertices.isEmpty ? null : _vertices.last;

  /// Get the last x coordinate
  double get lastX => _vertices.isEmpty ? 0 : _vertices.last.x;

  /// Get the last y coordinate
  double get lastY => _vertices.isEmpty ? 0 : _vertices.last.y;

  @override
  void rewind([int pathId = 0]) {
    _iteratorIndex = 0;
  }

  @override
  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    if (_iteratorIndex >= _vertices.length) {
      x.value = 0;
      y.value = 0;
      return FlagsAndCommand.commandStop;
    }

    var v = _vertices[_iteratorIndex++];
    x.value = v.x;
    y.value = v.y;
    return v.command;
  }

  int getLongHashCode([int hash = 0xcbf29ce484222325]) {
    for (var v in _vertices) {
      hash = v.getLongHashCode(hash);
    }
    return hash;
  }

  @override
  Iterable<VertexData> vertices() sync* {
    for (var v in _vertices) {
      yield v;
    }
  }

  /// Remove all vertices after the specified index
  void removeAfter(int index) {
    if (index < _vertices.length) {
      _vertices.removeRange(index, _vertices.length);
    }
  }

  /// Concatenate another path
  void concat(IVertexSource other) {
    var x = RefParam<double>(0.0);
    var y = RefParam<double>(0.0);
    other.rewind();

    while (true) {
      var cmd = other.vertex(x, y);
      if (cmd.isStop) break;
      addVertex(x.value, y.value, cmd);
    }
  }

  @override
  String toString() => 'VertexStorage(${_vertices.length} vertices)';
}
