import 'dart:typed_data';
import 'dart:math' as math;

import 'package:agg/src/agg/agg_basics.dart';
import 'package:agg/src/agg/agg_dda_line.dart';
import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/line_aa_basics.dart';
import 'package:agg/src/agg/line_profile_aa.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/primitives/rectangle_int.dart';
import 'package:agg/src/agg/rasterizer_outline_aa.dart';
import 'package:agg/src/shared/ref_param.dart';

// Distance interpolators used by outline rasterizers.
class DistanceInterpolator0 {
  int _dx = 0;
  int _dy = 0;
  int _dist = 0;

  DistanceInterpolator0();

  DistanceInterpolator0.init(int x1, int y1, int x2, int y2, int x, int y) {
    _dx = LineAABasics.line_mr(x2) - LineAABasics.line_mr(x1);
    _dy = LineAABasics.line_mr(y2) - LineAABasics.line_mr(y1);
    _dist = (LineAABasics.line_mr(x + LineAABasics.line_subpixel_scale ~/ 2) -
                LineAABasics.line_mr(x2)) *
            _dy -
        (LineAABasics.line_mr(y + LineAABasics.line_subpixel_scale ~/ 2) -
                LineAABasics.line_mr(y2)) *
            _dx;
    _dx <<= LineAABasics.line_mr_subpixel_shift;
    _dy <<= LineAABasics.line_mr_subpixel_shift;
  }

  void incX() {
    _dist += _dy;
  }

  int dist() => _dist;
}

class DistanceInterpolator00 {
  int _dx1 = 0;
  int _dy1 = 0;
  int _dx2 = 0;
  int _dy2 = 0;
  int _dist1 = 0;
  int _dist2 = 0;

  DistanceInterpolator00();

  DistanceInterpolator00.init(
    int xc,
    int yc,
    int x1,
    int y1,
    int x2,
    int y2,
    int x,
    int y,
  ) {
    _dx1 = LineAABasics.line_mr(x1) - LineAABasics.line_mr(xc);
    _dy1 = LineAABasics.line_mr(y1) - LineAABasics.line_mr(yc);
    _dx2 = LineAABasics.line_mr(x2) - LineAABasics.line_mr(xc);
    _dy2 = LineAABasics.line_mr(y2) - LineAABasics.line_mr(yc);
    _dist1 = (LineAABasics.line_mr(x + LineAABasics.line_subpixel_scale ~/ 2) -
                LineAABasics.line_mr(x1)) *
            _dy1 -
        (LineAABasics.line_mr(y + LineAABasics.line_subpixel_scale ~/ 2) -
                LineAABasics.line_mr(y1)) *
            _dx1;
    _dist2 = (LineAABasics.line_mr(x + LineAABasics.line_subpixel_scale ~/ 2) -
                LineAABasics.line_mr(x2)) *
            _dy2 -
        (LineAABasics.line_mr(y + LineAABasics.line_subpixel_scale ~/ 2) -
                LineAABasics.line_mr(y2)) *
            _dx2;

    _dx1 <<= LineAABasics.line_mr_subpixel_shift;
    _dy1 <<= LineAABasics.line_mr_subpixel_shift;
    _dx2 <<= LineAABasics.line_mr_subpixel_shift;
    _dy2 <<= LineAABasics.line_mr_subpixel_shift;
  }

  void incX() {
    _dist1 += _dy1;
    _dist2 += _dy2;
  }

  int dist1() => _dist1;
  int dist2() => _dist2;
}

class DistanceInterpolator1 {
  int _dx = 0;
  int _dy = 0;
  int _dist = 0;

  DistanceInterpolator1();

  DistanceInterpolator1.init(int x1, int y1, int x2, int y2, int x, int y) {
    _dx = x2 - x1;
    _dy = y2 - y1;
    _dist = Agg_basics.iround(
      (x + LineAABasics.line_subpixel_scale / 2 - x2) * _dy -
          (y + LineAABasics.line_subpixel_scale / 2 - y2) * _dx,
    );
    _dx <<= LineAABasics.line_subpixel_shift;
    _dy <<= LineAABasics.line_subpixel_shift;
  }

  void incX() {
    _dist += _dy;
  }

  void decX() {
    _dist -= _dy;
  }

  void incY() {
    _dist -= _dx;
  }

  void decY() {
    _dist += _dx;
  }

  void incXWithDy(int dy) {
    _dist += _dy;
    if (dy > 0) _dist -= _dx;
    if (dy < 0) _dist += _dx;
  }

  void decXWithDy(int dy) {
    _dist -= _dy;
    if (dy > 0) _dist -= _dx;
    if (dy < 0) _dist += _dx;
  }

  void incYWithDx(int dx) {
    _dist -= _dx;
    if (dx > 0) _dist += _dy;
    if (dx < 0) _dist -= _dy;
  }

  void decYWithDx(int dx) {
    _dist += _dx;
    if (dx > 0) _dist += _dy;
    if (dx < 0) _dist -= _dy;
  }

  int dist() => _dist;
  int dx() => _dx;
  int dy() => _dy;
}

class DistanceInterpolator2 {
  int _dx = 0;
  int _dy = 0;
  int _dxStart = 0;
  int _dyStart = 0;
  int _dist = 0;
  int _distStart = 0;

  DistanceInterpolator2();

  DistanceInterpolator2.init(
    int x1,
    int y1,
    int x2,
    int y2,
    int sx,
    int sy,
    int x,
    int y,
  ) {
    _dx = x2 - x1;
    _dy = y2 - y1;
    _dxStart = LineAABasics.line_mr(sx) - LineAABasics.line_mr(x1);
    _dyStart = LineAABasics.line_mr(sy) - LineAABasics.line_mr(y1);

    _dist = Agg_basics.iround(
      (x + LineAABasics.line_subpixel_scale / 2 - x2) * _dy -
          (y + LineAABasics.line_subpixel_scale / 2 - y2) * _dx,
    );

    _distStart =
        (LineAABasics.line_mr(x + LineAABasics.line_subpixel_scale ~/ 2) -
                    LineAABasics.line_mr(sx)) *
                _dyStart -
            (LineAABasics.line_mr(y + LineAABasics.line_subpixel_scale ~/ 2) -
                    LineAABasics.line_mr(sy)) *
                _dxStart;

    _dx <<= LineAABasics.line_subpixel_shift;
    _dy <<= LineAABasics.line_subpixel_shift;
    _dxStart <<= LineAABasics.line_mr_subpixel_shift;
    _dyStart <<= LineAABasics.line_mr_subpixel_shift;
  }

  DistanceInterpolator2.initEnd(
    int x1,
    int y1,
    int x2,
    int y2,
    int ex,
    int ey,
    int x,
    int y,
  ) {
    _dx = x2 - x1;
    _dy = y2 - y1;
    _dxStart = LineAABasics.line_mr(ex) - LineAABasics.line_mr(x2);
    _dyStart = LineAABasics.line_mr(ey) - LineAABasics.line_mr(y2);

    _dist = Agg_basics.iround(
      (x + LineAABasics.line_subpixel_scale / 2 - x2) * _dy -
          (y + LineAABasics.line_subpixel_scale / 2 - y2) * _dx,
    );

    _distStart =
        (LineAABasics.line_mr(x + LineAABasics.line_subpixel_scale ~/ 2) -
                    LineAABasics.line_mr(ex)) *
                _dyStart -
            (LineAABasics.line_mr(y + LineAABasics.line_subpixel_scale ~/ 2) -
                    LineAABasics.line_mr(ey)) *
                _dxStart;

    _dx <<= LineAABasics.line_subpixel_shift;
    _dy <<= LineAABasics.line_subpixel_shift;
    _dxStart <<= LineAABasics.line_mr_subpixel_shift;
    _dyStart <<= LineAABasics.line_mr_subpixel_shift;
  }

  void incX() {
    _dist += _dy;
    _distStart += _dyStart;
  }

  void decX() {
    _dist -= _dy;
    _distStart -= _dyStart;
  }

  void incY() {
    _dist -= _dx;
    _distStart -= _dxStart;
  }

  void decY() {
    _dist += _dx;
    _distStart += _dxStart;
  }

  void incXWithDy(int dy) {
    _dist += _dy;
    _distStart += _dyStart;
    if (dy > 0) {
      _dist -= _dx;
      _distStart -= _dxStart;
    }
    if (dy < 0) {
      _dist += _dx;
      _distStart += _dxStart;
    }
  }

  void decXWithDy(int dy) {
    _dist -= _dy;
    _distStart -= _dyStart;
    if (dy > 0) {
      _dist -= _dx;
      _distStart -= _dxStart;
    }
    if (dy < 0) {
      _dist += _dx;
      _distStart += _dxStart;
    }
  }

  void incYWithDx(int dx) {
    _dist -= _dx;
    _distStart -= _dxStart;
    if (dx > 0) {
      _dist += _dy;
      _distStart += _dyStart;
    }
    if (dx < 0) {
      _dist -= _dy;
      _distStart -= _dyStart;
    }
  }

  void decYWithDx(int dx) {
    _dist += _dx;
    _distStart += _dxStart;
    if (dx > 0) {
      _dist += _dy;
      _distStart += _dyStart;
    }
    if (dx < 0) {
      _dist -= _dy;
      _distStart -= _dyStart;
    }
  }

  int dist() => _dist;
  int distStart() => _distStart;
  int distEnd() => _distStart;

  int dxStart() => _dxStart;
  int dyStart() => _dyStart;
}

class DistanceInterpolator3 {
  int _dx = 0;
  int _dy = 0;
  int _dxStart = 0;
  int _dyStart = 0;
  int _dxEnd = 0;
  int _dyEnd = 0;
  int _dist = 0;
  int _distStart = 0;
  int _distEnd = 0;

  DistanceInterpolator3();

  DistanceInterpolator3.init(
    int x1,
    int y1,
    int x2,
    int y2,
    int sx,
    int sy,
    int ex,
    int ey,
    int x,
    int y,
  ) {
    _dx = x2 - x1;
    _dy = y2 - y1;
    _dxStart = LineAABasics.line_mr(sx) - LineAABasics.line_mr(x1);
    _dyStart = LineAABasics.line_mr(sy) - LineAABasics.line_mr(y1);
    _dxEnd = LineAABasics.line_mr(ex) - LineAABasics.line_mr(x2);
    _dyEnd = LineAABasics.line_mr(ey) - LineAABasics.line_mr(y2);

    _dist = Agg_basics.iround(
      (x + LineAABasics.line_subpixel_scale / 2 - x2) * _dy -
          (y + LineAABasics.line_subpixel_scale / 2 - y2) * _dx,
    );

    _distStart =
        (LineAABasics.line_mr(x + LineAABasics.line_subpixel_scale ~/ 2) -
                    LineAABasics.line_mr(sx)) *
                _dyStart -
            (LineAABasics.line_mr(y + LineAABasics.line_subpixel_scale ~/ 2) -
                    LineAABasics.line_mr(sy)) *
                _dxStart;

    _distEnd =
        (LineAABasics.line_mr(x + LineAABasics.line_subpixel_scale ~/ 2) -
                    LineAABasics.line_mr(ex)) *
                _dyEnd -
            (LineAABasics.line_mr(y + LineAABasics.line_subpixel_scale ~/ 2) -
                    LineAABasics.line_mr(ey)) *
                _dxEnd;

    _dx <<= LineAABasics.line_subpixel_shift;
    _dy <<= LineAABasics.line_subpixel_shift;
    _dxStart <<= LineAABasics.line_mr_subpixel_shift;
    _dyStart <<= LineAABasics.line_mr_subpixel_shift;
    _dxEnd <<= LineAABasics.line_mr_subpixel_shift;
    _dyEnd <<= LineAABasics.line_mr_subpixel_shift;
  }

  void incX() {
    _dist += _dy;
    _distStart += _dyStart;
    _distEnd += _dyEnd;
  }

  void decX() {
    _dist -= _dy;
    _distStart -= _dyStart;
    _distEnd -= _dyEnd;
  }

  void incY() {
    _dist -= _dx;
    _distStart -= _dxStart;
    _distEnd -= _dxEnd;
  }

  void decY() {
    _dist += _dx;
    _distStart += _dxStart;
    _distEnd += _dxEnd;
  }

  void incXWithDy(int dy) {
    _dist += _dy;
    _distStart += _dyStart;
    _distEnd += _dyEnd;
    if (dy > 0) {
      _dist -= _dx;
      _distStart -= _dxStart;
      _distEnd -= _dxEnd;
    }
    if (dy < 0) {
      _dist += _dx;
      _distStart += _dxStart;
      _distEnd += _dxEnd;
    }
  }

  void decXWithDy(int dy) {
    _dist -= _dy;
    _distStart -= _dyStart;
    _distEnd -= _dyEnd;
    if (dy > 0) {
      _dist -= _dx;
      _distStart -= _dxStart;
      _distEnd -= _dxEnd;
    }
    if (dy < 0) {
      _dist += _dx;
      _distStart += _dxStart;
      _distEnd += _dxEnd;
    }
  }

  void incYWithDx(int dx) {
    _dist -= _dx;
    _distStart -= _dxStart;
    _distEnd -= _dxEnd;
    if (dx > 0) {
      _dist += _dy;
      _distStart += _dyStart;
      _distEnd += _dyEnd;
    }
    if (dx < 0) {
      _dist -= _dy;
      _distStart -= _dyStart;
      _distEnd -= _dyEnd;
    }
  }

  void decYWithDx(int dx) {
    _dist += _dx;
    _distStart += _dxStart;
    _distEnd += _dxEnd;
    if (dx > 0) {
      _dist += _dy;
      _distStart += _dyStart;
      _distEnd += _dyEnd;
    }
    if (dx < 0) {
      _dist -= _dy;
      _distStart -= _dyStart;
      _distEnd -= _dyEnd;
    }
  }

  int dist() => _dist;
  int distStart() => _distStart;
  int distEnd() => _distEnd;

  int dxStart() => _dxStart;
  int dyStart() => _dyStart;
  int dxEnd() => _dxEnd;
  int dyEnd() => _dyEnd;
}

class LineInterpolatorAABase {
  static const int maxHalfWidth = 64;

  late LineParameters _lp;
  late Dda2LineInterpolator _li;
  late OutlineRenderer _ren;
  int _len = 0;
  int _x = 0;
  int _y = 0;
  int _oldX = 0;
  int _oldY = 0;
  int _count = 0;
  int _width = 0;
  int _maxExtent = 0;
  int _step = 0;
  final List<int> _dist = List<int>.filled(maxHalfWidth + 1, 0);
  final Uint8List _covers = Uint8List(maxHalfWidth * 2 + 4);

  LineInterpolatorAABase(OutlineRenderer ren, LineParameters lp) {
    _lp = lp;
    _li = Dda2LineInterpolator.forward(
      0,
      lp.vertical
          ? (lp.dy << LineAABasics.line_subpixel_shift)
          : (lp.dx << LineAABasics.line_subpixel_shift),
      lp.len,
    );
    _ren = ren;
    _len = ((lp.vertical == (lp.inc > 0)) ? -lp.len : lp.len);
    _x = lp.x1 >> LineAABasics.line_subpixel_shift;
    _y = lp.y1 >> LineAABasics.line_subpixel_shift;
    _oldX = _x;
    _oldY = _y;
    _count = lp.vertical
        ? ((lp.y2 >> LineAABasics.line_subpixel_shift) - _y).abs()
        : ((lp.x2 >> LineAABasics.line_subpixel_shift) - _x).abs();
    _width = ren.subpixelWidth();
    _maxExtent = (_width + LineAABasics.line_subpixel_mask) >>
        LineAABasics.line_subpixel_shift;
    _step = 0;

    final Dda2LineInterpolator li = Dda2LineInterpolator.forward(
      0,
      lp.vertical
          ? (lp.dy << LineAABasics.line_subpixel_shift)
          : (lp.dx << LineAABasics.line_subpixel_shift),
      lp.len,
    );

    int i = 0;
    int stop = _width + LineAABasics.line_subpixel_scale * 2;
    for (; i < maxHalfWidth; ++i) {
      _dist[i] = li.y();
      if (_dist[i] >= stop) break;
      li.next();
    }
    if (i < _dist.length) _dist[i] = 0x7FFF0000;
  }

  int stepHorBase(dynamic di) {
    _li.next();
    _x += _lp.inc;
    _y = (_lp.y1 + _li.y()) >> LineAABasics.line_subpixel_shift;

    if (_lp.inc > 0) {
      di.incXWithDy(_y - _oldY);
    } else {
      di.decXWithDy(_y - _oldY);
    }

    _oldY = _y;

    return di.dist() ~/ _len;
  }

  int stepVerBase(dynamic di) {
    _li.next();
    _y += _lp.inc;
    _x = (_lp.x1 + _li.y()) >> LineAABasics.line_subpixel_shift;

    if (_lp.inc > 0) {
      di.incYWithDx(_x - _oldX);
    } else {
      di.decYWithDx(_x - _oldX);
    }

    _oldX = _x;

    return di.dist() ~/ _len;
  }

  bool get vertical => _lp.vertical;
  int get width => _width;
  int get count => _count;
}

class LineInterpolatorAA0 extends LineInterpolatorAABase {
  late DistanceInterpolator1 _di;

  LineInterpolatorAA0(OutlineRenderer ren, LineParameters lp) : super(ren, lp) {
    _di = DistanceInterpolator1.init(
      lp.x1,
      lp.y1,
      lp.x2,
      lp.y2,
      lp.x1 & ~LineAABasics.line_subpixel_mask,
      lp.y1 & ~LineAABasics.line_subpixel_mask,
    );
    _li.adjustForward();
  }

  bool stepHor() {
    int dist;
    int dy;
    int s1 = stepHorBase(_di);
    int offset0 = LineInterpolatorAABase.maxHalfWidth + 2;
    int offset1 = offset0;

    _covers[offset1++] = _ren.cover(s1);

    dy = 1;
    while ((dist = _dist[dy] - s1) <= _width) {
      _covers[offset1++] = _ren.cover(dist);
      ++dy;
    }

    dy = 1;
    while ((dist = _dist[dy] + s1) <= _width) {
      _covers[--offset0] = _ren.cover(dist);
      ++dy;
    }

    _ren.blendSolidVspan(_x, _y - dy + 1, offset1 - offset0, _covers, offset0);
    return ++_step < _count;
  }

  bool stepVer() {
    int dist;
    int dx;
    int s1 = stepVerBase(_di);
    int offset0 = LineInterpolatorAABase.maxHalfWidth + 2;
    int offset1 = offset0;

    _covers[offset1++] = _ren.cover(s1);

    dx = 1;
    while ((dist = _dist[dx] - s1) <= _width) {
      _covers[offset1++] = _ren.cover(dist);
      ++dx;
    }

    dx = 1;
    while ((dist = _dist[dx] + s1) <= _width) {
      _covers[--offset0] = _ren.cover(dist);
      ++dx;
    }

    _ren.blendSolidHspan(_x - dx + 1, _y, offset1 - offset0, _covers, offset0);
    return ++_step < _count;
  }
}

class LineInterpolatorAA1 extends LineInterpolatorAABase {
  late DistanceInterpolator2 _di;

  LineInterpolatorAA1(
    OutlineRenderer ren,
    LineParameters lp,
    int sx,
    int sy,
  ) : super(ren, lp) {
    _di = DistanceInterpolator2.init(
      lp.x1,
      lp.y1,
      lp.x2,
      lp.y2,
      sx,
      sy,
      lp.x1 & ~LineAABasics.line_subpixel_mask,
      lp.y1 & ~LineAABasics.line_subpixel_mask,
    );
    _li.adjustForward();
    _step -= _maxExtent;
  }

  bool stepHor() {
    int dist;
    int dy;
    int s1 = stepHorBase(_di);
    int distStart = _di.distStart();
    int offset0 = LineInterpolatorAABase.maxHalfWidth + 2;
    int offset1 = offset0;

    if (distStart <= 0) {
      _covers[offset1++] = _ren.cover(s1);
    } else {
      _covers[offset1++] = 0;
    }

    dy = 1;
    while ((dist = _dist[dy] - s1) <= _width) {
      if (distStart - _di.dyStart() * dy <= 0) {
        _covers[offset1++] = _ren.cover(dist);
      } else {
        _covers[offset1++] = 0;
      }
      ++dy;
    }

    dy = 1;
    while ((dist = _dist[dy] + s1) <= _width) {
      if (distStart + _di.dyStart() * dy <= 0) {
        _covers[--offset0] = _ren.cover(dist);
      } else {
        _covers[--offset0] = 0;
      }
      ++dy;
    }

    _ren.blendSolidVspan(_x, _y - dy + 1, offset1 - offset0, _covers, offset0);
    return ++_step < _count + _maxExtent;
  }

  bool stepVer() {
    int dist;
    int dx;
    int s1 = stepVerBase(_di);
    int distStart = _di.distStart();
    int offset0 = LineInterpolatorAABase.maxHalfWidth + 2;
    int offset1 = offset0;

    if (distStart <= 0) {
      _covers[offset1++] = _ren.cover(s1);
    } else {
      _covers[offset1++] = 0;
    }

    dx = 1;
    while ((dist = _dist[dx] - s1) <= _width) {
      if (distStart - _di.dxStart() * dx <= 0) {
        _covers[offset1++] = _ren.cover(dist);
      } else {
        _covers[offset1++] = 0;
      }
      ++dx;
    }

    dx = 1;
    while ((dist = _dist[dx] + s1) <= _width) {
      if (distStart + _di.dxStart() * dx <= 0) {
        _covers[--offset0] = _ren.cover(dist);
      } else {
        _covers[--offset0] = 0;
      }
      ++dx;
    }

    _ren.blendSolidHspan(_x - dx + 1, _y, offset1 - offset0, _covers, offset0);
    return ++_step < _count + _maxExtent;
  }
}

class LineInterpolatorAA2 extends LineInterpolatorAABase {
  late DistanceInterpolator2 _di;

  LineInterpolatorAA2(
    OutlineRenderer ren,
    LineParameters lp,
    int ex,
    int ey,
  ) : super(ren, lp) {
    _di = DistanceInterpolator2.initEnd(
      lp.x1,
      lp.y1,
      lp.x2,
      lp.y2,
      ex,
      ey,
      lp.x1 & ~LineAABasics.line_subpixel_mask,
      lp.y1 & ~LineAABasics.line_subpixel_mask,
    );
    _li.adjustForward();
    _step -= _maxExtent;
  }

  bool stepHor() {
    int dist;
    int dy;
    int s1 = stepHorBase(_di);
    int distEnd = _di.distEnd();
    int offset0 = LineInterpolatorAABase.maxHalfWidth + 2;
    int offset1 = offset0;

    if (distEnd > 0) {
      _covers[offset1++] = _ren.cover(s1);
    } else {
      _covers[offset1++] = 0;
    }

    dy = 1;
    while ((dist = _dist[dy] - s1) <= _width) {
      if (distEnd - _di.dyStart() * dy > 0) {
        _covers[offset1++] = _ren.cover(dist);
      } else {
        _covers[offset1++] = 0;
      }
      ++dy;
    }

    dy = 1;
    while ((dist = _dist[dy] + s1) <= _width) {
      if (distEnd + _di.dyStart() * dy > 0) {
        _covers[--offset0] = _ren.cover(dist);
      } else {
        _covers[--offset0] = 0;
      }
      ++dy;
    }

    _ren.blendSolidVspan(_x, _y - dy + 1, offset1 - offset0, _covers, offset0);
    return ++_step < _count + _maxExtent;
  }

  bool stepVer() {
    int dist;
    int dx;
    int s1 = stepVerBase(_di);
    int distEnd = _di.distEnd();
    int offset0 = LineInterpolatorAABase.maxHalfWidth + 2;
    int offset1 = offset0;

    if (distEnd > 0) {
      _covers[offset1++] = _ren.cover(s1);
    } else {
      _covers[offset1++] = 0;
    }

    dx = 1;
    while ((dist = _dist[dx] - s1) <= _width) {
      if (distEnd - _di.dxStart() * dx > 0) {
        _covers[offset1++] = _ren.cover(dist);
      } else {
        _covers[offset1++] = 0;
      }
      ++dx;
    }

    dx = 1;
    while ((dist = _dist[dx] + s1) <= _width) {
      if (distEnd + _di.dxStart() * dx > 0) {
        _covers[--offset0] = _ren.cover(dist);
      } else {
        _covers[--offset0] = 0;
      }
      ++dx;
    }

    _ren.blendSolidHspan(_x - dx + 1, _y, offset1 - offset0, _covers, offset0);
    return ++_step < _count + _maxExtent;
  }
}

class LineInterpolatorAA3 extends LineInterpolatorAABase {
  late DistanceInterpolator3 _di;

  LineInterpolatorAA3(
    OutlineRenderer ren,
    LineParameters lp,
    int sx,
    int sy,
    int ex,
    int ey,
  ) : super(ren, lp) {
    _di = DistanceInterpolator3.init(
      lp.x1,
      lp.y1,
      lp.x2,
      lp.y2,
      sx,
      sy,
      ex,
      ey,
      lp.x1 & ~LineAABasics.line_subpixel_mask,
      lp.y1 & ~LineAABasics.line_subpixel_mask,
    );
    _li.adjustForward();
    _step -= _maxExtent;
  }

  bool stepHor() {
    int dist;
    int dy;
    int s1 = stepHorBase(_di);
    int distStart = _di.distStart();
    int distEnd = _di.distEnd();
    int offset0 = LineInterpolatorAABase.maxHalfWidth + 2;
    int offset1 = offset0;

    if (distEnd > 0 && distStart <= 0) {
      _covers[offset1++] = _ren.cover(s1);
    } else {
      _covers[offset1++] = 0;
    }

    dy = 1;
    while ((dist = _dist[dy] - s1) <= _width) {
      if (distEnd - _di.dyEnd() * dy > 0 &&
          distStart - _di.dyStart() * dy <= 0) {
        _covers[offset1++] = _ren.cover(dist);
      } else {
        _covers[offset1++] = 0;
      }
      ++dy;
    }

    dy = 1;
    while ((dist = _dist[dy] + s1) <= _width) {
      if (distEnd + _di.dyEnd() * dy > 0 &&
          distStart + _di.dyStart() * dy <= 0) {
        _covers[--offset0] = _ren.cover(dist);
      } else {
        _covers[--offset0] = 0;
      }
      ++dy;
    }

    _ren.blendSolidVspan(_x, _y - dy + 1, offset1 - offset0, _covers, offset0);
    return ++_step < _count + _maxExtent;
  }

  bool stepVer() {
    int dist;
    int dx;
    int s1 = stepVerBase(_di);
    int distStart = _di.distStart();
    int distEnd = _di.distEnd();
    int offset0 = LineInterpolatorAABase.maxHalfWidth + 2;
    int offset1 = offset0;

    if (distEnd > 0 && distStart <= 0) {
      _covers[offset1++] = _ren.cover(s1);
    } else {
      _covers[offset1++] = 0;
    }

    dx = 1;
    while ((dist = _dist[dx] - s1) <= _width) {
      if (distEnd - _di.dxEnd() * dx > 0 &&
          distStart - _di.dxStart() * dx <= 0) {
        _covers[offset1++] = _ren.cover(dist);
      } else {
        _covers[offset1++] = 0;
      }
      ++dx;
    }

    dx = 1;
    while ((dist = _dist[dx] + s1) <= _width) {
      if (distEnd + _di.dxEnd() * dx > 0 &&
          distStart + _di.dxStart() * dx <= 0) {
        _covers[--offset0] = _ren.cover(dist);
      } else {
        _covers[--offset0] = 0;
      }
      ++dx;
    }

    _ren.blendSolidHspan(_x - dx + 1, _y, offset1 - offset0, _covers, offset0);
    return ++_step < _count + _maxExtent;
  }
}

class EllipseBresenhamInterpolator {
  int _rx2 = 0;
  int _ry2 = 0;
  int _twoRx2 = 0;
  int _twoRy2 = 0;
  int _dx = 0;
  int _dy = 0;
  int _incX = 0;
  int _incY = 0;
  int _curF = 0;

  EllipseBresenhamInterpolator(int rx, int ry) {
    _rx2 = rx * rx;
    _ry2 = ry * ry;
    _twoRx2 = _rx2 << 1;
    _twoRy2 = _ry2 << 1;
    _dx = 0;
    _dy = 0;
    _incX = 0;
    _incY = -ry * _twoRx2;
    _curF = 0;
  }

  int get dx => _dx;
  int get dy => _dy;

  void next() {
    int mx, my, mxy, minM;
    int fx, fy, fxy;

    mx = fx = _curF + _incX + _ry2;
    if (mx < 0) mx = -mx;

    my = fy = _curF + _incY + _rx2;
    if (my < 0) my = -my;

    mxy = fxy = _curF + _incX + _ry2 + _incY + _rx2;
    if (mxy < 0) mxy = -mxy;

    minM = mx;
    bool flag = true;

    if (minM > my) {
      minM = my;
      flag = false;
    }

    _dx = _dy = 0;

    if (minM > mxy) {
      _incX += _twoRy2;
      _incY += _twoRx2;
      _curF = fxy;
      _dx = 1;
      _dy = 1;
      return;
    }

    if (flag) {
      _incX += _twoRy2;
      _curF = fx;
      _dx = 1;
      return;
    }

    _incY += _twoRx2;
    _curF = fy;
    _dy = 1;
  }
}

class OutlineRenderer implements LineRenderer {
  final IImageByte _image;
  final LineProfileAA _profile;
  Color _color;
  RectangleInt? _clipBox;

  OutlineRenderer(this._image, this._profile, [Color? color])
      : _color = color ?? Color(0, 0, 0, 255);

  set color(Color c) => _color = c;
  Color get color => _color;

  set clipBox(RectangleInt? rect) => _clipBox = rect;
  RectangleInt? get clipBox => _clipBox;

  int subpixelWidth() => _profile.subpixelWidth();

  int cover(int d) => _profile.value(d);

  void blendSolidHspan(int x, int y, int len, Uint8List covers, int coversIdx) {
    if (y < 0 || y >= _image.height) return;
    if (_clipBox != null) {
      if (y < _clipBox!.bottom || y > _clipBox!.top) {
        return;
      }
      final int left = _clipBox!.left;
      final int right = _clipBox!.right;
      if (x < left) {
        final int delta = left - x;
        len -= delta;
        coversIdx += delta;
        x = left;
      }
      final int overRight = (x + len) - (right + 1);
      if (overRight > 0) {
        len -= overRight;
      }
    }
    if (len <= 0) {
      return;
    }
    if (x < 0) {
      len += x;
      if (len <= 0) return;
      coversIdx -= x;
      x = 0;
    }
    if (x + len > _image.width) {
      len = _image.width - x;
      if (len <= 0) return;
    }
    _image.blend_solid_hspan(x, y, len, _color, covers, coversIdx);
  }

  void blendSolidVspan(int x, int y, int len, Uint8List covers, int coversIdx) {
    if (x < 0 || x >= _image.width) return;
    if (_clipBox != null) {
      if (x < _clipBox!.left || x > _clipBox!.right) {
        return;
      }
      if (y < _clipBox!.bottom) {
        final int delta = _clipBox!.bottom - y;
        len -= delta;
        coversIdx += delta;
        y = _clipBox!.bottom;
      }
      final int overTop = (y + len) - (_clipBox!.top + 1);
      if (overTop > 0) {
        len -= overTop;
      }
    }
    if (len <= 0) {
      return;
    }
    if (y < 0) {
      len += y;
      if (len <= 0) return;
      coversIdx -= y;
      y = 0;
    }
    if (y + len > _image.height) {
      len = _image.height - y;
      if (len <= 0) return;
    }
    _image.blend_solid_vspan(x, y, len, _color, covers, coversIdx);
  }

  @override
  void line0(LineParameters lp) {
    if (lp.len > LineAABasics.line_max_length) {
      LineParameters lp1 = LineParameters(0, 0, 0, 0, 0);
      LineParameters lp2 = LineParameters(0, 0, 0, 0, 0);
      lp.divide(RefParam(lp1), RefParam(lp2));
      line0(lp1);
      line0(lp2);
      return;
    }

    final li = LineInterpolatorAA0(this, lp);
    if (li.vertical) {
      while (li.stepVer()) {}
    } else {
      while (li.stepHor()) {}
    }
  }

  @override
  void line1(LineParameters lp, int sx, int sy) {
    if (lp.len > LineAABasics.line_max_length) {
      LineParameters lp1 = LineParameters(0, 0, 0, 0, 0);
      LineParameters lp2 = LineParameters(0, 0, 0, 0, 0);
      lp.divide(RefParam(lp1), RefParam(lp2));
      line1(lp1, (sx + lp.x1) >> 1, (sy + lp.y1) >> 1);
      line1(lp2, lp1.x2 + (lp1.y2 - lp1.y1), lp1.y2 - (lp1.x2 - lp1.x1));
      return;
    }

    final li = LineInterpolatorAA1(this, lp, sx, sy);
    if (li.vertical) {
      while (li.stepVer()) {}
    } else {
      while (li.stepHor()) {}
    }
  }

  @override
  void line2(LineParameters lp, int ex, int ey) {
    if (lp.len > LineAABasics.line_max_length) {
      LineParameters lp1 = LineParameters(0, 0, 0, 0, 0);
      LineParameters lp2 = LineParameters(0, 0, 0, 0, 0);
      lp.divide(RefParam(lp1), RefParam(lp2));
      line2(lp1, lp1.x2 + (lp1.y2 - lp1.y1), lp1.y2 - (lp1.x2 - lp1.x1));
      line2(lp2, (ex + lp.x2) >> 1, (ey + lp.y2) >> 1);
      return;
    }

    final li = LineInterpolatorAA2(this, lp, ex, ey);
    if (li.vertical) {
      while (li.stepVer()) {}
    } else {
      while (li.stepHor()) {}
    }
  }

  @override
  void line3(LineParameters lp, int sx, int sy, int ex, int ey) {
    if (lp.len > LineAABasics.line_max_length) {
      LineParameters lp1 = LineParameters(0, 0, 0, 0, 0);
      LineParameters lp2 = LineParameters(0, 0, 0, 0, 0);
      lp.divide(RefParam(lp1), RefParam(lp2));
      final int mx = lp1.x2 + (lp1.y2 - lp1.y1);
      final int my = lp1.y2 - (lp1.x2 - lp1.x1);
      line3(lp1, (sx + lp.x1) >> 1, (sy + lp.y1) >> 1, mx, my);
      line3(lp2, mx, my, (ex + lp.x2) >> 1, (ey + lp.y2) >> 1);
      return;
    }

    final li = LineInterpolatorAA3(this, lp, sx, sy, ex, ey);
    if (li.vertical) {
      while (li.stepVer()) {}
    } else {
      while (li.stepHor()) {}
    }
  }

  void _pieHline(int xc, int yc, int xp1, int yp1, int xp2, int yp2, int xh1,
      int yh1, int xh2) {
    // if (_clipBox != null && ClipLiangBarsky.clipping_flags(xc, yc, _clipBox!) != 0) return;

    final Uint8List covers =
        Uint8List(LineInterpolatorAABase.maxHalfWidth * 2 + 4);
    int index0 = 0;
    int index1 = 0;
    int x = xh1 << LineAABasics.line_subpixel_shift;
    int y = yh1 << LineAABasics.line_subpixel_shift;
    int w = subpixelWidth();

    final di = DistanceInterpolator00.init(xc, yc, xp1, yp1, xp2, yp2, x, y);
    x += LineAABasics.line_subpixel_scale ~/ 2;
    y += LineAABasics.line_subpixel_scale ~/ 2;

    int xh0 = xh1;
    int dx = x - xc;
    int dy = y - yc;
    do {
      int d = math.sqrt(dx * dx + dy * dy).toInt();
      covers[index1] = 0;
      if (di.dist1() <= 0 && di.dist2() > 0 && d <= w) {
        covers[index1] = cover(d);
      }
      ++index1;
      dx += LineAABasics.line_subpixel_scale;
      di.incX();
    } while (++xh1 <= xh2);

    blendSolidHspan(xh0, yh1, index1 - index0, covers, index0);
  }

  @override
  void pie(int xc, int yc, int x1, int y1, int x2, int y2) {
    int r = ((subpixelWidth() + LineAABasics.line_subpixel_mask) >>
        LineAABasics.line_subpixel_shift);
    if (r < 1) r = 1;

    final ei = EllipseBresenhamInterpolator(r, r);
    int dx = 0;
    int dy = -r;
    int dy0 = dy;
    int dx0 = dx;
    int x = xc >> LineAABasics.line_subpixel_shift;
    int y = yc >> LineAABasics.line_subpixel_shift;

    do {
      dx += ei.dx;
      dy += ei.dy;

      if (dy != dy0) {
        _pieHline(xc, yc, x1, y1, x2, y2, x - dx0, y + dy0, x + dx0);
        _pieHline(xc, yc, x1, y1, x2, y2, x - dx0, y - dy0, x + dx0);
      }
      dx0 = dx;
      dy0 = dy;
      ei.next();
    } while (dy < 0);
    _pieHline(xc, yc, x1, y1, x2, y2, x - dx0, y + dy0, x + dx0);
  }
}
