import '../vertex_source/path_commands.dart';

abstract class IMarkers {
  void clear();
  void addVertex(double x, double y, FlagsAndCommand cmd);
}
