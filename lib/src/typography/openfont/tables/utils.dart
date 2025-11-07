// Apache2, 2017-present, WinterDev
// Ported to Dart by insinfo

import 'dart:typed_data';
import 'dart:convert';
import '../../../typography/io/byte_order_swapping_reader.dart';

/// Utility functions for reading OpenType font data
class Utils {
  /// Read float in 2.14 format
  /// This is a fixed-point format with 2 bits for the integer part
  /// and 14 bits for the fractional part
  static double readF2Dot14(ByteOrderSwappingBinaryReader reader) {
    return reader.readInt16() / (1 << 14); // Format 2.14
  }

  /// Read float in 16.16 format (Fixed)
  /// This is a fixed-point format with 16 bits for the integer part
  /// and 16 bits for the fractional part
  static double readFixed(ByteOrderSwappingBinaryReader reader) {
    return reader.readUInt32() / (1 << 16); // Format 16.16
  }

  /// Read a 24-bit unsigned integer
  static int readUInt24(ByteOrderSwappingBinaryReader reader) {
    final highByte = reader.readByte();
    return (highByte << 16) | reader.readUInt16();
  }

  /// Convert a 4-byte tag (as uint32) to a string
  static String tagToString(int tag) {
    final bytes = Uint8List(4);
    bytes[0] = (tag >> 24) & 0xFF;
    bytes[1] = (tag >> 16) & 0xFF;
    bytes[2] = (tag >> 8) & 0xFF;
    bytes[3] = tag & 0xFF;
    return utf8.decode(bytes);
  }

  /// Read an array of unsigned 16-bit integers
  static List<int> readUInt16Array(ByteOrderSwappingBinaryReader reader, int count) {
    final arr = <int>[];
    for (var i = 0; i < count; i++) {
      arr.add(reader.readUInt16());
    }
    return arr;
  }

  /// Read an array of unsigned 32-bit integers
  static List<int> readUInt32Array(ByteOrderSwappingBinaryReader reader, int count) {
    final arr = <int>[];
    for (var i = 0; i < count; i++) {
      arr.add(reader.readUInt32());
    }
    return arr;
  }

  /// Clone an array with optional extension
  static List<T> cloneArray<T>(List<T> original, [int newArrLenExtend = 0]) {
    final newClone = List<T>.filled(original.length + newArrLenExtend, original[0]);
    for (var i = 0; i < original.length; i++) {
      newClone[i] = original[i];
    }
    return newClone;
  }

  /// Concatenate two arrays
  static List<T> concatArray<T>(List<T> arr1, List<T> arr2) {
    return [...arr1, ...arr2];
  }

  /// Warn about unimplemented features (for debugging)
  static void warnUnimplemented(String message) {
    // In debug mode, print warning
    assert(() {
      print('!STUB! $message');
      return true;
    }());
  }
}

/// Represents the bounding box of a glyph or font
class Bounds {
  final int xMin;
  final int yMin;
  final int xMax;
  final int yMax;

  const Bounds(this.xMin, this.yMin, this.xMax, this.yMax);
  
  /// Empty bounds
  static const zero = Bounds(0, 0, 0, 0);

  /// Read bounds from a binary reader
  static Bounds read(ByteOrderSwappingBinaryReader reader) {
    return Bounds(
      reader.readInt16(), // xMin
      reader.readInt16(), // yMin
      reader.readInt16(), // xMax
      reader.readInt16(), // yMax
    );
  }

  int get width => xMax - xMin;
  int get height => yMax - yMin;

  @override
  String toString() => 'Bounds($xMin, $yMin, $xMax, $yMax)';
}
