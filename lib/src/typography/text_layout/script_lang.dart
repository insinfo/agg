/// Minimal representation of a script/lang tag used during glyph layout.
/// This mirrors the ScriptLang data used in the C# implementation.
class ScriptLang {
  /// Human readable name (e.g., "Latin").
  final String fullname;

  /// OpenType short tag used to look up features (e.g., "latn").
  final String shortname;

  const ScriptLang(this.fullname, this.shortname);

  /// Latin script (default for most fonts).
  static const latin = ScriptLang('Latin', 'latn');

  String get normalizedTag => shortname.toLowerCase();

  @override
  String toString() => fullname;
}
