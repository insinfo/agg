import 'i_color_type.dart';
import 'color.dart';

class ColorF implements IColorType {
  double red;
  double green;
  double blue;
  double alpha;

  ColorF(this.red, this.green, this.blue, [this.alpha = 1.0]);

  ColorF.fromRgba(double r, double g, double b, double a)
      : red = r,
        green = g,
        blue = b,
        alpha = a;

  @override
  int get red0To255 => (red * 255).round().clamp(0, 255);
  @override
  int get green0To255 => (green * 255).round().clamp(0, 255);
  @override
  int get blue0To255 => (blue * 255).round().clamp(0, 255);
  @override
  int get alpha0To255 => (alpha * 255).round().clamp(0, 255);

  @override
  double get red0To1 => red;
  @override
  double get green0To1 => green;
  @override
  double get blue0To1 => blue;
  @override
  double get alpha0To1 => alpha;

  Color toColor() {
    return Color(red0To255, green0To255, blue0To255, alpha0To255);
  }

  void getHSL(List<double> hsl) {
    double max = red > green ? (red > blue ? red : blue) : (green > blue ? green : blue);
    double min = red < green ? (red < blue ? red : blue) : (green < blue ? green : blue);
    double h = 0, s = 0, l = (max + min) / 2;

    if (max == min) {
      h = s = 0; // achromatic
    } else {
      double d = max - min;
      s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
      if (max == red) {
        h = (green - blue) / d + (green < blue ? 6 : 0);
      } else if (max == green) {
        h = (blue - red) / d + 2;
      } else {
        h = (red - green) / d + 4;
      }
      h /= 6;
    }
    if (hsl.length >= 3) {
      hsl[0] = h;
      hsl[1] = s;
      hsl[2] = l;
    } else {
      hsl.addAll([h, s, l]);
    }
  }

  static ColorF fromHSL(double h, double s, double l) {
    // Simple HSL to RGB conversion
    double r, g, b;

    if (s == 0) {
      r = g = b = l; // achromatic
    } else {
      double hue2rgb(double p, double q, double t) {
        if (t < 0) t += 1;
        if (t > 1) t -= 1;
        if (t < 1 / 6) return p + (q - p) * 6 * t;
        if (t < 1 / 2) return q;
        if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
        return p;
      }

      double q = l < 0.5 ? l * (1 + s) : l + s - l * s;
      double p = 2 * l - q;
      r = hue2rgb(p, q, h + 1 / 3);
      g = hue2rgb(p, q, h);
      b = hue2rgb(p, q, h - 1 / 3);
    }

    return ColorF(r, g, b, 1.0);
  }

  @override
  String toString() => 'ColorF($red, $green, $blue, $alpha)';
}
