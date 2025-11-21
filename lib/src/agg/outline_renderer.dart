import 'package:agg/src/agg/agg_basics.dart';
import 'package:agg/src/agg/line_aa_basics.dart';

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
  int _dist = 0;

  DistanceInterpolator2();

  DistanceInterpolator2.init(LineParameters lp, int x, int y) {
    _dx = lp.dy;
    _dy = lp.dx;
    _dist = Agg_basics.iround(
      (x + LineAABasics.line_subpixel_scale / 2 - lp.x2) * _dx +
          (y + LineAABasics.line_subpixel_scale / 2 - lp.y2) * _dy,
    );
    _dx = lp.dy << LineAABasics.line_subpixel_shift;
    _dy = lp.dx << LineAABasics.line_subpixel_shift;
  }

  void incX() {
    _dist += _dx;
  }

  void decX() {
    _dist -= _dx;
  }

  void incY() {
    _dist += _dy;
  }

  void decY() {
    _dist -= _dy;
  }

  int dist() => _dist;
}
