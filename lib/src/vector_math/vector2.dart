import 'package:agg/src/shared/iequatable.dart';
import 'package:agg/src/vector_math/utils.dart';
import 'dart:math' as math;

class Vector2 implements IEquatable<Vector2> {
  /// Defines an instance with all components set to positive infinity.
  static Vector2 positiveInfinity = new Vector2(double.infinity, double.infinity);

  /// Defines an instance with all components set to negative infinity.
  static Vector2 negativeInfinity = new Vector2(double.negativeInfinity, double.negativeInfinity);

  /// The X coordinate of this instance.</summary>
  double x;

  /// The Y coordinate of this instance.</summary>
  double y;

  /// Defines a unit-length Vector2d that points towards the X-axis.
  static Vector2 unitX = new Vector2(1, 0);

  /// Defines a unit-length Vector2d that points towards the Y-axis.

  static Vector2 unitY = new Vector2(0, 1);

  /// Defines a zero-length Vector2d.
  static Vector2 zero = new Vector2(0, 0);

  /// Defines an instance with all components set to 1.
  static Vector2 one = new Vector2(1, 1);

  /// Constructs left vector with the given coordinates.</summary>
  /// <param name="x">The X coordinate.</param>
  /// <param name="y">The Y coordinate.</param>
  Vector2(double x, double y) {
    this.x = x;
    this.y = y;
  }

  operator [](int index) {
    switch (index) {
      case 0:
        return x;

      case 1:
        return y;

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

      default:
        throw new Exception();
    }
  } // set

  /// return a 64 bit hash code proposed by Jon Skeet
  // http://stackoverflow.com/questions/8094867/good-gethashcode-override-for-list-of-foo-objects-respecting-the-order
  /// <returns></returns>
  int getLongHashCode([hash = 0xcbf29ce484222325]) {
    hash = Utils.getLongHashCodeFrom(x, hash);
    hash = Utils.getLongHashCodeFrom(y, hash);
    return hash;
  }

  /// Get the delta angle from start to end relative to this
  /// <param name="startPosition"></param>
  /// <param name="endPosition"></param>
  double getDeltaAngle(Vector2 startPosition, Vector2 endPosition) {
    /*	startPosition -= this;
			var startAngle = math.atan2(startPosition.y, startPosition.x);
			startAngle = startAngle < 0 ? startAngle + MathHelper.Tau : startAngle;

			endPosition -= this;
			var endAngle = math.atan2(endPosition.y, endPosition.x);
			endAngle = endAngle < 0 ? endAngle + MathHelper.Tau : endAngle;

			return endAngle - startAngle;*/
  }

  /// Gets the length (magnitude) of the vector.
  /// <seealso cref="LengthSquared"/>
  double get length {
    return math.sqrt(x * x + y * y);
  }

  double distance(Vector2 p) {
    return (this - p).length;
  }

  /// Gets the square of the vector length (magnitude).
  /// <remarks>
  /// This property avoids the costly square root operation required by the Length property. This makes it more suitable
  /// for comparisons.
  /// </remarks>
  /// <see cref="Length"/>
  double get lengthSquared {
    return x * x + y * y;
  }

  void rotate(double radians) {
    var temp = Vector2(0, 0);

    double cos, sin;

    cos = math.cos(radians);
    sin = math.sin(radians);

    temp.x = this.x * cos - this.y * sin;
    temp.y = this.y * cos + this.x * sin;

    this.x = temp.x;
    this.y = temp.y;
  }

  Vector2 getRotated(double radians) {
    return Vector2.rotateS(this, radians);
  }

  double getAngle() {
    return math.atan2(y, x);
  }

  double getAngle0To2PI() {
    //	return MathHelper.Range0ToTau(GetAngle());
  }

  /// Gets the perpendicular vector on the right side of this vector.
  /// </summary>
  Vector2 getPerpendicularRight() {
    return new Vector2(y, -x);
  }

  /// Gets the perpendicular vector on the left side of this vector.
  /// </summary>
  Vector2 getPerpendicularLeft() {
    return new Vector2(-y, x);
  }

  /// Returns a normalized Vector of this.
  /// </summary>
  /// <returns></returns>
  Vector2 getNormal() {
    Vector2 temp = this;
    temp.normalize();
    return temp;
  }

  /// Scales the Vector2 to unit length.
  /// </summary>
  void normalize() {
    double scale = 1.0 / length;
    x *= scale;
    y *= scale;
  }

  bool isValid() {
    if (x.isNaN || x.isInfinite || y.isNaN || y.isInfinite) {
      return false;
    }

    return true;
  }

  /// Adds two vectors.
  /// </summary>
  /// <param name="a">Left operand.</param>
  /// <param name="b">Right operand.</param>
  /// <returns>Result of operation.</returns>
  static Vector2 add(Vector2 a, Vector2 b) {
    return new Vector2(a.x + b.x, a.y + b.y);
  }

  /// <summary>
  /// Subtract one Vector from another
  /// </summary>
  /// <param name="a">First operand</param>
  /// <param name="b">Second operand</param>
  /// <param name="result">Result of subtraction</param>
  static Vector2 subtract(Vector2 a, Vector2 b) {
    return new Vector2(a.x - b.x, a.y - b.y);
  }

  /// <summary>
  /// Multiplies a vector by a scalar.
  /// </summary>
  /// <param name="vector">Left operand.</param>
  /// <param name="scale">Right operand.</param>
  /// <param name="result">Result of the operation.</param>
  static Vector2 multiplyByScalar(Vector2 vector, double scale) {
    return new Vector2(vector.x * scale, vector.y * scale);
  }

  /// <summary>
  /// Multiplies a vector by the components of a vector (scale).
  /// </summary>
  /// <param name="vector">Left operand.</param>
  /// <param name="scale">Right operand.</param>
  /// <param name="result">Result of the operation.</param>
  static Vector2 multiply(Vector2 vector, Vector2 scale) {
    return new Vector2(vector.x * scale.x, vector.y * scale.y);
  }

  /// Divides a vector by a scalar.
  /// </summary>
  /// <param name="vector">Left operand.</param>
  /// <param name="scale">Right operand.</param>
  /// <param name="result">Result of the operation.</param>
  static Vector2 divideByScalar(Vector2 vector, double scale) {
    return multiplyByScalar(vector, 1 / scale);
  }

  /// Divide a vector by the components of a vector (scale).
  /// <param name="vector">Left operand.</param>
  /// <param name="scale">Right operand.</param>
  /// <param name="result">Result of the operation.</param>
  static Vector2 divide(Vector2 vector, Vector2 scale) {
    return new Vector2(vector.x / scale.x, vector.y / scale.y);
  }

  /// <summary>
  /// Calculate the component-wise minimum of two vectors
  /// </summary>
  /// <param name="a">First operand</param>
  /// <param name="b">Second operand</param>
  /// <returns>The component-wise minimum</returns>
  static Vector2 min(Vector2 a, Vector2 b) {
    a.x = a.x < b.x ? a.x : b.x;
    a.y = a.y < b.y ? a.y : b.y;
    return a;
  }

  static Vector2 parse(String s) {
    var result = Vector2.zero;
    var values = s.split(',').map((sValue) {
      //double number = 0;

      if (double.tryParse(sValue) != null) {
        return double.parse(sValue);
      }

      return 0;
    }).toList();

    for (int i = 0; i < math.min(2, values.length); i++) {
      result[i] = values[i];
    }

    return result;
  }

  /// <summary>
  /// Calculate the component-wise maximum of two vectors
  /// </summary>
  /// <param name="a">First operand</param>
  /// <param name="b">Second operand</param>
  /// <returns>The component-wise maximum</returns>
  static Vector2 max(Vector2 a, Vector2 b) {
    a.x = a.x > b.x ? a.x : b.x;
    a.y = a.y > b.y ? a.y : b.y;
    return a;
  }

  /// <summary>
  /// Clamp a vector to the given minimum and maximum vectors
  /// </summary>
  /// <param name="vec">Input vector</param>
  /// <param name="min">Minimum vector</param>
  /// <param name="max">Maximum vector</param>
  /// <returns>The clamped vector</returns>
  static Vector2 clamp(Vector2 vec, Vector2 min, Vector2 max) {
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
    return vec;
  }

  /// <summary>
  /// Scale a vector to unit length
  /// </summary>
  /// <param name="vec">The input vector</param>
  /// <returns>The normalized vector</returns>
  static Vector2 normalizeS(Vector2 vec) {
    double scale = 1.0 / vec.length;
    vec.x *= scale;
    vec.y *= scale;
    return vec;
  }

  /// <summary>
  /// Calculate the dot (scalar) product of two vectors
  /// </summary>
  /// <param name="left">First operand</param>
  /// <param name="right">Second operand</param>
  /// <returns>The dot product of the two inputs</returns>
  static double dot(Vector2 left, Vector2 right) {
    return left.x * right.x + left.y * right.y;
  }

  /// <summary>
  /// Calculate the cross product of two vectors
  /// </summary>
  /// <param name="left">First operand</param>
  /// <param name="right">Second operand</param>
  /// <returns>The cross product of the two inputs</returns>
  static double crossS(Vector2 left, Vector2 right) {
    return left.x * right.y - left.y * right.x;
  }

  double cross(Vector2 right) {
    return this.x * right.y - this.y * right.x;
  }

  static Vector2 rotateS(Vector2 input, double radians) {
    var output = Vector2(0, 0);
    double cos, sin;

    cos = math.cos(radians);
    sin = math.sin(radians);

    output.x = input.x * cos - input.y * sin;
    output.y = input.y * cos + input.x * sin;
    return output;
  }

  /// <summary>
  /// Returns a new Vector that is the linear blend of the 2 given Vectors
  /// </summary>
  /// <param name="a">First input vector</param>
  /// <param name="b">Second input vector</param>
  /// <param name="blend">The blend factor. a when blend=0, b when blend=1.</param>
  /// <param name="result">a when blend=0, b when blend=1, and a linear combination otherwise</param>
  static Vector2 lerp(Vector2 a, Vector2 b, double blend) {
    a.x = blend * (b.x - a.x) + a.x;
    a.y = blend * (b.y - a.y) + a.y;
    return a;
  }

  static Vector2 baryCentric(Vector2 a, Vector2 b, Vector2 c, double u, double v) {
    var result = Vector2(a.x, a.y); // copy

    var temp = Vector2(b.x, b.y); // copy
    temp = subtract(temp, a);
    temp = multiplyByScalar(temp, u);
    result = add(result, temp);

    temp = c; // copy
    temp = subtract(temp, a);
    temp = multiplyByScalar(temp, v);
    result = add(result, temp);

    return result;
  }

  /// <summary>
  /// Calculate the component-wise minimum of two vectors
  /// </summary>
  /// <param name="a">First operand</param>
  /// <param name="b">Second operand</param>
  /// <returns>The component-wise minimum</returns>
  static Vector2 componentMin(Vector2 a, Vector2 b) {
    a.x = a.x < b.x ? a.x : b.x;
    a.y = a.y < b.y ? a.y : b.y;
    return a;
  }

  /// <summary>
  /// Calculate the component-wise maximum of two vectors
  /// </summary>
  /// <param name="a">First operand</param>
  /// <param name="b">Second operand</param>
  /// <returns>The component-wise maximum</returns>
  static Vector2 componentMax(Vector2 a, Vector2 b) {
    a.x = a.x > b.x ? a.x : b.x;
    a.y = a.y > b.y ? a.y : b.y;
    return a;
  }

  /// <summary>
  /// Adds two instances.
  /// </summary>
  /// <param name="left">The left instance.</param>
  /// <param name="right">The right instance.</param>
  /// <returns>The result of the operation.</returns>
  Vector2 operator +(Vector2 right) {
    Vector2 left = this;
    left.x += right.x;
    left.y += right.y;
    return left;
  }

  /// <summary>
  /// Subtracts two instances.
  /// </summary>
  /// <param name="left">The left instance.</param>
  /// <param name="right">The right instance.</param>
  /// <returns>The result of the operation.</returns>
  Vector2 operator -(Vector2 right) {
    Vector2 left = this;
    left.x -= right.x;
    left.y -= right.y;
    return left;
  }

  /// <summary>
  /// Negates an instance.
  /// </summary>
  /// <param name="vec">The instance.</param>
  /// <returns>The result of the operation.</returns>
  static Vector2 negates(Vector2 vec) {
    vec.x = -vec.x;
    vec.y = -vec.y;
    return vec;
  }

  /// <summary>
  /// Multiplies an instance by a scalar.
  /// </summary>
  /// <param name="vec">The instance.</param>
  /// <param name="f">The scalar.</param>
  /// <returns>The result of the operation.</returns>
  Vector2 operator *(double f) {
    Vector2 vec = this;
    vec.x *= f;
    vec.y *= f;
    return vec;
  }

  /// <summary>
  /// Divides an instance by a scalar.
  /// </summary>
  /// <param name="vec">The instance.</param>
  /// <param name="f">The scalar.</param>
  /// <returns>The result of the operation.</returns>
  Vector2 operator /(double f) {
    Vector2 vec = this;
    double mult = 1.0 / f;
    vec.x *= mult;
    vec.y *= mult;
    return vec;
  }

  /// <summary>
  /// Compares two instances for equality.
  /// </summary>
  /// <param name="left">The left instance.</param>
  /// <param name="right">The right instance.</param>
  /// <returns>True, if both instances are equal; false otherwise.</returns>
  bool operator ==(Object right) {
    Vector2 left = this;
    return left.equalsFromObj(right);
  }

  /// <summary>
  /// Returns a System.String that represents the current instance.
  /// </summary>
  /// <returns></returns>
  String toString() {
    return "(x, y)";
  }

  /// <summary>
  /// Returns the hashcode for this instance.
  /// </summary>
  /// <returns>A System.Int32 containing the unique hashcode for this instance.</returns>
  int get hashCode {
    return {x, y}.hashCode;
  }

  /// <summary>Indicates whether the current vector is equal to another vector.</summary>
  /// <param name="other">A vector to compare with this vector.</param>
  /// <returns>true if the current vector is equal to the vector parameter; otherwise, false.</returns>
  @override
  bool equals(Vector2 obj) {
    return equalsFromObj(obj);
  }

  /// <summary>
  /// Indicates whether this instance and a specified object are equal.
  /// </summary>
  /// <param name="obj">The object to compare to.</param>
  /// <returns>True if the instances are equal; false otherwise.</returns>
  bool equalsFromObj(Object obj) {
    if (obj is Vector2) {
      return x == obj.x && y == obj.y;
    } else {
      return false;
    }
  }
  /**************** */

  /*static double lolygonLength(this List<Vector2> polygon, bool isClosed = true)
		{
			var length = 0.0;
			if (polygon.Count > 1)
			{
				var previousPoint = polygon[0];
				if (isClosed)
				{
					previousPoint = polygon[polygon.Count - 1];
				}

				for (int i = isClosed ? 0 : 1; i < polygon.Count; i++)
				{
					var currentPoint = polygon[i];
					length += (previousPoint - currentPoint).Length;
					previousPoint = currentPoint;
				}
			}

			return length;
		}*/
}
