import 'dart:math';
import 'dart:typed_data';
import 'package:agg/src/agg/util.dart';
import 'package:agg/src/agg/agg_math.dart';

abstract class IImageFilterFunction {
  double radius();
  double calcWeight(double x);
}

class ImageFilterScale {
  static const int imageFilterShift = 14;
  static const int imageFilterScale = 1 << imageFilterShift;
  static const int imageFilterMask = imageFilterScale - 1;
}

class ImageSubpixelScale {
  static const int imageSubpixelShift = 8;
  static const int imageSubpixelScale = 1 << imageSubpixelShift;
  static const int imageSubpixelMask = imageSubpixelScale - 1;
}

class ImageFilterLookUpTable {
  double m_radius = 0;
  int m_diameter = 0;
  int m_start = 0;
  Int32List m_weight_array = Int32List(0);

  ImageFilterLookUpTable([IImageFilterFunction? filter, bool normalization = true]) {
    m_weight_array = Int32List(256);
    if (filter != null) {
      calculate(filter, normalization);
    }
  }

  void calculate(IImageFilterFunction filter, [bool normalization = true]) {
    double r = filter.radius();
    reallocLut(r);
    int i;
    int pivot = diameter() << (ImageSubpixelScale.imageSubpixelShift - 1);
    for (i = 0; i < pivot; i++) {
      double x = i.toDouble() / ImageSubpixelScale.imageSubpixelScale;
      double y = filter.calcWeight(x);
      m_weight_array[pivot + i] =
      m_weight_array[pivot - i] = Util.iround(y * ImageFilterScale.imageFilterScale);
    }
    int end = (diameter() << ImageSubpixelScale.imageSubpixelShift) - 1;
    m_weight_array[0] = m_weight_array[end];
    if (normalization) {
      normalize();
    }
  }

  double radius() => m_radius;
  int diameter() => m_diameter;
  int start() => m_start;
  Int32List weightArray() => m_weight_array;

  void normalize() {
    int i;
    int flip = 1;

    for (i = 0; i < ImageSubpixelScale.imageSubpixelScale; i++) {
      while (true) {
        int sum = 0;
        int j;
        for (j = 0; j < m_diameter; j++) {
          sum += m_weight_array[j * ImageSubpixelScale.imageSubpixelScale + i];
        }

        if (sum == ImageFilterScale.imageFilterScale) break;

        double k = ImageFilterScale.imageFilterScale.toDouble() / sum.toDouble();
        sum = 0;
        for (j = 0; j < m_diameter; j++) {
          m_weight_array[j * ImageSubpixelScale.imageSubpixelScale + i] =
              Util.iround(m_weight_array[j * ImageSubpixelScale.imageSubpixelScale + i] * k);
          sum += m_weight_array[j * ImageSubpixelScale.imageSubpixelScale + i];
        }

        sum -= ImageFilterScale.imageFilterScale;
        int inc = (sum > 0) ? -1 : 1;

        for (j = 0; j < m_diameter && sum != 0; j++) {
          flip ^= 1;
          int idx = flip != 0 ? m_diameter ~/ 2 + j ~/ 2 : m_diameter ~/ 2 - j ~/ 2;
          int v = m_weight_array[idx * ImageSubpixelScale.imageSubpixelScale + i];
          if (v < ImageFilterScale.imageFilterScale) {
            m_weight_array[idx * ImageSubpixelScale.imageSubpixelScale + i] += inc;
            sum += inc;
          }
        }
      }
    }

    int pivot = m_diameter << (ImageSubpixelScale.imageSubpixelShift - 1);

    for (i = 0; i < pivot; i++) {
      m_weight_array[pivot + i] = m_weight_array[pivot - i];
    }
    int end = (diameter() << ImageSubpixelScale.imageSubpixelShift) - 1;
    m_weight_array[0] = m_weight_array[end];
  }

  void reallocLut(double radius) {
    m_radius = radius;
    m_diameter = Util.uceil(radius) * 2;
    m_start = -(m_diameter ~/ 2 - 1);
    int size = m_diameter << ImageSubpixelScale.imageSubpixelShift;
    if (size > m_weight_array.length) {
      var newArray = Int32List(size);
      newArray.setAll(0, m_weight_array);
      m_weight_array = newArray;
    }
  }
}

class ImageFilterBilinear implements IImageFilterFunction {
  @override
  double radius() => 1.0;

  @override
  double calcWeight(double x) {
    if (x.abs() < 1) {
      if (x < 0) {
        return 1.0 + x;
      } else {
        return 1.0 - x;
      }
    }
    return 0;
  }
}

class ImageFilterHanning implements IImageFilterFunction {
  @override
  double radius() => 1.0;

  @override
  double calcWeight(double x) {
    return 0.5 + 0.5 * cos(pi * x);
  }
}

class ImageFilterHamming implements IImageFilterFunction {
  @override
  double radius() => 1.0;

  @override
  double calcWeight(double x) {
    return 0.54 + 0.46 * cos(pi * x);
  }
}

class ImageFilterHermite implements IImageFilterFunction {
  @override
  double radius() => 1.0;

  @override
  double calcWeight(double x) {
    return (2.0 * x - 3.0) * x * x + 1.0;
  }
}

class ImageFilterQuadric implements IImageFilterFunction {
  @override
  double radius() => 1.5;

  @override
  double calcWeight(double x) {
    double t;
    if (x < 0.5) return 0.75 - x * x;
    if (x < 1.5) { t = x - 1.5; return 0.5 * t * t; }
    return 0.0;
  }
}

class ImageFilterBicubic implements IImageFilterFunction {
  static double pow3(double x) {
    return (x <= 0.0) ? 0.0 : x * x * x;
  }

  @override
  double radius() => 2.0;

  @override
  double calcWeight(double x) {
    return (1.0 / 6.0) *
        (pow3(x + 2) - 4 * pow3(x + 1) + 6 * pow3(x) - 4 * pow3(x - 1));
  }
}

class ImageFilterKaiser implements IImageFilterFunction {
  double a = 0;
  double i0a = 0;
  double epsilon = 0;

  ImageFilterKaiser([double b = 6.33]) {
    a = b;
    epsilon = 1e-12;
    i0a = 1.0 / besselI0(b);
  }

  @override
  double radius() => 1.0;

  @override
  double calcWeight(double x) {
    return besselI0(a * sqrt(1.0 - x * x)) * i0a;
  }

  double besselI0(double x) {
    int i;
    double sum, y, t;

    sum = 1.0;
    y = x * x / 4.0;
    t = y;

    for (i = 2; t > epsilon; i++) {
      sum += t;
      t *= y / (i * i);
    }
    return sum;
  }
}

class ImageFilterCatrom implements IImageFilterFunction {
  @override
  double radius() => 2.0;

  @override
  double calcWeight(double x) {
    if (x < 1.0) return 0.5 * (2.0 + x * x * (-5.0 + x * 3.0));
    if (x < 2.0) return 0.5 * (4.0 + x * (-8.0 + x * (5.0 - x)));
    return 0.0;
  }
}

class ImageFilterMitchell implements IImageFilterFunction {
  double p0 = 0, p2 = 0, p3 = 0;
  double q0 = 0, q1 = 0, q2 = 0, q3 = 0;

  ImageFilterMitchell([double b = 1.0 / 3.0, double c = 1.0 / 3.0]) {
    p0 = ((6.0 - 2.0 * b) / 6.0);
    p2 = ((-18.0 + 12.0 * b + 6.0 * c) / 6.0);
    p3 = ((12.0 - 9.0 * b - 6.0 * c) / 6.0);
    q0 = ((8.0 * b + 24.0 * c) / 6.0);
    q1 = ((-12.0 * b - 48.0 * c) / 6.0);
    q2 = ((6.0 * b + 30.0 * c) / 6.0);
    q3 = ((-b - 6.0 * c) / 6.0);
  }

  @override
  double radius() => 2.0;

  @override
  double calcWeight(double x) {
    if (x < 1.0) return p0 + x * x * (p2 + x * p3);
    if (x < 2.0) return q0 + x * (q1 + x * (q2 + x * q3));
    return 0.0;
  }
}

class ImageFilterSpline16 implements IImageFilterFunction {
  @override
  double radius() => 2.0;

  @override
  double calcWeight(double x) {
    if (x < 1.0) {
      return ((x - 9.0 / 5.0) * x - 1.0 / 5.0) * x + 1.0;
    }
    return ((-1.0 / 3.0 * (x - 1) + 4.0 / 5.0) * (x - 1) - 7.0 / 15.0) * (x - 1);
  }
}

class ImageFilterSpline36 implements IImageFilterFunction {
  @override
  double radius() => 3.0;

  @override
  double calcWeight(double x) {
    if (x < 1.0) {
      return ((13.0 / 11.0 * x - 453.0 / 209.0) * x - 3.0 / 209.0) * x + 1.0;
    }
    if (x < 2.0) {
      return ((-6.0 / 11.0 * (x - 1) + 270.0 / 209.0) * (x - 1) - 156.0 / 209.0) * (x - 1);
    }
    return ((1.0 / 11.0 * (x - 2) - 45.0 / 209.0) * (x - 2) + 26.0 / 209.0) * (x - 2);
  }
}

class ImageFilterGaussian implements IImageFilterFunction {
  @override
  double radius() => 2.0;

  @override
  double calcWeight(double x) {
    return exp(-2.0 * x * x) * sqrt(2.0 / pi);
  }
}

class ImageFilterBessel implements IImageFilterFunction {
  @override
  double radius() => 3.2383;

  @override
  double calcWeight(double x) {
    return (x == 0.0) ? pi / 4.0 : AggMath.besj(pi * x, 1) / (2.0 * x);
  }
}

class ImageFilterSinc implements IImageFilterFunction {
  double m_radius;

  ImageFilterSinc(double r) : m_radius = (r < 2.0 ? 2.0 : r);

  @override
  double radius() => m_radius;

  @override
  double calcWeight(double x) {
    if (x == 0.0) return 1.0;
    x *= pi;
    return sin(x) / x;
  }
}

class ImageFilterLanczos implements IImageFilterFunction {
  double m_radius;

  ImageFilterLanczos(double r) : m_radius = (r < 2.0 ? 2.0 : r);

  @override
  double radius() => m_radius;

  @override
  double calcWeight(double x) {
    if (x == 0.0) return 1.0;
    if (x > m_radius) return 0.0;
    x *= pi;
    double xr = x / m_radius;
    return (sin(x) / x) * (sin(xr) / xr);
  }
}

class ImageFilterBlackman implements IImageFilterFunction {
  double m_radius;

  ImageFilterBlackman(double r) : m_radius = (r < 2.0 ? 2.0 : r);

  @override
  double radius() => m_radius;

  @override
  double calcWeight(double x) {
    if (x == 0.0) return 1.0;
    if (x > m_radius) return 0.0;
    x *= pi;
    double xr = x / m_radius;
    return (sin(x) / x) * (0.42 + 0.5 * cos(xr) + 0.08 * cos(2 * xr));
  }
}
