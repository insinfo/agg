import 'package:vector_math/vector_math.dart';

enum RoundMode {
  toHalfGrid,
  toGrid,
  toDoubleGrid,
  downToGrid,
  upToGrid,
  off,
  superRound,
  super45
}

class InstructionControlFlags {
  static const int none = 0;
  static const int inhibitGridFitting = 0x1;
  static const int useDefaultGraphicsState = 0x2;
}

class GraphicsState {
  Vector2 freedom = Vector2(1.0, 0.0);
  Vector2 dualProjection = Vector2(1.0, 0.0);
  Vector2 projection = Vector2(1.0, 0.0);
  int instructionControl = InstructionControlFlags.none;
  RoundMode roundState = RoundMode.toGrid;
  double minDistance = 1.0;
  double controlValueCutIn = 17.0 / 16.0;
  double singleWidthCutIn = 0.0;
  double singleWidthValue = 0.0;
  int deltaBase = 9;
  int deltaShift = 3;
  int loop = 1;
  int rp0 = 0;
  int rp1 = 0;
  int rp2 = 0;
  bool autoFlip = true;

  void reset() {
    freedom = Vector2(1.0, 0.0);
    projection = Vector2(1.0, 0.0);
    dualProjection = Vector2(1.0, 0.0);
    instructionControl = InstructionControlFlags.none;
    roundState = RoundMode.toGrid;
    minDistance = 1.0;
    controlValueCutIn = 17.0 / 16.0;
    singleWidthCutIn = 0.0;
    singleWidthValue = 0.0;
    deltaBase = 9;
    deltaShift = 3;
    loop = 1;
    rp0 = 0;
    rp1 = 0;
    rp2 = 0;
    autoFlip = true;
  }
}
