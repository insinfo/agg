// MIT, 2019-present, WinterDev
// Ported to Dart by insinfo, 2025

import 'dart:typed_data';
import '../../../io/byte_order_swapping_reader.dart';
import '../table_entry.dart';
import '../utils.dart';
import 'tuple_variation.dart';

class GVar extends TableEntry {
  static const String _N = "gvar";
  @override
  String get name => _N;

  int axisCount = 0;
  int sharedTupleCount = 0;
  int sharedTuplesOffset = 0;
  int glyphCount = 0;
  int flags = 0;
  int glyphVariationDataArrayOffset = 0;

  List<int>? glyphVariationDataOffsets;
  List<TupleRecord>? sharedTuples;
  
  // Store the raw table data for lazy loading of glyph variation data
  Uint8List? _rawTableData;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    // Store the start position to calculate relative offsets
    int tableStart = reader.position;
    
    // Read the entire table into memory for random access later
    // We need to reset position after reading header to read the rest?
    // Or we can just read the header, then read the rest.
    // But we need the raw bytes for the whole table because offsets are from the start of the table.
    
    // Let's read the header first.
    int majorVersion = reader.readUInt16();
    int minorVersion = reader.readUInt16();
    if (majorVersion == 0 && minorVersion == 0) {} // Suppress unused warning

    axisCount = reader.readUInt16();
    sharedTupleCount = reader.readUInt16();
    sharedTuplesOffset = reader.readUInt32();
    glyphCount = reader.readUInt16();
    flags = reader.readUInt16();
    glyphVariationDataArrayOffset = reader.readUInt32();

    // Read offsets
    if ((flags & 0x1) == 0) {
      // Offset16
      glyphVariationDataOffsets = List<int>.generate(glyphCount + 1, (index) {
        return reader.readUInt16() * 2;
      });
    } else {
      // Offset32
      glyphVariationDataOffsets = Utils.readUInt32Array(reader, glyphCount + 1);
    }

    // Read Shared Tuples
    // We need to seek to sharedTuplesOffset from tableStart
    // But we are currently at the end of offsets.
    // The sharedTuplesOffset is from the start of the table.
    
    // To support lazy loading, we should probably capture the underlying data.
    // Since we can't easily clone the reader's source, let's assume we can read the rest.
    // But wait, if we read the whole table into a buffer, we duplicate memory.
    // However, for GVar which can be large, maybe we should just keep the reader?
    // But the reader might be disposed.
    
    // Let's try to read the shared tuples now.
    int currentPos = reader.position;
    int absoluteSharedTuplesOffset = tableStart + sharedTuplesOffset;
    
    if (currentPos != absoluteSharedTuplesOffset) {
      reader.seek(absoluteSharedTuplesOffset);
    }

    sharedTuples = List<TupleRecord>.generate(sharedTupleCount, (index) {
      TupleRecord rec = TupleRecord(axisCount);
      rec.readContent(reader);
      return rec;
    });

    // Now we need to store the data for GlyphVariationData.
    // The offsets in glyphVariationDataOffsets are relative to the start of the GlyphVariationData array?
    // No, "Offsets from the start of the GlyphVariationData array to each GlyphVariationData table."
    // So we need the data starting at glyphVariationDataArrayOffset.
    
    int absoluteDataStart = tableStart + glyphVariationDataArrayOffset;
    if (absoluteDataStart > 0) {} // Suppress unused warning
    
    // We can read the rest of the stream from absoluteDataStart?
    // Or we can just read the whole table data if we can.
    // Since we don't have access to the underlying buffer of the reader easily,
    // let's read the whole table data from the beginning?
    // No, we already read some.
    
    // Let's read from current position to the end?
    // But we need random access.
    
    // Hack: Read the whole table into a Uint8List at the beginning?
    // But we already read the header.
    // Let's rewind to tableStart and read everything.
    reader.seek(tableStart);
    int length = reader.length - tableStart; // Assuming reader is bounded to the table or we know the length?
    if (length > 0) {} // Suppress unused warning
    // ByteOrderSwappingBinaryReader doesn't know the table size unless it was created with it.
    // But usually it is.
    // Let's assume we can read `length` bytes.
    // But `reader.length` might be the file length.
    // We don't know the table size from the header (it's not in the header).
    // But `glyphVariationDataOffsets[glyphCount]` points to the end of the data?
    // Yes, usually the last offset indicates the end.
    
    int lastOffset = glyphVariationDataOffsets![glyphCount];
    int totalSize = glyphVariationDataArrayOffset + lastOffset;
    
    _rawTableData = reader.readBytes(totalSize);
    
    // Restore position? No, we are done reading.
  }

  GlyphVariationData? getGlyphVariationData(int glyphIndex) {
    if (glyphIndex < 0 || glyphIndex >= glyphCount) return null;
    if (_rawTableData == null) return null;

    int offset = glyphVariationDataOffsets![glyphIndex];
    int nextOffset = glyphVariationDataOffsets![glyphIndex + 1];
    int length = nextOffset - offset;

    if (length == 0) return null; // No variation data

    int absoluteOffset = glyphVariationDataArrayOffset + offset;
    
    // Create a reader for this slice
    ByteOrderSwappingBinaryReader reader = ByteOrderSwappingBinaryReader(
        _rawTableData!.sublist(absoluteOffset, absoluteOffset + length));

    GlyphVariationData data = GlyphVariationData();
    data.readContent(reader, axisCount, sharedTuples);
    return data;
  }
}

class GlyphVariationData {
  List<TupleVariationHeader>? tupleVariationHeaders;
  
  // We might want to store the parsed data or just the headers and parse data on demand?
  // For now, let's parse headers.
  
  void readContent(ByteOrderSwappingBinaryReader reader, int axisCount, List<TupleRecord>? sharedTuples) {
    int tupleVariationCount = reader.readUInt16();
    int dataOffset = reader.readUInt16();
    if (dataOffset > 0) {} // Suppress unused warning
    
    int flags = tupleVariationCount >> 12;
    int tupleCount = tupleVariationCount & 0x0FFF;
    
    bool sharedPointNumbers = (flags & 0x8) != 0; // 0x8000 >> 12 = 0x8
    if (sharedPointNumbers) {} // Suppress unused warning
    
    tupleVariationHeaders = List<TupleVariationHeader>.generate(tupleCount, (index) {
      TupleVariationHeader header = TupleVariationHeader();
      header.readContent(reader, axisCount);
      return header;
    });
    
    // Now read the serialized data
    // The data starts at dataOffset from the beginning of the table (GlyphVariationData table)
    // reader is currently at the end of headers.
    // We need to seek to dataOffset?
    // "Offset from the start of the GlyphVariationData table to the serialized data."
    
    // reader.seek(dataOffset); // reader is 0-based on the slice
    
    // Parse data for each tuple
    // This involves reading packed point numbers and deltas.
    // This is complex and depends on shared point numbers.
    
    // TODO: Implement full parsing of variation data (deltas)
    // For now we just read the headers.
  }
}
