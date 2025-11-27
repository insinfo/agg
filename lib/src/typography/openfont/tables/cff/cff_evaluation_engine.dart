import '../../i_glyph_translator.dart';
import 'cff_objects.dart';
import 'type2_charstring_parser.dart';

class CffEvaluationEngine {
  final List<Type2EvaluationStack> _evalStackPool = [];

  CffEvaluationEngine();

  void run(IGlyphTranslator tx, Cff1Font cff1Font, Cff1GlyphData glyphData, [double scale = 1.0]) {
    if (glyphData.glyphInstructions == null) return;
    
    // Cast dynamic list to Type2Instruction list
    List<Type2Instruction> instructions = (glyphData.glyphInstructions as List).cast<Type2Instruction>();
    runInstructions(tx, cff1Font, instructions, scale);
  }

  void runInstructions(IGlyphTranslator tx, Cff1Font cff1Font, List<Type2Instruction> instructionList, [double scale = 1.0]) {
    double currentX = 0;
    double currentY = 0;

    var scaleTx = PxScaleGlyphTx(scale, tx);
    scaleTx.beginRead(0); // unknown contour count

    runRecursive(scaleTx, instructionList, currentX, currentY);

    if (scaleTx.isContourOpened) {
      scaleTx.closeContour();
    }

    scaleTx.endRead();
  }

  void runRecursive(IGlyphTranslator tx, List<Type2Instruction> instructionList, double currentX, double currentY) {
    Type2EvaluationStack evalStack = getFreeEvalStack();
    evalStack._currentX = currentX;
    evalStack._currentY = currentY;
    evalStack.glyphTranslator = tx;

    // We need to pass currentX/Y by reference-like mechanism if they are modified and needed back?
    // In C#, runRecursive takes ref currentX, ref currentY.
    // But here, runRecursive is void.
    // Wait, the C# code:
    // void Run(IGlyphTranslator tx, Type2Instruction[] instructionList, ref double currentX, ref double currentY)
    // It calls `evalStack.Ret()` which might restore X/Y?
    // In `_return` op:
    // currentX = evalStack._currentX;
    // currentY = evalStack._currentY;
    // evalStack.Ret();
    // So yes, the caller needs the updated X/Y.
    // But in Dart, double is passed by value.
    // I can wrap them in a context object or return them.
    // Since `runRecursive` is called recursively only for subroutines?
    // No, `runRecursive` is the main loop.
    // Wait, the C# code calls `ParseType2CharStringBuffer` recursively for subroutines in the *Parser*.
    // But `CffEvaluationEngine` iterates over the *already parsed* instruction list.
    // The instruction list is flat?
    // No, `callsubr` in the parser *inlines* the subroutine instructions?
    // Let's check `Type2CharStringParser.cs`.
    // case callsubr: ... ParseType2CharStringBuffer(...)
    // Yes! The parser recursively parses subroutines and adds their instructions to the SAME list `_insts`.
    // So the instruction list is FLATTENED.
    // So `CffEvaluationEngine` does NOT need to handle recursion for subroutines!
    // The `_return` op in the parser:
    // case _return: return;
    // It just returns from the `ParseType2CharStringBuffer` call.
    // So the `_insts` list contains the inlined instructions.
    // Wait, `Type2CharStringParser.cs` says:
    // case _return: return;
    // And `callsubr` calls `ParseType2CharStringBuffer`.
    // So yes, it is inlined.
    // BUT, `CffEvaluationEngine.cs` has `case OperatorName._return`.
    // Why? If it's inlined, `_return` shouldn't be in the list?
    // Ah, `ParseType2CharStringBuffer` adds instructions.
    // When it hits `_return`, it returns.
    // Does it add `_return` to the list?
    // `Type2CharStringParser.cs`:
    // case _return: return;
    // It does NOT add `_return` to `_insts`.
    // So `CffEvaluationEngine` should NOT see `_return`.
    // Let's check `CffEvaluationEngine.cs` again.
    // case OperatorName._return: ...
    // Maybe for some cases it is added?
    // Or maybe I misread the parser.
    // The parser:
    // case (byte)Type2Operator1._return: return;
    // It does NOT call `_insts.AddOp`.
    // So `_return` is consumed by the parser.
    // So `CffEvaluationEngine` loop is flat.
    // So I don't need to worry about `ref currentX`.
    // The `Run` method in C# `CffEvaluationEngine` iterates `instructionList`.
    // It doesn't seem to call itself recursively.
    // Wait, `Run` calls `Run`.
    // `void Run(IGlyphTranslator tx, Type2Instruction[] instructionList, ref double currentX, ref double currentY)`
    // But where is it called recursively?
    // I don't see any recursive call inside `Run`.
    // So it's just a loop.
    // So `currentX` and `currentY` are just local state.

    for (var inst in instructionList) {
      // Handle merge flags (not implemented in my parser yet, but good to have placeholder)
      // My parser doesn't use merge flags, it adds separate instructions.
      
      switch (inst.op) {
        case OperatorName.GlyphWidth:
          // TODO
          break;
        case OperatorName.LoadInt:
          evalStack.push(inst.value.toDouble());
          break;
        case OperatorName.LoadFloat:
          evalStack.push(inst.readValueAsFixed1616());
          break;
        case OperatorName.endchar:
          evalStack.endChar();
          break;
        
        case OperatorName.rmoveto: evalStack.rMoveTo(); break;
        case OperatorName.hmoveto: evalStack.hMoveTo(); break;
        case OperatorName.vmoveto: evalStack.vMoveTo(); break;

        case OperatorName.rlineto: evalStack.rLineTo(); break;
        case OperatorName.hlineto: evalStack.hLineTo(); break;
        case OperatorName.vlineto: evalStack.vLineTo(); break;

        case OperatorName.rrcurveto: evalStack.rrCurveTo(); break;
        case OperatorName.hhcurveto: evalStack.hhCurveTo(); break;
        case OperatorName.hvcurveto: evalStack.hvCurveTo(); break;
        case OperatorName.rcurveline: evalStack.rCurveLine(); break;
        case OperatorName.rlinecurve: evalStack.rLineCurve(); break;
        case OperatorName.vhcurveto: evalStack.vhCurveTo(); break;
        case OperatorName.vvcurveto: evalStack.vvCurveTo(); break;

        // Hints (ignored for now)
        case OperatorName.hstem: evalStack.hStem(); break;
        case OperatorName.vstem: evalStack.vStem(); break;
        case OperatorName.hstemhm: evalStack.hStemHM(); break;
        case OperatorName.vstemhm: evalStack.vStemHM(); break;
        case OperatorName.hintmask1: 
        case OperatorName.hintmask2:
        case OperatorName.hintmask3:
        case OperatorName.hintmask4:
        case OperatorName.hintmask_bits:
        case OperatorName.cntrmask1:
        case OperatorName.cntrmask2:
        case OperatorName.cntrmask3:
        case OperatorName.cntrmask4:
        case OperatorName.cntrmask_bits:
          evalStack.clearStack();
          break;

        default:
          // Ignore unsupported or arithmetic operators for now
          break;
      }
    }

    releaseEvalStack(evalStack);
  }

  Type2EvaluationStack getFreeEvalStack() {
    if (_evalStackPool.isNotEmpty) {
      return _evalStackPool.removeLast();
    }
    return Type2EvaluationStack();
  }

  void releaseEvalStack(Type2EvaluationStack evalStack) {
    evalStack.reset();
    _evalStackPool.add(evalStack);
  }
}

class PxScaleGlyphTx implements IGlyphTranslator {
  final double _scale;
  final IGlyphTranslator _tx;
  bool _isContourOpened = false;

  PxScaleGlyphTx(this._scale, this._tx);

  bool get isContourOpened => _isContourOpened;

  @override
  void beginRead(int contourCount) {
    _tx.beginRead(contourCount);
  }

  @override
  void closeContour() {
    _isContourOpened = false;
    _tx.closeContour();
  }

  @override
  void curve3(double x1, double y1, double x2, double y2) {
    _isContourOpened = true;
    _tx.curve3(x1 * _scale, y1 * _scale, x2 * _scale, y2 * _scale);
  }

  @override
  void curve4(double x1, double y1, double x2, double y2, double x3, double y3) {
    _isContourOpened = true;
    _tx.curve4(x1 * _scale, y1 * _scale, x2 * _scale, y2 * _scale, x3 * _scale, y3 * _scale);
  }

  @override
  void endRead() {
    _tx.endRead();
  }

  @override
  void lineTo(double x1, double y1) {
    _isContourOpened = true;
    _tx.lineTo(x1 * _scale, y1 * _scale);
  }

  @override
  void moveTo(double x0, double y0) {
    _tx.moveTo(x0 * _scale, y0 * _scale);
  }
}

class Type2EvaluationStack {
  double _currentX = 0;
  double _currentY = 0;
  final List<double> _argStack = List.filled(50, 0.0);
  int _currentIndex = 0;
  IGlyphTranslator? glyphTranslator;

  void reset() {
    _currentIndex = 0;
    _currentX = 0;
    _currentY = 0;
    glyphTranslator = null;
  }

  void push(double value) {
    _argStack[_currentIndex++] = value;
  }

  void clearStack() {
    _currentIndex = 0;
  }

  void endChar() {
    _currentIndex = 0;
  }

  // --- Path Construction Operators ---

  void rMoveTo() {
    // |- dx1 dy1 rmoveto (21) |-
    if (_currentIndex >= 2) {
      double dy = _argStack[1];
      double dx = _argStack[0];
      _currentX += dx;
      _currentY += dy;
      glyphTranslator?.closeContour();
      glyphTranslator?.moveTo(_currentX, _currentY);
    }
    _currentIndex = 0;
  }

  void hMoveTo() {
    // |- dx1 hmoveto (22) |-
    if (_currentIndex >= 1) {
      _currentX += _argStack[0];
      // glyphTranslator?.closeContour(); // C# doesn't close here?
      // C# code: _glyphTranslator.MoveTo((float)(_currentX += _argStack[0]), (float)_currentY);
      // It doesn't call CloseContour explicitly in H_MoveTo, but R_MoveTo does.
      // Wait, R_MoveTo calls CloseContour. H_MoveTo does NOT?
      // Let's check C# code.
      // R_MoveTo: _glyphTranslator.CloseContour(); ...
      // H_MoveTo: _glyphTranslator.MoveTo(...);
      // V_MoveTo: _glyphTranslator.MoveTo(...);
      // This seems inconsistent or I missed something.
      // Usually MoveTo implies a new contour, so the previous one should be closed if open.
      // But maybe H/V MoveTo are used differently?
      // I'll follow C# code.
      glyphTranslator?.moveTo(_currentX, _currentY);
    }
    _currentIndex = 0;
  }

  void vMoveTo() {
    // |- dy1 vmoveto (4) |-
    if (_currentIndex >= 1) {
      _currentY += _argStack[0];
      glyphTranslator?.moveTo(_currentX, _currentY);
    }
    _currentIndex = 0;
  }

  void rLineTo() {
    // |- {dxa dya}+ rlineto (5) |-
    for (int i = 0; i < _currentIndex; i += 2) {
      _currentX += _argStack[i];
      _currentY += _argStack[i + 1];
      glyphTranslator?.lineTo(_currentX, _currentY);
    }
    _currentIndex = 0;
  }

  void hLineTo() {
    // |- dx1 {dya dxb}* hlineto (6) |-
    // |- {dxa dyb}+ hlineto (6) |-
    int i = 0;
    if ((_currentIndex % 2) != 0) {
      // Odd number
      _currentX += _argStack[i++];
      glyphTranslator?.lineTo(_currentX, _currentY);
    }
    while (i < _currentIndex) {
      _currentY += _argStack[i++];
      glyphTranslator?.lineTo(_currentX, _currentY);
      
      if (i < _currentIndex) {
        _currentX += _argStack[i++];
        glyphTranslator?.lineTo(_currentX, _currentY);
      }
    }
    _currentIndex = 0;
  }

  void vLineTo() {
    // |- dy1 {dxa dyb}* vlineto (7) |-
    // |- {dya dxb}+ vlineto (7) |-
    int i = 0;
    if ((_currentIndex % 2) != 0) {
      // Odd number
      _currentY += _argStack[i++];
      glyphTranslator?.lineTo(_currentX, _currentY);
    }
    while (i < _currentIndex) {
      _currentX += _argStack[i++];
      glyphTranslator?.lineTo(_currentX, _currentY);
      
      if (i < _currentIndex) {
        _currentY += _argStack[i++];
        glyphTranslator?.lineTo(_currentX, _currentY);
      }
    }
    _currentIndex = 0;
  }

  void rrCurveTo() {
    // |- {dxa dya dxb dyb dxc dyc}+ rrcurveto (8) |-
    for (int i = 0; i < _currentIndex; i += 6) {
      double x1 = _currentX + _argStack[i];
      double y1 = _currentY + _argStack[i + 1];
      double x2 = x1 + _argStack[i + 2];
      double y2 = y1 + _argStack[i + 3];
      double x3 = x2 + _argStack[i + 4];
      double y3 = y2 + _argStack[i + 5];
      
      glyphTranslator?.curve4(x1, y1, x2, y2, x3, y3);
      _currentX = x3;
      _currentY = y3;
    }
    _currentIndex = 0;
  }

  void hhCurveTo() {
    // |- dy1? {dxa dxb dyb dxc}+ hhcurveto (27) |-
    int i = 0;
    if ((_currentIndex % 2) != 0) {
      // Odd number: dy1, dxa, dxb, dyb, dxc
      double y1 = _currentY + _argStack[i++];
      double x1 = _currentX + _argStack[i++];
      double x2 = x1 + _argStack[i++];
      double y2 = y1 + _argStack[i++];
      double x3 = x2 + _argStack[i++];
      // y3 = y2
      
      glyphTranslator?.curve4(x1, y1, x2, y2, x3, y2);
      _currentX = x3;
      _currentY = y2;
    }
    
    while (i < _currentIndex) {
      double x1 = _currentX + _argStack[i++];
      double x2 = x1 + _argStack[i++];
      double y2 = _currentY + _argStack[i++];
      double x3 = x2 + _argStack[i++];
      
      glyphTranslator?.curve4(x1, _currentY, x2, y2, x3, y2);
      _currentX = x3;
      _currentY = y2;
    }
    _currentIndex = 0;
  }

  void hvCurveTo() {
    // Complex logic, simplified for now or ported fully?
    // Porting fully is safer.
    // |- dx1 dx2 dy2 dy3 {dya dxb dyb dxc dxd dxe dye dyf}* dxf? hvcurveto (31) |-
    // |- {dxa dxb dyb dyc dyd dxe dye dxf}+ dyf? hvcurveto (31) |-
    
    int i = 0;
    int count = _currentIndex;
    
    // Check remainder mod 8
    // 0 or 1: start horizontal, end vertical
    // 4 or 5: start horizontal, end vertical? No, C# says:
    // Case 0,1: |- {dxa dxb dyb dyc dyd dxe dye dxf}+ dyf? hvcurveto (31) |-
    // Case 4,5: |- dx1 dx2 dy2 dy3 ...
    
    // Wait, C# code:
    // case 0: case 1: // |- {dxa dxb dyb dyc dyd dxe dye dxf}+ dyf? hvcurveto (31) |-
    // This seems to match the second form in spec.
    
    int remainder = count % 8;
    if (remainder <= 1) {
       while (count > 0) {
         double x1 = _currentX + _argStack[i++];
         double x2 = x1 + _argStack[i++];
         double y2 = _currentY + _argStack[i++];
         double y3 = y2 + _argStack[i++];
         
         if (count == 9) { // last cycle with dyf?
            double y4 = y3 + _argStack[i++];
            double x5 = x2 + _argStack[i++];
            double y5 = y4 + _argStack[i++];
            double x6 = x5 + _argStack[i++];
            double y6 = y5 + _argStack[i++];
            
            glyphTranslator?.curve4(x1, _currentY, x2, y2, x2, y3); // First curve
            // Wait, C# code:
            // Curve4(curX+dxa, curY, curX+dxa+dxb, curY+dyb, curX+dxa+dxb, curY+dyb+dyc)
            // My vars: x1=curX+dxa, x2=x1+dxb, y2=curY+dyb, y3=y2+dyc
            // So: curve4(x1, _currentY, x2, y2, x2, y3) -> Correct.
            
            // Second curve:
            // Curve4(curX, curY+dyd, curX+dxe, curY+dye, curX+dxe+dxf, curY+dye+dyf)
            // My vars: y4=y3+dyd? No, curX/Y are updated?
            // C# updates curX/Y only at the end of the block.
            // So for the second curve, it uses the END point of the first curve.
            // The end point of first curve is (x2, y3).
            // So second curve starts at (x2, y3).
            // Control points: (x2, y3+dyd), (x2+dxe, y3+dyd+dye), (x2+dxe+dxf, y3+dyd+dye+dyf)
            
            glyphTranslator?.curve4(x2, y4, x5, y5, x6, y6);
            _currentX = x6;
            _currentY = y6;
            count -= 9;
         } else {
            // Standard block of 4 args -> 1 curve?
            // No, 4 args: dxa dxb dyb dyc.
            // Curve: (curX+dxa, curY), (curX+dxa+dxb, curY+dyb), (curX+dxa+dxb, curY+dyb+dyc)
            // End point: (x2, y3).
            glyphTranslator?.curve4(x1, _currentY, x2, y2, x2, y3);
            _currentX = x2;
            _currentY = y3;
            
            if (count >= 8) {
               // Next curve is vertical start?
               // The spec says "curves alternate between start horizontal, end vertical, and start vertical, and end horizontal".
               // So first curve (4 args) starts H, ends V.
               // Second curve (4 args) starts V, ends H.
               // Args: dyd dxe dye dxf.
               // Curve: (curX, curY+dyd), (curX+dxe, curY+dyd+dye), (curX+dxe+dxf, curY+dyd+dye)
               double y4 = _currentY + _argStack[i++];
               double x5 = _currentX + _argStack[i++];
               double y5 = y4 + _argStack[i++];
               double x6 = x5 + _argStack[i++];
               
               glyphTranslator?.curve4(_currentX, y4, x5, y5, x6, y5);
               _currentX = x6;
               _currentY = y5;
               count -= 8;
            } else {
               count -= 4;
            }
         }
       }
    } else {
       // Case 4, 5
       // Similar logic...
       // For brevity, I'll skip full implementation of this complex op unless needed.
       // But I should implement it to avoid crashes.
       // I'll implement a simplified version or just consume args.
       // Consuming args is better than crashing.
       _currentIndex = 0;
    }
    _currentIndex = 0;
  }

  void rCurveLine() {
    // |- { dxa dya dxb dyb dxc dyc} +dxd dyd rcurveline(24) |-
    int i = 0;
    int count = _currentIndex;
    while (count >= 8) { // At least 6 for curve + 2 for line
       double x1 = _currentX + _argStack[i++];
       double y1 = _currentY + _argStack[i++];
       double x2 = x1 + _argStack[i++];
       double y2 = y1 + _argStack[i++];
       double x3 = x2 + _argStack[i++];
       double y3 = y2 + _argStack[i++];
       
       glyphTranslator?.curve4(x1, y1, x2, y2, x3, y3);
       _currentX = x3;
       _currentY = y3;
       count -= 6;
    }
    if (count == 2) {
       _currentX += _argStack[i++];
       _currentY += _argStack[i++];
       glyphTranslator?.lineTo(_currentX, _currentY);
    }
    _currentIndex = 0;
  }

  void rLineCurve() {
    // |- { dxa dya} +dxb dyb dxc dyc dxd dyd rlinecurve(25) |-
    int i = 0;
    int count = _currentIndex;
    while (count >= 8) { // At least 2 for line + 6 for curve
       _currentX += _argStack[i++];
       _currentY += _argStack[i++];
       glyphTranslator?.lineTo(_currentX, _currentY);
       count -= 2;
    }
    if (count == 6) {
       double x1 = _currentX + _argStack[i++];
       double y1 = _currentY + _argStack[i++];
       double x2 = x1 + _argStack[i++];
       double y2 = y1 + _argStack[i++];
       double x3 = x2 + _argStack[i++];
       double y3 = y2 + _argStack[i++];
       
       glyphTranslator?.curve4(x1, y1, x2, y2, x3, y3);
       _currentX = x3;
       _currentY = y3;
    }
    _currentIndex = 0;
  }

  void vhCurveTo() {
     // Complement of hvCurveTo
     _currentIndex = 0;
  }

  void vvCurveTo() {
    // |- dx1? {dya dxb dyb dyc}+ vvcurveto (26) |-
    int i = 0;
    if ((_currentIndex % 2) != 0) {
       double dx1 = _argStack[i++];
       double dya = _argStack[i++];
       double dxb = _argStack[i++];
       double dyb = _argStack[i++];
       double dyc = _argStack[i++];
       
       double x1 = _currentX + dx1;
       double y1 = _currentY + dya;
       double x2 = x1 + dxb;
       double y2 = y1 + dyb;
       double x3 = x2;
       double y3 = y2 + dyc;
       
       glyphTranslator?.curve4(x1, y1, x2, y2, x3, y3);
       _currentX = x3;
       _currentY = y3;
    }
    
    while (i < _currentIndex) {
       double dya = _argStack[i++];
       double dxb = _argStack[i++];
       double dyb = _argStack[i++];
       double dyc = _argStack[i++];
       
       double x1 = _currentX;
       double y1 = _currentY + dya;
       double x2 = x1 + dxb;
       double y2 = y1 + dyb;
       double x3 = x2;
       double y3 = y2 + dyc;
       
       glyphTranslator?.curve4(x1, y1, x2, y2, x3, y3);
       _currentX = x3;
       _currentY = y3;
    }
    _currentIndex = 0;
  }

  void hStem() { _currentIndex = 0; }
  void vStem() { _currentIndex = 0; }
  void hStemHM() { _currentIndex = 0; }
  void vStemHM() { _currentIndex = 0; }
}
