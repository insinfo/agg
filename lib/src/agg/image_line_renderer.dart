import 'dart:typed_data';

import 'package:agg/src/agg/agg_basics.dart';
import 'package:agg/src/agg/agg_pattern_filters_rgba.dart';
import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/line_aa_basics.dart';
import 'package:agg/src/agg/primitives/color.dart';

class LineImagePattern extends ImageBuffer {
  late IPatternFilter _filter;
  int _dilation = 0;
  int _dilationHr = 0;
  int _widthHr = 0;
  int _halfHeightHr = 0;
  int _offsetYHr = 0;
  ImageBuffer? _buf;

  int _patternWidth = 0;
  int _patternHeight = 0;

  LineImagePattern(IPatternFilter filter) : super(0, 0) {
    _filter = filter;
    _dilation = filter.dilation() + 1;
    _dilationHr = _dilation << LineAABasics.line_subpixel_shift;
  }

  void create(IImageByte src) {
    _patternHeight = Agg_basics.uceil(src.height.toDouble());
    _patternWidth = Agg_basics.uceil(src.width.toDouble());
    _widthHr = Agg_basics.uround(
        src.width * LineAABasics.line_subpixel_scale.toDouble());
    _halfHeightHr =
        Agg_basics.uround(src.height * LineAABasics.line_subpixel_scale / 2);
    _offsetYHr =
        _dilationHr + _halfHeightHr - LineAABasics.line_subpixel_scale ~/ 2;
    _halfHeightHr += LineAABasics.line_subpixel_scale ~/ 2;

    int bufferWidth = _patternWidth + _dilation * 2;
    int bufferHeight = _patternHeight + _dilation * 2;
    int bytesPerPixel = 4; // RGBA8888

    // Create a new ImageBuffer wrapping the data
    // ImageBuffer in Dart allocates its own buffer.
    // We need a way to wrap existing buffer or copy to it.
    // For now, let's just create a new ImageBuffer and copy data if needed,
    // or use ImageBuffer's buffer.
    _buf = ImageBuffer(bufferWidth, bufferHeight);
    // We ignore _data for now and use _buf's buffer.

    final Uint8List destBuffer = _buf!.getBuffer();
    final Uint8List sourceBuffer = src.getBuffer();

    // Copy image into middle of dest
    for (int y = 0; y < _patternHeight; y++) {
      for (int x = 0; x < _patternWidth; x++) {
        int sourceOffset = src.getBufferOffsetXY(x, y);
        int destOffset = _buf!.getBufferOffsetXY(_dilation + x, _dilation + y);
        for (int channel = 0; channel < bytesPerPixel; channel++) {
          destBuffer[destOffset++] = sourceBuffer[sourceOffset++];
        }
      }
    }

    // Copy first two pixels from end into beginning and from beginning into end
    for (int y = 0; y < _patternHeight; y++) {
      int s1Offset = src.getBufferOffsetXY(0, y);
      int d1Offset =
          _buf!.getBufferOffsetXY(_dilation + _patternWidth, _dilation + y);

      int s2Offset = src.getBufferOffsetXY(_patternWidth - _dilation, y);
      int d2Offset = _buf!.getBufferOffsetXY(0, _dilation + y);

      for (int x = 0; x < _dilation; x++) {
        for (int channel = 0; channel < bytesPerPixel; channel++) {
          destBuffer[d1Offset++] = sourceBuffer[s1Offset++];
          destBuffer[d2Offset++] = sourceBuffer[s2Offset++];
        }
      }
    }
  }

  int patternWidth() => _widthHr;
  int lineWidth() => _halfHeightHr;
  double widthDouble() => _patternHeight.toDouble();

  void pixel(List<Color> destBuffer, int destBufferOffset, int x, int y) {
    _filter.pixelHighRes(
      _buf!,
      destBuffer,
      destBufferOffset,
      x % _widthHr + _dilationHr,
      y + _offsetYHr,
    );
  }

  IPatternFilter filter() => _filter;
}

class DistanceInterpolator4 {
  int _dx = 0;
  int _dy = 0;
  int _dxStart = 0;
  int _dyStart = 0;
  int _dxPict = 0;
  int _dyPict = 0;
  int _dxEnd = 0;
  int _dyEnd = 0;

  int _dist = 0;
  int _distStart = 0;
  int _distPict = 0;
  int _distEnd = 0;
  int _len = 0;

  DistanceInterpolator4();

  DistanceInterpolator4.init(
    int x1,
    int y1,
    int x2,
    int y2,
    int sx,
    int sy,
    int ex,
    int ey,
    int len,
    double scale,
    int x,
    int y,
  ) {
    _dx = x2 - x1;
    _dy = y2 - y1;
    _dxStart = LineAABasics.line_mr(sx) - LineAABasics.line_mr(x1);
    _dyStart = LineAABasics.line_mr(sy) - LineAABasics.line_mr(y1);
    _dxEnd = LineAABasics.line_mr(ex) - LineAABasics.line_mr(x2);
    _dyEnd = LineAABasics.line_mr(ey) - LineAABasics.line_mr(y2);

    _dist = Agg_basics.iround(
      (x + LineAABasics.line_subpixel_scale / 2 - x2) * _dy -
          (y + LineAABasics.line_subpixel_scale / 2 - y2) * _dx,
    );

    _distStart =
        (LineAABasics.line_mr(x + LineAABasics.line_subpixel_scale ~/ 2) -
                    LineAABasics.line_mr(sx)) *
                _dyStart -
            (LineAABasics.line_mr(y + LineAABasics.line_subpixel_scale ~/ 2) -
                    LineAABasics.line_mr(sy)) *
                _dxStart;

    _distEnd =
        (LineAABasics.line_mr(x + LineAABasics.line_subpixel_scale ~/ 2) -
                    LineAABasics.line_mr(ex)) *
                _dyEnd -
            (LineAABasics.line_mr(y + LineAABasics.line_subpixel_scale ~/ 2) -
                    LineAABasics.line_mr(ey)) *
                _dxEnd;

    _len = Agg_basics.uround(len / scale);

    double d = len * scale;
    int dx =
        Agg_basics.iround(((x2 - x1) << LineAABasics.line_subpixel_shift) / d);
    int dy =
        Agg_basics.iround(((y2 - y1) << LineAABasics.line_subpixel_shift) / d);
    _dxPict = -dy;
    _dyPict = dx;
    _distPict =
        ((x + LineAABasics.line_subpixel_scale ~/ 2 - (x1 - dy)) * _dyPict -
                (y + LineAABasics.line_subpixel_scale ~/ 2 - (y1 + dx)) *
                    _dxPict) >>
            LineAABasics.line_subpixel_shift;

    _dx <<= LineAABasics.line_subpixel_shift;
    _dy <<= LineAABasics.line_subpixel_shift;
    _dxStart <<= LineAABasics.line_mr_subpixel_shift;
    _dyStart <<= LineAABasics.line_mr_subpixel_shift;
    _dxEnd <<= LineAABasics.line_mr_subpixel_shift;
    _dyEnd <<= LineAABasics.line_mr_subpixel_shift;
  }

  void incX() {
    _dist += _dy;
    _distStart += _dyStart;
    _distPict += _dyPict;
    _distEnd += _dyEnd;
  }

  void decX() {
    _dist -= _dy;
    _distStart -= _dyStart;
    _distPict -= _dyPict;
    _distEnd -= _dyEnd;
  }

  void incY() {
    _dist -= _dx;
    _distStart -= _dxStart;
    _distPict -= _dxPict;
    _distEnd -= _dxEnd;
  }

  void decY() {
    _dist += _dx;
    _distStart += _dxStart;
    _distPict += _dxPict;
    _distEnd += _dxEnd;
  }

  void incXWithDy(int dy) {
    _dist += _dy;
    _distStart += _dyStart;
    _distPict += _dyPict;
    _distEnd += _dyEnd;
    if (dy > 0) {
      _dist -= _dx;
      _distStart -= _dxStart;
      _distPict -= _dxPict;
      _distEnd -= _dxEnd;
    }
    if (dy < 0) {
      _dist += _dx;
      _distStart += _dxStart;
      _distPict += _dxPict;
      _distEnd += _dxEnd;
    }
  }

  void decXWithDy(int dy) {
    _dist -= _dy;
    _distStart -= _dyStart;
    _distPict -= _dyPict;
    _distEnd -= _dyEnd;
    if (dy > 0) {
      _dist -= _dx;
      _distStart -= _dxStart;
      _distPict -= _dxPict;
      _distEnd -= _dxEnd;
    }
    if (dy < 0) {
      _dist += _dx;
      _distStart += _dxStart;
      _distPict += _dxPict;
      _distEnd += _dxEnd;
    }
  }

  void incYWithDx(int dx) {
    _dist -= _dx;
    _distStart -= _dxStart;
    _distPict -= _dxPict;
    _distEnd -= _dxEnd;
    if (dx > 0) {
      _dist += _dy;
      _distStart += _dyStart;
      _distPict += _dyPict;
      _distEnd += _dyEnd;
    }
    if (dx < 0) {
      _dist -= _dy;
      _distStart -= _dyStart;
      _distPict -= _dyPict;
      _distEnd -= _dyEnd;
    }
  }

  void decYWithDx(int dx) {
    _dist += _dx;
    _distStart += _dxStart;
    _distPict += _dxPict;
    _distEnd += _dxEnd;
    if (dx > 0) {
      _dist += _dy;
      _distStart += _dyStart;
      _distPict += _dyPict;
      _distEnd += _dyEnd;
    }
    if (dx < 0) {
      _dist -= _dy;
      _distStart -= _dyStart;
      _distPict -= _dyPict;
      _distEnd -= _dyEnd;
    }
  }

  int dist() => _dist;
  int distStart() => _distStart;
  int distPict() => _distPict;
  int distEnd() => _distEnd;
  int len() => _len;

  int dx() => _dx;
  int dy() => _dy;
  int dxStart() => _dxStart;
  int dyStart() => _dyStart;
  int dxPict() => _dxPict;
  int dyPict() => _dyPict;
  int dxEnd() => _dxEnd;
  int dyEnd() => _dyEnd;
}
