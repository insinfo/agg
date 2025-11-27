import 'dart:math';
import 'package:agg/src/agg/primitives/color.dart';

abstract class IThresholdFunction {
  double transform(Color color);
  double threshold(Color color);
  Color get zeroColor;
}

class AlphaThresholdFunction implements IThresholdFunction {
  double rangeStart = 0.1;
  double rangeEnd = 1.0;

  AlphaThresholdFunction([double rangeStart = 0.1, double rangeEnd = 1.0]) {
    this.rangeStart = max(0, min(1, rangeStart));
    this.rangeEnd = max(0, min(1, rangeEnd));
  }

  @override
  double transform(Color color) {
    return color.alpha0To1;
  }

  @override
  Color get zeroColor => Color.transparent;

  @override
  double threshold(Color color) {
    return _getThresholded0To1(transform(color));
  }

  double _getThresholded0To1(double rawValue) {
    double outValue = 0;
    if (rawValue < rangeStart) {
      outValue = 0;
    } else if (rawValue > rangeEnd) {
      outValue = 0;
    } else {
      outValue = (rawValue - rangeStart) / (rangeEnd - rangeStart);
    }
    return outValue;
  }
}

class AlphaFunction implements IThresholdFunction {
  @override
  double transform(Color color) {
    return color.alpha0To1;
  }

  @override
  Color get zeroColor => Color.transparent;

  @override
  double threshold(Color color) {
    return color.alpha0To1;
  }
}

class HueThresholdFunction implements IThresholdFunction {
  double rangeStart = 255.0 / 120.0;
  double rangeEnd = 255.0;

  HueThresholdFunction([double rangeStart = 255.0 / 120.0, double rangeEnd = 255.0]) {
    this.rangeStart = max(0, min(1, rangeStart));
    this.rangeEnd = max(0, min(1, rangeEnd));
  }

  @override
  double transform(Color color) {
    List<double> hsl = [0, 0, 0];
    color.toColorF().getHSL(hsl);
    return hsl[0];
  }

  @override
  Color get zeroColor => Color.black;

  @override
  double threshold(Color color) {
    return _getThresholded0To1(transform(color));
  }

  double _getThresholded0To1(double rawValue) {
    double outValue = 0;
    if (rawValue < rangeStart) {
      outValue = 0;
    } else if (rawValue > rangeEnd) {
      outValue = 0;
    } else {
      outValue = (rawValue - rangeStart) / (rangeEnd - rangeStart);
    }
    return outValue;
  }
}

class MapOnMaxIntensity implements IThresholdFunction {
  double rangeStart = .1;
  double rangeEnd = 1.0;

  MapOnMaxIntensity([double rangeStart = .1, double rangeEnd = 1.0]) {
    this.rangeStart = max(0, min(1, rangeStart));
    this.rangeEnd = max(0, min(1, rangeEnd));
  }

  @override
  double transform(Color color) {
    // we invert the gray value so we have black being the color we are finding
    return (color.red0To1 * 0.2989) + (color.blue0To1 * 0.5870) + (color.green0To1 * 0.1140);
  }

  @override
  double threshold(Color color) {
    // this is on I from HSI
    return getThresholded0To1(transform(color));
  }

  @override
  Color get zeroColor => Color.black;

  double getThresholded0To1(double rawValue) {
    double outValue = 0;
    if (rawValue < rangeStart) {
      outValue = 0;
    } else if (rawValue > rangeEnd) {
      outValue = 0;
    } else {
      outValue = (rawValue - rangeStart) / (rangeEnd - rangeStart);
    }

    return outValue;
  }
}

class SilhouetteThresholdFunction implements IThresholdFunction {
  double rangeStart = .1;
  double rangeEnd = 1.0;

  SilhouetteThresholdFunction([double rangeStart = .1, double rangeEnd = 1.0]) {
    this.rangeStart = max(0, min(1, rangeStart));
    this.rangeEnd = max(0, min(1, rangeEnd));
  }

  @override
  double transform(Color color) {
    // we invert the gray value so we have black being the color we are finding
    return 1 - ((color.red0To1 * 0.2989) + (color.blue0To1 * 0.5870) + (color.green0To1 * 0.1140));
  }

  @override
  double threshold(Color color) {
    // this is on I from HSI
    return getThresholded0To1(transform(color));
  }

  @override
  Color get zeroColor => Color.white;

  double getThresholded0To1(double rawValue) {
    double outValue = 0;
    if (rawValue < rangeStart) {
      outValue = 0;
    } else if (rawValue > rangeEnd) {
      outValue = 0;
    } else {
      outValue = (rawValue - rangeStart) / (rangeEnd - rangeStart);
    }

    return outValue;
  }
}
