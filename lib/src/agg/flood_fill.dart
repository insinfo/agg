import 'dart:collection';
import 'dart:typed_data';

import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/color.dart';

class FloodFill {
  Uint8List? destBuffer;
  int imageStride = 0;
  List<bool>? pixelsChecked;
  ImageBuffer? destImage;
  late FillingRule fillRule;
  final Queue<Range> ranges = Queue<Range>();

  FloodFill(Color fillColor) {
    fillRule = ExactMatch(fillColor);
  }

  FloodFill.withTolerance(Color fillColor, int tolerance0To255) {
    if (tolerance0To255 > 0) {
      fillRule = ToleranceMatch(fillColor, tolerance0To255);
    } else {
      fillRule = ExactMatch(fillColor);
    }
  }

  FloodFill.withRule(this.fillRule);

  void fill(ImageBuffer bufferToFillOn, int x, int y) {
    if (x < 0 || x >= bufferToFillOn.width || y < 0 || y >= bufferToFillOn.height) {
      return;
    }

    destImage = bufferToFillOn;
    imageStride = destImage!.strideInBytes();
    destBuffer = destImage!.getBuffer();
    int imageWidth = destImage!.width;
    int imageHeight = destImage!.height;

    pixelsChecked = List<bool>.filled(destImage!.width * destImage!.height, false);

    int startColorBufferOffset = destImage!.getBufferOffsetXY(x, y);

    // Assuming RGBA order as per BlenderRgba
    fillRule.setStartColor(Color.fromRgba(
      destBuffer![startColorBufferOffset],
      destBuffer![startColorBufferOffset + 1],
      destBuffer![startColorBufferOffset + 2],
      destBuffer![startColorBufferOffset + 3],
    ));

    linearFill(x, y);

    while (ranges.isNotEmpty) {
      Range range = ranges.removeFirst();

      int downY = range.y - 1;
      int upY = range.y + 1;
      int downPixelOffset = (imageWidth * (range.y - 1)) + range.startX;
      int upPixelOffset = (imageWidth * (range.y + 1)) + range.startX;
      
      for (int rangeX = range.startX; rangeX <= range.endX; rangeX++) {
        if (range.y > 0) {
          if (!pixelsChecked![downPixelOffset]) {
            int bufferOffset = destImage!.getBufferOffsetXY(rangeX, downY);
            if (fillRule.checkPixel(destBuffer!, bufferOffset)) {
              linearFill(rangeX, downY);
            }
          }
        }

        if (range.y < (imageHeight - 1)) {
          if (!pixelsChecked![upPixelOffset]) {
            int bufferOffset = destImage!.getBufferOffsetXY(rangeX, upY);
            if (fillRule.checkPixel(destBuffer!, bufferOffset)) {
              linearFill(rangeX, upY);
            }
          }
        }
        upPixelOffset++;
        downPixelOffset++;
      }
    }
  }

  void linearFill(int x, int y) {
    int bytesPerPixel = destImage!.getBytesBetweenPixelsInclusive();
    int imageWidth = destImage!.width;

    int leftFillX = x;
    int bufferOffset = destImage!.getBufferOffsetXY(x, y);
    int pixelOffset = (imageWidth * y) + x;
    
    while (true) {
      fillRule.setPixel(destBuffer!, bufferOffset);
      pixelsChecked![pixelOffset] = true;
      leftFillX--;
      pixelOffset--;
      bufferOffset -= bytesPerPixel;
      
      if (leftFillX < 0 || (pixelsChecked![pixelOffset]) || !fillRule.checkPixel(destBuffer!, bufferOffset)) {
        break;
      }
    }
    leftFillX++;

    int rightFillX = x;
    bufferOffset = destImage!.getBufferOffsetXY(x, y);
    pixelOffset = (imageWidth * y) + x;
    
    while (true) {
      fillRule.setPixel(destBuffer!, bufferOffset);
      pixelsChecked![pixelOffset] = true;
      rightFillX++;
      pixelOffset++;
      bufferOffset += bytesPerPixel;
      
      if (rightFillX >= imageWidth || pixelsChecked![pixelOffset] || !fillRule.checkPixel(destBuffer!, bufferOffset)) {
        break;
      }
    }
    rightFillX--;

    ranges.add(Range(leftFillX, rightFillX, y));
  }
}

class Range {
  int endX;
  int startX;
  int y;

  Range(this.startX, this.endX, this.y);
}

abstract class FillingRule {
  Color fillColor;
  Color startColor = Color(0, 0, 0);

  FillingRule(this.fillColor);

  bool checkPixel(Uint8List destBuffer, int bufferOffset);

  void setPixel(Uint8List destBuffer, int bufferOffset) {
    // RGBA order
    destBuffer[bufferOffset] = fillColor.red;
    destBuffer[bufferOffset + 1] = fillColor.green;
    destBuffer[bufferOffset + 2] = fillColor.blue;
    destBuffer[bufferOffset + 3] = fillColor.alpha;
  }

  void setStartColor(Color startColor) {
    this.startColor = startColor;
  }
}

class ExactMatch extends FillingRule {
  ExactMatch(Color fillColor) : super(fillColor);

  @override
  bool checkPixel(Uint8List destBuffer, int bufferOffset) {
    // RGBA order
    return (destBuffer[bufferOffset] == startColor.red) &&
        (destBuffer[bufferOffset + 1] == startColor.green) &&
        (destBuffer[bufferOffset + 2] == startColor.blue) &&
        (destBuffer[bufferOffset + 3] == startColor.alpha);
  }
}

class ToleranceMatch extends FillingRule {
  int tolerance0To255;

  ToleranceMatch(Color fillColor, this.tolerance0To255) : super(fillColor);

  @override
  bool checkPixel(Uint8List destBuffer, int bufferOffset) {
    // RGBA order
    return (destBuffer[bufferOffset] >= (startColor.red - tolerance0To255)) &&
        (destBuffer[bufferOffset] <= (startColor.red + tolerance0To255)) &&
        (destBuffer[bufferOffset + 1] >= (startColor.green - tolerance0To255)) &&
        (destBuffer[bufferOffset + 1] <= (startColor.green + tolerance0To255)) &&
        (destBuffer[bufferOffset + 2] >= (startColor.blue - tolerance0To255)) &&
        (destBuffer[bufferOffset + 2] <= (startColor.blue + tolerance0To255)) &&
        (destBuffer[bufferOffset + 3] >= (startColor.alpha - tolerance0To255)) &&
        (destBuffer[bufferOffset + 3] <= (startColor.alpha + tolerance0To255));
  }
}
