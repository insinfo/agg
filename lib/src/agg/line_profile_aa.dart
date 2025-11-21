import 'dart:typed_data';

import 'package:agg/src/agg/agg_basics.dart';
import 'package:agg/src/agg/agg_gamma_functions.dart';

/// Precomputed coverage profile used by outline AA rendering.
class LineProfileAA {
  static const int _subpixelShift = 8;
  static const int _subpixelScale = 1 << _subpixelShift;
  static const int _aaShift = 8;
  static const int _aaScale = 1 << _aaShift;
  static const int _aaMask = _aaScale - 1;

  final Uint8List _gamma = Uint8List(_aaScale);
  Uint8List _profile = Uint8List(0);
  int _subpixelWidth = 0;
  double _minWidth = 1.0;
  double _smootherWidth = 1.0;

  LineProfileAA() {
    for (int i = 0; i < _aaScale; i++) {
      _gamma[i] = i;
    }
  }

  factory LineProfileAA.withWidth(double width, IGammaFunction gammaFunction) {
    final lp = LineProfileAA();
    lp.gamma(gammaFunction);
    lp.width(width);
    return lp;
  }

  void minWidth(double w) => _minWidth = w;

  void smootherWidth(double w) => _smootherWidth = w;

  void gamma(IGammaFunction gammaFunction) {
    for (int i = 0; i < _aaScale; i++) {
      _gamma[i] = Agg_basics.uround(
        (gammaFunction.getGamma(i / _aaMask).clamp(0.0, 1.0) * _aaMask),
      );
    }
  }

  void width(double w) {
    if (w < 0.0) w = 0.0;
    if (w < _smootherWidth) {
      w += w;
    } else {
      w += _smootherWidth;
    }
    w *= 0.5;
    w -= _smootherWidth;
    double s = _smootherWidth;
    if (w < 0.0) {
      s += w;
      w = 0.0;
    }
    _set(w, s);
  }

  int profileSize() => _profile.length;

  int subpixelWidth() => _subpixelWidth;
  int get subpixelScale => _subpixelScale;

  double min_width() => _minWidth;

  double smoother_width() => _smootherWidth;

  /// Lookup coverage for a given distance in subpixel units.
  int value(int dist) {
    final int idx = dist + _subpixelScale * 2;
    return idx >= 0 && idx < _profile.length ? _profile[idx] : 0;
  }

  Uint8List _profileBuffer(double w) {
    _subpixelWidth = Agg_basics.uround(w * _subpixelScale);
    final int size = _subpixelWidth + _subpixelScale * 6;
    if (size > _profile.length) {
      final Uint8List expanded = Uint8List(size);
      expanded.setAll(0, _profile);
      _profile = expanded;
    }
    return _profile;
  }

  void _set(double centerWidth, double smootherWidth) {
    double baseVal = 1.0;
    if (centerWidth == 0.0) centerWidth = 1.0 / _subpixelScale;
    if (smootherWidth == 0.0) smootherWidth = 1.0 / _subpixelScale;

    double width = centerWidth + smootherWidth;
    if (width < _minWidth) {
      final double k = width / _minWidth;
      baseVal *= k;
      centerWidth /= k;
      smootherWidth /= k;
    }

    final Uint8List buf = _profileBuffer(centerWidth + smootherWidth);
    final int subpixelCenterWidth = (centerWidth * _subpixelScale).toInt();
    final int subpixelSmootherWidth = (smootherWidth * _subpixelScale).toInt();

    int chCenter = _subpixelScale * 2;
    int chSmoother = chCenter + subpixelCenterWidth;

    // Center portion.
    final int centerVal = _gamma[(baseVal * _aaMask).toInt()];
    for (int i = 0, idx = chCenter; i < subpixelCenterWidth; i++, idx++) {
      buf[idx] = centerVal;
    }

    // Smoother falloff.
    for (int i = 0; i < subpixelSmootherWidth; i++, chSmoother++) {
      final double factor = 1.0 - (i / subpixelSmootherWidth);
      buf[chSmoother] = _gamma[(baseVal * factor * _aaMask).toInt()];
    }

    // Tail to zero.
    final int nSmoother = buf.length - subpixelSmootherWidth - subpixelCenterWidth - _subpixelScale * 2;
    for (int i = 0; i < nSmoother; i++, chSmoother++) {
      buf[chSmoother] = _gamma[0];
    }

    // Mirror to negative side.
    int left = chCenter;
    int right = chCenter;
    for (int i = 0; i < _subpixelScale * 2; i++) {
      buf[--left] = buf[right++];
    }
  }
}
