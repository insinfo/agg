# Exemplos da Biblioteca Typography

Esta pasta contém exemplos de uso da biblioteca Typography para Dart.

## Exemplos Disponíveis

### 1. typography_example.dart

Demonstra as capacidades básicas da biblioteca usando uma fonte de teste criada programaticamente.

**Funcionalidades demonstradas:**
- Criar uma fonte de teste
- Calcular escalas para diferentes tamanhos de fonte
- Mapear caracteres Unicode para índices de glifos
- Obter métricas de glifos (advance width, left side bearing)
- Fazer layout de texto
- Escalar planos de glifos para pixels
- Suporte a emoji e caracteres especiais
- Conversão de pontos para pixels em diferentes DPIs

**Como executar:**
```bash
dart run example/typography_example.dart
```

**Saída esperada:**
```
=== Typography Library Example ===

1. Criando uma fonte de teste...
   Fonte: Demo Sans
   Subfamília: Regular
   Glifos: 100
   UnitsPerEm: 1000
   ...
```

### 2. load_font_example.dart

Exemplo placeholder para carregamento de arquivos TrueType/OpenType reais.

**Status:** Este exemplo será implementado na **Fase 3** do projeto, quando o parser completo de arquivos de fonte for adicionado.

**Como usar (quando implementado):**
```bash
# Windows
dart run example/load_font_example.dart C:\Windows\Fonts\arial.ttf

# Linux
dart run example/load_font_example.dart /usr/share/fonts/truetype/dejavu/DejaVuSans.ttf

# macOS
dart run example/load_font_example.dart /System/Library/Fonts/Helvetica.ttc
```

## Conceitos Demonstrados

### Sistema de Coordenadas

A biblioteca usa dois sistemas de coordenadas:

1. **Unidades de Fonte (Font Units):** Valores inteiros no espaço de design da fonte
   - Definido por `unitsPerEm` (geralmente 1000 ou 2048)
   - Usado em `UnscaledGlyphPlan`

2. **Pixels:** Valores float no espaço da tela
   - Calculado multiplicando unidades de fonte pela escala
   - Usado em `GlyphPlan`

### Conversão de Escalas

```dart
// Calcular escala para tamanho específico em pixels
final scale = typeface.calculateScaleToPixel(16.0);

// Ou a partir de pontos
final scale = typeface.calculateScaleToPixelFromPointSize(12.0);

// Converter pontos para pixels
final pixels = Typeface.convertPointsToPixels(12.0); // 72 DPI padrão
final pixels = Typeface.convertPointsToPixels(12.0, 96); // 96 DPI
```

### Pipeline de Layout de Texto

1. **String → Codepoints:** Converte string para codepoints Unicode (suporta surrogate pairs)
2. **Codepoints → Glyph Indices:** Usa tabela CMAP para mapear para índices
3. **Glyph Indices → Unscaled Plans:** Cria planos com métricas em unidades de fonte
4. **Unscaled Plans → Scaled Plans:** Aplica escala para converter para pixels

```dart
final glyphLayout = GlyphLayout();
glyphLayout.typeface = typeface;

// Layout em unidades de fonte
final unscaledPlans = glyphLayout.layout('Hello World!');

// Converter para pixels (16pt)
final scale = typeface.calculateScaleToPixel(16.0);
final scaledPlans = glyphLayout.generateGlyphPlans(scale);

// Acessar posições
for (var i = 0; i < scaledPlans.count; i++) {
  final plan = scaledPlans[i];
  print('Glyph #${plan.glyphIndex} at x=${plan.x}px, advance=${plan.advanceX}px');
}
```

### Suporte a Unicode

A biblioteca suporta:
- Caracteres BMP (Basic Multilingual Plane): U+0000 a U+FFFF
- Caracteres suplementares via surrogate pairs: U+10000 a U+10FFFF
- Emoji: 🙌, 😀, 👍, etc.

```dart
// Texto com emoji
final plans = glyphLayout.layout('Hello 🙌 World!');
// Cada emoji pode ser 1 ou mais glifos dependendo da fonte
```

## Estrutura do Código

### Principais Classes

#### Typeface
Representa uma fonte completa com todas as suas tabelas e glifos.

```dart
final typeface = Typeface.fromTrueType(...);

print(typeface.name); // Nome da fonte
print(typeface.unitsPerEm); // Unidades por Em
print(typeface.ascender); // Ascender
print(typeface.descender); // Descender
print(typeface.glyphCount); // Número de glifos
```

#### GlyphLayout
Motor de layout de texto que converte strings em sequências de glifos posicionados.

```dart
final layout = GlyphLayout();
layout.typeface = typeface;

final plans = layout.layout('Text');
```

#### UnscaledGlyphPlan
Plano de glifo em unidades de fonte (valores inteiros).

```dart
class UnscaledGlyphPlan {
  final int glyphIndex;
  final int advanceX;
  final int offsetX;
  final int offsetY;
}
```

#### GlyphPlan
Plano de glifo escalado em pixels (valores float).

```dart
class GlyphPlan {
  final int glyphIndex;
  final double x;
  final double y;
  final double advanceX;
}
```

## Próximas Funcionalidades

### Fase 3: OpenType Features (Planejado)

- **GSUB (Glyph Substitution):**
  - Ligaduras: fi → ﬁ, fl → ﬂ
  - Substituições contextuais
  - Variantes estilísticas

- **GPOS (Glyph Positioning):**
  - Kerning: ajuste de espaçamento entre pares
  - Mark positioning: acentos e diacríticos
  - Posicionamento contextual

- **GDEF (Glyph Definitions):**
  - Classificação de glifos
  - Classes de ligadura
  - Informações de attach points

### Fase 4: File I/O

- Leitura completa de arquivos .ttf e .otf
- Suporte a TrueType Collections (.ttc)
- Cache de fontes
- Validação de arquivos

## Recursos Adicionais

- [Especificação OpenType](https://docs.microsoft.com/en-us/typography/opentype/spec/)
- [TrueType Reference Manual](https://developer.apple.com/fonts/TrueType-Reference-Manual/)
- [Documentação do projeto](../doc/roteiro.md)

## Contribuindo

Para adicionar novos exemplos:

1. Crie um novo arquivo `.dart` nesta pasta
2. Documente o exemplo neste README
3. Adicione comentários explicativos no código
4. Teste com `dart run example/seu_exemplo.dart`

## Status do Projeto

- ✅ **Fase 0:** Estrutura e utilitários (100%)
- ✅ **Fase 1:** Análise de arquivo de fonte (100%)
- 🔄 **Fase 2:** Motor de layout de texto (20%)
- ⏳ **Fase 3:** Features OpenType avançadas (0%)
- ⏳ **Fase 4:** File I/O completo (0%)

**Última atualização:** 2025-01-07
