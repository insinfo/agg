abstract class IVertexSource {
  ///IEnumerable<VertexData> Vertices();
  //Iterable <VertexData> vertices();

  void rewind([int pathId = 0]); // for a PathStorage this is the vertex index.

  //ShapePath.FlagsAndCommand vertex(out double x, out double y);
}
