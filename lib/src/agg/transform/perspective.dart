import 'dart:math' as math;

import 'package:agg/src/agg/agg_basics.dart';
import 'package:agg/src/shared/ref_param.dart';
import 'package:agg/src/agg/transform/affine.dart';
import 'package:agg/src/agg/transform/i_transform.dart';

/// Perspective 2D transformation (3x3 matrix with projective terms).
class Perspective implements ITransform {
  static const double affineEpsilon = 1e-14;

  double sx;
  double shy;
  double w0;
  double shx;
  double sy;
  double w1;
  double tx;
  double ty;
  double w2;

  /// Identity by default.
  Perspective({
    this.sx = 1.0,
    this.shy = 0.0,
    this.w0 = 0.0,
    this.shx = 0.0,
    this.sy = 1.0,
    this.w1 = 0.0,
    this.tx = 0.0,
    this.ty = 0.0,
    this.w2 = 1.0,
  });

  Perspective.fromValues(
    double v0,
    double v1,
    double v2,
    double v3,
    double v4,
    double v5,
    double v6,
    double v7,
    double v8,
  )   : sx = v0,
        shy = v1,
        w0 = v2,
        shx = v3,
        sy = v4,
        w1 = v5,
        tx = v6,
        ty = v7,
        w2 = v8;

  Perspective.fromList(List<double> m)
      : assert(m.length >= 9),
        sx = m[0],
        shy = m[1],
        w0 = m[2],
        shx = m[3],
        sy = m[4],
        w1 = m[5],
        tx = m[6],
        ty = m[7],
        w2 = m[8];

  factory Perspective.fromAffine(Affine a) {
    return Perspective(
      sx: a.sx,
      shy: a.shy,
      w0: 0.0,
      shx: a.shx,
      sy: a.sy,
      w1: 0.0,
      tx: a.tx,
      ty: a.ty,
      w2: 1.0,
    );
  }

  Perspective.copy(Perspective a)
      : sx = a.sx,
        shy = a.shy,
        w0 = a.w0,
        shx = a.shx,
        sy = a.sy,
        w1 = a.w1,
        tx = a.tx,
        ty = a.ty,
        w2 = a.w2;

  factory Perspective.rectToQuad(
    double x1,
    double y1,
    double x2,
    double y2,
    List<double> quad,
  ) {
    final Perspective p = Perspective();
    p.rectToQuad(x1, y1, x2, y2, quad);
    return p;
  }

  factory Perspective.quadToRect(
    List<double> quad,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final Perspective p = Perspective();
    p.quadToRect(quad, x1, y1, x2, y2);
    return p;
  }

  factory Perspective.quadToQuad(List<double> src, List<double> dst) {
    final Perspective p = Perspective();
    p.quadToQuad(src, dst);
    return p;
  }

  Perspective setFrom(Perspective other) {
    sx = other.sx;
    shy = other.shy;
    w0 = other.w0;
    shx = other.shx;
    sy = other.sy;
    w1 = other.w1;
    tx = other.tx;
    ty = other.ty;
    w2 = other.w2;
    return this;
  }

  /// Map one quadrilateral to another.
  bool quadToQuad(List<double> qs, List<double> qd) {
    if (!quadToSquare(qs)) return false;
    final Perspective p = Perspective();
    if (!p.squareToQuad(qd)) return false;
    multiply(p);
    return true;
  }

  /// Rectangle -> quadrilateral.
  bool rectToQuad(double x1, double y1, double x2, double y2, List<double> q) {
    final List<double> r = List<double>.filled(8, 0.0);
    r[0] = r[6] = x1;
    r[2] = r[4] = x2;
    r[1] = r[3] = y1;
    r[5] = r[7] = y2;
    return quadToQuad(r, q);
  }

  /// Quadrilateral -> rectangle.
  bool quadToRect(
    List<double> q,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    final List<double> r = List<double>.filled(8, 0.0);
    r[0] = r[6] = x1;
    r[2] = r[4] = x2;
    r[1] = r[3] = y1;
    r[5] = r[7] = y2;
    return quadToQuad(q, r);
  }

  /// Map square (0,0)-(1,1) to quadrilateral.
  bool squareToQuad(List<double> q) {
    final double dx = q[0] - q[2] + q[4] - q[6];
    final double dy = q[1] - q[3] + q[5] - q[7];
    if (dx == 0.0 && dy == 0.0) {
      // Affine (parallelogram) case.
      sx = q[2] - q[0];
      shy = q[3] - q[1];
      w0 = 0.0;
      shx = q[4] - q[2];
      sy = q[5] - q[3];
      w1 = 0.0;
      tx = q[0];
      ty = q[1];
      w2 = 1.0;
      return true;
    }

    final double dx1 = q[2] - q[4];
    final double dy1 = q[3] - q[5];
    final double dx2 = q[6] - q[4];
    final double dy2 = q[7] - q[5];
    final double den = dx1 * dy2 - dx2 * dy1;
    if (den == 0.0) {
      // Singular case.
      sx = shy = w0 = shx = sy = w1 = tx = ty = w2 = 0.0;
      return false;
    }

    final double u = (dx * dy2 - dy * dx2) / den;
    final double v = (dy * dx1 - dx * dy1) / den;
    sx = q[2] - q[0] + u * q[2];
    shy = q[3] - q[1] + u * q[3];
    w0 = u;
    shx = q[6] - q[0] + v * q[6];
    sy = q[7] - q[1] + v * q[7];
    w1 = v;
    tx = q[0];
    ty = q[1];
    w2 = 1.0;
    return true;
  }

  bool quadToSquare(List<double> q) {
    if (!squareToQuad(q)) return false;
    return invert();
  }

  Perspective reset() {
    sx = 1.0;
    shy = 0.0;
    w0 = 0.0;
    shx = 0.0;
    sy = 1.0;
    w1 = 0.0;
    tx = 0.0;
    ty = 0.0;
    w2 = 1.0;
    return this;
  }

  /// Invert matrix. Returns false if the matrix is singular.
  bool invert() {
    final double d0 = sy * w2 - w1 * ty;
    final double d1 = w0 * ty - shy * w2;
    final double d2 = shy * w1 - w0 * sy;
    double d = sx * d0 + shx * d1 + tx * d2;
    if (d == 0.0) {
      sx = shy = w0 = shx = sy = w1 = tx = ty = w2 = 0.0;
      return false;
    }

    d = 1.0 / d;
    final Perspective a = Perspective.copy(this);
    sx = d * d0;
    shy = d * d1;
    w0 = d * d2;
    shx = d * (a.w1 * a.tx - a.shx * a.w2);
    sy = d * (a.sx * a.w2 - a.w0 * a.tx);
    w1 = d * (a.w0 * a.shx - a.sx * a.w1);
    tx = d * (a.shx * a.ty - a.sy * a.tx);
    ty = d * (a.shy * a.tx - a.sx * a.ty);
    w2 = d * (a.sx * a.sy - a.shy * a.shx);
    return true;
  }

  Perspective translate(double x, double y) {
    tx += x;
    ty += y;
    return this;
  }

  Perspective rotate(double angle) {
    multiplyAffine(Affine.rotation(angle));
    return this;
  }

  Perspective scale(double s) {
    multiplyAffine(Affine.scaling(s));
    return this;
  }

  Perspective scaleXY(double x, double y) {
    multiplyAffine(Affine.scaling(x, y));
    return this;
  }

  Perspective multiply(Perspective a) {
    final Perspective b = Perspective.copy(this);
    sx = a.sx * b.sx + a.shx * b.shy + a.tx * b.w0;
    shx = a.sx * b.shx + a.shx * b.sy + a.tx * b.w1;
    tx = a.sx * b.tx + a.shx * b.ty + a.tx * b.w2;
    shy = a.shy * b.sx + a.sy * b.shy + a.ty * b.w0;
    sy = a.shy * b.shx + a.sy * b.sy + a.ty * b.w1;
    ty = a.shy * b.tx + a.sy * b.ty + a.ty * b.w2;
    w0 = a.w0 * b.sx + a.w1 * b.shy + a.w2 * b.w0;
    w1 = a.w0 * b.shx + a.w1 * b.sy + a.w2 * b.w1;
    w2 = a.w0 * b.tx + a.w1 * b.ty + a.w2 * b.w2;
    return this;
  }

  Perspective multiplyAffine(Affine a) {
    final Perspective b = Perspective.copy(this);
    sx = a.sx * b.sx + a.shx * b.shy + a.tx * b.w0;
    shx = a.sx * b.shx + a.shx * b.sy + a.tx * b.w1;
    tx = a.sx * b.tx + a.shx * b.ty + a.tx * b.w2;
    shy = a.shy * b.sx + a.sy * b.shy + a.ty * b.w0;
    sy = a.shy * b.shx + a.sy * b.sy + a.ty * b.w1;
    ty = a.shy * b.tx + a.sy * b.ty + a.ty * b.w2;
    return this;
  }

  Perspective premultiply(Perspective b) {
    final Perspective a = Perspective.copy(this);
    sx = a.sx * b.sx + a.shx * b.shy + a.tx * b.w0;
    shx = a.sx * b.shx + a.shx * b.sy + a.tx * b.w1;
    tx = a.sx * b.tx + a.shx * b.ty + a.tx * b.w2;
    shy = a.shy * b.sx + a.sy * b.shy + a.ty * b.w0;
    sy = a.shy * b.shx + a.sy * b.sy + a.ty * b.w1;
    ty = a.shy * b.tx + a.sy * b.ty + a.ty * b.w2;
    w0 = a.w0 * b.sx + a.w1 * b.shy + a.w2 * b.w0;
    w1 = a.w0 * b.shx + a.w1 * b.sy + a.w2 * b.w1;
    w2 = a.w0 * b.tx + a.w1 * b.ty + a.w2 * b.w2;
    return this;
  }

  Perspective premultiplyAffine(Affine b) {
    final Perspective a = Perspective.copy(this);
    sx = a.sx * b.sx + a.shx * b.shy;
    shx = a.sx * b.shx + a.shx * b.sy;
    tx = a.sx * b.tx + a.shx * b.ty + a.tx;
    shy = a.shy * b.sx + a.sy * b.shy;
    sy = a.shy * b.shx + a.sy * b.sy;
    ty = a.shy * b.tx + a.sy * b.ty + a.ty;
    w0 = a.w0 * b.sx + a.w1 * b.shy;
    w1 = a.w0 * b.shx + a.w1 * b.sy;
    w2 = a.w0 * b.tx + a.w1 * b.ty + a.w2;
    return this;
  }

  Perspective multiplyInv(Perspective m) {
    final Perspective t = Perspective.copy(m);
    t.invert();
    return multiply(t);
  }

  Perspective multiplyInvAffine(Affine m) {
    final Affine t = m.clone()..invert();
    return multiplyAffine(t);
  }

  Perspective premultiplyInv(Perspective m) {
    final Perspective t = Perspective.copy(m)..invert();
    setFrom(t.multiply(this));
    return this;
  }

  Perspective premultiplyInvAffine(Affine m) {
    final Perspective t = Perspective.fromAffine(m)..invert();
    setFrom(t.multiply(this));
    return this;
  }

  void storeTo(List<double> m) {
    if (m.length < 9) {
      throw ArgumentError.value(m.length, 'm', 'Expected length >= 9');
    }
    m[0] = sx;
    m[1] = shy;
    m[2] = w0;
    m[3] = shx;
    m[4] = sy;
    m[5] = w1;
    m[6] = tx;
    m[7] = ty;
    m[8] = w2;
  }

  Perspective loadFrom(List<double> m) {
    if (m.length < 9) {
      throw ArgumentError.value(m.length, 'm', 'Expected length >= 9');
    }
    sx = m[0];
    shy = m[1];
    w0 = m[2];
    shx = m[3];
    sy = m[4];
    w1 = m[5];
    tx = m[6];
    ty = m[7];
    w2 = m[8];
    return this;
  }

  @override
  void transform(List<double> xy) {
    double px = xy[0];
    double py = xy[1];
    final double denom = px * w0 + py * w1 + w2;
    final double invDenom = 1.0 / denom;
    xy[0] = (px * sx + py * shx + tx) * invDenom;
    xy[1] = (px * shy + py * sy + ty) * invDenom;
  }

  ({double x, double y}) transformPoint(double px, double py) {
    final double denom = px * w0 + py * w1 + w2;
    final double invDenom = 1.0 / denom;
    return (
      x: (px * sx + py * shx + tx) * invDenom,
      y: (px * shy + py * sy + ty) * invDenom,
    );
  }

  ({double x, double y}) transformAffine(double px, double py) {
    return (
      x: px * sx + py * shx + tx,
      y: px * shy + py * sy + ty,
    );
  }

  ({double x, double y}) transform2x2(double px, double py) {
    return (
      x: px * sx + py * shx,
      y: px * shy + py * sy,
    );
  }

  ({double x, double y}) inverseTransform(double px, double py) {
    final Perspective t = Perspective.copy(this);
    if (t.invert()) {
      return t.transformPoint(px, py);
    }
    return (x: 0.0, y: 0.0);
  }

  /// Mutable transform helper for existing ref-style call sites.
  void transformRef(RefParam<double> x, RefParam<double> y) {
    final result = transformPoint(x.value, y.value);
    x.value = result.x;
    y.value = result.y;
  }

  double determinant() {
    return sx * (sy * w2 - ty * w1) +
        shx * (ty * w0 - shy * w2) +
        tx * (shy * w1 - sy * w0);
  }

  double determinantReciprocal() {
    return 1.0 / determinant();
  }

  bool isValid([double epsilon = affineEpsilon]) {
    return sx.abs() > epsilon && sy.abs() > epsilon && w2.abs() > epsilon;
  }

  bool isIdentity([double epsilon = affineEpsilon]) {
    return Agg_basics.is_equal_eps(sx, 1.0, epsilon) &&
        Agg_basics.is_equal_eps(shy, 0.0, epsilon) &&
        Agg_basics.is_equal_eps(w0, 0.0, epsilon) &&
        Agg_basics.is_equal_eps(shx, 0.0, epsilon) &&
        Agg_basics.is_equal_eps(sy, 1.0, epsilon) &&
        Agg_basics.is_equal_eps(w1, 0.0, epsilon) &&
        Agg_basics.is_equal_eps(tx, 0.0, epsilon) &&
        Agg_basics.is_equal_eps(ty, 0.0, epsilon) &&
        Agg_basics.is_equal_eps(w2, 1.0, epsilon);
  }

  bool isEqual(Perspective m, [double epsilon = affineEpsilon]) {
    return Agg_basics.is_equal_eps(sx, m.sx, epsilon) &&
        Agg_basics.is_equal_eps(shy, m.shy, epsilon) &&
        Agg_basics.is_equal_eps(w0, m.w0, epsilon) &&
        Agg_basics.is_equal_eps(shx, m.shx, epsilon) &&
        Agg_basics.is_equal_eps(sy, m.sy, epsilon) &&
        Agg_basics.is_equal_eps(w1, m.w1, epsilon) &&
        Agg_basics.is_equal_eps(tx, m.tx, epsilon) &&
        Agg_basics.is_equal_eps(ty, m.ty, epsilon) &&
        Agg_basics.is_equal_eps(w2, m.w2, epsilon);
  }

  double calcScale() {
    final double x = 0.707106781 * sx + 0.707106781 * shx;
    final double y = 0.707106781 * shy + 0.707106781 * sy;
    return math.sqrt(x * x + y * y);
  }

  double rotation() {
    double x1 = 0.0;
    double y1 = 0.0;
    double x2 = 1.0;
    double y2 = 0.0;
    final p1 = transformPoint(x1, y1);
    final p2 = transformPoint(x2, y2);
    x1 = p1.x;
    y1 = p1.y;
    x2 = p2.x;
    y2 = p2.y;
    return math.atan2(y2 - y1, x2 - x1);
  }

  ({double x, double y}) translation() => (x: tx, y: ty);

  ({double x, double y}) scaling() {
    final Perspective t =
        Perspective.copy(this)..multiplyAffine(Affine.rotation(-rotation()));
    double x1 = 0.0;
    double y1 = 0.0;
    double x2 = 1.0;
    double y2 = 1.0;
    final p1 = t.transformPoint(x1, y1);
    final p2 = t.transformPoint(x2, y2);
    x1 = p1.x;
    y1 = p1.y;
    x2 = p2.x;
    y2 = p2.y;
    return (x: x2 - x1, y: y2 - y1);
  }

  ({double x, double y}) scalingAbs() {
    return (
      x: math.sqrt(sx * sx + shx * shx),
      y: math.sqrt(shy * shy + sy * sy),
    );
  }

  PerspectiveIteratorX begin(double x, double y, double step) {
    return PerspectiveIteratorX.start(x, y, step, this);
  }

  Perspective clone() => Perspective.copy(this);

  @override
  String toString() {
    return 'Perspective($sx, $shy, $w0, $shx, $sy, $w1, $tx, $ty, $w2)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Perspective && isEqual(other);
  }

  @override
  int get hashCode => Object.hash(
        sx,
        shy,
        w0,
        shx,
        sy,
        w1,
        tx,
        ty,
        w2,
      );

  Perspective operator *(Perspective other) =>
      Perspective.copy(this)..multiply(other);

  Perspective operator /(Perspective other) =>
      Perspective.copy(this)..multiplyInv(other);

  Perspective operator ~() => Perspective.copy(this)..invert();
}

/// Iterator helper for perspective interpolation (used by span generators).
class PerspectiveIteratorX {
  double _den;
  double _denStep;
  double _nomX;
  double _nomXStep;
  double _nomY;
  double _nomYStep;

  double x;
  double y;

  PerspectiveIteratorX._(
    this._den,
    this._denStep,
    this._nomX,
    this._nomXStep,
    this._nomY,
    this._nomYStep,
    this.x,
    this.y,
  );

  factory PerspectiveIteratorX.start(
    double px,
    double py,
    double step,
    Perspective m,
  ) {
    final double den = px * m.w0 + py * m.w1 + m.w2;
    final double nomX = px * m.sx + py * m.shx + m.tx;
    final double nomY = px * m.shy + py * m.sy + m.ty;

    final double d = 1.0 / den;
    return PerspectiveIteratorX._(
      den,
      m.w0 * step,
      nomX,
      step * m.sx,
      nomY,
      step * m.shy,
      nomX * d,
      nomY * d,
    );
  }

  void step() {
    _den += _denStep;
    _nomX += _nomXStep;
    _nomY += _nomYStep;
    final double d = 1.0 / _den;
    x = _nomX * d;
    y = _nomY * d;
  }
}
