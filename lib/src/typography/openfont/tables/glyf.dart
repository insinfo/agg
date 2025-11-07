// MIT, 2019-present, WinterDev
// Apache2, 2014-2016, Samuel Carlsson, WinterDev
// Ported to Dart by insinfo, 2025
// https://www.microsoft.com/typography/otspec/glyf.htm

import '../../io/byte_order_swapping_reader.dart';
import '../glyph.dart';
import 'loca.dart';
import 'table_entry.dart';
import 'utils.dart';

/// glyf — Glyph Data
/// 
/// This table contains information that describes the glyphs in the font.
class Glyf extends TableEntry {
  static const String tableName = 'glyf';

  List<Glyph>? _glyphs;
  final GlyphLocations _glyphLocations;

  /// Empty glyph used for glyphs with no outline
  final Glyph emptyGlyph = Glyph.empty(0);

  Glyf(this._glyphLocations);

  @override
  String get name => tableName;

  List<Glyph>? get glyphs => _glyphs;
  set glyphs(List<Glyph>? value) => _glyphs = value;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    final tableOffset = header!.offset;
    final locations = _glyphLocations;
    final glyphCount = locations.glyphCount;
    final tempGlyphs = List<Glyph?>.filled(glyphCount, null);

    final compositeGlyphs = <int>[];

    // First pass: Read simple glyphs
    for (var i = 0; i < glyphCount; i++) {
      reader.seek(tableOffset + locations.offsets[i]);
      final length = locations.offsets[i + 1] - locations.offsets[i];

      if (length > 0) {
        // Read glyph header
        final numberOfContours = reader.readInt16();
        
        if (numberOfContours >= 0) {
          // Simple glyph
          final bounds = Bounds.read(reader);
          tempGlyphs[i] = _readSimpleGlyph(reader, numberOfContours, bounds, i);
        } else {
          // Composite glyph - defer reading
          compositeGlyphs.add(i);
        }
      } else {
        // Empty glyph
        tempGlyphs[i] = Glyph.empty(i);
      }
    }

    // Second pass: Read composite glyphs
    for (final glyphIndex in compositeGlyphs) {
      tempGlyphs[glyphIndex] = _readCompositeGlyph(
        tempGlyphs,
        reader,
        tableOffset,
        glyphIndex,
      );
    }

    // Convert to non-nullable list
    _glyphs = tempGlyphs.cast<Glyph>();
  }

  /// Flags for simple glyph coordinates
  static const int _onCurve = 1;
  static const int _xByte = 1 << 1;
  static const int _yByte = 1 << 2;
  static const int _repeat = 1 << 3;
  static const int _xSignOrSame = 1 << 4;
  static const int _ySignOrSame = 1 << 5;

  static bool _hasFlag(int target, int test) => (target & test) == test;

  List<int> _readFlags(ByteOrderSwappingBinaryReader reader, int flagCount) {
    final result = List<int>.filled(flagCount, 0);
    var i = 0;
    var repeatCount = 0;
    var flag = 0;

    while (i < flagCount) {
      if (repeatCount > 0) {
        repeatCount--;
      } else {
        flag = reader.readByte();
        if (_hasFlag(flag, _repeat)) {
          repeatCount = reader.readByte();
        }
      }
      result[i++] = flag;
    }

    return result;
  }

  List<int> _readCoordinates(
    ByteOrderSwappingBinaryReader reader,
    int pointCount,
    List<int> flags,
    int isByte,
    int signOrSame,
  ) {
    final xs = List<int>.filled(pointCount, 0);
    var x = 0;

    for (var i = 0; i < pointCount; i++) {
      int dx;
      if (_hasFlag(flags[i], isByte)) {
        final b = reader.readByte();
        dx = _hasFlag(flags[i], signOrSame) ? b : -b;
      } else {
        if (_hasFlag(flags[i], signOrSame)) {
          dx = 0;
        } else {
          dx = reader.readInt16();
        }
      }
      x += dx;
      xs[i] = x;
    }

    return xs;
  }

  Glyph _readSimpleGlyph(
    ByteOrderSwappingBinaryReader reader,
    int contourCount,
    Bounds bounds,
    int index,
  ) {
    // Read end points of each contour
    final endPoints = Utils.readUInt16Array(reader, contourCount);

    // Read instructions
    final instructionLen = reader.readUInt16();
    final instructions = instructionLen > 0
        ? reader.readBytes(instructionLen)
        : <int>[];

    // Read flags and coordinates
    final pointCount = endPoints[contourCount - 1] + 1;
    final flags = _readFlags(reader, pointCount);
    final xs = _readCoordinates(reader, pointCount, flags, _xByte, _xSignOrSame);
    final ys = _readCoordinates(reader, pointCount, flags, _yByte, _ySignOrSame);

    // Create glyph points
    final glyphPoints = <GlyphPointF>[];
    for (var i = 0; i < xs.length; i++) {
      final onCurve = _hasFlag(flags[i], _onCurve);
      glyphPoints.add(GlyphPointF(xs[i].toDouble(), ys[i].toDouble(), onCurve));
    }

    return Glyph.fromTrueType(
      glyphPoints: glyphPoints,
      contourEndPoints: endPoints,
      bounds: bounds,
      glyphInstructions: instructions.isNotEmpty ? instructions : null,
      glyphIndex: index,
    );
  }

  /// Flags for composite glyphs
  static const int _arg1And2AreWords = 1;
  static const int _argsAreXyValues = 1 << 1;
  static const int _weHaveAScale = 1 << 3;
  static const int _moreComponents = 1 << 5;
  static const int _weHaveAnXAndYScale = 1 << 6;
  static const int _weHaveATwoByTwo = 1 << 7;
  static const int _weHaveInstructions = 1 << 8;

  Glyph _readCompositeGlyph(
    List<Glyph?> createdGlyphs,
    ByteOrderSwappingBinaryReader reader,
    int tableOffset,
    int compositeGlyphIndex,
  ) {
    // Move to composite glyph position
    reader.seek(tableOffset + _glyphLocations.offsets[compositeGlyphIndex]);

    // Read header
    reader.readInt16(); // numberOfContours (ignored, we know it's composite)
    Bounds.read(reader); // bounds (not used for composite)

    Glyph? finalGlyph;
    int flags;
    var isFirstComponent = true;

    do {
      flags = reader.readUInt16();
      final glyphIndex = reader.readUInt16();

      // Ensure referenced glyph is loaded
      if (createdGlyphs[glyphIndex] == null) {
        // This glyph is not read yet, resolve it first recursively
        final storedOffset = reader.position;
        final missingGlyph = _readCompositeGlyph(
          createdGlyphs,
          reader,
          tableOffset,
          glyphIndex,
        );
        createdGlyphs[glyphIndex] = missingGlyph;
        reader.seek(storedOffset);
      }

      final newGlyph = Glyph.clone(createdGlyphs[glyphIndex]!, compositeGlyphIndex);

      // Read arguments (offsets or point numbers)
      int arg1, arg2;
      if (_hasFlag(flags, _arg1And2AreWords)) {
        if (_hasFlag(flags, _argsAreXyValues)) {
          // Signed 16-bit values
          arg1 = reader.readInt16();
          arg2 = reader.readInt16();
        } else {
          // Unsigned 16-bit point numbers
          arg1 = reader.readUInt16();
          arg2 = reader.readUInt16();
        }
      } else {
        if (_hasFlag(flags, _argsAreXyValues)) {
          // Signed 8-bit values
          arg1 = reader.readByte().toSigned(8);
          arg2 = reader.readByte().toSigned(8);
        } else {
          // Unsigned 8-bit point numbers
          arg1 = reader.readByte();
          arg2 = reader.readByte();
        }
      }

      // Read transformation matrix if present
      var xscale = 1.0;
      var scale01 = 0.0;
      var scale10 = 0.0;
      var yscale = 1.0;
      var useMatrix = false;

      if (_hasFlag(flags, _weHaveAScale)) {
        xscale = yscale = Utils.readF2Dot14(reader);
      } else if (_hasFlag(flags, _weHaveAnXAndYScale)) {
        xscale = Utils.readF2Dot14(reader);
        yscale = Utils.readF2Dot14(reader);
      } else if (_hasFlag(flags, _weHaveATwoByTwo)) {
        useMatrix = true;
        xscale = Utils.readF2Dot14(reader);
        scale01 = Utils.readF2Dot14(reader);
        scale10 = Utils.readF2Dot14(reader);
        yscale = Utils.readF2Dot14(reader);
      }

      // Apply transformations
      if (_hasFlag(flags, _argsAreXyValues)) {
        // Arguments are offsets
        Glyph.offsetXY(newGlyph, arg1, arg2);
      } else {
        // Arguments are point numbers (not commonly used)
        // Would need to match point indices - not implemented
      }

      if (useMatrix) {
        Glyph.transformNormalWith2x2Matrix(
          newGlyph,
          xscale,
          scale01,
          scale10,
          yscale,
        );
      } else if (xscale != 1.0 || yscale != 1.0) {
        Glyph.transformNormalWith2x2Matrix(
          newGlyph,
          xscale,
          0,
          0,
          yscale,
        );
      }

      // Append to final glyph
      if (isFirstComponent) {
        finalGlyph = newGlyph;
        isFirstComponent = false;
      } else {
        Glyph.appendGlyph(finalGlyph!, newGlyph);
      }
    } while (_hasFlag(flags, _moreComponents));

    // Read instructions if present
    if (_hasFlag(flags, _weHaveInstructions)) {
      final instructionLength = reader.readUInt16();
      reader.readBytes(instructionLength); // Skip instructions for now
    }

    return finalGlyph;
  }

  @override
  String toString() {
    return 'Glyf(glyphCount: ${_glyphs?.length ?? 0})';
  }
}
