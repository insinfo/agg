import '../openfont/tables/gsub.dart';
import '../openfont/tables/script_table.dart';
import 'glyph_index_list.dart';

/// Applies GSUB-based substitutions (ligatures, compositions, etc.) to a glyph stream.
class GlyphSubstitution {
  final GSUB _gsubTable;
  final String _language;
  final List<LookupTable> _lookupTables = [];
  bool _mustRebuildTables = true;
  bool _enableLigation = true;
  bool _enableComposition = true;
  bool _enableMathFeature = true;

  GlyphSubstitution(GSUB gsubTable, String language)
      : _gsubTable = gsubTable,
        _language = language;

  bool get enableLigation => _enableLigation;
  set enableLigation(bool value) {
    if (_enableLigation != value) {
      _enableLigation = value;
      _mustRebuildTables = true;
    }
  }

  bool get enableComposition => _enableComposition;
  set enableComposition(bool value) {
    if (_enableComposition != value) {
      _enableComposition = value;
      _mustRebuildTables = true;
    }
  }

  /// Enable OpenType math-related substitutions (ssty, dtls, flac, math)
  bool get enableMathFeature => _enableMathFeature;
  set enableMathFeature(bool value) {
    if (_enableMathFeature != value) {
      _enableMathFeature = value;
      _mustRebuildTables = true;
    }
  }

  void doSubstitution(GlyphIndexList glyphIndexList) {
    if (_mustRebuildTables) {
      _rebuildTables();
      _mustRebuildTables = false;
    }

    if (_lookupTables.isEmpty) {
      return;
    }

    for (final lookup in _lookupTables) {
      final glyphCount = glyphIndexList.count;
      for (var pos = 0; pos < glyphCount; pos++) {
        lookup.doSubstitutionAt(glyphIndexList, pos, glyphCount - pos);
      }
    }
  }

  void collectAssociatedSubstitutionGlyphIndices(List<int> outputGlyphIndices) {
    if (_mustRebuildTables) {
      _rebuildTables();
      _mustRebuildTables = false;
    }

    for (final lookup in _lookupTables) {
      lookup.collectAssociatedSubstitutionGlyph(outputGlyphIndices);
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

    final featureList = _gsubTable.featureList;
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
      if (!_featureEnabled(tag)) {
        continue;
      }

      for (final lookupIndex in feature.lookupListIndices) {
        if (lookupIndex < 0 || lookupIndex >= _gsubTable.lookupList.length) {
          continue;
        }
        _lookupTables.add(_gsubTable.lookupList[lookupIndex]);
      }
    }
  }

  bool _featureEnabled(String tag) {
    switch (tag) {
      case 'ccmp':
        return _enableComposition;
      case 'liga':
        return _enableLigation;
      case 'ssty':
      case 'dtls':
      case 'dlts': // typo-friendly alias
      case 'flac':
      case 'math':
        return _enableMathFeature;
      default:
        return false;
    }
  }

  ScriptTable? _findScriptTable() {
    final scriptList = _gsubTable.scriptList;
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
}
