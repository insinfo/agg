import 'package:agg/src/shared/ref_param.dart';
import '../transform/affine.dart';
import 'ivertex_source.dart';
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
  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    final cmd = _source.vertex(x, y);

    if (cmd.isVertex) {
      final tx = x.value;
      final ty = y.value;
      x.value = tx * _transform.sx + ty * _transform.shx + _transform.tx;
      y.value = tx * _transform.shy + ty * _transform.sy + _transform.ty;
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
    hash = _source.getLongHashCode(hash);
    hash ^= _transform.hashCode;
    hash *= 1099511628211;
    return hash;
  }
}
