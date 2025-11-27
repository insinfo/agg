import 'package:vector_math/vector_math.dart';
import '../agg_math.dart';
import '../vertex_sequence.dart';
import 'igenerator.dart';
import 'path_commands.dart';
import 'stroke_math.dart';
import '../../shared/ref_param.dart';
import 'vector2_container.dart';

class ContourGenerator implements IGenerator {
  late StrokeMath _stroker;
  double _width = 1.0;
  late VertexSequence _srcVertices;
  late Vector2Container _outVertices;
  StrokeMathStatus _status = StrokeMathStatus.initial;
  int _srcVertex = 0;
  int _outVertex = 0;
  bool _closed = false;
  FlagsAndCommand _orientation = FlagsAndCommand.flagNone;
  bool _autoDetect = false;
  double _shorten = 0.0;

  ContourGenerator() {
    _stroker = StrokeMath();
    _width = 1;
    _srcVertices = VertexSequence();
    _outVertices = Vector2Container();
    _status = StrokeMathStatus.initial;
    _srcVertex = 0;
    _closed = false;
    _orientation = FlagsAndCommand.flagNone;
    _autoDetect = false;
  }

  @override
  double get approximationScale => _stroker.approximationScale;
  @override
  set approximationScale(double value) => _stroker.approximationScale = value;

  @override
  bool get autoDetectOrientation => _autoDetect;
  @override
  set autoDetectOrientation(bool value) => _autoDetect = value;

  @override
  InnerJoin get innerJoin => _stroker.innerJoin;
  @override
  set innerJoin(InnerJoin value) => _stroker.innerJoin = value;

  @override
  double get innerMiterLimit => _stroker.innerMiterLimit;
  @override
  set innerMiterLimit(double value) => _stroker.innerMiterLimit = value;

  @override
  LineCap get lineCap => _stroker.lineCap;
  @override
  set lineCap(LineCap value) => _stroker.lineCap = value;

  @override
  LineJoin get lineJoin => _stroker.lineJoin;
  @override
  set lineJoin(LineJoin value) => _stroker.lineJoin = value;

  @override
  double get miterLimit => _stroker.miterLimit;
  @override
  set miterLimit(double value) => _stroker.miterLimit = value;

  @override
  double get shorten => _shorten;
  @override
  set shorten(double value) => _shorten = value;

  @override
  double get width => _stroker.widthValue;
  @override
  set width(double value) => _stroker.width = value;

  @override
  void miterLimitTheta(double t) => _stroker.miterLimitTheta(t);

  @override
  void removeAll() {
    _srcVertices.clear();
    _closed = false;
    _status = StrokeMathStatus.initial;
  }

  @override
  void addVertex(double x, double y, FlagsAndCommand cmd) {
    _status = StrokeMathStatus.initial;
    if (ShapePath.isMoveTo(cmd)) {
      _srcVertices.modifyLast(VertexDistance(x, y));
    } else {
      if (ShapePath.isVertex(cmd)) {
        _srcVertices.add(VertexDistance(x, y));
      } else {
        if (ShapePath.isEndPoly(cmd)) {
          _closed = ShapePath.getCloseFlag(cmd) == FlagsAndCommand.flagClose;
          if (_orientation == FlagsAndCommand.flagNone) {
            _orientation = ShapePath.getOrientation(cmd);
          }
        }
      }
    }
  }

  @override
  void rewind(int pathId) {
    if (_status == StrokeMathStatus.initial) {
      _srcVertices.close(true);
      if (_autoDetect) {
        if (!ShapePath.isOriented(_orientation)) {
          _orientation = (AggMath.calc_polygon_area(_srcVertices.items) > 0.0)
              ? FlagsAndCommand.flagCCW
              : FlagsAndCommand.flagCW;
        }
      }
      if (ShapePath.isOriented(_orientation)) {
        _stroker.width = ShapePath.isCCW(_orientation) ? _width : -_width;
      }
    }
    _status = StrokeMathStatus.ready;
    _srcVertex = 0;
  }

  @override
  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    FlagsAndCommand cmd = FlagsAndCommand.commandLineTo;
    while (!ShapePath.isStop(cmd)) {
      switch (_status) {
        case StrokeMathStatus.initial:
          rewind(0);
          _status = StrokeMathStatus.ready;
          continue;

        case StrokeMathStatus.ready:
          if (_srcVertices.length < 2 + (_closed ? 1 : 0)) {
            cmd = FlagsAndCommand.commandStop;
            break;
          }
          _status = StrokeMathStatus.outline1;
          cmd = FlagsAndCommand.commandMoveTo;
          _srcVertex = 0;
          _outVertex = 0;
          continue; // goto case outline1

        case StrokeMathStatus.outline1:
          if (_srcVertex >= _srcVertices.length) {
            _status = StrokeMathStatus.endPoly1;
            break;
          }
          _stroker.calcJoin(_outVertices,
              _srcVertices.prev(_srcVertex),
              _srcVertices.curr(_srcVertex),
              _srcVertices.next(_srcVertex),
              _srcVertices.prev(_srcVertex).dist,
              _srcVertices.curr(_srcVertex).dist);
          ++_srcVertex;
          _status = StrokeMathStatus.outVertices;
          _outVertex = 0;
          continue; // goto case outVertices

        case StrokeMathStatus.outVertices:
          if (_outVertex >= _outVertices.count) {
            _status = StrokeMathStatus.outline1;
          } else {
            Vector2 c = _outVertices[_outVertex++];
            x.value = c.x;
            y.value = c.y;
            return cmd;
          }
          break;

        case StrokeMathStatus.endPoly1:
          if (!_closed) return FlagsAndCommand.commandStop;
          _status = StrokeMathStatus.stop;
          return FlagsAndCommand.commandEndPoly |
              FlagsAndCommand.flagClose |
              FlagsAndCommand.flagCCW;

        case StrokeMathStatus.stop:
          return FlagsAndCommand.commandStop;
          
        default:
          // Should not happen
          return FlagsAndCommand.commandStop;
      }
    }
    return cmd;
  }
}
