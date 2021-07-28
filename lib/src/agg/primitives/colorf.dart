class ColorF {
  static final int base_shift = 8;
  static final int base_scale = (1 << base_shift);
  static final int base_mask = base_scale - 1;

  double red;
  double green;
  double blue;
  double alpha;

  ColorF();
}
