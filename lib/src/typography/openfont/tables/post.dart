import 'dart:convert';
import '../../io/byte_order_swapping_reader.dart';
import 'table_entry.dart';
import 'utils.dart';

/// PostScript Table
class PostTable extends TableEntry {
  static const String _N = "post";
  @override
  String get name => _N;

  // https://www.microsoft.com/typography/otspec/post.htm

  Map<int, String>? _glyphNames;
  Map<String, int>? _glyphIndiceByName;

  int version = 0;
  double italicAngle = 0;
  int underlinePosition = 0;
  int underlineThickness = 0;
  int isFixedPitch = 0;
  int minMemType42 = 0;
  int maxMemType42 = 0;
  int minMemType1 = 0;
  int maxMemType1 = 0;

  Map<int, String>? get glyphNames => _glyphNames;

  @override
  void readContentFrom(ByteOrderSwappingBinaryReader reader) {
    // header
    final versionRaw = reader.readUInt32(); // 16.16
    italicAngle = Utils.readFixed(reader); // Fixed 16.16
    underlinePosition = reader.readInt16();
    underlineThickness = reader.readInt16();
    isFixedPitch = reader.readUInt32();
    minMemType42 = reader.readUInt32();
    maxMemType42 = reader.readUInt32();
    minMemType1 = reader.readUInt32();
    maxMemType1 = reader.readUInt32();

    // If the version is 1.0 or 3.0, the table ends here.

    // The additional entries for versions 2.0 and 2.5 are shown below.
    // Apple has defined a version 4.0 for use with Apple Advanced Typography (AAT), which is described in their documentation.

    switch (versionRaw) {
      case 0x00010000: // version 1
        version = 1;
        break;
      case 0x00030000: // version 3
        version = 3;
        break;
      case 0x00020000: // version 2
        {
          version = 2;

          // Version 2.0
          // This is the version required in order to supply PostScript glyph names for fonts which do not supply them elsewhere.
          // A version 2.0 'post' table can be used in fonts with TrueType or CFF version 2 outlines.

          _glyphNames = {};
          final numOfGlyphs = reader.readUInt16();
          final glyphNameIndice = Utils.readUInt16Array(reader, numOfGlyphs);
          final stdMacGlyphNames = MacPostFormat1.getStdMacGlyphNames();

          // The table contains the glyph name index for each glyph.
          // If the index is between 0 and 257, it refers to the standard Macintosh glyph set.
          // If the index is between 258 and 65535, it refers to the Pascal strings at the end of the table.
          
          // We need to read the Pascal strings first if there are any custom names.
          // But the structure is:
          // uint16 numberOfGlyphs
          // uint16 glyphNameIndex[numGlyphs]
          // int8 names[numberNewGlyphs] (Pascal strings)
          
          // So we iterate through glyphNameIndice. If index >= 258, we need to fetch from the names array.
          // The names array is sequential. The first name corresponds to index 258, the second to 259, etc.
          
          // Let's collect the custom names first.
          // The number of custom names is the max index - 257.
          // But we don't know the max index easily without scanning.
          // Actually, the spec says: "Glyph names with length bytes [variable] (a Pascal string)".
          // And "If the name index is between 258 and 65535, then subtract 258 and use that to index into the list of Pascal strings at the end of the table."
          
          // Wait, the C# implementation reads the string immediately when it encounters an index >= 258?
          // No, the C# implementation loop looks wrong or I am misinterpreting it.
          // C# code:
          /*
            for (ushort i = 0; i < numOfGlyphs; ++i)
            {
                ushort glyphNameIndex = glyphNameIndice[i];
                if (glyphNameIndex < 258)
                {
                    _glyphNames[i] = stdMacGlyphNames[glyphNameIndex];
                }
                else
                {
                    int len = reader.ReadByte(); //name len 
                    _glyphNames.Add(i, System.Text.Encoding.UTF8.GetString(reader.ReadBytes(len), 0, len));
                }
            }
          */
          // This C# code implies that for every glyph with index >= 258, there is a string immediately following?
          // That doesn't match the spec "index into the list of Pascal strings".
          // If two glyphs point to index 258, do we read the string twice?
          // The spec says: "The glyph name array maps the glyphs in this font to name index."
          // And then "names[numberNewGlyphs]".
          // So the strings are stored sequentially at the end.
          // Index 258 is the 0th string in the `names` array.
          // Index 259 is the 1st string.
          
          // The C# code seems to assume that the `glyphNameIndex` array is sorted or that the strings appear in the order they are referenced?
          // Or maybe the C# code is actually buggy for fonts that reuse names or have out-of-order indices?
          // Let's look at the spec again.
          // "names[numberNewGlyphs]"
          // "Glyph names with length bytes [variable] (a Pascal string)."
          
          // If I have glyph A pointing to 258 and glyph B pointing to 258.
          // The file will have ONE string for 258.
          // The C# code reads a string every time it sees an index >= 258. This consumes the stream.
          // If the indices are 258, 259, 260... in order, it works.
          // If the indices are 258, 258... it would read two strings, which is wrong.
          
          // However, usually `glyphNameIndex` for custom names are assigned sequentially starting from 258.
          // But we should read all strings into a list first?
          // We don't know how many strings there are unless we find the max index.
          
          // Let's scan for the max index.
          int maxIndex = 0;
          for (var idx in glyphNameIndice) {
            if (idx > maxIndex) maxIndex = idx;
          }
          
          List<String> customNames = [];
          if (maxIndex >= 258) {
            int numCustomNames = maxIndex - 257;
            for (int i = 0; i < numCustomNames; i++) {
              int len = reader.readByte();
              String name = utf8.decode(reader.readBytes(len));
              customNames.add(name);
            }
          }
          
          for (var i = 0; i < numOfGlyphs; ++i) {
            int glyphNameIndex = glyphNameIndice[i];
            if (glyphNameIndex < 258) {
              if (glyphNameIndex < stdMacGlyphNames.length) {
                _glyphNames![i] = stdMacGlyphNames[glyphNameIndex];
              }
            } else {
              int customIndex = glyphNameIndex - 258;
              if (customIndex < customNames.length) {
                _glyphNames![i] = customNames[customIndex];
              }
            }
          }
        }
        break;
      case 0x00025000: // version 2.5
        // deprecated
        // throw UnimplementedError("PostTable version 2.5 is deprecated and not supported.");
        break;
      default:
        // throw UnimplementedError("PostTable version $versionRaw not supported.");
        break;
    }
  }

  int getGlyphIndex(String glyphName) {
    if (_glyphNames == null) {
      return 0; // not found!
    }
    
    if (_glyphIndiceByName == null) {
      // create a cache
      _glyphIndiceByName = {};
      _glyphNames!.forEach((key, value) {
        _glyphIndiceByName![value] = key;
      });
    }
    
    return _glyphIndiceByName![glyphName] ?? 0;
  }
}

class MacPostFormat1 {
  static List<String> getStdMacGlyphNames() {
    return [
      ".notdef", ".null", "nonmarkingreturn", "space", "exclam", "quotedbl", "numbersign", "dollar",
      "percent", "ampersand", "quotesingle", "parenleft", "parenright", "asterisk", "plus", "comma",
      "hyphen", "period", "slash", "zero", "one", "two", "three", "four", "five", "six", "seven",
      "eight", "nine", "colon", "semicolon", "less", "equal", "greater", "question", "at", "A", "B",
      "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U",
      "V", "W", "X", "Y", "Z", "bracketleft", "backslash", "bracketright", "asciicircum", "underscore",
      "grave", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q",
      "r", "s", "t", "u", "v", "w", "x", "y", "z", "braceleft", "bar", "braceright", "asciitilde",
      "Adieresis", "Aring", "Ccedilla", "Eacute", "Ntilde", "Odieresis", "Udieresis", "aacute",
      "agrave", "acircumflex", "adieresis", "atilde", "aring", "ccedilla", "eacute", "egrave",
      "ecircumflex", "edieresis", "iacute", "igrave", "icircumflex", "idieresis", "ntilde", "oacute",
      "ograve", "ocircumflex", "odieresis", "otilde", "uacute", "ugrave", "ucircumflex", "udieresis",
      "dagger", "degree", "cent", "sterling", "section", "bullet", "paragraph", "germandbls",
      "registered", "copyright", "trademark", "acute", "dieresis", "notequal", "AE", "Oslash",
      "infinity", "plusminus", "lessequal", "greaterequal", "yen", "mu", "partialdiff", "summation",
      "product", "pi", "integral", "ordfeminine", "ordmasculine", "Omega", "ae", "oslash", "questiondown",
      "exclamdown", "logicalnot", "radical", "florin", "approxequal", "Delta", "guillemotleft",
      "guillemotright", "ellipsis", "nonbreakingspace", "Agrave", "Atilde", "Otilde", "OE", "oe",
      "endash", "emdash", "quotedblleft", "quotedblright", "quoteleft", "quoteright", "divide",
      "lozenge", "ydieresis", "Ydieresis", "fraction", "currency", "guilsinglleft", "guilsinglright",
      "fi", "fl", "daggerdbl", "periodcentered", "quotesinglbase", "quotedblbase", "perthousand",
      "Acircumflex", "Ecircumflex", "Aacute", "Edieresis", "Egrave", "Iacute", "Icircumflex",
      "Idieresis", "Igrave", "Oacute", "Ocircumflex", "apple", "Ograve", "Uacute", "Ucircumflex",
      "Ugrave", "dotlessi", "circumflex", "tilde", "macron", "breve", "dotaccent", "ring", "cedilla",
      "hungarumlaut", "ogonek", "caron", "Lslash", "lslash", "Scaron", "scaron", "Zcaron", "zcaron",
      "brokenbar", "Eth", "eth", "Yacute", "yacute", "Thorn", "thorn", "minus", "multiply",
      "onesuperior", "twosuperior", "threesuperior", "onehalf", "onequarter", "threequarters",
      "franc", "Gbreve", "gbreve", "Idotaccent", "Scedilla", "scedilla", "Cacute", "cacute",
      "Ccaron", "ccaron", "dcroat"
    ];
  }
}
