import 'dart:math' as math;

import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/svg/colored_vertex_source.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';

/// TODO Lightweight SVG parser for paths and polygons.
///
/// This is intentionally minimal: it understands `<path d="...">` and
/// `<polygon points="...">` with solid fills (#RRGGBB or in style).
class SvgParser {
  static final RegExp _pathRe = RegExp(r'<path[^>]*d="([^"]+)"[^>]*>', caseSensitive: false);
  static final RegExp _polygonRe = RegExp(r'<polygon[^>]*points="([^"]+)"[^>]*>', caseSensitive: false);
  static final RegExp _fillRe = RegExp(r'fill:\s*#([0-9a-fA-F]{6})');
  static final RegExp _fillAttrRe = RegExp(r'fill="(#?[0-9a-fA-F]{6})"');

  /// Parse an SVG string into colored vertex sources.
  static List<ColoredVertexSource> parseString(String svg, {bool flipY = false}) {
    final List<ColoredVertexSource> result = [];
    for (final match in _pathRe.allMatches(svg)) {
      final d = match.group(1)!;
      final color = _extractFill(svg, match.start) ?? Color.black;
      final vs = _buildPath(d, flipY: flipY);
      result.add(ColoredVertexSource(vs, color));
    }
    for (final match in _polygonRe.allMatches(svg)) {
      final pts = match.group(1)!;
      final color = _extractFill(svg, match.start) ?? Color.black;
      final vs = _buildPolygon(pts, flipY: flipY);
      result.add(ColoredVertexSource(vs, color));
    }
    return result;
  }

  static Color? _extractFill(String svg, int startIndex) {
    // Look ahead a small window for fill info.
    final window = svg.substring(startIndex, math.min(svg.length, startIndex + 200));
    final attr = _fillAttrRe.firstMatch(window);
    if (attr != null) return _colorFromString(attr.group(1)!);
    final style = _fillRe.firstMatch(window);
    if (style != null) return _colorFromString(style.group(1)!);
    return null;
  }

  static Color _colorFromString(String s) {
    var hex = s;
    if (hex.startsWith('#')) hex = hex.substring(1);
    final r = int.parse(hex.substring(0, 2), radix: 16);
    final g = int.parse(hex.substring(2, 4), radix: 16);
    final b = int.parse(hex.substring(4, 6), radix: 16);
    return Color(r, g, b, 255);
  }

  static VertexStorage _buildPolygon(String points, {bool flipY = false}) {
    final vs = VertexStorage();
    final nums = _parseNumbers(points);
    if (nums.length < 2) return vs;
    for (int i = 0; i < nums.length; i += 2) {
      final x = nums[i];
      final y = flipY ? -nums[i + 1] : nums[i + 1];
      if (i == 0) {
        vs.moveTo(x, y);
      } else {
        vs.lineTo(x, y);
      }
    }
    vs.closePath();
    return vs;
  }

  static VertexStorage _buildPath(String d, {bool flipY = false}) {
    final vs = VertexStorage();
    int i = 0;
    double cx = 0, cy = 0;
    double sx = 0, sy = 0;
    while (i < d.length) {
      final ch = d[i];
      if (_isSkip(ch)) {
        i++;
        continue;
      }
      i++;
      switch (ch) {
        case 'M':
        case 'm':
          final nums = _readPoint(d, i);
          i = nums.nextIndex;
          cx = ch == 'm' ? cx + nums.x : nums.x;
          cy = ch == 'm' ? cy + nums.y : nums.y;
          final py = flipY ? -cy : cy;
          vs.moveTo(cx, py);
          sx = cx;
          sy = cy;
          break;
        case 'L':
        case 'l':
          final nums2 = _readPoint(d, i);
          i = nums2.nextIndex;
          cx = ch == 'l' ? cx + nums2.x : nums2.x;
          cy = ch == 'l' ? cy + nums2.y : nums2.y;
          vs.lineTo(cx, flipY ? -cy : cy);
          break;
        case 'H':
        case 'h':
          final val = _readNumber(d, i);
          i = val.nextIndex;
          cx = ch == 'h' ? cx + val.value : val.value;
          vs.lineTo(cx, flipY ? -cy : cy);
          break;
        case 'V':
        case 'v':
          final valy = _readNumber(d, i);
          i = valy.nextIndex;
          cy = ch == 'v' ? cy + valy.value : valy.value;
          vs.lineTo(cx, flipY ? -cy : cy);
          break;
        case 'C':
        case 'c':
          final p1 = _readPoint(d, i);
          final p2 = _readPoint(d, p1.nextIndex);
          final p3 = _readPoint(d, p2.nextIndex);
          i = p3.nextIndex;
          final c1x = ch == 'c' ? cx + p1.x : p1.x;
          final c1y = ch == 'c' ? cy + p1.y : p1.y;
          final c2x = ch == 'c' ? cx + p2.x : p2.x;
          final c2y = ch == 'c' ? cy + p2.y : p2.y;
          cx = ch == 'c' ? cx + p3.x : p3.x;
          cy = ch == 'c' ? cy + p3.y : p3.y;
          vs.curve4(
            c1x,
            flipY ? -c1y : c1y,
            c2x,
            flipY ? -c2y : c2y,
            cx,
            flipY ? -cy : cy,
          );
          break;
        case 'Q':
        case 'q':
          final cp = _readPoint(d, i);
          final ep = _readPoint(d, cp.nextIndex);
          i = ep.nextIndex;
          final qx = ch == 'q' ? cx + ep.x : ep.x;
          final qy = ch == 'q' ? cy + ep.y : ep.y;
          final cpx = ch == 'q' ? cx + cp.x : cp.x;
          final cpy = ch == 'q' ? cy + cp.y : cp.y;
          cx = qx;
          cy = qy;
          vs.curve3(cpx, flipY ? -cpy : cpy, cx, flipY ? -cy : cy);
          break;
        case 'Z':
        case 'z':
          vs.closePath();
          cx = sx;
          cy = sy;
          break;
        default:
          // Unsupported command, skip one character.
          break;
      }
    }
    return vs;
  }

  static bool _isSkip(String ch) => ch == ' ' || ch == '\n' || ch == '\t' || ch == ',';

  static _PointRead _readPoint(String s, int index) {
    final x = _readNumber(s, index);
    final y = _readNumber(s, x.nextIndex);
    return _PointRead(x.value, y.value, y.nextIndex);
  }

  static _NumberRead _readNumber(String s, int index) {
    while (index < s.length && _isSkip(s[index])) index++;
    final start = index;
    while (index < s.length && !_isSkip(s[index]) && !_isCommandLetter(s[index])) {
      index++;
    }
    final str = s.substring(start, index);
    return _NumberRead(double.parse(str), index);
  }

  static bool _isCommandLetter(String ch) {
    if (ch.length != 1) return false;
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  static List<double> _parseNumbers(String s) {
    final List<double> nums = [];
    int i = 0;
    while (i < s.length) {
      while (i < s.length && _isSkip(s[i])) i++;
      final start = i;
      while (i < s.length && !_isSkip(s[i])) i++;
      if (start == i) break;
      nums.add(double.parse(s.substring(start, i)));
    }
    return nums;
  }
}

class _NumberRead {
  final double value;
  final int nextIndex;
  _NumberRead(this.value, this.nextIndex);
}

class _PointRead {
  final double x;
  final double y;
  final int nextIndex;
  _PointRead(this.x, this.y, this.nextIndex);
}
