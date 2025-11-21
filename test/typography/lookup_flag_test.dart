import 'package:agg/src/typography/openfont/glyph.dart';
import 'package:agg/src/typography/openfont/tables/coverage_table.dart';
import 'package:agg/src/typography/openfont/tables/gdef.dart';
import 'package:agg/src/typography/openfont/tables/gpos.dart' as gpos;
import 'package:agg/src/typography/openfont/tables/gsub.dart' as gsub;
import 'package:agg/src/typography/openfont/tables/i_glyph_index_list.dart';
import 'package:test/test.dart';

void main() {
  group('GPOS LookupTable flags', () {
    test('ignore base, ligature, and mark flags skip glyphs', () {
      final baseLookup = gpos.LookupTable(1, 0x0002, 0);
      final ligLookup = gpos.LookupTable(1, 0x0004, 0);
      final markLookup = gpos.LookupTable(1, 0x0008, 0);

      final positions = _TestGlyphPositions(
        glyphIndices: [10, 11, 12],
        glyphClasses: [
          GlyphClassKind.base,
          GlyphClassKind.ligature,
          GlyphClassKind.mark,
        ],
        markClasses: const [0, 0, 1],
        advances: const [500, 500, 500],
      );

      expect(baseLookup.shouldProcessGlyph(positions, 0), isFalse);
      expect(ligLookup.shouldProcessGlyph(positions, 1), isFalse);
      expect(markLookup.shouldProcessGlyph(positions, 2), isFalse);
    });

    test('mark filtering set is respected', () {
      final lookup = gpos.LookupTable(1, 0x0010, 0);
      lookup.setMarkGlyphSets(
        MarkGlyphSetsTable(1, [_StubCoverageTable({30})]),
      );
      final positions = _TestGlyphPositions(
        glyphIndices: [30, 31],
        glyphClasses: [
          GlyphClassKind.mark,
          GlyphClassKind.mark,
        ],
        markClasses: const [1, 1],
        advances: const [500, 500],
      );

      expect(lookup.shouldProcessGlyph(positions, 0), isTrue);
      expect(lookup.shouldProcessGlyph(positions, 1), isFalse);
    });

    test('mark attachment type filter requires matching mark class', () {
      final lookup = gpos.LookupTable(1, 0x0300, 0); // attachment type = 3
      final positions = _TestGlyphPositions(
        glyphIndices: [50, 51],
        glyphClasses: [
          GlyphClassKind.mark,
          GlyphClassKind.mark,
        ],
        markClasses: const [3, 2],
        advances: const [400, 400],
      );

      expect(lookup.shouldProcessGlyph(positions, 0), isTrue);
      expect(lookup.shouldProcessGlyph(positions, 1), isFalse);
    });
  });

  group('GSUB LookupTable flags', () {
    test('ignore mark flag suppresses substitution attempts', () {
      final lookup = gsub.LookupTable(1, 0x0008, 0);
      lookup.glyphClassResolver = (_) => GlyphClassKind.mark;
      final recorder = _RecordingSubTable();
      lookup.subTables.add(recorder);

      final glyphs = _TestGlyphIndexList([15]);
      final result = lookup.doSubstitutionAt(glyphs, 0, glyphs.count);
      expect(result, isFalse);
      expect(recorder.callCount, equals(0));
    });

    test('mark filtering set determines eligible marks', () {
      final lookup = gsub.LookupTable(1, 0x0010, 0);
      lookup.glyphClassResolver = (_) => GlyphClassKind.mark;
      lookup.markGlyphSets = MarkGlyphSetsTable(
        1,
        [_StubCoverageTable({90})],
      );
      final recorder = _RecordingSubTable(returnValue: true);
      lookup.subTables.add(recorder);

      final glyphs = _TestGlyphIndexList([90]);
      final success = lookup.doSubstitutionAt(glyphs, 0, glyphs.count);
      expect(success, isTrue);
      expect(recorder.callCount, equals(1));

      final glyphsBlocked = _TestGlyphIndexList([91]);
      final skipped = lookup.doSubstitutionAt(glyphsBlocked, 0, 1);
      expect(skipped, isFalse);
      expect(recorder.callCount, equals(1)); // unchanged
    });

    test('mark attachment type rejects mismatched mark class', () {
      final lookup = gsub.LookupTable(1, 0x0200, 0); // attachment class = 2
      lookup.glyphClassResolver = (_) => GlyphClassKind.mark;
      lookup.markClassResolver = (glyphIndex) => glyphIndex == 77 ? 2 : 1;
      final recorder = _RecordingSubTable();
      lookup.subTables.add(recorder);

      final allowed = _TestGlyphIndexList([77]);
      expect(lookup.doSubstitutionAt(allowed, 0, 1), isFalse);
      expect(recorder.callCount, equals(1));

      final blocked = _TestGlyphIndexList([78]);
      expect(lookup.doSubstitutionAt(blocked, 0, 1), isFalse);
      expect(recorder.callCount, equals(1)); // unchanged
    });
  });

  group('GPOS mark attachment', () {
    test('mark-to-mark positions current mark against previous mark', () {
      final lookup = gpos.LookupTable(6, 0, 0);
      final sub = gpos.LkSubTableType6(
        lookup,
        _StubCoverageTable({11}), // mark1
        _StubCoverageTable({10}), // mark2
        gpos.MarkArrayTable([
          gpos.MarkRecord(0, gpos.AnchorPoint(format: 1, xcoord: 10, ycoord: -5)),
        ]),
        gpos.Mark2ArrayTable([
          gpos.Mark2Record([
            gpos.AnchorPoint(format: 1, xcoord: 14, ycoord: -2),
          ])
        ]),
      );
      lookup.subTables.add(sub);

      final positions = _TestGlyphPositions(
        glyphIndices: [10, 11],
        glyphClasses: [
          GlyphClassKind.mark,
          GlyphClassKind.mark,
        ],
        markClasses: const [0, 0],
        advances: const [0, 0],
      );

      lookup.doGlyphPosition(positions, 0, positions.count);
      expect(positions.offsets, contains((4, 3)));
    });

    test('mark-to-ligature attaches to first component anchor', () {
      final lookup = gpos.LookupTable(5, 0, 0);
      final sub = gpos.LkSubTableType5(
        lookup,
        _StubCoverageTable({21}),
        _StubCoverageTable({20}),
        gpos.MarkArrayTable([
          gpos.MarkRecord(0, gpos.AnchorPoint(format: 1, xcoord: 5, ycoord: 7)),
        ]),
        gpos.LigatureArrayTable([
          gpos.LigatureAttachTable([
            gpos.LigatureComponentRecord([
              gpos.AnchorPoint(format: 1, xcoord: 8, ycoord: 10),
            ])
          ])
        ]),
      );
      lookup.subTables.add(sub);

      final positions = _TestGlyphPositions(
        glyphIndices: [20, 21],
        glyphClasses: [
          GlyphClassKind.ligature,
          GlyphClassKind.mark,
        ],
        markClasses: const [0, 0],
        advances: const [500, 0],
      );

      lookup.doGlyphPosition(positions, 0, positions.count);
      expect(positions.offsets, contains((3, 3)));
    });
  });
}

class _TestGlyphPositions implements gpos.IGlyphPositions {
  @override
  final int count;
  final List<int> glyphIndices;
  final List<GlyphClassKind> glyphClasses;
  final List<int> markClasses;
  final List<int> advances;
  final List<(int x, int y)> offsets = [];
  final List<(int x, int y)> advancesAppended = [];

  _TestGlyphPositions({
    required this.glyphIndices,
    required this.glyphClasses,
    required this.markClasses,
    required this.advances,
  }) : count = glyphIndices.length;

  @override
  void appendGlyphAdvance(int index, int appendAdvX, int appendAdvY) {
    advancesAppended.add((appendAdvX, appendAdvY));
  }

  @override
  void appendGlyphOffset(int index, int appendOffsetX, int appendOffsetY) {
    offsets.add((appendOffsetX, appendOffsetY));
  }

  @override
  int getGlyphAdvanceWidth(int index) => advances[index];

  @override
  GlyphClassKind getGlyphClassKind(int index) => glyphClasses[index];

  @override
  int getGlyphIndex(int index) => glyphIndices[index];

  @override
  int getGlyphMarkAttachmentType(int index) => markClasses[index];
}

class _TestGlyphIndexList implements IGlyphIndexList {
  final List<int> _glyphs;

  _TestGlyphIndexList(this._glyphs);

  @override
  int get count => _glyphs.length;

  @override
  int operator [](int index) => _glyphs[index];

  @override
  void replace(int index, int newGlyphIndex) {
    _glyphs[index] = newGlyphIndex;
  }

  @override
  void replaceRange(int index, int removeLen, int newGlyphIndex) {
    _glyphs
      ..removeRange(index, index + removeLen)
      ..insert(index, newGlyphIndex);
  }

  @override
  void replaceWithMultiple(int index, List<int> newGlyphIndices) {
    _glyphs
      ..removeAt(index)
      ..insertAll(index, newGlyphIndices);
  }
}

class _StubCoverageTable extends CoverageTable {
  final Set<int> glyphs;

  _StubCoverageTable(this.glyphs);

  @override
  int findPosition(int glyphIndex) => glyphs.contains(glyphIndex) ? 0 : -1;

  @override
  Iterable<int> getExpandedValueIter() => glyphs;
}

class _RecordingSubTable extends gsub.LookupSubTable {
  int callCount = 0;
  final bool returnValue;

  _RecordingSubTable({this.returnValue = false});

  @override
  void collectAssociatedSubstitutionGlyphs(List<int> outputAssocGlyphs) {}

  @override
  bool doSubstitutionAt(IGlyphIndexList glyphIndices, int pos, int len) {
    callCount++;
    return returnValue;
  }
}
