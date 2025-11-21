import 'dart:math' as math;

import 'package:agg/src/agg/agg_basics.dart';
import 'package:agg/src/agg/line_aa_basics.dart';
import 'package:agg/src/agg/line_aa_vertex_sequence.dart';
import 'package:agg/src/shared/ref_param.dart';

typedef CompareFunction = bool Function(int value);

/// Stub for the renderer used by the outline rasterizer. Methods should be
/// filled in once blending/image backends are ported.
abstract class LineRenderer {
  void line0(LineParameters lp);
  void line1(LineParameters lp, int xb1, int yb1);
  void line2(LineParameters lp, int xb2, int yb2);
  void line3(LineParameters lp, int xb1, int yb1, int xb2, int yb2);
  void pie(int x1, int y1, int x2, int y2, int x3, int y3);
}

class RasterizerOutlineAA {
  final LineRenderer _renderer;
  final LineAAVertexSequence _srcVertices = LineAAVertexSequence();
  OutlineJoin _lineJoin = OutlineJoin.miter;
  bool _roundCap = false;
  int _startX = 0;
  int _startY = 0;

  RasterizerOutlineAA(this._renderer);

  OutlineJoin get lineJoin => _lineJoin;
  set lineJoin(OutlineJoin join) => _lineJoin = join;

  bool get roundCap => _roundCap;
  set roundCap(bool v) => _roundCap = v;

  void moveTo(int x, int y) {
    _srcVertices.add(LineAAVertex(x, y));
    _startX = x;
    _startY = y;
  }

  void lineTo(int x, int y) {
    _srcVertices.add(LineAAVertex(x, y));
  }

  void closePolygon() {
    _srcVertices.close(true);
    render(true);
  }

  void render([bool close = false]) {
    if (_srcVertices.length < 2) return;
    if (close) {
      _srcVertices.add(LineAAVertex(_startX, _startY));
    }

    if (_srcVertices.length == 2) {
      final dx = _srcVertices[1].x - _srcVertices[0].x;
      final dy = _srcVertices[1].y - _srcVertices[0].y;
      final len = Agg_basics.uround(math.sqrt((dx * dx + dy * dy).toDouble()));
      _renderer.line0(LineParameters(_srcVertices[0].x, _srcVertices[0].y, _srcVertices[1].x, _srcVertices[1].y, len));
      return;
    }

    final DrawVars dv = DrawVars();
    dv.idx = 1;
    dv.x1 = _srcVertices[0].x;
    dv.y1 = _srcVertices[0].y;
    dv.x2 = _srcVertices[1].x;
    dv.y2 = _srcVertices[1].y;
    final dx = dv.x2 - dv.x1;
    final dy = dv.y2 - dv.y1;
    final int segLen = Agg_basics.uround(math.sqrt((dx * dx + dy * dy).toDouble()));
    dv.lcurr = dv.lnext = segLen;
    dv.curr = LineParameters(dv.x1, dv.y1, dv.x2, dv.y2, dv.lcurr);

    int flags = 3;
    if (_lineJoin == OutlineJoin.miter || _lineJoin == OutlineJoin.miterAccurate) {
      if (_srcVertices.length > 2) {
        dv.xb1 = dv.curr.x1 + (dv.curr.y2 - dv.curr.y1);
        dv.yb1 = dv.curr.y1 - (dv.curr.x2 - dv.curr.x1);
      }
    }

    _draw(dv, 1, _srcVertices.length - 1, flags);
  }

  void _draw(DrawVars dv, int start, int end, int flags) {
    dv.flags = flags;
    for (int i = start; i < end; i++) {
      if (_lineJoin == OutlineJoin.round) {
        dv.xb1 = dv.curr.x1 + (dv.curr.y2 - dv.curr.y1);
        dv.yb1 = dv.curr.y1 - (dv.curr.x2 - dv.curr.x1);
        dv.xb2 = dv.curr.x2 + (dv.curr.y2 - dv.curr.y1);
        dv.yb2 = dv.curr.y2 - (dv.curr.x2 - dv.curr.x1);
      }

      switch (dv.flags) {
        case 0:
          _renderer.line3(dv.curr, dv.xb1, dv.yb1, dv.xb2, dv.yb2);
          break;
        case 1:
          _renderer.line2(dv.curr, dv.xb2, dv.yb2);
          break;
        case 2:
          _renderer.line1(dv.curr, dv.xb1, dv.yb1);
          break;
        case 3:
          _renderer.line0(dv.curr);
          break;
      }

      if (_lineJoin == OutlineJoin.round && (dv.flags & 2) == 0) {
        _renderer.pie(
          dv.curr.x2,
          dv.curr.y2,
          dv.curr.x2 + (dv.curr.y2 - dv.curr.y1),
          dv.curr.y2 - (dv.curr.x2 - dv.curr.x1),
          dv.curr.x2 + (dv.next.y2 - dv.next.y1),
          dv.curr.y2 - (dv.next.x2 - dv.next.x1),
        );
      }

      dv.x1 = dv.x2;
      dv.y1 = dv.y2;
      dv.lcurr = dv.lnext;
      dv.lnext = _srcVertices[dv.idx].len;

      dv.idx++;
      if (dv.idx >= _srcVertices.length) dv.idx = 0;

      dv.x2 = _srcVertices[dv.idx].x;
      dv.y2 = _srcVertices[dv.idx].y;

      dv.curr = dv.next;
      dv.next = LineParameters(dv.x1, dv.y1, dv.x2, dv.y2, dv.lnext);
      dv.xb1 = dv.xb2;
      dv.yb1 = dv.yb2;

      switch (_lineJoin) {
        case OutlineJoin.noJoin:
          dv.flags = 3;
          break;
        case OutlineJoin.miter:
      dv.flags >>= 1;
      dv.flags |=
          (dv.curr.diagonalQuadrant() == dv.next.diagonalQuadrant() ? 1 : 0);
      if ((dv.flags & 2) == 0) {
        final rx = RefParam<int>(0);
        final ry = RefParam<int>(0);
        LineAABasics.bisectrix(dv.curr, dv.next, rx, ry);
        dv.xb2 = rx.value;
        dv.yb2 = ry.value;
      }
      break;
        case OutlineJoin.round:
          dv.flags = 0;
          break;
        case OutlineJoin.miterAccurate:
      dv.flags >>= 1;
      dv.flags |= _accurateJoin(dv.curr, dv.next) ? 1 : 0;
      if ((dv.flags & 2) == 0) {
        final rx = RefParam<int>(0);
        final ry = RefParam<int>(0);
        LineAABasics.bisectrix(dv.curr, dv.next, rx, ry);
        dv.xb2 = rx.value;
        dv.yb2 = ry.value;
      }
      break;
      }
    }
  }

  bool _accurateJoin(LineParameters lp1, LineParameters lp2) {
    final double d = (lp1.x2 - lp1.x1).toDouble() * (lp2.y2 - lp2.y1) -
        (lp1.y2 - lp1.y1).toDouble() * (lp2.x2 - lp2.x1);
    if (d == 0) return false;
    return ((lp1.x2 - lp1.x1) * (lp2.y2 - lp1.y1) -
            (lp1.y2 - lp1.y1) * (lp2.x2 - lp1.x1)) /
        d >
        0;
  }
}

class DrawVars {
  late int idx;
  late int x1, y1, x2, y2;
  late LineParameters curr, next;
  late int lcurr, lnext;
  int xb1 = 0, yb1 = 0, xb2 = 0, yb2 = 0;
  late int flags;
}

enum OutlineJoin { noJoin, miter, round, miterAccurate }
