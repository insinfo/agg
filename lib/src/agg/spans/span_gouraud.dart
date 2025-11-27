import '../agg_math.dart';
import '../primitives/color.dart';
import '../primitives/i_color_type.dart';
import '../vertex_source/ivertex_source.dart';
import '../vertex_source/path_commands.dart';
import '../vertex_source/vertex_data.dart';
import '../../shared/ref_param.dart';

class CoordType {
  double x = 0.0;
  double y = 0.0;
  Color color = Color(0, 0, 0);
}

class SpanGouraud implements IVertexSource {
  final List<CoordType> _coord = List.generate(3, (_) => CoordType());
  final List<double> _x = List.filled(8, 0.0);
  final List<double> _y = List.filled(8, 0.0);
  final List<FlagsAndCommand> _cmd = List.filled(8, FlagsAndCommand.commandStop);
  int _vertex = 0;

  SpanGouraud([
    Color? c1,
    Color? c2,
    Color? c3,
    double x1 = 0,
    double y1 = 0,
    double x2 = 0,
    double y2 = 0,
    double x3 = 0,
    double y3 = 0,
    double d = 0,
  ]) {
    _vertex = 0;
    _cmd[0] = FlagsAndCommand.commandStop;
    if (c1 != null && c2 != null && c3 != null) {
      colors(c1, c2, c3);
      triangle(x1, y1, x2, y2, x3, y3, d);
    }
  }

  void colors(IColorType c1, IColorType c2, IColorType c3) {
    _coord[0].color = c1 is Color
        ? c1
        : Color(c1.red0To255, c1.green0To255, c1.blue0To255, c1.alpha0To255);
    _coord[1].color = c2 is Color
        ? c2
        : Color(c2.red0To255, c2.green0To255, c2.blue0To255, c2.alpha0To255);
    _coord[2].color = c3 is Color
        ? c3
        : Color(c3.red0To255, c3.green0To255, c3.blue0To255, c3.alpha0To255);
  }

  void triangle(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
    double dilation,
  ) {
    _coord[0].x = _x[0] = x1;
    _coord[0].y = _y[0] = y1;
    _coord[1].x = _x[1] = x2;
    _coord[1].y = _y[1] = y2;
    _coord[2].x = _x[2] = x3;
    _coord[2].y = _y[2] = y3;
    _cmd[0] = FlagsAndCommand.commandMoveTo;
    _cmd[1] = FlagsAndCommand.commandLineTo;
    _cmd[2] = FlagsAndCommand.commandLineTo;
    _cmd[3] = FlagsAndCommand.commandStop;

    if (dilation != 0.0) {
      AggMath.dilate_triangle(
        _coord[0].x,
        _coord[0].y,
        _coord[1].x,
        _coord[1].y,
        _coord[2].x,
        _coord[2].y,
        _x,
        _y,
        dilation,
      );

      var intersection1 = AggMath.calc_intersection(
        _x[4],
        _y[4],
        _x[5],
        _y[5],
        _x[0],
        _y[0],
        _x[1],
        _y[1],
      );
      if (intersection1 != null) {
        _coord[0].x = intersection1.x;
        _coord[0].y = intersection1.y;
      }

      var intersection2 = AggMath.calc_intersection(
        _x[0],
        _y[0],
        _x[1],
        _y[1],
        _x[2],
        _y[2],
        _x[3],
        _y[3],
      );
      if (intersection2 != null) {
        _coord[1].x = intersection2.x;
        _coord[1].y = intersection2.y;
      }

      var intersection3 = AggMath.calc_intersection(
        _x[2],
        _y[2],
        _x[3],
        _y[3],
        _x[4],
        _y[4],
        _x[5],
        _y[5],
      );
      if (intersection3 != null) {
        _coord[2].x = intersection3.x;
        _coord[2].y = intersection3.y;
      }

      _cmd[3] = FlagsAndCommand.commandLineTo;
      _cmd[4] = FlagsAndCommand.commandLineTo;
      _cmd[5] = FlagsAndCommand.commandLineTo;
      _cmd[6] = FlagsAndCommand.commandStop;
    }
  }

  @override
  void rewind([int pathId = 0]) {
    _vertex = 0;
  }

  @override
  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    x.value = _x[_vertex];
    y.value = _y[_vertex];
    return _cmd[_vertex++];
  }

  @override
  int getLongHashCode([int hash = 0xcbf29ce484222325]) {
    return hash;
  }

  @override
  Iterable<VertexData> vertices() sync* {
    rewind(0);
    var x = RefParam(0.0);
    var y = RefParam(0.0);
    var cmd = vertex(x, y);
    while (!ShapePath.isStop(cmd)) {
      yield VertexData(cmd, x.value, y.value);
      cmd = vertex(x, y);
    }
  }

  void arrangeVertices(List<CoordType> coord) {
    coord[0] = _coord[0];
    coord[1] = _coord[1];
    coord[2] = _coord[2];

    if (_coord[0].y > _coord[2].y) {
      coord[0] = _coord[2];
      coord[2] = _coord[0];
    }

    CoordType tmp;
    if (coord[0].y > coord[1].y) {
      tmp = coord[1];
      coord[1] = coord[0];
      coord[0] = tmp;
    }

    if (coord[1].y > coord[2].y) {
      tmp = coord[2];
      coord[2] = coord[1];
      coord[1] = tmp;
    }
  }
}
