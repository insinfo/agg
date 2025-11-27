//==================================================rasterizer_scanline_aa
// Polygon rasterizer that is used to render filled polygons with
// high-quality Anti-Aliasing. See agg_rasterizer_scanline_aa in AGG.
import 'package:agg/src/shared/ref_param.dart';
import 'package:agg/src/agg/agg_basics.dart';
import 'package:agg/src/agg/agg_gamma_functions.dart';
import 'package:agg/src/agg/interfaces/iscanline.dart';
import 'package:agg/src/agg/primitives/rectangle_double.dart';
import 'package:agg/src/agg/rasterizer_cells_aa.dart';
import 'package:agg/src/agg/vector_clipper.dart';
import 'package:agg/src/agg/vertex_source/ivertex_source.dart';
import 'package:agg/src/agg/vertex_source/path_commands.dart';

abstract class IRasterizer {
  int min_x();
  int min_y();
  int max_x();
  int max_y();

  void gamma(IGammaFunction gamma_function);
  bool sweep_scanline(IScanlineCache sl);
  void reset();
  void add_path(IVertexSource vs);
  bool rewind_scanlines();
}

class ScanlineRasterizer implements IRasterizer {
  final RasterizerCellsAa _outline;
  final VectorClipper _clipper;
  final List<int> _gamma =
      List<int>.filled(_AaScale.aa_scale, 0, growable: false);
  filling_rule_e _fillingRule = filling_rule_e.fill_non_zero;
  bool _autoClose = true;
  int _startX = 0;
  int _startY = 0;
  _RasterizerStatus _status = _RasterizerStatus.initial;
  int _scanY = 0;

  ScanlineRasterizer({VectorClipper? clipper})
      : _outline = RasterizerCellsAa(),
        _clipper = clipper ?? VectorClipper() {
    for (int i = 0; i < _AaScale.aa_scale; i++) {
      _gamma[i] = i;
    }
  }

  void reset_clipping() {
    reset();
    _clipper.reset_clipping();
  }

  RectangleDouble getVectorClipBox() {
    return RectangleDouble(
      _clipper.downscale(_clipper.clipBox.left).toDouble(),
      _clipper.downscale(_clipper.clipBox.bottom).toDouble(),
      _clipper.downscale(_clipper.clipBox.right).toDouble(),
      _clipper.downscale(_clipper.clipBox.top).toDouble(),
    );
  }

  void setVectorClipBox(double x1, double y1, double x2, double y2) {
    reset();
    _clipper.clip_box(
      _clipper.upscale(x1),
      _clipper.upscale(y1),
      _clipper.upscale(x2),
      _clipper.upscale(y2),
    );
  }

  void filling_rule(filling_rule_e rule) {
    _fillingRule = rule;
  }

  void auto_close(bool flag) {
    _autoClose = flag;
  }

  @override
  void gamma(IGammaFunction gamma_function) {
    for (int i = 0; i < _AaScale.aa_scale; i++) {
      _gamma[i] = Agg_basics.uround(
        gamma_function
                .getGamma(i / _AaScale.aa_mask)
                .clamp(0.0, 1.0) *
            _AaScale.aa_mask,
      );
    }
  }

  void move_to_d(double x, double y) {
    if (_outline.sorted()) reset();
    if (_autoClose) close_polygon();
    _clipper.move_to(_startX = _clipper.upscale(x), _startY = _clipper.upscale(y));
    _status = _RasterizerStatus.move_to;
  }

  void line_to_d(double x, double y) {
    _clipper.line_to(
      _outline,
      _clipper.upscale(x),
      _clipper.upscale(y),
    );
    _status = _RasterizerStatus.line_to;
  }

  void close_polygon() {
    if (_status == _RasterizerStatus.line_to) {
      _clipper.line_to(_outline, _startX, _startY);
      _status = _RasterizerStatus.closed;
    }
  }

  void _addVertex(FlagsAndCommand cmd, double x, double y) {
    if (ShapePath.isMoveTo(cmd)) {
      move_to_d(x, y);
    } else if (ShapePath.isVertex(cmd)) {
      line_to_d(x, y);
    } else if (ShapePath.isClose(cmd)) {
      close_polygon();
    }
  }

  @override
  void add_path(IVertexSource vs) {
    final x = RefParam(0.0);
    final y = RefParam(0.0);
    vs.rewind();
    if (_outline.sorted()) {
      reset();
    }

    while (true) {
      final cmd = vs.vertex(x, y);
      if (ShapePath.isStop(cmd)) break;
      _addVertex(cmd, x.value, y.value);
    }
  }

  @override
  void reset() {
    _outline.reset();
    _status = _RasterizerStatus.initial;
  }

  @override
  int min_x() => _outline.min_x();
  @override
  int min_y() => _outline.min_y();
  @override
  int max_x() => _outline.max_x();
  @override
  int max_y() => _outline.max_y();

  void _ensureSorted() {
    if (_autoClose) close_polygon();
    _outline.sortCells();
  }

  @override
  bool rewind_scanlines() {
    _ensureSorted();
    if (_outline.total_cells() == 0) {
      return false;
    }
    _scanY = _outline.min_y();
    return true;
  }

  bool _navigateScanline(int y) {
    _ensureSorted();
    if (_outline.total_cells() == 0 ||
        y < _outline.min_y() ||
        y > _outline.max_y()) {
      return false;
    }
    _scanY = y;
    return true;
  }

  int calculate_alpha(int area) {
    int cover = area >>
        ((poly_subpixel_scale_e.poly_subpixel_shift * 2 + 1) -
            _AaScale.aa_shift);
    if (cover < 0) cover = -cover;

    if (_fillingRule == filling_rule_e.fill_even_odd) {
      cover &= _AaScale.aa_mask2;
      if (cover > _AaScale.aa_scale) {
        cover = _AaScale.aa_scale2 - cover;
      }
    }
    if (cover > _AaScale.aa_mask) {
      cover = _AaScale.aa_mask;
    }
    return _gamma[cover];
  }

  @override
  bool sweep_scanline(IScanlineCache scanlineCache) {
    for (;;) {
      if (_scanY > _outline.max_y()) {
        return false;
      }

      scanlineCache.resetSpans();
      final scanCells = _outline.scanline_cells(_scanY);
      int numCells = scanCells.length;
      List<PixelCellAa> cells = scanCells.cells;
      int offset = scanCells.offset;
      int cover = 0;

      while (numCells != 0) {
        PixelCellAa cur = cells[offset];
        int x = cur.x;
        int area = cur.area;

        cover += cur.cover;

        while (--numCells != 0) {
          offset++;
          cur = cells[offset];
          if (cur.x != x) {
            break;
          }
          area += cur.area;
          cover += cur.cover;
        }

        if (area != 0) {
          final int alpha = calculate_alpha(
            (cover << (poly_subpixel_scale_e.poly_subpixel_shift + 1)) - area,
          );
          if (alpha != 0) {
            scanlineCache.add_cell(x, alpha);
          }
          x++;
        }

        if (numCells != 0 && cur.x > x) {
          final int alpha = calculate_alpha(
            cover << (poly_subpixel_scale_e.poly_subpixel_shift + 1),
          );
          if (alpha != 0) {
            scanlineCache.add_span(x, cur.x - x, alpha);
          }
        }
      }

      if (scanlineCache.num_spans() != 0) break;
      ++_scanY;
    }

    scanlineCache.finalize(_scanY);
    ++_scanY;
    return true;
  }

  bool hit_test(int tx, int ty) {
    if (!_navigateScanline(ty)) return false;
    // A proper hit-test scanline can be added later; navigating Y suffices here.
    return true;
  }
}

enum _RasterizerStatus { initial, move_to, line_to, closed }

class _AaScale {
  static const aa_shift = 8;
  static const aa_scale = 1 << aa_shift;
  static const aa_mask = aa_scale - 1;
  static const aa_scale2 = aa_scale * 2;
  static const aa_mask2 = aa_scale2 - 1;
}
