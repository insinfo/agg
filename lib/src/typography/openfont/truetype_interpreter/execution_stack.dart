import 'exceptions.dart';

class ExecutionStack {
  final List<int> _s;
  int _count = 0;

  ExecutionStack(int maxStack) : _s = List<int>.filled(maxStack, 0);

  int peek([int index = 0]) {
    if (index < 0 || index >= _count) {
      throw InvalidTrueTypeFontException('Stack underflow');
    }
    return _s[_count - index - 1];
  }

  bool popBool() => pop() != 0;

  double popFloat() => f26Dot6ToFloat(pop());

  void pushBool(bool value) => push(value ? 1 : 0);

  void pushFloat(double value) => push(floatToF26Dot6(value));

  void clear() {
    _count = 0;
  }

  void depth() {
    push(_count);
  }

  void duplicate() {
    push(peek());
  }

  void copy([int? index]) {
    if (index == null) {
      copyAt(pop() - 1);
    } else {
      copyAt(index);
    }
  }
  
  void copyAt(int index) {
      push(peek(index));
  }

  void move() {
    moveAt(pop() - 1);
  }

  void roll() {
    moveAt(2);
  }

  void moveAt(int index) {
    var val = peek(index);
    for (int i = _count - index - 1; i < _count - 1; i++) {
      _s[i] = _s[i + 1];
    }
    _s[_count - 1] = val;
  }

  void swap() {
    if (_count < 2) {
      throw InvalidTrueTypeFontException('Stack underflow');
    }

    var tmp = _s[_count - 1];
    _s[_count - 1] = _s[_count - 2];
    _s[_count - 2] = tmp;
  }

  void push(int value) {
    if (_count == _s.length) {
      throw InvalidTrueTypeFontException('Stack overflow');
    }
    _s[_count++] = value;
  }

  int pop() {
    if (_count == 0) {
      throw InvalidTrueTypeFontException('Stack underflow');
    }
    return _s[--_count];
  }

  static double f26Dot6ToFloat(int value) {
    return value / 64.0;
  }

  static int floatToF26Dot6(double value) {
    return (value * 64.0).round();
  }
}
