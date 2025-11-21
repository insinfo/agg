import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';

/// Simple pair of geometry + fill color for parsed SVG shapes.
class ColoredVertexSource {
  final VertexStorage vertices;
  final Color fill;

  ColoredVertexSource(this.vertices, this.fill);
}
