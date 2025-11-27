import 'package:agg/src/shared/ref_param.dart';
import '../../typography/openfont/glyph.dart';
import 'ivertex_source.dart';
import 'path_commands.dart';
import 'vertex_data.dart';

/// Adapts a Typography Glyph to an AGG IVertexSource
class GlyphVertexSource implements IVertexSource {
  final Glyph _glyph;
  int _currentContour = 0;
  int _currentPoint = 0;
  int _startPointOfContour = 0;
  
  // State machine for processing points
  // 0: Start of contour (MoveTo)
  // 1: Processing points (LineTo / Curve3)
  // 2: End of contour (Close)
  int _state = 0;
  
  // For curve processing (Curve3 requires 2 calls)
  bool _processingCurve = false;
  double _nextCurveX = 0;
  double _nextCurveY = 0;

  GlyphVertexSource(this._glyph);

  @override
  void rewind([int pathId = 0]) {
    _currentContour = 0;
    _currentPoint = 0;
    _startPointOfContour = 0;
    _state = 0;
    _processingCurve = false;
  }

  @override
  FlagsAndCommand vertex(RefParam<double> x, RefParam<double> y) {
    if (_glyph.glyphPoints == null || _glyph.contourEndPoints == null) {
      return FlagsAndCommand.commandStop;
    }

    // Check if we finished all contours
    if (_currentContour >= _glyph.contourEndPoints!.length) {
      return FlagsAndCommand.commandStop;
    }

    final endPointOfContour = _glyph.contourEndPoints![_currentContour];
    final points = _glyph.glyphPoints!;

    // Handle second part of Curve3 (the end point)
    if (_processingCurve) {
      _processingCurve = false;
      x.value = _nextCurveX;
      y.value = _nextCurveY;
      return FlagsAndCommand.commandCurve3;
    }

    // State 0: Start of contour
    if (_state == 0) {
      var startP = points[_startPointOfContour];
      double startX = startP.x;
      double startY = startP.y;
      
      if (startP.onCurve) {
        // If start is OnCurve, move there and skip it in the loop
        _currentPoint = _startPointOfContour + 1;
      } else {
        // If start is OffCurve, calculate logical start point
        var endP = points[endPointOfContour];
        if (endP.onCurve) {
          startX = endP.x;
          startY = endP.y;
          // We start processing from the first point (which is OffCurve)
          _currentPoint = _startPointOfContour;
        } else {
          // Both start and end are OffCurve, start at midpoint
          startX = (startP.x + endP.x) / 2;
          startY = (startP.y + endP.y) / 2;
          _currentPoint = _startPointOfContour;
        }
      }
      
      x.value = startX;
      y.value = startY;
      _state = 1; // Move to processing state
      return FlagsAndCommand.commandMoveTo;
    }
    
    // State 1: Processing points
    if (_state == 1) {
      if (_currentPoint > endPointOfContour) {
        // Finished points, close polygon
        _state = 2;
        // We return ClosePoly now. Next call will handle state 2.
        return FlagsAndCommand.commandEndPoly | FlagsAndCommand.flagClose;
      }

      final p = points[_currentPoint];
      
      if (p.onCurve) {
        x.value = p.x;
        y.value = p.y;
        _currentPoint++;
        return FlagsAndCommand.commandLineTo;
      } else {
        // OffCurve - it's a control point
        // We need the next point to determine the end of the curve
        
        int nextIdx = _currentPoint + 1;
        if (nextIdx > endPointOfContour) {
          nextIdx = _startPointOfContour;
        }
        
        final nextP = points[nextIdx];
        
        double endX, endY;
        if (nextP.onCurve) {
          endX = nextP.x;
          endY = nextP.y;
          // Consume next point as it is the end of this curve
          if (nextIdx == _startPointOfContour) {
             // We wrapped around. The loop condition (_currentPoint > endPointOfContour) will handle termination
             // But we need to increment _currentPoint to eventually exit.
             _currentPoint++; 
          } else {
             // Normal case, consume next point
             _currentPoint += 2; // Consume current (control) and next (end)
          }
        } else {
          // Next is also OffCurve.
          // Implicit OnCurve at midpoint.
          endX = (p.x + nextP.x) / 2;
          endY = (p.y + nextP.y) / 2;
          // We only consume the current point (control).
          // The next point will be the control point for the NEXT segment.
          _currentPoint++;
        }
        
        // Emit control point
        x.value = p.x;
        y.value = p.y;
        
        // Store end point for next call
        _nextCurveX = endX;
        _nextCurveY = endY;
        _processingCurve = true;
        
        return FlagsAndCommand.commandCurve3;
      }
    }
    
    // State 2: End of contour
    if (_state == 2) {
      // Prepare for next contour
      _startPointOfContour = endPointOfContour + 1;
      _currentPoint = _startPointOfContour;
      _currentContour++;
      _state = 0;
      
      // Recursive call to start next contour?
      // No, just return what the next contour starts with.
      return vertex(x, y);
    }
    
    return FlagsAndCommand.commandStop;
  }

  @override
  Iterable<VertexData> vertices() sync* {
    var x = RefParam(0.0);
    var y = RefParam(0.0);
    rewind();
    while (true) {
      var cmd = vertex(x, y);
      if (cmd.isStop) break;
      yield VertexData(cmd, x.value, y.value);
    }
  }
  
  @override
  int getLongHashCode([int hash = 0xcbf29ce484222325]) {
    // Simple hash based on glyph index
    return hash ^ _glyph.glyphIndex;
  }
}
