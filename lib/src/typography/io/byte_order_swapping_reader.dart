// Apache2, 2014-2016, Samuel Carlsson, WinterDev
// Ported to Dart by insinfo

import 'dart:typed_data';

/// Binary reader that handles big-endian byte order (Motorola-style).
/// All OpenType fonts use big-endian byte ordering.
class ByteOrderSwappingBinaryReader {
  final ByteData _byteData;
  int _position = 0;

  ByteOrderSwappingBinaryReader(Uint8List data)
      : _byteData = ByteData.view(data.buffer, data.offsetInBytes, data.length);

  /// Current position in the byte stream
  int get position => _position;

  /// Total length of the data
  int get length => _byteData.lengthInBytes;

  /// Seek to a specific position
  void seek(int position) {
    if (position < 0 || position > _byteData.lengthInBytes) {
      throw RangeError('Position $position is out of range [0, ${_byteData.lengthInBytes}]');
    }
    _position = position;
  }

  /// Skip forward by count bytes
  void skip(int count) {
    _position += count;
    if (_position > _byteData.lengthInBytes) {
      throw RangeError('Position $_position is out of range');
    }
  }

  /// Read a single byte
  int readByte() {
    final value = _byteData.getUint8(_position);
    _position += 1;
    return value;
  }

  /// Read a signed 8-bit integer
  int readSByte() {
    final value = _byteData.getInt8(_position);
    _position += 1;
    return value;
  }

  /// Read an unsigned 16-bit integer (big-endian)
  int readUInt16() {
    final value = _byteData.getUint16(_position, Endian.big);
    _position += 2;
    return value;
  }

  /// Read a signed 16-bit integer (big-endian)
  int readInt16() {
    final value = _byteData.getInt16(_position, Endian.big);
    _position += 2;
    return value;
  }

  /// Read an unsigned 32-bit integer (big-endian)
  int readUInt32() {
    final value = _byteData.getUint32(_position, Endian.big);
    _position += 4;
    return value;
  }

  /// Read a signed 32-bit integer (big-endian)
  int readInt32() {
    final value = _byteData.getInt32(_position, Endian.big);
    _position += 4;
    return value;
  }

  /// Read an unsigned 64-bit integer (big-endian)
  int readUInt64() {
    final value = _byteData.getUint64(_position, Endian.big);
    _position += 8;
    return value;
  }

  /// Read a signed 64-bit integer (big-endian)
  int readInt64() {
    final value = _byteData.getInt64(_position, Endian.big);
    _position += 8;
    return value;
  }

  /// Read a 64-bit double (big-endian) - used in CFF fonts
  double readDouble() {
    final value = _byteData.getFloat64(_position, Endian.big);
    _position += 8;
    return value;
  }

  /// Read a 32-bit float (big-endian)
  double readFloat() {
    final value = _byteData.getFloat32(_position, Endian.big);
    _position += 4;
    return value;
  }

  /// Read a specific number of bytes
  Uint8List readBytes(int count) {
    if (_position + count > _byteData.lengthInBytes) {
      throw RangeError('Cannot read $count bytes from position $_position');
    }
    final bytes = Uint8List.view(
      _byteData.buffer,
      _byteData.offsetInBytes + _position,
      count,
    );
    _position += count;
    return bytes;
  }

  /// Read a tag (4 bytes as string)
  String readTag() {
    final bytes = readBytes(4);
    return String.fromCharCodes(bytes);
  }

  /// Peek at the next byte without advancing position
  int peekByte() {
    return _byteData.getUint8(_position);
  }

  /// Check if we're at the end of the stream
  bool get isEndOfStream => _position >= _byteData.lengthInBytes;

  /// Get remaining bytes in the stream
  int get remainingBytes => _byteData.lengthInBytes - _position;
}
