import 'dart:convert';

import '../../../io/byte_order_swapping_reader.dart';
import '../../glyph.dart';
import '../utils.dart';
import 'cff_objects.dart';
import 'type2_charstring_parser.dart';

class CffIndexOffset {
  final int startOffset;
  final int len;

  CffIndexOffset(this.startOffset, this.len);
}

class Cff1Parser {
  late ByteOrderSwappingBinaryReader _reader;
  late Cff1FontSet _cff1FontSet;
  late Cff1Font _currentCff1Font;
  
  int _cffStartAt = 0;
  int _charStringsOffset = 0;
  int _charsetOffset = 0;
  // ignore: unused_field
  int _encodingOffset = 0;
  int _privateDICTLen = 0;
  int _privateDICTOffset = 0;

  // CID Font Info
  // ignore: unused_field
  String? _rosRegister;
  // ignore: unused_field
  String? _rosOrdering;
  // ignore: unused_field
  String? _rosSupplement;
  // ignore: unused_field
  double _cidFontVersion = 0;
  // ignore: unused_field
  int _cidFontCount = 0;
  int _fdSelect = 0;
  int _fdArray = 0;
  // ignore: unused_field
  int _fdSelectFormat = 0;
  // ignore: unused_field
  List<FDRange3>? _fdRanges;

  Cff1FontSet get resultCff1FontSet => _cff1FontSet;

  void parseAfterHeader(int cffStartAt, ByteOrderSwappingBinaryReader reader) {
    _cffStartAt = cffStartAt;
    _reader = reader;
    _cff1FontSet = Cff1FontSet();
    
    // Ensure operators are registered
    CFFOperator.ensureInit();

    readNameIndex();
    readTopDICTIndex();
    readStringIndex();
    resolveTopDictInfo();
    readGlobalSubrIndex();
    
    readFDSelect();
    readFDArray();
    
    readPrivateDict();
    
    readCharStringsIndex();
    readCharsets();
    readEncodings();
  }

  List<CffIndexOffset>? readIndexDataOffsets() {
    // Card16 count
    final count = _reader.readUInt16();
    if (count == 0) {
      return null;
    }

    // OffSize offSize
    final offSize = _reader.readByte();
    
    final offsets = <int>[];
    for (var i = 0; i <= count; i++) {
      offsets.add(_readOffset(offSize));
    }

    final indexElems = <CffIndexOffset>[];
    for (var i = 0; i < count; i++) {
      indexElems.add(CffIndexOffset(offsets[i], offsets[i + 1] - offsets[i]));
    }
    return indexElems;
  }

  int _readOffset(int offSize) {
    switch (offSize) {
      case 1:
        return _reader.readByte();
      case 2:
        return _reader.readUInt16();
      case 3:
        return Utils.readUInt24(_reader);
      case 4:
        return _reader.readUInt32();
      default:
        throw FormatException('Invalid offset size: $offSize');
    }
  }

  void readNameIndex() {
    final nameIndexElems = readIndexDataOffsets();
    if (nameIndexElems == null) return;

    final fontNames = <String>[];
    // Offsets are relative to the byte that precedes the object data.
    // The data starts after the offset array.
    // The offset array size is (count + 1) * offSize.
    // The header is 2 (count) + 1 (offSize).
    // So data starts at: current_pos + (count + 1) * offSize - 1 (because offsets start at 1)
    
    // Wait, the offsets are relative to the byte *preceding* the object data.
    // The structure is:
    // count (2)
    // offSize (1)
    // offset[count+1] (offSize * (count+1))
    // data...
    
    // The first offset is always 1.
    // So if we are at the start of data, offset 1 means the first byte.
    
    // My readIndexDataOffsets reads the offsets but doesn't position the stream to the data.
    // The stream is now at the start of data.
    
    final dataStart = _reader.position;

    for (final indexElem in nameIndexElems) {
      _reader.seek(dataStart + indexElem.startOffset - 1);
      final bytes = _reader.readBytes(indexElem.len);
      fontNames.add(utf8.decode(bytes));
    }

    _cff1FontSet.fontNames = fontNames;

    if (fontNames.length != 1) {
      // For now, we assume 1 font per CFF in this context, though CFF supports sets.
      // But we'll just take the first one as current.
    }
    
    _currentCff1Font = Cff1Font();
    if (fontNames.isNotEmpty) {
      _currentCff1Font.fontName = fontNames[0];
    }
    _cff1FontSet.fonts.add(_currentCff1Font);
  }

  List<CffDataDicEntry>? _topDic;

  void readTopDICTIndex() {
    final offsets = readIndexDataOffsets();
    if (offsets == null) return;

    final dataStart = _reader.position;
    
    // We only handle the first font's Top DICT for now if there are multiple?
    // The spec says "Objects contained within this INDEX correspond to those in the Name INDEX".
    // So if we have 1 font, we have 1 Top DICT.
    
    for (final offset in offsets) {
      _reader.seek(dataStart + offset.startOffset - 1);
      _topDic = readDICTData(offset.len);
      // We only support one font for now, so we break or overwrite
      break; 
    }
  }

  void readStringIndex() {
    final offsets = readIndexDataOffsets();
    if (offsets == null) return;

    final dataStart = _reader.position;
    final strings = <String>[];

    for (final offset in offsets) {
      _reader.seek(dataStart + offset.startOffset - 1);
      final bytes = _reader.readBytes(offset.len);
      strings.add(utf8.decode(bytes, allowMalformed: true));
    }
    _cff1FontSet.uniqueStringTable = strings;
  }

  String? getSid(int sid) {
    if (sid < Cff1FontSet.nStdStrings) {
      return Cff1FontSet.stdStrings[sid];
    } else {
      final index = sid - Cff1FontSet.nStdStrings;
      if (index < _cff1FontSet.uniqueStringTable.length) {
        return _cff1FontSet.uniqueStringTable[index];
      }
      return null;
    }
  }

  List<CffDataDicEntry> readDICTData(int len) {
    final endBefore = _reader.position + len;
    final dicData = <CffDataDicEntry>[];
    
    while (_reader.position < endBefore) {
      dicData.add(readEntry());
    }
    return dicData;
  }

  CffDataDicEntry readEntry() {
    final entry = CffDataDicEntry();
    final operands = <CffOperand>[];

    while (true) {
      final b0 = _reader.readByte();
      
      if (b0 >= 0 && b0 <= 21) {
        // Operator
        entry.operator = readOperator(b0);
        break;
      } else if (b0 == 28 || b0 == 29) {
        final num = readIntegerNumber(b0);
        operands.add(CffOperand(num.toDouble(), OperandKind.intNumber));
      } else if (b0 == 30) {
        final num = readRealNumber();
        operands.add(CffOperand(num, OperandKind.realNumber));
      } else if (b0 >= 32 && b0 <= 254) {
        final num = readIntegerNumber(b0);
        operands.add(CffOperand(num.toDouble(), OperandKind.intNumber));
      } else {
        throw FormatException('Invalid DICT data b0 byte: $b0');
      }
    }
    entry.operands = operands;
    return entry;
  }

  CFFOperator? readOperator(int b0) {
    int b1 = 0;
    if (b0 == 12) {
      b1 = _reader.readByte();
    }
    return CFFOperator.getOperatorByKey(b0, b1);
  }

  int readIntegerNumber(int b0) {
    if (b0 == 28) {
      return _reader.readInt16();
    } else if (b0 == 29) {
      return _reader.readInt32();
    } else if (b0 >= 32 && b0 <= 246) {
      return b0 - 139;
    } else if (b0 >= 247 && b0 <= 250) {
      final b1 = _reader.readByte();
      return (b0 - 247) * 256 + b1 + 108;
    } else if (b0 >= 251 && b0 <= 254) {
      final b1 = _reader.readByte();
      return -(b0 - 251) * 256 - b1 - 108;
    } else {
      throw FormatException('Invalid integer number prefix: $b0');
    }
  }

  double readRealNumber() {
    final sb = StringBuffer();
    bool done = false;
    bool exponentMissing = false;

    while (!done) {
      final b = _reader.readByte();
      final nibbles = [(b >> 4) & 0xf, b & 0xf];

      for (final nibble in nibbles) {
        if (done) break;
        
        switch (nibble) {
          case 0x0:
          case 0x1:
          case 0x2:
          case 0x3:
          case 0x4:
          case 0x5:
          case 0x6:
          case 0x7:
          case 0x8:
          case 0x9:
            sb.write(nibble);
            exponentMissing = false;
            break;
          case 0xa:
            sb.write('.');
            break;
          case 0xb:
            sb.write('E');
            exponentMissing = true;
            break;
          case 0xc:
            sb.write('E-');
            exponentMissing = true;
            break;
          case 0xd:
            // reserved
            break;
          case 0xe:
            sb.write('-');
            break;
          case 0xf:
            done = true;
            break;
        }
      }
    }
    
    if (exponentMissing) {
      sb.write('0');
    }
    
    if (sb.isEmpty) return 0.0;
    return double.tryParse(sb.toString()) ?? 0.0;
  }

  void resolveTopDictInfo() {
    final topDic = _topDic;
    if (topDic == null) return;

    for (final entry in topDic) {
      final op = entry.operator;
      if (op == null) continue;
      final operands = entry.operands;
      if (operands.isEmpty) continue;

      switch (op.name) {
        case "version":
          _currentCff1Font.version = getSid(operands[0].realNumValue.toInt());
          break;
        case "Notice":
          _currentCff1Font.notice = getSid(operands[0].realNumValue.toInt());
          break;
        case "Copyright":
          _currentCff1Font.copyRight = getSid(operands[0].realNumValue.toInt());
          break;
        case "FullName":
          _currentCff1Font.fullName = getSid(operands[0].realNumValue.toInt());
          break;
        case "FamilyName":
          _currentCff1Font.familyName = getSid(operands[0].realNumValue.toInt());
          break;
        case "Weight":
          _currentCff1Font.weight = getSid(operands[0].realNumValue.toInt());
          break;
        case "UnderlinePosition":
          _currentCff1Font.underlinePosition = operands[0].realNumValue;
          break;
        case "UnderlineThickness":
          _currentCff1Font.underlineThickness = operands[0].realNumValue;
          break;
        case "FontBBox":
          if (operands.length >= 4) {
            _currentCff1Font.fontBBox = [
              operands[0].realNumValue,
              operands[1].realNumValue,
              operands[2].realNumValue,
              operands[3].realNumValue
            ];
          }
          break;
        case "CharStrings":
          _charStringsOffset = operands[0].realNumValue.toInt();
          break;
        case "charset":
          _charsetOffset = operands[0].realNumValue.toInt();
          break;
        case "Encoding":
          _encodingOffset = operands[0].realNumValue.toInt();
          break;
        case "Private":
          if (operands.length >= 2) {
            _privateDICTLen = operands[0].realNumValue.toInt();
            _privateDICTOffset = operands[1].realNumValue.toInt();
          }
          break;
        case "ROS":
          if (operands.length >= 3) {
            _rosRegister = getSid(operands[0].realNumValue.toInt());
            _rosOrdering = getSid(operands[1].realNumValue.toInt());
            _rosSupplement = getSid(operands[2].realNumValue.toInt());
          }
          break;
        case "CIDFontVersion":
          _cidFontVersion = operands[0].realNumValue;
          break;
        case "CIDCount":
          _cidFontCount = operands[0].realNumValue.toInt();
          break;
        case "FDSelect":
          _fdSelect = operands[0].realNumValue.toInt();
          break;
        case "FDArray":
          _fdArray = operands[0].realNumValue.toInt();
          break;
      }
    }
  }

  void readGlobalSubrIndex() {
    _currentCff1Font.globalSubrRawBufferList = readSubrBuffer();
  }

  List<List<int>>? readSubrBuffer() {
    final offsets = readIndexDataOffsets();
    if (offsets == null) return null;

    final dataStart = _reader.position;
    final buffers = <List<int>>[];

    for (final offset in offsets) {
      _reader.seek(dataStart + offset.startOffset - 1);
      buffers.add(_reader.readBytes(offset.len));
    }
    return buffers;
  }

  void readFDSelect() {
    if (_fdSelect == 0) return;
    
    _reader.seek(_cffStartAt + _fdSelect);
    final format = _reader.readByte();
    
    if (format == 3) {
      final nRanges = _reader.readUInt16();
      final ranges = <FDRange3>[];
      
      for (var i = 0; i < nRanges; i++) {
        ranges.add(FDRange3(_reader.readUInt16(), _reader.readByte()));
      }
      // Sentinel
      ranges.add(FDRange3(_reader.readUInt16(), 0));
      
      _fdSelectFormat = 3;
      _fdRanges = ranges;
    } else {
      // Format 0 not implemented yet
    }
  }

  void readFDArray() {
    if (_fdArray == 0) return;
    
    _reader.seek(_cffStartAt + _fdArray);
    final offsets = readIndexDataOffsets();
    if (offsets == null) return;
    
    final dataStart = _reader.position;
    final fontDicts = <FontDict>[];
    _currentCff1Font.cidFontDict = fontDicts;
    
    for (final offset in offsets) {
      _reader.seek(dataStart + offset.startOffset - 1);
      final dic = readDICTData(offset.len);
      
      int name = 0;
      int size = 0;
      int dictOffset = 0;
      
      for (final entry in dic) {
        if (entry.operator?.name == "FontName") {
          name = entry.operands[0].realNumValue.toInt();
        } else if (entry.operator?.name == "Private") {
          size = entry.operands[0].realNumValue.toInt();
          dictOffset = entry.operands[1].realNumValue.toInt();
        }
      }
      
      final fontDict = FontDict(size, dictOffset);
      fontDict.fontName = name;
      fontDicts.add(fontDict);
    }
    
    for (final fdict in fontDicts) {
      _reader.seek(_cffStartAt + fdict.privateDicOffset);
      final dicData = readDICTData(fdict.privateDicSize);
      
      for (final entry in dicData) {
        if (entry.operator?.name == "Subrs") {
          final localSubrsOffset = entry.operands[0].realNumValue.toInt();
          _reader.seek(_cffStartAt + fdict.privateDicOffset + localSubrsOffset);
          fdict.localSubr = readSubrBuffer();
        }
      }
    }
  }

  void readPrivateDict() {
    if (_privateDICTLen == 0) return;
    
    _reader.seek(_cffStartAt + _privateDICTOffset);
    final dicData = readDICTData(_privateDICTLen);
    
    for (final entry in dicData) {
      switch (entry.operator?.name) {
        case "Subrs":
          final localSubrsOffset = entry.operands[0].realNumValue.toInt();
          _reader.seek(_cffStartAt + _privateDICTOffset + localSubrsOffset);
          _currentCff1Font.localSubrRawBufferList = readSubrBuffer();
          break;
        case "defaultWidthX":
          _currentCff1Font.defaultWidthX = entry.operands[0].realNumValue.toInt();
          break;
        case "nominalWidthX":
          _currentCff1Font.nominalWidthX = entry.operands[0].realNumValue.toInt();
          break;
      }
    }
  }

  void readCharStringsIndex() {
    _reader.seek(_cffStartAt + _charStringsOffset);
    final offsets = readIndexDataOffsets();
    if (offsets == null) return;
    
    final dataStart = _reader.position;
    final glyphCount = offsets.length;
    
    final parser = Type2CharStringParser();
    parser.setCurrentCff1Font(_currentCff1Font);
    
    // Create a default FontDict for simple fonts
    final simpleFontDict = FontDict(0, 0);
    simpleFontDict.localSubr = _currentCff1Font.localSubrRawBufferList;

    for (var i = 0; i < glyphCount; i++) {
      final offset = offsets[i];
      _reader.seek(dataStart + offset.startOffset - 1);
      final buffer = _reader.readBytes(offset.len);
      
      final glyphData = Cff1GlyphData();
      glyphData.glyphIndex = i;
      
      // Set the correct FontDict for this glyph
      if (_currentCff1Font.cidFontDict != null && _fdRanges != null) {
        // Find FD index for this glyph
        int fdIndex = 0;
        for (final range in _fdRanges!) {
          if (i >= range.first) {
            fdIndex = range.fd;
          } else {
            break;
          }
        }
        if (fdIndex < _currentCff1Font.cidFontDict!.length) {
          parser.setCidFontDict(_currentCff1Font.cidFontDict![fdIndex]);
        }
      } else {
        parser.setCidFontDict(simpleFontDict);
      }

      final instructions = parser.parseType2CharString(buffer);
      glyphData.glyphInstructions = instructions.instructions;
      
      final glyph = Glyph.cff(
        glyphIndex: i,
        cffGlyphData: glyphData,
      );
      
      _currentCff1Font.glyphs.add(glyph);
    }
  }

  void readCharsets() {
    if (_charsetOffset == 0) return;
    _reader.seek(_cffStartAt + _charsetOffset);
    
    final format = _reader.readByte();
    final glyphs = _currentCff1Font.glyphs;
    final nGlyphs = glyphs.length;
    
    if (format == 0) {
      for (var i = 1; i < nGlyphs; i++) {
        final sid = _reader.readUInt16();
        final glyph = glyphs[i];
        final data = glyph.cffGlyphData as Cff1GlyphData?;
        if (data != null) {
          data.sidName = sid;
          data.name = getSid(sid);
        }
      }
    } else if (format == 1) {
      var i = 1;
      while (i < nGlyphs) {
        var sid = _reader.readUInt16();
        var count = _reader.readByte() + 1;
        while (count > 0 && i < nGlyphs) {
          final glyph = glyphs[i];
          final data = glyph.cffGlyphData as Cff1GlyphData?;
          if (data != null) {
            data.sidName = sid;
            data.name = getSid(sid);
          }
          i++;
          sid++;
          count--;
        }
      }
    } else if (format == 2) {
      var i = 1;
      while (i < nGlyphs) {
        var sid = _reader.readUInt16();
        var count = _reader.readUInt16() + 1;
        while (count > 0 && i < nGlyphs) {
          final glyph = glyphs[i];
          final data = glyph.cffGlyphData as Cff1GlyphData?;
          if (data != null) {
            data.sidName = sid;
            data.name = getSid(sid);
          }
          i++;
          sid++;
          count--;
        }
      }
    }
  }

  void readEncodings() {
    // TODO: Implement encoding reading
  }
}

class FDRange3 {
  final int first;
  final int fd;
  FDRange3(this.first, this.fd);
}
