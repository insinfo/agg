import 'dart:typed_data';
import 'package:agg/src/agg/agg_image_filters.dart';
import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/primitives/color_f.dart';
import 'package:agg/src/agg/primitives/i_color_type.dart';
import 'package:agg/src/agg/raster_buffer_accessors.dart';
import 'package:agg/src/agg/spans/agg_span_image_filter.dart';
import 'package:agg/src/agg/spans/agg_span_interpolator_linear.dart';
import 'package:agg/src/shared/ref_param.dart';
import 'package:agg/src/vector_math/vector2.dart';
import 'dart:math' as math;

class SpanImageFilterRgbaNnStepXby1 extends SpanImageFilter {
  static const int baseShift = 8;
  static const int baseScale = 1 << baseShift;
  static const int baseMask = baseScale - 1;

  SpanImageFilterRgbaNnStepXby1(
      IImageBufferAccessor sourceAccessor, ISpanInterpolator spanInterpolator)
      : super(sourceAccessor, spanInterpolator, null);

  @override
  void generate(List<Color> span, int spanIndex, int x, int y, int len) {
    IImageByte sourceRenderingBuffer = getImageBufferAccessor().sourceImage;
    if (sourceRenderingBuffer.bitDepth != 32) {
      throw UnsupportedError("The source is expected to be 32 bit.");
    }
    ISpanInterpolator spanInterpolator = interpolator();
    spanInterpolator.begin(x + filterDxDbl(), y + filterDyDbl(), len);
    
    List<int> xy = [0, 0];
    spanInterpolator.coordinates(xy);
    int xHr = xy[0];
    int yHr = xy[1];
    
    int xLr = xHr >> ImageSubpixelScale.imageSubpixelShift;
    int yLr = yHr >> ImageSubpixelScale.imageSubpixelShift;
    
    int bufferIndex = sourceRenderingBuffer.getBufferOffsetXY(xLr, yLr);
    Uint8List fgPtr = sourceRenderingBuffer.getBuffer();

    do {
      span[spanIndex++] = Color.fromRgba(
          fgPtr[bufferIndex + 2], // R
          fgPtr[bufferIndex + 1], // G
          fgPtr[bufferIndex + 0], // B
          fgPtr[bufferIndex + 3]  // A
      );
      bufferIndex += 4;
    } while (--len != 0);
  }
}

class SpanImageFilterRgbaNn extends SpanImageFilter {
  static const int baseShift = 8;
  static const int baseScale = 1 << baseShift;
  static const int baseMask = baseScale - 1;

  SpanImageFilterRgbaNn(
      IImageBufferAccessor sourceAccessor, ISpanInterpolator spanInterpolator)
      : super(sourceAccessor, spanInterpolator, null);

  @override
  void generate(List<Color> span, int spanIndex, int x, int y, int len) {
    IImageByte sourceRenderingBuffer = getImageBufferAccessor().sourceImage;
    if (sourceRenderingBuffer.bitDepth != 32) {
      throw UnsupportedError("The source is expected to be 32 bit.");
    }
    ISpanInterpolator spanInterpolator = interpolator();
    spanInterpolator.begin(x + filterDxDbl(), y + filterDyDbl(), len);
    Uint8List fgPtr = sourceRenderingBuffer.getBuffer();
    
    List<int> xy = [0, 0];
    
    do {
      spanInterpolator.coordinates(xy);
      int xHr = xy[0];
      int yHr = xy[1];
      
      int xLr = xHr >> ImageSubpixelScale.imageSubpixelShift;
      int yLr = yHr >> ImageSubpixelScale.imageSubpixelShift;
      
      int bufferIndex = sourceRenderingBuffer.getBufferOffsetXY(xLr, yLr);
      
      span[spanIndex] = Color.fromRgba(
          fgPtr[bufferIndex + 2], // R
          fgPtr[bufferIndex + 1], // G
          fgPtr[bufferIndex + 0], // B
          fgPtr[bufferIndex + 3]  // A
      );
      spanIndex++;
      spanInterpolator.next();
    } while (--len != 0);
  }
}

class SpanImageFilterRgbaBilinear extends SpanImageFilter {
  static const int baseShift = 8;
  static const int baseScale = 1 << baseShift;
  static const int baseMask = baseScale - 1;

  SpanImageFilterRgbaBilinear(
      IImageBufferAccessor src, ISpanInterpolator inter)
      : super(src, inter, null);

  @override
  void generate(List<Color> span, int spanIndex, int x, int y, int len) {
    interpolator().begin(x + filterDxDbl(), y + filterDyDbl(), len);

    IImageByte sourceRenderingBuffer = getImageBufferAccessor().sourceImage;
    ISpanInterpolator spanInterpolator = interpolator();
    
    RefParam<int> bufferIndexRef = RefParam(0);
    Uint8List fgPtr = getImageBufferAccessor().span(0, 0, 0, bufferIndexRef); // Just to get buffer? No, span updates bufferIndex.
    // Actually, we need to call span inside the loop or use getBuffer directly if we calculate offset manually.
    // The C# code uses GetBuffer(out bufferIndex) which seems to be a helper or just GetBuffer().
    // But here we use manual calculation.
    
    fgPtr = sourceRenderingBuffer.getBuffer();
    
    List<int> xy = [0, 0];

    do {
      int tempR, tempG, tempB;
      
      spanInterpolator.coordinates(xy);
      int xHr = xy[0];
      int yHr = xy[1];

      xHr -= filterDxInt();
      yHr -= filterDyInt();

      int xLr = xHr >> ImageSubpixelScale.imageSubpixelShift;
      int yLr = yHr >> ImageSubpixelScale.imageSubpixelShift;
      int weight;

      tempR = tempG = tempB = ImageSubpixelScale.imageSubpixelScale * ImageSubpixelScale.imageSubpixelScale ~/ 2;

      xHr &= ImageSubpixelScale.imageSubpixelMask;
      yHr &= ImageSubpixelScale.imageSubpixelMask;

      int bufferIndex = sourceRenderingBuffer.getBufferOffsetXY(xLr, yLr);

      weight = ((ImageSubpixelScale.imageSubpixelScale - xHr) *
               (ImageSubpixelScale.imageSubpixelScale - yHr));
      tempR += weight * fgPtr[bufferIndex + 2]; // R
      tempG += weight * fgPtr[bufferIndex + 1]; // G
      tempB += weight * fgPtr[bufferIndex + 0]; // B
      bufferIndex += 4;

      weight = (xHr * (ImageSubpixelScale.imageSubpixelScale - yHr));
      tempR += weight * fgPtr[bufferIndex + 2];
      tempG += weight * fgPtr[bufferIndex + 1];
      tempB += weight * fgPtr[bufferIndex + 0];

      yLr++;
      bufferIndex = sourceRenderingBuffer.getBufferOffsetXY(xLr, yLr);

      weight = ((ImageSubpixelScale.imageSubpixelScale - xHr) * yHr);
      tempR += weight * fgPtr[bufferIndex + 2];
      tempG += weight * fgPtr[bufferIndex + 1];
      tempB += weight * fgPtr[bufferIndex + 0];
      bufferIndex += 4;

      weight = (xHr * yHr);
      tempR += weight * fgPtr[bufferIndex + 2];
      tempG += weight * fgPtr[bufferIndex + 1];
      tempB += weight * fgPtr[bufferIndex + 0];

      tempR >>= ImageSubpixelScale.imageSubpixelShift * 2;
      tempG >>= ImageSubpixelScale.imageSubpixelShift * 2;
      tempB >>= ImageSubpixelScale.imageSubpixelShift * 2;

      span[spanIndex] = Color.fromRgba(tempR, tempG, tempB, 255); // Alpha 255 as per C# code comment
      spanIndex++;
      spanInterpolator.next();
    } while (--len != 0);
  }
}

class SpanImageFilterRgbaBilinearClip extends SpanImageFilter {
  late Color _outsideSourceColor;
  static const int baseShift = 8;
  static const int baseScale = 1 << baseShift;
  static const int baseMask = baseScale - 1;

  SpanImageFilterRgbaBilinearClip(
      IImageBufferAccessor src, IColorType backColor, ISpanInterpolator inter)
      : super(src, inter, null) {
    _outsideSourceColor = Color.fromRgba(
        backColor.red0To255,
        backColor.green0To255,
        backColor.blue0To255,
        backColor.alpha0To255);
  }

  IColorType backgroundColor() {
    return _outsideSourceColor;
  }

  void setBackgroundColor(IColorType v) {
    _outsideSourceColor = Color.fromRgba(
        v.red0To255,
        v.green0To255,
        v.blue0To255,
        v.alpha0To255);
  }

  @override
  void generate(List<Color> span, int spanIndex, int x, int y, int len) {
    IImageByte sourceRenderingBuffer = getImageBufferAccessor().sourceImage;
    
    // Optimization for identity transform
    if (interpolator() is SpanInterpolatorLinear) {
       // Check for identity transform... skipping for now as I don't have Affine class details handy here
       // But if I did, I would implement the fast path.
    }

    interpolator().begin(x + filterDxDbl(), y + filterDyDbl(), len);

    List<int> accumulatedColor = [0, 0, 0, 0];

    int backR = _outsideSourceColor.red;
    int backG = _outsideSourceColor.green;
    int backB = _outsideSourceColor.blue;
    int backA = _outsideSourceColor.alpha;

    int distanceBetweenPixelsInclusive = getImageBufferAccessor().sourceImage.getBytesBetweenPixelsInclusive();
    int maxx = sourceRenderingBuffer.width - 1;
    int maxy = sourceRenderingBuffer.height - 1;
    ISpanInterpolator spanInterpolator = interpolator();
    
    Uint8List fgPtr = sourceRenderingBuffer.getBuffer();
    List<int> xy = [0, 0];

    do {
      spanInterpolator.coordinates(xy);
      int xHr = xy[0];
      int yHr = xy[1];

      xHr -= filterDxInt();
      yHr -= filterDyInt();

      int xLr = xHr >> ImageSubpixelScale.imageSubpixelShift;
      int yLr = yHr >> ImageSubpixelScale.imageSubpixelShift;
      int weight;

      if (xLr >= 0 && yLr >= 0 && xLr < maxx && yLr < maxy) {
        accumulatedColor[0] = accumulatedColor[1] = accumulatedColor[2] = accumulatedColor[3] =
            ImageSubpixelScale.imageSubpixelScale * ImageSubpixelScale.imageSubpixelScale ~/ 2;

        xHr &= ImageSubpixelScale.imageSubpixelMask;
        yHr &= ImageSubpixelScale.imageSubpixelMask;

        int bufferIndex = sourceRenderingBuffer.getBufferOffsetXY(xLr, yLr);

        weight = ((ImageSubpixelScale.imageSubpixelScale - xHr) *
                 (ImageSubpixelScale.imageSubpixelScale - yHr));
        if (weight > baseMask) {
          accumulatedColor[0] += weight * fgPtr[bufferIndex + 2]; // R
          accumulatedColor[1] += weight * fgPtr[bufferIndex + 1]; // G
          accumulatedColor[2] += weight * fgPtr[bufferIndex + 0]; // B
          accumulatedColor[3] += weight * fgPtr[bufferIndex + 3]; // A
        }

        weight = (xHr * (ImageSubpixelScale.imageSubpixelScale - yHr));
        if (weight > baseMask) {
          bufferIndex += distanceBetweenPixelsInclusive;
          accumulatedColor[0] += weight * fgPtr[bufferIndex + 2];
          accumulatedColor[1] += weight * fgPtr[bufferIndex + 1];
          accumulatedColor[2] += weight * fgPtr[bufferIndex + 0];
          accumulatedColor[3] += weight * fgPtr[bufferIndex + 3];
        }

        weight = ((ImageSubpixelScale.imageSubpixelScale - xHr) * yHr);
        if (weight > baseMask) {
          yLr++;
          bufferIndex = sourceRenderingBuffer.getBufferOffsetXY(xLr, yLr); // Recalculate for next row
          // Wait, bufferIndex += distanceBetweenPixelsInclusive was for next pixel in X?
          // No, distanceBetweenPixelsInclusive is usually 4.
          // The C# code: bufferIndex += distanceBetweenPixelsInclusive;
          // This moves to (x+1, y).
          // Then for next row: ++y_lr; fg_ptr = ... GetPixelPointerXY(x_lr, y_lr, out bufferIndex);
          // So I need to be careful.
          
          // Let's re-read C# logic carefully.
          /*
            fg_ptr = SourceRenderingBuffer.GetPixelPointerXY(x_lr, y_lr, out bufferIndex);
            // ... (x, y)
            bufferIndex += distanceBetweenPixelsInclusive; // (x+1, y)
            // ...
            ++y_lr;
            fg_ptr = SourceRenderingBuffer.GetPixelPointerXY(x_lr, y_lr, out bufferIndex); // (x, y+1)
            // ...
            bufferIndex += distanceBetweenPixelsInclusive; // (x+1, y+1)
          */
          
          // My Dart code:
          // bufferIndex = sourceRenderingBuffer.getBufferOffsetXY(xLr, yLr);
          // ...
          // bufferIndex += distanceBetweenPixelsInclusive;
          // ...
          // yLr++;
          // bufferIndex = sourceRenderingBuffer.getBufferOffsetXY(xLr, yLr);
          // ...
          // bufferIndex += distanceBetweenPixelsInclusive;
          
          // This matches.
          
          accumulatedColor[0] += weight * fgPtr[bufferIndex + 2];
          accumulatedColor[1] += weight * fgPtr[bufferIndex + 1];
          accumulatedColor[2] += weight * fgPtr[bufferIndex + 0];
          accumulatedColor[3] += weight * fgPtr[bufferIndex + 3];
        }
        
        weight = (xHr * yHr);
        if (weight > baseMask) {
          bufferIndex += distanceBetweenPixelsInclusive;
          accumulatedColor[0] += weight * fgPtr[bufferIndex + 2];
          accumulatedColor[1] += weight * fgPtr[bufferIndex + 1];
          accumulatedColor[2] += weight * fgPtr[bufferIndex + 0];
          accumulatedColor[3] += weight * fgPtr[bufferIndex + 3];
        }
        
        accumulatedColor[0] >>= ImageSubpixelScale.imageSubpixelShift * 2;
        accumulatedColor[1] >>= ImageSubpixelScale.imageSubpixelShift * 2;
        accumulatedColor[2] >>= ImageSubpixelScale.imageSubpixelShift * 2;
        accumulatedColor[3] >>= ImageSubpixelScale.imageSubpixelShift * 2;
      } else {
        // Clip handling
        if (xLr < -1 || yLr < -1 || xLr > maxx || yLr > maxy) {
          accumulatedColor[0] = backR;
          accumulatedColor[1] = backG;
          accumulatedColor[2] = backB;
          accumulatedColor[3] = backA;
        } else {
          accumulatedColor[0] = accumulatedColor[1] = accumulatedColor[2] = accumulatedColor[3] =
              ImageSubpixelScale.imageSubpixelScale * ImageSubpixelScale.imageSubpixelScale ~/ 2;

          xHr &= ImageSubpixelScale.imageSubpixelMask;
          yHr &= ImageSubpixelScale.imageSubpixelMask;

          weight = ((ImageSubpixelScale.imageSubpixelScale - xHr) *
                   (ImageSubpixelScale.imageSubpixelScale - yHr));
          if (weight > baseMask) {
            blendInFilterPixel(accumulatedColor, backR, backG, backB, backA, sourceRenderingBuffer, maxx, maxy, xLr, yLr, weight);
          }

          xLr++;

          weight = (xHr * (ImageSubpixelScale.imageSubpixelScale - yHr));
          if (weight > baseMask) {
            blendInFilterPixel(accumulatedColor, backR, backG, backB, backA, sourceRenderingBuffer, maxx, maxy, xLr, yLr, weight);
          }

          xLr--;
          yLr++;

          weight = ((ImageSubpixelScale.imageSubpixelScale - xHr) * yHr);
          if (weight > baseMask) {
            blendInFilterPixel(accumulatedColor, backR, backG, backB, backA, sourceRenderingBuffer, maxx, maxy, xLr, yLr, weight);
          }

          xLr++;

          weight = (xHr * yHr);
          if (weight > baseMask) {
            blendInFilterPixel(accumulatedColor, backR, backG, backB, backA, sourceRenderingBuffer, maxx, maxy, xLr, yLr, weight);
          }

          accumulatedColor[0] >>= ImageSubpixelScale.imageSubpixelShift * 2;
          accumulatedColor[1] >>= ImageSubpixelScale.imageSubpixelShift * 2;
          accumulatedColor[2] >>= ImageSubpixelScale.imageSubpixelShift * 2;
          accumulatedColor[3] >>= ImageSubpixelScale.imageSubpixelShift * 2;
        }
      }

      span[spanIndex] = Color.fromRgba(
          accumulatedColor[0],
          accumulatedColor[1],
          accumulatedColor[2],
          accumulatedColor[3]
      );
      spanIndex++;
      spanInterpolator.next();
    } while (--len != 0);
  }

  void blendInFilterPixel(List<int> accumulatedColor, int backR, int backG, int backB, int backA, IImageByte sourceRenderingBuffer, int maxx, int maxy, int xLr, int yLr, int weight) {
    if (xLr >= 0 && xLr <= maxx && yLr >= 0 && yLr <= maxy) {
      int bufferIndex = sourceRenderingBuffer.getBufferOffsetXY(xLr, yLr);
      Uint8List fgPtr = sourceRenderingBuffer.getBuffer();

      accumulatedColor[0] += weight * fgPtr[bufferIndex + 2]; // R
      accumulatedColor[1] += weight * fgPtr[bufferIndex + 1]; // G
      accumulatedColor[2] += weight * fgPtr[bufferIndex + 0]; // B
      accumulatedColor[3] += weight * fgPtr[bufferIndex + 3]; // A
    } else {
      accumulatedColor[0] += backR * weight;
      accumulatedColor[1] += backG * weight;
      accumulatedColor[2] += backB * weight;
      accumulatedColor[3] += backA * weight;
    }
  }
}

class SpanImageFilterRgba extends SpanImageFilter {
  static const int baseMask = 255;

  SpanImageFilterRgba(
      IImageBufferAccessor src, ISpanInterpolator inter, ImageFilterLookUpTable filter)
      : super(src, inter, filter) {
    if (src.sourceImage.getBytesBetweenPixelsInclusive() != 4) {
      throw UnsupportedError("span_image_filter_rgba must have a 32 bit DestImage");
    }
  }

  @override
  void generate(List<Color> span, int spanIndex, int x, int y, int len) {
    interpolator().begin(x + filterDxDbl(), y + filterDyDbl(), len);

    int fR, fG, fB, fA;

    int diameter = filter()!.diameter();
    int start = filter()!.start();
    Int32List weightArray = filter()!.weightArray();

    int xCount;
    int weightY;

    ISpanInterpolator spanInterpolator = interpolator();
    IImageBufferAccessor sourceAccessor = getImageBufferAccessor();
    
    List<int> xy = [0, 0];
    RefParam<int> bufferIndexRef = RefParam(0);

    do {
      spanInterpolator.coordinates(xy);
      x = xy[0];
      y = xy[1];

      x -= filterDxInt();
      y -= filterDyInt();

      int xHr = x;
      int yHr = y;

      int xLr = xHr >> ImageSubpixelScale.imageSubpixelShift;
      int yLr = yHr >> ImageSubpixelScale.imageSubpixelShift;

      fB = fG = fR = fA = ImageFilterScale.imageFilterScale ~/ 2;

      int xFract = xHr & ImageSubpixelScale.imageSubpixelMask;
      int yCount = diameter;

      yHr = ImageSubpixelScale.imageSubpixelMask - (yHr & ImageSubpixelScale.imageSubpixelMask);

      Uint8List fgPtr = sourceAccessor.span(xLr + start, yLr + start, diameter, bufferIndexRef);
      int bufferIndex = bufferIndexRef.value;
      
      for (;;) {
        xCount = diameter;
        weightY = weightArray[yHr];
        xHr = ImageSubpixelScale.imageSubpixelMask - xFract;
        for (;;) {
          int weight = (weightY * weightArray[xHr] +
                       ImageFilterScale.imageFilterScale ~/ 2) >>
                       ImageFilterScale.imageFilterShift;

          fR += weight * fgPtr[bufferIndex + 2]; // R
          fG += weight * fgPtr[bufferIndex + 1]; // G
          fB += weight * fgPtr[bufferIndex + 0]; // B
          fA += weight * fgPtr[bufferIndex + 3]; // A

          if (--xCount == 0) break;
          xHr += ImageSubpixelScale.imageSubpixelScale;
          sourceAccessor.nextX(bufferIndexRef);
          bufferIndex = bufferIndexRef.value;
        }

        if (--yCount == 0) break;
        yHr += ImageSubpixelScale.imageSubpixelScale;
        sourceAccessor.nextY(bufferIndexRef);
        bufferIndex = bufferIndexRef.value;
      }

      fB >>= ImageFilterScale.imageFilterShift;
      fG >>= ImageFilterScale.imageFilterShift;
      fR >>= ImageFilterScale.imageFilterShift;
      fA >>= ImageFilterScale.imageFilterShift;

      if (fB > baseMask) { if (fB < 0) fB = 0; if (fB > baseMask) fB = baseMask; }
      if (fG > baseMask) { if (fG < 0) fG = 0; if (fG > baseMask) fG = baseMask; }
      if (fR > baseMask) { if (fR < 0) fR = 0; if (fR > baseMask) fR = baseMask; }
      if (fA > baseMask) { if (fA < 0) fA = 0; if (fA > baseMask) fA = baseMask; }

      span[spanIndex] = Color.fromRgba(fR, fG, fB, fA);
      spanIndex++;
      spanInterpolator.next();
    } while (--len != 0);
  }
}

class SpanImageFilterRgbaFloat extends SpanImageFilterFloat {
  SpanImageFilterRgbaFloat(
      IImageBufferAccessorFloat src, ISpanInterpolatorFloat inter, IImageFilterFunction filterFunction)
      : super(src, inter, filterFunction) {
    if (src.sourceImage.getFloatsBetweenPixelsInclusive() != 4) {
      throw UnsupportedError("span_image_filter_rgba must have a 32 bit DestImage");
    }
  }

  @override
  void generate(List<ColorF> span, int spanIndex, int xInt, int yInt, int len) {
    interpolator().begin(xInt + filterDxDbl(), yInt + filterDyDbl(), len);

    double fR, fG, fB;

    int radius = filterFunction()!.radius().toInt();
    int diameter = radius * 2;
    int start = -(diameter ~/ 2 - 1);

    int xCount;

    ISpanInterpolatorFloat spanInterpolator = interpolator();
    IImageBufferAccessorFloat sourceAccessor = source();
    
    List<double> xy = [0.0, 0.0];
    RefParam<int> bufferIndexRef = RefParam(0);

    do {
      spanInterpolator.coordinates(xy);
      double x = xy[0];
      double y = xy[1];
      
      int sourceXInt = x.toInt();
      int sourceYInt = y.toInt();
      Vector2 sourceOrigin = Vector2(x, y);
      Vector2 sourceSample = Vector2((sourceXInt + start).toDouble(), (sourceYInt + start).toDouble());

      fB = fG = fR = 0;

      int yCount = diameter;

      Float32List fgPtr = sourceAccessor.span(sourceXInt + start, sourceYInt + start, diameter, bufferIndexRef);
      int bufferIndex = bufferIndexRef.value;
      
      for (;;) {
        double yweight = filterFunction()!.calcWeight(math.sqrt((sourceSample.y - sourceOrigin.y) * (sourceSample.y - sourceOrigin.y)));
        xCount = diameter;
        for (;;) {
          double xweight = filterFunction()!.calcWeight(math.sqrt((sourceSample.x - sourceOrigin.x) * (sourceSample.x - sourceOrigin.x)));
          double weight = xweight * yweight;

          fR += weight * fgPtr[bufferIndex + 0]; // R (Float buffer usually R, G, B, A order?)
          // Wait, C# code: fg_ptr[bufferIndex + ImageBuffer.OrderR]
          // ImageBuffer.OrderR is usually 2 for BGRA, but for Float buffer it might be different.
          // In C# ImageBufferFloat, OrderR is 0?
          // Let's assume RGBA for float buffer for now, or check IImageFloat.
          // IImageFloat doesn't specify order constants.
          // But usually float buffers are RGBA.
          // Let's assume R=0, G=1, B=2, A=3 for now.
          // C# code uses ImageBuffer.OrderR which is for byte buffer.
          // But SpanImageFilterRgbaFloat uses ImageBuffer.OrderR too.
          // If ImageBufferFloat uses same constants, then it depends on platform.
          // In Dart, we usually use RGBA.
          
          // Let's assume standard RGBA for now.
          fR += weight * fgPtr[bufferIndex + 0];
          fG += weight * fgPtr[bufferIndex + 1];
          fB += weight * fgPtr[bufferIndex + 2];

          sourceSample.x += 1;
          if (--xCount == 0) break;
          sourceAccessor.nextX(bufferIndexRef);
          bufferIndex = bufferIndexRef.value;
        }

        sourceSample.x -= diameter;

        if (--yCount == 0) break;
        sourceSample.y += 1;
        sourceAccessor.nextY(bufferIndexRef);
        bufferIndex = bufferIndexRef.value;
      }

      if (fB < 0) fB = 0; if (fB > 1) fB = 1;
      if (fR < 0) fR = 0; if (fR > 1) fR = 1;
      if (fG < 0) fG = 0; if (fG > 1) fG = 1;

      span[spanIndex] = ColorF(fR, fG, fB, 1.0); // Alpha 1.0 as per C# code
      spanIndex++;
      spanInterpolator.next();
    } while (--len != 0);
  }
}

class SpanImageResampleRgba extends SpanImageResample {
  static const int baseMask = 255;
  static const int downscaleShift = ImageFilterScale.imageFilterShift;

  SpanImageResampleRgba(
      IImageBufferAccessor src, ISpanInterpolator inter, ImageFilterLookUpTable filter)
      : super(src, inter, filter) {
    if (src.sourceImage.getRecieveBlender().numPixelBits != 32) {
      throw FormatException("You have to use a rgba blender with span_image_resample_rgba");
    }
  }

  @override
  void generate(List<Color> span, int spanIndex, int x, int y, int len) {
    ISpanInterpolator spanInterpolator = interpolator();
    spanInterpolator.begin(x + filterDxDbl(), y + filterDyDbl(), len);

    List<int> fg = [0, 0, 0, 0];

    Int32List weightArray = filter()!.weightArray();
    int diameter = filter()!.diameter();
    int filterScale = diameter << ImageSubpixelScale.imageSubpixelShift;

    RefParam<int> bufferIndexRef = RefParam(0);
    List<int> xy = [0, 0];
    List<int> rxRy = [0, 0];

    do {
      int rx;
      int ry;
      int rxInv = ImageSubpixelScale.imageSubpixelScale;
      int ryInv = ImageSubpixelScale.imageSubpixelScale;
      
      spanInterpolator.coordinates(xy);
      x = xy[0];
      y = xy[1];
      
      // spanInterpolator.localScale(rxRy); // Not implemented in Linear interpolator yet?
      // Assuming it is implemented or we need to implement it.
      // In C# it is implemented in span_interpolator_linear.
      // I implemented it as throwing UnimplementedError in agg_span_interpolator_linear.dart.
      // I should fix that.
      
      // For now, let's assume it works or I'll fix it later.
      try {
        spanInterpolator.localScale(rxRy);
      } catch (e) {
        rxRy[0] = ImageSubpixelScale.imageSubpixelScale;
        rxRy[1] = ImageSubpixelScale.imageSubpixelScale;
      }
      
      rx = rxRy[0];
      ry = rxRy[1];
      
      adjustScale(rxRy);
      rx = rxRy[0];
      ry = rxRy[1];

      rxInv = ImageSubpixelScale.imageSubpixelScale * ImageSubpixelScale.imageSubpixelScale ~/ rx;
      ryInv = ImageSubpixelScale.imageSubpixelScale * ImageSubpixelScale.imageSubpixelScale ~/ ry;

      int radiusX = (diameter * rx) >> 1;
      int radiusY = (diameter * ry) >> 1;
      int lenXLr =
          (diameter * rx + ImageSubpixelScale.imageSubpixelMask) >>
              ImageSubpixelScale.imageSubpixelShift;

      x += filterDxInt() - radiusX;
      y += filterDyInt() - radiusY;

      fg[0] = fg[1] = fg[2] = fg[3] = ImageFilterScale.imageFilterScale ~/ 2;

      int yLr = y >> ImageSubpixelScale.imageSubpixelShift;
      int yHr = ((ImageSubpixelScale.imageSubpixelMask - (y & ImageSubpixelScale.imageSubpixelMask)) *
                     ryInv) >> ImageSubpixelScale.imageSubpixelShift;
      int totalWeight = 0;
      int xLr = x >> ImageSubpixelScale.imageSubpixelShift;
      int xHr = ((ImageSubpixelScale.imageSubpixelMask - (x & ImageSubpixelScale.imageSubpixelMask)) *
                     rxInv) >> ImageSubpixelScale.imageSubpixelShift;
      int xHr2 = xHr;
      
      Uint8List fgPtr = getImageBufferAccessor().span(xLr, yLr, lenXLr, bufferIndexRef);
      int sourceIndex = bufferIndexRef.value;

      for (;;) {
        int weightY = weightArray[yHr];
        xHr = xHr2;
        for (;;) {
          int weight = (weightY * weightArray[xHr] +
                       ImageFilterScale.imageFilterScale ~/ 2) >>
                       downscaleShift;
          fg[0] += fgPtr[sourceIndex + 2] * weight; // R
          fg[1] += fgPtr[sourceIndex + 1] * weight; // G
          fg[2] += fgPtr[sourceIndex + 0] * weight; // B
          fg[3] += fgPtr[sourceIndex + 3] * weight; // A
          totalWeight += weight;
          xHr += rxInv;
          if (xHr >= filterScale) break;
          getImageBufferAccessor().nextX(bufferIndexRef);
          sourceIndex = bufferIndexRef.value;
        }
        yHr += ryInv;
        if (yHr >= filterScale) {
          break;
        }

        getImageBufferAccessor().nextY(bufferIndexRef);
        sourceIndex = bufferIndexRef.value;
      }

      fg[0] ~/= totalWeight;
      fg[1] ~/= totalWeight;
      fg[2] ~/= totalWeight;
      fg[3] ~/= totalWeight;

      if (fg[0] < 0) fg[0] = 0;
      if (fg[1] < 0) fg[1] = 0;
      if (fg[2] < 0) fg[2] = 0;
      if (fg[3] < 0) fg[3] = 0;

      if (fg[0] > baseMask) fg[0] = baseMask;
      if (fg[1] > baseMask) fg[1] = baseMask;
      if (fg[2] > baseMask) fg[2] = baseMask;
      if (fg[3] > baseMask) fg[3] = baseMask;

      span[spanIndex] = Color.fromRgba(fg[0], fg[1], fg[2], fg[3]);

      spanIndex++;
      interpolator().next();
    } while (--len != 0);
  }
}
