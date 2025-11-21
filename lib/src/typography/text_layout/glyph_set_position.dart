import '../openfont/tables/gpos.dart';
import '../openfont/tables/script_table.dart';

/// Applies GPOS lookups (kerning, mark attachment, etc.) to glyph positions.
class GlyphSetPosition {
  final GPOS _gposTable;
  final String _language;
  final List<LookupTable> _lookupTables = [];
  bool _mustRebuildTables = true;

  GlyphSetPosition(GPOS gposTable, String language)
      : _gposTable = gposTable,
        _language = language;

  void doGlyphPosition(IGlyphPositions glyphPositions) {
    if (_mustRebuildTables) {
      _rebuildTables();
      _mustRebuildTables = false;
    }

    if (_lookupTables.isEmpty) {
      return;
    }

    final glyphCount = glyphPositions.count;
    for (final lookup in _lookupTables) {
      lookup.doGlyphPosition(glyphPositions, 0, glyphCount);
    }
  }

  void _rebuildTables() {
    _lookupTables.clear();

    final scriptTable = _findScriptTable();
    if (scriptTable == null) {
      return;
    }

    final langSys = _findLangSys(scriptTable);
    if (langSys == null || langSys.featureIndexList.isEmpty) {
      return;
    }

    final featureList = _gposTable.featureList;
    if (featureList == null) {
      return;
    }

    for (final featureIndex in langSys.featureIndexList) {
      if (featureIndex < 0 ||
          featureIndex >= featureList.featureTables.length) {
        continue;
      }
      final feature = featureList.featureTables[featureIndex];
      final tag = feature.tagName.toLowerCase();
      if (!_supportedFeature(tag)) {
        continue;
      }
      for (final lookupIndex in feature.lookupListIndices) {
        if (lookupIndex < 0 || lookupIndex >= _gposTable.lookupList.length) {
          continue;
        }
        _lookupTables.add(_gposTable.lookupList[lookupIndex]);
      }
    }
  }

  ScriptTable? _findScriptTable() {
    final scriptList = _gposTable.scriptList;
    if (scriptList == null) {
      return null;
    }
    final normalized = _language.toUpperCase();
    return scriptList[normalized] ?? scriptList['DFLT'];
  }

  LangSysTable? _findLangSys(ScriptTable scriptTable) {
    return scriptTable.defaultLang ??
        (scriptTable.langSysTables.isNotEmpty
            ? scriptTable.langSysTables.first
            : null);
  }

  bool _supportedFeature(String tag) {
    return tag == 'kern' || tag == 'mark' || tag == 'mkmk';
  }
}
