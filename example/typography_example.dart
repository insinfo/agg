// Exemplo de uso da biblioteca Typography
// Este exemplo demonstra como usar as funcionalidades básicas implementadas

import 'package:agg/typography.dart';

void main() {
  print('=== Typography Library Example ===\n');

  // 1. Criar uma fonte de teste
  print('1. Criando uma fonte de teste...');
  final typeface = createTestTypeface();
  print('   Fonte: ${typeface.name}');
  print('   Subfamília: ${typeface.fontSubFamily}');
  print('   Glifos: ${typeface.glyphCount}');
  print('   UnitsPerEm: ${typeface.unitsPerEm}');
  print('   Ascender: ${typeface.ascender}');
  print('   Descender: ${typeface.descender}\n');

  // 2. Escalar fonte para tamanho específico
  print('2. Calculando escala para diferentes tamanhos...');
  final sizes = [12.0, 16.0, 24.0, 48.0];
  for (final pointSize in sizes) {
    final scale = typeface.calculateScaleToPixelFromPointSize(pointSize);
    final pixels = Typeface.convertPointsToPixels(pointSize);
    print('   ${pointSize}pt = ${pixels.toStringAsFixed(1)}px, scale: ${scale.toStringAsFixed(6)}');
  }
  print('');

  // 3. Mapear caracteres para glifos
  print('3. Mapeando caracteres para índices de glifos...');
  final testChars = ['A', 'B', 'C', 'Z', '!', '?'];
  for (final char in testChars) {
    final codepoint = char.codeUnitAt(0);
    final glyphIndex = typeface.getGlyphIndex(codepoint);
    print('   \'$char\' (U+${codepoint.toRadixString(16).toUpperCase().padLeft(4, '0')}) → Glyph #$glyphIndex');
  }
  print('');

  // 4. Obter métricas de glifos
  print('4. Obtendo métricas de glifos...');
  for (final char in ['A', 'W', 'i']) {
    final codepoint = char.codeUnitAt(0);
    final glyphIndex = typeface.getGlyphIndex(codepoint);
    final advanceWidth = typeface.getHAdvanceWidthFromGlyphIndex(glyphIndex);
    final leftSideBearing = typeface.getHFrontSideBearingFromGlyphIndex(glyphIndex);
    print('   \'$char\': advance=$advanceWidth, lsb=$leftSideBearing');
  }
  print('');

  // 5. Layout de texto
  print('5. Fazendo layout de texto...');
  final glyphLayout = GlyphLayout();
  glyphLayout.typeface = typeface;
  
  final text = 'Hello World!';
  print('   Texto: "$text"');
  
  final unscaledPlans = glyphLayout.layout(text);
  print('   Número de glifos: ${unscaledPlans.count}');
  
  // Mostrar alguns planos
  print('   Primeiros glifos (unscaled):');
  for (var i = 0; i < 5 && i < unscaledPlans.count; i++) {
    final plan = unscaledPlans[i];
    print('     [$i] Glyph #${plan.glyphIndex}, advance: ${plan.advanceX}');
  }
  print('');

  // 6. Escalar para pixels
  print('6. Gerando planos escalados para 16px...');
  final scale = typeface.calculateScaleToPixel(16.0);
  final scaledPlans = glyphLayout.generateGlyphPlans(scale);
  
  print('   Primeiros glifos (escalados):');
  var totalWidth = 0.0;
  for (var i = 0; i < 5 && i < scaledPlans.count; i++) {
    final plan = scaledPlans[i];
    print('     [$i] Glyph #${plan.glyphIndex}, x: ${plan.x.toStringAsFixed(2)}px, advance: ${plan.advanceX.toStringAsFixed(2)}px');
    totalWidth += plan.advanceX;
  }
  print('   Largura dos 5 primeiros: ${totalWidth.toStringAsFixed(2)}px\n');

  // 7. Testar emoji e caracteres especiais
  print('7. Testando caracteres especiais...');
  final specialTexts = ['Hello 🙌', 'Café', 'Über'];
  for (final specialText in specialTexts) {
    final plans = glyphLayout.layout(specialText);
    print('   "$specialText" → ${plans.count} glifos');
  }
  print('');

  // 8. Demonstrar conversão de pontos para pixels
  print('8. Conversão de unidades...');
  print('   12pt @ 72 DPI = ${Typeface.convertPointsToPixels(12, 72)}px');
  print('   12pt @ 96 DPI = ${Typeface.convertPointsToPixels(12, 96)}px');
  print('   12pt @ 144 DPI = ${Typeface.convertPointsToPixels(12, 144)}px');
  print('');

  print('=== Exemplo Concluído ===');
}

/// Cria uma fonte de teste para demonstração
Typeface createTestTypeface() {
  // Criar entrada de nome
  final nameEntry = NameEntry();
  nameEntry.fontName = 'Demo Sans';
  nameEntry.fontSubFamily = 'Regular';
  nameEntry.versionString = '1.0';
  nameEntry.postScriptName = 'DemoSans-Regular';

  // Criar glifos (100 glifos de exemplo)
  final glyphs = List.generate(100, (i) {
    if (i == 0) {
      // Glyph 0 é sempre o .notdef (vazio)
      return Glyph.empty(0);
    }
    
    // Criar glifos simples com contornos básicos
    return Glyph.fromTrueType(
      glyphPoints: [
        GlyphPointF(0, 0, true),
        GlyphPointF(100, 0, true),
        GlyphPointF(100, 100, true),
        GlyphPointF(0, 100, true),
      ],
      contourEndPoints: [3],
      bounds: Bounds(0, 0, 100, 100),
      glyphIndex: i,
    );
  });

  // Criar tabela de métricas horizontais
  // Simular larguras variadas para diferentes caracteres
  final hmtx = HorizontalMetrics(100, 100);
  // Em uma implementação real, isso seria populado com dados reais da fonte

  // Criar tabela OS/2
  final os2 = OS2Table();
  os2.sTypoAscender = 800;
  os2.sTypoDescender = -200;
  os2.sTypoLineGap = 100;
  os2.usWinAscent = 900;
  os2.usWinDescent = 300;

  // Criar tabela cmap (mapeamento básico)
  final cmap = Cmap();
  // Em uma implementação real, isso seria populado com mapeamentos reais

  // Criar a fonte
  return Typeface.fromTrueType(
    nameEntry: nameEntry,
    bounds: Bounds(0, -200, 1000, 800),
    unitsPerEm: 1000,
    glyphs: glyphs,
    horizontalMetrics: hmtx,
    os2Table: os2,
    cmapTable: cmap,
    filename: 'demo_sans.ttf',
  );
}
