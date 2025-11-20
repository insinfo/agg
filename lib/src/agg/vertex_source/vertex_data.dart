import 'path_commands.dart';

/// Represents a vertex with position and command
class VertexData {
  FlagsAndCommand command;
  double x;
  double y;
  CommandHint hint;

  VertexData(this.command, this.x, this.y, [this.hint = CommandHint.none]);

  VertexData.fromPosition(this.command, ({double x, double y}) position,
      [this.hint = CommandHint.none])
      : x = position.x,
        y = position.y;

  // Convenience getters
  bool get isClose => command.isClose;
  bool get isCurve => command.isCurve;
  bool get isCurve3 => command.isCurve3;
  bool get isCurve4 => command.isCurve4;
  bool get isLineTo => command.isLineTo;
  bool get isMoveTo => command.isMoveTo;
  bool get isStop => command.isStop;
  bool get isVertex => command.isVertex;
  bool get isEndPoly => command.isEndPoly;

  ({double x, double y}) get position => (x: x, y: y);

  set position(({double x, double y}) pos) {
    x = pos.x;
    y = pos.y;
  }

  @override
  String toString() {
    if (hint != CommandHint.none) {
      return '${command.name}:($x, $y) ($hint)';
    }
    return '${command.name}:($x, $y)';
  }

  int getLongHashCode([int hash = 0xcbf29ce484222325]) {
    // FNV-1a hash
    hash ^= x.hashCode;
    hash *= 1099511628211;
    hash ^= y.hashCode;
    hash *= 1099511628211;
    hash ^= command.value;
    hash *= 1099511628211;
    return hash;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VertexData &&
        other.command == command &&
        other.x == x &&
        other.y == y &&
        other.hint == hint;
  }

  @override
  int get hashCode => Object.hash(command, x, y, hint);
}
