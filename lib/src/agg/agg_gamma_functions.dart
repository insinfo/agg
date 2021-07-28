import 'dart:math' as math;

abstract class IGammaFunction {
  ///double GetGamma(double x);
  double getGamma(double x);
}

class Gamma_none implements IGammaFunction {
  double getGamma(double x) {
    return x;
  }
}

//==============================================================gamma_power
class Gamma_power implements IGammaFunction {
  Gamma_power() {
    m_gamma = 1.0;
  }

  /// gamma_power(double g)
  Gamma_power.fromGama(double g) {
    m_gamma = g;
  }

  /// void gamma(double g)
  set gamma(double g) {
    m_gamma = g;
  }

  /// double gamma()
  double get gamma {
    return m_gamma;
  }

  double getGamma(double x) {
    return math.pow(x, m_gamma);
  }

  double m_gamma;
}

//==========================================================gamma_threshold
class Gamma_threshold implements IGammaFunction {
  Gamma_threshold() {
    m_threshold = 0.5;
  }

  /// gamma_threshold(double t)
  Gamma_threshold.fromThreshold(double t) {
    m_threshold = t;
  }

  /// void threshold(double t)
  set threshold(double t) {
    m_threshold = t;
  }

  double get threshold {
    return m_threshold;
  }

  double getGamma(double x) {
    return (x < m_threshold) ? 0.0 : 1.0;
  }

  double m_threshold;
}

//============================================================gamma_linear
class Gamma_linear implements IGammaFunction {
  Gamma_linear() {
    m_start = (0.0);
    m_end = (1.0);
  }

  /// gamma_linear(double s, double e)
  Gamma_linear.fromStartEnd(double s, double e) {
    m_start = (s);
    m_end = (e);
  }

  void fromStartEnd(double s, double e) {
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

  double getGamma(double x) {
    if (x < m_start) return 0.0;
    if (x > m_end) return 1.0;
    double endMinusStart = m_end - m_start;
    if (endMinusStart != 0)
      return (x - m_start) / endMinusStart;
    else
      return 0.0;
  }

  double m_start;
  double m_end;
}

//==========================================================gamma_multiply
class Gamma_multiply implements IGammaFunction {
  Gamma_multiply() {
    m_mul = (1.0);
  }

  Gamma_multiply.fromV(double v) {
    m_mul = (v);
  }

  set value(double v) {
    m_mul = v;
  }

  double get value {
    return m_mul;
  }

  double getGamma(double x) {
    double y = x * m_mul;
    if (y > 1.0) y = 1.0;
    return y;
  }

  double m_mul;
}
