import 'dart:math' as math;
import 'package:vector_math/vector_math.dart';
import '../agg_math.dart';
import '../interfaces/ivertex_dest.dart';
import '../vertex_sequence.dart';

enum LineCap {
  butt,
  square,
  round,
}

enum LineJoin {
  miter,
  miterRevert,
  round,
  bevel,
  miterRound,
}

enum InnerJoin {
  bevel,
  miter,
  jag,
  round,
}

enum StrokeMathStatus {
  initial,
  ready,
  cap1,
  cap2,
  outline1,
  closeFirst,
  outline2,
  outVertices,
  endPoly1,
  endPoly2,
  stop,
}

class StrokeMath {
  double _width = 0.5;
  double _widthAbs = 0.5;
  double _widthEps = 0.5 / 1024.0;
  int _widthSign = 1;
  double _miterLimit = 4.0;
  double _innerMiterLimit = 1.01;
  double _approxScale = 1.0;
  LineCap _lineCap = LineCap.butt;
  LineJoin _lineJoin = LineJoin.miter;
  InnerJoin _innerJoin = InnerJoin.miter;

  StrokeMath() {
    _width = 0.5;
    _widthAbs = 0.5;
    _widthEps = 0.5 / 1024.0;
    _widthSign = 1;
    _miterLimit = 4.0;
    _innerMiterLimit = 1.01;
    _approxScale = 1.0;
    _lineCap = LineCap.butt;
    _lineJoin = LineJoin.miter;
    _innerJoin = InnerJoin.miter;
  }

  void set lineCap(LineCap lc) {
    _lineCap = lc;
  }

  void set lineJoin(LineJoin lj) {
    _lineJoin = lj;
  }

  void set innerJoin(InnerJoin ij) {
    _innerJoin = ij;
  }

  LineCap get lineCap => _lineCap;
  LineJoin get lineJoin => _lineJoin;
  InnerJoin get innerJoin => _innerJoin;

  void set width(double w) {
    _width = w * 0.5;
    if (_width < 0) {
      _widthAbs = -_width;
      _widthSign = -1;
    } else {
      _widthAbs = _width;
      _widthSign = 1;
    }
    _widthEps = _width / 1024.0;
  }

  void set miterLimit(double ml) {
    _miterLimit = ml;
  }

  void miterLimitTheta(double t) {
    _miterLimit = 1.0 / math.sin(t * 0.5);
  }

  void set innerMiterLimit(double ml) {
    _innerMiterLimit = ml;
  }

  void set approximationScale(double aproxScale) {
    _approxScale = aproxScale;
  }

  double get widthValue => _width * 2.0;
  double get miterLimit => _miterLimit;
  double get innerMiterLimit => _innerMiterLimit;
  double get approximationScale => _approxScale;

  void calcCap(IVertexDest vc, VertexDistance v0, VertexDistance v1, double len) {
    vc.clear();

    double dx1 = (v1.y - v0.y) / len;
    double dy1 = (v1.x - v0.x) / len;
    double dx2 = 0;
    double dy2 = 0;

    dx1 *= _width;
    dy1 *= _width;

    if (_lineCap != LineCap.round) {
      if (_lineCap == LineCap.square) {
        dx2 = dy1 * _widthSign;
        dy2 = dx1 * _widthSign;
      }
      addVertex(vc, v0.x - dx1 - dx2, v0.y + dy1 - dy2);
      addVertex(vc, v0.x + dx1 - dx2, v0.y - dy1 - dy2);
    } else {
      double da = math.acos(_widthAbs / (_widthAbs + 0.125 / _approxScale)) * 2;
      double a1;
      int i;
      int n = (math.pi / da).toInt();

      da = math.pi / (n + 1);
      addVertex(vc, v0.x - dx1, v0.y + dy1);
      if (_widthSign > 0) {
        a1 = math.atan2(dy1, -dx1);
        a1 += da;
        for (i = 0; i < n; i++) {
          addVertex(vc, v0.x + math.cos(a1) * _width, v0.y + math.sin(a1) * _width);
          a1 += da;
        }
      } else {
        a1 = math.atan2(-dy1, dx1);
        a1 -= da;
        for (i = 0; i < n; i++) {
          addVertex(vc, v0.x + math.cos(a1) * _width, v0.y + math.sin(a1) * _width);
          a1 -= da;
        }
      }
      addVertex(vc, v0.x + dx1, v0.y - dy1);
    }
  }

  void calcJoin(IVertexDest vc, VertexDistance v0, VertexDistance v1, VertexDistance v2, double len1, double len2) {
    double dx1 = _width * (v1.y - v0.y) / len1;
    double dy1 = _width * (v1.x - v0.x) / len1;
    double dx2 = _width * (v2.y - v1.y) / len2;
    double dy2 = _width * (v2.x - v1.x) / len2;

    vc.clear();

    double cp = AggMath.cross_product(v0.x, v0.y, v1.x, v1.y, v2.x, v2.y);
    if (cp != 0 && (cp > 0) == (_width > 0)) {
      // Inner join
      double limit = ((len1 < len2) ? len1 : len2) / _widthAbs;
      if (limit < _innerMiterLimit) {
        limit = _innerMiterLimit;
      }

      switch (_innerJoin) {
        case InnerJoin.miter:
          calcMiter(vc, v0, v1, v2, dx1, dy1, dx2, dy2, LineJoin.miterRevert, limit, 0);
          break;

        case InnerJoin.jag:
        case InnerJoin.round:
          cp = (dx1 - dx2) * (dx1 - dx2) + (dy1 - dy2) * (dy1 - dy2);
          if (cp < len1 * len1 && cp < len2 * len2) {
            calcMiter(vc, v0, v1, v2, dx1, dy1, dx2, dy2, LineJoin.miterRevert, limit, 0);
          } else {
            if (_innerJoin == InnerJoin.jag) {
              addVertex(vc, v1.x + dx1, v1.y - dy1);
              addVertex(vc, v1.x, v1.y);
              addVertex(vc, v1.x + dx2, v1.y - dy2);
            } else {
              addVertex(vc, v1.x + dx1, v1.y - dy1);
              addVertex(vc, v1.x, v1.y);
              calcArc(vc, v1.x, v1.y, dx2, -dy2, dx1, -dy1);
              addVertex(vc, v1.x, v1.y);
              addVertex(vc, v1.x + dx2, v1.y - dy2);
            }
          }
          break;
        default: // inner_bevel
          addVertex(vc, v1.x + dx1, v1.y - dy1);
          addVertex(vc, v1.x + dx2, v1.y - dy2);
          break;
      }
    } else {
      // Outer join
      double dx = (dx1 + dx2) / 2;
      double dy = (dy1 + dy2) / 2;
      double dbevel = math.sqrt(dx * dx + dy * dy);

      if (_lineJoin == LineJoin.round || _lineJoin == LineJoin.bevel) {
        if (_approxScale * (_widthAbs - dbevel) < _widthEps) {
          var intersection = AggMath.calc_intersection(
              v0.x + dx1, v0.y - dy1, v1.x + dx1, v1.y - dy1, v1.x + dx2, v1.y - dy2, v2.x + dx2, v2.y - dy2);
          if (intersection != null) {
            addVertex(vc, intersection.x, intersection.y);
          } else {
            addVertex(vc, v1.x + dx1, v1.y - dy1);
          }
          return;
        }
      }

      switch (_lineJoin) {
        case LineJoin.miter:
        case LineJoin.miterRevert:
        case LineJoin.miterRound:
          calcMiter(vc, v0, v1, v2, dx1, dy1, dx2, dy2, _lineJoin, _miterLimit, dbevel);
          break;

        case LineJoin.round:
          calcArc(vc, v1.x, v1.y, dx1, -dy1, dx2, -dy2);
          break;

        default: // Bevel join
          addVertex(vc, v1.x + dx1, v1.y - dy1);
          addVertex(vc, v1.x + dx2, v1.y - dy2);
          break;
      }
    }
  }

  void addVertex(IVertexDest vc, double x, double y) {
    vc.add(Vector2(x, y));
  }

  void calcArc(IVertexDest vc, double x, double y, double dx1, double dy1, double dx2, double dy2) {
    double a1 = math.atan2(dy1 * _widthSign, dx1 * _widthSign);
    double a2 = math.atan2(dy2 * _widthSign, dx2 * _widthSign);
    double da = a1 - a2;
    int i, n;

    da = math.acos(_widthAbs / (_widthAbs + 0.125 / _approxScale)) * 2;

    addVertex(vc, x + dx1, y + dy1);
    if (_widthSign > 0) {
      if (a1 > a2) a2 += 2 * math.pi;
      n = ((a2 - a1) / da).toInt();
      da = (a2 - a1) / (n + 1);
      a1 += da;
      for (i = 0; i < n; i++) {
        addVertex(vc, x + math.cos(a1) * _width, y + math.sin(a1) * _width);
        a1 += da;
      }
    } else {
      if (a1 < a2) a2 -= 2 * math.pi;
      n = ((a1 - a2) / da).toInt();
      da = (a1 - a2) / (n + 1);
      a1 -= da;
      for (i = 0; i < n; i++) {
        addVertex(vc, x + math.cos(a1) * _width, y + math.sin(a1) * _width);
        a1 -= da;
      }
    }
    addVertex(vc, x + dx2, y + dy2);
  }

  void calcMiter(IVertexDest vc, VertexDistance v0, VertexDistance v1, VertexDistance v2, double dx1, double dy1,
      double dx2, double dy2, LineJoin lj, double mlimit, double dbevel) {
    double xi = v1.x;
    double yi = v1.y;
    double di = 1;
    double lim = _widthAbs * mlimit;
    bool miterLimitExceeded = true; // Assume the worst
    bool intersectionFailed = true; // Assume the worst

    var intersection = AggMath.calc_intersection(
        v0.x + dx1, v0.y - dy1, v1.x + dx1, v1.y - dy1, v1.x + dx2, v1.y - dy2, v2.x + dx2, v2.y - dy2);

    if (intersection != null) {
      xi = intersection.x;
      yi = intersection.y;
      // Calculation of the intersection succeeded
      di = AggMath.CalcDistance(v1.x, v1.y, xi, yi);
      if (di <= lim) {
        // Inside the miter limit
        addVertex(vc, xi, yi);
        miterLimitExceeded = false;
      }
      intersectionFailed = false;
    } else {
      // Calculation of the intersection failed, most probably
      // the three points lie one straight line.
      double x2 = v1.x + dx1;
      double y2 = v1.y - dy1;
      if ((AggMath.cross_product(v0.x, v0.y, v1.x, v1.y, x2, y2) < 0.0) ==
          (AggMath.cross_product(v1.x, v1.y, v2.x, v2.y, x2, y2) < 0.0)) {
        // This case means that the next segment continues
        // the previous one (straight line)
        addVertex(vc, v1.x + dx1, v1.y - dy1);
        miterLimitExceeded = false;
      }
    }

    if (miterLimitExceeded) {
      // Miter limit exceeded
      switch (lj) {
        case LineJoin.miterRevert:
          // For the compatibility with SVG, PDF, etc,
          // we use a simple bevel join instead of
          // "smart" bevel
          addVertex(vc, v1.x + dx1, v1.y - dy1);
          addVertex(vc, v1.x + dx2, v1.y - dy2);
          break;

        case LineJoin.miterRound:
          calcArc(vc, v1.x, v1.y, dx1, -dy1, dx2, -dy2);
          break;

        default:
          // If no miter-revert, calculate new dx1, dy1, dx2, dy2
          if (intersectionFailed) {
            mlimit *= _widthSign;
            addVertex(vc, v1.x + dx1 + dy1 * mlimit, v1.y - dy1 + dx1 * mlimit);
            addVertex(vc, v1.x + dx2 - dy2 * mlimit, v1.y - dy2 - dx2 * mlimit);
          } else {
            double x1 = v1.x + dx1;
            double y1 = v1.y - dy1;
            double x2 = v1.x + dx2;
            double y2 = v1.y - dy2;
            di = (lim - dbevel) / (di - dbevel);
            addVertex(vc, x1 + (xi - x1) * di, y1 + (yi - y1) * di);
            addVertex(vc, x2 + (xi - x2) * di, y2 + (yi - y2) * di);
          }
          break;
      }
    }
  }
}
