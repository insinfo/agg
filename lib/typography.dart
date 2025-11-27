/// Typography library for Dart
/// 
/// This library provides functionality for loading OpenType/TrueType fonts,
/// performing text layout, and accessing glyph metrics and outlines.
library typography;

// Core font classes
export 'src/typography/openfont/typeface.dart';
export 'src/typography/openfont/glyph.dart';
export 'src/typography/openfont/open_font_reader.dart';

// Text layout classes
export 'src/typography/text_layout/glyph_layout.dart';
export 'src/typography/text_layout/glyph_plan.dart';
export 'src/typography/text_layout/script_lang.dart';
export 'src/typography/text_layout/user_char_to_glyph_index_map.dart';

// Helper classes (only exposing what's necessary)
export 'src/typography/openfont/tables/name_entry.dart' show NameEntry;
export 'src/typography/openfont/tables/os2.dart' show OS2Table;
export 'src/typography/openfont/tables/hmtx.dart' show HorizontalMetrics;
export 'src/typography/openfont/tables/cmap.dart' show Cmap;
export 'src/typography/openfont/tables/utils.dart' show Bounds;

// Note: Internal tables like GPOS, GSUB, GDEF, etc. are not exported by default
// to keep the API clean. If you need low-level access, import them directly.
