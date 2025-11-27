import '../vertex_sequence.dart';

/// Path command flags for vertex data
class FlagsAndCommand {
  final int value;
  const FlagsAndCommand._(this.value);

  // Command codes
  static const commandStop = FlagsAndCommand._(0x00);
  static const commandMoveTo = FlagsAndCommand._(0x01);
  static const commandLineTo = FlagsAndCommand._(0x02);
  static const commandCurve3 = FlagsAndCommand._(0x03);
  static const commandCurve4 = FlagsAndCommand._(0x04);
  static const commandCurveN = FlagsAndCommand._(0x05);
  static const commandCatrom = FlagsAndCommand._(0x06);
  static const commandUbspline = FlagsAndCommand._(0x07);
  static const commandEndPoly = FlagsAndCommand._(0x0F);
  static const commandMask = FlagsAndCommand._(0x0F);

  // Flag codes
  static const flagNone = FlagsAndCommand._(0x00);
  static const flagCCW = FlagsAndCommand._(0x10);
  static const flagCW = FlagsAndCommand._(0x20);
  static const flagClose = FlagsAndCommand._(0x40);
  static const flagMask = FlagsAndCommand._(0xF0);

  static const List<FlagsAndCommand> values = <FlagsAndCommand>[
    commandStop,
    commandMoveTo,
    commandLineTo,
    commandCurve3,
    commandCurve4,
    commandCurveN,
    commandCatrom,
    commandUbspline,
    commandEndPoly,
    commandMask,
    flagNone,
    flagCCW,
    flagCW,
    flagClose,
    flagMask,
  ];

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
    return FlagsAndCommand._(value);
  }

  FlagsAndCommand operator |(FlagsAndCommand other) {
    return FlagsAndCommand.fromValue(value | other.value);
  }

  FlagsAndCommand operator &(FlagsAndCommand other) {
    return FlagsAndCommand.fromValue(value & other.value);
  }

  String get name {
    switch (value & commandMask.value) {
      case 0x00:
        return 'commandStop';
      case 0x01:
        return 'commandMoveTo';
      case 0x02:
        return 'commandLineTo';
      case 0x03:
        return 'commandCurve3';
      case 0x04:
        return 'commandCurve4';
      case 0x05:
        return 'commandCurveN';
      case 0x06:
        return 'commandCatrom';
      case 0x07:
        return 'commandUbspline';
      case 0x0F:
        return 'commandEndPoly';
    }
    return 'command($value)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlagsAndCommand && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Typedef for backward compatibility
typedef PathCommand = FlagsAndCommand;

/// Helper class for path commands
class PathCommands {
  static const stop = FlagsAndCommand.commandStop;
  static const moveTo = FlagsAndCommand.commandMoveTo;
  static const lineTo = FlagsAndCommand.commandLineTo;
  static const curve3 = FlagsAndCommand.commandCurve3;
  static const curve4 = FlagsAndCommand.commandCurve4;
  static const endPoly = FlagsAndCommand.commandEndPoly;
  static const mask = FlagsAndCommand.commandMask;
  static const flagClose = FlagsAndCommand.flagClose;
  static const flagsMask = FlagsAndCommand.flagMask;

  static bool isVertex(FlagsAndCommand cmd) => cmd.isVertex;
  static bool isStop(FlagsAndCommand cmd) => cmd.isStop;
  static bool isMoveTo(FlagsAndCommand cmd) => cmd.isMoveTo;
  static bool isLineTo(FlagsAndCommand cmd) => cmd.isLineTo;
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

  static FlagsAndCommand getCloseFlag(FlagsAndCommand cmd) {
    return cmd & FlagsAndCommand.flagClose;
  }

  static FlagsAndCommand getOrientation(FlagsAndCommand cmd) {
    return cmd & (FlagsAndCommand.flagCCW | FlagsAndCommand.flagCW);
  }

  static bool isOriented(FlagsAndCommand cmd) {
    return (cmd.value & (FlagsAndCommand.flagCCW.value | FlagsAndCommand.flagCW.value)) != 0;
  }

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

  static void shortenPath(VertexSequence vs, double s, [int closed = 0]) {
    if (s > 0.0 && vs.length > 1) {
      double d;
      int n = vs.length - 2;
      while (n >= 0) {
        d = vs[n].dist;
        if (d > s) break;
        vs.removeLast();
        s -= d;
        --n;
      }
      if (vs.length < 2) {
        vs.clear();
      } else {
        n = vs.length - 1;
        VertexDistance prev = vs[n - 1];
        VertexDistance last = vs[n];
        d = (prev.dist - s) / prev.dist;
        double x = prev.x + (last.x - prev.x) * d;
        double y = prev.y + (last.y - prev.y) * d;
        last.x = x;
        last.y = y;
        if (!prev.isEqual(last)) vs.removeLast();
        vs.close(closed != 0);
      }
    }
  }
}
