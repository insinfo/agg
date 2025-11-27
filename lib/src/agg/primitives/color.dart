import 'dart:math' as math;
import 'i_color_type.dart';
import 'color_f.dart';

class Color implements IColorType {
  int red;
  int green;
  int blue;
  int alpha;

  Color(this.red, this.green, this.blue, [this.alpha = 255]);

  Color.fromArgb(int a, int r, int g, int b)
      : alpha = a,
        red = r,
        green = g,
        blue = b;

  Color.fromRgba(int r, int g, int b, int a)
      : red = r,
        green = g,
        blue = b,
        alpha = a;

  Color.fromColor(Color other)
      : red = other.red,
        green = other.green,
        blue = other.blue,
        alpha = other.alpha;

  /// Parse hex string like "#RRGGBB" or "#RRGGBBAA"
  factory Color.fromHex(String hex) {
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    if (hex.length == 6) {
      int r = int.parse(hex.substring(0, 2), radix: 16);
      int g = int.parse(hex.substring(2, 4), radix: 16);
      int b = int.parse(hex.substring(4, 6), radix: 16);
      return Color(r, g, b);
    } else if (hex.length == 8) {
      int r = int.parse(hex.substring(0, 2), radix: 16);
      int g = int.parse(hex.substring(2, 4), radix: 16);
      int b = int.parse(hex.substring(4, 6), radix: 16);
      int a = int.parse(hex.substring(6, 8), radix: 16);
      return Color(r, g, b, a);
    }
    throw FormatException("Invalid hex color format");
  }

  static Color fromWavelength(double w, [double gamma = 1.0]) {
    double r = 0.0, g = 0.0, b = 0.0;

    if (w >= 380.0 && w <= 440.0) {
      r = -1.0 * (w - 440.0) / (440.0 - 380.0);
      g = 0.0;
      b = 1.0;
    } else if (w >= 440.0 && w <= 490.0) {
      r = 0.0;
      g = (w - 440.0) / (490.0 - 440.0);
      b = 1.0;
    } else if (w >= 490.0 && w <= 510.0) {
      r = 0.0;
      g = 1.0;
      b = -1.0 * (w - 510.0) / (510.0 - 490.0);
    } else if (w >= 510.0 && w <= 580.0) {
      r = (w - 510.0) / (580.0 - 510.0);
      g = 1.0;
      b = 0.0;
    } else if (w >= 580.0 && w <= 645.0) {
      r = 1.0;
      g = -1.0 * (w - 645.0) / (645.0 - 580.0);
      b = 0.0;
    } else if (w >= 645.0 && w <= 780.0) {
      r = 1.0;
      g = 0.0;
      b = 0.0;
    } else {
      r = 0.0;
      g = 0.0;
      b = 0.0;
    }

    double s = 1.0;
    if (w > 700.0) {
      s = 0.3 + 0.7 * (780.0 - w) / (780.0 - 700.0);
    } else if (w < 420.0) {
      s = 0.3 + 0.7 * (w - 380.0) / (420.0 - 380.0);
    }

    r = (r * s);
    g = (g * s);
    b = (b * s);

    if (gamma != 1.0) {
      r = math.pow(r, gamma).toDouble();
      g = math.pow(g, gamma).toDouble();
      b = math.pow(b, gamma).toDouble();
    }

    return Color(
      (r * 255).round().clamp(0, 255),
      (g * 255).round().clamp(0, 255),
      (b * 255).round().clamp(0, 255),
    );
  }

  @override
  int get red0To255 => red;
  @override
  int get green0To255 => green;
  @override
  int get blue0To255 => blue;
  @override
  int get alpha0To255 => alpha;

  @override
  double get red0To1 => red / 255.0;
  @override
  double get green0To1 => green / 255.0;
  @override
  double get blue0To1 => blue / 255.0;
  @override
  double get alpha0To1 => alpha / 255.0;

  ColorF toColorF() {
    return ColorF(red0To1, green0To1, blue0To1, alpha0To1);
  }

  // Predefined colors
  static final Color black = Color(0, 0, 0);
  static final Color white = Color(255, 255, 255);
  static final Color redColor = Color(255, 0, 0);
  static final Color greenColor = Color(0, 255, 0);
  static final Color blueColor = Color(0, 0, 255);
  static final Color transparent = Color(0, 0, 0, 0);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Color &&
        other.red == red &&
        other.green == green &&
        other.blue == blue &&
        other.alpha == alpha;
  }

  @override
  int get hashCode => Object.hash(red, green, blue, alpha);

  @override
  String toString() => 'Color($red, $green, $blue, $alpha)';
}
