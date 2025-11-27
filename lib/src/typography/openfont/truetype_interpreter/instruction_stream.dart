import 'dart:typed_data';
import 'opcodes.dart';
import 'exceptions.dart';

class InstructionStream {
  final Uint8List instructions;
  int ip = 0;

  InstructionStream(this.instructions);

  bool get isValid => instructions.isNotEmpty;
  bool get done => ip >= instructions.length;

  int nextByte() {
    if (done) {
      throw InvalidTrueTypeFontException('Unexpected end of instruction stream');
    }
    return instructions[ip++];
  }

  OpCode nextOpCode() {
    return OpCodeExtension.fromInt(nextByte());
  }

  int nextWord() {
    int b1 = nextByte();
    int b2 = nextByte();
    int val = (b1 << 8) | b2;
    // Convert to signed 16-bit
    if (val >= 0x8000) {
      val -= 0x10000;
    }
    return val;
  }

  void jump(int offset) {
    ip += offset;
  }
}
