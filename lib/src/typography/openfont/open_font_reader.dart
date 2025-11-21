// Apache2, 2017-present, WinterDev
// Apache2, 2014-2016, Samuel Carlsson, WinterDev
// Ported to Dart by insinfo

import 'dart:typed_data';

import '../io/byte_order_swapping_reader.dart';
import 'typeface.dart';
import 'tables/cmap.dart';
import 'tables/gdef.dart';
import 'tables/glyf.dart';
import 'tables/gpos.dart';
import 'tables/gsub.dart';
import 'tables/head.dart';
import 'tables/hhea.dart';
import 'tables/hmtx.dart';
import 'tables/loca.dart';
import 'tables/maxp.dart';
import 'tables/name_entry.dart';
import 'tables/os2.dart';
import 'tables/table_entry.dart';

/// Flags for controlling what data to read from a font file
enum ReadFlags {
  full,
  name,
  matrix,
  advancedLayout,
  variation,
}

/// Preview information about a font before fully loading it
class PreviewFontInfo {
  final String name;
  final String subFamilyName;
  final String? typographicFamilyName;
  final String? typographicSubFamilyName;
  final String? postScriptName;
  final String? uniqueFontIden;
  final String? versionString;
  
  /// For TrueType Collections, this is the offset where this font starts
  int actualStreamOffset = 0;
  
  /// For TrueType Collections, contains info about all fonts in the collection
  final List<PreviewFontInfo>? members;

  PreviewFontInfo({
    required this.name,
    required this.subFamilyName,
    this.typographicFamilyName,
    this.typographicSubFamilyName,
    this.postScriptName,
    this.uniqueFontIden,
    this.versionString,
    this.members,
  });

  @override
  String toString() => name;
}

/// Known font file formats
class KnownFontFiles {
  /// Check if this is a TrueType Collection format
  static bool isTtcf(int majorVersion, int minorVersion) {
    // 'ttcf' in big-endian is 0x74746366
    // When read as version numbers it's different
    return majorVersion == 0x7474 && minorVersion == 0x6366;
  }

  /// Check if this is WOFF format
  static bool isWoff(int majorVersion, int minorVersion) {
    // 'wOFF' in big-endian
    return majorVersion == 0x774F && minorVersion == 0x4646;
  }

  /// Check if this is WOFF2 format
  static bool isWoff2(int majorVersion, int minorVersion) {
    // 'wOF2' in big-endian
    return majorVersion == 0x774F && minorVersion == 0x4632;
  }
}

/// Header for TrueType Collection (TTC) format
class FontCollectionHeader {
  int majorVersion = 0;
  int minorVersion = 0;
  int numFonts = 0;
  List<int> offsetTables = [];
  
  // Version 2.0 fields
  int dsigTag = 0;
  int dsigLength = 0;
  int dsigOffset = 0;
}

/// Reader for OpenType/TrueType font files
class OpenFontReader {
  OpenFontReader();

  /// Read a full typeface from raw font bytes.
  /// Supports basic TrueType fonts (glyf outlines). TTC/WOFF are not yet handled.
  Typeface? read(
    Uint8List data, {
    int offset = 0,
    ReadFlags readFlags = ReadFlags.full,
  }) {
    final reader = ByteOrderSwappingBinaryReader(data);
    if (offset != 0) {
      reader.seek(offset);
    }

    final majorVersion = reader.readUInt16();
    final minorVersion = reader.readUInt16();

    if (KnownFontFiles.isTtcf(majorVersion, minorVersion) ||
        KnownFontFiles.isWoff(majorVersion, minorVersion) ||
        KnownFontFiles.isWoff2(majorVersion, minorVersion)) {
      throw UnimplementedError(
        'Font collections and WOFF formats are not supported yet',
      );
    }

    final tableCount = reader.readUInt16();
    reader.readUInt16(); // searchRange
    reader.readUInt16(); // entrySelector
    reader.readUInt16(); // rangeShift

    final tables = TableEntryCollection();
    for (var i = 0; i < tableCount; i++) {
      tables.addEntry(UnreadTableEntry(_readTableHeader(reader)));
    }

    return _readTypefaceFromTables(tables, reader);
  }

  /// Read preview information without loading the entire font
  PreviewFontInfo readPreview(Uint8List data) {
    final reader = ByteOrderSwappingBinaryReader(data);
    
    final majorVersion = reader.readUInt16();
    final minorVersion = reader.readUInt16();

    if (KnownFontFiles.isTtcf(majorVersion, minorVersion)) {
      // This is a TrueType Collection
      final ttcHeader = _readTTCHeader(reader);
      final members = <PreviewFontInfo>[];
      
      for (var i = 0; i < ttcHeader.numFonts; i++) {
        reader.seek(ttcHeader.offsetTables[i]);
        final member = _readActualFontPreview(reader, false);
        member.actualStreamOffset = ttcHeader.offsetTables[i];
        members.add(member);
      }
      
      return PreviewFontInfo(
        name: _buildTtcfName(members),
        subFamilyName: '',
        members: members,
      );
    } else if (KnownFontFiles.isWoff(majorVersion, minorVersion)) {
      throw UnimplementedError('WOFF format not yet supported');
    } else if (KnownFontFiles.isWoff2(majorVersion, minorVersion)) {
      throw UnimplementedError('WOFF2 format not yet supported');
    } else {
      // Regular TrueType/OpenType font
      return _readActualFontPreview(reader, true);
    }
  }

  /// Read TrueType Collection header
  FontCollectionHeader _readTTCHeader(ByteOrderSwappingBinaryReader reader) {
    final header = FontCollectionHeader();
    
    header.majorVersion = reader.readUInt16();
    header.minorVersion = reader.readUInt16();
    header.numFonts = reader.readUInt32();
    
    final offsetTables = <int>[];
    for (var i = 0; i < header.numFonts; i++) {
      offsetTables.add(reader.readInt32());
    }
    header.offsetTables = offsetTables;
    
    // Version 2.0 adds digital signature fields
    if (header.majorVersion == 2) {
      header.dsigTag = reader.readUInt32();
      header.dsigLength = reader.readUInt32();
      header.dsigOffset = reader.readUInt32();
    }
    
    return header;
  }

  /// Read preview info from the actual font data
  PreviewFontInfo _readActualFontPreview(
    ByteOrderSwappingBinaryReader reader,
    bool skipVersionData,
  ) {
    if (!skipVersionData) {
      reader.readUInt16(); // majorVersion
      reader.readUInt16(); // minorVersion
    }

    final tableCount = reader.readUInt16();
    reader.readUInt16(); // searchRange
    reader.readUInt16(); // entrySelector
    reader.readUInt16(); // rangeShift

    final tables = TableEntryCollection();
    for (var i = 0; i < tableCount; i++) {
      tables.addEntry(UnreadTableEntry(_readTableHeader(reader)));
    }

    // For now, return basic info
    // TODO: Read name table for actual font name
    return PreviewFontInfo(
      name: 'Font',
      subFamilyName: 'Regular',
    );
  }

  /// Read a table header (directory entry)
  TableHeader _readTableHeader(ByteOrderSwappingBinaryReader reader) {
    return TableHeader(
      tag: reader.readUInt32(),
      checkSum: reader.readUInt32(),
      offset: reader.readUInt32(),
      length: reader.readUInt32(),
    );
  }

  /// Build a name for TrueType Collection
  String _buildTtcfName(List<PreviewFontInfo> members) {
    final uniqueNames = <String>{};
    for (final member in members) {
      uniqueNames.add(member.name);
    }
    return 'TTCF: ${members.length}, ${uniqueNames.join(", ")}';
  }

  /// Read a table if it exists in the collection
  T? readTableIfExists<T extends TableEntry>(
    TableEntryCollection tables,
    ByteOrderSwappingBinaryReader reader,
    T resultTable,
  ) {
    final found = tables.tryGetTable(resultTable.name);
    
    if (found == null) {
      return null;
    }

    if (found is UnreadTableEntry) {
      // Set header before actual read
      resultTable.header = found.header;
      
      if (found.hasCustomContentReader) {
        // Some tables have custom readers
        // TODO: implement custom reading
        throw UnimplementedError('Custom content readers not yet implemented');
      } else {
        // Standard reading
        resultTable.loadDataFrom(reader);
      }
      
      // Replace the unread entry with the read table
      tables.replaceTable(resultTable);
      return resultTable;
    } else {
      // Table was already read
      return found as T;
    }
  }

  Typeface? _readTypefaceFromTables(
    TableEntryCollection tables,
    ByteOrderSwappingBinaryReader reader,
  ) {
    final os2 = readTableIfExists(tables, reader, OS2Table());
    final nameEntry = readTableIfExists(tables, reader, NameEntry());
    final head = readTableIfExists(tables, reader, Head());
    final maxProfile = readTableIfExists(tables, reader, MaxProfile());
    final hhea = readTableIfExists(tables, reader, HorizontalHeader());

    if (os2 == null ||
        nameEntry == null ||
        head == null ||
        maxProfile == null ||
        hhea == null) {
      return null;
    }

    final hmtx = readTableIfExists(
      tables,
      reader,
      HorizontalMetrics(hhea.horizontalMetricsCount, maxProfile.glyphCount),
    );
    final cmap = readTableIfExists(tables, reader, Cmap());
    final glyphLocations = readTableIfExists(
      tables,
      reader,
      GlyphLocations(maxProfile.glyphCount, head.wideGlyphLocations),
    );
    final glyf = glyphLocations != null
        ? readTableIfExists(tables, reader, Glyf(glyphLocations))
        : null;

    if (hmtx == null || glyf == null || glyf.glyphs == null) {
      return null;
    }

    final gdef = readTableIfExists(tables, reader, GDEF());
    final gsub = readTableIfExists(tables, reader, GSUB());
    final gpos = readTableIfExists(tables, reader, GPOS());

    final typeface = Typeface.fromTrueType(
      nameEntry: nameEntry,
      bounds: head.bounds,
      unitsPerEm: head.unitsPerEm,
      glyphs: glyf.glyphs!,
      horizontalMetrics: hmtx,
      os2Table: os2,
      cmapTable: cmap,
      maxProfile: maxProfile,
      hheaTable: hhea,
      gdefTable: gdef,
      gsubTable: gsub,
      gposTable: gpos,
    );
    return typeface;
  }
}
