import 'dart:typed_data';
import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/util.dart';

abstract class IAlphaMask {
  int pixel(int x, int y);

  int combinePixel(int x, int y, int val);

  void fillHspan(int x, int y, Uint8List dst, int dstIndex, int numPix);

  void fillVspan(int x, int y, Uint8List dst, int dstIndex, int numPix);

  void combineHspanFullCover(int x, int y, Uint8List dst, int dstIndex, int numPix);

  void combineHspan(int x, int y, Uint8List dst, int dstIndex, int numPix);

  void combineVspan(int x, int y, Uint8List dst, int dstIndex, int numPix);
}

class AlphaMaskByteUnclipped implements IAlphaMask {
  IImageByte m_rbuf;
  int m_Step;
  int m_Offset;

  static const int coverShift = 8;
  static const int coverNone = 0;
  static const int coverFull = 255;

  AlphaMaskByteUnclipped(this.m_rbuf, this.m_Step, this.m_Offset);

  void attach(IImageByte rbuf) {
    m_rbuf = rbuf;
  }

  @override
  int pixel(int x, int y) {
    int bufferIndex = m_rbuf.getBufferOffsetXY(x, y);
    Uint8List buffer = m_rbuf.getBuffer();
    return buffer[bufferIndex];
  }

  @override
  int combinePixel(int x, int y, int val) {
    int bufferIndex = m_rbuf.getBufferOffsetXY(x, y);
    Uint8List buffer = m_rbuf.getBuffer();
    return (255 + val * buffer[bufferIndex]) >> 8;
  }

  @override
  void fillHspan(int x, int y, Uint8List dst, int dstIndex, int numPix) {
    throw UnimplementedError();
  }

  @override
  void combineHspanFullCover(int x, int y, Uint8List covers, int coversIndex, int count) {
    int maskIndex = m_rbuf.getBufferOffsetXY(x, y);
    Uint8List mask = m_rbuf.getBuffer();
    for (int i = 0; i < count; i++) {
      covers[coversIndex++] = mask[maskIndex++];
    }
  }

  @override
  void combineHspan(int x, int y, Uint8List covers, int coversIndex, int count) {
    int maskIndex = m_rbuf.getBufferOffsetXY(x, y);
    Uint8List mask = m_rbuf.getBuffer();
    for (int i = 0; i < count; i++) {
      covers[coversIndex] = (255 + (covers[coversIndex]) * mask[maskIndex]) >> 8;
      coversIndex++;
      maskIndex++;
    }
  }

  @override
  void fillVspan(int x, int y, Uint8List dst, int dstIndex, int numPix) {
    throw UnimplementedError();
  }

  @override
  void combineVspan(int x, int y, Uint8List dst, int dstIndex, int numPix) {
    throw UnimplementedError();
  }
}

class AlphaMaskByteClipped implements IAlphaMask {
  IImageByte m_rbuf;
  int m_Step;
  int m_Offset;

  static const int coverShift = 8;
  static const int coverNone = 0;
  static const int coverFull = 255;

  AlphaMaskByteClipped(this.m_rbuf, this.m_Step, this.m_Offset);

  void attach(IImageByte rbuf) {
    m_rbuf = rbuf;
  }

  @override
  int pixel(int x, int y) {
    if (x >= 0 && x < m_rbuf.width && y >= 0 && y < m_rbuf.height) {
      int bufferIndex = m_rbuf.getBufferOffsetXY(x, y);
      Uint8List buffer = m_rbuf.getBuffer();
      return buffer[bufferIndex];
    }
    return 0;
  }

  @override
  int combinePixel(int x, int y, int val) {
    if (x >= 0 && x < m_rbuf.width && y >= 0 && y < m_rbuf.height) {
      int bufferIndex = m_rbuf.getBufferOffsetXY(x, y);
      Uint8List buffer = m_rbuf.getBuffer();
      return (val * buffer[bufferIndex] + 255) >> 8;
    }
    return 0;
  }

  @override
  void fillHspan(int x, int y, Uint8List dst, int dstIndex, int numPix) {
    throw UnimplementedError();
  }

  @override
  void combineHspanFullCover(int x, int y, Uint8List covers, int coversIndex, int numPix) {
    int xmax = m_rbuf.width - 1;
    int ymax = m_rbuf.height - 1;

    int count = numPix;

    if (y < 0 || y > ymax) {
      Util.memClear(covers, coversIndex, numPix);
      return;
    }

    if (x < 0) {
      count += x;
      if (count <= 0) {
        Util.memClear(covers, coversIndex, numPix);
        return;
      }
      Util.memClear(covers, coversIndex, -x);
      coversIndex -= x;
      x = 0;
    }

    if (x + count > xmax) {
      int rest = x + count - xmax - 1;
      count -= rest;
      if (count <= 0) {
        Util.memClear(covers, coversIndex, numPix);
        return;
      }
      Util.memClear(covers, coversIndex + count, rest);
    }

    int maskIndex = m_rbuf.getBufferOffsetXY(x, y);
    Uint8List mask = m_rbuf.getBuffer();
    for (int i = 0; i < count; i++) {
      covers[coversIndex++] = mask[maskIndex++];
    }
  }

  @override
  void combineHspan(int x, int y, Uint8List buffer, int bufferIndex, int numPix) {
    int xmax = m_rbuf.width - 1;
    int ymax = m_rbuf.height - 1;

    int count = numPix;
    Uint8List covers = buffer;
    int coversIndex = bufferIndex;

    if (y < 0 || y > ymax) {
      Util.memClear(buffer, bufferIndex, numPix);
      return;
    }

    if (x < 0) {
      count += x;
      if (count <= 0) {
        Util.memClear(buffer, bufferIndex, numPix);
        return;
      }
      Util.memClear(covers, coversIndex, -x);
      coversIndex -= x;
      x = 0;
    }

    if (x + count > xmax) {
      int rest = x + count - xmax - 1;
      count -= rest;
      if (count <= 0) {
        Util.memClear(buffer, bufferIndex, numPix);
        return;
      }
      Util.memClear(covers, coversIndex + count, rest);
    }

    int maskIndex = m_rbuf.getBufferOffsetXY(x, y);
    Uint8List mask = m_rbuf.getBuffer();
    for (int i = 0; i < count; i++) {
      covers[coversIndex] = ((covers[coversIndex]) * mask[maskIndex] + 255) >> 8;
      coversIndex++;
      maskIndex++;
    }
  }

  @override
  void fillVspan(int x, int y, Uint8List dst, int dstIndex, int numPix) {
    throw UnimplementedError();
  }

  @override
  void combineVspan(int x, int y, Uint8List dst, int dstIndex, int numPix) {
    throw UnimplementedError();
  }
}
