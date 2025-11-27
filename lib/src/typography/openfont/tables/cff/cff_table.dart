import '../../../io/byte_order_swapping_reader.dart';
import '../table_entry.dart';
import '../utils.dart';
import 'cff_objects.dart';
import 'cff_parser.dart';

/// CFF (Compact Font Format) table.
class CFFTable extends TableEntry {
  static const String tableName = 'CFF ';
  @override
  String get name => tableName;

  Cff1FontSet? _cff1FontSet;
  Cff1FontSet? get cff1FontSet => _cff1FontSet;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    final tableOffset = header!.offset;
    
    // Table 8 Header Format
    // Type      Name    Description
    // Card8     major   Format major version(starting at 1)
    // Card8     minor   Format minor version(starting at 0)
    // Card8     hdrSize Header size(bytes)
    // OffSize   offSize Absolute offset(0) size
    final major = reader.readByte();
    reader.readByte(); // minor
    reader.readByte(); // hdrSize
    reader.readByte(); // offSize

    switch (major) {
      case 1:
        final cff1 = Cff1Parser();
        cff1.parseAfterHeader(tableOffset, reader);
        _cff1FontSet = cff1.resultCff1FontSet;
        break;
      case 2:
        // CFF2 not yet implemented
        Utils.warnUnimplemented('CFF2 table not supported');
        break;
      default:
        throw UnimplementedError('CFF major version $major not supported');
    }
  }
}
