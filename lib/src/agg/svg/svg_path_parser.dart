import 'package:agg/src/agg/vertex_source/vertex_storage.dart';

class SvgPathParser {
  static VertexStorage parse(String d) {
    final vs = VertexStorage();
    int i = 0;
    double cx = 0, cy = 0;
    double sx = 0, sy = 0;
    double lastCx = 0, lastCy = 0;

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
          vs.moveTo(cx, cy);
          sx = cx;
          sy = cy;
          lastCx = cx;
          lastCy = cy;

          while (true) {
            int nextI = _skipWhitespace(d, i);
            if (nextI >= d.length || _isCommandLetter(d[nextI])) break;
            final pt = _readPoint(d, nextI);
            i = pt.nextIndex;
            cx = ch == 'm' ? cx + pt.x : pt.x;
            cy = ch == 'm' ? cy + pt.y : pt.y;
            vs.lineTo(cx, cy);
            lastCx = cx;
            lastCy = cy;
          }
          break;
        case 'L':
        case 'l':
          while (true) {
            int nextI = _skipWhitespace(d, i);
            if (nextI >= d.length || _isCommandLetter(d[nextI])) break;
            final pt = _readPoint(d, nextI);
            i = pt.nextIndex;
            cx = ch == 'l' ? cx + pt.x : pt.x;
            cy = ch == 'l' ? cy + pt.y : pt.y;
            vs.lineTo(cx, cy);
            lastCx = cx;
            lastCy = cy;
          }
          break;
        case 'H':
        case 'h':
          while (true) {
            int nextI = _skipWhitespace(d, i);
            if (nextI >= d.length || _isCommandLetter(d[nextI])) break;
            final val = _readNumber(d, nextI);
            i = val.nextIndex;
            cx = ch == 'h' ? cx + val.value : val.value;
            vs.lineTo(cx, cy);
            lastCx = cx;
            lastCy = cy;
          }
          break;
        case 'V':
        case 'v':
          while (true) {
            int nextI = _skipWhitespace(d, i);
            if (nextI >= d.length || _isCommandLetter(d[nextI])) break;
            final val = _readNumber(d, nextI);
            i = val.nextIndex;
            cy = ch == 'v' ? cy + val.value : val.value;
            vs.lineTo(cx, cy);
            lastCx = cx;
            lastCy = cy;
          }
          break;
        case 'C':
        case 'c':
          while (true) {
            int nextI = _skipWhitespace(d, i);
            if (nextI >= d.length || _isCommandLetter(d[nextI])) break;
            final p1 = _readPoint(d, nextI);
            final p2 = _readPoint(d, p1.nextIndex);
            final p3 = _readPoint(d, p2.nextIndex);
            i = p3.nextIndex;

            final c1x = ch == 'c' ? cx + p1.x : p1.x;
            final c1y = ch == 'c' ? cy + p1.y : p1.y;
            final c2x = ch == 'c' ? cx + p2.x : p2.x;
            final c2y = ch == 'c' ? cy + p2.y : p2.y;
            final ex = ch == 'c' ? cx + p3.x : p3.x;
            final ey = ch == 'c' ? cy + p3.y : p3.y;

            vs.curve4(c1x, c1y, c2x, c2y, ex, ey);
            cx = ex;
            cy = ey;
            lastCx = c2x;
            lastCy = c2y;
          }
          break;
        case 'S':
        case 's':
          while (true) {
            int nextI = _skipWhitespace(d, i);
            if (nextI >= d.length || _isCommandLetter(d[nextI])) break;
            final p2 = _readPoint(d, nextI);
            final p3 = _readPoint(d, p2.nextIndex);
            i = p3.nextIndex;

            double c1x = 2 * cx - lastCx;
            double c1y = 2 * cy - lastCy;

            final c2x = ch == 's' ? cx + p2.x : p2.x;
            final c2y = ch == 's' ? cy + p2.y : p2.y;
            final ex = ch == 's' ? cx + p3.x : p3.x;
            final ey = ch == 's' ? cy + p3.y : p3.y;

            vs.curve4(c1x, c1y, c2x, c2y, ex, ey);
            cx = ex;
            cy = ey;
            lastCx = c2x;
            lastCy = c2y;
          }
          break;
        case 'Q':
        case 'q':
          while (true) {
            int nextI = _skipWhitespace(d, i);
            if (nextI >= d.length || _isCommandLetter(d[nextI])) break;
            final cp = _readPoint(d, nextI);
            final ep = _readPoint(d, cp.nextIndex);
            i = ep.nextIndex;

            final cpx = ch == 'q' ? cx + cp.x : cp.x;
            final cpy = ch == 'q' ? cy + cp.y : cp.y;
            final ex = ch == 'q' ? cx + ep.x : ep.x;
            final ey = ch == 'q' ? cy + ep.y : ep.y;

            vs.curve3(cpx, cpy, ex, ey);
            cx = ex;
            cy = ey;
            lastCx = cpx;
            lastCy = cpy;
          }
          break;
        case 'T':
        case 't':
          while (true) {
            int nextI = _skipWhitespace(d, i);
            if (nextI >= d.length || _isCommandLetter(d[nextI])) break;
            final ep = _readPoint(d, nextI);
            i = ep.nextIndex;

            double cpx = 2 * cx - lastCx;
            double cpy = 2 * cy - lastCy;

            final ex = ch == 't' ? cx + ep.x : ep.x;
            final ey = ch == 't' ? cy + ep.y : ep.y;

            vs.curve3(cpx, cpy, ex, ey);
            cx = ex;
            cy = ey;
            lastCx = cpx;
            lastCy = cpy;
          }
          break;
        case 'Z':
        case 'z':
          vs.closePath();
          cx = sx;
          cy = sy;
          lastCx = cx;
          lastCy = cy;
          break;
        default:
          break;
      }
    }
    return vs;
  }

  static bool _isSkip(String ch) => ch == ' ' || ch == '\n' || ch == '\t' || ch == ',';

  static int _skipWhitespace(String s, int index) {
    while (index < s.length && _isSkip(s[index])) index++;
    return index;
  }

  static _PointRead _readPoint(String s, int index) {
    final x = _readNumber(s, index);
    final y = _readNumber(s, x.nextIndex);
    return _PointRead(x.value, y.value, y.nextIndex);
  }

  static _NumberRead _readNumber(String s, int index) {
    while (index < s.length && _isSkip(s[index])) index++;
    final start = index;
    if (index < s.length && (s[index] == '+' || s[index] == '-')) index++;
    while (index < s.length &&
        (_isDigit(s[index]) || s[index] == '.' || s[index] == 'e' || s[index] == 'E')) {
      if (s[index] == 'e' || s[index] == 'E') {
        index++;
        if (index < s.length && (s[index] == '+' || s[index] == '-')) index++;
      } else {
        index++;
      }
    }
    final str = s.substring(start, index);
    try {
      return _NumberRead(double.parse(str), index);
    } catch (e) {
      return _NumberRead(0.0, index);
    }
  }

  static bool _isDigit(String ch) {
    if (ch.isEmpty) return false;
    final code = ch.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  static bool _isCommandLetter(String ch) {
    if (ch.length != 1) return false;
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
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