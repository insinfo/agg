import 'package:agg/src/shared/ref_param.dart';
import 'ivertex_source.dart';
import 'path_commands.dart';
import 'vertex_data.dart';

abstract class VertexSourceLegacySupport implements IVertexSource {
  Iterator<VertexData>? _currentIterator;

  @override
  void rewind([int pathId = 0]) {
    _currentIterator = vertices().iterator;
    // In Dart, iterator starts before the first element.
    // We don't call moveNext() here because vertex() will call it if needed,
    // or we need to handle the first call.
    // Actually, the C# code calls MoveNext() immediately.
    // "currentEnumerator.MoveNext();"
    // This means Current is valid after Rewind.
    
    if (_currentIterator != null) {
      _currentIterator!.moveNext();
    }
  }

  @override
  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    if (_currentIterator == null) {
      rewind(0);
    }

    if (_currentIterator == null) {
       // Should not happen if vertices() returns at least Stop
       x.value = 0;
       y.value = 0;
       return FlagsAndCommand.commandStop;
    }

    var current = _currentIterator!.current;
    x.value = current.x;
    y.value = current.y;
    var command = current.command;

    // Move to next for the next call
    if (!_currentIterator!.moveNext()) {
       // If we reached the end, we might want to ensure we return Stop next time?
       // But usually the last element is Stop.
       // If the iterator is exhausted, we can't get current anymore.
       // The C# code assumes Vertices() yields a Stop command at the end.
    }

    return command;
  }

  @override
  Iterable<VertexData> vertices();
}
