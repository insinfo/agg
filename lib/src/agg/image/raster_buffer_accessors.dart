import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/primitives/color.dart';

/// Minimal span accessor for byte-based images.
abstract class IImageBufferAccessor {
  int get bufferOffset;
  IImageByte get sourceImage;

  /// Returns backing buffer pointing at x/y span start. Sets [bufferIndex].
  List<int> span(int x, int y, int len, int Function(int) bufferIndex);

  /// Advance one pixel in X, returning buffer and offset.
  List<int> nextX(int Function(int) bufferIndex);

  /// Advance one pixel in Y (resets X).
  List<int> nextY(int Function(int) bufferIndex);
}

class ImageBufferAccessorCommon implements IImageBufferAccessor {
  @override
  IImageByte sourceImage;
  int _x = 0;
  int _x0 = 0;
  int _y = 0;
  int _currentOffset = -1;
  int _distanceBetweenPixelsInclusive = 0;
  late List<int> _buffer;

  ImageBufferAccessorCommon(this.sourceImage) {
    _buffer = sourceImage.getBuffer();
    _distanceBetweenPixelsInclusive = sourceImage.getBytesBetweenPixelsInclusive();
  }

  @override
  int get bufferOffset => _currentOffset;

  @override
  List<int> span(int x, int y, int len, int Function(int) bufferIndex) {
    _x = _x0 = x;
    _y = y;
    if (y >= 0 &&
        y < sourceImage.height &&
        x >= 0 &&
        x + len <= sourceImage.width) {
      _currentOffset = sourceImage.getBufferOffsetXY(x, y);
      bufferIndex(_currentOffset);
      return _buffer;
    }

    _currentOffset = -1;
    final buf = _pixel(bufferIndex);
    return buf;
  }

  @override
  List<int> nextX(int Function(int) bufferIndex) {
    if (_currentOffset != -1) {
      _currentOffset += _distanceBetweenPixelsInclusive;
      bufferIndex(_currentOffset);
      return _buffer;
    }
    _x++;
    return _pixel(bufferIndex);
  }

  @override
  List<int> nextY(int Function(int) bufferIndex) {
    _y++;
    _x = _x0;
    if (_currentOffset != -1 && _y >= 0 && _y < sourceImage.height) {
      _currentOffset = sourceImage.getBufferOffsetXY(_x, _y);
      bufferIndex(_currentOffset);
      return _buffer;
    }
    _currentOffset = -1;
    return _pixel(bufferIndex);
  }

  List<int> _pixel(int Function(int) bufferIndex) {
    int x = _x;
    int y = _y;
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    if (x >= sourceImage.width) x = sourceImage.width - 1;
    if (y >= sourceImage.height) y = sourceImage.height - 1;
    _currentOffset = sourceImage.getBufferOffsetXY(x, y);
    bufferIndex(_currentOffset);
    return _buffer;
  }
}

class ImageBufferAccessorClip extends ImageBufferAccessorCommon {
  final List<int> _outside;
  ImageBufferAccessorClip(IImageByte sourceImage, Color bk)
      : _outside = <int>[bk.red, bk.green, bk.blue, bk.alpha],
        super(sourceImage);

  @override
  List<int> span(int x, int y, int len, int Function(int) bufferIndex) {
    _x = _x0 = x;
    _y = y;
    if (y >= 0 &&
        y < sourceImage.height &&
        x >= 0 &&
        x + len <= sourceImage.width) {
      _currentOffset = sourceImage.getBufferOffsetXY(x, y);
      bufferIndex(_currentOffset);
      return sourceImage.getBuffer();
    }
    _currentOffset = 0;
    bufferIndex(0);
    return _outside;
  }

  @override
  List<int> nextX(int Function(int) bufferIndex) {
    _x++;
    if (_x >= 0 &&
        _x < sourceImage.width &&
        _y >= 0 &&
        _y < sourceImage.height) {
      _currentOffset = sourceImage.getBufferOffsetXY(_x, _y);
      bufferIndex(_currentOffset);
      return sourceImage.getBuffer();
    }
    _currentOffset = 0;
    bufferIndex(0);
    return _outside;
  }

  @override
  List<int> nextY(int Function(int) bufferIndex) {
    _y++;
    _x = _x0;
    if (_x >= 0 &&
        _x < sourceImage.width &&
        _y >= 0 &&
        _y < sourceImage.height) {
      _currentOffset = sourceImage.getBufferOffsetXY(_x, _y);
      bufferIndex(_currentOffset);
      return sourceImage.getBuffer();
    }
    _currentOffset = 0;
    bufferIndex(0);
    return _outside;
  }
}
