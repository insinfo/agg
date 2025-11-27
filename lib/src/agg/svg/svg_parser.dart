import 'package:agg/src/agg/svg/colored_vertex_source.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';
import 'package:agg/src/agg/svg/svg_parser_new.dart';
import 'package:agg/src/agg/svg/svg_paint.dart';
import 'package:agg/src/agg/transform/affine.dart';

/// Lightweight SVG parser for paths and polygons.
///
/// This is intentionally minimal: it understands `<path d="...">` and
/// `<polygon points="...">` with solid fills (#RRGGBB or in style).
class SvgParser {
  /// Parse an SVG string into colored vertex sources.
  static List<ColoredVertexSource> parseString(String svg, {bool flipY = false}) {
    final shapes = SvgParserNew.parse(svg);
    final result = <ColoredVertexSource>[];

    for (final shape in shapes) {
      if (shape.fill == null) continue;

      var paint = shape.fill!;

      if (flipY) {
         final vs = shape.path;
         final transformedVs = VertexStorage();
         for (int i = 0; i < vs.count; i++) {
            final v = vs[i];
            if (v.command.isVertex) {
               transformedVs.addVertex(v.x, -v.y, v.command);
            } else {
               transformedVs.addVertex(0, 0, v.command);
            }
         }
         
         // Flip gradient coordinates if needed
         if (paint is SvgPaintLinearGradient && paint.userSpaceOnUse) {
            Affine? newTransform;
            if (paint.gradientTransform != null) {
               final t = paint.gradientTransform!;
               newTransform = Affine(t.sx, -t.shy, -t.shx, t.sy, t.tx, -t.ty);
            }

            paint = SvgPaintLinearGradient(
               id: paint.id,
               x1: paint.x1, y1: -paint.y1,
               x2: paint.x2, y2: -paint.y2,
               stops: paint.stops,
               gradientTransform: newTransform,
               userSpaceOnUse: paint.userSpaceOnUse,
            );
         }
         
         result.add(ColoredVertexSource(transformedVs, paint));
      } else {
         result.add(ColoredVertexSource(shape.path, paint));
      }
    }
    return result;
  }
}
