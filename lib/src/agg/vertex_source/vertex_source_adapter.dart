import 'i_vertex_source.dart';
import 'path_commands.dart';
import 'vertex_data.dart';

/// Adapts a vertex source with optional transformation and filtering.
///
/// This class provides a flexible way to wrap and modify vertex sources
/// without changing the original source.
class VertexSourceAdapter implements IVertexSource {
  IVertexSource _source;
  bool _removeMoveTo = false;
  bool _removeLineTo = false;
  bool _removeCurves = false;

  VertexSourceAdapter(this._source);

  /// Gets the wrapped source.
  IVertexSource get source => _source;

  /// Sets a new source to wrap.
  set source(IVertexSource value) {
    _source = value;
  }

  /// If true, filters out moveTo commands.
  bool get removeMoveTo => _removeMoveTo;
  set removeMoveTo(bool value) {
    _removeMoveTo = value;
  }

  /// If true, filters out lineTo commands.
  bool get removeLineTo => _removeLineTo;
  set removeLineTo(bool value) {
    _removeLineTo = value;
  }

  /// If true, filters out curve commands.
  bool get removeCurves => _removeCurves;
  set removeCurves(bool value) {
    _removeCurves = value;
  }

  @override
  void rewind([int pathId = 0]) {
    _source.rewind(pathId);
  }

  @override
  FlagsAndCommand vertex(VertexOutput output) {
    while (true) {
      final cmd = _source.vertex(output);

      if (cmd.isStop) {
        return cmd;
      }

      final cmdBase = cmd & FlagsAndCommand.commandMask;

      // Filter based on settings
      if (_removeMoveTo && cmdBase == FlagsAndCommand.commandMoveTo) {
        continue;
      }

      if (_removeLineTo && cmdBase == FlagsAndCommand.commandLineTo) {
        continue;
      }

      if (_removeCurves &&
          (cmdBase == FlagsAndCommand.commandCurve3 ||
              cmdBase == FlagsAndCommand.commandCurve4)) {
        continue;
      }

      return cmd;
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
    hash = _source.getLongHashCode(hash);
    hash ^= 0x41444150; // ASCII "ADAP"
    hash *= 1099511628211;
    return hash;
  }
}
