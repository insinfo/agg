import 'package:agg/src/shared/ref_param.dart';
import 'ivertex_source.dart';
import 'path_commands.dart';
import 'vertex_data.dart';

/// Reverses the direction of a path.
///
/// This class takes a vertex source and returns its vertices in reverse order,
/// which is useful for changing the winding direction of paths.
class ReversePath implements IVertexSource {
  IVertexSource? _source;
  final List<VertexData> _vertices = [];
  int _currentVertex = 0;

  ReversePath([IVertexSource? source]) {
    _source = source;
  }

  /// Sets the source vertex path to reverse.
  void setSource(IVertexSource source) {
    _source = source;
  }

  @override
  void rewind([int pathId = 0]) {
    _vertices.clear();
    _currentVertex = 0;

    if (_source == null) return;

    _source!.rewind(pathId);

    // Read all vertices from the source
    final x = RefParam(0.0);
    final y = RefParam(0.0);
    FlagsAndCommand cmd;

    while ((cmd = _source!.vertex(x, y)) != FlagsAndCommand.commandStop) {
      _vertices.add(VertexData(cmd, x.value, y.value));
    }

    // Reverse the order
    if (_vertices.isNotEmpty) {
      _reverseVertices();
    }
  }

  @override
  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    if (_currentVertex >= _vertices.length) {
      x.value = 0;
      y.value = 0;
      return FlagsAndCommand.commandStop;
    }

    final v = _vertices[_currentVertex];
    x.value = v.x;
    y.value = v.y;
    _currentVertex++;

    return v.command;
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
    if (_source != null) {
      hash = _source!.getLongHashCode(hash);
    }
    hash ^= 0x52455645; // Add a marker for reversed paths (ASCII "REVE")
    hash *= 1099511628211;
    return hash;
  }

  void _reverseVertices() {
    // Find path segments and reverse each one
    int start = 0;

    for (int i = 0; i < _vertices.length; i++) {
      final cmd = _vertices[i].command;
      final cmdBase = cmd & FlagsAndCommand.commandMask;

      if (cmdBase == FlagsAndCommand.commandEndPoly ||
          i == _vertices.length - 1) {
        final end = (cmdBase == FlagsAndCommand.commandEndPoly) ? i : i + 1;
        _reverseSegment(start, end);
        start = i + 1;
      }
    }
  }

  void _reverseSegment(int start, int end) {
    if (end <= start) return;

    // Reverse the vertices in this segment
    int left = start;
    int right = end - 1;

    while (left < right) {
      // Swap vertices
      final temp = _vertices[left];
      _vertices[left] = _vertices[right];
      _vertices[right] = temp;

      left++;
      right--;
    }

    // Fix the first command to be moveTo
    if (start < _vertices.length) {
      final firstCmd = _vertices[start].command;
      final flags = firstCmd & FlagsAndCommand.flagMask;
      _vertices[start] = VertexData(
        FlagsAndCommand.commandMoveTo | flags,
        _vertices[start].x,
        _vertices[start].y,
      );
    }

    // Fix subsequent commands to be lineTo
    for (int i = start + 1; i < end; i++) {
      final cmd = _vertices[i].command;
      final cmdBase = cmd & FlagsAndCommand.commandMask;
      if (cmdBase != FlagsAndCommand.commandEndPoly) {
        final flags = cmd & FlagsAndCommand.flagMask;
        _vertices[i] = VertexData(
          FlagsAndCommand.commandLineTo | flags,
          _vertices[i].x,
          _vertices[i].y,
        );
      }
    }
  }
}
