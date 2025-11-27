import 'package:agg/src/agg/agg_basics.dart';
import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/scanline_renderer.dart';
import 'package:agg/src/agg/scanline_unpacked8.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';
import 'package:agg/src/agg/vertex_source/ivertex_source.dart';

enum CompoundLayerOrder { direct, inverse }

class _CompoundStyle {
  final List<VertexStorage> paths = [];
  Color fill;

  _CompoundStyle(this.fill);
}

/// Simplified compound rasterizer that layers multiple styles on top of each
/// other. This is a lightweight port of AGG's rasterizer_compound_aa.
class RasterizerCompoundAa {
  final Map<int, _CompoundStyle> _styles = {};
  final ScanlineRasterizer _rasterizer = ScanlineRasterizer();
  final ScanlineUnpacked8 _scanline = ScanlineUnpacked8();

  CompoundLayerOrder layerOrder = CompoundLayerOrder.direct;
  filling_rule_e fillingRule = filling_rule_e.fill_non_zero;

  /// Registers or updates a style with the given [styleId] and [fill] color.
  /// Styles must be defined before they can host paths.
  void defineStyle(int styleId, Color fill) {
    final style = _styles[styleId];
    if (style != null) {
      style.fill = fill;
    } else {
      _styles[styleId] = _CompoundStyle(fill);
    }
  }

  /// Adds a copy of [source] to the style identified by [styleId].
  void addPath(IVertexSource source, int styleId) {
    final style = _styles[styleId];
    if (style == null) {
      throw StateError('Style $styleId must be defined before adding paths.');
    }
    final clone = VertexStorage();
    clone.concat(source);
    style.paths.add(clone);
  }

  /// Clears all defined styles and their accumulated paths.
  void clear() {
    _styles.clear();
  }

  /// Renders the defined styles into [target]. Caller should mark the image
  /// changed if needed.
  void render(IImageByte target) {
    if (_styles.isEmpty) {
      return;
    }

    final keys = _styles.keys.toList()..sort();
    if (layerOrder == CompoundLayerOrder.inverse) {
      keys.replaceRange(0, keys.length, keys.reversed);
    }

    for (final key in keys) {
      final style = _styles[key]!;
      if (style.paths.isEmpty) continue;

      _rasterizer.reset();
      _rasterizer.filling_rule(fillingRule);
      for (final path in style.paths) {
        _rasterizer.add_path(path);
      }
      if (_rasterizer.rewind_scanlines()) {
        ScanlineRenderer.renderSolid(
          _rasterizer,
          _scanline,
          target,
          style.fill,
        );
      }
    }
  }
}
