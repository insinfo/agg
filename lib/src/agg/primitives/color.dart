import 'package:agg/src/agg/agg_basics.dart';
import 'package:agg/src/agg/interfaces/icolor_type.dart';
import 'dart:math' as math;

import 'package:agg/src/agg/primitives/colorf.dart';

class Color implements IColorType {
  static const int cover_shift = 8;
  static const int cover_size = 1 << cover_shift; //----cover_size
  static const int cover_mask = cover_size - 1; //----cover_mask
  // final int cover_none  = 0,                 //----cover_none
  // final int cover_full  = cover_mask         //----cover_full

  static final int base_shift = 8;
  static final int base_scale = (1 << base_shift);
  static final int base_mask = base_scale - 1;

  int blue;
  int green;
  int red;
  int alpha;

  static final Color Black = new Color.fromRGB(0, 0, 0);
  static final Color Blue = new Color.fromHex("#0000FF");
  static final Color Crimson = new Color.fromHex("#DC143C");
  static final Color Cyan = new Color.fromRGB(0, 255, 255);
  static final Color DarkBlue = new Color.fromHex("#0000A0");
  static final Color DarkGray = new Color.fromRGB(85, 85, 85);
  static final Color FireEngineRed = new Color.fromHex("#F62817");
  static final Color Gray = new Color.fromRGB(125, 125, 125);
  static final Color Green = new Color.fromRGB(0, 255, 0);
  static final Color Indigo = new Color.fromRGB(75, 0, 130);
  static final Color LightBlue = new Color.fromHex("#ADD8E6");
  static final Color LightGray = new Color.fromRGB(225, 225, 225);
  static final Color Magenta = new Color.fromRGB(255, 0, 255);
  static final Color Orange = new Color.fromRGB(255, 127, 0);
  static final Color Pink = new Color.fromRGB(255, 192, 203);
  static final Color Red = new Color.fromRGB(255, 0, 0);
  static final Color Transparent = new Color.fromRGBA(0, 0, 0, 0);
  static final Color Violet = new Color.fromRGB(143, 0, 255);
  static final Color White = new Color.fromRGB(255, 255, 255);
  static final Color Yellow = new Color.fromRGB(255, 255, 0);
  static final Color YellowGreen = new Color.fromRGB(154, 205, 50);

  int get red0To255 {
    return red;
  }

  set red0To255(int value) {
    red = value;
  }

  int get green0To255 {
    return green;
  }

  set green0To255(int value) {
    green = value;
  }

  int get blue0To255 {
    return blue;
  }

  set blue0To255(int value) {
    blue = value;
  }

  int get alpha0To255 {
    return alpha;
  }

  set alpha0To255(int value) {
    alpha = value;
  }

  double get red0To1 {
    return red / 255.0;
  }

  set red0To1(double value) {
    red = math.max(0, math.min((value * 255) as int, 255));
  }

  double get green0To1 {
    return green / 255.0;
  }

  set green0To1(double value) {
    green = math.max(0, math.min((value * 255) as int, 255));
  }

  double get blue0To1 {
    return blue / 255.0;
  }

  set blue0To1(double value) {
    blue = math.max(0, math.min((value * 255) as int, 255));
  }

  double get alpha0To1 {
    return alpha / 255.0;
  }

  set alpha0To1(double value) {
    alpha = math.max(0, math.min((value * 255) as int, 255));
  }

  String get html {
    return "#${red.toRadixString(16)}${green.toRadixString(16)}${blue.toRadixString(16)}${alpha.toRadixString(16)}"
        .toUpperCase();
  }

  set html(String value) {
    switch (value.length) {
      case 4: // #CCC, single char rgb
      case 5: // also has alpha
        red = int.tryParse(value.substring(1, 1) + value.substring(1, 1), radix: 16);
        green = int.tryParse(value.substring(2, 1) + value.substring(2, 1), radix: 16);
        blue = int.tryParse(value.substring(3, 1) + value.substring(3, 1), radix: 16);
        if (value.length == 5) {
          alpha = int.tryParse(value.substring(4, 1) + value.substring(4, 1), radix: 16);
        } else {
          alpha = 255;
        }
        break;
      case 7: // #ACACAC, two char rgb
      case 9: // also has alpha
        red = int.tryParse(value.substring(1, 2), radix: 16);
        green = int.tryParse(value.substring(3, 2), radix: 16);
        blue = int.tryParse(value.substring(5, 2), radix: 16);
        if (value.length == 9) {
          alpha = int.tryParse(value.substring(7, 2), radix: 16);
        } else {
          alpha = 255;
        }
        break;
      default:
        break; // don't know what it is, do nothing
    }
  }

  Color() {
    /*red = 0;
    green = 0;
    blue = 0;
    alpha = 0;*/
  }
  Color.fromHex(String htmlString) {
    html = htmlString;
  }

  Color.fromRGB(int r_, int g_, int b_) {
    Color.fromRGBA(r_, g_, b_, base_mask);
  }

  Color.fromRGBA(int r_, int g_, int b_, int a_) {
    red = math.min(math.max(r_, 0), 255);
    green = math.min(math.max(g_, 0), 255);
    blue = math.min(math.max(b_, 0), 255);
    alpha = math.min(math.max(a_, 0), 255);
  }

  Color.fromRGBAf(double r_, double g_, double b_, double a_) {
    red = (Agg_basics.uround(r_ * base_mask));
    green = (Agg_basics.uround(g_ * base_mask));
    blue = (Agg_basics.uround(b_ * base_mask));
    alpha = (Agg_basics.uround(a_ * base_mask));
  }

  Color.fromColor(Color c) {
    red = c.red;
    green = c.green;
    blue = c.blue;
    alpha = c.alpha;
  }

  Color.fromColorWithAlpha(Color c, int a_) {
    red = c.red;
    green = c.green;
    blue = c.blue;
    alpha = math.max(0, math.min(255, a_));
  }

  Color.fromFourByteColor(int fourByteColor) {
    red = ((fourByteColor >> 16) & 0xFF);
    green = ((fourByteColor >> 8) & 0xFF);
    blue = ((fourByteColor >> 0) & 0xFF);
    alpha = ((fourByteColor >> 24) & 0xFF);
  }

  void fromColor(Color c) {
    red = c.red;
    green = c.green;
    blue = c.blue;
    alpha = c.alpha;
  }

  Color.fromColorF(ColorF c) {
    red = (Agg_basics.uround(c.red * (base_mask as double)));
    green = (Agg_basics.uround(c.green * (base_mask as double)));
    blue = (Agg_basics.uround(c.blue * (base_mask as double)));
    alpha = (Agg_basics.uround(c.alpha * (base_mask as double)));
  }

  @override
  int get hashCode => {blue, green, red, alpha}.hashCode;

  Color toColor() {
    return this;
  }

  String getAsHTMLString() {
    if (alpha == 255) {
      return "#${red.toRadixString(16)}${green.toRadixString(16)}${blue.toRadixString(16)}".toUpperCase();
    } else {
      return "#${red.toRadixString(16)}${green.toRadixString(16)}${blue.toRadixString(16)}${alpha.toRadixString(16)}"
          .toUpperCase();
    }
  }

  void clear() {
    red = green = blue = alpha = 0;
  }

  Color gradient(Color c, double k) {
    Color ret = new Color();
    int ik = Agg_basics.uround(k * base_scale);
    ret.red0To255 = ((red0To255) + ((((c.red0To255) - red0To255) * ik) >> base_shift));
    ret.green0To255 = ((green0To255) + ((((c.green0To255) - green0To255) * ik) >> base_shift));
    ret.blue0To255 = ((blue0To255) + ((((c.blue0To255) - blue0To255) * ik) >> base_shift));
    ret.alpha0To255 = ((alpha0To255) + ((((c.alpha0To255) - alpha0To255) * ik) >> base_shift));
    return ret;
  }

  bool operator ==(Object b) {
    if (b is Color) {
      Color a = this;
      if (a.red == b.red && a.green == b.green && a.blue == b.blue && a.alpha == b.alpha) {
        return true;
      }
      return false;
    }
    return false;
  }

  @override
  String toString() {
    return getAsHTMLString();
  }

  bool equals(Object obj) {
    if (obj is Color) {
      return this == obj;
    }
    return false;
  }

  Color operator +(Color b) {
    Color a = this;
    Color temp = new Color();
    temp.red = ((a.red + b.red) > 255 ? 255 : (a.red + b.red));
    temp.green = ((a.green + b.green) > 255 ? 255 : (a.green + b.green));
    temp.blue = ((a.blue + b.blue) > 255 ? 255 : (a.blue + b.blue));
    temp.alpha = ((a.alpha + b.alpha) > 255 ? 255 : (a.alpha + b.alpha));
    return temp;
  }

  Color operator -(Color b) {
    Color a = this;
    Color temp = new Color();
    temp.red = ((a.red - b.red) < 0 ? 0 : (a.red - b.red));
    temp.green = ((a.green - b.green) < 0 ? 0 : (a.green - b.green));
    temp.blue = ((a.blue - b.blue) < 0 ? 0 : (a.blue - b.blue));
    temp.alpha = 255; // (byte)((A.m_A - B.m_A) < 0 ? 0 : (A.m_A - B.m_A));
    return temp;
  }

  Color operator *(double doubleB) {
    Color a = this;
    double B = doubleB;
    ColorF temp = new ColorF();
    temp.red = a.red / 255.0 * B;
    temp.green = a.green / 255.0 * B;
    temp.blue = a.blue / 255.0 * B;
    temp.alpha = a.alpha / 255.0 * B;
    return new Color.fromColorF(temp);
  }

  void add(Color c, int cover) {
    int cr, cg, cb, ca;
    if (cover == cover_mask) {
      if (c.alpha0To255 == base_mask) {
        fromColor(c);
      } else {
        cr = red0To255 + c.red0To255;
        red0To255 = (cr > (base_mask)) ? (base_mask) : cr;
        cg = green0To255 + c.green0To255;
        green0To255 = (cg > (base_mask)) ? (base_mask) : cg;
        cb = blue0To255 + c.blue0To255;
        blue0To255 = (cb > (base_mask)) ? (base_mask) : cb;
        ca = alpha0To255 + c.alpha0To255;
        alpha0To255 = (ca > (base_mask)) ? (base_mask) : ca;
      }
    } else {
      cr = red0To255 + (((c.red0To255 * cover + cover_mask / 2) as int) >> cover_shift);
      cg = green0To255 + (((c.green0To255 * cover + cover_mask / 2) as int) >> cover_shift);
      cb = blue0To255 + (((c.blue0To255 * cover + cover_mask / 2) as int) >> cover_shift);
      ca = alpha0To255 + (((c.alpha0To255 * cover + cover_mask / 2) as int) >> cover_shift);
      red0To255 = (cr > (base_mask)) ? (base_mask) : cr;
      green0To255 = (cg > (base_mask)) ? (base_mask) : cg;
      blue0To255 = (cb > (base_mask)) ? (base_mask) : cb;
      alpha0To255 = (ca > (base_mask)) ? (base_mask) : ca;
    }
  }

  /*void apply_gamma_dir(GammaLookUpTable gamma)
		{
			Red0To255 = gamma.dir((byte)Red0To255);
			Green0To255 = gamma.dir((byte)Green0To255);
			Blue0To255 = gamma.dir((byte)Blue0To255);
		}*/

  static IColorType no_color() {
    return new Color.fromRGBA(0, 0, 0, 0);
  }

  static Color rgb8_packed(int v) {
    return new Color.fromRGB((v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF);
  }

  Color blend(Color other, double weight) {
    var result = new Color.fromColor(this);
    result = this * (1 - weight) + other * weight;
    return result;
  }

  @override
  ColorF toColorF() {
    throw UnimplementedError();
    /* 
    return new ColorF((float)red / (float)base_mask, (float)green / (float)base_mask, (float)blue / (float)base_mask, (float)alpha / (float)base_mask);
    }*/
  }

  Color blendHsl(Color b, double rationB) {
    throw UnimplementedError();
    /*double aH, aS, aL;
			new ColorF(this).getHSL(out aH, out aS, out aL);
			double bH, bS, bL;
			new ColorF(b).getHSL(out bH, out bS, out bL);

			return ColorF.fromHSL(
				aH * (1 - rationB) + bH * rationB,
				aS * (1 - rationB) + bS * rationB,
				aL * (1 - rationB) + bL * rationB).ToColor();*/
  }
}
