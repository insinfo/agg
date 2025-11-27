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
  void semidot(CompareFunction cmp, int xc1, int yc1, int xc2, int yc2);
  void pie(int x1, int y1, int x2, int y2, int x3, int y3);
}

class RasterizerOutlineAA {
  final LineRenderer _renderer;
  final LineAAVertexSequence _srcVertices = LineAAVertexSequence();
  OutlineJoin _lineJoin = OutlineJoin.round; // Default to round like Rust
  bool _roundCap = false;
  int _startX = 0;
  int _startY = 0;

  RasterizerOutlineAA(this._renderer);

  OutlineJoin get lineJoin => _lineJoin;
  set lineJoin(OutlineJoin join) => _lineJoin = join;

  bool get roundCap => _roundCap;
  set roundCap(bool v) => _roundCap = v;

  bool cmpDistStart(int d) => d > 0;
  bool cmpDistEnd(int d) => d <= 0;

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
    _srcVertices.close(close);
    final DrawVars dv = DrawVars();
    LineAAVertex v;
    int x1, y1, x2, y2, lprev;

    if (close) {
      if (_srcVertices.length >= 3) {
        dv.idx = 2;

        v = _srcVertices[_srcVertices.length - 1];
        x1 = v.x;
        y1 = v.y;
        lprev = v.len;

        v = _srcVertices[0];
        x2 = v.x;
        y2 = v.y;
        dv.lcurr = v.len;
        final LineParameters prev = LineParameters(x1, y1, x2, y2, lprev);

        v = _srcVertices[1];
        dv.x1 = v.x;
        dv.y1 = v.y;
        dv.lnext = v.len;
        dv.curr = LineParameters(x2, y2, dv.x1, dv.y1, dv.lcurr);

        v = _srcVertices[dv.idx];
        dv.x2 = v.x;
        dv.y2 = v.y;
        dv.next = LineParameters(dv.x1, dv.y1, dv.x2, dv.y2, dv.lnext);

        dv.xb1 = 0;
        dv.yb1 = 0;
        dv.xb2 = 0;
        dv.yb2 = 0;

        switch (_lineJoin) {
          case OutlineJoin.noJoin:
            dv.flags = 3;
            break;
          case OutlineJoin.miter:
          case OutlineJoin.round:
            dv.flags = (prev.diagonalQuadrant() == dv.curr.diagonalQuadrant()
                    ? 1
                    : 0) |
                ((dv.curr.diagonalQuadrant() == dv.next.diagonalQuadrant()
                        ? 1
                        : 0) <<
                    1);
            break;
          case OutlineJoin.miterAccurate:
            dv.flags = 0;
            break;
        }

        if ((dv.flags & 1) == 0 && _lineJoin != OutlineJoin.round) {
          final rx = RefParam<int>(0);
          final ry = RefParam<int>(0);
          LineAABasics.bisectrix(prev, dv.curr, rx, ry);
          dv.xb1 = rx.value;
          dv.yb1 = ry.value;
        }

        if ((dv.flags & 2) == 0 && _lineJoin != OutlineJoin.round) {
          final rx = RefParam<int>(0);
          final ry = RefParam<int>(0);
          LineAABasics.bisectrix(dv.curr, dv.next, rx, ry);
          dv.xb2 = rx.value;
          dv.yb2 = ry.value;
        }
        _draw(dv, 0, _srcVertices.length);
      }
    } else {
      switch (_srcVertices.length) {
        case 0:
        case 1:
          break;
        case 2:
          {
            v = _srcVertices[0];
            x1 = v.x;
            y1 = v.y;
            lprev = v.len;
            v = _srcVertices[1];
            x2 = v.x;
            y2 = v.y;
            final LineParameters lp = LineParameters(x1, y1, x2, y2, lprev);
            if (_roundCap) {
              _renderer.semidot(
                  cmpDistStart, x1, y1, x1 + (y2 - y1), y1 - (x2 - x1));
            }
            _renderer.line3(
                lp, x1 + (y2 - y1), y1 - (x2 - x1), x2 + (y2 - y1), y2 - (x2 - x1));
            if (_roundCap) {
              _renderer.semidot(
                  cmpDistEnd, x2, y2, x2 + (y2 - y1), y2 - (x2 - x1));
            }
          }
          break;
        case 3:
          {
            int x3, y3;
            int lnext;
            v = _srcVertices[0];
            x1 = v.x;
            y1 = v.y;
            lprev = v.len;
            v = _srcVertices[1];
            x2 = v.x;
            y2 = v.y;
            lnext = v.len;
            v = _srcVertices[2];
            x3 = v.x;
            y3 = v.y;
            final LineParameters lp1 = LineParameters(x1, y1, x2, y2, lprev);
            final LineParameters lp2 = LineParameters(x2, y2, x3, y3, lnext);

            if (_roundCap) {
              _renderer.semidot(
                  cmpDistStart, x1, y1, x1 + (y2 - y1), y1 - (x2 - x1));
            }

            if (_lineJoin == OutlineJoin.round) {
              _renderer.line3(lp1, x1 + (y2 - y1), y1 - (x2 - x1),
                  x2 + (y2 - y1), y2 - (x2 - x1));
              _renderer.pie(x2, y2, x2 + (y2 - y1), y2 - (x2 - x1),
                  x2 + (y3 - y2), y2 - (x3 - x2));
              _renderer.line3(lp2, x2 + (y3 - y2), y2 - (x3 - x2),
                  x3 + (y3 - y2), y3 - (x3 - x2));
            } else {
              final rx = RefParam<int>(0);
              final ry = RefParam<int>(0);
              LineAABasics.bisectrix(lp1, lp2, rx, ry);
              dv.xb1 = rx.value;
              dv.yb1 = ry.value;
              _renderer.line3(lp1, x1 + (y2 - y1), y1 - (x2 - x1), dv.xb1, dv.yb1);
              _renderer.line3(lp2, dv.xb1, dv.yb1, x3 + (y3 - y2), y3 - (x3 - x2));
            }
            if (_roundCap) {
              _renderer.semidot(
                  cmpDistEnd, x3, y3, x3 + (y3 - y2), y3 - (x3 - x2));
            }
          }
          break;
        default:
          {
            dv.idx = 3;
            v = _srcVertices[0];
            x1 = v.x;
            y1 = v.y;
            lprev = v.len;

            v = _srcVertices[1];
            x2 = v.x;
            y2 = v.y;
            dv.lcurr = v.len;
            final LineParameters prev = LineParameters(x1, y1, x2, y2, lprev);

            v = _srcVertices[2];
            dv.x1 = v.x;
            dv.y1 = v.y;
            dv.lnext = v.len;
            dv.curr = LineParameters(x2, y2, dv.x1, dv.y1, dv.lcurr);

            v = _srcVertices[dv.idx];
            dv.x2 = v.x;
            dv.y2 = v.y;
            dv.next = LineParameters(dv.x1, dv.y1, dv.x2, dv.y2, dv.lnext);

            dv.xb1 = 0;
            dv.yb1 = 0;
            dv.xb2 = 0;
            dv.yb2 = 0;

            switch (_lineJoin) {
              case OutlineJoin.noJoin:
                dv.flags = 3;
                break;
              case OutlineJoin.miter:
              case OutlineJoin.round:
                dv.flags = (prev.diagonalQuadrant() == dv.curr.diagonalQuadrant()
                        ? 1
                        : 0) |
                    ((dv.curr.diagonalQuadrant() == dv.next.diagonalQuadrant()
                            ? 1
                            : 0) <<
                        1);
                break;
              case OutlineJoin.miterAccurate:
                dv.flags = 0;
                break;
            }

            if (_roundCap) {
              _renderer.semidot(
                  cmpDistStart, x1, y1, x1 + (y2 - y1), y1 - (x2 - x1));
            }

            if ((dv.flags & 1) == 0) {
              if (_lineJoin == OutlineJoin.round) {
                _renderer.line3(prev, x1 + (y2 - y1), y1 - (x2 - x1),
                    x2 + (y2 - y1), y2 - (x2 - x1));
                _renderer.pie(prev.x2, prev.y2, x2 + (y2 - y1), y2 - (x2 - x1),
                    dv.curr.x1 + (dv.curr.y2 - dv.curr.y1),
                    dv.curr.y1 - (dv.curr.x2 - dv.curr.x1));
              } else {
                final rx = RefParam<int>(0);
                final ry = RefParam<int>(0);
                LineAABasics.bisectrix(prev, dv.curr, rx, ry);
                dv.xb1 = rx.value;
                dv.yb1 = ry.value;
                _renderer.line3(prev, x1 + (y2 - y1), y1 - (x2 - x1), dv.xb1, dv.yb1);
              }
            } else {
              _renderer.line1(prev, x1 + (y2 - y1), y1 - (x2 - x1));
            }

            if ((dv.flags & 2) == 0 && _lineJoin != OutlineJoin.round) {
              final rx = RefParam<int>(0);
              final ry = RefParam<int>(0);
              LineAABasics.bisectrix(dv.curr, dv.next, rx, ry);
              dv.xb2 = rx.value;
              dv.yb2 = ry.value;
            }

            _draw(dv, 1, _srcVertices.length - 2, 0); // flags passed as 0 but overwritten in draw

            if ((dv.flags & 1) == 0) {
              if (_lineJoin == OutlineJoin.round) {
                _renderer.line3(dv.curr, dv.curr.x1 + (dv.curr.y2 - dv.curr.y1),
                    dv.curr.y1 - (dv.curr.x2 - dv.curr.x1),
                    dv.curr.x2 + (dv.curr.y2 - dv.curr.y1),
                    dv.curr.y2 - (dv.curr.x2 - dv.curr.x1));
              } else {
                _renderer.line3(dv.curr, dv.xb1, dv.yb1,
                    dv.curr.x2 + (dv.curr.y2 - dv.curr.y1),
                    dv.curr.y2 - (dv.curr.x2 - dv.curr.x1));
              }
            } else {
              _renderer.line2(dv.curr, dv.curr.x2 + (dv.curr.y2 - dv.curr.y1),
                  dv.curr.y2 - (dv.curr.x2 - dv.curr.x1));
            }

            if (_roundCap) {
              _renderer.semidot(cmpDistEnd, dv.curr.x2, dv.curr.y2,
                  dv.curr.x2 + (dv.curr.y2 - dv.curr.y1),
                  dv.curr.y2 - (dv.curr.x2 - dv.curr.x1));
            }
          }
          break;
      }
    }
    _srcVertices.clear();
  }

  void _draw(DrawVars dv, int start, int end, [int flags = 0]) {
    // flags argument is ignored if not passed, but we use dv.flags
    // In C# draw takes ref dv, start, end. flags is inside dv.
    // But in my previous implementation I passed flags.
    // Now I will use dv.flags.
    
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
          dv.flags |= (dv.curr.diagonalQuadrant() == dv.next.diagonalQuadrant()
              ? 1
              : 0);
          if ((dv.flags & 2) == 0) {
            final rx = RefParam<int>(0);
            final ry = RefParam<int>(0);
            LineAABasics.bisectrix(dv.curr, dv.next, rx, ry);
            dv.xb2 = rx.value;
            dv.yb2 = ry.value;
          }
          break;
        case OutlineJoin.round:
          dv.flags >>= 1;
          dv.flags |= ((dv.curr.diagonalQuadrant() == dv.next.diagonalQuadrant()
                  ? 1
                  : 0) <<
              1);
          break;
        case OutlineJoin.miterAccurate:
          dv.flags = 0;
          final rx = RefParam<int>(0);
          final ry = RefParam<int>(0);
          LineAABasics.bisectrix(dv.curr, dv.next, rx, ry);
          dv.xb2 = rx.value;
          dv.yb2 = ry.value;
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
