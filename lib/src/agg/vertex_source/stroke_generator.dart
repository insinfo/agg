import 'package:vector_math/vector_math.dart';
import '../vertex_sequence.dart';
import 'igenerator.dart';
import 'path_commands.dart';
import 'stroke_math.dart';
import '../../shared/ref_param.dart';
import 'vector2_container.dart';

class StrokeGenerator implements IGenerator {
  late StrokeMath _stroker;
  late VertexSequence _srcVertices;
  late Vector2Container _outVertices;
  double _shorten = 0.0;
  int _closed = 0;
  StrokeMathStatus _status = StrokeMathStatus.initial;
  StrokeMathStatus _prevStatus = StrokeMathStatus.initial;
  int _srcVertex = 0;
  int _outVertex = 0;

  StrokeGenerator() {
    _stroker = StrokeMath();
    _srcVertices = VertexSequence();
    _outVertices = Vector2Container();
  }

  @override
  double get approximationScale => _stroker.approximationScale;
  @override
  set approximationScale(double value) => _stroker.approximationScale = value;

  @override
  bool autoDetectOrientation = false;

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
  void miterLimitTheta(double t) => _stroker.miterLimitTheta(t);

  @override
  double get shorten => _shorten;
  @override
  set shorten(double value) => _shorten = value;

  @override
  double get width => _stroker.widthValue;
  @override
  set width(double value) => _stroker.width = value;

  @override
  void removeAll() {
    _srcVertices.clear();
    _closed = 0;
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
        if (ShapePath.isClose(cmd)) {
           _closed = 1; // Assuming flagClose is set
        }
        // Or use get_close_flag logic if needed, but here we just check isClose
        // In C#: m_closed = (int)ShapePath.get_close_flag(cmd);
        // get_close_flag returns the flag itself.
        // If we store it as int, we might want to preserve the flag value?
        // But later it checks m_closed != 0.
        // So just setting it to 1 if closed is fine, or preserving the flag.
        if (cmd.isClose) {
           _closed = FlagsAndCommand.flagClose.value;
        } else {
           _closed = 0;
        }
      }
    }
  }

  @override
  void rewind(int pathId) {
    if (_status == StrokeMathStatus.initial) {
      _srcVertices.close(_closed != 0);
      ShapePath.shortenPath(_srcVertices, _shorten, _closed);
      if (_srcVertices.length < 3) _closed = 0;
    }
    _status = StrokeMathStatus.ready;
    _srcVertex = 0;
    _outVertex = 0;
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
          if (_srcVertices.length < 2 + (_closed != 0 ? 1 : 0)) {
            cmd = FlagsAndCommand.commandStop;
            break;
          }
          _status = (_closed != 0) ? StrokeMathStatus.outline1 : StrokeMathStatus.cap1;
          cmd = FlagsAndCommand.commandMoveTo;
          _srcVertex = 0;
          _outVertex = 0;
          break;

        case StrokeMathStatus.cap1:
          _stroker.calcCap(_outVertices, _srcVertices[0], _srcVertices[1],
              _srcVertices[0].dist);
          _srcVertex = 1;
          _prevStatus = StrokeMathStatus.outline1;
          _status = StrokeMathStatus.outVertices;
          _outVertex = 0;
          break;

        case StrokeMathStatus.cap2:
          _stroker.calcCap(_outVertices,
              _srcVertices[_srcVertices.length - 1],
              _srcVertices[_srcVertices.length - 2],
              _srcVertices[_srcVertices.length - 2].dist);
          _prevStatus = StrokeMathStatus.outline2;
          _status = StrokeMathStatus.outVertices;
          _outVertex = 0;
          break;

        case StrokeMathStatus.outline1:
          if (_closed != 0) {
            if (_srcVertex >= _srcVertices.length) {
              _prevStatus = StrokeMathStatus.closeFirst;
              _status = StrokeMathStatus.endPoly1;
              break;
            }
          } else {
            if (_srcVertex >= _srcVertices.length - 1) {
              _status = StrokeMathStatus.cap2;
              break;
            }
          }
          _stroker.calcJoin(_outVertices,
              _srcVertices.prev(_srcVertex),
              _srcVertices.curr(_srcVertex),
              _srcVertices.next(_srcVertex),
              _srcVertices.prev(_srcVertex).dist,
              _srcVertices.curr(_srcVertex).dist);
          ++_srcVertex;
          _prevStatus = _status;
          _status = StrokeMathStatus.outVertices;
          _outVertex = 0;
          break;

        case StrokeMathStatus.closeFirst:
          _status = StrokeMathStatus.outline2;
          cmd = FlagsAndCommand.commandMoveTo;
          continue; // goto case outline2

        case StrokeMathStatus.outline2:
          if (_srcVertex <= (_closed == 0 ? 1 : 0)) {
            _status = StrokeMathStatus.endPoly2;
            _prevStatus = StrokeMathStatus.stop;
            break;
          }

          --_srcVertex;
          _stroker.calcJoin(_outVertices,
              _srcVertices.next(_srcVertex),
              _srcVertices.curr(_srcVertex),
              _srcVertices.prev(_srcVertex),
              _srcVertices.curr(_srcVertex).dist,
              _srcVertices.prev(_srcVertex).dist);

          _prevStatus = _status;
          _status = StrokeMathStatus.outVertices;
          _outVertex = 0;
          break;

        case StrokeMathStatus.outVertices:
          if (_outVertex >= _outVertices.count) {
            _status = _prevStatus;
          } else {
            Vector2 c = _outVertices[_outVertex++];
            x.value = c.x;
            y.value = c.y;
            return cmd;
          }
          break;

        case StrokeMathStatus.endPoly1:
          _status = _prevStatus;
          return FlagsAndCommand.commandEndPoly |
              FlagsAndCommand.flagClose |
              FlagsAndCommand.flagCCW;

        case StrokeMathStatus.endPoly2:
          _status = _prevStatus;
          return FlagsAndCommand.commandEndPoly |
              FlagsAndCommand.flagClose |
              FlagsAndCommand.flagCW;

        case StrokeMathStatus.stop:
          cmd = FlagsAndCommand.commandStop;
          break;
      }
    }
    return cmd;
  }
}
