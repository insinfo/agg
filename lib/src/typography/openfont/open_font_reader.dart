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
import 'tables/base.dart';
import 'tables/jstf.dart';
import 'tables/math.dart';
import 'tables/colr.dart';
import 'tables/cpal.dart';
import 'tables/cff/cff_table.dart';
import 'tables/eblc.dart';
import 'tables/ebdt.dart';
import 'tables/cblc.dart';
import 'tables/cbdt.dart';
import 'tables/svg_table.dart';
import 'tables/variations/fvar.dart';
import 'tables/variations/gvar.dart';
import 'tables/variations/hvar.dart';
import 'tables/variations/mvar.dart';
import 'tables/variations/stat.dart';
import 'tables/variations/vvar.dart';
import 'tables/vhea.dart';
import 'tables/vmtx.dart';
import 'tables/gasp.dart';
import 'tables/kern.dart';
import 'tables/post.dart';
import 'tables/fpgm.dart';
import 'tables/prep.dart';
import 'tables/cvt.dart';

import 'glyph.dart';
import 'webfont/woff_reader.dart';
import 'webfont/woff2_reader.dart';

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

    if (KnownFontFiles.isWoff(majorVersion, minorVersion)) {
      return WoffReader().read(reader);
    } else if (KnownFontFiles.isWoff2(majorVersion, minorVersion)) {
      return Woff2Reader().read(reader);
    } else if (KnownFontFiles.isTtcf(majorVersion, minorVersion)) {
      throw UnimplementedError(
        'Font collections are not supported yet',
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

  /// Read a typeface from a pre-populated collection of tables
  Typeface? readTableEntryCollection(
    TableEntryCollection tables,
    ByteOrderSwappingBinaryReader reader,
  ) {
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
    String name = 'Font';
    String subFamily = 'Regular';

    final nameEntry = tables.tryGetTable('name');
    if (nameEntry is UnreadTableEntry) {
      final loadedName = NameEntry();
      loadedName.header = nameEntry.header;
      loadedName.loadDataFrom(reader);
      if (loadedName.fontName.isNotEmpty) {
        name = loadedName.fontName;
      }
      if (loadedName.fontSubFamily.isNotEmpty) {
        subFamily = loadedName.fontSubFamily;
      }
    }

    return PreviewFontInfo(
      name: name,
      subFamilyName: subFamily,
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
    
    final post = readTableIfExists(tables, reader, PostTable());
    final vhea = readTableIfExists(tables, reader, VerticalHeader());

    final vmtx = vhea != null 
        ? readTableIfExists(
            tables, 
            reader, 
            VerticalMetrics(vhea.numOfLongVerMetrics, maxProfile.glyphCount))
        : null;

    final gasp = readTableIfExists(tables, reader, Gasp());
    final kern = readTableIfExists(tables, reader, Kern());
    final fpgm = readTableIfExists(tables, reader, FpgmTable());
    final prep = readTableIfExists(tables, reader, PrepTable());
    final cvt = readTableIfExists(tables, reader, CvtTable());

    final cmap = readTableIfExists(tables, reader, Cmap());
    
    final cff = readTableIfExists(tables, reader, CFFTable());
    final eblc = readTableIfExists(tables, reader, EBLC());
    final ebdt = readTableIfExists(tables, reader, EBDT());
    final cblc = readTableIfExists(tables, reader, CBLC());
    final cbdt = readTableIfExists(tables, reader, CBDT());
    final svg = readTableIfExists(tables, reader, SvgTable());
    final fvar = readTableIfExists(tables, reader, FVar());
    final gvar = readTableIfExists(tables, reader, GVar());
    final hvar = readTableIfExists(tables, reader, HVar());
    final mvar = readTableIfExists(tables, reader, MVar());
    final vvar = readTableIfExists(tables, reader, VVar());
    final stat = readTableIfExists(tables, reader, STAT());
    
    List<Glyph>? glyphs;
    
    if (cff != null && cff.cff1FontSet != null && cff.cff1FontSet!.fonts.isNotEmpty) {
      glyphs = cff.cff1FontSet!.fonts[0].glyphs;
    } else {
      final glyphLocations = readTableIfExists(
        tables,
        reader,
        GlyphLocations(maxProfile.glyphCount, head.wideGlyphLocations),
      );
      final glyf = glyphLocations != null
          ? readTableIfExists(tables, reader, Glyf(glyphLocations))
          : null;
      glyphs = glyf?.glyphs;

      // If no glyphs found yet (e.g. bitmap-only font), create empty glyphs
      if (glyphs == null && (eblc != null || svg != null || cblc != null)) {
        glyphs = List<Glyph>.generate(
            maxProfile.glyphCount, (index) => Glyph.empty(index));
      }
    }

    if (hmtx == null || glyphs == null) {
      return null;
    }

    final gdef = readTableIfExists(tables, reader, GDEF());
    final gsub = readTableIfExists(tables, reader, GSUB());
    final gpos = readTableIfExists(tables, reader, GPOS());
    final base = readTableIfExists(tables, reader, BASE());
    final jstf = readTableIfExists(tables, reader, JSTF());
    final math = readTableIfExists(tables, reader, MathTable());
    final colr = readTableIfExists(tables, reader, COLR());
    final cpal = readTableIfExists(tables, reader, CPAL());

    final typeface = Typeface.fromTrueType(
      nameEntry: nameEntry,
      bounds: head.bounds,
      unitsPerEm: head.unitsPerEm,
      glyphs: glyphs,
      horizontalMetrics: hmtx,
      os2Table: os2,
      cmapTable: cmap,
      maxProfile: maxProfile,
      hheaTable: hhea,
      gdefTable: gdef,
      gsubTable: gsub,
      gposTable: gpos,
      baseTable: base,
      jstfTable: jstf,
      mathTable: math,
      colrTable: colr,
      cpalTable: cpal,
      cffTable: cff,
      eblcTable: eblc,
      ebdtTable: ebdt,
      cblcTable: cblc,
      cbdtTable: cbdt,
      svgTable: svg,
      fvarTable: fvar,
      gvarTable: gvar,
      hvarTable: hvar,
      mvarTable: mvar,
      vvarTable: vvar,
      statTable: stat,
      vheaTable: vhea,
      vmtxTable: vmtx,
      gaspTable: gasp,
      kernTable: kern,
      postTable: post,
      fpgmTable: fpgm,
      prepTable: prep,
      cvtTable: cvt,
    );
    return typeface;
  }
}
