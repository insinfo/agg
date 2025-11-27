// Tests for Typography Text Layout
// Ported to Dart by insinfo, 2025

import 'package:test/test.dart';
import 'package:agg/src/typography/text_layout/glyph_plan.dart';
import 'package:agg/src/typography/text_layout/glyph_index_list.dart';
import 'package:agg/src/typography/text_layout/glyph_layout.dart';
import 'package:agg/src/typography/text_layout/pixel_scale_extensions.dart';
import 'package:agg/src/typography/text_layout/user_char_to_glyph_index_map.dart';
import 'package:agg/src/typography/openfont/typeface.dart';
import 'package:agg/src/typography/openfont/glyph.dart';
import 'package:agg/src/typography/openfont/tables/os2.dart';
import 'package:agg/src/typography/openfont/tables/hmtx.dart';
import 'package:agg/src/typography/openfont/tables/name_entry.dart';
import 'package:agg/src/typography/openfont/tables/cmap.dart';
import 'package:agg/src/typography/openfont/tables/utils.dart';
import 'package:agg/src/typography/openfont/tables/coverage_table.dart';
import 'package:agg/src/typography/openfont/tables/feature_list.dart';
import 'package:agg/src/typography/openfont/tables/gdef.dart';
import 'package:agg/src/typography/openfont/tables/gpos.dart' as gpos_table;
import 'package:agg/src/typography/openfont/tables/gsub.dart' as gsub_table;
import 'package:agg/src/typography/openfont/tables/class_def_table.dart';
import 'package:agg/src/typography/openfont/tables/script_list.dart';
import 'package:agg/src/typography/openfont/tables/script_table.dart';

const int _testGlyphCount = 100;
const int _testAdvanceBase = 500;
const int _testAdvanceStep = 20;

void main() {
  group('UnscaledGlyphPlan', () {
    test('creates plan with all properties', () {
      final plan = UnscaledGlyphPlan(
        inputCodepointOffset: 0,
        glyphIndex: 42,
        advanceX: 500,
        offsetX: 10,
        offsetY: -5,
      );

      expect(plan.inputCodepointOffset, equals(0));
      expect(plan.glyphIndex, equals(42));
      expect(plan.advanceX, equals(500));
      expect(plan.offsetX, equals(10));
      expect(plan.offsetY, equals(-5));
      expect(plan.advanceMoveForward, isTrue);
    });

    test('detects backward advance', () {
      final plan = UnscaledGlyphPlan(
        inputCodepointOffset: 0,
        glyphIndex: 1,
        advanceX: -100,
      );

      expect(plan.advanceMoveForward, isFalse);
    });
  });

  group('UnscaledGlyphPlanList', () {
    test('appends and retrieves plans', () {
      final list = UnscaledGlyphPlanList();

      list.append(UnscaledGlyphPlan(
        inputCodepointOffset: 0,
        glyphIndex: 1,
        advanceX: 100,
      ));

      list.append(UnscaledGlyphPlan(
        inputCodepointOffset: 1,
        glyphIndex: 2,
        advanceX: 200,
      ));

      expect(list.count, equals(2));
      expect(list[0].glyphIndex, equals(1));
      expect(list[1].glyphIndex, equals(2));
    });

    test('clears all plans', () {
      final list = UnscaledGlyphPlanList();
      list.append(UnscaledGlyphPlan(
        inputCodepointOffset: 0,
        glyphIndex: 1,
        advanceX: 100,
      ));

      list.clear();
      expect(list.count, equals(0));
    });
  });

  group('GlyphPlan', () {
    test('stores scaled glyph information', () {
      final plan = GlyphPlan(
        glyphIndex: 5,
        x: 10.5,
        y: 20.3,
        advanceX: 15.7,
      );

      expect(plan.glyphIndex, equals(5));
      expect(plan.x, equals(10.5));
      expect(plan.y, equals(20.3));
      expect(plan.advanceX, equals(15.7));
    });
  });

  group('GlyphIndexList', () {
    test('adds glyphs with mappings', () {
      final list = GlyphIndexList();

      list.addGlyph(0, 10);
      list.addGlyph(1, 20);
      list.addGlyph(2, 30);

      expect(list.count, equals(3));
      expect(list[0], equals(10));
      expect(list[1], equals(20));
      expect(list[2], equals(30));

      final mapping = list.getMapping(1);
      expect(mapping.codepointCharOffset, equals(1));
      expect(mapping.length, equals(1));
    });

    test('replaces glyphs for ligature', () {
      final list = GlyphIndexList();

      // Add 'f', 'f', 'i' glyphs
      list.addGlyph(0, 10); // f
      list.addGlyph(1, 10); // f
      list.addGlyph(2, 20); // i

      // Replace with 'ffi' ligature
      list.replaceRange(0, 3, 99); // ffi ligature glyph

      expect(list.count, equals(1));
      expect(list[0], equals(99));

      final mapping = list.getMapping(0);
      expect(mapping.codepointCharOffset, equals(0));
      expect(mapping.length, equals(3)); // Represents 3 original chars
    });

    test('replaces one glyph with multiple', () {
      final list = GlyphIndexList();

      list.addGlyph(0, 10);

      // Replace with multiple glyphs
      list.replaceWithMultiple(0, [20, 30, 40]);

      expect(list.count, equals(3));
      expect(list[0], equals(20));
      expect(list[1], equals(30));
      expect(list[2], equals(40));
    });

    test('clears all data', () {
      final list = GlyphIndexList();
      list.addGlyph(0, 10);
      list.addGlyph(1, 20);

      list.clear();
      expect(list.count, equals(0));
    });

    test('creates map from user codepoints to glyph indices (ligature)', () {
      final list = GlyphIndexList();
      list.addGlyph(0, 10);
      list.addGlyph(1, 11);
      list.addGlyph(2, 12);

      // Replace all three with a single ligature glyph
      list.replaceRange(0, 3, 99);

      final output = <UserCodePointToGlyphIndex>[];
      list.createMapFromUserCodePointToGlyphIndices(output);

      expect(output.length, equals(3));
      expect(output[0].glyphIndexListOffsetPlus1, equals(1));
      expect(output[0].len, equals(3));
      expect(output[1].glyphIndexListOffsetPlus1, equals(0)); // merged into first
      expect(output[2].glyphIndexListOffsetPlus1, equals(0));
    });

    test('creates map from user codepoints to glyph indices (split)', () {
      final list = GlyphIndexList();
      list.addGlyph(0, 50);

      // Replace one codepoint with two glyphs
      list.replaceWithMultiple(0, [60, 61]);

      final output = <UserCodePointToGlyphIndex>[];
      list.createMapFromUserCodePointToGlyphIndices(output);

      expect(output.length, equals(1));
      expect(output[0].glyphIndexListOffsetPlus1, equals(1));
      expect(output[0].len, equals(2)); // spans both glyphs
    });
  });

  group('GlyphLayout', () {
    // Helper to create a minimal typeface for testing
    Typeface createTestTypeface({gpos_table.GPOS? gpos}) {
      final nameEntry = NameEntry();
      nameEntry.fontName = 'Test Font';
      nameEntry.fontSubFamily = 'Regular';

      final glyphs = List.generate(_testGlyphCount, (i) => Glyph.empty(i));
      final advances =
          List<int>.generate(_testGlyphCount, (i) => _expectedAdvance(i));
      final hmtx = _DummyHorizontalMetrics(
        advances,
        List<int>.filled(_testGlyphCount, 0),
      );
      final os2 = OS2Table();
      os2.sTypoAscender = 800;
      os2.sTypoDescender = -200;
      os2.sTypoLineGap = 100;
      os2.usWinAscent = 900;
      os2.usWinDescent = 300;

      final cmap = _DummyCmap(_buildTestGlyphMap());

      return Typeface.fromTrueType(
        nameEntry: nameEntry,
        bounds: Bounds(0, 0, 1000, 1000),
        unitsPerEm: 1000,
        glyphs: glyphs,
        horizontalMetrics: hmtx,
        os2Table: os2,
        cmapTable: cmap,
        gposTable: gpos,
      );
    }

    test('requires typeface to be set', () {
      final layout = GlyphLayout();

      expect(() => layout.layout('test'), throwsStateError);
    });

    test('converts string to codepoints correctly', () {
      final layout = GlyphLayout();
      final typeface = createTestTypeface();
      layout.typeface = typeface;

      // Layout simple ASCII text
      final plans = layout.layout('ABC');

      // Should create plans for 3 glyphs
      expect(plans.count, equals(3));
    });

    test('generates scaled glyph plans', () {
      final layout = GlyphLayout();
      final typeface = createTestTypeface();
      layout.typeface = typeface;

      layout.layout('Hi');

      // Scale for 16px at 1000 units per em
      final scale = 16.0 / 1000.0; // 0.016
      final scaledPlans = layout.generateGlyphPlans(scale);

      expect(scaledPlans.count, equals(2));

      // Positions should accumulate
      expect(scaledPlans[0].x, equals(0.0));
      // Second glyph x position depends on first glyph's advance
    });

    test('handles emoji and surrogate pairs', () {
      final layout = GlyphLayout();
      final typeface = createTestTypeface();
      layout.typeface = typeface;

      // String with emoji (surrogate pair)
      final plans = layout.layout('A🙌B');

      // Should create 3 glyph plans (A, emoji, B)
      expect(plans.count, equals(3));
    });

    test('clears cached data', () {
      final layout = GlyphLayout();
      final typeface = createTestTypeface();
      layout.typeface = typeface;

      layout.layout('Test');
      layout.clear();

      final plans = layout.layout('New');
      expect(plans.count, equals(3)); // Should work after clear
    });

    test('creates map from user chars to glyph indices', () {
      final layout = GlyphLayout();
      final typeface = createTestTypeface();
      layout.typeface = typeface;

      layout.layout('abc');
      final mapping = <UserCodePointToGlyphIndex>[];
      layout.createMapFromUserCharToGlyphIndices(mapping);

      expect(mapping.length, equals(3));
      expect(mapping[0].glyphIndexListOffsetPlus1, equals(1));
      expect(mapping[0].len, equals(1));
      expect(mapping[1].glyphIndexListOffsetPlus1, equals(2));
      expect(mapping[2].glyphIndexListOffsetPlus1, equals(3));
    });

    test('layoutAndMeasureString returns expected pixel width', () {
      final layout = GlyphLayout();
      final typeface = createTestTypeface();
      layout.typeface = typeface;

      final box = layoutAndMeasureString(
        layout,
        'AB',
        10.0,
        snapToGrid: false,
      );

      final scale = typeface.calculateScaleToPixelFromPointSize(10.0);
      final expectedWidth = ( _expectedAdvance(1) + _expectedAdvance(2) ) * scale;
      expect(box.width, closeTo(expectedWidth, 1e-6));
      final expectedLineSpace =
          ((typeface.ascender - typeface.descender) + typeface.lineGap) * scale;
      expect(box.lineSpaceInPx, closeTo(expectedLineSpace, 1e-6));
    });

    test('layoutAndMeasureString obeys width limit and stopAt', () {
      final layout = GlyphLayout();
      final typeface = createTestTypeface();
      layout.typeface = typeface;

      final scale = typeface.calculateScaleToPixelFromPointSize(12.0);
      final firstGlyphWidth = (_expectedAdvance(1) * scale).round();
      final limit = firstGlyphWidth + 1; // allow first glyph, block second

      final box = layoutAndMeasureString(
        layout,
        'AB',
        12.0,
        limitWidth: limit.toDouble(),
        snapToGrid: true,
      );

      expect(box.width, equals(firstGlyphWidth.toDouble()));
      expect(box.stopAt, equals(1)); // stop before glyph index 1 (second glyph)
    });

    test('applies GPOS pair kerning to glyph advances', () {
      final gpos = _buildKernGpos(-50);
      final layout = GlyphLayout();
      final typeface = createTestTypeface(gpos: gpos);
      layout.typeface = typeface;

      layout.layout('AB');
      final plans = layout.generateGlyphPlans(1.0);

      expect(plans.count, equals(2));
      expect(plans[1].x, equals(_expectedAdvance(1) - 50));
    });

    test('applies mark-to-base positioning end-to-end', () {
      // glyphs: 0 (missing), 1 base, 2 mark
      final gdef = _buildMarkGdef(
        glyphClasses: [0, 1, 3],
        markClasses: [0, 0, 0],
      );
      final gpos = _buildMarkToBaseGpos(
        baseGlyph: 1,
        markGlyph: 2,
        markClass: 0,
        baseAnchor: gpos_table.AnchorPoint(format: 1, xcoord: 400, ycoord: 10),
        markAnchor: gpos_table.AnchorPoint(format: 1, xcoord: 50, ycoord: 3),
      );
      final typeface = _makeTypeface(
        glyphCount: 3,
        advances: [0, 500, 0],
        cmap: {
          'A'.codeUnitAt(0): 1,
          '^'.codeUnitAt(0): 2,
        },
        gdef: gdef,
        gpos: gpos,
      );

      final layout = GlyphLayout()..typeface = typeface;
      layout.layout('A^');
      final plans = layout.generateGlyphPlans(1.0);

      // Mark origin should align its anchor (50) to base anchor (400).
      final expectedMarkX = 400 - 50; // 350
      expect(plans.count, equals(2));
      expect(plans[1].x, equals(expectedMarkX));
      expect(plans[1].y, equals(10 - 3)); // y alignment from anchors
    });

    test('applies mark-to-mark positioning end-to-end', () {
      // glyphs: 0 (missing), 1 base, 2 mark2, 3 mark1
      final gdef = _buildMarkGdef(
        glyphClasses: [0, 1, 3, 3],
        markClasses: [0, 0, 0, 1],
      );
      final gpos = _buildMarkToMarkGpos(
        mark2Glyph: 2,
        mark1Glyph: 3,
        mark1Class: 1,
        mark1Anchor: gpos_table.AnchorPoint(format: 1, xcoord: 5, ycoord: 2),
        mark2AnchorForClass: gpos_table.AnchorPoint(format: 1, xcoord: 9, ycoord: -1),
      );
      final typeface = _makeTypeface(
        glyphCount: 4,
        advances: [0, 400, 0, 0],
        cmap: {
          '^'.codeUnitAt(0): 2, // mark2
          '~'.codeUnitAt(0): 3, // mark1 to attach on mark2
        },
        gdef: gdef,
        gpos: gpos,
      );

      final layout = GlyphLayout()..typeface = typeface;
      layout.layout('^~');
      final plans = layout.generateGlyphPlans(1.0);

      // mark1 anchor aligned to mark2 anchor for class 1: delta = 4, -3
      expect(plans.count, equals(2));
      expect(plans[1].x, equals(4));
      expect(plans[1].y, equals(-3));
    });

    test('applies GSUB ligature substitution end-to-end', () {
      // glyphs: 0 (missing), 1 'f', 2 'i', 3 'fi' (ligature)
      final gsub = _buildLigatureGsub(
        firstGlyph: 1,
        otherComponents: [2],
        ligatureGlyph: 3,
      );
      final typeface = _makeTypeface(
        glyphCount: 4,
        advances: [0, 300, 300, 550], // f=300, i=300, fi=550
        cmap: {
          'f'.codeUnitAt(0): 1,
          'i'.codeUnitAt(0): 2,
        },
        gsub: gsub,
      );

      final layout = GlyphLayout()..typeface = typeface;
      layout.layout('fi');
      final plans = layout.generateGlyphPlans(1.0);

      // Should be replaced by single ligature glyph
      expect(plans.count, equals(1));
      expect(plans[0].glyphIndex, equals(3));
      expect(plans[0].advanceX, equals(550));
    });

    test('applies mark-to-ligature positioning end-to-end', () {
      // glyphs: 0 (missing), 1 'f', 2 'i', 3 'fi', 4 mark
      final gdef = _buildMarkGdef(
        glyphClasses: [0, 1, 1, 2, 3], // 3=ligature, 4=mark
        markClasses: [0, 0, 0, 0, 0],
      );
      final gpos = _buildMarkToLigatureGpos(
        ligatureGlyph: 3,
        markGlyph: 4,
        markClass: 0,
        componentIndex: 1,
        ligatureAnchor: gpos_table.AnchorPoint(format: 1, xcoord: 500, ycoord: 50),
        markAnchor: gpos_table.AnchorPoint(format: 1, xcoord: 10, ycoord: 5),
      );
      
      final typeface = _makeTypeface(
        glyphCount: 5,
        advances: [0, 300, 300, 600, 0],
        cmap: {
          'f'.codeUnitAt(0): 1,
          'i'.codeUnitAt(0): 2,
          '^'.codeUnitAt(0): 4,
        },
        gdef: gdef,
        gpos: gpos,
      );

      // Hack to inject GSUB for ligature formation
      final gsub = _buildLigatureGsub(
        firstGlyph: 1,
        otherComponents: [2],
        ligatureGlyph: 3,
      );
      typeface.gsubTable = gsub;
      // Typeface has gsubTable field which is GSUB?
      // Let's check Typeface class.
      // Typeface has `GSUB? gsubTable`.
      // So `typeface.gsubTable = gsub;` works.
      
      final layout = GlyphLayout()..typeface = typeface;
      layout.layout('fi^');
      final plans = layout.generateGlyphPlans(1.0);

      expect(plans.count, equals(2));
      expect(plans[0].glyphIndex, equals(3)); // ligature
      expect(plans[1].glyphIndex, equals(4)); // mark

      // Mark x = ligAnchor.x - markAnchor.x = 500 - 10 = 490
      // Mark y = ligAnchor.y - markAnchor.y = 50 - 5 = 45
      expect(plans[1].x, equals(490));
      expect(plans[1].y, equals(45));
    });
  });
}

int _expectedAdvance(int glyphIndex) {
  if (glyphIndex <= 0) {
    return 0;
  }
  return _testAdvanceBase + glyphIndex * _testAdvanceStep;
}

Map<int, int> _buildTestGlyphMap() {
  final map = <int, int>{};
  for (var i = 0; i < 26; i++) {
    map['A'.codeUnitAt(0) + i] = 1 + i;
    map['a'.codeUnitAt(0) + i] = 40 + i;
  }
  for (var i = 0; i < 10; i++) {
    map['0'.codeUnitAt(0) + i] = 70 + i;
  }
  map['!'.codeUnitAt(0)] = 90;
  map['?'.codeUnitAt(0)] = 91;
  map[' '.codeUnitAt(0)] = 0;
  return map;
}

class _DummyCmap extends Cmap {
  final Map<int, int> _mapping;
  _DummyCmap(this._mapping);

  @override
  int getGlyphIndex(int codepoint, int nextCodepoint, {bool? skipNextCodepoint}) {
    return _mapping[codepoint] ?? 0;
  }
}

class _DummyHorizontalMetrics extends HorizontalMetrics {
  final List<int> _advances;
  final List<int> _lsbs;

  _DummyHorizontalMetrics(this._advances, this._lsbs)
      : super(_advances.length, _advances.length);

  @override
  int getAdvanceWidth(int index) {
    if (index < 0) return 0;
    if (index >= _advances.length) return _advances.last;
    return _advances[index];
  }

  @override
  int getLeftSideBearing(int index) {
    if (index < 0) return 0;
    if (index >= _lsbs.length) return _lsbs.last;
    return _lsbs[index];
  }

  @override
  (int advanceWidth, int leftSideBearing) getHMetric(int index) {
    return (getAdvanceWidth(index), getLeftSideBearing(index));
  }
}

gpos_table.GPOS _buildKernGpos(int adjust) {
  final lookup = gpos_table.LookupTable(2, 0, 0);
  final coverage = _StubCoverageTable({1}); // first glyph in pair
  final pairSet = gpos_table.PairSetTable([
    gpos_table.PairSet(
      2, // second glyph
      gpos_table.ValueRecord()
        ..valueFormat = gpos_table.ValueRecord.fmtXAdvance
        ..xAdvance = adjust,
      null,
    ),
  ]);
  final sub = gpos_table.LkSubTableType2Fmt1(lookup, coverage, [pairSet]);
  lookup.subTables.add(sub);

  final feature = FeatureTable()
    ..featureTag = _tag('kern')
    ..lookupListIndices = [0];
  final featureList = FeatureList()..featureTables = [feature];

  final lang = LangSysTable(0, 0)
    ..featureIndexList = [0]
    ..requireFeatureIndex = 0xFFFF;
  final script = ScriptTable()
    ..defaultLang = lang
    ..langSysTables = []
    ..scriptTag = _tag('DFLT');
  final scriptList = ScriptList()..['DFLT'] = script;

  final gpos = gpos_table.GPOS()
    ..majorVersion = 1
    ..minorVersion = 0
    ..featureList = featureList
    ..scriptList = scriptList;
  gpos.lookupList.add(lookup);
  return gpos;
}

int _tag(String value) {
  assert(value.length == 4);
  return value.codeUnitAt(0) << 24 |
      value.codeUnitAt(1) << 16 |
      value.codeUnitAt(2) << 8 |
      value.codeUnitAt(3);
}

class _StubCoverageTable extends CoverageTable {
  final Set<int> glyphs;
  _StubCoverageTable(this.glyphs);

  @override
  int findPosition(int glyphIndex) => glyphs.contains(glyphIndex) ? 0 : -1;

  @override
  Iterable<int> getExpandedValueIter() => glyphs;
}

GDEF _buildMarkGdef({
  required List<int> glyphClasses,
  required List<int> markClasses,
}) {
  final glyphClassDef = ClassDefTable()
    ..format = 1
    ..startGlyph = 0
    ..classValueArray = glyphClasses;
  final markClassDef = ClassDefTable()
    ..format = 1
    ..startGlyph = 0
    ..classValueArray = markClasses;
  return GDEF()
    ..glyphClassDef = glyphClassDef
    ..markAttachmentClassDef = markClassDef;
}

gpos_table.GPOS _buildMarkToBaseGpos({
  required int baseGlyph,
  required int markGlyph,
  required int markClass,
  required gpos_table.AnchorPoint baseAnchor,
  required gpos_table.AnchorPoint markAnchor,
}) {
  final lookup = gpos_table.LookupTable(4, 0, 0);
  final sub = gpos_table.LkSubTableType4(lookup)
    ..markCoverageTable = _StubCoverageTable({markGlyph})
    ..baseCoverageTable = _StubCoverageTable({baseGlyph})
    ..markArrayTable = gpos_table.MarkArrayTable([
      gpos_table.MarkRecord(markClass, markAnchor),
    ])
    ..baseArrayTable = gpos_table.BaseArrayTable([
      gpos_table.BaseRecord([baseAnchor]),
    ]);
  lookup.subTables.add(sub);

  final feature = FeatureTable()
    ..featureTag = _tag('mark')
    ..lookupListIndices = [0];
  final featureList = FeatureList()..featureTables = [feature];

  final lang = LangSysTable(0, 0)
    ..featureIndexList = [0]
    ..requireFeatureIndex = 0xFFFF;
  final script = ScriptTable()
    ..defaultLang = lang
    ..langSysTables = []
    ..scriptTag = _tag('DFLT');
  final scriptList = ScriptList()..['DFLT'] = script;

  final gpos = gpos_table.GPOS()
    ..majorVersion = 1
    ..minorVersion = 0
    ..featureList = featureList
    ..scriptList = scriptList;
  gpos.lookupList.add(lookup);
  return gpos;
}

gpos_table.GPOS _buildMarkToMarkGpos({
  required int mark2Glyph,
  required int mark1Glyph,
  required int mark1Class,
  required gpos_table.AnchorPoint mark1Anchor,
  required gpos_table.AnchorPoint mark2AnchorForClass,
}) {
  final lookup = gpos_table.LookupTable(6, 0, 0);
  final sub = gpos_table.LkSubTableType6(
    lookup,
    _StubCoverageTable({mark1Glyph}),
    _StubCoverageTable({mark2Glyph}),
    gpos_table.MarkArrayTable([
      gpos_table.MarkRecord(mark1Class, mark1Anchor),
    ]),
    gpos_table.Mark2ArrayTable([
      gpos_table.Mark2Record([
        null,
        mark2AnchorForClass,
      ]),
    ]),
  );
  lookup.subTables.add(sub);

  final feature = FeatureTable()
    ..featureTag = _tag('mkmk')
    ..lookupListIndices = [0];
  final featureList = FeatureList()..featureTables = [feature];

  final lang = LangSysTable(0, 0)
    ..featureIndexList = [0]
    ..requireFeatureIndex = 0xFFFF;
  final script = ScriptTable()
    ..defaultLang = lang
    ..langSysTables = []
    ..scriptTag = _tag('DFLT');
  final scriptList = ScriptList()..['DFLT'] = script;

  final gpos = gpos_table.GPOS()
    ..majorVersion = 1
    ..minorVersion = 0
    ..featureList = featureList
    ..scriptList = scriptList;
  gpos.lookupList.add(lookup);
  return gpos;
}

Typeface _makeTypeface({
  required int glyphCount,
  required List<int> advances,
  required Map<int, int> cmap,
  GDEF? gdef,
  gpos_table.GPOS? gpos,
  gsub_table.GSUB? gsub,
}) {
  final nameEntry = NameEntry();
  nameEntry.fontName = 'Test Mark Font';
  nameEntry.fontSubFamily = 'Regular';

  final glyphs = List.generate(glyphCount, (i) => Glyph.empty(i));
  final hmtx = _DummyHorizontalMetrics(
    advances,
    List<int>.filled(glyphCount, 0),
  );
  final os2 = OS2Table()
    ..sTypoAscender = 800
    ..sTypoDescender = -200
    ..sTypoLineGap = 100
    ..usWinAscent = 900
    ..usWinDescent = 300;

  final cmapTable = _DummyCmap(cmap);
  return Typeface.fromTrueType(
    nameEntry: nameEntry,
    bounds: Bounds(0, 0, 1000, 1000),
    unitsPerEm: 1000,
    glyphs: glyphs,
    horizontalMetrics: hmtx,
    os2Table: os2,
    cmapTable: cmapTable,
    gdefTable: gdef,
    gposTable: gpos,
    gsubTable: gsub,
  );
}

gsub_table.GSUB _buildLigatureGsub({
  required int firstGlyph,
  required List<int> otherComponents,
  required int ligatureGlyph,
}) {
  final lookup = gsub_table.LookupTable(4, 0, 0);
  
  final ligTable = gsub_table.LigatureTable()
    ..glyphId = ligatureGlyph
    ..componentGlyphs = otherComponents;
    
  final ligSetTable = gsub_table.LigatureSetTable()
    ..ligatures = [ligTable];

  final sub = gsub_table.LkSubTableT4()
    ..coverageTable = _StubCoverageTable({firstGlyph})
    ..ligatureSetTables = [ligSetTable];
  
  lookup.subTables.add(sub);

  final feature = FeatureTable()
    ..featureTag = _tag('liga')
    ..lookupListIndices = [0];
  final featureList = FeatureList()..featureTables = [feature];

  final lang = LangSysTable(0, 0)
    ..featureIndexList = [0]
    ..requireFeatureIndex = 0xFFFF;
  final script = ScriptTable()
    ..defaultLang = lang
    ..langSysTables = []
    ..scriptTag = _tag('DFLT');
  final scriptList = ScriptList()..['DFLT'] = script;

  final gsub = gsub_table.GSUB()
    ..majorVersion = 1
    ..minorVersion = 0
    ..featureList = featureList
    ..scriptList = scriptList;
  gsub.lookupList.add(lookup);
  return gsub;
}

gpos_table.GPOS _buildMarkToLigatureGpos({
  required int ligatureGlyph,
  required int markGlyph,
  required int markClass,
  required int componentIndex,
  required gpos_table.AnchorPoint ligatureAnchor,
  required gpos_table.AnchorPoint markAnchor,
}) {
  final lookup = gpos_table.LookupTable(5, 0, 0);
  
  // Ligature Array: one LigatureAttachTable per ligature glyph in coverage
  // LigatureAttachTable: list of ComponentRecords (one per component)
  // ComponentRecord: list of Anchors (one per mark class)
  
  // We need to pad the component record with nulls if markClass > 0, 
  // but here we assume markClass=0 for simplicity.
  final componentRecord = gpos_table.LigatureComponentRecord([ligatureAnchor]);
  
  // If we want to test specific component, we need enough components in the list.
  // But LkSubTableType5 currently only takes the first one.
  // Let's build it "correctly" anyway.
  final components = List<gpos_table.LigatureComponentRecord>.filled(componentIndex + 1, componentRecord);
  
  final ligAttach = gpos_table.LigatureAttachTable(components);
  
  final sub = gpos_table.LkSubTableType5(
    lookup,
    _StubCoverageTable({markGlyph}),
    _StubCoverageTable({ligatureGlyph}),
    gpos_table.MarkArrayTable([
      gpos_table.MarkRecord(markClass, markAnchor),
    ]),
    gpos_table.LigatureArrayTable([ligAttach]),
  );
  lookup.subTables.add(sub);

  final feature = FeatureTable()
    ..featureTag = _tag('mark')
    ..lookupListIndices = [0];
  final featureList = FeatureList()..featureTables = [feature];

  final lang = LangSysTable(0, 0)
    ..featureIndexList = [0]
    ..requireFeatureIndex = 0xFFFF;
  final script = ScriptTable()
    ..defaultLang = lang
    ..langSysTables = []
    ..scriptTag = _tag('DFLT');
  final scriptList = ScriptList()..['DFLT'] = script;

  final gpos = gpos_table.GPOS()
    ..majorVersion = 1
    ..minorVersion = 0
    ..featureList = featureList
    ..scriptList = scriptList;
  gpos.lookupList.add(lookup);
  return gpos;
}
