/// Integer DDA line interpolators used by AGG.
class DdaLineInterpolator {
  int _y = 0;
  int _inc = 0;
  int _dy = 0;
  final int _fractionShift;

  DdaLineInterpolator(this._fractionShift);

  DdaLineInterpolator.init(int y1, int y2, int count, int fractionShift)
      : _fractionShift = fractionShift {
    _y = y1;
    _inc = ((y2 - y1) << _fractionShift) ~/ (count == 0 ? 1 : count);
    _dy = 0;
  }

  void next() {
    _dy += _inc;
  }

  void prev() {
    _dy -= _inc;
  }

  void nextN(int n) {
    _dy += _inc * n;
  }

  void prevN(int n) {
    _dy -= _inc * n;
  }

  int y() => _y + (_dy >> _fractionShift);
  int dy() => _dy;
}

class Dda2LineInterpolator {
  int _mCnt = 1;
  int _mLft = 0;
  int _mRem = 0;
  int _mMod = 0;
  int _mY = 0;

  Dda2LineInterpolator();

  // Forward-adjusted line
  Dda2LineInterpolator.forward(int y1, int y2, int count) {
    _init(y1, y2, count, forward: true);
  }

  // Backward-adjusted line
  Dda2LineInterpolator.backward(int y1, int y2, int count) {
    _init(y1, y2, count, forward: false);
  }

  // Backward-adjusted line with implicit y1=0
  Dda2LineInterpolator.backwardFromZero(int y, int count) {
    _mCnt = count <= 0 ? 1 : count;
    _mLft = y ~/ _mCnt;
    _mRem = y % _mCnt;
    _mMod = _mRem;
    _mY = 0;
    if (_mMod <= 0) {
      _mMod += count;
      _mRem += count;
      _mLft--;
    }
  }

  void _init(int y1, int y2, int count, {required bool forward}) {
    _mCnt = count <= 0 ? 1 : count;
    _mLft = (y2 - y1) ~/ _mCnt;
    _mRem = (y2 - y1) % _mCnt;
    _mMod = _mRem;
    _mY = y1;

    if (_mMod <= 0) {
      _mMod += count;
      _mRem += count;
      _mLft--;
    }
    if (forward) {
      _mMod -= count;
    }
  }

  void next() {
    _mMod += _mRem;
    _mY += _mLft;
    if (_mMod > 0) {
      _mMod -= _mCnt;
      _mY++;
    }
  }

  void prev() {
    if (_mMod <= _mRem) {
      _mMod += _mCnt;
      _mY--;
    }
    _mMod -= _mRem;
    _mY -= _mLft;
  }

  void adjustForward() {
    _mMod -= _mCnt;
  }

  void adjustBackward() {
    _mMod += _mCnt;
  }

  int y() => _mY;
  int mod() => _mMod;
}
