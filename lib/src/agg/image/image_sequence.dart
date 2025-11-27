import 'dart:math';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/primitives/rectangle_int.dart';
import 'package:agg/src/vector_math/vector2.dart';

class ImageSequence {
  List<ImageBuffer> frames = [];
  List<int> frameTimesMs = [];

  ImageSequence([ImageBuffer? firstImage]) {
    if (firstImage != null) {
      addImage(firstImage, 0);
    }
  }

  // event EventHandler Invalidated;
  // In Dart we can use a Stream or a callback list. For now, let's skip events or use a simple callback.
  Function(Object?, Object?)? invalidated;

  double get framesPerSecond => 1 / secondsPerFrame;
  set framesPerSecond(double value) => secondsPerFrame = 1 / value;

  int get height {
    if (frames.isNotEmpty) {
      RectangleInt bounds = RectangleInt(2147483647, 2147483647, -2147483648, -2147483648);
      for (var frame in frames) {
        bounds.expandToInclude(frame.getBounds());
      }
      return max(0, bounds.height);
    }
    return 0;
  }

  bool looping = false;

  int get numFrames => frames.length;

  double secondsPerFrame = 1.0 / 30.0;

  double get time {
    if (frameTimesMs.isNotEmpty) {
      int totalTime = 0;
      for (var time in frameTimesMs) {
        totalTime += time;
      }
      return totalTime / 1000.0;
    } else {
      return frames.length * secondsPerFrame;
    }
  }

  int get width {
    if (frames.isNotEmpty) {
      RectangleInt bounds = RectangleInt(2147483647, 2147483647, -2147483648, -2147483648);
      for (var frame in frames) {
        bounds.expandToInclude(frame.getBounds());
      }
      return max(0, bounds.width);
    }
    return 0;
  }

  // LoadFromTgas skipped for now as it involves file IO and TGA loading which might not be ported yet.

  void addImage(ImageBuffer imageBuffer, [int frameTimeMs = 1000 ~/ 30]) {
    frames.add(imageBuffer);
    frameTimesMs.add(max(frameTimeMs, 1));
  }

  void centerOriginOffset() {
    for (var image in frames) {
      image.originOffset = Vector2(image.width / 2, image.height / 2);
    }
  }

  void copy(ImageSequence imageSequenceToCopy) {
    frames = List.from(imageSequenceToCopy.frames);
    frameTimesMs = List.from(imageSequenceToCopy.frameTimesMs);
    looping = imageSequenceToCopy.looping;
    invalidated?.call(this, null);
  }

  void cropToVisible() {
    // ImageBuffer.cropToVisible not implemented yet?
    // Assuming it exists or skipping.
    // for (int i = 0; i < frames.length; i++) {
    //   frames[i] = frames[i].cropToVisible();
    // }
  }

  int getFrameIndexByRatio(double fractionOfTotalLength) {
    return ((fractionOfTotalLength * (numFrames - 1)) + .5).toInt();
  }

  ImageBuffer getImageByIndex(dynamic imageIndex) {
    if (imageIndex is double) {
      return getImageByIndexInt((imageIndex + .5).toInt());
    }
    return getImageByIndexInt(imageIndex as int);
  }

  ImageBuffer getImageByIndexInt(int imageIndex) {
    if (looping) {
      return frames[imageIndex % numFrames];
    }

    if (imageIndex < 0) {
      return frames[0];
    } else if (imageIndex > numFrames - 1) {
      return frames[numFrames - 1];
    }

    return frames[imageIndex];
  }

  ImageBuffer? getImageByRatio(double fractionOfTotalLength) {
    if (numFrames > 0) {
      return getImageByIndex(fractionOfTotalLength * (numFrames - 1));
    }
    return null;
  }

  ImageBuffer getImageByTime(double numSeconds) {
    return frames[getImageIndexByTime(numSeconds)];
  }

  int getImageIndexByTime(double numSeconds) {
    if (frameTimesMs.isNotEmpty) {
      int timeMs = (numSeconds * 1000).toInt();
      double totalTime = 0;
      int index = 0;
      for (var time in frameTimesMs) {
        totalTime += time;
        if (totalTime > timeMs) {
          return min(index, frames.length - 1);
        }
        index++;
      }
    }

    int frame = (numSeconds * framesPerSecond).round();
    return min(frame, frames.length - 1);
  }

  void invalidate() {
    onInvalidated(null);
  }

  void onInvalidated(Object? args) {
    invalidated?.call(this, args);
  }

  void setAlpha(int value) {
    // ImageBuffer.setAlpha not implemented?
    // for (var image in frames) {
    //   image.setAlpha(value);
    // }
  }
}

class ImageSequenceProperties {
  double framePerFrame = 30;
  bool looping = false;
}
