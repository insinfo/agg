import '../../glyph.dart';

class Cff1FontSet {
  List<String> fontNames = [];
  List<Cff1Font> fonts = [];
  List<String> uniqueStringTable = [];

  static const int nStdStrings = 390;
  static const List<String> stdStrings = [
    ".notdef", "space", "exclam", "quotedbl", "numbersign", "dollar", "percent", "ampersand", "quoteright", "parenleft", "parenright", "asterisk", "plus", "comma", "hyphen", "period", "slash", "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "colon", "semicolon", "less", "equal", "greater", "question", "at", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "bracketleft", "backslash", "bracketright", "asciicircum", "underscore", "quoteleft", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "braceleft", "bar", "braceright", "asciitilde", "exclamdown", "cent", "sterling", "fraction", "yen", "florin", "section", "currency", "quotesingle", "quotedblleft", "guillemotleft", "guilsinglleft", "guilsinglright", "fi", "fl", "endash", "dagger", "daggerdbl", "periodcentered", "paragraph", "bullet", "quotesinglbase", "quotedblbase", "quotedblright", "guillemotright", "ellipsis", "perthousand", "questiondown", "grave", "acute", "circumflex", "tilde", "macron", "breve", "dotaccent", "dieresis", "ring", "cedilla", "hungarumlaut", "ogonek", "caron", "emdash", "AE", "ordfeminine", "Lslash", "Oslash", "OE", "ordmasculine", "ae", "dotlessi", "lslash", "oslash", "oe", "germandbls", "onesuperior", "logicalnot", "mu", "trademark", "Eth", "onehalf", "plusminus", "Thorn", "onequarter", "divide", "brokenbar", "degree", "thorn", "threequarters", "twosuperior", "registered", "minus", "eth", "multiply", "threesuperior", "copyright", "Aacute", "Acircumflex", "Adieresis", "Agrave", "Aring", "Atilde", "Ccedilla", "Eacute", "Ecircumflex", "Edieresis", "Egrave", "Iacute", "Icircumflex", "Idieresis", "Igrave", "Ntilde", "Oacute", "Ocircumflex", "Odieresis", "Ograve", "Otilde", "Scaron", "Uacute", "Ucircumflex", "Udieresis", "Ugrave", "Yacute", "Ydieresis", "Zcaron", "aacute", "acircumflex", "adieresis", "agrave", "aring", "atilde", "ccedilla", "eacute", "ecircumflex", "edieresis", "egrave", "iacute", "icircumflex", "idieresis", "igrave", "ntilde", "oacute", "ocircumflex", "odieresis", "ograve", "otilde", "scaron", "uacute", "ucircumflex", "udieresis", "ugrave", "yacute", "ydieresis", "zcaron", "exclamsmall", "Hungarumlautsmall", "dollaroldstyle", "dollarsuperior", "ampersandsmall", "Acutesmall", "parenleftsuperior", "parenrightsuperior", "twodotenleader", "onedotenleader", "zerooldstyle", "oneoldstyle", "twooldstyle", "threeoldstyle", "fouroldstyle", "fiveoldstyle", "sixoldstyle", "sevenoldstyle", "eightoldstyle", "nineoldstyle", "commasuperior", "threequartersemdash", "periodsuperior", "questionsmall", "asuperior", "bsuperior", "centsuperior", "dsuperior", "esuperior", "isuperior", "lsuperior", "msuperior", "nsuperior", "osuperior", "rsuperior", "ssuperior", "tsuperior", "ff", "ffi", "ffl", "parenleftinferior", "parenrightinferior", "Circumflexsmall", "hyphensuperior", "Gravesmall", "Asmall", "Bsmall", "Csmall", "Dsmall", "Esmall", "Fsmall", "Gsmall", "Hsmall", "Ismall", "Jsmall", "Ksmall", "Lsmall", "Msmall", "Nsmall", "Osmall", "Psmall", "Qsmall", "Rsmall", "Ssmall", "Tsmall", "Usmall", "Vsmall", "Wsmall", "Xsmall", "Ysmall", "Zsmall", "colonmonetary", "onefitted", "rupiah", "Tildesmall", "exclamdownsmall", "centoldstyle", "Lslashsmall", "Scaronsmall", "Zcaronsmall", "Dieresissmall", "Brevesmall", "Caronsmall", "Dotaccentsmall", "Macronsmall", "figuredash", "hypheninferior", "Ogoneksmall", "Ringsmall", "Cedillasmall", "questiondownsmall", "oneeighth", "threeeighths", "fiveeighths", "seveneighths", "onethird", "twothirds", "zerosuperior", "foursuperior", "fivesuperior", "sixsuperior", "sevensuperior", "eightsuperior", "ninesuperior", "zeroinferior", "oneinferior", "twoinferior", "threeinferior", "fourinferior", "fiveinferior", "sixinferior", "seveninferior", "eightinferior", "nineinferior", "centinferior", "dollarinferior", "periodinferior", "commainferior", "Agravesmall", "Aacutesmall", "Acircumflexsmall", "Atildesmall", "Adieresissmall", "Aringsmall", "AEsmall", "Ccedillasmall", "Egravesmall", "Eacutesmall", "Ecircumflexsmall", "Edieresissmall", "Igravesmall", "Iacutesmall", "Icircumflexsmall", "Idieresissmall", "Ethsmall", "Ntildesmall", "Ogravesmall", "Oacutesmall", "Ocircumflexsmall", "Otildesmall", "Odieresissmall", "OEsmall", "Oslashsmall", "Ugravesmall", "Uacutesmall", "Ucircumflexsmall", "Udieresissmall", "Yacutesmall", "Thornsmall", "Ydieresissmall", "001.000", "001.001", "001.002", "001.003", "Black", "Bold", "Book", "Light", "Medium", "Regular", "Roman", "Semibold"
  ];
}

class FontDict {
  int fontName = 0;
  int privateDicSize;
  int privateDicOffset;
  List<List<int>>? localSubr;

  FontDict(this.privateDicSize, this.privateDicOffset);
}

class Cff1Font {
  String? fontName;
  List<Glyph> glyphs = [];
  
  List<List<int>>? localSubrRawBufferList;
  List<List<int>>? globalSubrRawBufferList;

  // Alias for parser compatibility
  List<List<int>>? get globalSubrIndex => globalSubrRawBufferList;

  int defaultWidthX = 0;
  int nominalWidthX = 0;
  List<FontDict>? cidFontDict;

  Map<String, Glyph>? _cachedGlyphDicByName;

  String? version;
  String? notice;
  String? copyRight;
  String? fullName;
  String? familyName;
  String? weight;
  double underlinePosition = 0;
  double underlineThickness = 0;
  List<double>? fontBBox;

  Glyph? getGlyphByName(String name) {
    if (_cachedGlyphDicByName == null) {
      _cachedGlyphDicByName = {};
      // for (final glyph in glyphs) {
      //   // ...
      // }
    }
    return _cachedGlyphDicByName?[name];
  }
}

class Cff1GlyphData {
  String? name;
  int sidName = 0;
  int glyphIndex = 0;
  List<dynamic>? glyphInstructions; // Type2Instruction list
}

enum OperandKind {
  intNumber,
  realNumber
}

class CffOperand {
  final OperandKind kind;
  final double realNumValue;

  CffOperand(this.realNumValue, this.kind);

  @override
  String toString() {
    if (kind == OperandKind.intNumber) {
      return realNumValue.toInt().toString();
    }
    return realNumValue.toString();
  }
}

enum OperatorOperandKind {
  sid,
  boolean,
  number,
  array,
  delta,
  numberNumber,
  sidSidNumber,
}

class CFFOperator {
  final String name;
  final int b0;
  final int b1;
  final OperatorOperandKind operandKind;

  CFFOperator(this.name, this.b0, this.b1, this.operandKind);

  static final Map<int, CFFOperator> _registeredOperators = {};

  static void register(int b0, int b1, String name, OperatorOperandKind kind) {
    _registeredOperators[(b1 << 8) | b0] = CFFOperator(name, b0, b1, kind);
  }

  static void registerSingle(int b0, String name, OperatorOperandKind kind) {
    _registeredOperators[b0] = CFFOperator(name, b0, 0, kind);
  }

  static CFFOperator? getOperatorByKey(int b0, int b1) {
    return _registeredOperators[(b1 << 8) | b0];
  }

  static void _init() {
    if (_registeredOperators.isNotEmpty) return;
    
    // Table 9: Top DICT Operator Entries
    registerSingle(0, "version", OperatorOperandKind.sid);
    registerSingle(1, "Notice", OperatorOperandKind.sid);
    register(12, 0, "Copyright", OperatorOperandKind.sid);
    registerSingle(2, "FullName", OperatorOperandKind.sid);
    registerSingle(3, "FamilyName", OperatorOperandKind.sid);
    registerSingle(4, "Weight", OperatorOperandKind.sid);
    register(12, 1, "isFixedPitch", OperatorOperandKind.boolean);
    register(12, 2, "ItalicAngle", OperatorOperandKind.number);
    register(12, 3, "UnderlinePosition", OperatorOperandKind.number);
    register(12, 4, "UnderlineThickness", OperatorOperandKind.number);
    register(12, 5, "PaintType", OperatorOperandKind.number);
    register(12, 6, "CharstringType", OperatorOperandKind.number);
    register(12, 7, "FontMatrix", OperatorOperandKind.array);
    registerSingle(13, "UniqueID", OperatorOperandKind.number);
    registerSingle(5, "FontBBox", OperatorOperandKind.array);
    register(12, 8, "StrokeWidth", OperatorOperandKind.number);
    registerSingle(14, "XUID", OperatorOperandKind.array);
    registerSingle(15, "charset", OperatorOperandKind.number);
    registerSingle(16, "Encoding", OperatorOperandKind.number);
    registerSingle(17, "CharStrings", OperatorOperandKind.number);
    registerSingle(18, "Private", OperatorOperandKind.numberNumber);
    register(12, 20, "SyntheticBase", OperatorOperandKind.number);
    register(12, 21, "PostScript", OperatorOperandKind.sid);
    register(12, 22, "BaseFontName", OperatorOperandKind.sid);
    register(12, 23, "BaseFontBlend", OperatorOperandKind.sid);

    // Table 10: CIDFont Operator Extensions
    register(12, 30, "ROS", OperatorOperandKind.sidSidNumber);
    register(12, 31, "CIDFontVersion", OperatorOperandKind.number);
    register(12, 32, "CIDFontRevision", OperatorOperandKind.number);
    register(12, 33, "CIDFontType", OperatorOperandKind.number);
    register(12, 34, "CIDCount", OperatorOperandKind.number);
    register(12, 35, "UIDBase", OperatorOperandKind.number);
    register(12, 36, "FDArray", OperatorOperandKind.number);
    register(12, 37, "FDSelect", OperatorOperandKind.number);
    register(12, 38, "FontName", OperatorOperandKind.sid);

    // Table 23: Private DICT Operators
    registerSingle(6, "BlueValues", OperatorOperandKind.delta);
    registerSingle(7, "OtherBlues", OperatorOperandKind.delta);
    registerSingle(8, "FamilyBlues", OperatorOperandKind.delta);
    registerSingle(9, "FamilyOtherBlues", OperatorOperandKind.delta);
    register(12, 9, "BlueScale", OperatorOperandKind.number);
    register(12, 10, "BlueShift", OperatorOperandKind.number);
    register(12, 11, "BlueFuzz", OperatorOperandKind.number);
    registerSingle(10, "StdHW", OperatorOperandKind.number);
    registerSingle(11, "StdVW", OperatorOperandKind.number);
    register(12, 12, "StemSnapH", OperatorOperandKind.delta);
    register(12, 13, "StemSnapV", OperatorOperandKind.delta);
    register(12, 14, "ForceBold", OperatorOperandKind.boolean);
    
    register(12, 17, "LanguageGroup", OperatorOperandKind.number);
    register(12, 18, "ExpansionFactor", OperatorOperandKind.number);
    register(12, 19, "initialRandomSeed", OperatorOperandKind.number);

    registerSingle(19, "Subrs", OperatorOperandKind.number);
    registerSingle(20, "defaultWidthX", OperatorOperandKind.number);
    registerSingle(21, "nominalWidthX", OperatorOperandKind.number);
  }
  
  // Ensure initialization
  static void ensureInit() {
    _init();
  }
}

class CffDataDicEntry {
  List<CffOperand> operands = [];
  CFFOperator? operator;
}
