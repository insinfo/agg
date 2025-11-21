import 'dart:typed_data';
import 'iimage.dart';

abstract class IImageFloat extends IImage {
  Float32List getBuffer();
  int getFloatsBetweenPixelsInclusive();
}
