//==================================================rasterizer_scanline_aa
// Polygon rasterizer that is used to render filled polygons with
// high-quality Anti-Aliasing. Internally, by default, the class uses
// integer coordinates in format 24.8, i.e. 24 bits for integer part
// and 8 bits for fractional - see poly_subpixel_shift. This class can be
// used in the following  way:
//
// 1. filling_rule(filling_rule_e ft) - optional.
//
// 2. gamma() - optional.
//
// 3. reset()
//
// 4. move_to(x, y) / line_to(x, y) - make the polygon. One can create
//    more than one contour, but each contour must consist of at least 3
//    vertices, i.e. move_to(x1, y1); line_to(x2, y2); line_to(x3, y3);
//    is the absolute minimum of vertices that define a triangle.
//    The algorithm does not check either the number of vertices nor
//    coincidence of their coordinates, but in the worst case it just
//    won't draw anything.
//    The order of the vertices (clockwise or counterclockwise)
//    is important when using the non-zero filling rule (fill_non_zero).
//    In this case the vertex order of all the contours must be the same
//    if you want your intersecting polygons to be without "holes".
//    You actually can use different vertices order. If the contours do not
//    intersect each other the order is not important anyway. If they do,
//    contours with the same vertex order will be rendered without "holes"
//    while the intersecting contours with different orders will have "holes".
//
// filling_rule() and gamma() can be called anytime before "sweeping".
//------------------------------------------------------------------------
import 'package:agg/src/agg/agg_gamma_functions.dart';
import 'package:agg/src/agg/interfaces/iscanline.dart';

abstract class IRasterizer {
  int min_x();

  int min_y();

  int max_x();

  int max_y();

  void gamma(IGammaFunction gamma_function);

  bool sweep_scanline(IScanlineCache sl);

  void reset();

  //void add_path(IVertexSource vs);

  bool rewind_scanlines();
}
