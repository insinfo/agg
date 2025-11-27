import '../../shared/ref_param.dart';
import '../interfaces/imarkers.dart';
import 'igenerator.dart';
import 'ivertex_source.dart';
import 'path_commands.dart';
import 'vertex_data.dart';

class NullMarkers implements IMarkers {
  @override
  void clear() {}

  @override
  void addVertex(double x, double y, FlagsAndCommand cmd) {}
}

enum _Status {
  initial,
  accumulate,
  generate,
}

class VertexSourceAdapter implements IVertexSource {
  IGenerator _generator;
  IMarkers _markers;
  _Status _status = _Status.initial;
  FlagsAndCommand _lastCmd = FlagsAndCommand.commandStop;
  double _startX = 0.0;
  double _startY = 0.0;

  IVertexSource vertexSource;

  VertexSourceAdapter(this.vertexSource, this._generator, [IMarkers? markers])
      : _markers = markers ?? NullMarkers();

  IGenerator get generator => _generator;
  IMarkers get markers => _markers;

  void attach(IVertexSource source) {
    vertexSource = source;
  }

  @override
  void rewind([int pathId = 0]) {
    vertexSource.rewind(pathId);
    _status = _Status.initial;
  }

  @override
  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    x.value = 0;
    y.value = 0;
    FlagsAndCommand command = FlagsAndCommand.commandStop;
    bool done = false;

    while (!done) {
      switch (_status) {
        case _Status.initial:
          _markers.clear();
          var px = RefParam(0.0);
          var py = RefParam(0.0);
          _lastCmd = vertexSource.vertex(px, py);
          _startX = px.value;
          _startY = py.value;
          _status = _Status.accumulate;
          continue;

        case _Status.accumulate:
          if (ShapePath.isStop(_lastCmd)) {
            return FlagsAndCommand.commandStop;
          }

          _generator.removeAll();
          _generator.addVertex(_startX, _startY, FlagsAndCommand.commandMoveTo);
          _markers.addVertex(_startX, _startY, FlagsAndCommand.commandMoveTo);

          for (;;) {
            var px = RefParam(0.0);
            var py = RefParam(0.0);
            command = vertexSource.vertex(px, py);
            
            if (ShapePath.isVertex(command)) {
              _lastCmd = command;
              if (ShapePath.isMoveTo(command)) {
                _startX = px.value;
                _startY = py.value;
                break;
              }
              _generator.addVertex(px.value, py.value, command);
              _markers.addVertex(px.value, py.value, FlagsAndCommand.commandLineTo);
            } else {
              if (ShapePath.isStop(command)) {
                _lastCmd = FlagsAndCommand.commandStop;
                break;
              }
              if (ShapePath.isEndPoly(command)) {
                _generator.addVertex(px.value, py.value, command);
                break;
              }
            }
          }
          _generator.rewind(0);
          _status = _Status.generate;
          continue;

        case _Status.generate:
          command = _generator.vertex(x, y);
          if (ShapePath.isStop(command)) {
            _status = _Status.accumulate;
            break;
          }
          done = true;
          break;
      }
    }
    return command;
  }

  @override
  Iterable<VertexData> vertices() sync* {
    rewind(0);
    var x = RefParam(0.0);
    var y = RefParam(0.0);
    FlagsAndCommand cmd;
    do {
      cmd = vertex(x, y);
      if (!ShapePath.isStop(cmd)) {
        yield VertexData(cmd, x.value, y.value);
      }
    } while (!ShapePath.isStop(cmd));
  }

  @override
  int getLongHashCode([int hash = 0xcbf29ce484222325]) {
    // TODO: Implement getLongHashCode properly if needed
    return vertexSource.getLongHashCode(hash);
  }
}
