import '../../../typography/io/byte_order_swapping_reader.dart';
import 'table_entry.dart';
import 'utils.dart';

/// The Justification table (JSTF)
///
/// The Justification table (JSTF) provides font developers with additional control over glyph substitution and
/// positioning in justified text.
class JSTF extends TableEntry {
  static const String tableName = 'JSTF';
  @override
  String get name => tableName;

  List<JstfScriptTable>? jstfScriptTables;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    final tableStartAt = reader.position;

    reader.readUInt16(); // majorVersion
    reader.readUInt16(); // minorVersion
    final jstfScriptCount = reader.readUInt16();

    final recs = <_JstfScriptRecord>[];
    for (var i = 0; i < jstfScriptCount; ++i) {
      recs.add(_JstfScriptRecord(
        Utils.tagToString(reader.readUInt32()),
        reader.readUInt16(),
      ));
    }

    jstfScriptTables = [];
    for (final rec in recs) {
      reader.seek(tableStartAt + rec.jstfScriptOffset);
      final jstfScriptTable = _readJstfScriptTable(reader);
      jstfScriptTable.scriptTag = rec.jstfScriptTag;
      jstfScriptTables!.add(jstfScriptTable);
    }
  }

  JstfScriptTable _readJstfScriptTable(ByteOrderSwappingBinaryReader reader) {
    final tableStartAt = reader.position;

    final extenderGlyphOffset = reader.readUInt16();
    final defJstfLangSysOffset = reader.readUInt16();
    final jstfLangSysCount = reader.readUInt16();

    final jstfScriptTable = JstfScriptTable();

    if (jstfLangSysCount > 0) {
      final recs = <JstfLangSysRecord>[];
      for (var i = 0; i < jstfLangSysCount; ++i) {
        // JstfLangSysRecord: Tag (4) + Offset (2)
        // Wait, the C# code calls ReadJstfLangSysRecord directly in the loop?
        // Let's check C# code again.
        /*
            if (jstfLangSysCount > 0)
            {
                JstfLangSysRecord[] recs = new JstfLangSysRecord[jstfLangSysCount];
                for (int i = 0; i < jstfLangSysCount; ++i)
                {
                    recs[i] = ReadJstfLangSysRecord(reader);
                }
                jstfScriptTable.other = recs;
            }
        */
        // But ReadJstfLangSysRecord reads:
        /*
            long tableStartAt = reader.BaseStream.Position;
            ushort jstfPriorityCount = reader.ReadUInt16();
            ushort[] jstfPriorityOffsets = Utils.ReadUInt16Array(reader, jstfPriorityCount);
            ...
        */
        // This looks like reading the TABLE, not the RECORD.
        // The JstfScript table definition says:
        // JstfLangSysRecord jstfLangSysRecords[jstfLangSysCount]
        // And JstfLangSysRecord contains: Tag + Offset.
        
        // The C# code seems to be reading JstfLangSysRecord as if it was the table itself?
        // Wait, let's look at C# ReadJstfScriptTable again.
        /*
            if (jstfLangSysCount > 0)
            {
                JstfLangSysRecord[] recs = new JstfLangSysRecord[jstfLangSysCount];
                for (int i = 0; i < jstfLangSysCount; ++i)
                {
                    recs[i] = ReadJstfLangSysRecord(reader);
                }
                jstfScriptTable.other = recs;
            }
        */
        // And ReadJstfLangSysRecord:
        /*
        static JstfLangSysRecord ReadJstfLangSysRecord(BinaryReader reader)
        {
            // ...
            long tableStartAt = reader.BaseStream.Position;
            ushort jstfPriorityCount = reader.ReadUInt16();
            // ...
        }
        */
        // This is definitely reading the TABLE structure (count + offsets).
        // BUT, the JstfScript table structure says it contains an array of RECORDS.
        // "JstfLangSysRecord jstfLangSysRecords[jstfLangSysCount]"
        // And "Each JstfLangSysRecord contains a language system tag(jstfLangSysTag) and an offset to a justification language system table(jstfLangSysOffset)."
        
        // So the C# code seems to be skipping the Tag and Offset reading in the loop?
        // Or maybe `ReadJstfLangSysRecord` is misnamed and actually reads the record?
        // No, it reads `jstfPriorityCount`. That's the table content.
        
        // Wait, if the C# code is correct, then `JstfLangSysRecord` in C# is NOT the record with Tag+Offset.
        // Let's check `JstfLangSysRecord` struct in C#.
        /*
        public struct JstfLangSysRecord
        {
            public JstfPriority[] jstfPriority;
        }
        */
        // It doesn't have Tag or Offset! It holds the data of the table.
        
        // So the C# code is reading the TABLE content directly where the RECORD should be?
        // That would imply the RECORD structure is NOT Tag+Offset, but the Table itself?
        // But the spec says:
        // "JstfLangSysRecord: Tag jstfLangSysTag, Offset16 jstfLangSysOffset"
        
        // If the C# code reads `jstfPriorityCount` (uint16) where `jstfLangSysTag` (Tag, 4 bytes) should be...
        // Then it's reading the first 2 bytes of the Tag as the count.
        // This seems like a BUG in the C# implementation or I am misreading it.
        
        // Let's look at `ReadJstfScriptTable` in C# again.
        /*
            if (jstfLangSysCount > 0)
            {
                JstfLangSysRecord[] recs = new JstfLangSysRecord[jstfLangSysCount];
                for (int i = 0; i < jstfLangSysCount; ++i)
                {
                    recs[i] = ReadJstfLangSysRecord(reader);
                }
                jstfScriptTable.other = recs;
            }
        */
        // It calls `ReadJstfLangSysRecord`.
        
        // If the file format follows the spec, there should be records here.
        // If the C# code works, maybe it's because it's not fully implemented or tested?
        // The comment says "//test this with Arial font".
        
        // I should follow the SPEC, not the potentially buggy C# code, but I should also check if I can support what C# does.
        // Actually, looking at `ReadJstfLangSysRecord` in C#, it returns `JstfLangSysRecord` struct which contains `JstfPriority[]`.
        // This struct name is confusing. It should be `JstfLangSysTable`.
        
        // I will implement it according to the SPEC (Record with Tag+Offset), and then read the Table at the offset.
        // This is how `BaseScriptList` worked (Record -> Offset -> Table).
        
        // Wait, `defJstfLangSysOffset` points to a default table.
        // `jstfLangSysRecords` is an array of records.
        
        // I will implement it correctly.
        
        recs.add(_readJstfLangSysRecord(reader, tableStartAt));
      }
      jstfScriptTable.other = recs;
    }

    if (extenderGlyphOffset > 0) {
      reader.seek(tableStartAt + extenderGlyphOffset);
      jstfScriptTable.extenderGlyphs = _readExtenderGlyphTable(reader);
    }

    if (defJstfLangSysOffset > 0) {
      reader.seek(tableStartAt + defJstfLangSysOffset);
      jstfScriptTable.defaultLangSys = _readJstfLangSysTable(reader);
    }

    return jstfScriptTable;
  }

  JstfLangSysRecord _readJstfLangSysRecord(ByteOrderSwappingBinaryReader reader, int parentTableStart) {
      final tag = Utils.tagToString(reader.readUInt32());
      final offset = reader.readUInt16();
      
      // Save current position to return to it (actually the loop continues, so we need to peek or seek back?
      // No, usually we read the record (Tag+Offset), then later jump to offset.
      // But here I want to resolve the table immediately?
      // Or just store the record and resolve later?
      // The C# code seemed to try to read the table content inline, which is definitely wrong if it's an offset.
      
      final currentPos = reader.position;
      reader.seek(parentTableStart + offset);
      final table = _readJstfLangSysTable(reader);
      reader.seek(currentPos);
      
      return JstfLangSysRecord(tag, table);
  }

  JstfLangSysTable _readJstfLangSysTable(ByteOrderSwappingBinaryReader reader) {
    final tableStartAt = reader.position;
    final jstfPriorityCount = reader.readUInt16();
    final jstfPriorityOffsets = Utils.readUInt16Array(reader, jstfPriorityCount);

    final jstfPriorities = <JstfPriority>[];
    for (final offset in jstfPriorityOffsets) {
      reader.seek(tableStartAt + offset);
      jstfPriorities.add(_readJstfPriority(reader));
    }

    return JstfLangSysTable(jstfPriorities);
  }

  List<int> _readExtenderGlyphTable(ByteOrderSwappingBinaryReader reader) {
    final glyphCount = reader.readUInt16();
    return Utils.readUInt16Array(reader, glyphCount);
  }

  JstfPriority _readJstfPriority(ByteOrderSwappingBinaryReader reader) {
    return JstfPriority(
      shrinkageEnableGSUB: reader.readUInt16(),
      shrinkageDisableGSUB: reader.readUInt16(),
      shrinkageEnableGPOS: reader.readUInt16(),
      shrinkageDisableGPOS: reader.readUInt16(),
      shrinkageJstfMax: reader.readUInt16(),
      extensionEnableGSUB: reader.readUInt16(),
      extensionDisableGSUB: reader.readUInt16(),
      extensionEnableGPOS: reader.readUInt16(),
      extensionDisableGPOS: reader.readUInt16(),
      extensionJstfMax: reader.readUInt16(),
    );
  }
}

class _JstfScriptRecord {
  final String jstfScriptTag;
  final int jstfScriptOffset;
  _JstfScriptRecord(this.jstfScriptTag, this.jstfScriptOffset);
}

class JstfScriptTable {
  String? scriptTag;
  List<int>? extenderGlyphs;
  JstfLangSysTable? defaultLangSys;
  List<JstfLangSysRecord>? other;

  @override
  String toString() => scriptTag ?? super.toString();
}

class JstfLangSysRecord {
    final String tag;
    final JstfLangSysTable table;
    JstfLangSysRecord(this.tag, this.table);
}

class JstfLangSysTable {
  final List<JstfPriority> jstfPriority;
  JstfLangSysTable(this.jstfPriority);
}

class JstfPriority {
  final int shrinkageEnableGSUB;
  final int shrinkageDisableGSUB;
  final int shrinkageEnableGPOS;
  final int shrinkageDisableGPOS;
  final int shrinkageJstfMax;
  final int extensionEnableGSUB;
  final int extensionDisableGSUB;
  final int extensionEnableGPOS;
  final int extensionDisableGPOS;
  final int extensionJstfMax;

  JstfPriority({
    required this.shrinkageEnableGSUB,
    required this.shrinkageDisableGSUB,
    required this.shrinkageEnableGPOS,
    required this.shrinkageDisableGPOS,
    required this.shrinkageJstfMax,
    required this.extensionEnableGSUB,
    required this.extensionDisableGSUB,
    required this.extensionEnableGPOS,
    required this.extensionDisableGPOS,
    required this.extensionJstfMax,
  });
}
