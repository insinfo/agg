import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/primitives/colorf.dart';

abstract class IColorType {
  ColorF toColorF();

  Color toColor();

  Color gradient(Color c, double k);

  int get red0To255;
  set red0To255(int v);

  int get green0To255;
  set green0To255(int v);

  int get blue0To255;
  set blue0To255(int v);

  int get alpha0To255;
  set alpha0To255(int v);

  double get red0To1;
  set red0To1(double v);

  double get green0To1;
  set green0To1(double v);

  double get blue0To1;
  set blue0To1(double v);

  double get alpha0To1;
  set alpha0To1(double v);
}
