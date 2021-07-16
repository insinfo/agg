import 'package:agg/src/agg/agg_basics.dart';
import 'package:agg/src/agg/interfaces/icolor_type.dart';
import 'dart:math' as math;

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

  static final Color black = new Color(0, 0, 0);
  static final Color blueS = new Color.fromHex("#0000FF");
  static final Color crimson = new Color.fromHex("#DC143C");
  static final Color cyan = new Color(0, 255, 255);
  static final Color darkBlue = new Color.fromHex("#0000A0");
  static final Color darkGray = new Color(85, 85, 85);
  static final Color fireEngineRed = new Color.fromHex("#F62817");
  static final Color gray = new Color(125, 125, 125);
  static final Color greenS = new Color(0, 255, 0);
  static final Color indigo = new Color(75, 0, 130);
  static final Color lightBlue = new Color.fromHex("#ADD8E6");
  static final Color lightGray = new Color(225, 225, 225);
  static final Color magenta = new Color(255, 0, 255);
  static final Color orange = new Color(255, 127, 0);
  static final Color pink = new Color(255, 192, 203);
  static final Color redS = new Color(255, 0, 0);
  static final Color transparent = new Color.withAlpha(0, 0, 0, 0);
  static final Color violet = new Color(143, 0, 255);
  static final Color white = new Color(255, 255, 255);
  static final Color yellow = new Color(255, 255, 0);
  static final Color yellowGreen = new Color(154, 205, 50);

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

  Color.fromHex(String htmlString) {
    html = htmlString;
  }

  Color(int r_, int g_, int b_) {
    Color.withAlpha(r_, g_, b_, base_mask);
  }

  Color.withAlpha(int r_, int g_, int b_, int a_) {
    red = math.min(math.max(r_, 0), 255);
    green = math.min(math.max(g_, 0), 255);
    blue = math.min(math.max(b_, 0), 255);
    alpha = math.min(math.max(a_, 0), 255);
  }

  Color.withAlphaF(double r_, double g_, double b_, double a_) {
    red = (Agg_basics.uround(r_ * base_mask));
    green = (Agg_basics.uround(g_ * base_mask));
    blue = (Agg_basics.uround(b_ * base_mask));
    alpha = (Agg_basics.uround(a_ * base_mask));
  }
}
