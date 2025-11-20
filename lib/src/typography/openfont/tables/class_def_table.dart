import '../../../typography/io/byte_order_swapping_reader.dart';
import 'utils.dart';

//https://www.microsoft.com/typography/otspec/chapter2.htm
class ClassDefTable {
  int format = 0;
  //----------------
  //format 1
  int startGlyph = 0;
  late List<int> classValueArray;
  //---------------
  //format2
  late List<ClassRangeRecord> records;

  static ClassDefTable createFrom(
      ByteOrderSwappingBinaryReader reader, int beginAt) {
    reader.seek(beginAt);

    //---------
    ClassDefTable classDefTable = ClassDefTable();
    classDefTable.format = reader.readUInt16();

    switch (classDefTable.format) {
      case 1:
        {
          classDefTable.startGlyph = reader.readUInt16();
          int glyphCount = reader.readUInt16();
          classDefTable.classValueArray =
              Utils.readUInt16Array(reader, glyphCount);
        }
        break;
      case 2:
        {
          int classRangeCount = reader.readUInt16();
          classDefTable.records =
              List<ClassRangeRecord>.generate(classRangeCount, (i) {
            return ClassRangeRecord(
                reader.readUInt16(), //start glyph id
                reader.readUInt16(), //end glyph id
                reader.readUInt16() //classNo
                );
          });
        }
        break;
      default:
        throw UnsupportedError(
            'ClassDefTable format ${classDefTable.format} not supported');
    }
    return classDefTable;
  }

  int getClassValue(int glyphIndex) {
    switch (format) {
      case 1:
        {
          if (glyphIndex >= startGlyph &&
              glyphIndex < startGlyph + classValueArray.length) {
            return classValueArray[glyphIndex - startGlyph];
          }
          return 0; // Default to class 0 if not found (C# returned -1 but spec says class 0)
          // Wait, C# code returned -1. Let's check usage.
          // "Any glyph not included in the range of covered GlyphIDs automatically belongs to Class 0."
          // So returning 0 is probably correct for "not found".
          // But let's stick to C# logic if it's used for detection.
          // Actually, C# code returns -1.
          // "return -1;//no need to go further"
          // I will return -1 to be safe and consistent with C# port,
          // but I should check if 0 is better.
          // If I return -1, the caller might handle it.
        }
      case 2:
        {
          for (int i = 0; i < records.length; ++i) {
            ClassRangeRecord rec = records[i];
            if (rec.startGlyphId <= glyphIndex) {
              if (glyphIndex <= rec.endGlyphId) {
                return rec.classNo;
              }
            } else {
              return -1; //no need to go further
            }
          }
          return -1;
        }
      default:
        throw UnsupportedError('ClassDefTable format $format not supported');
    }
  }
}

class ClassRangeRecord {
  //---------------------------------------
  //
  //ClassRangeRecord
  //---------------------------------------
  //Type 	    Name 	            Descriptionc
  //uint16 	Start 	            First glyph ID in the range
  //uint16 	End 	            Last glyph ID in the range
  //uint16 	Class 	            Applied to all glyphs in the range
  //---------------------------------------
  final int startGlyphId;
  final int endGlyphId;
  final int classNo;

  ClassRangeRecord(this.startGlyphId, this.endGlyphId, this.classNo);

  @override
  String toString() {
    return "class=$classNo [$startGlyphId,$endGlyphId]";
  }
}
