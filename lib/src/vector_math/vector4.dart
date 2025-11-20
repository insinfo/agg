import 'dart:math' as math;
import 'package:agg/src/shared/iequatable.dart';
import 'package:agg/src/vector_math/utils.dart';
import 'package:agg/src/vector_math/vector2.dart';

/// Represents a 4D vector using four double-precision floating-point numbers.
class Vector4 implements IEquatable<Vector4> {
  /// The X component of the Vector4d.
  double x;

  /// The Y component of the Vector4d.
  double y;

  /// The Z component of the Vector4d.
  double z;

  /// The W component of the Vector4d.
  double w;

  /// Defines a unit-length Vector4d that points towards the X-axis.
  static Vector4 unitX = Vector4(1, 0, 0, 0);

  /// Defines a unit-length Vector4d that points towards the Y-axis.
  static Vector4 unitY = Vector4(0, 1, 0, 0);

  /// Defines a unit-length Vector4d that points towards the Z-axis.
  static Vector4 unitZ = Vector4(0, 0, 1, 0);

  /// Defines a unit-length Vector4d that points towards the W-axis.
  static Vector4 unitW = Vector4(0, 0, 0, 1);

  /// Defines a zero-length Vector4d.
  static Vector4 zero = Vector4(0, 0, 0, 0);

  /// Defines an instance with all components set to 1.
  static final Vector4 one = Vector4(1, 1, 1, 1);

  /// Defines the size of the Vector4d struct in bytes.
  //static final int sizeInBytes = Marshal.SizeOf(new Vector4());

  /// Constructs a new Vector4d.
  /// <param name="x">The x component of the Vector4d.</param>
  /// <param name="y">The y component of the Vector4d.</param>
  /// <param name="z">The z component of the Vector4d.</param>
  /// <param name="w">The w component of the Vector4d.</param>
  Vector4(this.x, this.y, this.z, this.w);

  /// Constructs a new Vector4d from the given Vector2d.
  /// <param name="v">The Vector2d to copy components from.</param>
  Vector4.fromVector2(Vector2 v)
      : x = v.x,
        y = v.y,
        z = 0.0,
        w = 0.0;

  /// Constructs a new Vector4d from the given Vector3d.
  /// <param name="v">The Vector3d to copy components from.</param>
  /*Vector4.fromVector3(Vector3 v) {
    x = v.x;
    y = v.y;
    z = v.z;
    w = 0.0;
  }

  /// Constructs a new Vector4d from the specified Vector3d and w component.
  /// <param name="v">The Vector3d to copy components from.</param>
  /// <param name="w">The w component of the new Vector4.</param>
  Vector4.fromVector3AndW(Vector3 v, double w) {
    x = v.x;
    y = v.y;
    z = v.z;
    this.w = w;
  }*/

  /// Constructs a new Vector4d from the given Vector4d.
  /// <param name="v">The Vector4d to copy components from.</param>
  Vector4.fromVector4(Vector4 v)
      : x = v.x,
        y = v.y,
        z = v.z,
        w = v.w;

  static Vector4 parse(String s) {
    var result = Vector4.zero;
    var values =
        s.split(',').map((sValue) => double.tryParse(sValue) ?? 0.0).toList();
    for (int i = 0; i < math.min(4, values.length); i++) {
      result[i] = values[i];
    }
    return result;
  }

  operator [](int index) {
    switch (index) {
      case 0:
        return x;

      case 1:
        return y;

      case 2:
        return z;

      case 3:
        return w;

      default:
        return 0;
    }
  } // get

  operator []=(int index, double value) {
    switch (index) {
      case 0:
        x = value;
        break;

      case 1:
        y = value;
        break;

      case 2:
        z = value;
        break;

      case 3:
        w = value;
        break;

      default:
        throw new Exception();
    }
  } // set

  /// Gets the length (magnitude) of the vector.
  /// <see cref="LengthFast"/>
  /// <seealso cref="LengthSquared"/>
  double get length {
    return math.sqrt(x * x + y * y + z * z + w * w);
  }

  /// Gets the square of the vector length (magnitude).
  /// This property avoids the costly square root operation required by the Length property. This makes it more suitable
  /// for comparisons.
  /// <see cref="Length"/>
  double get lengthSquared {
    return x * x + y * y + z * z + w * w;
  }

  /// Scales the Vector4d to unit length.
  void normalize() {
    double scale = 1.0 / this.length;
    x *= scale;
    y *= scale;
    z *= scale;
    w *= scale;
  }

  bool isValid() {
    if (x.isNaN ||
        x.isInfinite ||
        y.isNaN ||
        y.isInfinite ||
        z.isNaN ||
        z.isInfinite ||
        w.isNaN ||
        w.isInfinite) {
      return false;
    }
    return true;
  }

  /// Adds two vectors.
  /// <param name="a">Left operand.</param>
  /// <param name="b">Right operand.</param>
  /// <returns>Result of operation.</returns>
  static Vector4 add(Vector4 a, Vector4 b) {
    return Vector4(a.x + b.x, a.y + b.y, a.z + b.z, a.w + b.w);
  }

  /// Subtract one Vector from another
  /// <param name="a">First operand</param>
  /// <param name="b">Second operand</param>
  /// <returns>Result of subtraction</returns>
  static Vector4 subtract(Vector4 a, Vector4 b) {
    return Vector4(a.x - b.x, a.y - b.y, a.z - b.z, a.w - b.w);
  }

  /// Multiplies a vector by a scalar.
  /// <param name="vector">Left operand.</param>
  /// <param name="scale">Right operand.</param>
  /// <returns>Result of the operation.</returns>
  static Vector4 multiplyByScalar(Vector4 vector, double scale) {
    return Vector4(
        vector.x * scale, vector.y * scale, vector.z * scale, vector.w * scale);
  }

  /// Multiplies a vector by the components a vector (scale).
  /// <param name="vector">Left operand.</param>
  /// <param name="scale">Right operand.</param>
  /// <returns>Result of the operation.</returns>
  static Vector4 multiply(Vector4 vector, Vector4 scale) {
    return Vector4(vector.x * scale.x, vector.y * scale.y, vector.z * scale.z,
        vector.w * scale.w);
  }

  /// Divides a vector by a scalar.
  /// <param name="vector">Left operand.</param>
  /// <param name="scale">Right operand.</param>
  /// <returns>Result of the operation.</returns>
  static Vector4 divideByScalar(Vector4 vector, double scale) {
    return multiplyByScalar(vector, 1 / scale);
  }

  /// Divides a vector by the components of a vector (scale).
  /// <param name="vector">Left operand.</param>
  /// <param name="scale">Right operand.</param>
  /// <returns>Result of the operation.</returns>
  static Vector4 divide(Vector4 vector, Vector4 scale) {
    return Vector4(vector.x / scale.x, vector.y / scale.y, vector.z / scale.z,
        vector.w / scale.w);
  }

  /// Calculate the component-wise minimum of two vectors

  /// <param name="a">First operand</param>
  /// <param name="b">Second operand</param>
  /// <returns>The component-wise minimum</returns>
  static Vector4 min(Vector4 a, Vector4 b) {
    a.x = a.x < b.x ? a.x : b.x;
    a.y = a.y < b.y ? a.y : b.y;
    a.z = a.z < b.z ? a.z : b.z;
    a.w = a.w < b.w ? a.w : b.w;
    return a;
  }

  /// Calculate the component-wise maximum of two vectors
  /// <param name="a">First operand</param>
  /// <param name="b">Second operand</param>
  /// <returns>The component-wise maximum</returns>
  Vector4 max(Vector4 a, Vector4 b) {
    a.x = a.x > b.x ? a.x : b.x;
    a.y = a.y > b.y ? a.y : b.y;
    a.z = a.z > b.z ? a.z : b.z;
    a.w = a.w > b.w ? a.w : b.w;
    return a;
  }

  /// Clamp a vector to the given minimum and maximum vectors
  /// <param name="vec">Input vector</param>
  /// <param name="min">Minimum vector</param>
  /// <param name="max">Maximum vector</param>
  /// <returns>The clamped vector</returns>
  static Vector4 clamp(Vector4 vec, Vector4 min, Vector4 max) {
    vec.x = vec.x < min.x
        ? min.x
        : vec.x > max.x
            ? max.x
            : vec.x;
    vec.y = vec.y < min.y
        ? min.y
        : vec.y > max.y
            ? max.y
            : vec.y;
    vec.z = vec.x < min.z
        ? min.z
        : vec.z > max.z
            ? max.z
            : vec.z;
    vec.w = vec.y < min.w
        ? min.w
        : vec.w > max.w
            ? max.w
            : vec.w;
    return vec;
  }

  ///static method for Scale a vector to unit length

  /// <param name="vec">The input vector</param>
  /// <returns>The normalized vector</returns>
  static Vector4 normalizeS(Vector4 vec) {
    double scale = 1.0 / vec.length;
    vec.x *= scale;
    vec.y *= scale;
    vec.z *= scale;
    vec.w *= scale;
    return vec;
  }

  /// Calculate the dot product of two vectors
  /// <param name="left">First operand</param>
  /// <param name="right">Second operand</param>
  /// <returns>The dot product of the two inputs</returns>
  static double dot(Vector4 left, Vector4 right) {
    return left.x * right.x +
        left.y * right.y +
        left.z * right.z +
        left.w * right.w;
  }

  /// Returns a new Vector that is the linear blend of the 2 given Vectors
  /// <param name="a">First input vector</param>
  /// <param name="b">Second input vector</param>
  /// <param name="blend">The blend factor. a when blend=0, b when blend=1.</param>
  /// <returns>a when blend=0, b when blend=1, and a linear combination otherwise</returns>
  static Vector4 lerp(Vector4 a, Vector4 b, double blend) {
    a.x = blend * (b.x - a.x) + a.x;
    a.y = blend * (b.y - a.y) + a.y;
    a.z = blend * (b.z - a.z) + a.z;
    a.w = blend * (b.w - a.w) + a.w;
    return a;
  }

  /// Interpolate 3 Vectors using Barycentric coordinates
  /// <param name="a">First input Vector</param>
  /// <param name="b">Second input Vector</param>
  /// <param name="c">Third input Vector</param>
  /// <param name="u">First Barycentric Coordinate</param>
  /// <param name="v">Second Barycentric Coordinate</param>
  /// <returns>a when u=v=0, b when u=1,v=0, c when u=0,v=1, and a linear combination of a,b,c otherwise</returns>
  /*static Vector4 baryCentric2(Vector4 a, Vector4 b, Vector4 c, double u, double v) {
    return a + u * (b - a) + v * (c - a);
  }*/

  /// Interpolate 3 Vectors using Barycentric coordinates
  /// <param name="a">First input Vector</param>
  /// <param name="b">Second input Vector</param>
  /// <param name="c">Third input Vector</param>
  /// <param name="u">First Barycentric Coordinate</param>
  /// <param name="v">Second Barycentric Coordinate</param>
  /// <returns>a when u=v=0, b when u=1,v=0, c when u=0,v=1, and a linear combination of a,b,c otherwise</returns>
  static Vector4 baryCentric(
      Vector4 a, Vector4 b, Vector4 c, double u, double v) {
    var result = Vector4(a.x, a.y, a.z, a.w); // copy

    var temp = Vector4(b.x, b.y, b.z, b.w); // copy
    temp = subtract(temp, a);
    temp = multiplyByScalar(temp, u);
    result = add(result, temp);

    temp = c; // copy
    temp = subtract(temp, a);
    temp = multiplyByScalar(temp, v);
    result = add(result, temp);
    return result;
  }

  /// Adds two instances.
  /// <param name="left">The first instance.</param>
  /// <param name="right">The second instance.</param>
  /// <returns>The result of the calculation.</returns>
  Vector4 operator +(Vector4 right) {
    Vector4 left = this;
    left.x += right.x;
    left.y += right.y;
    left.z += right.z;
    left.w += right.w;
    return left;
  }

  /// Subtracts two instances.
  /// <param name="left">The first instance.</param>
  /// <param name="right">The second instance.</param>
  /// <returns>The result of the calculation.</returns>
  Vector4 operator -(Vector4 right) {
    Vector4 left = this;
    left.x -= right.x;
    left.y -= right.y;
    left.z -= right.z;
    left.w -= right.w;
    return left;
  }

  /// Negates an instance.
  /// <param name="vec">The instance.</param>
  /// <returns>The result of the calculation.</returns>
  static Vector4 negates(Vector4 vec) {
    vec.x = -vec.x;
    vec.y = -vec.y;
    vec.z = -vec.z;
    vec.w = -vec.w;
    return vec;
  }

  /// Multiplies an instance by a scalar.
  /// <param name="vec">The instance.</param>
  /// <param name="scale">The scalar.</param>
  /// <returns>The result of the calculation.</returns>
  Vector4 operator *(double scale) {
    Vector4 vec = this;
    vec.x *= scale;
    vec.y *= scale;
    vec.z *= scale;
    vec.w *= scale;
    return vec;
  }

  /// Divides an instance by a scalar.

  /// <param name="vec">The instance.</param>
  /// <param name="scale">The scalar.</param>
  /// <returns>The result of the calculation.</returns>
  Vector4 operator /(double scale) {
    Vector4 vec = this;
    double mult = 1 / scale;
    vec.x *= mult;
    vec.y *= mult;
    vec.z *= mult;
    vec.w *= mult;
    return vec;
  }

  /// Compares two instances for equality.
  /// <param name="left">The first instance.</param>
  /// <param name="right">The second instance.</param>
  /// <returns>True, if left equals right; false otherwise.</returns>
  bool operator ==(Object right) {
    Vector4 left = this;
    return left.equalsFromObj(right);
  }

  /// Compares two instances for inequality.
  /// <param name="left">The first instance.</param>
  /// <param name="right">The second instance.</param>
  /// <returns>True, if left does not equa lright; false otherwise.</returns>
  /*	bool operator !=(covariant Vector4 right)
	{
		Vector4 left = this;
    return !left.equals(right);
	}*/

  /// Returns a System.String that represents the current Vector4d.
  /// <returns></returns>
  @override
  String toString() {
    return "$x, $y, $z, $w";
  }

  /// Returns the hashcode for this instance.

  /// <returns>A System.Int32 containing the unique hashcode for this instance.</returns>
  @override
  int get hashCode {
    return {x, y, z, w}.hashCode;
  }

  /// return a 64 bit hash code proposed by Jon Skeet
  // http://stackoverflow.com/questions/8094867/good-gethashcode-override-for-list-of-foo-objects-respecting-the-order

  /// <returns></returns>
  int getLongHashCode([hash = 0xcbf29ce484222325]) {
    hash = Utils.getLongHashCodeFrom(x, hash);
    hash = Utils.getLongHashCodeFrom(y, hash);
    hash = Utils.getLongHashCodeFrom(z, hash);
    hash = Utils.getLongHashCodeFrom(w, hash);
    return hash;
  }

  /// Indicates whether this instance and a specified object are equal.
  /// <param name="obj">The object to compare to.</param>
  /// <returns>True if the instances are equal; false otherwise.</returns>
  @override
  bool equals(Vector4 obj) {
    return this.equalsFromObj(obj);
  }

  //Indicates whether the current vector is equal to another vector.</summary>
  /// <param name="other">A vector to compare with this vector.</param>
  /// <returns>true if the current vector is equal to the vector parameter; otherwise, false.</returns>
  bool equalsFromObj(Object other) {
    if (other is Vector4) {
      return x == other.x && y == other.y && z == other.z && w == other.w;
    } else {
      return false;
    }
  }

  /// Indicates whether this instance and a specified object are equal within an error range.
  /// <param name="OtherVector"></param>
  /// <param name="ErrorValue"></param>
  /// <returns>True if the instances are equal; false otherwise.</returns>
  bool equalsErrorValue(Vector4 otherVector, double errorValue) {
    if ((x < otherVector.x + errorValue && x > otherVector.x - errorValue) &&
        (y < otherVector.y + errorValue && y > otherVector.y - errorValue) &&
        (z < otherVector.z + errorValue && z > otherVector.z - errorValue) &&
        (w < otherVector.w + errorValue && w > otherVector.w - errorValue)) {
      return true;
    }
    return false;
  }
}
