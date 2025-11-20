import 'dart:collection';
import '../../../typography/io/byte_order_swapping_reader.dart';
import 'script_table.dart';
import 'utils.dart';

class ScriptList extends MapBase<String, ScriptTable> {
  final Map<String, ScriptTable> _map = {};

  // https://www.microsoft.com/typography/otspec/chapter2.htm
  // The ScriptList identifies the scripts in a font,
  // each of which is represented by a Script table that contains script and language-system data.
  // Language system tables reference features, which are defined in the FeatureList.
  // Each feature table references the lookup data defined in the LookupList that describes how, when, and where to implement the feature.

  ScriptList();

  @override
  ScriptTable? operator [](Object? key) => _map[key];

  @override
  void operator []=(String key, ScriptTable value) => _map[key] = value;

  @override
  void clear() => _map.clear();

  @override
  Iterable<String> get keys => _map.keys;

  @override
  ScriptTable? remove(Object? key) => _map.remove(key);

  static ScriptList createFrom(
      ByteOrderSwappingBinaryReader reader, int beginAt) {
    // https://www.microsoft.com/typography/otspec/chapter2.htm
    //
    // ScriptList table
    // Type    Name                      Description
    // uint16  ScriptCount               Number of ScriptRecords
    // struct  ScriptRecord[ScriptCount] Array of ScriptRecords
    //                                   -listed alphabetically by ScriptTag
    // ScriptRecord
    // Type      Name       Description
    // Tag       ScriptTag  4-byte ScriptTag identifier
    // Offset16  Script     Offset to Script table-from beginning of ScriptList

    reader.seek(beginAt);
    int scriptCount = reader.readUInt16();

    ScriptList scriptList = ScriptList();

    // Read records (tags and table offsets)
    List<int> scriptTags = List<int>.filled(scriptCount, 0);
    List<int> scriptOffsets = List<int>.filled(scriptCount, 0);

    for (int i = 0; i < scriptCount; ++i) {
      scriptTags[i] = reader.readUInt32();
      scriptOffsets[i] = reader.readUInt16();
    }

    // Read each table and add it to the dictionary
    for (int i = 0; i < scriptCount; ++i) {
      ScriptTable scriptTable =
          ScriptTable.createFrom(reader, beginAt + scriptOffsets[i]);
      scriptTable.scriptTag = scriptTags[i];

      scriptList[Utils.tagToString(scriptTags[i])] = scriptTable;
    }

    return scriptList;
  }
}
