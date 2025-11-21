import 'package:agg/src/agg/agg_basics.dart';

class PixelCellAa {
  int x;
  int y;
  int cover;
  int area;
  int left;
  int right;

  PixelCellAa({
    this.x = 0x7FFFFFFF,
    this.y = 0x7FFFFFFF,
    this.cover = 0,
    this.area = 0,
    this.left = -1,
    this.right = -1,
  });

  void initial() {
    x = 0x7FFFFFFF;
    y = 0x7FFFFFFF;
    cover = 0;
    area = 0;
    left = -1;
    right = -1;
  }

  void setFrom(PixelCellAa other) {
    x = other.x;
    y = other.y;
    cover = other.cover;
    area = other.area;
    left = other.left;
    right = other.right;
  }

  void styleFrom(PixelCellAa other) {
    left = other.left;
    right = other.right;
  }

  bool notEqual(int ex, int ey, PixelCellAa cell) {
    return ((ex - x) | (ey - y) | (left - cell.left) | (right - cell.right)) !=
        0;
  }
}

class _SortedY {
  int start;
  int num;
  _SortedY({required this.start, required this.num});
}

class _ScanlineCells {
  final List<PixelCellAa> cells;
  final int offset;
  final int length;
  _ScanlineCells(this.cells, this.offset, this.length);
}

/// Core AA cell accumulator. Sorts cells by y/x for scanline use.
class RasterizerCellsAa {
  static const int _dxLimit =
      16384 << poly_subpixel_scale_e.poly_subpixel_shift;

  final List<PixelCellAa> _cells = <PixelCellAa>[];
  final List<PixelCellAa> _sortedCells = <PixelCellAa>[];
  final List<_SortedY> _sortedY = <_SortedY>[];

  PixelCellAa _currCell = PixelCellAa();
  PixelCellAa _styleCell = PixelCellAa();
  bool _sorted = false;

  int _minX = 0x7FFFFFFF;
  int _minY = 0x7FFFFFFF;
  int _maxX = -0x7FFFFFFF;
  int _maxY = -0x7FFFFFFF;

  void reset() {
    _cells.clear();
    _sortedCells.clear();
    _sortedY.clear();
    _currCell.initial();
    _styleCell.initial();
    _sorted = false;
    _minX = 0x7FFFFFFF;
    _minY = 0x7FFFFFFF;
    _maxX = -0x7FFFFFFF;
    _maxY = -0x7FFFFFFF;
  }

  void style(PixelCellAa styleCell) {
    _styleCell.styleFrom(styleCell);
  }

  void line(int x1, int y1, int x2, int y2) {
    final int polyShift = poly_subpixel_scale_e.poly_subpixel_shift;
    final int polyMask = poly_subpixel_scale_e.poly_subpixel_mask;
    final int polyScale = poly_subpixel_scale_e.poly_subpixel_scale;
    int dx = x2 - x1;

    if (dx >= _dxLimit || dx <= -_dxLimit) {
      final int cx = (x1 + x2) >> 1;
      final int cy = (y1 + y2) >> 1;
      line(x1, y1, cx, cy);
      line(cx, cy, x2, y2);
      return;
    }

    int dy = y2 - y1;
    int ex1 = x1 >> polyShift;
    int ex2 = x2 >> polyShift;
    int ey1 = y1 >> polyShift;
    int ey2 = y2 >> polyShift;
    int fy1 = y1 & polyMask;
    int fy2 = y2 & polyMask;

    if (ex1 < _minX) _minX = ex1;
    if (ex1 > _maxX) _maxX = ex1;
    if (ey1 < _minY) _minY = ey1;
    if (ey1 > _maxY) _maxY = ey1;
    if (ex2 < _minX) _minX = ex2;
    if (ex2 > _maxX) _maxX = ex2;
    if (ey2 < _minY) _minY = ey2;
    if (ey2 > _maxY) _maxY = ey2;

    _setCurrCell(ex1, ey1);

    // Single horizontal line
    if (ey1 == ey2) {
      _renderHLine(ey1, x1, fy1, x2, fy2);
      return;
    }

    // Vertical line
    int incr = 1;
    if (dx == 0) {
      final int ex = x1 >> polyShift;
      final int twoFx = (x1 - (ex << polyShift)) << 1;
      int area;

      int first = polyScale;
      if (dy < 0) {
        first = 0;
        incr = -1;
      }

      int delta = first - fy1;
      _currCell.cover += delta;
      _currCell.area += twoFx * delta;

      ey1 += incr;
      _setCurrCell(ex, ey1);

      delta = first + first - polyScale;
      area = twoFx * delta;
      while (ey1 != ey2) {
        _currCell.cover = delta;
        _currCell.area = area;
        ey1 += incr;
        _setCurrCell(ex, ey1);
      }
      delta = fy2 - polyScale + first;
      _currCell.cover += delta;
      _currCell.area += twoFx * delta;
      return;
    }

    // Render multiple horizontal segments
    int p = (polyScale - fy1) * dx;
    int first = polyScale;
    if (dy < 0) {
      p = fy1 * dx;
      first = 0;
      incr = -1;
      dy = -dy;
    }

    int delta = p ~/ dy;
    int mod = p % dy;

    if (mod < 0) {
      delta--;
      mod += dy;
    }

    int xFrom = x1 + delta;
    _renderHLine(ey1, x1, fy1, xFrom, first);

    ey1 += incr;
    _setCurrCell(xFrom >> polyShift, ey1);

    if (ey1 != ey2) {
      p = polyScale * dx;
      int lift = p ~/ dy;
      int rem = p % dy;

      if (rem < 0) {
        lift--;
        rem += dy;
      }
      mod -= dy;

      while (ey1 != ey2) {
        delta = lift;
        mod += rem;
        if (mod >= 0) {
          mod -= dy;
          ++delta;
        }

        final int xTo = xFrom + delta;
        _renderHLine(ey1, xFrom, polyScale - first, xTo, first);
        xFrom = xTo;

        ey1 += incr;
        _setCurrCell(xFrom >> polyShift, ey1);
      }
    }
    _renderHLine(ey1, xFrom, polyScale - first, x2, fy2);
  }

  int min_x() => _minX;
  int min_y() => _minY;
  int max_x() => _maxX;
  int max_y() => _maxY;

  int total_cells() {
    sortCells();
    return _sortedCells.length;
  }

  int scanline_num_cells(int y) {
    sortCells();
    for (final sy in _sortedY) {
      final cellY = _sortedCells[sy.start].y;
      if (cellY == y) return sy.num;
      if (cellY > y) break;
    }
    return 0;
  }

  /// Range of cells for scanline y. Returns empty range if nothing present.
  _ScanlineCells scanline_cells(int y) {
    sortCells();
    for (final sy in _sortedY) {
      final cellY = _sortedCells[sy.start].y;
      if (cellY == y) {
        return _ScanlineCells(_sortedCells, sy.start, sy.num);
      }
      if (cellY > y) break;
    }
    return _ScanlineCells(const [], 0, 0);
  }

  bool sorted() => _sorted;

  void _setCurrCell(int x, int y) {
    if (_currCell.notEqual(x, y, _styleCell)) {
      _addCurrCell();
      _currCell.styleFrom(_styleCell);
      _currCell.x = x;
      _currCell.y = y;
      _currCell.cover = 0;
      _currCell.area = 0;
    }
  }

  void _addCurrCell() {
    if ((_currCell.area | _currCell.cover) != 0) {
      _cells.add(PixelCellAa()..setFrom(_currCell));
    }
  }

  void _renderHLine(int ey, int x1, int y1, int x2, int y2) {
    int ex1 = x1 >> poly_subpixel_scale_e.poly_subpixel_shift;
    int ex2 = x2 >> poly_subpixel_scale_e.poly_subpixel_shift;
    int fx1 = x1 & poly_subpixel_scale_e.poly_subpixel_mask;
    int fx2 = x2 & poly_subpixel_scale_e.poly_subpixel_mask;

    int delta, p, first, dx;
    int incr, lift, mod, rem;

    // Trivial case: same height
    if (y1 == y2) {
      _setCurrCell(ex2, ey);
      return;
    }

    // Everything in one cell
    if (ex1 == ex2) {
      delta = y2 - y1;
      _currCell.cover += delta;
      _currCell.area += (fx1 + fx2) * delta;
      return;
    }

    p = (poly_subpixel_scale_e.poly_subpixel_scale - fx1) * (y2 - y1);
    first = poly_subpixel_scale_e.poly_subpixel_scale;
    incr = 1;
    dx = x2 - x1;

    if (dx < 0) {
      p = fx1 * (y2 - y1);
      first = 0;
      incr = -1;
      dx = -dx;
    }

    delta = p ~/ dx;
    mod = p % dx;
    if (mod < 0) {
      delta--;
      mod += dx;
    }

    _currCell.cover += delta;
    _currCell.area += (fx1 + first) * delta;
    ex1 += incr;
    _setCurrCell(ex1, ey);
    y1 += delta;

    if (ex1 != ex2) {
      p = poly_subpixel_scale_e.poly_subpixel_scale * (y2 - y1 + delta);
      lift = p ~/ dx;
      rem = p % dx;
      if (rem < 0) {
        lift--;
        rem += dx;
      }
      mod -= dx;

      while (ex1 != ex2) {
        delta = lift;
        mod += rem;
        if (mod >= 0) {
          mod -= dx;
          delta++;
        }
        _currCell.cover += delta;
        _currCell.area +=
            poly_subpixel_scale_e.poly_subpixel_scale * delta;
        y1 += delta;
        ex1 += incr;
        _setCurrCell(ex1, ey);
      }
    }

    delta = y2 - y1;
    _currCell.cover += delta;
    _currCell.area +=
        (fx2 + poly_subpixel_scale_e.poly_subpixel_scale - first) * delta;
  }

  void sortCells() {
    if (_sorted) return;
    _addCurrCell();
    _currCell = PixelCellAa(); // reset guard
    _sortedCells
      ..clear()
      ..addAll(_cells);

    if (_sortedCells.isEmpty) {
      _sorted = true;
      return;
    }

    _sortedCells.sort((a, b) {
      if (a.y == b.y) return a.x - b.x;
      return a.y - b.y;
    });

    _sortedY.clear();
    int start = 0;
    int currentY = _sortedCells[0].y;
    for (int i = 1; i < _sortedCells.length; i++) {
      if (_sortedCells[i].y != currentY) {
        _sortedY.add(_SortedY(start: start, num: i - start));
        start = i;
        currentY = _sortedCells[i].y;
      }
    }
    _sortedY.add(_SortedY(start: start, num: _sortedCells.length - start));
    _sorted = true;
  }
}
