import 'package:agg/src/agg/transform/i_transform.dart';
import 'package:agg/src/agg/util.dart';
import 'package:agg/src/agg/spans/agg_span_interpolator_linear.dart';

class SpanSubdivAdaptor implements ISpanInterpolator {
  int m_subdiv_shift;
  int m_subdiv_size;
  int m_subdiv_mask;
  ISpanInterpolator m_interpolator;
  int m_src_x = 0;
  double m_src_y = 0;
  int m_pos = 0;
  int m_len = 0;

  static const int subpixelShift = 8;
  static const int subpixelScale = 1 << subpixelShift;

  SpanSubdivAdaptor(this.m_interpolator, [this.m_subdiv_shift = 4])
      : m_subdiv_size = 1 << 4,
        m_subdiv_mask = (1 << 4) - 1 {
    m_subdiv_size = 1 << m_subdiv_shift;
    m_subdiv_mask = m_subdiv_size - 1;
  }

  SpanSubdivAdaptor.withLen(ISpanInterpolator interpolator, double x, double y, int len, [int subdiv_shift = 4])
      : m_interpolator = interpolator,
        m_subdiv_shift = subdiv_shift,
        m_subdiv_size = 1 << subdiv_shift,
        m_subdiv_mask = (1 << subdiv_shift) - 1 {
    begin(x, y, len);
  }

  @override
  void resynchronize(double xe, double ye, int len) {
    throw UnimplementedError();
  }

  ISpanInterpolator get interpolator => m_interpolator;
  set interpolator(ISpanInterpolator intr) => m_interpolator = intr;

  @override
  ITransform transformer() => m_interpolator.transformer();

  @override
  void setTransformer(ITransform trans) {
    m_interpolator.setTransformer(trans);
  }

  int get subdivShift => m_subdiv_shift;
  set subdivShift(int shift) {
    m_subdiv_shift = shift;
    m_subdiv_size = 1 << m_subdiv_shift;
    m_subdiv_mask = m_subdiv_size - 1;
  }

  @override
  void begin(double x, double y, int len) {
    m_pos = 1;
    m_src_x = Util.iround(x * subpixelScale) + subpixelScale;
    m_src_y = y;
    m_len = len;
    if (len > m_subdiv_size) len = m_subdiv_size;
    m_interpolator.begin(x, y, len);
  }

  @override
  void next() {
    m_interpolator.next();
    if (m_pos >= m_subdiv_size) {
      int len = m_len;
      if (len > m_subdiv_size) len = m_subdiv_size;
      m_interpolator.resynchronize(m_src_x / subpixelScale + len, m_src_y, len);
      m_pos = 0;
    }
    m_src_x += subpixelScale;
    m_pos++;
    m_len--;
  }

  @override
  void coordinates(List<int> xy) {
    m_interpolator.coordinates(xy);
  }

  @override
  void localScale(List<int> xy) {
    m_interpolator.localScale(xy);
  }
}
