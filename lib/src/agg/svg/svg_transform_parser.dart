import 'dart:math' as math;
import 'package:agg/src/agg/transform/affine.dart';

class SvgTransformParser {
  static final RegExp _transformRe = RegExp(r'(\w+)\s*\(([^)]*)\)');
  static final RegExp _separatorRe = RegExp(r'[,\s]+');

  static Affine parse(String? transform) {
    final affine = Affine.identity();
    if (transform == null || transform.isEmpty) return affine;

    for (final match in _transformRe.allMatches(transform)) {
      final name = match.group(1)!;
      final argsStr = match.group(2)!;
      final args = argsStr.trim().split(_separatorRe).where((s) => s.isNotEmpty).map(double.parse).toList();

      switch (name) {
        case 'matrix':
          if (args.length == 6) {
            affine.premultiply(Affine.fromArray(args));
          }
          break;
        case 'translate':
          if (args.length == 1) {
            affine.premultiply(Affine.translation(args[0], 0));
          } else if (args.length == 2) {
            affine.premultiply(Affine.translation(args[0], args[1]));
          }
          break;
        case 'scale':
          if (args.length == 1) {
            affine.premultiply(Affine.scaling(args[0]));
          } else if (args.length == 2) {
            affine.premultiply(Affine.scaling(args[0], args[1]));
          }
          break;
        case 'rotate':
          if (args.length == 1) {
            affine.premultiply(Affine.rotation(args[0] * math.pi / 180.0));
          } else if (args.length == 3) {
            affine.premultiply(Affine.translation(args[1], args[2]));
            affine.premultiply(Affine.rotation(args[0] * math.pi / 180.0));
            affine.premultiply(Affine.translation(-args[1], -args[2]));
          }
          break;
        case 'skewX':
          if (args.length == 1) {
            affine.premultiply(Affine.skewing(args[0] * math.pi / 180.0, 0));
          }
          break;
        case 'skewY':
          if (args.length == 1) {
            affine.premultiply(Affine.skewing(0, args[0] * math.pi / 180.0));
          }
          break;
      }
    }
    return affine;
  }
}
