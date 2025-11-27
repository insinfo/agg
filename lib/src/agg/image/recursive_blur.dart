import 'dart:math';
import 'package:agg/src/agg/image/format_transposer.dart';
import 'package:agg/src/agg/image/iimage.dart';
import 'package:agg/src/agg/primitives/color.dart';
import 'package:agg/src/agg/util.dart';

abstract class RecursizeBlurCalculator {
  double r = 0, g = 0, b = 0, a = 0;

  RecursizeBlurCalculator createNew();

  void fromPix(Color c);

  void calc(double b1, double b2, double b3, double b4,
      RecursizeBlurCalculator c1, RecursizeBlurCalculator c2, RecursizeBlurCalculator c3, RecursizeBlurCalculator c4);

  void toPix(Color c);
}

class RecursiveBlur {
  List<RecursizeBlurCalculator?> m_sum1 = [];
  List<RecursizeBlurCalculator?> m_sum2 = [];
  List<Color> m_buf = [];
  RecursizeBlurCalculator m_RecursizeBlurCalculatorFactory;

  RecursiveBlur(this.m_RecursizeBlurCalculatorFactory);

  void blurX(IImageByte img, double radius) {
    if (radius < 0.62) return;
    if (img.width < 3) return;

    double s = radius * 0.5;
    double q = (s < 2.5) ?
                3.97156 - 4.14554 * sqrt(1 - 0.26891 * s) :
                0.98711 * s - 0.96330;

    double q2 = q * q;
    double q3 = q2 * q;

    double b0 = 1.0 / (1.578250 +
                        2.444130 * q +
                        1.428100 * q2 +
                        0.422205 * q3);

    double b1 = 2.44413 * q +
                  2.85619 * q2 +
                  1.26661 * q3;

    double b2 = -1.42810 * q2 +
                 -1.26661 * q3;

    double b3 = 0.422205 * q3;

    double b = 1 - (b1 + b2 + b3) * b0;

    b1 *= b0;
    b2 *= b0;
    b3 *= b0;

    int w = img.width;
    int h = img.height;
    int wm = w - 1;
    int x, y;

    int startCreatingAt = m_sum1.length;
    for (int i = startCreatingAt; i < w; i++) {
      m_sum1.add(null);
      m_sum2.add(null);
    }
    
    // Resize buffer
    if (m_buf.length < w) {
        m_buf = List.generate(w, (index) => Color(0,0,0,0));
    }

    for (int i = startCreatingAt; i < w; i++) {
      m_sum1[i] = m_RecursizeBlurCalculatorFactory.createNew();
      m_sum2[i] = m_RecursizeBlurCalculatorFactory.createNew();
    }

    for (y = 0; y < h; y++) {
      RecursizeBlurCalculator c = m_RecursizeBlurCalculatorFactory;
      c.fromPix(img.getPixel(0, y));
      m_sum1[0]!.calc(b, b1, b2, b3, c, c, c, c);
      c.fromPix(img.getPixel(1, y));
      m_sum1[1]!.calc(b, b1, b2, b3, c, m_sum1[0]!, m_sum1[0]!, m_sum1[0]!);
      c.fromPix(img.getPixel(2, y));
      m_sum1[2]!.calc(b, b1, b2, b3, c, m_sum1[1]!, m_sum1[0]!, m_sum1[0]!);

      for (x = 3; x < w; ++x) {
        c.fromPix(img.getPixel(x, y));
        m_sum1[x]!.calc(b, b1, b2, b3, c, m_sum1[x - 1]!, m_sum1[x - 2]!, m_sum1[x - 3]!);
      }

      m_sum2[wm]!.calc(b, b1, b2, b3, m_sum1[wm]!, m_sum1[wm]!, m_sum1[wm]!, m_sum1[wm]!);
      m_sum2[wm - 1]!.calc(b, b1, b2, b3, m_sum1[wm - 1]!, m_sum2[wm]!, m_sum2[wm]!, m_sum2[wm]!);
      m_sum2[wm - 2]!.calc(b, b1, b2, b3, m_sum1[wm - 2]!, m_sum2[wm - 1]!, m_sum2[wm]!, m_sum2[wm]!);
      m_sum2[wm]!.toPix(m_buf[wm]);
      m_sum2[wm - 1]!.toPix(m_buf[wm - 1]);
      m_sum2[wm - 2]!.toPix(m_buf[wm - 2]);

      for (x = wm - 3; x >= 0; --x) {
        m_sum2[x]!.calc(b, b1, b2, b3, m_sum1[x]!, m_sum2[x + 1]!, m_sum2[x + 2]!, m_sum2[x + 3]!);
        m_sum2[x]!.toPix(m_buf[x]);
      }

      img.copy_color_hspan(0, y, w, m_buf, 0);
    }
  }

  void blurY(IImageByte img, double radius) {
    FormatTransposer img2 = FormatTransposer(img);
    blurX(img2, radius);
  }

  void blur(IImageByte img, double radius) {
    blurX(img, radius);
    blurY(img, radius);
  }
}

class RecursiveBlurCalcRgb extends RecursizeBlurCalculator {
  @override
  RecursizeBlurCalculator createNew() {
    return RecursiveBlurCalcRgb();
  }

  @override
  void fromPix(Color c) {
    r = c.red.toDouble();
    g = c.green.toDouble();
    b = c.blue.toDouble();
  }

  @override
  void calc(double b1, double b2, double b3, double b4,
      RecursizeBlurCalculator c1, RecursizeBlurCalculator c2, RecursizeBlurCalculator c3, RecursizeBlurCalculator c4) {
    r = b1 * c1.r + b2 * c2.r + b3 * c3.r + b4 * c4.r;
    g = b1 * c1.g + b2 * c2.g + b3 * c3.g + b4 * c4.g;
    b = b1 * c1.b + b2 * c2.b + b3 * c3.b + b4 * c4.b;
  }

  @override
  void toPix(Color c) {
    c.red = Util.uround(r);
    c.green = Util.uround(g);
    c.blue = Util.uround(b);
  }
}

class RecursiveBlurCalcRgba extends RecursizeBlurCalculator {
  @override
  RecursizeBlurCalculator createNew() {
    return RecursiveBlurCalcRgba();
  }

  @override
  void fromPix(Color c) {
    r = c.red.toDouble();
    g = c.green.toDouble();
    b = c.blue.toDouble();
    a = c.alpha.toDouble();
  }

  @override
  void calc(double b1, double b2, double b3, double b4,
      RecursizeBlurCalculator c1, RecursizeBlurCalculator c2, RecursizeBlurCalculator c3, RecursizeBlurCalculator c4) {
    r = b1 * c1.r + b2 * c2.r + b3 * c3.r + b4 * c4.r;
    g = b1 * c1.g + b2 * c2.g + b3 * c3.g + b4 * c4.g;
    b = b1 * c1.b + b2 * c2.b + b3 * c3.b + b4 * c4.b;
    a = b1 * c1.a + b2 * c2.a + b3 * c3.a + b4 * c4.a;
  }

  @override
  void toPix(Color c) {
    c.red = Util.uround(r);
    c.green = Util.uround(g);
    c.blue = Util.uround(b);
    c.alpha = Util.uround(a);
  }
}

class RecursiveBlurCalcGray extends RecursizeBlurCalculator {
  @override
  RecursizeBlurCalculator createNew() {
    return RecursiveBlurCalcGray();
  }

  @override
  void fromPix(Color c) {
    r = c.red.toDouble();
  }

  @override
  void calc(double b1, double b2, double b3, double b4,
      RecursizeBlurCalculator c1, RecursizeBlurCalculator c2, RecursizeBlurCalculator c3, RecursizeBlurCalculator c4) {
    r = b1 * c1.r + b2 * c2.r + b3 * c3.r + b4 * c4.r;
  }

  @override
  void toPix(Color c) {
    c.red = Util.uround(r);
  }
}
