import 'i_vertex_source.dart';
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
  FlagsAndCommand vertex(VertexOutput output) {
    if (_currentSource >= _sources.length) {
      output.set(0, 0);
      return FlagsAndCommand.commandStop;
    }

    FlagsAndCommand cmd = _sources[_currentSource].vertex(output);

    while (cmd == FlagsAndCommand.commandStop &&
        _currentSource < _sources.length - 1) {
      _currentSource++;

      // Get the first vertex of the next source
      final nextCmd = _sources[_currentSource].vertex(output);

      // If we have a last point and the next path starts with moveTo,
      // connect them with a line
      if (_hasLastPoint && nextCmd.isMoveTo) {
        final nextX = output.x;
        final nextY = output.y;

        // Return a lineTo to connect the paths
        output.set(_lastX, _lastY);
        _lastX = nextX;
        _lastY = nextY;
        return FlagsAndCommand.commandLineTo;
      }

      cmd = nextCmd;
    }

    // Track the last point for connecting paths
    if (cmd.isVertex) {
      _lastX = output.x;
      _lastY = output.y;
      _hasLastPoint = true;
    }

    return cmd;
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
    for (final source in _sources) {
      hash = source.getLongHashCode(hash);
    }
    hash ^= 0x434F4E4E; // ASCII "CONN"
    hash *= 1099511628211;
    return hash;
  }
}
