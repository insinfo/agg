// Apache2, 2017-present, WinterDev
// Apache2, 2014-2016, Samuel Carlsson, WinterDev
// Ported to Dart by insinfo

import '../../../typography/io/byte_order_swapping_reader.dart';

/// Base class for all top-level font tables
abstract class TableEntry {
  TableHeader? _header;

  TableEntry();

  TableHeader? get header => _header;
  
  set header(TableHeader? value) => _header = value;

  /// Read the table content from the binary reader
  /// This method should be implemented by each specific table
  void readContentFrom(ByteOrderSwappingBinaryReader reader);

  /// The name/tag of this table (e.g., 'head', 'maxp', 'cmap')
  String get name;

  /// Load data from the reader by seeking to the table's offset
  void loadDataFrom(ByteOrderSwappingBinaryReader reader) {
    if (_header == null) {
      throw StateError('TableHeader is not set');
    }
    reader.seek(_header!.offset);
    readContentFrom(reader);
  }

  /// Get the length of the table data
  int get tableLength => _header?.length ?? 0;
}

/// Represents a table that hasn't been read yet
class UnreadTableEntry extends TableEntry {
  UnreadTableEntry(TableHeader header) {
    this.header = header;
  }

  @override
  String get name => header?.tagName ?? '';

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    // Intentionally not implemented - this table is unread
    throw UnimplementedError('Cannot read content of UnreadTableEntry');
  }

  bool hasCustomContentReader = false;

  T createTableEntry<T extends TableEntry>(
    ByteOrderSwappingBinaryReader reader,
    T expectedResult,
  ) {
    throw UnimplementedError();
  }

  @override
  String toString() => name;
}

/// Header information for a font table
class TableHeader {
  final int tag;
  final int checkSum;
  final int offset;
  final int length;
  final String tagName;

  TableHeader({
    required this.tag,
    required this.checkSum,
    required this.offset,
    required this.length,
  }) : tagName = _tagToString(tag);

  TableHeader.fromString({
    required String tag,
    required this.checkSum,
    required this.offset,
    required this.length,
  })  : tag = 0,
        tagName = tag;

  /// Convert a 4-byte tag (as uint32) to a string
  static String _tagToString(int tag) {
    final bytes = <int>[
      (tag >> 24) & 0xFF,
      (tag >> 16) & 0xFF,
      (tag >> 8) & 0xFF,
      tag & 0xFF,
    ];
    return String.fromCharCodes(bytes);
  }

  @override
  String toString() => '{$tagName}';
}

/// Collection of font tables indexed by their tag/name
class TableEntryCollection {
  final Map<String, TableEntry> _tables = {};

  TableEntryCollection();

  /// Add a table entry to the collection
  void addEntry(TableEntry entry) {
    _tables[entry.name] = entry;
  }

  /// Try to get a table by name
  TableEntry? tryGetTable(String tableName) {
    return _tables[tableName];
  }

  /// Replace an existing table entry
  void replaceTable(TableEntry table) {
    _tables[table.name] = table;
  }

  /// Check if a table exists
  bool hasTable(String tableName) {
    return _tables.containsKey(tableName);
  }

  /// Get all table names
  Iterable<String> get tableNames => _tables.keys;

  /// Get number of tables
  int get count => _tables.length;
}
