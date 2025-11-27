import 'package:agg/src/shared/ref_param.dart';
import 'ivertex_source.dart';
import 'path_commands.dart';
import 'vertex_data.dart';

/// Connects multiple vertex sources with automatic path closing.
///
/// Similar to JoinPaths but ensures paths are properly connected
/// by adding line segments between them if needed.
class ConnectedPaths implements IVertexSource {
  final List<IVertexSource> _sources = [];
  int _currentSource = 0;
  double _lastX = 0.0;
  double _lastY = 0.0;
  bool _hasLastPoint = false;

  ConnectedPaths([List<IVertexSource>? sources]) {
    if (sources != null) {
      _sources.addAll(sources);
    }
  }

  /// Adds a vertex source to the collection.
  void add(IVertexSource source) {
    _sources.add(source);
  }

  /// Removes all vertex sources from the collection.
  void clear() {
    _sources.clear();
  }

  /// Gets the number of vertex sources in the collection.
  int get count => _sources.length;

  @override
  void rewind([int pathId = 0]) {
    _currentSource = 0;
    _hasLastPoint = false;
    for (final source in _sources) {
      source.rewind(pathId);
    }
  }

  @override
  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    if (_currentSource >= _sources.length) {
      x.value = 0;
      y.value = 0;
      return FlagsAndCommand.commandStop;
    }

    FlagsAndCommand cmd = _sources[_currentSource].vertex(x, y);

    while (cmd == FlagsAndCommand.commandStop &&
        _currentSource < _sources.length - 1) {
      _currentSource++;

      // Get the first vertex of the next source
      final nextCmd = _sources[_currentSource].vertex(x, y);

      // If we have a last point and the next path starts with moveTo,
      // connect them with a line
      if (_hasLastPoint && nextCmd.isMoveTo) {
        final nextX = x.value;
        final nextY = y.value;

        // Return a lineTo to connect the paths
        x.value = _lastX;
        y.value = _lastY;
        _lastX = nextX;
        _lastY = nextY;
        return FlagsAndCommand.commandLineTo;
      }

      cmd = nextCmd;
    }

    // Track the last point for connecting paths
    if (cmd.isVertex) {
      _lastX = x.value;
      _lastY = y.value;
      _hasLastPoint = true;
    }

    return cmd;
  }

  @override
  Iterable<VertexData> vertices() sync* {
    rewind();
    var x = RefParam(0.0);
    var y = RefParam(0.0);

    while (true) {
      var cmd = vertex(x, y);
      if (cmd.isStop) break;
      yield VertexData(cmd, x.value, y.value);
    }
  }

  @override
  int getLongHashCode([int hash = 0xcbf29ce484222325]) {
    for (final source in _sources) {
      hash = source.getLongHashCode(hash);
    }
    hash ^= 0x434F4E4E; // ASCII "CONN"
    hash *= 1099511628211;
    return hash;
  }
}
