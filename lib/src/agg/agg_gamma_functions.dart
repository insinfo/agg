import 'dart:math' as math;

abstract class IGammaFunction {
  ///double GetGamma(double x);
  double getGamma(double x);
}

class GammaNone implements IGammaFunction {
  @override
  double getGamma(double x) {
    return x;
  }
}

//==============================================================gamma_power
class GammaPower implements IGammaFunction {
  double m_gamma;

  GammaPower([this.m_gamma = 1.0]);

  /// gamma_power(double g)
  GammaPower.fromGamma(double g) : m_gamma = g;

  /// void gamma(double g)
  set gamma(double g) {
    m_gamma = g;
  }

  /// double gamma()
  double get gamma {
    return m_gamma;
  }

  @override
  double getGamma(double x) {
    return math.pow(x, m_gamma).toDouble();
  }
}

//==========================================================gamma_threshold
class GammaThreshold implements IGammaFunction {
  double m_threshold;

  GammaThreshold([this.m_threshold = 0.5]);

  /// gamma_threshold(double t)
  GammaThreshold.fromThreshold(double t) : m_threshold = t;

  /// void threshold(double t)
  set threshold(double t) {
    m_threshold = t;
  }

  double get threshold {
    return m_threshold;
  }

  @override
  double getGamma(double x) {
    return (x < m_threshold) ? 0.0 : 1.0;
  }
}

//============================================================gamma_linear
class GammaLinear implements IGammaFunction {
  double m_start;
  double m_end;

  GammaLinear([this.m_start = 0.0, this.m_end = 1.0]);

  /// gamma_linear(double s, double e)
  GammaLinear.fromStartEnd(double s, double e)
      : m_start = s,
        m_end = e;

  void setStartEnd(double s, double e) {
    m_start = s;
    m_end = e;
  }

  set start(double s) {
    m_start = s;
  }

  set end(double e) {
    m_end = e;
  }

  double get start {
    return m_start;
  }

  double get end {
    return m_end;
  }

  @override
  double getGamma(double x) {
    if (x < m_start) return 0.0;
    if (x > m_end) return 1.0;
    double endMinusStart = m_end - m_start;
    if (endMinusStart != 0) {
      return (x - m_start) / endMinusStart;
    } else {
      return 0.0;
    }
  }
}

//==========================================================gamma_multiply
class GammaMultiply implements IGammaFunction {
  double m_mul;

  GammaMultiply([this.m_mul = 1.0]);

  GammaMultiply.fromV(double v) : m_mul = v;

  set value(double v) {
    m_mul = v;
  }

  double get value {
    return m_mul;
  }

  @override
  double getGamma(double x) {
    double y = x * m_mul;
    if (y > 1.0) y = 1.0;
    return y;
  }
}
