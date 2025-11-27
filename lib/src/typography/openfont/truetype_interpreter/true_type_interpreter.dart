import 'dart:math' as math;
import 'dart:typed_data';
import 'package:vector_math/vector_math.dart';

import '../glyph.dart';
import '../typeface.dart';
import '../tables/maxp.dart';
import 'opcodes.dart';
import 'execution_stack.dart';
import 'graphics_state.dart';
import 'zone.dart';
import 'instruction_stream.dart';
import 'exceptions.dart';

class TrueTypeInterpreter {
  Typeface? _currentTypeFace;
  SharpFontInterpreter? _interpreter;
  bool useVerticalHinting = false;

  Typeface? get typeface => _currentTypeFace;
  set typeface(Typeface? value) => setTypeFace(value);

  void setTypeFace(Typeface? typeface) {
    _currentTypeFace = typeface;
    if (typeface == null) {
      _interpreter = null;
      return;
    }

    MaxProfile? maximumProfile = typeface.maxProfile;
    if (maximumProfile == null) {
       return;
    }

    _interpreter = SharpFontInterpreter(
      maximumProfile.maxStackElements,
      maximumProfile.maxStorage,
      maximumProfile.maxFunctionDefs,
      maximumProfile.maxInstructionDefs,
      maximumProfile.maxTwilightPoints,
    );

    if (typeface.fpgmProgramBuffer != null) {
      _interpreter!.initializeFunctionDefs(typeface.fpgmProgramBuffer!);
    }
  }

  List<GlyphPointF> hintGlyph(
    int glyphIndex,
    double glyphSizeInPixel,
  ) {
    if (_currentTypeFace == null) return [];
    
    Glyph glyph = _currentTypeFace!.getGlyph(glyphIndex);
    int horizontalAdv = _currentTypeFace!.getHAdvanceWidthFromGlyphIndex(glyphIndex);
    int hFrontSideBearing = _currentTypeFace!.getHFrontSideBearingFromGlyphIndex(glyphIndex);

    return hintGlyphInternal(
      horizontalAdv,
      hFrontSideBearing,
      glyph.minX,
      glyph.maxY,
      glyph.glyphPoints ?? [],
      glyph.endPoints ?? [],
      glyph.glyphInstructions,
      glyphSizeInPixel,
    );
  }

  List<GlyphPointF> hintGlyphInternal(
    int horizontalAdv,
    int hFrontSideBearing,
    int minX,
    int maxY,
    List<GlyphPointF> glyphPoints,
    List<int> contourEndPoints,
    List<int>? instructions,
    double glyphSizeInPixel,
  ) {
    if (_interpreter == null || _currentTypeFace == null) {
      return glyphPoints;
    }

    // 1. Setup phantom points
    int verticalAdv = 0;
    int vFrontSideBearing = 0;
    
    var pp1 = GlyphPointF((minX - hFrontSideBearing).toDouble(), 0, true);
    var pp2 = GlyphPointF(pp1.x + horizontalAdv, 0, true);
    var pp3 = GlyphPointF(0, (maxY + vFrontSideBearing).toDouble(), true);
    var pp4 = GlyphPointF(0, pp3.y - verticalAdv, true);

    // 2. Clone points and add phantom points
    List<GlyphPointF> newGlyphPoints = List<GlyphPointF>.from(
      glyphPoints.map((p) => GlyphPointF(p.x, p.y, p.onCurve))
    );
    newGlyphPoints.add(pp1);
    newGlyphPoints.add(pp2);
    newGlyphPoints.add(pp3);
    newGlyphPoints.add(pp4);

    // 3. Scale all points
    double pxScale = _currentTypeFace!.calculateScaleToPixel(glyphSizeInPixel);
    for (var p in newGlyphPoints) {
      p.applyScale(pxScale);
    }

    // Vertical hinting hack from C#
    double aggXScale = 1000.0;
    if (useVerticalHinting) {
      applyScaleOnlyOnXAxis(newGlyphPoints, aggXScale);
    }

    // 4. Set CVT
    _interpreter!.setControlValueTable(
      _currentTypeFace!.controlValues,
      pxScale,
      glyphSizeInPixel,
      _currentTypeFace!.prepProgramBuffer,
    );

    // 5. Hint
    if (instructions != null && instructions.isNotEmpty) {
       Uint8List instrBytes = instructions is Uint8List 
          ? instructions 
          : Uint8List.fromList(instructions);
          
       _interpreter!.hintGlyph(newGlyphPoints, contourEndPoints, instrBytes);
    }

    // 6. Scale back
    if (useVerticalHinting) {
      applyScaleOnlyOnXAxis(newGlyphPoints, 1.0 / aggXScale);
    }

    return newGlyphPoints;
  }

  static void applyScaleOnlyOnXAxis(List<GlyphPointF> points, double scale) {
    for (var p in points) {
      p.applyScaleOnlyOnXAxis(scale);
    }
  }
}

class SharpFontInterpreter {
  GraphicsState _state = GraphicsState();
  GraphicsState _cvtState = GraphicsState();
  late ExecutionStack _stack;
  late List<InstructionStream?> _functions;
  late List<InstructionStream?> _instructionDefs;
  List<double>? _controlValueTable;
  late List<int> _storage;
  List<int>? _contours;
  double _scale = 0.0;
  int _ppem = 0;
  int _callStackSize = 0;
  double _fdotp = 0.0;
  double _roundThreshold = 0.0;
  double _roundPhase = 0.0;
  double _roundPeriod = 0.0;
  Zone? _zp0, _zp1, _zp2;
  Zone? _points, _twilight;
  
  static const double sqrt2Over2 = 0.7071067811865476;
  static const int maxCallStack = 128;
  static const double epsilon = 0.000001;

  SharpFontInterpreter(
      int maxStack,
      int maxStorage,
      int maxFunctions,
      int maxInstructionDefs,
      int maxTwilightPoints) {
    _stack = ExecutionStack(maxStack);
    _storage = List<int>.filled(maxStorage, 0);
    _functions = List<InstructionStream?>.filled(maxFunctions, null);
    _instructionDefs = List<InstructionStream?>.filled(maxInstructionDefs > 0 ? 256 : 0, null);
    _twilight = Zone(List<GlyphPointF>.generate(maxTwilightPoints, (i) => GlyphPointF(0, 0, false)), isTwilight: true);
  }

  void initializeFunctionDefs(Uint8List instructions) {
    execute(InstructionStream(instructions), false, true);
  }

  void setControlValueTable(Int16List? cvt, double scale, double ppem, Uint8List? cvProgram) {
    if (_scale == scale || cvt == null) return;

    if (_controlValueTable == null || _controlValueTable!.length != cvt.length) {
      _controlValueTable = List<double>.filled(cvt.length, 0.0);
    }
    
    // copy cvt and apply scale
    for (int i = cvt.length - 1; i >= 0; --i) {
      _controlValueTable![i] = cvt[i] * scale;
    }

    _scale = scale;
    _ppem = ppem.round();
    _zp0 = _zp1 = _zp2 = _points;
    _state.reset();
    _stack.clear();

    if (cvProgram != null) {
      execute(InstructionStream(cvProgram), false, false);

      if ((_state.instructionControl & InstructionControlFlags.useDefaultGraphicsState) != 0) {
        _cvtState.reset();
      } else {
        // Copy state
        // We need a deep copy or manual copy of fields
        _cvtState = GraphicsState()
          ..freedom = _state.freedom.clone()
          ..projection = _state.projection.clone()
          ..dualProjection = _state.dualProjection.clone()
          ..instructionControl = _state.instructionControl
          ..roundState = _state.roundState
          ..minDistance = _state.minDistance
          ..controlValueCutIn = _state.controlValueCutIn
          ..singleWidthCutIn = _state.singleWidthCutIn
          ..singleWidthValue = _state.singleWidthValue
          ..deltaBase = _state.deltaBase
          ..deltaShift = _state.deltaShift
          ..loop = _state.loop
          ..rp0 = _state.rp0
          ..rp1 = _state.rp1
          ..rp2 = _state.rp2
          ..autoFlip = _state.autoFlip;
          
        _cvtState.freedom = Vector2(1.0, 0.0);
        _cvtState.projection = Vector2(1.0, 0.0);
        _cvtState.dualProjection = Vector2(1.0, 0.0);
        _cvtState.roundState = RoundMode.toGrid;
        _cvtState.loop = 1;
      }
    }
  }

  void hintGlyph(List<GlyphPointF> glyphPoints, List<int> contours, Uint8List instructions) {
    if (instructions.isEmpty) return;

    if ((_state.instructionControl & InstructionControlFlags.inhibitGridFitting) != 0) {
      return;
    }

    _contours = contours;
    _points = Zone(glyphPoints, isTwilight: false);
    _zp0 = _zp1 = _zp2 = _points;

    // Restore state
    _state = GraphicsState()
          ..freedom = _cvtState.freedom.clone()
          ..projection = _cvtState.projection.clone()
          ..dualProjection = _cvtState.dualProjection.clone()
          ..instructionControl = _cvtState.instructionControl
          ..roundState = _cvtState.roundState
          ..minDistance = _cvtState.minDistance
          ..controlValueCutIn = _cvtState.controlValueCutIn
          ..singleWidthCutIn = _cvtState.singleWidthCutIn
          ..singleWidthValue = _cvtState.singleWidthValue
          ..deltaBase = _cvtState.deltaBase
          ..deltaShift = _cvtState.deltaShift
          ..loop = _cvtState.loop
          ..rp0 = _cvtState.rp0
          ..rp1 = _cvtState.rp1
          ..rp2 = _cvtState.rp2
          ..autoFlip = _cvtState.autoFlip;

    _callStackSize = 0;
    _stack.clear();
    onVectorsUpdated();

    switch (_state.roundState) {
      case RoundMode.superRound:
        setSuperRound(1.0);
        break;
      case RoundMode.super45:
        setSuperRound(sqrt2Over2);
        break;
      default:
        break;
    }

    try {
      execute(InstructionStream(instructions), false, false);
    } on InvalidTrueTypeFontException catch (e) {
      print('TrueType Hinting Error: $e');
    }
  }

  void execute(InstructionStream stream, bool inFunction, bool allowFunctionDefs) {
    while (!stream.done) {
      var opcode = stream.nextOpCode();
      switch (opcode) {
        // ==== PUSH INSTRUCTIONS ====
        case OpCode.NPUSHB:
        case OpCode.PUSHB1:
        case OpCode.PUSHB2:
        case OpCode.PUSHB3:
        case OpCode.PUSHB4:
        case OpCode.PUSHB5:
        case OpCode.PUSHB6:
        case OpCode.PUSHB7:
        case OpCode.PUSHB8:
          var count = opcode == OpCode.NPUSHB 
              ? stream.nextByte() 
              : opcode.index - OpCode.PUSHB1.index + 1;
          for (int i = 0; i < count; i++) {
            _stack.push(stream.nextByte());
          }
          break;
        case OpCode.NPUSHW:
        case OpCode.PUSHW1:
        case OpCode.PUSHW2:
        case OpCode.PUSHW3:
        case OpCode.PUSHW4:
        case OpCode.PUSHW5:
        case OpCode.PUSHW6:
        case OpCode.PUSHW7:
        case OpCode.PUSHW8:
          var count = opcode == OpCode.NPUSHW 
              ? stream.nextByte() 
              : opcode.index - OpCode.PUSHW1.index + 1;
          for (int i = 0; i < count; i++) {
            _stack.push(stream.nextWord());
          }
          break;

        // ==== STORAGE MANAGEMENT ====
        case OpCode.RS:
          int addr = _stack.pop();
          if (addr < 0 || addr >= _storage.length) {
             throw InvalidTrueTypeFontException('Storage address out of bounds');
          }
          _stack.push(_storage[addr]);
          break;
        case OpCode.WS:
          int val = _stack.pop();
          int addr2 = _stack.pop();
          if (addr2 < 0 || addr2 >= _storage.length) {
             throw InvalidTrueTypeFontException('Storage address out of bounds');
          }
          _storage[addr2] = val;
          break;

        // ==== CONTROL VALUE TABLE ====
        case OpCode.WCVTP:
          int val2 = _stack.pop();
          int loc = _stack.pop();
          if (_controlValueTable != null && loc >= 0 && loc < _controlValueTable!.length) {
             _controlValueTable![loc] = ExecutionStack.f26Dot6ToFloat(val2);
          }
          break;
        case OpCode.WCVTF:
          int val3 = _stack.pop();
          int loc2 = _stack.pop();
           if (_controlValueTable != null && loc2 >= 0 && loc2 < _controlValueTable!.length) {
             _controlValueTable![loc2] = val3 * _scale;
          }
          break;
        case OpCode.RCVT:
          int loc3 = _stack.pop();
          if (_controlValueTable != null && loc3 >= 0 && loc3 < _controlValueTable!.length) {
             _stack.pushFloat(_controlValueTable![loc3]);
          } else {
             _stack.push(0);
          }
          break;

        // ==== STATE VECTORS ====
        case OpCode.SVTCA0:
        case OpCode.SVTCA1:
          if (opcode == OpCode.SVTCA0) {
             _state.freedom = Vector2(0.0, 1.0); // Y-axis
             _state.projection = Vector2(0.0, 1.0);
          } else {
             _state.freedom = Vector2(1.0, 0.0); // X-axis
             _state.projection = Vector2(1.0, 0.0);
          }
          _state.dualProjection = _state.projection.clone();
          onVectorsUpdated();
          break;
        case OpCode.SPVTCA0:
        case OpCode.SPVTCA1:
          if (opcode == OpCode.SPVTCA0) {
             _state.projection = Vector2(0.0, 1.0);
          } else {
             _state.projection = Vector2(1.0, 0.0);
          }
          _state.dualProjection = _state.projection.clone();
          onVectorsUpdated();
          break;
        case OpCode.SFVTCA0:
        case OpCode.SFVTCA1:
          if (opcode == OpCode.SFVTCA0) {
             _state.freedom = Vector2(0.0, 1.0);
          } else {
             _state.freedom = Vector2(1.0, 0.0);
          }
          onVectorsUpdated();
          break;
        case OpCode.SPVTL0:
        case OpCode.SPVTL1:
        case OpCode.SFVTL0:
        case OpCode.SFVTL1:
          setVectorsToLine(opcode.index, false);
          break;
        case OpCode.SPVFS:
        case OpCode.SFVFS:
          int y = _stack.pop();
          int x = _stack.pop();
          var vec = Vector2(f2Dot14ToFloat(x), f2Dot14ToFloat(y));
          vec.normalize();
          if (opcode == OpCode.SPVFS) {
             _state.projection = vec;
             _state.dualProjection = vec.clone();
          } else {
             _state.freedom = vec;
          }
          onVectorsUpdated();
          break;
        case OpCode.GPV:
        case OpCode.GFV:
          var vec2 = opcode == OpCode.GPV ? _state.projection : _state.freedom;
          _stack.push(floatToF2Dot14(vec2.x));
          _stack.push(floatToF2Dot14(vec2.y));
          break;
        case OpCode.SFVTPV:
          _state.freedom = _state.projection.clone();
          onVectorsUpdated();
          break;
        case OpCode.ISECT:
          var b1 = _zp0!.getCurrent(_stack.pop());
          var b0 = _zp0!.getCurrent(_stack.pop());
          var a1 = _zp1!.getCurrent(_stack.pop());
          var a0 = _zp1!.getCurrent(_stack.pop());
          var index = _stack.pop();

          var da = a0 - a1;
          var db = b0 - b1;
          var den = (da.x * db.y) - (da.y * db.x);
          if (den.abs() <= epsilon) {
            _zp2!.current[index].updateX((a0.x + a1.x + b0.x + b1.x) / 4);
            _zp2!.current[index].updateY((a0.y + a1.y + b0.y + b1.y) / 4);
          } else {
            var t = (a0.x * a1.y) - (a0.y * a1.x);
            var u = (b0.x * b1.y) - (b0.y * b1.x);
            var px = (t * db.x) - (da.x * u);
            var py = (t * db.y) - (da.y * u);
            _zp2!.current[index].updateX(px / den);
            _zp2!.current[index].updateY(py / den);
          }
          _zp2!.touchState[index] = TouchState.both;
          break;

        // ==== GRAPHICS STATE ====
        case OpCode.SRP0: _state.rp0 = _stack.pop(); break;
        case OpCode.SRP1: _state.rp1 = _stack.pop(); break;
        case OpCode.SRP2: _state.rp2 = _stack.pop(); break;
        case OpCode.SZP0: _zp0 = getZoneFromStack(); break;
        case OpCode.SZP1: _zp1 = getZoneFromStack(); break;
        case OpCode.SZP2: _zp2 = getZoneFromStack(); break;
        case OpCode.SZPS: _zp0 = _zp1 = _zp2 = getZoneFromStack(); break;
        case OpCode.SLOOP: _state.loop = _stack.pop(); break;
        case OpCode.RTG: _state.roundState = RoundMode.toGrid; break;
        case OpCode.RTHG: _state.roundState = RoundMode.toHalfGrid; break;
        case OpCode.SMD: _state.minDistance = _stack.popFloat(); break;
        case OpCode.SCVTCI: _state.controlValueCutIn = _stack.popFloat(); break;
        case OpCode.SSWCI: _state.singleWidthCutIn = _stack.popFloat(); break;
        case OpCode.SSW: _state.singleWidthValue = readCvt(); break;
        case OpCode.FLIPON: _state.autoFlip = true; break;
        case OpCode.FLIPOFF: _state.autoFlip = false; break;
        case OpCode.SDB: _state.deltaBase = _stack.pop(); break;
        case OpCode.SDS: _state.deltaShift = _stack.pop(); break;
        case OpCode.MD0:
        case OpCode.MD1:
          var p1 = _zp1!.getOriginal(_stack.pop());
          var p2 = _zp0!.getOriginal(_stack.pop());
          var dist = dualProject(p2 - p1);
          if (opcode == OpCode.MD1) dist = round(dist);
          _stack.pushFloat(dist);
          break;
        case OpCode.MPPEM: _stack.push(_ppem); break;
        case OpCode.MPS: _stack.pushFloat(12.0); break; // TODO: Implement MPS properly

        // ==== MOVEMENT ====
        case OpCode.MIAP0:
        case OpCode.MIAP1:
          var distance = readCvt();
          var pointIndex = _stack.pop();

          if (_zp0!.isTwilight) {
            var original = _state.freedom * distance;
            _zp0!.original[pointIndex].updateX(original.x);
            _zp0!.original[pointIndex].updateY(original.y);
            _zp0!.current[pointIndex].updateX(original.x);
            _zp0!.current[pointIndex].updateY(original.y);
          }

          var point = _zp0!.getCurrent(pointIndex);
          var currentPos = project(point);
          if (opcode == OpCode.MIAP1) {
            if ((distance - currentPos).abs() > _state.controlValueCutIn) {
              distance = currentPos;
            }
            distance = round(distance);
          }

          movePoint(_zp0!, pointIndex, distance - currentPos);
          _state.rp0 = pointIndex;
          _state.rp1 = pointIndex;
          break;
        case OpCode.MDAP0:
        case OpCode.MDAP1:
          var pointIndex = _stack.pop();
          var point = _zp0!.getCurrent(pointIndex);
          var distance = 0.0;
          if (opcode == OpCode.MDAP1) {
            distance = project(point);
            distance = round(distance) - distance;
          }
          movePoint(_zp0!, pointIndex, distance);
          _state.rp0 = pointIndex;
          _state.rp1 = pointIndex;
          break;
        case OpCode.MSIRP0:
        case OpCode.MSIRP1:
          var targetDistance = _stack.popFloat();
          var pointIndex = _stack.pop();

          if (_zp1!.isTwilight) {
            var p = _zp0!.getOriginal(_state.rp0) + _state.freedom * (targetDistance / _fdotp);
            _zp1!.original[pointIndex].updateX(p.x);
            _zp1!.original[pointIndex].updateY(p.y);
            _zp1!.current[pointIndex].updateX(p.x);
            _zp1!.current[pointIndex].updateY(p.y);
          }

          var currentDistance = project(_zp1!.getCurrent(pointIndex) - _zp0!.getCurrent(_state.rp0));
          movePoint(_zp1!, pointIndex, targetDistance - currentDistance);

          _state.rp1 = _state.rp0;
          _state.rp2 = pointIndex;
          if (opcode == OpCode.MSIRP1) _state.rp0 = pointIndex;
          break;
        case OpCode.IP:
          var originalBase = _zp0!.getOriginal(_state.rp1);
          var currentBase = _zp0!.getCurrent(_state.rp1);
          var originalRange = dualProject(_zp1!.getOriginal(_state.rp2) - originalBase);
          var currentRange = project(_zp1!.getCurrent(_state.rp2) - currentBase);

          for (int i = 0; i < _state.loop; i++) {
            var pointIndex = _stack.pop();
            var point = _zp2!.getCurrent(pointIndex);
            var currentDistance = project(point - currentBase);
            var originalDistance = dualProject(_zp2!.getOriginal(pointIndex) - originalBase);

            var newDistance = 0.0;
            if (originalDistance != 0.0) {
              if (originalRange == 0.0) {
                newDistance = originalDistance;
              } else {
                newDistance = originalDistance * currentRange / originalRange;
              }
            }
            movePoint(_zp2!, pointIndex, newDistance - currentDistance);
          }
          _state.loop = 1;
          break;
        case OpCode.ALIGNRP:
          for (int i = 0; i < _state.loop; i++) {
            var pointIndex = _stack.pop();
            var p1 = _zp1!.getCurrent(pointIndex);
            var p2 = _zp0!.getCurrent(_state.rp0);
            movePoint(_zp1!, pointIndex, -project(p1 - p2));
          }
          _state.loop = 1;
          break;
        case OpCode.ALIGNPTS:
          var p1 = _stack.pop();
          var p2 = _stack.pop();
          var distance = project(_zp0!.getCurrent(p2) - _zp1!.getCurrent(p1)) / 2;
          movePoint(_zp1!, p1, distance);
          movePoint(_zp0!, p2, -distance);
          break;
        case OpCode.UTP:
          _zp0!.touchState[_stack.pop()] &= ~getTouchState();
          break;
        case OpCode.IUP0:
        case OpCode.IUP1:
          if (_contours == null || _contours!.isEmpty) break;
          
          int firstPoint = 0;
          for (int i = 0; i < _contours!.length; i++) {
            int endPoint = _contours![i];
            
            // Find first touched point
            int start = -1;
            int mask = opcode == OpCode.IUP0 ? TouchState.y : TouchState.x;
            
            for (int j = firstPoint; j <= endPoint; j++) {
                if ((_zp2!.touchState[j] & mask) != 0) {
                    start = j;
                    break;
                }
            }

            if (start != -1) {
                int p1 = start;
                int p2 = start;
                do {
                    p2 = p1 + 1;
                    if (p2 > endPoint) p2 = firstPoint;
                    while ((_zp2!.touchState[p2] & mask) == 0) {
                        p2++;
                        if (p2 > endPoint) p2 = firstPoint;
                        if (p2 == start) break;
                    }
                    
                    _interpolateIUP(p1, p2, firstPoint, endPoint, opcode == OpCode.IUP1);
                    
                    p1 = p2;
                } while (p1 != start);
            }
            
            firstPoint = endPoint + 1;
          }
          break;

        // ==== SHIFTING ====
        case OpCode.SHP0:
        case OpCode.SHP1:
          var dispInfo = _computeDisplacement(opcode.index);
          shiftPoints(dispInfo.displacement);
          break;
        case OpCode.SHPIX:
          shiftPoints(_stack.popFloat());
          break;
        case OpCode.SHC0:
        case OpCode.SHC1:
          var dispInfo = _computeDisplacement(opcode.index);
          var touch = getTouchState();
          var contour = _stack.pop();
          var start = contour == 0 ? 0 : _contours![contour - 1] + 1;
          var count = _zp2!.isTwilight ? _zp2!.current.length : _contours![contour] + 1;
          
          var dispVec = dispInfo.displacement;

          for (int i = start; i < count; i++) {
            if (dispInfo.zone.current != _zp2!.current || dispInfo.pointIndex != i) {
               var p = _zp2!.current[i];
               p.updateX(p.x + dispVec.x);
               p.updateY(p.y + dispVec.y);
               _zp2!.touchState[i] |= touch;
            }
          }
          break;
        case OpCode.SHZ0:
        case OpCode.SHZ1:
          var dispInfo = _computeDisplacement(opcode.index);
          var count = 0;
          if (_zp2!.isTwilight) {
            count = _zp2!.current.length;
          } else if (_contours != null && _contours!.isNotEmpty) {
            count = _contours!.last + 1;
          }
          
          var dispVec = dispInfo.displacement;

          for (int i = 0; i < count; i++) {
            if (dispInfo.zone.current != _zp2!.current || dispInfo.pointIndex != i) {
               var p = _zp2!.current[i];
               p.updateX(p.x + dispVec.x);
               p.updateY(p.y + dispVec.y);
            }
          }
          break;

        // ==== FLOW CONTROL ====
        case OpCode.IF:
          if (!_stack.popBool()) {
            int indent = 1;
            while (indent > 0) {
              opcode = skipNext(stream);
              switch (opcode) {
                case OpCode.IF: indent++; break;
                case OpCode.EIF: indent--; break;
                case OpCode.ELSE:
                  if (indent == 1) indent = 0;
                  break;
                default: break;
              }
            }
          }
          break;
        case OpCode.ELSE:
          int indent = 1;
          while (indent > 0) {
            opcode = skipNext(stream);
            switch (opcode) {
              case OpCode.IF: indent++; break;
              case OpCode.EIF: indent--; break;
              default: break;
            }
          }
          break;
        case OpCode.EIF: break;
        case OpCode.JROT:
        case OpCode.JROF:
          if (_stack.popBool() == (opcode == OpCode.JROT)) {
            stream.jump(_stack.pop() - 1);
          } else {
            _stack.pop();
          }
          break;
        case OpCode.JMPR:
          stream.jump(_stack.pop() - 1);
          break;

        // ==== FUNCTIONS ====
        case OpCode.FDEF:
          if (!allowFunctionDefs || inFunction) {
            throw InvalidTrueTypeFontException("Can't define functions here.");
          }
          _functions[_stack.pop()] = stream;
          while (skipNext(stream) != OpCode.ENDF) {}
          break;
        case OpCode.IDEF:
          if (!allowFunctionDefs || inFunction) {
            throw InvalidTrueTypeFontException("Can't define functions here.");
          }
          _instructionDefs[_stack.pop()] = stream;
          while (skipNext(stream) != OpCode.ENDF) {}
          break;
        case OpCode.ENDF:
          if (!inFunction) {
            throw InvalidTrueTypeFontException("Found invalid ENDF marker outside of a function definition.");
          }
          return;
        case OpCode.CALL:
        case OpCode.LOOPCALL:
          _callStackSize++;
          if (_callStackSize > maxCallStack) {
            throw InvalidTrueTypeFontException("Stack overflow; infinite recursion?");
          }
          var function = _functions[_stack.pop()];
          var count = opcode == OpCode.LOOPCALL ? _stack.pop() : 1;
          for (int i = 0; i < count; i++) {
            if (function != null) {
               // Clone stream to execute function? 
               // InstructionStream is struct in C#, so it's passed by value (copy).
               // In Dart it's a class, so we need to clone it or create new one with same state.
               // But wait, FDEF stores the stream at the point of definition.
               // We need to execute it from there.
               // The stored stream has 'ip' at the start of function body.
               // We should probably clone the stored stream to avoid modifying the stored 'ip'.
               var funcStream = InstructionStream(function.instructions)..ip = function.ip;
               execute(funcStream, true, false);
            }
          }
          _callStackSize--;
          break;

        // ==== ROUNDING ====
        case OpCode.ROUND0:
        case OpCode.ROUND1:
        case OpCode.ROUND2:
        case OpCode.ROUND3:
          _stack.pushFloat(round(_stack.popFloat()));
          break;
        case OpCode.NROUND0:
        case OpCode.NROUND1:
        case OpCode.NROUND2:
        case OpCode.NROUND3:
          break;
        case OpCode.RTDG: _state.roundState = RoundMode.toDoubleGrid; break;
        case OpCode.RUTG: _state.roundState = RoundMode.upToGrid; break;
        case OpCode.RDTG: _state.roundState = RoundMode.downToGrid; break;
        case OpCode.ROFF: _state.roundState = RoundMode.off; break;
        case OpCode.SROUND: setSuperRound(1.0); break;
        case OpCode.S45ROUND: setSuperRound(sqrt2Over2); break;

        // ==== DELTA ====
        case OpCode.DELTAC1:
        case OpCode.DELTAC2:
        case OpCode.DELTAC3:
          var last = _stack.pop();
          for (int i = 1; i <= last; i++) {
            var cvtIndex = _stack.pop();
            var arg = _stack.pop();
            var triggerPpem = (arg >> 4) & 0xF;
            triggerPpem += (opcode.index - OpCode.DELTAC1.index) * 16;
            triggerPpem += _state.deltaBase;

            if (_ppem == triggerPpem) {
              var amount = (arg & 0xF) - 8;
              if (amount >= 0) amount++;
              amount *= 1 << (6 - _state.deltaShift);
              checkIndex(cvtIndex, _controlValueTable!.length);
              _controlValueTable![cvtIndex] += ExecutionStack.f26Dot6ToFloat(amount);
            }
          }
          break;
        case OpCode.DELTAP1:
        case OpCode.DELTAP2:
        case OpCode.DELTAP3:
          var last = _stack.pop();
          for (int i = 1; i <= last; i++) {
            var pointIndex = _stack.pop();
            var arg = _stack.pop();
            var triggerPpem = (arg >> 4) & 0xF;
            triggerPpem += _state.deltaBase;
            if (opcode != OpCode.DELTAP1) {
              triggerPpem += (opcode.index - OpCode.DELTAP2.index + 1) * 16;
            }

            if (_ppem == triggerPpem) {
              var amount = (arg & 0xF) - 8;
              if (amount >= 0) amount++;
              amount *= 1 << (6 - _state.deltaShift);
              movePoint(_zp0!, pointIndex, ExecutionStack.f26Dot6ToFloat(amount));
            }
          }
          break;

        // ==== LOGICAL ====
        case OpCode.LT:
          var b = _stack.pop();
          var a = _stack.pop();
          _stack.pushBool(a < b);
          break;
        case OpCode.LTEQ:
          var b = _stack.pop();
          var a = _stack.pop();
          _stack.pushBool(a <= b);
          break;
        case OpCode.GT:
          var b = _stack.pop();
          var a = _stack.pop();
          _stack.pushBool(a > b);
          break;
        case OpCode.GTEQ:
          var b = _stack.pop();
          var a = _stack.pop();
          _stack.pushBool(a >= b);
          break;
        case OpCode.EQ:
          var b = _stack.pop();
          var a = _stack.pop();
          _stack.pushBool(a == b);
          break;
        case OpCode.NEQ:
          var b = _stack.pop();
          var a = _stack.pop();
          _stack.pushBool(a != b);
          break;
        case OpCode.AND:
          var b = _stack.popBool();
          var a = _stack.popBool();
          _stack.pushBool(a && b);
          break;
        case OpCode.OR:
          var b = _stack.popBool();
          var a = _stack.popBool();
          _stack.pushBool(a || b);
          break;
        case OpCode.NOT:
          _stack.pushBool(!_stack.popBool());
          break;
        case OpCode.ODD:
          var value = round(_stack.popFloat()).toInt();
          _stack.pushBool(value % 2 != 0);
          break;
        case OpCode.EVEN:
          var value = round(_stack.popFloat()).toInt();
          _stack.pushBool(value % 2 == 0);
          break;

        // ==== ARITHMETIC ====
        case OpCode.ADD:
          var b = _stack.pop();
          var a = _stack.pop();
          _stack.push(a + b);
          break;
        case OpCode.SUB:
          var b = _stack.pop();
          var a = _stack.pop();
          _stack.push(a - b);
          break;
        case OpCode.DIV:
          var b = _stack.pop();
          if (b == 0) throw InvalidTrueTypeFontException("Division by zero.");
          var a = _stack.pop();
          var result = (a * 64) ~/ b; // (long)a << 6 / b
          _stack.push(result);
          break;
        case OpCode.MUL:
          var b = _stack.pop();
          var a = _stack.pop();
          var result = (a * b) >> 6;
          _stack.push(result);
          break;
        case OpCode.ABS: _stack.push(_stack.pop().abs()); break;
        case OpCode.NEG: _stack.push(-_stack.pop()); break;
        case OpCode.FLOOR: _stack.push(_stack.pop() & ~63); break;
        case OpCode.CEILING: _stack.push((_stack.pop() + 63) & ~63); break;
        case OpCode.MAX: _stack.push(math.max(_stack.pop(), _stack.pop())); break;
        case OpCode.MIN: _stack.push(math.min(_stack.pop(), _stack.pop())); break;

        // ==== MISC ====
        case OpCode.DEBUG: _stack.pop(); break;
        case OpCode.GETINFO:
          var selector = _stack.pop();
          var result = 0;
          if ((selector & 0x1) != 0) result = 35; // MS Rasterizer v35
          if ((selector & 0x20) != 0) result |= 1 << 12; // Grayscale
          _stack.push(result);
          break;

        default:
          if (opcode.index >= OpCode.MIRP.index) {
            moveIndirectRelative(opcode.index - OpCode.MIRP.index);
          } else if (opcode.index >= OpCode.MDRP.index) {
            moveDirectRelative(opcode.index - OpCode.MDRP.index);
          } else {
             // Check runtime defined opcodes
             // Not implemented fully yet
          }
          break;
      }
    }
  }
  
  void onVectorsUpdated() {
      if (_state.freedom.dot(_state.projection) < epsilon) {
          _state.freedom = _state.projection.clone();
      }
      _fdotp = _state.freedom.dot(_state.projection);
      if (_fdotp.abs() < epsilon) _fdotp = 1.0;
  }
  
  void setSuperRound(double period) {
      var mode = _stack.pop();
      switch (mode & 0xC0) {
        case 0: _roundPeriod = period / 2; break;
        case 0x40: _roundPeriod = period; break;
        case 0x80: _roundPeriod = period * 2; break;
        default: throw InvalidTrueTypeFontException("Unknown rounding period multiplier.");
      }

      switch (mode & 0x30) {
        case 0: _roundPhase = 0; break;
        case 0x10: _roundPhase = _roundPeriod / 4; break;
        case 0x20: _roundPhase = _roundPeriod / 2; break;
        case 0x30: _roundPhase = _roundPeriod * 3 / 4; break;
      }

      if ((mode & 0xF) == 0) {
        _roundThreshold = _roundPeriod - 1;
      } else {
        _roundThreshold = ((mode & 0xF) - 4) * _roundPeriod / 8;
      }
  }

  void setVectorsToLine(int mode, bool dual) {
      // mode: 0: SPVTL0, 1: SPVTL1, 2: SFVTL0, 3: SFVTL1
      // Map opcode index to 0-3?
      // OpCode.SPVTL0 is base.
      // But wait, the caller passes opcode.index.
      // I should pass 0, 1, 2, 3 based on opcode.
      // SPVTL0, SPVTL1, SFVTL0, SFVTL1 are contiguous in my enum?
      // Let's check opcodes.dart.
      // SPVTL0, SPVTL1, SFVTL0, SFVTL1. Yes.
      
      int internalMode = 0;
      if (mode == OpCode.SPVTL0.index) internalMode = 0;
      else if (mode == OpCode.SPVTL1.index) internalMode = 1;
      else if (mode == OpCode.SFVTL0.index) internalMode = 2;
      else if (mode == OpCode.SFVTL1.index) internalMode = 3;

      int index1 = _stack.pop();
      int index2 = _stack.pop();
      var p1 = _zp2!.getCurrent(index1);
      var p2 = _zp1!.getCurrent(index2);

      var line = p2 - p1;
      if (line.length2 == 0) {
        if (internalMode >= 2) {
          _state.freedom = Vector2(1.0, 0.0);
        } else {
          _state.projection = Vector2(1.0, 0.0);
          _state.dualProjection = Vector2(1.0, 0.0);
        }
      } else {
        if ((internalMode & 0x1) != 0) {
          line = Vector2(-line.y, line.x);
        }
        line.normalize();

        if (internalMode >= 2) {
          _state.freedom = line;
        } else {
          _state.projection = line;
          _state.dualProjection = line;
        }
      }

      if (dual) {
        p1 = _zp2!.getOriginal(index1);
        p2 = _zp2!.getOriginal(index2);
        line = p2 - p1;

        if (line.length2 == 0) {
          _state.dualProjection = Vector2(1.0, 0.0);
        } else {
          if ((internalMode & 0x1) != 0) {
            line = Vector2(-line.y, line.x);
          }
          line.normalize();
          _state.dualProjection = line;
        }
      }
      onVectorsUpdated();
  }

  static double f2Dot14ToFloat(int value) {
    int shortVal = value;
    if (shortVal >= 0x8000) shortVal -= 0x10000;
    return shortVal / 16384.0;
  }

  static int floatToF2Dot14(double value) {
    return (value * 16384.0).round();
  }

  Zone getZoneFromStack() {
    switch (_stack.pop()) {
      case 0: return _twilight!;
      case 1: return _points!;
      default: throw InvalidTrueTypeFontException('Invalid zone pointer.');
    }
  }

  OpCode skipNext(InstructionStream stream) {
    var opcode = stream.nextOpCode();
    switch (opcode) {
      case OpCode.NPUSHB:
      case OpCode.PUSHB1:
      case OpCode.PUSHB2:
      case OpCode.PUSHB3:
      case OpCode.PUSHB4:
      case OpCode.PUSHB5:
      case OpCode.PUSHB6:
      case OpCode.PUSHB7:
      case OpCode.PUSHB8:
        var count = opcode == OpCode.NPUSHB 
            ? stream.nextByte() 
            : opcode.index - OpCode.PUSHB1.index + 1;
        for (int i = 0; i < count; i++) stream.nextByte();
        break;
      case OpCode.NPUSHW:
      case OpCode.PUSHW1:
      case OpCode.PUSHW2:
      case OpCode.PUSHW3:
      case OpCode.PUSHW4:
      case OpCode.PUSHW5:
      case OpCode.PUSHW6:
      case OpCode.PUSHW7:
      case OpCode.PUSHW8:
        var count = opcode == OpCode.NPUSHW 
            ? stream.nextByte() 
            : opcode.index - OpCode.PUSHW1.index + 1;
        for (int i = 0; i < count; i++) stream.nextWord();
        break;
      default:
        break;
    }
    return opcode;
  }

  void moveIndirectRelative(int flags) {
    var cvt = readCvt();
    var pointIndex = _stack.pop();

    if ((cvt - _state.singleWidthValue).abs() < _state.singleWidthCutIn) {
      if (cvt >= 0) {
        cvt = _state.singleWidthValue;
      } else {
        cvt = -_state.singleWidthValue;
      }
    }

    var originalReference = _zp0!.getOriginal(_state.rp0);
    if (_zp1!.isTwilight) {
      var initialValue = originalReference + _state.freedom * cvt;
      _zp1!.original[pointIndex].updateX(initialValue.x);
      _zp1!.original[pointIndex].updateY(initialValue.y);
      _zp1!.current[pointIndex].updateX(initialValue.x);
      _zp1!.current[pointIndex].updateY(initialValue.y);
    }

    var point = _zp1!.getCurrent(pointIndex);
    var originalDistance = dualProject(_zp1!.getOriginal(pointIndex) - originalReference);
    var currentDistance = project(point - _zp0!.getCurrent(_state.rp0));

    if (_state.autoFlip && originalDistance.sign != cvt.sign) {
      cvt = -cvt;
    }

    var distance = cvt;
    if ((flags & 0x4) != 0) {
      if (_zp0!.isTwilight == _zp1!.isTwilight && (cvt - originalDistance).abs() > _state.controlValueCutIn) {
        cvt = originalDistance;
      }
      distance = round(cvt);
    }

    if ((flags & 0x8) != 0) {
      if (originalDistance >= 0) {
        distance = math.max(distance, _state.minDistance);
      } else {
        distance = math.min(distance, -_state.minDistance);
      }
    }

    movePoint(_zp1!, pointIndex, distance - currentDistance);
    _state.rp1 = _state.rp0;
    _state.rp2 = pointIndex;
    if ((flags & 0x10) != 0) {
      _state.rp0 = pointIndex;
    }
  }

  void moveDirectRelative(int flags) {
    var pointIndex = _stack.pop();
    var p1 = _zp0!.getOriginal(_state.rp0);
    var p2 = _zp1!.getOriginal(pointIndex);
    var originalDistance = dualProject(p2 - p1);

    if ((originalDistance - _state.singleWidthValue).abs() < _state.singleWidthCutIn) {
      if (originalDistance >= 0) {
        originalDistance = _state.singleWidthValue;
      } else {
        originalDistance = -_state.singleWidthValue;
      }
    }

    var distance = originalDistance;
    if ((flags & 0x4) != 0) {
      distance = round(distance);
    }

    if ((flags & 0x8) != 0) {
      if (originalDistance >= 0) {
        distance = math.max(distance, _state.minDistance);
      } else {
        distance = math.min(distance, -_state.minDistance);
      }
    }

    var currentDistance = project(_zp1!.getCurrent(pointIndex) - _zp0!.getCurrent(_state.rp0));
    movePoint(_zp1!, pointIndex, distance - currentDistance);
    _state.rp1 = _state.rp0;
    _state.rp2 = pointIndex;
    if ((flags & 0x10) != 0) {
      _state.rp0 = pointIndex;
    }
  }

  void interpolatePointsXAxis(List<GlyphPointF> current, List<GlyphPointF> original, int start, int end, int ref1, int ref2) {
    if (start > end) return;

    double delta1, delta2;
    double lower = original[ref1].x;
    double upper = original[ref2].x;

    if (lower > upper) {
      double temp = lower;
      lower = upper;
      upper = temp;

      delta1 = current[ref2].x - lower;
      delta2 = current[ref1].x - upper;
    } else {
      delta1 = current[ref1].x - lower;
      delta2 = current[ref2].x - upper;
    }

    double lowerCurrent = delta1 + lower;
    double upperCurrent = delta2 + upper;
    double scale = (upperCurrent - lowerCurrent) / (upper - lower);

    for (int i = start; i <= end; i++) {
      double pos = original[i].x;
      if (pos <= lower) {
        pos += delta1;
      } else if (pos >= upper) {
        pos += delta2;
      } else {
        pos = lowerCurrent + (pos - lower) * scale;
      }
      current[i].updateX(pos);
    }
  }

  void interpolatePointsYAxis(List<GlyphPointF> current, List<GlyphPointF> original, int start, int end, int ref1, int ref2) {
    if (start > end) return;

    double delta1, delta2;
    double lower = original[ref1].y;
    double upper = original[ref2].y;

    if (lower > upper) {
      double temp = lower;
      lower = upper;
      upper = temp;

      delta1 = current[ref2].y - lower;
      delta2 = current[ref1].y - upper;
    } else {
      delta1 = current[ref1].y - lower;
      delta2 = current[ref2].y - upper;
    }

    double lowerCurrent = delta1 + lower;
    double upperCurrent = delta2 + upper;
    double scale = (upperCurrent - lowerCurrent) / (upper - lower);

    for (int i = start; i <= end; i++) {
      double pos = original[i].y;
      if (pos <= lower) {
        pos += delta1;
      } else if (pos >= upper) {
        pos += delta2;
      } else {
        pos = lowerCurrent + (pos - lower) * scale;
      }
      current[i].updateY(pos);
    }
  }

  _DisplacementInfo _computeDisplacement(int opcodeIndex) {
    Zone zone;
    int point;
    // SHP0, SHP1, SHC0, SHC1, SHZ0, SHZ1
    // OpCode indices are not necessarily contiguous or aligned with 0/1 bit for mode.
    // Let's check logic.
    // SHP0/1: mode & 1.
    // SHC0/1: mode & 1.
    // SHZ0/1: mode & 1.
    // In C#, (int)opcode is used.
    // My OpCode enum might not match C# values exactly if I didn't set them explicitly.
    // But I did implement OpCodeExtension.fromInt.
    // However, opcode.index is just the index in the enum list.
    // I should use the OpCode enum values to determine mode.
    
    bool isMode1 = false;
    if (opcodeIndex == OpCode.SHP1.index || 
        opcodeIndex == OpCode.SHC1.index || 
        opcodeIndex == OpCode.SHZ1.index) {
      isMode1 = true;
    }

    if (!isMode1) {
      zone = _zp1!;
      point = _state.rp2;
    } else {
      zone = _zp0!;
      point = _state.rp1;
    }

    var distance = project(zone.getCurrent(point) - zone.getOriginal(point));
    return _DisplacementInfo(_state.freedom * (distance / _fdotp), zone, point);
  }



  void _interpolateIUP(int p1, int p2, int contourStart, int contourEnd, bool isX) {
    if (p1 == p2) return;
    
    if (p2 > p1) {
      if (p2 > p1 + 1) {
        if (isX) {
          interpolatePointsXAxis(_zp2!.current, _zp2!.original, p1 + 1, p2 - 1, p1, p2);
        } else {
          interpolatePointsYAxis(_zp2!.current, _zp2!.original, p1 + 1, p2 - 1, p1, p2);
        }
      }
    } else {
      if (p1 < contourEnd) {
        if (isX) {
          interpolatePointsXAxis(_zp2!.current, _zp2!.original, p1 + 1, contourEnd, p1, p2);
        } else {
          interpolatePointsYAxis(_zp2!.current, _zp2!.original, p1 + 1, contourEnd, p1, p2);
        }
      }
      if (p2 > contourStart) {
        if (isX) {
          interpolatePointsXAxis(_zp2!.current, _zp2!.original, contourStart, p2 - 1, p1, p2);
        } else {
          interpolatePointsYAxis(_zp2!.current, _zp2!.original, contourStart, p2 - 1, p1, p2);
        }
      }
    }
  }

  double project(Vector2 point) => point.dot(_state.projection);
  double dualProject(Vector2 point) => point.dot(_state.dualProjection);

  double round(double value) {
    switch (_state.roundState) {
      case RoundMode.toGrid:
        return value >= 0 ? value.roundToDouble() : -(-value).roundToDouble();
      case RoundMode.toHalfGrid:
        return value >= 0 ? value.floorToDouble() + 0.5 : -((-value).floorToDouble() + 0.5);
      case RoundMode.toDoubleGrid:
        return value >= 0 ? (value * 2).roundToDouble() / 2 : -((-value * 2).roundToDouble() / 2);
      case RoundMode.downToGrid:
        return value >= 0 ? value.floorToDouble() : -(-value).floorToDouble();
      case RoundMode.upToGrid:
        return value >= 0 ? value.ceilToDouble() : -(-value).ceilToDouble();
      case RoundMode.superRound:
      case RoundMode.super45:
        double result;
        if (value >= 0) {
          result = value - _roundPhase + _roundThreshold;
          result = (result / _roundPeriod).floorToDouble() * _roundPeriod + _roundPhase;
        } else {
          result = -value - _roundPhase + _roundThreshold;
          result = -((result / _roundPeriod).floorToDouble() * _roundPeriod + _roundPhase);
        }
        return result;
      case RoundMode.off:
        return value;
    }
  }

  void movePoint(Zone zone, int index, double distance) {
    var vector = _state.freedom * (distance / _fdotp);
    zone.current[index].updateX(zone.current[index].x + vector.x);
    zone.current[index].updateY(zone.current[index].y + vector.y);
    zone.touchState[index] |= getTouchState();
  }

  void shiftPoints(dynamic arg) {
    Vector2 vector;
    if (arg is Vector2) {
      vector = arg;
    } else if (arg is double) {
      vector = _state.freedom * (arg / _fdotp);
    } else {
      throw InvalidTrueTypeFontException("Invalid argument for shiftPoints");
    }

    var touch = getTouchState();
    for (int i = 0; i < _zp2!.current.length; i++) {
      _zp2!.current[i].updateX(_zp2!.current[i].x + vector.x);
      _zp2!.current[i].updateY(_zp2!.current[i].y + vector.y);
      _zp2!.touchState[i] |= touch;
    }
  }

  double readCvt() {
    int index = _stack.pop();
    if (_controlValueTable == null || index < 0 || index >= _controlValueTable!.length) {
      return 0.0;
    }
    return _controlValueTable![index];
  }

  void checkIndex(int index, int length) {
    if (index < 0 || index >= length) {
      throw InvalidTrueTypeFontException("Index out of bounds: $index (length: $length)");
    }
  }

  int getTouchState() {
    int touch = 0;
    if (_state.freedom.x != 0) touch |= TouchState.x;
    if (_state.freedom.y != 0) touch |= TouchState.y;
    return touch;
  }
}

class _DisplacementInfo {
  final Vector2 displacement;
  final Zone zone;
  final int pointIndex;

  _DisplacementInfo(this.displacement, this.zone, this.pointIndex);
}

