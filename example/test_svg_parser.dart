import 'dart:io';
import 'package:agg/src/agg/svg/svg_parser.dart';
import 'package:agg/src/agg/svg/svg_paint.dart';

void main() {
  final files = [
    'resources/image/brasao_editado_1.svg',
    'resources/image/logo_icon.svg'
  ];

  for (final file in files) {
    try {
      final content = File(file).readAsStringSync();
      final shapes = SvgParser.parseString(content);
      print('Parsed $file: ${shapes.length} shapes found.');
      int gradients = 0;
      int solids = 0;
      for (final shape in shapes) {
         if (shape.fill is SvgPaintLinearGradient) gradients++;
         if (shape.fill is SvgPaintSolid) solids++;
      }
      print('  Gradients: $gradients, Solids: $solids');
    } catch (e) {
      print('Error parsing $file: $e');
    }
  }
}
