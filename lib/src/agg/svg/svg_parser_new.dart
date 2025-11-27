import 'package:agg/src/agg/svg/css/css_style_sheet.dart';
import 'package:xml/xml.dart';

import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';
import 'package:agg/src/agg/transform/affine.dart';
import 'package:agg/src/agg/svg/svg_shape.dart';
import 'package:agg/src/agg/svg/svg_paint.dart';
import 'package:agg/src/agg/svg/svg_path_parser.dart';
import 'package:agg/src/agg/svg/svg_transform_parser.dart';


class SvgParserNew {
  static List<SvgShape> parse(String svg) {
    final document = XmlDocument.parse(svg);
    final root = document.rootElement;
    final context = SvgContext();
    final shapes = <SvgShape>[];
    
    _parseElement(root, context, shapes);
    
    return shapes;
  }

  static void _parseElement(XmlElement element, SvgContext context, List<SvgShape> shapes) {
    if (element.name.local == 'defs') {
      _parseDefs(element, context);
      return;
    }
    
    if (element.name.local == 'style') {
       context.styleSheet.parse(element.innerText);
       return;
    }
    
    if (element.name.local == 'linearGradient' || element.name.local == 'radialGradient') {
       final id = element.getAttribute('id');
       if (id != null) {
         context.defs[id] = element;
       }
       return;
    }

    context.push(element);

    switch (element.name.local) {
      case 'g':
      case 'svg':
      case 'a':
        for (final child in element.childElements) {
          _parseElement(child, context, shapes);
        }
        break;
      case 'path':
        _parsePath(element, context, shapes);
        break;
      case 'rect':
        _parseRect(element, context, shapes);
        break;
      case 'circle':
        _parseCircle(element, context, shapes);
        break;
      case 'ellipse':
        _parseEllipse(element, context, shapes);
        break;
      case 'line':
        _parseLine(element, context, shapes);
        break;
      case 'polyline':
      case 'polygon':
        _parsePoly(element, context, shapes);
        break;
      case 'use':
        _parseUse(element, context, shapes);
        break;
    }

    context.pop();
  }

  static void _parseDefs(XmlElement element, SvgContext context) {
    for (final child in element.childElements) {
      final id = child.getAttribute('id');
      if (id != null) {
        context.defs[id] = child;
      }
    }
  }

  static void _parseUse(XmlElement element, SvgContext context, List<SvgShape> shapes) {
    final href = element.getAttribute('href') ?? element.getAttribute('xlink:href');
    if (href == null || !href.startsWith('#')) return;
    final id = href.substring(1);
    final target = context.defs[id];
    if (target != null) {
      final x = double.tryParse(element.getAttribute('x') ?? '0') ?? 0;
      final y = double.tryParse(element.getAttribute('y') ?? '0') ?? 0;
      
      if (x != 0 || y != 0) {
         context.currentTransform.premultiply(Affine.translation(x, y));
      }
      
      _parseElement(target, context, shapes);
    }
  }

  static void _parsePath(XmlElement element, SvgContext context, List<SvgShape> shapes) {
    final d = element.getAttribute('d');
    if (d != null) {
      final vs = SvgPathParser.parse(d);
      _addShape(vs, context, shapes);
    }
  }

  static void _parseRect(XmlElement element, SvgContext context, List<SvgShape> shapes) {
    final x = double.tryParse(element.getAttribute('x') ?? '0') ?? 0;
    final y = double.tryParse(element.getAttribute('y') ?? '0') ?? 0;
    final w = double.tryParse(element.getAttribute('width') ?? '0') ?? 0;
    final h = double.tryParse(element.getAttribute('height') ?? '0') ?? 0;
    final rx = double.tryParse(element.getAttribute('rx') ?? '0') ?? 0;
    final ry = double.tryParse(element.getAttribute('ry') ?? '0') ?? 0;

    final vs = VertexStorage();
    if (rx > 0 || ry > 0) {
      vs.moveTo(x, y);
      vs.lineTo(x + w, y);
      vs.lineTo(x + w, y + h);
      vs.lineTo(x, y + h);
      vs.closePath();
    } else {
      vs.moveTo(x, y);
      vs.lineTo(x + w, y);
      vs.lineTo(x + w, y + h);
      vs.lineTo(x, y + h);
      vs.closePath();
    }
    _addShape(vs, context, shapes);
  }

  static void _parseCircle(XmlElement element, SvgContext context, List<SvgShape> shapes) {
    final cx = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
    final cy = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
    final r = double.tryParse(element.getAttribute('r') ?? '0') ?? 0;
    _parseEllipseHelper(cx, cy, r, r, context, shapes);
  }

  static void _parseEllipse(XmlElement element, SvgContext context, List<SvgShape> shapes) {
    final cx = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
    final cy = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
    final rx = double.tryParse(element.getAttribute('rx') ?? '0') ?? 0;
    final ry = double.tryParse(element.getAttribute('ry') ?? '0') ?? 0;
    _parseEllipseHelper(cx, cy, rx, ry, context, shapes);
  }

  static void _parseEllipseHelper(double cx, double cy, double rx, double ry, SvgContext context, List<SvgShape> shapes) {
    final vs = VertexStorage();
    final k = 0.5522847498;
    vs.moveTo(cx + rx, cy);
    vs.curve4(cx + rx, cy + k * ry, cx + k * rx, cy + ry, cx, cy + ry);
    vs.curve4(cx - k * rx, cy + ry, cx - rx, cy + k * ry, cx - rx, cy);
    vs.curve4(cx - rx, cy - k * ry, cx - k * rx, cy - ry, cx, cy - ry);
    vs.curve4(cx + k * rx, cy - ry, cx + rx, cy - k * ry, cx + rx, cy);
    vs.closePath();
    _addShape(vs, context, shapes);
  }

  static void _parseLine(XmlElement element, SvgContext context, List<SvgShape> shapes) {
    final x1 = double.tryParse(element.getAttribute('x1') ?? '0') ?? 0;
    final y1 = double.tryParse(element.getAttribute('y1') ?? '0') ?? 0;
    final x2 = double.tryParse(element.getAttribute('x2') ?? '0') ?? 0;
    final y2 = double.tryParse(element.getAttribute('y2') ?? '0') ?? 0;
    final vs = VertexStorage();
    vs.moveTo(x1, y1);
    vs.lineTo(x2, y2);
    _addShape(vs, context, shapes);
  }

  static void _parsePoly(XmlElement element, SvgContext context, List<SvgShape> shapes) {
    final points = element.getAttribute('points');
    if (points != null) {
      final vs = VertexStorage();
      final nums = _parseNumbers(points);
      if (nums.length >= 2) {
        vs.moveTo(nums[0], nums[1]);
        for (int i = 2; i < nums.length; i += 2) {
          vs.lineTo(nums[i], nums[i + 1]);
        }
        if (element.name.local == 'polygon') {
          vs.closePath();
        }
      }
      _addShape(vs, context, shapes);
    }
  }

  static void _addShape(VertexStorage vs, SvgContext context, List<SvgShape> shapes) {
    final t = context.currentTransform;
    final transformedVs = VertexStorage();
    for (int i = 0; i < vs.count; i++) {
       final v = vs[i];
       final cmd = v.command;
       final x = v.x;
       final y = v.y;
       if (cmd.isVertex) {
          final pt = t.transformPoint(x, y);
          transformedVs.addVertex(pt.x, pt.y, cmd);
       } else {
          transformedVs.addVertex(0, 0, cmd);
       }
    }
    
    SvgPaint? fill = context.current.fill;
    if (fill is SvgPaintLinearGradient) {
       double x1 = fill.x1;
       double y1 = fill.y1;
       double x2 = fill.x2;
       double y2 = fill.y2;
       
       if (!fill.userSpaceOnUse) {
          // objectBoundingBox
          final bbox = _calculateBoundingBox(vs);
          final w = bbox.maxX - bbox.minX;
          final h = bbox.maxY - bbox.minY;
          
          x1 = bbox.minX + x1 * w;
          y1 = bbox.minY + y1 * h;
          x2 = bbox.minX + x2 * w;
          y2 = bbox.minY + y2 * h;
       }
       
       // Apply gradientTransform if present
       if (fill.gradientTransform != null) {
          final pt1 = fill.gradientTransform!.transformPoint(x1, y1);
          final pt2 = fill.gradientTransform!.transformPoint(x2, y2);
          x1 = pt1.x; y1 = pt1.y;
          x2 = pt2.x; y2 = pt2.y;
       }
       
       // Apply current transform
       final pt1 = t.transformPoint(x1, y1);
       final pt2 = t.transformPoint(x2, y2);
       
       fill = SvgPaintLinearGradient(
          id: fill.id,
          x1: pt1.x, y1: pt1.y,
          x2: pt2.x, y2: pt2.y,
          stops: fill.stops,
          userSpaceOnUse: true, // Now it is in screen space
          gradientTransform: null, // Already applied
       );
    }

    shapes.add(SvgShape(
      transformedVs,
      fill: fill,
      stroke: context.current.stroke,
      strokeWidth: context.current.strokeWidth,
      opacity: context.current.opacity,
      fillOpacity: context.current.fillOpacity,
      strokeOpacity: context.current.strokeOpacity,
      strokeLineCap: context.current.strokeLineCap,
      strokeLineJoin: context.current.strokeLineJoin,
      strokeMiterLimit: context.current.strokeMiterLimit,
    ));
  }

  static ({double minX, double minY, double maxX, double maxY}) _calculateBoundingBox(VertexStorage vs) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    for (int i = 0; i < vs.count; i++) {
      final v = vs[i];
      if (v.command.isVertex) {
        if (v.x < minX) minX = v.x;
        if (v.y < minY) minY = v.y;
        if (v.x > maxX) maxX = v.x;
        if (v.y > maxY) maxY = v.y;
      }
    }
    
    if (minX == double.infinity) {
      return (minX: 0.0, minY: 0.0, maxX: 0.0, maxY: 0.0);
    }
    return (minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }

  static List<double> _parseNumbers(String s) {
    final List<double> nums = [];
    final re = RegExp(r'[+-]?(\d*\.\d+|\d+)([eE][+-]?\d+)?');
    for (final match in re.allMatches(s)) {
      nums.add(double.parse(match.group(0)!));
    }
    return nums;
  }
}

class SvgContext {
  final List<SvgState> _stack = [SvgState()];
  final Map<String, XmlElement> defs = {};
  final CssStyleSheet styleSheet = CssStyleSheet();

  SvgState get current => _stack.last;
  Affine get currentTransform => current.transform;

  void push(XmlElement element) {
    final newState = current.clone();
    
    final transform = element.getAttribute('transform');
    if (transform != null) {
      newState.transform.premultiply(SvgTransformParser.parse(transform));
    }
    
    // 1. Presentation attributes
    for (final attr in element.attributes) {
      if (_isStyleAttribute(attr.name.local)) {
         _applyStyle(attr.name.local, attr.value, newState, this);
      }
    }
    
    // 2. CSS
    final id = element.getAttribute('id');
    final className = element.getAttribute('class');
    final tagName = element.name.local;
    final cssStyles = styleSheet.getStyle(tagName, id, className);
    for (final entry in cssStyles.entries) {
       _applyStyle(entry.key, entry.value, newState, this);
    }
    
    // 3. Inline style
    final style = element.getAttribute('style');
    if (style != null) {
      _parseStyleString(style, newState, this);
    }
    
    _stack.add(newState);
  }
  
  bool _isStyleAttribute(String name) {
     const styles = {
        'fill', 'stroke', 'stroke-width', 'opacity', 'fill-opacity', 'stroke-opacity',
        'stroke-linecap', 'stroke-linejoin', 'stroke-miterlimit', 'display'
     };
     return styles.contains(name);
  }

  void pop() {
    _stack.removeLast();
  }
  
  void _parseStyleString(String style, SvgState state, SvgContext context) {
    final parts = style.split(';');
    for (final part in parts) {
      final kv = part.split(':');
      if (kv.length == 2) {
        final key = kv[0].trim();
        final value = kv[1].trim();
        _applyStyle(key, value, state, context);
      }
    }
  }
  
  void _applyStyle(String key, String value, SvgState state, SvgContext context) {
    switch (key) {
      case 'fill':
        state.fill = _parsePaint(value, context);
        break;
      case 'stroke':
        state.stroke = _parsePaint(value, context);
        break;
      case 'stroke-width':
        state.strokeWidth = double.tryParse(value.replaceAll('px', '')) ?? 1.0;
        break;
      case 'opacity':
        state.opacity = double.tryParse(value) ?? 1.0;
        break;
      case 'fill-opacity':
        state.fillOpacity = double.tryParse(value) ?? 1.0;
        break;
      case 'stroke-opacity':
        state.strokeOpacity = double.tryParse(value) ?? 1.0;
        break;
      case 'stroke-linecap':
        if (value == 'round') state.strokeLineCap = StrokeLineCap.round;
        else if (value == 'square') state.strokeLineCap = StrokeLineCap.square;
        else state.strokeLineCap = StrokeLineCap.butt;
        break;
      case 'stroke-linejoin':
        if (value == 'round') state.strokeLineJoin = StrokeLineJoin.round;
        else if (value == 'bevel') state.strokeLineJoin = StrokeLineJoin.bevel;
        else state.strokeLineJoin = StrokeLineJoin.miter;
        break;
      case 'stroke-miterlimit':
        state.strokeMiterLimit = double.tryParse(value) ?? 4.0;
        break;
      case 'display':
        if (value == 'none') {
           state.fill = null;
           state.stroke = null;
        }
        break;
    }
  }
  
  SvgPaint? _parsePaint(String value, SvgContext context) {
    if (value == 'none') return null;
    if (value.startsWith('url(#')) {
      final id = value.substring(5, value.length - 1);
      final def = context.defs[id];
      if (def != null) {
        if (def.name.local == 'linearGradient') {
           return _parseLinearGradient(def, context);
        }
      }
      return null;
    }
    final color = _parseColor(value);
    if (color != null) return SvgPaintSolid(color);
    return null;
  }
  
  SvgPaintLinearGradient _parseLinearGradient(XmlElement element, SvgContext context) {
     final x1 = _parseLength(element.getAttribute('x1') ?? '0%');
     final y1 = _parseLength(element.getAttribute('y1') ?? '0%');
     final x2 = _parseLength(element.getAttribute('x2') ?? '100%');
     final y2 = _parseLength(element.getAttribute('y2') ?? '0%');
     
     final stops = <GradientStop>[];
     for (final child in element.childElements) {
       if (child.name.local == 'stop') {
         final offset = _parseLength(child.getAttribute('offset') ?? '0');
         
         String? colorStr = child.getAttribute('stop-color');
         String? style = child.getAttribute('style');
         if (style != null) {
            final parts = style.split(';');
            for (final part in parts) {
               final kv = part.split(':');
               if (kv.length == 2 && kv[0].trim() == 'stop-color') {
                  colorStr = kv[1].trim();
               }
            }
         }
         
         if (colorStr != null) {
           final color = _parseColor(colorStr) ?? Color.black;
           stops.add(GradientStop(offset, color));
         }
       }
     }
     
     return SvgPaintLinearGradient(
       id: element.getAttribute('id') ?? '',
       x1: x1, y1: y1, x2: x2, y2: y2,
       stops: stops,
       userSpaceOnUse: element.getAttribute('gradientUnits') == 'userSpaceOnUse',
       gradientTransform: SvgTransformParser.parse(element.getAttribute('gradientTransform')),
     );
  }

  double _parseLength(String value) {
    if (value.endsWith('%')) {
      return double.parse(value.substring(0, value.length - 1)) / 100.0;
    }
    return double.tryParse(value) ?? 0.0;
  }

  Color? _parseColor(String value) {
    if (value.startsWith('#')) {
      var hex = value.substring(1);
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join('');
      }
      if (hex.length == 6) {
        final r = int.parse(hex.substring(0, 2), radix: 16);
        final g = int.parse(hex.substring(2, 4), radix: 16);
        final b = int.parse(hex.substring(4, 6), radix: 16);
        return Color(r, g, b, 255);
      }
    }
    switch (value.toLowerCase()) {
      case 'black': return Color.black;
      case 'white': return Color.white;
      case 'red': return Color(255, 0, 0, 255);
      case 'green': return Color(0, 255, 0, 255);
      case 'blue': return Color(0, 0, 255, 255);
      case 'yellow': return Color(255, 255, 0, 255);
      case 'cyan': return Color(0, 255, 255, 255);
      case 'magenta': return Color(255, 0, 255, 255);
      case 'gray': return Color(128, 128, 128, 255);
      case 'grey': return Color(128, 128, 128, 255);
    }
    return null;
  }
}

class SvgState {
  Affine transform = Affine.identity();
  SvgPaint? fill = SvgPaintSolid(Color.black);
  SvgPaint? stroke;
  double strokeWidth = 1.0;
  
  double opacity = 1.0;
  double fillOpacity = 1.0;
  double strokeOpacity = 1.0;
  StrokeLineCap strokeLineCap = StrokeLineCap.butt;
  StrokeLineJoin strokeLineJoin = StrokeLineJoin.miter;
  double strokeMiterLimit = 4.0;
  
  SvgState clone() {
    return SvgState()
      ..transform = transform.clone()
      ..fill = fill
      ..stroke = stroke
      ..strokeWidth = strokeWidth
      ..opacity = opacity
      ..fillOpacity = fillOpacity
      ..strokeOpacity = strokeOpacity
      ..strokeLineCap = strokeLineCap
      ..strokeLineJoin = strokeLineJoin
      ..strokeMiterLimit = strokeMiterLimit;
  }
}
