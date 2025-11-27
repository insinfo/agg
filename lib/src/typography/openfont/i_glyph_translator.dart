/// Interface for translating glyph outlines
abstract class IGlyphTranslator {
  /// Begin read a glyph
  void beginRead(int contourCount);

  /// End read a glyph
  void endRead();

  /// Set CURRENT pen position to (x0,y0) And set the position as latest MOVETO position
  void moveTo(double x0, double y0);

  /// Add line, begin from CURRENT pen position to (x1,y1) then set (x1,y1) as CURRENT pen position
  void lineTo(double x1, double y1);

  /// Add Quadratic Bézier curve, begin from CURRENT pen pos, to (x2,y2), then set (x2,y2) as CURRENT pen pos
  /// (x1,y1) is the control point
  void curve3(double x1, double y1, double x2, double y2);

  /// Add Cubic Bézier curve, begin from CURRENT pen pos, to (x3,y3), then set (x3,y3) as CURRENT pen pos
  /// (x1,y1) is the 1st control point
  /// (x2,y2) is the 2nd control point
  void curve4(double x1, double y1, double x2, double y2, double x3, double y3);

  /// Close current contour, create line from CURRENT pen position to latest MOVETO position
  void closeContour();
}
