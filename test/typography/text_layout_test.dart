// Tests for Typography Text Layout
// Ported to Dart by insinfo, 2025

import 'package:test/test.dart';
import 'package:agg/src/typography/text_layout/glyph_plan.dart';
import 'package:agg/src/typography/text_layout/glyph_index_list.dart';
import 'package:agg/src/typography/text_layout/glyph_layout.dart';
import 'package:agg/src/typography/openfont/typeface.dart';
import 'package:agg/src/typography/openfont/glyph.dart';
import 'package:agg/src/typography/openfont/tables/os2.dart';
import 'package:agg/src/typography/openfont/tables/hmtx.dart';
import 'package:agg/src/typography/openfont/tables/name_entry.dart';
import 'package:agg/src/typography/openfont/tables/cmap.dart';
import 'package:agg/src/typography/openfont/tables/utils.dart';

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
      list.replace(0, 3, 99); // ffi ligature glyph

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
  });

  group('GlyphLayout', () {
    // Helper to create a minimal typeface for testing
    Typeface createTestTypeface() {
      final nameEntry = NameEntry();
      nameEntry.fontName = 'Test Font';
      
      final glyphs = List.generate(100, (i) => Glyph.empty(i));
      final hmtx = HorizontalMetrics(100, 100);
      final os2 = OS2Table();
      
      // Create a simple cmap that maps A-Z to glyphs 1-26
      final cmap = Cmap();
      
      return Typeface.fromTrueType(
        nameEntry: nameEntry,
        bounds: Bounds(0, 0, 1000, 1000),
        unitsPerEm: 1000,
        glyphs: glyphs,
        horizontalMetrics: hmtx,
        os2Table: os2,
        cmapTable: cmap,
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
  });
}
