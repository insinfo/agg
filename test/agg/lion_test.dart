import 'dart:io';
import 'dart:math' as math;
import 'package:test/test.dart';
import 'package:agg/src/agg/vertex_source/vertex_storage.dart';
import 'package:agg/src/agg/vertex_source/path_commands.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/image/image_buffer.dart';
import 'package:agg/src/agg/scanline_rasterizer.dart';
import 'package:agg/src/agg/scanline_renderer.dart';
import 'package:agg/src/agg/scanline_unpacked8.dart';
import 'package:agg/src/agg/transform/affine.dart';
import 'package:agg/src/agg/vertex_source/apply_transform.dart';
import 'package:agg/src/agg/image/png_encoder.dart';
import 'package:agg/src/agg/primitives/rectangle_double.dart';
import 'package:agg/src/agg/vertex_source/ivertex_source.dart';
import 'package:agg/src/shared/ref_param.dart';

RectangleDouble? boundingRect(IVertexSource vs) {
  vs.rewind();
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = double.negativeInfinity;
  double maxY = double.negativeInfinity;
  bool first = true;

  var x = RefParam(0.0);
  var y = RefParam(0.0);

  while (true) {
    var cmd = vs.vertex(x, y);
    if (cmd.isStop) break;
    if (cmd.isVertex) {
      if (x.value < minX) minX = x.value;
      if (y.value < minY) minY = y.value;
      if (x.value > maxX) maxX = x.value;
      if (y.value > maxY) maxY = y.value;
      first = false;
    }
  }

  if (first) return null;
  return RectangleDouble(minX, minY, maxX, maxY);
}

(List<VertexStorage>, List<Color>) parseLion() {
  final file = File('resources/lion.txt');
  final lines = file.readAsLinesSync();
  
  List<VertexStorage> paths = [];
  List<Color> colors = [];
  VertexStorage path = VertexStorage();
  Color color = Color(0, 0, 0, 255);
  FlagsAndCommand cmd = FlagsAndCommand.commandStop;

  for (var line in lines) {
    var v = line.trim().split(RegExp(r'\s+'));
    if (v.length == 1 && v[0].isNotEmpty) {
      var hex = v[0];
      var r = int.parse(hex.substring(0, 2), radix: 16);
      var g = int.parse(hex.substring(2, 4), radix: 16);
      var b = int.parse(hex.substring(4, 6), radix: 16);
      
      if (path.count > 0) {
        path.closePath();
        paths.add(path);
        colors.add(color);
      }
      path = VertexStorage();
      color = Color(r, g, b, 255);
    } else {
      for (var val in v) {
        if (val == "M") {
          cmd = FlagsAndCommand.commandMoveTo;
        } else if (val == "L") {
          cmd = FlagsAndCommand.commandLineTo;
        } else if (val.isNotEmpty) {
          var pts = val.split(",").map((x) => double.parse(x)).toList();
          
          if (cmd == FlagsAndCommand.commandLineTo) {
            path.lineTo(pts[0], pts[1]);
          } else if (cmd == FlagsAndCommand.commandMoveTo) {
             if (path.count > 0) {
                path.closePath();
             }
             path.moveTo(pts[0], pts[1]);
          }
        }
      }
    }
  }
  
  if (path.count > 0) {
    colors.add(color);
    path.closePath();
    paths.add(path);
  }
  
  return (paths, colors);
}

void main() {
  test('Lion Rendering Test', () {
    final (paths, colors) = parseLion();
    
    const width = 400;
    const height = 400;
    
    final buffer = ImageBuffer(width, height);
    // Clear to white
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        buffer.SetPixel(x, y, Color(255, 255, 255, 255));
      }
    }
    
    final ras = ScanlineRasterizer();
    final sl = ScanlineUnpacked8();
    
    if (paths.isEmpty) return;
    
    // Calculate bounding box
    RectangleDouble? r;
    for (var p in paths) {
      var rp = boundingRect(p);
      if (rp != null) {
        if (r == null) {
          r = rp;
        } else {
          r = RectangleDouble(
            math.min(r.left, rp.left),
            math.min(r.bottom, rp.bottom),
            math.max(r.right, rp.right),
            math.max(r.top, rp.top)
          );
        }
      }
    }
    
    if (r == null) return;
    
    // Center of bounding box:
    double cx = r.left + (r.right - r.left) / 2.0;
    double cy = r.bottom + (r.top - r.bottom) / 2.0;
    
    final mtx = Affine();
    mtx.translate(-cx, -cy);
    mtx.translate(width / 2.0, height / 2.0);
    
    // Render
    for (var i = 0; i < paths.length; i++) {
      var p = paths[i];
      var c = colors[i];
      
      var transformedPath = ApplyTransform(p, mtx);
      
      ras.add_path(transformedPath);
      ScanlineRenderer.renderSolid(ras, sl, buffer, c);
    }
    
    // Save image
    Directory('test/tmp').createSync(recursive: true);
    PngEncoder.saveImage(buffer, 'test/tmp/lion.png');
    
    // Verify file exists
    expect(File('test/tmp/lion.png').existsSync(), isTrue);
  });
}
