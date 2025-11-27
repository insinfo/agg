import 'package:agg/src/shared/ref_param.dart';
import 'ivertex_source.dart';
import 'path_commands.dart';
import 'vertex_data.dart';

/// Joins multiple vertex sources into a single path.
///
/// This class allows you to combine multiple vertex sources and iterate
/// through them as if they were a single path.
class JoinPaths implements IVertexSource {
  final List<IVertexSource> _sources = [];
  int _currentSource = 0;

  JoinPaths([List<IVertexSource>? sources]) {
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
      cmd = _sources[_currentSource].vertex(x, y);
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
    return hash;
  }
}
