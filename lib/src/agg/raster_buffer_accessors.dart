import 'dart:typed_data';

import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/image/iimage_float.dart';
import 'package:agg/src/agg/primitives/color_f.dart';
import 'package:agg/src/shared/ref_param.dart';

abstract class IImageBufferAccessor {
  Uint8List span(int x, int y, int len, RefParam<int> bufferIndex);

  Uint8List nextX(RefParam<int> bufferByteOffset);

  Uint8List nextY(RefParam<int> bufferByteOffset);

  IImageByte get sourceImage;
}

class ImageBufferAccessorCommon implements IImageBufferAccessor {
  late IImageByte _sourceImage;
  int _x = 0;
  int _x0 = 0;
  int _y = 0;
  int _distanceBetweenPixelsInclusive = 0;
  late Uint8List _buffer;
  int _currentBufferOffset = -1;

  ImageBufferAccessorCommon(IImageByte pixf) {
    attach(pixf);
  }

  void attach(IImageByte pixf) {
    _sourceImage = pixf;
    _buffer = _sourceImage.getBuffer();

    _distanceBetweenPixelsInclusive =
        _sourceImage.getBytesBetweenPixelsInclusive();
  }

  @override
  IImageByte get sourceImage => _sourceImage;

  Uint8List pixel(RefParam<int> bufferByteOffset) {
    int x = _x;
    int y = _y;
    if (x >= _sourceImage.width) {
      x = x < 0 ? 0 : _sourceImage.width - 1;
    }
    if (y >= _sourceImage.height) {
      y = y < 0 ? 0 : _sourceImage.height - 1;
    }

    bufferByteOffset.value = _sourceImage.getBufferOffsetXY(x, y);
    return _sourceImage.getBuffer();
  }

  @override
  Uint8List span(int x, int y, int len, RefParam<int> bufferOffset) {
    _x = _x0 = x;
    _y = y;
    if (y >= 0 &&
        y < _sourceImage.height &&
        x >= 0 &&
        x + len <= _sourceImage.width) {
      bufferOffset.value = _sourceImage.getBufferOffsetXY(x, y);
      _buffer = _sourceImage.getBuffer();
      _currentBufferOffset = bufferOffset.value;
      return _buffer;
    }

    _currentBufferOffset = -1;
    return pixel(bufferOffset);
  }

  @override
  Uint8List nextX(RefParam<int> bufferOffset) {
    if (_currentBufferOffset != -1) {
      _currentBufferOffset += _distanceBetweenPixelsInclusive;
      bufferOffset.value = _currentBufferOffset;
      return _buffer;
    }
    ++_x;
    return pixel(bufferOffset);
  }

  @override
  Uint8List nextY(RefParam<int> bufferOffset) {
    ++_y;
    _x = _x0;
    if (_currentBufferOffset != -1 && _y < _sourceImage.height) {
      _currentBufferOffset = _sourceImage.getBufferOffsetXY(_x, _y);
      _sourceImage.getBuffer(); // Ensure buffer is fresh if needed?
      bufferOffset.value = _currentBufferOffset;
      return _buffer;
    }

    _currentBufferOffset = -1;
    return pixel(bufferOffset);
  }
}

class ImageBufferAccessorClip extends ImageBufferAccessorCommon {
  late Uint8List _outsideBufferColor;

  ImageBufferAccessorClip(IImageByte sourceImage, Color bk)
      : super(sourceImage) {
    _outsideBufferColor = Uint8List(4);
    _outsideBufferColor[0] = bk.red;
    _outsideBufferColor[1] = bk.green;
    _outsideBufferColor[2] = bk.blue;
    _outsideBufferColor[3] = bk.alpha;
  }

  @override
  Uint8List pixel(RefParam<int> bufferByteOffset) {
    if (_x >= 0 &&
        _x < _sourceImage.width &&
        _y >= 0 &&
        _y < _sourceImage.height) {
      bufferByteOffset.value = _sourceImage.getBufferOffsetXY(_x, _y);
      return _sourceImage.getBuffer();
    }

    bufferByteOffset.value = 0;
    return _outsideBufferColor;
  }
}

class ImageBufferAccessorClamp extends ImageBufferAccessorCommon {
  ImageBufferAccessorClamp(IImageByte pixf) : super(pixf);
}

abstract class IImageBufferAccessorFloat {
  Float32List span(int x, int y, int len, RefParam<int> bufferIndex);

  Float32List nextX(RefParam<int> bufferFloatOffset);

  Float32List nextY(RefParam<int> bufferFloatOffset);

  IImageFloat get sourceImage;
}

class ImageBufferAccessorCommonFloat implements IImageBufferAccessorFloat {
  late IImageFloat _sourceImage;
  int _x = 0;
  int _x0 = 0;
  int _y = 0;
  int _distanceBetweenPixelsInclusive = 0;
  late Float32List _buffer;
  int _currentBufferOffset = -1;

  ImageBufferAccessorCommonFloat(IImageFloat pixf) {
    attach(pixf);
  }

  void attach(IImageFloat pixf) {
    _sourceImage = pixf;
    _buffer = _sourceImage.getBuffer();
    _distanceBetweenPixelsInclusive =
        _sourceImage.getFloatsBetweenPixelsInclusive();
  }

  @override
  IImageFloat get sourceImage => _sourceImage;

  Float32List pixel(RefParam<int> bufferFloatOffset) {
    int x = _x;
    int y = _y;
    if (x >= _sourceImage.width) {
      x = x < 0 ? 0 : _sourceImage.width - 1;
    }
    if (y >= _sourceImage.height) {
      y = y < 0 ? 0 : _sourceImage.height - 1;
    }

    bufferFloatOffset.value = _sourceImage.getBufferOffsetXY(x, y);
    return _sourceImage.getBuffer();
  }

  @override
  Float32List span(int x, int y, int len, RefParam<int> bufferOffset) {
    _x = _x0 = x;
    _y = y;
    if (y >= 0 &&
        y < _sourceImage.height &&
        x >= 0 &&
        x + len <= _sourceImage.width) {
      bufferOffset.value = _sourceImage.getBufferOffsetXY(x, y);
      _buffer = _sourceImage.getBuffer();
      _currentBufferOffset = bufferOffset.value;
      return _buffer;
    }

    _currentBufferOffset = -1;
    return pixel(bufferOffset);
  }

  @override
  Float32List nextX(RefParam<int> bufferOffset) {
    if (_currentBufferOffset != -1) {
      _currentBufferOffset += _distanceBetweenPixelsInclusive;
      bufferOffset.value = _currentBufferOffset;
      return _buffer;
    }
    ++_x;
    return pixel(bufferOffset);
  }

  @override
  Float32List nextY(RefParam<int> bufferOffset) {
    ++_y;
    _x = _x0;
    if (_currentBufferOffset != -1 && _y < _sourceImage.height) {
      _currentBufferOffset = _sourceImage.getBufferOffsetXY(_x, _y);
      bufferOffset.value = _currentBufferOffset;
      return _buffer;
    }

    _currentBufferOffset = -1;
    return pixel(bufferOffset);
  }
}

class ImageBufferAccessorClipFloat extends ImageBufferAccessorCommonFloat {
  late Float32List _outsideBufferColor;

  ImageBufferAccessorClipFloat(IImageFloat sourceImage, ColorF bk)
      : super(sourceImage) {
    _outsideBufferColor = Float32List(4);
    _outsideBufferColor[0] = bk.red;
    _outsideBufferColor[1] = bk.green;
    _outsideBufferColor[2] = bk.blue;
    _outsideBufferColor[3] = bk.alpha;
  }

  @override
  Float32List pixel(RefParam<int> bufferFloatOffset) {
    if (_x >= 0 &&
        _x < _sourceImage.width &&
        _y >= 0 &&
        _y < _sourceImage.height) {
      bufferFloatOffset.value = _sourceImage.getBufferOffsetXY(_x, _y);
      return _sourceImage.getBuffer();
    }

    bufferFloatOffset.value = 0;
    return _outsideBufferColor;
  }
}
