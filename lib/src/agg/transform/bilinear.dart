import 'package:agg/src/agg/agg_simul_eq.dart';
import 'package:agg/src/agg/transform/i_transform.dart';
import 'package:agg/src/shared/ref_param.dart';

/// Bilinear 2D transformation between quadrilaterals.
class Bilinear implements ITransform {
  final List<List<double>> _mtx =
      List.generate(4, (_) => List.filled(2, 0.0));
  bool _valid = false;

  Bilinear();

  factory Bilinear.quadToQuad(List<double> src, List<double> dst) {
    final Bilinear b = Bilinear();
    b.quadToQuad(src, dst);
    return b;
  }

  factory Bilinear.rectToQuad(
    double x1,
    double y1,
    double x2,
    double y2,
    List<double> quad,
  ) {
    final Bilinear b = Bilinear();
    b.rectToQuad(x1, y1, x2, y2, quad);
    return b;
  }

  factory Bilinear.quadToRect(
    List<double> quad,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final Bilinear b = Bilinear();
    b.quadToRect(quad, x1, y1, x2, y2);
    return b;
  }

  void quadToQuad(List<double> src, List<double> dst) {
    if (src.length < 8 || dst.length < 8) {
      throw ArgumentError('src/dst must contain 8 values (x1,y1,...,x4,y4)');
    }

    final List<List<double>> left =
        List.generate(4, (_) => List.filled(4, 0.0));
    final List<List<double>> right =
        List.generate(4, (_) => List.filled(2, 0.0));

    for (int i = 0; i < 4; i++) {
      final int ix = i * 2;
      final int iy = ix + 1;
      left[i][0] = 1.0;
      left[i][1] = src[ix] * src[iy];
      left[i][2] = src[ix];
      left[i][3] = src[iy];

      right[i][0] = dst[ix];
      right[i][1] = dst[iy];
    }
    _valid = SimulEq.solve(left, right, _mtx);
  }

  void rectToQuad(double x1, double y1, double x2, double y2, List<double> quad) {
    final List<double> src = List.filled(8, 0.0);
    src[0] = src[6] = x1;
    src[2] = src[4] = x2;
    src[1] = src[3] = y1;
    src[5] = src[7] = y2;
    quadToQuad(src, quad);
  }

  void quadToRect(List<double> quad, double x1, double y1, double x2, double y2) {
    final List<double> dst = List.filled(8, 0.0);
    dst[0] = dst[6] = x1;
    dst[2] = dst[4] = x2;
    dst[1] = dst[3] = y1;
    dst[5] = dst[7] = y2;
    quadToQuad(quad, dst);
  }

  bool get isValid => _valid;

  @override
  ({double x, double y}) transform(double x, double y) {
    final double xy = x * y;
    final double tx =
        _mtx[0][0] + _mtx[1][0] * xy + _mtx[2][0] * x + _mtx[3][0] * y;
    final double ty =
        _mtx[0][1] + _mtx[1][1] * xy + _mtx[2][1] * x + _mtx[3][1] * y;
    return (x: tx, y: ty);
  }

  void transformRef(RefParam<double> x, RefParam<double> y) {
    final result = transform(x.value, y.value);
    x.value = result.x;
    y.value = result.y;
  }

  BilinearIterator begin(double x, double y, double step) {
    return BilinearIterator.start(x, y, step, _mtx);
  }
}

class BilinearIterator {
  double _incX;
  double _incY;
  double x;
  double y;

  BilinearIterator._(this._incX, this._incY, this.x, this.y);

  factory BilinearIterator.start(
    double tx,
    double ty,
    double step,
    List<List<double>> m,
  ) {
    final double incX = (m[1][0] * step * ty + m[2][0] * step);
    final double incY = (m[1][1] * step * ty + m[2][1] * step);
    final double startX =
        m[0][0] + m[1][0] * tx * ty + m[2][0] * tx + m[3][0] * ty;
    final double startY =
        m[0][1] + m[1][1] * tx * ty + m[2][1] * tx + m[3][1] * ty;
    return BilinearIterator._(incX, incY, startX, startY);
  }

  void step() {
    x += _incX;
    y += _incY;
  }
}
