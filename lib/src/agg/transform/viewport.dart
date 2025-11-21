import 'package:agg/src/agg/transform/affine.dart';
import 'package:agg/src/shared/ref_param.dart';

/// Simple orthogonal viewport transform (world <-> device) with aspect control.
class Viewport {
  double _worldX1 = 0.0;
  double _worldY1 = 0.0;
  double _worldX2 = 1.0;
  double _worldY2 = 1.0;
  double _deviceX1 = 0.0;
  double _deviceY1 = 0.0;
  double _deviceX2 = 1.0;
  double _deviceY2 = 1.0;
  AspectRatio _aspect = AspectRatio.stretch;
  bool _isValid = true;
  double _alignX = 0.5;
  double _alignY = 0.5;
  double _wx1 = 0.0;
  double _wy1 = 0.0;
  double _wx2 = 1.0;
  double _wy2 = 1.0;
  double _dx1 = 0.0;
  double _dy1 = 0.0;
  double _kx = 1.0;
  double _ky = 1.0;

  Viewport();

  void preserveAspectRatio(double alignX, double alignY, AspectRatio aspect) {
    _alignX = alignX;
    _alignY = alignY;
    _aspect = aspect;
    _update();
  }

  void deviceViewport(double x1, double y1, double x2, double y2) {
    _deviceX1 = x1;
    _deviceY1 = y1;
    _deviceX2 = x2;
    _deviceY2 = y2;
    _update();
  }

  void worldViewport(double x1, double y1, double x2, double y2) {
    _worldX1 = x1;
    _worldY1 = y1;
    _worldX2 = x2;
    _worldY2 = y2;
    _update();
  }

  ({double x1, double y1, double x2, double y2}) deviceViewportBounds() {
    return (x1: _deviceX1, y1: _deviceY1, x2: _deviceX2, y2: _deviceY2);
  }

  ({double x1, double y1, double x2, double y2}) worldViewportBounds() {
    return (x1: _worldX1, y1: _worldY1, x2: _worldX2, y2: _worldY2);
  }

  ({double x1, double y1, double x2, double y2}) worldViewportActual() {
    return (x1: _wx1, y1: _wy1, x2: _wx2, y2: _wy2);
  }

  bool get isValid => _isValid;
  double get alignX => _alignX;
  double get alignY => _alignY;
  AspectRatio get aspectRatio => _aspect;

  void transform(RefParam<double> x, RefParam<double> y) {
    x.value = (x.value - _wx1) * _kx + _dx1;
    y.value = (y.value - _wy1) * _ky + _dy1;
  }

  void transformScaleOnly(RefParam<double> x, RefParam<double> y) {
    x.value *= _kx;
    y.value *= _ky;
  }

  void inverseTransform(RefParam<double> x, RefParam<double> y) {
    x.value = (x.value - _dx1) / _kx + _wx1;
    y.value = (y.value - _dy1) / _ky + _wy1;
  }

  void inverseTransformScaleOnly(RefParam<double> x, RefParam<double> y) {
    x.value /= _kx;
    y.value /= _ky;
  }

  double deviceDx() => _dx1 - _wx1 * _kx;
  double deviceDy() => _dy1 - _wy1 * _ky;
  double scaleX() => _kx;
  double scaleY() => _ky;
  double scaleAvg() => (_kx + _ky) * 0.5;

  Affine toAffine() {
    final Affine mtx = Affine.translation(-_wx1, -_wy1);
    mtx.multiply(Affine.scaling(_kx, _ky));
    mtx.multiply(Affine.translation(_dx1, _dy1));
    return mtx;
  }

  Affine toAffineScaleOnly() => Affine.scaling(_kx, _ky);

  void _update() {
    const double epsilon = 1e-30;
    if (((_worldX1 - _worldX2).abs() < epsilon) ||
        ((_worldY1 - _worldY2).abs() < epsilon) ||
        ((_deviceX1 - _deviceX2).abs() < epsilon) ||
        ((_deviceY1 - _deviceY2).abs() < epsilon)) {
      _wx1 = _worldX1;
      _wy1 = _worldY1;
      _wx2 = _worldX1 + 1.0;
      _wy2 = _worldY2 + 1.0;
      _dx1 = _deviceX1;
      _dy1 = _deviceY1;
      _kx = 1.0;
      _ky = 1.0;
      _isValid = false;
      return;
    }

    double worldX1 = _worldX1;
    double worldY1 = _worldY1;
    double worldX2 = _worldX2;
    double worldY2 = _worldY2;
    final double deviceX1 = _deviceX1;
    final double deviceY1 = _deviceY1;
    final double deviceX2 = _deviceX2;
    final double deviceY2 = _deviceY2;

    if (_aspect != AspectRatio.stretch) {
      _kx = (deviceX2 - deviceX1) / (worldX2 - worldX1);
      _ky = (deviceY2 - deviceY1) / (worldY2 - worldY1);

      if ((_aspect == AspectRatio.meet) == (_kx < _ky)) {
        final double d = (worldY2 - worldY1) * _ky / _kx;
        worldY1 += (worldY2 - worldY1 - d) * _alignY;
        worldY2 = worldY1 + d;
      } else {
        final double d = (worldX2 - worldX1) * _kx / _ky;
        worldX1 += (worldX2 - worldX1 - d) * _alignX;
        worldX2 = worldX1 + d;
      }
    }

    _wx1 = worldX1;
    _wy1 = worldY1;
    _wx2 = worldX2;
    _wy2 = worldY2;
    _dx1 = deviceX1;
    _dy1 = deviceY1;
    _kx = (deviceX2 - deviceX1) / (worldX2 - worldX1);
    _ky = (deviceY2 - deviceY1) / (worldY2 - worldY1);
    _isValid = true;
  }
}

enum AspectRatio { stretch, meet, slice }
