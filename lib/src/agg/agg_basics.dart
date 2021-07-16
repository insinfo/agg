//----------------------------------------------------------filling_rule_e
import 'dart:typed_data';

import 'package:agg/src/shared/ref_param.dart';
import 'dart:math' as math;

enum filling_rule_e { fill_non_zero, fill_even_odd }

class Agg_basics {
  static void memcpy(Uint8List dest, int destIndex, Uint8List source, int sourceIndex, int count) {
    for (int i = 0; i < count; i++) {
      dest[destIndex + i] = source[sourceIndex + i];
    }
  }

  // private static Regex numberRegex = new Regex(@"[-+]?[0-9]*\.?[0-9]+");
  static RegExp numberRegex = new RegExp(r"[-+]?[0-9]*\.?[0-9]+([eE][-+]?[0-9]+)?");

  static double getNextNumber(String source, RefParam<int> startIndex) {
    /*
    Match numberMatch = numberRegex.Match(source, startIndex);
    string returnString = numberMatch.Value;
    startIndex = numberMatch.Index + numberMatch.Length;
    double returnVal;
    double.TryParse(returnString, NumberStyles.Number, CultureInfo.InvariantCulture, out returnVal);
    return returnVal;
      */
    Match numberMatch = numberRegex.matchAsPrefix(source, startIndex.value);
    String returnString = numberMatch.group(0);
    startIndex.value = numberMatch.start + numberMatch.end;
    return double.tryParse(returnString);
  }

  static int clamp(int value, int min, int max, [RefParam<bool> changed]) {
    min = math.min(min, max);

    if (value < min) {
      value = min;
      changed?.value = true;
    }

    if (value > max) {
      value = max;
      changed?.value = true;
    }

    return value;
  }

  static double clampF(double value, double min, double max, [RefParam<bool> changed]) {
    min = math.min(min, max);

    if (value < min) {
      value = min;
      changed?.value = true;
    }

    if (value > max) {
      value = max;
      changed?.value = true;
    }

    return value;
  }

  static Uint8List getBytes(String str) {
    //Uint8List bytes = new Uint8List.[str.length * sizeof(char)];
    //str.split('')
    //str.runes

    //System.Buffer.BlockCopy(str., 0, bytes, 0, bytes.Length);
    return str.codeUnits;
  }

  static bool is_equal_eps(double v1, double v2, double epsilon) {
    return (v1 - v2).abs() <= epsilon;
  }

  //------------------------------------------------------------------deg2rad
  static double deg2rad(double deg) {
    return deg * math.pi / 180.0;
  }

  //------------------------------------------------------------------rad2deg
  static double rad2deg(double rad) {
    return rad * 180.0 / math.pi;
  }

  static int iround(double v) {
    return ((v < 0.0) ? v - 0.5 : v + 0.5) as int;
  }

  static int iround2(double v, int saturationLimit) {
    if (v < (-saturationLimit as double)) {
      return -saturationLimit;
    }

    if (v > (saturationLimit as double)) {
      return saturationLimit;
    }

    return iround(v);
  }

  static int uround(double v) {
    return (v + 0.5) as int;
  }

  static int ufloor(double v) {
    return v as int;
  }

  static int uceil(double v) {
    return v.ceil();
  }
}
