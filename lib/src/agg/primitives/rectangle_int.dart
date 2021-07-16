class RectangleInt {
  int left, bottom, right, top;

  RectangleInt(int left, int bottom, int right, int top) {
    this.left = left;
    this.bottom = bottom;
    this.right = right;
    this.top = top;
  }

  void setRect(int left, int bottom, int right, int top) {
    init(left, bottom, right, top);
  }

  void init(int x1_, int y1_, int x2_, int y2_) {
    left = x1_;
    bottom = y1_;
    right = x2_;
    top = y2_;
  }

  // This function assumes the rect is normalized
  int get width {
    return right - left;
  }

  // This function assumes the rect is normalized
  int get height {
    return top - bottom;
  }

  RectangleInt normalize() {
    int t;
    if (left > right) {
      t = left;
      left = right;
      right = t;
    }
    if (bottom > top) {
      t = bottom;
      bottom = top;
      top = t;
    }
    return this;
  }

  void expandToInclude(RectangleInt rectToInclude) {
    if (right < rectToInclude.right) right = rectToInclude.right;
    if (top < rectToInclude.top) top = rectToInclude.top;
    if (left > rectToInclude.left) left = rectToInclude.left;
    if (bottom > rectToInclude.bottom) bottom = rectToInclude.bottom;
  }

  bool clip(RectangleInt r) {
    if (right > r.right) right = r.right;
    if (top > r.top) top = r.top;
    if (left < r.left) left = r.left;
    if (bottom < r.bottom) bottom = r.bottom;
    return left <= right && bottom <= top;
  }

  bool is_valid() {
    return left <= right && bottom <= top;
  }

  bool hit_test(int x, int y) {
    return (x >= left && x <= right && y >= bottom && y <= top);
  }

  bool intersectRectangles(RectangleInt rectToCopy, RectangleInt rectToIntersectWith) {
    left = rectToCopy.left;
    bottom = rectToCopy.bottom;
    right = rectToCopy.right;
    top = rectToCopy.top;

    if (left < rectToIntersectWith.left) left = rectToIntersectWith.left;
    if (bottom < rectToIntersectWith.bottom) bottom = rectToIntersectWith.bottom;
    if (right > rectToIntersectWith.right) right = rectToIntersectWith.right;
    if (top > rectToIntersectWith.top) top = rectToIntersectWith.top;

    if (left < right && bottom < top) {
      return true;
    }

    return false;
  }

  bool intersectWithRectangle(RectangleInt rectToIntersectWith) {
    if (left < rectToIntersectWith.left) left = rectToIntersectWith.left;
    if (bottom < rectToIntersectWith.bottom) bottom = rectToIntersectWith.bottom;
    if (right > rectToIntersectWith.right) right = rectToIntersectWith.right;
    if (top > rectToIntersectWith.top) top = rectToIntersectWith.top;

    if (left < right && bottom < top) {
      return true;
    }

    return false;
  }

  static bool doIntersect(RectangleInt rect1, RectangleInt rect2) {
    int x1 = rect1.left;
    int y1 = rect1.bottom;
    int x2 = rect1.right;
    int y2 = rect1.top;

    if (x1 < rect2.left) x1 = rect2.left;
    if (y1 < rect2.bottom) y1 = rect2.bottom;
    if (x2 > rect2.right) x2 = rect2.right;
    if (y2 > rect2.top) y2 = rect2.top;

    if (x1 < x2 && y1 < y2) {
      return true;
    }

    return false;
  }

  //---------------------------------------------------------unite_rectangles
  void unite_rectangles(RectangleInt r1, RectangleInt r2) {
    left = r1.left;
    bottom = r1.bottom;
    right = r1.right;
    right = r1.top;
    if (right < r2.right) right = r2.right;
    if (top < r2.top) top = r2.top;
    if (left > r2.left) left = r2.left;
    if (bottom > r2.bottom) bottom = r2.bottom;
  }

  void inflate(int inflateSize) {
    left = left - inflateSize;
    bottom = bottom - inflateSize;
    right = right + inflateSize;
    top = top + inflateSize;
  }

  void offset(int x, int y) {
    left = left + x;
    bottom = bottom + y;
    right = right + x;
    top = top + y;
  }

  int get hashCode {
    return {left, right, bottom, top}.hashCode;
  }

  static bool clipRects(RectangleInt pBoundingRect, RectangleInt pSourceRect, RectangleInt pDestRect) {
    // clip off the top so we don't write into random memory
    if (pDestRect.top < pBoundingRect.top) {
      // This type of clipping only works when we aren't scaling an image...
      // If we are scaling an image, the source and dest sizes won't match
      if (pSourceRect.height != pDestRect.height) {
        throw new Exception("source and dest rects must have the same height");
      }

      pSourceRect.top += pBoundingRect.top - pDestRect.top;
      pDestRect.top = pBoundingRect.top;
      if (pDestRect.top >= pDestRect.bottom) {
        return false;
      }
    }
    // clip off the bottom
    if (pDestRect.bottom > pBoundingRect.bottom) {
      // This type of clipping only works when we aren't scaling an image...
      // If we are scaling an image, the source and dest sizes won't match
      if (pSourceRect.height != pDestRect.height) {
        throw new Exception("source and dest rects must have the same height");
      }

      pSourceRect.bottom -= pDestRect.bottom - pBoundingRect.bottom;
      pDestRect.bottom = pBoundingRect.bottom;
      if (pDestRect.bottom <= pDestRect.top) {
        return false;
      }
    }

    // clip off the left
    if (pDestRect.left < pBoundingRect.left) {
      // This type of clipping only works when we aren't scaling an image...
      // If we are scaling an image, the source and dest sizes won't match
      if (pSourceRect.width != pDestRect.width) {
        throw new Exception("source and dest rects must have the same width");
      }

      pSourceRect.left += pBoundingRect.left - pDestRect.left;
      pDestRect.left = pBoundingRect.left;
      if (pDestRect.left >= pDestRect.right) {
        return false;
      }
    }
    // clip off the right
    if (pDestRect.right > pBoundingRect.right) {
      // This type of clipping only works when we aren't scaling an image...
      // If we are scaling an image, the source and dest sizes won't match
      if (pSourceRect.width != pDestRect.width) {
        throw new Exception("source and dest rects must have the same width");
      }

      pSourceRect.right -= pDestRect.right - pBoundingRect.right;
      pDestRect.right = pBoundingRect.right;
      if (pDestRect.right <= pDestRect.left) {
        return false;
      }
    }

    return true;
  }

  //***************************************************************************************************************************************************
  static bool ClipRect(RectangleInt pBoundingRect, RectangleInt pDestRect) {
    // clip off the top so we don't write into random memory
    if (pDestRect.top < pBoundingRect.top) {
      pDestRect.top = pBoundingRect.top;
      if (pDestRect.top >= pDestRect.bottom) {
        return false;
      }
    }
    // clip off the bottom
    if (pDestRect.bottom > pBoundingRect.bottom) {
      pDestRect.bottom = pBoundingRect.bottom;
      if (pDestRect.bottom <= pDestRect.top) {
        return false;
      }
    }

    // clip off the left
    if (pDestRect.left < pBoundingRect.left) {
      pDestRect.left = pBoundingRect.left;
      if (pDestRect.left >= pDestRect.right) {
        return false;
      }
    }

    // clip off the right
    if (pDestRect.right > pBoundingRect.right) {
      pDestRect.right = pBoundingRect.right;
      if (pDestRect.right <= pDestRect.left) {
        return false;
      }
    }

    return true;
  }
}
