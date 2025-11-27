import 'package:agg/src/agg/transform/i_transform.dart';
import 'package:agg/src/agg/transform/affine.dart';
import 'package:agg/src/agg/agg_dda_line.dart';
import 'package:agg/src/agg/util.dart';

abstract class ISpanInterpolator {
  void begin(double x, double y, int len);
  void coordinates(List<int> xy); // x=[0], y=[1]
  void next();
  ITransform transformer();
  void setTransformer(ITransform trans);
  void resynchronize(double xe, double ye, int len);
  void localScale(List<int> xy);
}

class SpanInterpolatorLinear implements ISpanInterpolator {
  ITransform m_trans;
  Dda2LineInterpolator? m_li_x;
  Dda2LineInterpolator? m_li_y;

  static const int subpixelShift = 8;
  static const int subpixelScale = 1 << subpixelShift;

  SpanInterpolatorLinear(this.m_trans, [double? x, double? y, int? len]) {
    if (x != null && y != null && len != null) {
      begin(x, y, len);
    }
  }

  @override
  ITransform transformer() => m_trans;

  @override
  void setTransformer(ITransform trans) {
    m_trans = trans;
  }

  @override
  void localScale(List<int> xy) {
    if (m_trans is Affine) {
      var affine = m_trans as Affine;
      var d = [0.0, 0.0];
      affine.scalingAbs(d);
      xy[0] = Util.iround(d[0] * subpixelScale);
      xy[1] = Util.iround(d[1] * subpixelScale);
    } else {
       // Fallback or throw?
       // For now throw as per C# implementation if not supported
       throw UnimplementedError("localScale not implemented for this transform type");
    }
  }

  @override
  void begin(double x, double y, int len) {
    double tx = x;
    double ty = y;
    var pt = [tx, ty];
    m_trans.transform(pt);
    tx = pt[0];
    ty = pt[1];
    
    int x1 = Util.iround(tx * subpixelScale);
    int y1 = Util.iround(ty * subpixelScale);

    tx = x + len;
    ty = y;
    pt = [tx, ty];
    m_trans.transform(pt);
    tx = pt[0];
    ty = pt[1];
    
    int x2 = Util.iround(tx * subpixelScale);
    int y2 = Util.iround(ty * subpixelScale);

    m_li_x = Dda2LineInterpolator.forward(x1, x2, len);
    m_li_y = Dda2LineInterpolator.forward(y1, y2, len);
  }

  @override
  void resynchronize(double xe, double ye, int len) {
    var pt = [xe, ye];
    m_trans.transform(pt);
    xe = pt[0];
    ye = pt[1];
    
    m_li_x = Dda2LineInterpolator.forward(m_li_x!.y(), Util.iround(xe * subpixelScale), len);
    m_li_y = Dda2LineInterpolator.forward(m_li_y!.y(), Util.iround(ye * subpixelScale), len);
  }

  @override
  void next() {
    m_li_x!.next();
    m_li_y!.next();
  }

  @override
  void coordinates(List<int> xy) {
    xy[0] = m_li_x!.y();
    xy[1] = m_li_y!.y();
  }
}

abstract class ISpanInterpolatorFloat {
  void begin(double x, double y, int len);
  void coordinates(List<double> xy); // x=[0], y=[1]
  void next();
  ITransform transformer();
  void setTransformer(ITransform trans);
  void resynchronize(double xe, double ye, int len);
  void localScale(List<double> xy);
}

class SpanInterpolatorLinearFloat implements ISpanInterpolatorFloat {
  ITransform m_trans;
  double currentX = 0;
  double stepX = 0;
  double currentY = 0;
  double stepY = 0;

  SpanInterpolatorLinearFloat(this.m_trans, [double? x, double? y, int? len]) {
    if (x != null && y != null && len != null) {
      begin(x, y, len);
    }
  }

  @override
  ITransform transformer() => m_trans;

  @override
  void setTransformer(ITransform trans) {
    m_trans = trans;
  }

  @override
  void localScale(List<double> xy) {
    if (m_trans is Affine) {
      var affine = m_trans as Affine;
      affine.scalingAbs(xy);
    } else {
      throw UnimplementedError();
    }
  }

  @override
  void begin(double x, double y, int len) {
    double tx = x;
    double ty = y;
    var pt = [tx, ty];
    m_trans.transform(pt);
    currentX = pt[0];
    currentY = pt[1];

    tx = x + len;
    ty = y;
    pt = [tx, ty];
    m_trans.transform(pt);
    
    stepX = (pt[0] - currentX) / len;
    stepY = (pt[1] - currentY) / len;
  }

  @override
  void resynchronize(double xe, double ye, int len) {
    throw UnimplementedError();
  }

  @override
  void next() {
    currentX += stepX;
    currentY += stepY;
  }

  @override
  void coordinates(List<double> xy) {
    xy[0] = currentX;
    xy[1] = currentY;
  }
}
