import '../transform/affine.dart';
import 'i_vertex_source.dart';
import 'path_commands.dart';
import 'vertex_data.dart';

/// Applies an affine transformation to a vertex source.
///
/// This class wraps another vertex source and applies an affine transformation
/// to all vertices as they are retrieved.
class ApplyTransform implements IVertexSource {
  IVertexSource _source;
  Affine _transform;

  ApplyTransform(this._source, this._transform);

  /// Gets the current transformation matrix.
  Affine get transform => _transform;

  /// Sets a new transformation matrix.
  set transform(Affine value) {
    _transform = value;
  }

  /// Gets the source vertex path.
  IVertexSource get source => _source;

  /// Sets a new source vertex path.
  set source(IVertexSource value) {
    _source = value;
  }

  @override
  void rewind([int pathId = 0]) {
    _source.rewind(pathId);
  }

  @override
  FlagsAndCommand vertex(VertexOutput output) {
    final cmd = _source.vertex(output);

    if (cmd.isVertex) {
      final x = output.x;
      final y = output.y;
      output.x = _transform.sx * x + _transform.shx * y + _transform.tx;
      output.y = _transform.shy * x + _transform.sy * y + _transform.ty;
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
    hash = _source.getLongHashCode(hash);
    hash ^= _transform.hashCode;
    hash *= 1099511628211;
    return hash;
  }
}
