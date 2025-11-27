import 'dart:typed_data';

class Util {
  static void memClear(Uint8List dest, int destIndex, int count) {
    dest.fillRange(destIndex, destIndex + count, 0);
  }

  static void memset(Uint8List dest, int destIndex, int value, int count) {
    dest.fillRange(destIndex, destIndex + count, value);
  }

  static int uround(double v) {
    return (v + 0.5).toInt();
  }

  static int iround(double v) {
    return ((v < 0.0) ? v - 0.5 : v + 0.5).toInt();
  }

  static int uceil(double v) {
    return v.ceil();
  }
}

class BoxInt {
  int value;
  BoxInt(this.value);
}
