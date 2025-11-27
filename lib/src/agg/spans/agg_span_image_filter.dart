import 'package:agg/src/agg/agg_image_filters.dart';
import 'package:agg/src/agg/primitives/color_f.dart';
import 'package:agg/src/agg/raster_buffer_accessors.dart';
import 'package:agg/src/agg/spans/agg_span_generator.dart';
import 'package:agg/src/agg/spans/agg_span_interpolator_linear.dart';
import 'package:agg/src/agg/util.dart';

abstract class SpanImageFilter extends ISpanGenerator {
  late IImageBufferAccessor _imageBufferAccessor;
  late ISpanInterpolator _interpolator;
  ImageFilterLookUpTable? _filter;
  double _dxDbl = 0.5;
  double _dyDbl = 0.5;
  int _dxInt = 0;
  int _dyInt = 0;

  SpanImageFilter(
      IImageBufferAccessor src, ISpanInterpolator interpolator,
      [ImageFilterLookUpTable? filter]) {
    _imageBufferAccessor = src;
    _interpolator = interpolator;
    _filter = filter;
    _dxInt = ImageSubpixelScale.imageSubpixelScale ~/ 2;
    _dyInt = ImageSubpixelScale.imageSubpixelScale ~/ 2;
  }

  void attach(IImageBufferAccessor v) {
    _imageBufferAccessor = v;
  }

  IImageBufferAccessor getImageBufferAccessor() {
    return _imageBufferAccessor;
  }

  ImageFilterLookUpTable? filter() {
    return _filter;
  }

  int filterDxInt() {
    return _dxInt;
  }

  int filterDyInt() {
    return _dyInt;
  }

  double filterDxDbl() {
    return _dxDbl;
  }

  double filterDyDbl() {
    return _dyDbl;
  }

  void setInterpolator(ISpanInterpolator v) {
    _interpolator = v;
  }

  void setFilter(ImageFilterLookUpTable v) {
    _filter = v;
  }

  void filterOffset(double dx, double dy) {
    _dxDbl = dx;
    _dyDbl = dy;
    _dxInt = Util.iround(dx * ImageSubpixelScale.imageSubpixelScale);
    _dyInt = Util.iround(dy * ImageSubpixelScale.imageSubpixelScale);
  }

  void filterOffsetScalar(double d) {
    filterOffset(d, d);
  }

  ISpanInterpolator interpolator() {
    return _interpolator;
  }

  @override
  void prepare() {}
}

abstract class ISpanGeneratorFloat {
  void prepare();
  void generate(List<ColorF> span, int spanIndex, int x, int y, int len);
}

abstract class SpanImageFilterFloat implements ISpanGeneratorFloat {
  late IImageBufferAccessorFloat _imageBufferAccessor;
  late ISpanInterpolatorFloat _interpolator;
  IImageFilterFunction? _filterFunction;
  double _dxDbl = 0.5;
  double _dyDbl = 0.5;

  SpanImageFilterFloat(
      IImageBufferAccessorFloat src, ISpanInterpolatorFloat interpolator,
      [IImageFilterFunction? filterFunction]) {
    _imageBufferAccessor = src;
    _interpolator = interpolator;
    _filterFunction = filterFunction;
  }

  void attach(IImageBufferAccessorFloat v) {
    _imageBufferAccessor = v;
  }

  IImageBufferAccessorFloat source() {
    return _imageBufferAccessor;
  }

  IImageFilterFunction? filterFunction() {
    return _filterFunction;
  }

  double filterDxDbl() {
    return _dxDbl;
  }

  double filterDyDbl() {
    return _dyDbl;
  }

  void setInterpolator(ISpanInterpolatorFloat v) {
    _interpolator = v;
  }

  void setFilterFunction(IImageFilterFunction v) {
    _filterFunction = v;
  }

  void filterOffset(double dx, double dy) {
    _dxDbl = dx;
    _dyDbl = dy;
  }

  void filterOffsetScalar(double d) {
    filterOffset(d, d);
  }

  ISpanInterpolatorFloat interpolator() {
    return _interpolator;
  }

  @override
  void prepare() {}
}

abstract class SpanImageResample extends SpanImageFilter {
  int _scaleLimit = 20;
  int _blurX = ImageSubpixelScale.imageSubpixelScale;
  int _blurY = ImageSubpixelScale.imageSubpixelScale;

  SpanImageResample(IImageBufferAccessor src, ISpanInterpolator inter,
      ImageFilterLookUpTable filter)
      : super(src, inter, filter);

  int scaleLimit() {
    return _scaleLimit;
  }

  void setScaleLimit(int v) {
    _scaleLimit = v;
  }

  double blurX() {
    return _blurX.toDouble() / ImageSubpixelScale.imageSubpixelScale;
  }

  double blurY() {
    return _blurY.toDouble() / ImageSubpixelScale.imageSubpixelScale;
  }

  void setBlurX(double v) {
    _blurX = Util.uround(v * ImageSubpixelScale.imageSubpixelScale);
  }

  void setBlurY(double v) {
    _blurY = Util.uround(v * ImageSubpixelScale.imageSubpixelScale);
  }

  void blur(double v) {
    _blurX = _blurY = Util.uround(v * ImageSubpixelScale.imageSubpixelScale);
  }

  void adjustScale(List<int> rxRy) {
    int rx = rxRy[0];
    int ry = rxRy[1];

    if (rx < ImageSubpixelScale.imageSubpixelScale) {
      rx = ImageSubpixelScale.imageSubpixelScale;
    }
    if (ry < ImageSubpixelScale.imageSubpixelScale) {
      ry = ImageSubpixelScale.imageSubpixelScale;
    }
    if (rx > ImageSubpixelScale.imageSubpixelScale * _scaleLimit) {
      rx = ImageSubpixelScale.imageSubpixelScale * _scaleLimit;
    }
    if (ry > ImageSubpixelScale.imageSubpixelScale * _scaleLimit) {
      ry = ImageSubpixelScale.imageSubpixelScale * _scaleLimit;
    }
    rx = (rx * _blurX) >> ImageSubpixelScale.imageSubpixelShift;
    ry = (ry * _blurY) >> ImageSubpixelScale.imageSubpixelShift;
    if (rx < ImageSubpixelScale.imageSubpixelScale) {
      rx = ImageSubpixelScale.imageSubpixelScale;
    }
    if (ry < ImageSubpixelScale.imageSubpixelScale) {
      ry = ImageSubpixelScale.imageSubpixelScale;
    }
    
    rxRy[0] = rx;
    rxRy[1] = ry;
  }
}
