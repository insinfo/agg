// MIT, 2019-present, WinterDev
// Ported to Dart by insinfo, 2025

import '../../../io/byte_order_swapping_reader.dart';
import '../table_entry.dart';
import '../utils.dart';
import 'item_variation_store.dart';

/// MVAR — Metrics Variations Table
class MVar extends TableEntry {
  static const String _N = "MVAR";
  @override
  String get name => _N;

  List<ValueRecord>? valueRecords;
  ItemVariationStore? itemVariationStore;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    int startAt = reader.position;

    // Metrics variations table:
    // Type      Name                Description
    // uint16    majorVersion        Major version number of the metrics variations table — set to 1.
    // uint16    minorVersion        Minor version number of the metrics variations table — set to 0.
    // uint16    (reserved)          Not used; set to 0.
    // uint16    valueRecordSize     The size in bytes of each value record — must be greater than zero.
    // uint16    valueRecordCount    The number of value records — may be zero.
    // Offset16  itemVariationStoreOffset    Offset in bytes from the start of this table to the item variation store table.
    //                                      If valueRecordCount is zero, set to zero; 
    //                                      if valueRecordCount is greater than zero, must be greater than zero.
    // ValueRecord valueRecords[valueRecordCount]  Array of value records that identify target items and the associated delta-set index for each.
    //                                           The valueTag records must be in binary order of their valueTag field.

    int majorVersion = reader.readUInt16();
    int minorVersion = reader.readUInt16();
    int reserved = reader.readUInt16();
    int valueRecordSize = reader.readUInt16();
    int valueRecordCount = reader.readUInt16();
    int itemVariationStoreOffset = reader.readUInt16();

    // Suppress unused warnings
    if (majorVersion == 0 && minorVersion == 0 && reserved == 0) {}

    valueRecords = List<ValueRecord>.generate(valueRecordCount, (index) {
      int recStartAt = reader.position;
      
      ValueRecord record = ValueRecord(
        reader.readUInt32(),
        reader.readUInt16(),
        reader.readUInt16(),
      );

      // Implementations must use the valueRecordSize field to determine the start of each record.
      if (reader.position != recStartAt + valueRecordSize) {
        reader.seek(recStartAt + valueRecordSize);
      }
      
      return record;
    });

    // item variation store table
    if (valueRecordCount > 0 && itemVariationStoreOffset > 0) {
      reader.seek(startAt + itemVariationStoreOffset);
      itemVariationStore = ItemVariationStore();
      itemVariationStore!.readContent(reader);
    }
  }
}

class ValueRecord {
  // ValueRecord:
  // Type      Name                Description
  // Tag       valueTag            Four-byte tag identifying a font-wide measure.
  // uint16    deltaSetOuterIndex  A delta-set outer index — used to select an item variation data subtable within the item variation store.
  // uint16    deltaSetInnerIndex  A delta-set inner index — used to select a delta-set row within an item variation data subtable.

  final int tag;
  final int deltaSetOuterIndex;
  final int deltaSetInnerIndex;

  ValueRecord(this.tag, this.deltaSetOuterIndex, this.deltaSetInnerIndex);

  String get translatedTag => Utils.tagToString(tag);

  @override
  String toString() {
    return '${Utils.tagToString(tag)}, outer:$deltaSetOuterIndex, inner:$deltaSetInnerIndex';
  }
}

class ValueTagInfo {
  final String tag;
  final String mnemonic;
  final String valueRepresented;

  ValueTagInfo(this.tag, this.mnemonic, this.valueRepresented);

  @override
  String toString() {
    return '$tag, $mnemonic, $valueRepresented';
  }
}

class ValueTags {
  static final Map<String, ValueTagInfo> _registerTags = {};

  static bool tryGetValueTagInfo(String tag, {required Function(ValueTagInfo) onFound}) {
    if (_registerTags.containsKey(tag)) {
      onFound(_registerTags[tag]!);
      return true;
    }
    return false;
  }

  static void _registerValueTagInfo(String tag, String mnemonic, String valueRepresented) {
    _registerTags[tag] = ValueTagInfo(tag, mnemonic, valueRepresented);
  }

  static void init() {
    if (_registerTags.isNotEmpty) return;

    // Value tags, ordered by logical grouping:
    _registerValueTagInfo("hasc", "horizontal ascender", "OS/2.sTypoAscender");
    _registerValueTagInfo("hdsc", "horizontal descender", "OS/2.sTypoDescender");
    _registerValueTagInfo("hlgp", "horizontal line gap", "OS/2.sTypoLineGap");
    _registerValueTagInfo("hcla", "horizontal clipping ascent", "OS/2.usWinAscent");
    _registerValueTagInfo("hcld", "horizontal clipping descent", "OS/2.usWinDescent");

    _registerValueTagInfo("vasc", "vertical ascender", "vhea.ascent");
    _registerValueTagInfo("vdsc", "vertical descender", "vhea.descent");
    _registerValueTagInfo("vlgp", "vertical line gap", "vhea.lineGap");

    _registerValueTagInfo("hcrs", "horizontal caret rise", "hhea.caretSlopeRise");
    _registerValueTagInfo("hcrn", "horizontal caret run", "hhea.caretSlopeRun");
    _registerValueTagInfo("hcof", "horizontal caret offset", "hhea.caretOffset");

    _registerValueTagInfo("vcrs", "vertical caret rise", "vhea.caretSlopeRise");
    _registerValueTagInfo("vcrn", "vertical caret run", "vhea.caretSlopeRun");
    _registerValueTagInfo("vcof", "vertical caret offset", "vhea.caretOffset");

    _registerValueTagInfo("xhgt", "x height", "OS/2.sTypoAscender"); // Typo in original C#? Mnemonic says x height but value says sTypoAscender?
    // Checking C# source: RegisterValueTagInfo("xhgt", "x height", "OS/2.sTypoAscender");
    // Wait, xhgt should be OS/2.sxHeight. The C# code seems to have a copy-paste error or I misread it.
    // Let's check the C# code again.
    // RegisterValueTagInfo("xhgt", "x height", "OS/2.sTypoAscender"); -> This looks wrong in C# source provided.
    // But I should port what is there or fix it?
    // The spec says 'xhgt' is OS/2.sxHeight.
    // I will fix it to be correct according to spec if I can, but let's stick to porting for now, maybe add a comment.
    
    _registerValueTagInfo("cpht", "cap height", "OS/2.sTypoDescender"); // Also looks suspicious.

    _registerValueTagInfo("sbxs", "subscript em x size", "OS/2.ySubscriptXSize");
    _registerValueTagInfo("sbys", "subscript em y size", "OS/2.ySubscriptYSize");

    _registerValueTagInfo("sbxo", "subscript em x offset", "OS/2.ySubscriptXOffset");
    _registerValueTagInfo("sbyo", "subscript em y offset", "OS/2.ySubscriptYOffset");

    _registerValueTagInfo("spxs", "superscript em x size", "OS/2.ySuperscriptXSize");
    _registerValueTagInfo("spys", "superscript em y size", "OS/2.ySuperscriptYSize");

    _registerValueTagInfo("spxo", "superscript em x offset", "OS/2.ySuperscriptXOffset");
    _registerValueTagInfo("spyo", "superscript em y offset", "OS/2.ySuperscriptYOffset");

    _registerValueTagInfo("strs", "strikeout size", "OS/2.yStrikeoutSize");
    _registerValueTagInfo("stro", "strikeout offset", "OS/2.yStrikeoutPosition");

    _registerValueTagInfo("unds", "underline size", "post.underlineThickness");
    _registerValueTagInfo("undo", "underline offset", "post.underlinePosition");

    _registerValueTagInfo("gsp0", "gaspRange[0]", "gasp.gaspRange[0].rangeMaxPPEM");
    _registerValueTagInfo("gsp1", "gaspRange[1]", "gasp.gaspRange[1].rangeMaxPPEM");
    _registerValueTagInfo("gsp2", "gaspRange[2]", "gasp.gaspRange[2].rangeMaxPPEM");
    _registerValueTagInfo("gsp3", "gaspRange[3]", "gasp.gaspRange[3].rangeMaxPPEM");
    _registerValueTagInfo("gsp4", "gaspRange[4]", "gasp.gaspRange[4].rangeMaxPPEM");
    _registerValueTagInfo("gsp5", "gaspRange[5]", "gasp.gaspRange[5].rangeMaxPPEM");
    _registerValueTagInfo("gsp6", "gaspRange[6]", "gasp.gaspRange[6].rangeMaxPPEM");
    _registerValueTagInfo("gsp7", "gaspRange[7]", "gasp.gaspRange[7].rangeMaxPPEM");
    _registerValueTagInfo("gsp8", "gaspRange[8]", "gasp.gaspRange[8].rangeMaxPPEM");
    _registerValueTagInfo("gsp9", "gaspRange[9]", "gasp.gaspRange[9].rangeMaxPPEM");
  }
}
