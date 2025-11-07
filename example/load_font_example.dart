// Exemplo de carregamento de fonte TrueType/OpenType real
// Este exemplo mostra como carregar e usar uma fonte a partir de um arquivo

import 'dart:io';
import 'package:agg/src/typography/openfont/typeface.dart';
import 'package:agg/src/typography/text_layout/glyph_layout.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    print('Uso: dart run example/load_font_example.dart <caminho_para_arquivo.ttf>');
    print('\nExemplos:');
    print('  dart run example/load_font_example.dart C:\\Windows\\Fonts\\arial.ttf');
    print('  dart run example/load_font_example.dart /System/Library/Fonts/Helvetica.ttc');
    return;
  }

  final fontPath = args[0];
  print('=== Carregando Fonte: $fontPath ===\n');

  try {
    // Carregar arquivo da fonte
    final file = File(fontPath);
    if (!file.existsSync()) {
      print('Erro: Arquivo não encontrado: $fontPath');
      return;
    }

    final bytes = file.readAsBytesSync();
    print('Arquivo carregado: ${bytes.length} bytes\n');

    // Criar typeface a partir dos bytes
    // Nota: Esta funcionalidade será implementada na Fase 3
    print('NOTA: A leitura completa de arquivos TrueType/OpenType será');
    print('implementada na Fase 3 do projeto. Por enquanto, veja o');
    print('typography_example.dart para demonstração com fonte de teste.\n');
    
  } catch (e, stackTrace) {
    print('Erro ao carregar fonte: $e');
    print('Stack trace: $stackTrace');
  }
}

// As funções abaixo serão úteis quando a Fase 3 for implementada
// ignore: unused_element
void _printFontInfo(Typeface typeface) {
  print('=== Informações da Fonte ===');
  print('Nome: ${typeface.name}');
  print('Subfamília: ${typeface.fontSubFamily}');
  print('PostScript: ${typeface.postScriptName}');
  print('\nMétricas:');
  print('  Units Per Em: ${typeface.unitsPerEm}');
  print('  Ascender: ${typeface.ascender}');
  print('  Descender: ${typeface.descender}');
  print('  Line Gap: ${typeface.lineGap}');
  print('\nContagem:');
  print('  Glifos: ${typeface.glyphCount}');
  print('\nBounds:');
  print('  XMin: ${typeface.bounds.xMin}');
  print('  YMin: ${typeface.bounds.yMin}');
  print('  XMax: ${typeface.bounds.xMax}');
  print('  YMax: ${typeface.bounds.yMax}');
  print('');
}

// ignore: unused_element
void _demonstrateTextLayout(Typeface typeface) {
  print('=== Layout de Texto ===');
  
  final glyphLayout = GlyphLayout();
  glyphLayout.typeface = typeface;
  
  // Testar diferentes textos
  final texts = [
    'Hello World!',
    'The quick brown fox',
    'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
    'abcdefghijklmnopqrstuvwxyz',
    '0123456789',
    'Typography 2024',
  ];
  
  for (final text in texts) {
    final unscaledPlans = glyphLayout.layout(text);
    
    // Calcular largura total em unidades de fonte
    var totalWidth = 0;
    for (var i = 0; i < unscaledPlans.count; i++) {
      totalWidth += unscaledPlans[i].advanceX;
    }
    
    // Calcular em pixels (16pt)
    final scale = typeface.calculateScaleToPixel(16.0);
    final widthInPixels = totalWidth * scale;
    
    print('  "$text"');
    print('    Glifos: ${unscaledPlans.count}');
    print('    Largura: $totalWidth unidades (${widthInPixels.toStringAsFixed(2)}px @ 16pt)');
  }
  print('');
}

// ignore: unused_element
void _demonstrateCharacterMetrics(Typeface typeface) {
  print('=== Métricas de Caracteres ===');
  
  // Caracteres comuns para análise
  final testChars = [
    'A', 'W', 'M', 'i', 'l', 'j',  // Letras com larguras variadas
    '0', '5', '8',                  // Números
    '.', ',', '!', '?',             // Pontuação
    ' ',                             // Espaço
  ];
  
  print('Char  Unicode   Glyph  Advance  LSB');
  print('----  --------  -----  -------  ---');
  
  for (final char in testChars) {
    final codepoint = char.codeUnitAt(0);
    final glyphIndex = typeface.getGlyphIndex(codepoint);
    
    if (glyphIndex > 0) {
      final advance = typeface.getHAdvanceWidthFromGlyphIndex(glyphIndex);
      final lsb = typeface.getHFrontSideBearingFromGlyphIndex(glyphIndex);
      
      final charDisplay = char == ' ' ? '␣' : char;
      final unicode = 'U+${codepoint.toRadixString(16).toUpperCase().padLeft(4, '0')}';
      
      print('  $charDisplay    $unicode  ${glyphIndex.toString().padLeft(5)}  ${advance.toString().padLeft(7)}  ${lsb.toString().padLeft(3)}');
    }
  }
  print('');
  
  // Demonstrar conversão para diferentes tamanhos
  print('=== Conversão de Tamanhos ===');
  final sizes = [8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 24.0, 36.0, 48.0, 72.0];
  
  print('Tamanho (pt)  Pixels    Escala');
  print('------------  --------  --------');
  
  for (final pointSize in sizes) {
    final pixels = Typeface.convertPointsToPixels(pointSize);
    final scale = typeface.calculateScaleToPixelFromPointSize(pointSize);
    
    print('${pointSize.toString().padLeft(12)}  ${pixels.toStringAsFixed(2).padLeft(8)}  ${scale.toStringAsFixed(6)}');
  }
  print('');
}


