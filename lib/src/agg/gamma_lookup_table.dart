import 'dart:math' as math;
import 'dart:typed_data';

/// Gamma correction lookup table for anti-aliased rendering.
///
/// This class provides gamma correction for anti-aliased graphics rendering.
/// Gamma correction adjusts the intensity of pixels to compensate for the
/// non-linear response of display devices.
class GammaLookUpTable {
  static const int _gammaShift = 8;
  static const int _gammaSize = 1 << _gammaShift; // 256
  static const int _gammaMask = _gammaSize - 1; // 255

  double _gamma;
  late Uint8List _dirGamma;
  late Uint8List _invGamma;

  /// Creates a gamma lookup table with gamma value of 1.0 (no correction).
  GammaLookUpTable([double gamma = 1.0]) : _gamma = gamma {
    _dirGamma = Uint8List(_gammaSize);
    _invGamma = Uint8List(_gammaSize);
    if (gamma != 1.0) {
      setGamma(gamma);
    } else {
      // Initialize with identity mapping
      for (var i = 0; i < _gammaSize; i++) {
        _dirGamma[i] = i;
        _invGamma[i] = i;
      }
    }
  }

  /// Sets the gamma correction value and recalculates the lookup tables.
  ///
  /// [g] - The gamma value. Values > 1.0 make the image brighter,
  /// values < 1.0 make it darker. A value of 1.0 means no correction.
  void setGamma(double g) {
    _gamma = g;

    // Calculate direct gamma correction
    for (var i = 0; i < _gammaSize; i++) {
      final normalized = i / _gammaMask;
      final corrected = math.pow(normalized, _gamma).toDouble() * _gammaMask;
      _dirGamma[i] = _uround(corrected);
    }

    // Calculate inverse gamma correction
    final invG = 1.0 / g;
    for (var i = 0; i < _gammaSize; i++) {
      final normalized = i / _gammaMask;
      final corrected = math.pow(normalized, invG).toDouble() * _gammaMask;
      _invGamma[i] = _uround(corrected);
    }
  }

  /// Gets the current gamma value.
  double getGamma() => _gamma;

  /// Gets the direct gamma-corrected value for the given input.
  ///
  /// [v] - Input value (0-255)
  /// Returns the gamma-corrected value (0-255)
  int dir(int v) => _dirGamma[v & _gammaMask];

  /// Gets the inverse gamma-corrected value for the given input.
  ///
  /// [v] - Input value (0-255)
  /// Returns the inverse gamma-corrected value (0-255)
  int inv(int v) => _invGamma[v & _gammaMask];

  /// Rounds a double to the nearest unsigned integer.
  static int _uround(double v) {
    return (v + 0.5).floor();
  }
}
