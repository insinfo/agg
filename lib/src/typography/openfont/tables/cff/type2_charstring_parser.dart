import 'dart:typed_data';
import 'cff_objects.dart';

/// The Type 2 Charstring Format
/// ref http://wwwimages.adobe.com/www.adobe.com/content/dam/acom/en/devnet/font/pdfs/5177.Type2.pdf
class Type2Instruction {
  final int value;
  final int op; // byte

  Type2Instruction(this.op, [this.value = 0]);

  bool get isLoadInt => op == OperatorName.LoadInt;

  double readValueAsFixed1616() {
    int b0 = (0xff) & (value >> 24);
    int b1 = (0xff) & (value >> 16);
    int b2 = (0xff) & (value >> 8);
    int b3 = (0xff) & (value >> 0);

    /// This number is interpreted as a Fixed; that is, a signed number with 16 bits of fraction
    int intPart = ((b0 << 8) | b1).toSigned(16);
    double fractionPart = ((b2 << 8) | b3) / (1 << 16);
    return intPart + fractionPart;
  }

  @override
  String toString() {
    return 'Op: $op, Value: $value';
  }
}

class OperatorName {
  static const int Unknown = 0;
  
  // Internal Ops (100+)
  static const int LoadInt = 101;
  static const int LoadFloat = 102;
  static const int GlyphWidth = 103;

  static const int LoadSbyte4 = 104; 
  static const int LoadSbyte3 = 105; 
  static const int LoadShort2 = 106; 

  // Type2Operator1 (Standard Ops)
  static const int hstem = 1; 
  static const int vstem = 3; 
  static const int vmoveto = 4; 
  static const int rlineto = 5; 
  static const int hlineto = 6; 
  static const int vlineto = 7; 
  static const int rrcurveto = 8; 
  static const int callsubr = 10; 
  static const int returnOp = 11; 
  static const int endchar = 14; 
  static const int hstemhm = 18; 
  static const int hintmask = 19; 
  static const int cntrmask = 20; 
  static const int rmoveto = 21; 
  static const int hmoveto = 22; 
  static const int vstemhm = 23; 
  static const int rcurveline = 24; 
  static const int rlinecurve = 25; 
  static const int vvcurveto = 26; 
  static const int hhcurveto = 27; 
  static const int shortint = 28; 
  static const int callgsubr = 29; 
  static const int vhcurveto = 30; 
  static const int hvcurveto = 31; 

  // Two-byte Type 2 Operators (mapped to 32+)
  static const int andOp = 32;
  static const int orOp = 33;
  static const int notOp = 34;
  static const int abs = 35;
  static const int add = 36;
  static const int sub = 37;
  static const int div = 38;
  static const int neg = 39;
  static const int eq = 40;
  static const int drop = 41;
  static const int put = 42;
  static const int get = 43;
  static const int ifelse = 44;
  static const int random = 45;
  static const int mul = 46;
  static const int sqrt = 47;
  static const int dup = 48;
  static const int exch = 49;
  static const int index = 50;
  static const int roll = 51;
  static const int hflex = 52;
  static const int flex = 53;
  static const int hflex1 = 54;
  static const int flex1 = 55;

  // Extensions (mapped to 60+)
  static const int hintmask1 = 60;
  static const int hintmask2 = 61;
  static const int hintmask3 = 62;
  static const int hintmask4 = 63;
  static const int hintmask_bits = 64;

  static const int cntrmask1 = 65;
  static const int cntrmask2 = 66;
  static const int cntrmask3 = 67;
  static const int cntrmask4 = 68; 
  static const int cntrmask_bits = 69; 
}

class Type2GlyphInstructionList {
  final List<Type2Instruction> _insts = [];

  List<Type2Instruction> get instructions => _insts;

  void addInt(int intValue) {
    _insts.add(Type2Instruction(OperatorName.LoadInt, intValue));
  }

  void addFloat(int float1616Fmt) {
    _insts.add(Type2Instruction(OperatorName.LoadFloat, float1616Fmt));
  }

  void addOp(int opName, [int value = 0]) {
    _insts.add(Type2Instruction(opName, value));
  }

  int get count => _insts.length;

  Type2Instruction removeLast() {
    return _insts.removeLast();
  }

  void changeFirstInstToGlyphWidthValue() {
    if (_insts.isEmpty) return;
    var firstInst = _insts[0];
    if (!firstInst.isLoadInt) {
      throw Exception('First instruction must be LoadInt');
    }
    _insts[0] = Type2Instruction(OperatorName.GlyphWidth, firstInst.value);
  }
}

class SimpleBinaryReader {
  final Uint8List _buffer;
  int _pos = 0;

  SimpleBinaryReader(this._buffer);

  bool get isEnd => _pos >= _buffer.length;
  int get bufferLength => _buffer.length;
  int get position => _pos;

  int readByte() {
    return _buffer[_pos++];
  }

  int readFloatFixed1616() {
    int b0 = _buffer[_pos];
    int b1 = _buffer[_pos + 1];
    int b2 = _buffer[_pos + 2];
    int b3 = _buffer[_pos + 3];
    _pos += 4;
    return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
  }
}

class Type2CharStringParser {
  int _hintStemCount = 0;
  bool _foundSomeStem = false;
  bool _enterPathConstructionSeq = false;
  late Type2GlyphInstructionList _insts;
  int _currentIntegerCount = 0;
  bool _doStemCount = true;
  Cff1Font? _currentCff1Font;
  int _globalSubrBias = 0;
  int _localSubrBias = 0;
  FontDict? _currentFontDict;

  void setCurrentCff1Font(Cff1Font currentCff1Font) {
    _currentFontDict = null;
    _currentCff1Font = currentCff1Font;

    if (_currentCff1Font!.globalSubrIndex != null) {
      _globalSubrBias = calculateBias(_currentCff1Font!.globalSubrIndex!.length);
    }
  }

  void setCidFontDict(FontDict fontDict) {
    _currentFontDict = fontDict;
    if (fontDict.localSubr != null) {
      _localSubrBias = calculateBias(fontDict.localSubr!.length);
    } else {
      _localSubrBias = 0;
    }
  }

  static int calculateBias(int nSubr) {
    if (nSubr < 1240) return 107;
    if (nSubr < 33900) return 1131;
    return 32768;
  }

  Type2GlyphInstructionList parseType2CharString(Uint8List buffer) {
    _hintStemCount = 0;
    _currentIntegerCount = 0;
    _foundSomeStem = false;
    _enterPathConstructionSeq = false;
    _doStemCount = true;
    _insts = Type2GlyphInstructionList();

    parseType2CharStringBuffer(buffer);
    return _insts;
  }

  void parseType2CharStringBuffer(Uint8List buffer) {
    var reader = SimpleBinaryReader(buffer);
    while (!reader.isEnd) {
      int b0 = reader.readByte();
      
      if (b0 >= 32 && b0 <= 255) {
        if (b0 == 255) {
           _insts.addFloat(reader.readFloatFixed1616());
        } else {
           _insts.addInt(readIntegerNumber(reader, b0));
        }
        if (_doStemCount) _currentIntegerCount++;
        continue;
      }

      // Operators
      switch (b0) {
        case 28: // shortint
          int sB0 = reader.readByte();
          int sB1 = reader.readByte();
          int val = ((sB0 << 8) | sB1).toSigned(16);
          _insts.addInt(val);
          if (_doStemCount) _currentIntegerCount++;
          break;
        
        case 12: // escape
          int b1 = reader.readByte();
          handleEscapeOperator(b1);
          stopStemCount();
          break;

        case 14: // endchar
          addEndCharOp();
          return; // Stop reading

        case 21: // rmoveto
          addMoveToOp(OperatorName.rmoveto);
          stopStemCount();
          break;
        case 22: // hmoveto
          addMoveToOp(OperatorName.hmoveto);
          stopStemCount();
          break;
        case 4: // vmoveto
          addMoveToOp(OperatorName.vmoveto);
          stopStemCount();
          break;

        case 5: _insts.addOp(OperatorName.rlineto); stopStemCount(); break;
        case 6: _insts.addOp(OperatorName.hlineto); stopStemCount(); break;
        case 7: _insts.addOp(OperatorName.vlineto); stopStemCount(); break;
        case 8: _insts.addOp(OperatorName.rrcurveto); stopStemCount(); break;
        case 27: _insts.addOp(OperatorName.hhcurveto); stopStemCount(); break;
        case 31: _insts.addOp(OperatorName.hvcurveto); stopStemCount(); break;
        case 24: _insts.addOp(OperatorName.rcurveline); stopStemCount(); break;
        case 25: _insts.addOp(OperatorName.rlinecurve); stopStemCount(); break;
        case 30: _insts.addOp(OperatorName.vhcurveto); stopStemCount(); break;
        case 26: _insts.addOp(OperatorName.vvcurveto); stopStemCount(); break;

        case 1: addStemToList(OperatorName.hstem); break;
        case 3: addStemToList(OperatorName.vstem); break;
        case 23: addStemToList(OperatorName.vstemhm); break;
        case 18: addStemToList(OperatorName.hstemhm); break;

        case 19: addHintMaskToList(reader); stopStemCount(); break;
        case 20: addCounterMaskToList(reader); stopStemCount(); break;

        case 11: // return
          return;
        
        case 10: // callsubr
          handleCallSubr();
          break;
        case 29: // callgsubr
          handleCallGSubr();
          break;

        default:
          // Reserved or unknown
          break;
      }
    }
  }

  void handleEscapeOperator(int op) {
    switch (op) {
      case 35: _insts.addOp(OperatorName.flex); break;
      case 34: _insts.addOp(OperatorName.hflex); break;
      case 36: _insts.addOp(OperatorName.hflex1); break;
      case 37: _insts.addOp(OperatorName.flex1); break;
      
      case 9: _insts.addOp(OperatorName.abs); break;
      case 10: _insts.addOp(OperatorName.add); break;
      case 11: _insts.addOp(OperatorName.sub); break;
      case 12: _insts.addOp(OperatorName.div); break;
      case 14: _insts.addOp(OperatorName.neg); break;
      case 23: _insts.addOp(OperatorName.random); break;
      case 24: _insts.addOp(OperatorName.mul); break;
      case 26: _insts.addOp(OperatorName.sqrt); break;
      case 18: _insts.addOp(OperatorName.drop); break;
      case 28: _insts.addOp(OperatorName.exch); break;
      case 29: _insts.addOp(OperatorName.index); break;
      case 30: _insts.addOp(OperatorName.roll); break;
      case 27: _insts.addOp(OperatorName.dup); break;

      case 20: _insts.addOp(OperatorName.put); break;
      case 21: _insts.addOp(OperatorName.get); break;

      case 3: _insts.addOp(OperatorName.andOp); break;
      case 4: _insts.addOp(OperatorName.orOp); break;
      case 5: _insts.addOp(OperatorName.notOp); break;
      case 15: _insts.addOp(OperatorName.eq); break;
      case 22: _insts.addOp(OperatorName.ifelse); break;
    }
  }

  void handleCallSubr() {
    if (_currentFontDict != null && _currentFontDict!.localSubr != null) {
      var inst = _insts.removeLast();
      if (!inst.isLoadInt) throw Exception('Expected int for callsubr');
      if (_doStemCount) _currentIntegerCount--;
      
      int index = inst.value + _localSubrBias;
      if (index >= 0 && index < _currentFontDict!.localSubr!.length) {
        parseType2CharStringBuffer(Uint8List.fromList(_currentFontDict!.localSubr![index]));
      }
    }
  }

  void handleCallGSubr() {
    if (_currentCff1Font != null && _currentCff1Font!.globalSubrIndex != null) {
      var inst = _insts.removeLast();
      if (!inst.isLoadInt) throw Exception('Expected int for callgsubr');
      if (_doStemCount) _currentIntegerCount--;

      int index = inst.value + _globalSubrBias;
      if (index >= 0 && index < _currentCff1Font!.globalSubrIndex!.length) {
        parseType2CharStringBuffer(Uint8List.fromList(_currentCff1Font!.globalSubrIndex![index]));
      }
    }
  }

  int readIntegerNumber(SimpleBinaryReader reader, int b0) {
    if (b0 >= 32 && b0 <= 246) {
      return b0 - 139;
    } else if (b0 <= 250) {
      int b1 = reader.readByte();
      return (b0 - 247) * 256 + b1 + 108;
    } else if (b0 <= 254) {
      int b1 = reader.readByte();
      return -(b0 - 251) * 256 - b1 - 108;
    } else {
      throw Exception('Invalid integer format');
    }
  }

  void stopStemCount() {
    _currentIntegerCount = 0;
    _doStemCount = false;
  }

  void addEndCharOp() {
    if (!_foundSomeStem && !_enterPathConstructionSeq) {
      if (_insts.count > 0) {
        _insts.changeFirstInstToGlyphWidthValue();
      }
    }
    _insts.addOp(OperatorName.endchar);
  }

  void addMoveToOp(int op) {
    if (!_foundSomeStem && !_enterPathConstructionSeq) {
      if (op == OperatorName.rmoveto) {
        if ((_insts.count % 2) != 0) {
          _insts.changeFirstInstToGlyphWidthValue();
        }
      } else {
        if (_insts.count > 1) {
          _insts.changeFirstInstToGlyphWidthValue();
        }
      }
    }
    _enterPathConstructionSeq = true;
    _insts.addOp(op);
  }

  void addStemToList(int stemName) {
    if ((_currentIntegerCount % 2) != 0) {
      if (_foundSomeStem) {
        throw Exception('Stem count mismatch');
      } else {
        _insts.changeFirstInstToGlyphWidthValue();
        _currentIntegerCount--;
      }
    }
    _hintStemCount += (_currentIntegerCount ~/ 2);
    _insts.addOp(stemName);
    _currentIntegerCount = 0;
    _foundSomeStem = true;
  }

  void addHintMaskToList(SimpleBinaryReader reader) {
    if (_foundSomeStem && _currentIntegerCount > 0) {
      // Implicit vstem
      _hintStemCount += (_currentIntegerCount ~/ 2);
      _insts.addOp(OperatorName.vstem);
      _currentIntegerCount = 0;
    }

    if (_hintStemCount == 0) {
      if (!_foundSomeStem) {
        _hintStemCount = (_currentIntegerCount ~/ 2);
        if (_hintStemCount == 0) return;
        _foundSomeStem = true;
      } else {
        throw Exception('Hint mask without stems');
      }
    }

    int properNumberOfMaskBytes = (_hintStemCount + 7) ~/ 8;
    if (reader.position + properNumberOfMaskBytes > reader.bufferLength) {
      throw Exception('Buffer overflow reading hint mask');
    }

    if (properNumberOfMaskBytes > 4) {
      int remaining = properNumberOfMaskBytes;
      while (remaining > 3) {
        _insts.addInt(
          (reader.readByte() << 24) |
          (reader.readByte() << 16) |
          (reader.readByte() << 8) |
          (reader.readByte())
        );
        remaining -= 4;
      }
      // Handle remaining bytes... logic similar to C#
      if (remaining == 1) _insts.addInt(reader.readByte() << 24);
      else if (remaining == 2) _insts.addInt((reader.readByte() << 24) | (reader.readByte() << 16));
      else if (remaining == 3) _insts.addInt((reader.readByte() << 24) | (reader.readByte() << 16) | (reader.readByte() << 8));
      
      _insts.addOp(OperatorName.hintmask_bits, properNumberOfMaskBytes);
    } else {
      int val = 0;
      if (properNumberOfMaskBytes == 1) val = reader.readByte() << 24;
      else if (properNumberOfMaskBytes == 2) val = (reader.readByte() << 24) | (reader.readByte() << 16);
      else if (properNumberOfMaskBytes == 3) val = (reader.readByte() << 24) | (reader.readByte() << 16) | (reader.readByte() << 8);
      else if (properNumberOfMaskBytes == 4) val = (reader.readByte() << 24) | (reader.readByte() << 16) | (reader.readByte() << 8) | reader.readByte();
      
      int op = OperatorName.hintmask1;
      if (properNumberOfMaskBytes == 2) op = OperatorName.hintmask2;
      if (properNumberOfMaskBytes == 3) op = OperatorName.hintmask3;
      if (properNumberOfMaskBytes == 4) op = OperatorName.hintmask4;
      
      _insts.addOp(op, val);
    }
  }

  void addCounterMaskToList(SimpleBinaryReader reader) {
     // Similar logic to hintmask
     if (_hintStemCount == 0) {
       if (!_foundSomeStem) {
         _hintStemCount = (_currentIntegerCount ~/ 2);
         _foundSomeStem = true;
       } else {
         throw Exception('Counter mask without stems');
       }
     } else {
       _hintStemCount += (_currentIntegerCount ~/ 2);
     }

     int properNumberOfMaskBytes = (_hintStemCount + 7) ~/ 8;
     // ... (implementation similar to hintmask)
     // For brevity, I'll implement the >4 case and <=4 case
     if (properNumberOfMaskBytes > 4) {
        int remaining = properNumberOfMaskBytes;
        while (remaining > 3) {
          _insts.addInt(
            (reader.readByte() << 24) |
            (reader.readByte() << 16) |
            (reader.readByte() << 8) |
            (reader.readByte())
          );
          remaining -= 4;
        }
        if (remaining == 1) _insts.addInt(reader.readByte() << 24);
        else if (remaining == 2) _insts.addInt((reader.readByte() << 24) | (reader.readByte() << 16));
        else if (remaining == 3) _insts.addInt((reader.readByte() << 24) | (reader.readByte() << 16) | (reader.readByte() << 8));
        
        _insts.addOp(OperatorName.cntrmask_bits, properNumberOfMaskBytes);
     } else {
        int val = 0;
        if (properNumberOfMaskBytes == 1) val = reader.readByte() << 24;
        else if (properNumberOfMaskBytes == 2) val = (reader.readByte() << 24) | (reader.readByte() << 16);
        else if (properNumberOfMaskBytes == 3) val = (reader.readByte() << 24) | (reader.readByte() << 16) | (reader.readByte() << 8);
        else if (properNumberOfMaskBytes == 4) val = (reader.readByte() << 24) | (reader.readByte() << 16) | (reader.readByte() << 8) | reader.readByte();
        
        int op = OperatorName.cntrmask1;
        if (properNumberOfMaskBytes == 2) op = OperatorName.cntrmask2;
        if (properNumberOfMaskBytes == 3) op = OperatorName.cntrmask3;
        if (properNumberOfMaskBytes == 4) op = OperatorName.cntrmask4;
        
        _insts.addOp(op, val);
     }
  }
}
