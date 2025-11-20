import 'path_commands.dart';
import 'vertex_data.dart';

/// Interface for vertex sources in AGG
abstract class IVertexSource {
  /// Rewind the vertex source to the beginning
  void rewind([int pathId = 0]);

  /// Get the next vertex
  /// Returns the command and sets x, y to the vertex position
  FlagsAndCommand vertex(VertexOutput output);

  /// Get a hash code for the vertex source
  int getLongHashCode([int hash = 0xcbf29ce484222325]);

  /// Get all vertices as an iterable
  Iterable<VertexData> vertices();
}

/// Output parameter holder for vertex method
class VertexOutput {
  double x = 0;
  double y = 0;

  VertexOutput([this.x = 0, this.y = 0]);

  void set(double newX, double newY) {
    x = newX;
    y = newY;
  }

  ({double x, double y}) get position => (x: x, y: y);
}
