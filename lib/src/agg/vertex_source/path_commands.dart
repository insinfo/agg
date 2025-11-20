/// Path command flags for vertex data
enum FlagsAndCommand {
  // Command codes
  commandStop(0x00),
  commandMoveTo(0x01),
  commandLineTo(0x02),
  commandCurve3(0x03),
  commandCurve4(0x04),
  commandCurveN(0x05),
  commandCatrom(0x06),
  commandUbspline(0x07),
  commandEndPoly(0x0F),
  commandMask(0x0F),

  // Flag codes
  flagNone(0x00),
  flagCCW(0x10),
  flagCW(0x20),
  flagClose(0x40),
  flagMask(0xF0);

  final int value;
  const FlagsAndCommand(this.value);

  bool get isStop => (value & commandMask.value) == commandStop.value;
  bool get isMoveTo => (value & commandMask.value) == commandMoveTo.value;
  bool get isLineTo => (value & commandMask.value) == commandLineTo.value;
  bool get isVertex =>
      (value & commandMask.value) >= commandMoveTo.value &&
      (value & commandMask.value) < commandEndPoly.value;
  bool get isCurve =>
      (value & commandMask.value) == commandCurve3.value ||
      (value & commandMask.value) == commandCurve4.value;
  bool get isCurve3 => (value & commandMask.value) == commandCurve3.value;
  bool get isCurve4 => (value & commandMask.value) == commandCurve4.value;
  bool get isEndPoly => (value & commandMask.value) == commandEndPoly.value;
  bool get isClose => (value & flagClose.value) == flagClose.value;
  bool get isCCW => (value & flagCCW.value) == flagCCW.value;
  bool get isCW => (value & flagCW.value) == flagCW.value;

  static FlagsAndCommand fromValue(int value) {
    for (var cmd in FlagsAndCommand.values) {
      if (cmd.value == value) return cmd;
    }
    return FlagsAndCommand.commandStop;
  }

  FlagsAndCommand operator |(FlagsAndCommand other) {
    return FlagsAndCommand.fromValue(value | other.value);
  }

  FlagsAndCommand operator &(FlagsAndCommand other) {
    return FlagsAndCommand.fromValue(value & other.value);
  }
}

/// Hint for vertex command interpretation
enum CommandHint {
  none,
  c3Cpx,
  c3Cpy,
  c4Cp1x,
  c4Cp1y,
  c4Cp2x,
  c4Cp2y,
}

/// Helper functions for path commands
class ShapePath {
  static bool isStop(FlagsAndCommand cmd) => cmd.isStop;
  static bool isMoveTo(FlagsAndCommand cmd) => cmd.isMoveTo;
  static bool isLineTo(FlagsAndCommand cmd) => cmd.isLineTo;
  static bool isVertex(FlagsAndCommand cmd) => cmd.isVertex;
  static bool isCurve(FlagsAndCommand cmd) => cmd.isCurve;
  static bool isCurve3(FlagsAndCommand cmd) => cmd.isCurve3;
  static bool isCurve4(FlagsAndCommand cmd) => cmd.isCurve4;
  static bool isEndPoly(FlagsAndCommand cmd) => cmd.isEndPoly;
  static bool isClose(FlagsAndCommand cmd) => cmd.isClose;
  static bool isCCW(FlagsAndCommand cmd) => cmd.isCCW;
  static bool isCW(FlagsAndCommand cmd) => cmd.isCW;

  static FlagsAndCommand getCommand(FlagsAndCommand cmd) {
    return FlagsAndCommand.fromValue(
        cmd.value & FlagsAndCommand.commandMask.value);
  }

  static FlagsAndCommand getFlags(FlagsAndCommand cmd) {
    return FlagsAndCommand.fromValue(
        cmd.value & FlagsAndCommand.flagMask.value);
  }

  static FlagsAndCommand clearFlags(FlagsAndCommand cmd) {
    return FlagsAndCommand.fromValue(
        cmd.value & FlagsAndCommand.commandMask.value);
  }

  static FlagsAndCommand setFlags(FlagsAndCommand cmd, FlagsAndCommand flags) {
    return FlagsAndCommand.fromValue(clearFlags(cmd).value | flags.value);
  }
}
