import '../../../typography/io/byte_order_swapping_reader.dart';
import 'utils.dart';

/// Script Table and Language System Record
/// A Script table identifies each language system that defines how to use the glyphs in a script for a particular language.
class ScriptTable {
  LangSysTable? defaultLang;
  late List<LangSysTable> langSysTables;
  late int scriptTag;

  String get scriptTagName => Utils.tagToString(scriptTag);

  ScriptTable();

  static ScriptTable createFrom(
      ByteOrderSwappingBinaryReader reader, int beginAt) {
    reader.seek(beginAt);
    //---------------
    //Script table
    //Type 	    Name 	        Description
    //Offset16 	DefaultLangSys 	Offset to DefaultLangSys table-from beginning of Script table-may be NULL
    //uint16 	LangSysCount 	Number of LangSysRecords for this script-excluding the DefaultLangSys
    //struct 	LangSysRecord[LangSysCount] 	Array of LangSysRecords-listed alphabetically by LangSysTag
    //---------------
    ScriptTable scriptTable = ScriptTable();
    int defaultLangSysOffset = reader.readUInt16();
    int langSysCount = reader.readUInt16();

    scriptTable.langSysTables = List<LangSysTable>.generate(langSysCount, (i) {
      //-----------------------
      //LangSysRecord
      //Type 	    Name 	    Description
      //Tag 	    LangSysTag 	4-byte LangSysTag identifier
      //Offset16 	LangSys 	Offset to LangSys table-from beginning of Script table
      //-----------------------
      return LangSysTable(
          reader.readUInt32(), // 4-byte LangSysTag identifier
          reader.readUInt16() // offset
          );
    });

    //-----------
    if (defaultLangSysOffset > 0) {
      scriptTable.defaultLang = LangSysTable(0, defaultLangSysOffset);
      reader.seek(beginAt + defaultLangSysOffset);
      scriptTable.defaultLang!.readFrom(reader);
    }

    //-----------
    //read actual content of each table
    for (int i = 0; i < langSysCount; ++i) {
      LangSysTable langSysTable = scriptTable.langSysTables[i];
      reader.seek(beginAt + langSysTable.offset);
      langSysTable.readFrom(reader);
    }

    return scriptTable;
  }

  @override
  String toString() {
    return Utils.tagToString(scriptTag);
  }
}

class LangSysTable {
  //The Language System table (LangSys) identifies language-system features
  //used to render the glyphs in a script. (The LookupOrder offset is reserved for future use.)
  //
  final int langSysTagIden;
  final int offset;

  //
  late List<int> featureIndexList;
  late int requireFeatureIndex;

  LangSysTable(this.langSysTagIden, this.offset);

  void readFrom(ByteOrderSwappingBinaryReader reader) {
    //---------------------
    //LangSys table
    //Type 	    Name 	        Description
    //Offset16 	LookupOrder 	= NULL (reserved for an offset to a reordering table)
    //uint16 	ReqFeatureIndex Index of a feature required for this language system- if no required features = 0xFFFF
    //uint16 	FeatureCount 	Number of FeatureIndex values for this language system-excludes the required feature
    //uint16 	FeatureIndex[FeatureCount] 	Array of indices into the FeatureList-in arbitrary order
    //---------------------
    reader.readUInt16(); // lookupOrder (reserved)
    requireFeatureIndex = reader.readUInt16();
    int featureCount = reader.readUInt16();
    featureIndexList = Utils.readUInt16Array(reader, featureCount);
  }

  bool get hasRequireFeature => requireFeatureIndex != 0xFFFF;

  @override
  String toString() {
    return Utils.tagToString(langSysTagIden);
  }
}
