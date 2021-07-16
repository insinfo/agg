abstract class IStyleHandler {
  bool is_solid(int style);

  //	Color color(int style);
  //	void generate_span(Color[] span, int spanIndex, int x, int y, int len, int style);
}

enum TransformQuality { Fastest, Best }

abstract class Graphics2D {
  TransformQuality _imageRenderQuality = TransformQuality.Fastest;
  TransformQuality get imageRenderQuality => _imageRenderQuality;
  set(TransformQuality v) => _imageRenderQuality = v;
}
