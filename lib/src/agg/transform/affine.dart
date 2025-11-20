import 'dart:math' as math;

/// Affine transformation matrix for 2D graphics.
/// Represents a 2x3 matrix for affine transformations:
/// | sx  shx  tx |
/// | shy sy   ty |
/// | 0   0    1  |
class Affine {
  double sx; // Scale X
  double shy; // Shear Y
  double shx; // Shear X
  double sy; // Scale Y
  double tx; // Translate X
  double ty; // Translate Y

  Affine([
    this.sx = 1.0,
    this.shy = 0.0,
    this.shx = 0.0,
    this.sy = 1.0,
    this.tx = 0.0,
    this.ty = 0.0,
  ]);

  /// Create from array [sx, shy, shx, sy, tx, ty]
  Affine.fromArray(List<double> m)
      : sx = m[0],
        shy = m[1],
        shx = m[2],
        sy = m[3],
        tx = m[4],
        ty = m[5];

  /// Create identity matrix
  factory Affine.identity() {
    return Affine(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
  }

  /// Create rotation matrix
  factory Affine.rotation(double angle) {
    double ca = math.cos(angle);
    double sa = math.sin(angle);
    return Affine(ca, sa, -sa, ca, 0.0, 0.0);
  }

  /// Create scaling matrix
  factory Affine.scaling(double scaleX, [double? scaleY]) {
    scaleY ??= scaleX;
    return Affine(scaleX, 0.0, 0.0, scaleY, 0.0, 0.0);
  }

  /// Create translation matrix
  factory Affine.translation(double dx, double dy) {
    return Affine(1.0, 0.0, 0.0, 1.0, dx, dy);
  }

  /// Create skewing matrix
  factory Affine.skewing(double sx, double sy) {
    return Affine(1.0, math.tan(sy), math.tan(sx), 1.0, 0.0, 0.0);
  }

  /// Reset to identity
  void reset() {
    sx = 1.0;
    shy = 0.0;
    shx = 0.0;
    sy = 1.0;
    tx = 0.0;
    ty = 0.0;
  }

  /// Multiply this matrix by another (this = this * m)
  Affine multiply(Affine m) {
    double t0 = sx * m.sx + shy * m.shx;
    double t2 = shx * m.sx + sy * m.shx;
    double t4 = tx * m.sx + ty * m.shx + m.tx;

    shy = sx * m.shy + shy * m.sy;
    sy = shx * m.shy + sy * m.sy;
    ty = tx * m.shy + ty * m.sy + m.ty;

    sx = t0;
    shx = t2;
    tx = t4;

    return this;
  }

  /// Premultiply this matrix by another (this = m * this)
  Affine premultiply(Affine m) {
    Affine t = Affine.fromArray([sx, shy, shx, sy, tx, ty]);
    sx = m.sx * t.sx + m.shy * t.shx;
    shy = m.sx * t.shy + m.shy * t.sy;
    shx = m.shx * t.sx + m.sy * t.shx;
    sy = m.shx * t.shy + m.sy * t.sy;
    tx = m.tx * t.sx + m.ty * t.shx + t.tx;
    ty = m.tx * t.shy + m.ty * t.sy + t.ty;
    return this;
  }

  /// Invert the matrix
  Affine invert() {
    double d = determinant();

    double t0 = sy / d;
    sy = sx / d;
    shy = -shy / d;
    shx = -shx / d;

    double t4 = -tx * t0 - ty * shx;
    ty = -tx * shy - ty * sy;

    sx = t0;
    tx = t4;

    return this;
  }

  /// Calculate determinant
  double determinant() {
    return sx * sy - shy * shx;
  }

  /// Get the scale factor
  double getScale() {
    double x = 0.707106781 * sx + 0.707106781 * shx;
    double y = 0.707106781 * shy + 0.707106781 * sy;
    return math.sqrt(x * x + y * y);
  }

  /// Transform a point (x, y)
  ({double x, double y}) transform(double x, double y) {
    return (
      x: x * sx + y * shx + tx,
      y: x * shy + y * sy + ty,
    );
  }

  /// Transform only the vector part (no translation)
  ({double x, double y}) transformVector(double x, double y) {
    return (
      x: x * sx + y * shx,
      y: x * shy + y * sy,
    );
  }

  /// Inverse transform a point
  ({double x, double y}) inverseTransform(double x, double y) {
    double d = determinant();
    double a = (x - tx) * sy - (y - ty) * shx;
    double b = (y - ty) * sx - (x - tx) * shy;
    return (
      x: a / d,
      y: b / d,
    );
  }

  /// Rotate
  Affine rotate(double angle) {
    multiply(Affine.rotation(angle));
    return this;
  }

  /// Scale
  Affine scale(double scaleX, [double? scaleY]) {
    scaleY ??= scaleX;
    multiply(Affine.scaling(scaleX, scaleY));
    return this;
  }

  /// Translate
  Affine translate(double dx, double dy) {
    tx += dx;
    ty += dy;
    return this;
  }

  /// Copy from another affine
  void copyFrom(Affine other) {
    sx = other.sx;
    shy = other.shy;
    shx = other.shx;
    sy = other.sy;
    tx = other.tx;
    ty = other.ty;
  }

  /// Clone this affine
  Affine clone() {
    return Affine(sx, shy, shx, sy, tx, ty);
  }

  @override
  String toString() {
    return 'Affine($sx, $shy, $shx, $sy, $tx, $ty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Affine &&
        other.sx == sx &&
        other.shy == shy &&
        other.shx == shx &&
        other.sy == sy &&
        other.tx == tx &&
        other.ty == ty;
  }

  @override
  int get hashCode => Object.hash(sx, shy, shx, sy, tx, ty);
}
