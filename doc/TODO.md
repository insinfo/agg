# TODO - Porte da Biblioteca Typography para Dart

## Status Geral
**Projeto:** Porte da biblioteca Typography (agg-sharp) de C# para Dart  
**Data de Início:** 07 de Novembro de 2025  
**Status Atual:** Em Progresso - Fase 3 (AGG Core) - 30%
continue portando o C:\MyDartProjects\agg\agg-sharp\agg para dart e validando rasterização
---

## ✅ Fase 0: Estrutura de Pastas e Utilitários Essenciais - CONCLUÍDO

### Estrutura de Pastas
- [x] Criada estrutura `lib/src/typography/`
- [x] Criada estrutura `lib/src/typography/io/`
- [x] Criada estrutura `lib/src/typography/openfont/`
- [x] Criada estrutura `lib/src/typography/openfont/tables/`
- [x] Criada estrutura `lib/src/typography/text_layout/`

### Utilitários Essenciais
- [x] `ByteOrderSwappingBinaryReader` - `lib/src/typography/io/byte_order_swapping_reader.dart`
  - Leitura big-endian usando ByteData
  - Todos os métodos implementados (readUInt16, readInt16, readUInt32, readInt32, readUInt64, readInt64, readDouble, readFloat, readBytes, readTag)
  - ✅ **Testado e validado**

- [x] `Utils` - `lib/src/typography/openfont/tables/utils.dart`
  - readF2Dot14 (formato 2.14)
  - readFixed (formato 16.16)
  - readUInt24
  - tagToString
  - readUInt16Array, readUInt32Array
  - Classe `Bounds` para bounding boxes
  - ✅ **Testado e validado**

### Classes Base para Tabelas
- [x] `TableEntry` - `lib/src/typography/openfont/tables/table_entry.dart`
  - Classe abstrata base para todas as tabelas
  - `UnreadTableEntry` para tabelas não lidas
  - ✅ **Testado e validado**

- [x] `TableHeader` - `lib/src/typography/openfont/tables/table_entry.dart`
  - Informações do cabeçalho de cada tabela
  - Tag, checksum, offset, length
  - ✅ **Testado e validado**

- [x] `TableEntryCollection` - `lib/src/typography/openfont/tables/table_entry.dart`
  - Coleção de tabelas indexadas por nome
  - ✅ **Testado e validado**

### Leitores Principais
- [x] `OpenFontReader` - `lib/src/typography/openfont/open_font_reader.dart`
  - Versão inicial simplificada
  - Suporte para preview de fontes
  - Detecção de TrueType Collection (TTC)
  - Detecção de WOFF/WOFF2 (não implementado ainda)
  - ✅ **Estrutura criada e testada**

---

## ✅ Fase 1: Análise do Arquivo da Fonte - CONCLUÍDA

### Tabelas Simples (Leitura Sequencial) - ✅ CONCLUÍDO
- [x] `Head` - `lib/src/typography/openfont/tables/head.dart`
  - Tabela 'head' (Font Header)
  - Informações globais da fonte
  - UnitsPerEm, bounds, flags, version
  - ✅ **Implementado e testado** (20 testes passando)

- [x] `MaxProfile` - `lib/src/typography/openfont/tables/maxp.dart`
  - Tabela 'maxp' (Maximum Profile)
  - Requisitos de memória da fonte
  - Suporte para versões 0.5 (CFF) e 1.0 (TrueType)
  - ✅ **Implementado e testado** (20 testes passando)

- [x] `HorizontalHeader` - `lib/src/typography/openfont/tables/hhea.dart`
  - Tabela 'hhea' (Horizontal Header)
  - Informações de layout horizontal
  - Ascent, descent, lineGap, metrics count
  - ✅ **Implementado e testado** (20 testes passando)

- [x] `OS2` - `lib/src/typography/openfont/tables/os2.dart`
  - Tabela 'OS/2' (OS/2 and Windows Metrics)
  - Suporte para versões 0-5
  - ✅ **Implementado e testado** (24 testes passando)
  
### Tabelas de Métricas
- [x] `HorizontalMetrics` - `lib/src/typography/openfont/tables/hmtx.dart`
  - Tabela 'hmtx'
  - Métricas horizontais de cada glifo
  - Suporte para fontes proporcionais e monoespaçadas
  - ✅ **Implementado e testado** (29 testes passando)

### Tabela de Nomes
- [x] `NameEntry` - `lib/src/typography/openfont/tables/name_entry.dart`
  - Tabela 'name'
  - Nomes da fonte em múltiplas codificações
  - Suporte para UTF-16BE e UTF-8
  - ✅ **Implementado e testado** (33 testes passando)

### Tabela de Mapeamento de Caracteres
- [x] `Cmap` - `lib/src/typography/openfont/tables/cmap.dart`
  - Tabela 'cmap' (Character to Glyph Index Mapping)
  - CharMapFormat4 (formato mais comum)
  - CharMapFormat12 (para Unicode completo)
  - CharMapFormat0 (para fontes simples)
  - ✅ **Implementado e testado** (37 testes passando)

### Tabelas de Glifo
- [x] `GlyphLocations` - `lib/src/typography/openfont/tables/loca.dart`
  - Tabela 'loca' (Index to Location)
  - Offsets dos glifos
  - Suporte para versão curta (16-bit) e longa (32-bit)
  - ✅ **Implementado e testado** (43 testes passando)

- [x] `Glyf` - `lib/src/typography/openfont/tables/glyf.dart`
  - Tabela 'glyf' (Glyph Data)
  - Dados dos contornos dos glifos
  - Glifos simples e compostos
  - Transformações 2x2 matrix
  - ✅ **Implementado e testado** (43 testes passando)

- [x] `Glyph` - `lib/src/typography/openfont/glyph.dart`
  - Representação de um glifo
  - GlyphPointF com coordenadas e flag onCurve
  - GlyphClassKind enum
  - ✅ **Implementado e testado** (43 testes passando)

### Typeface (Objeto Central)
- [x] `Typeface` - `lib/src/typography/openfont/typeface.dart`
  - Objeto central que contém todas as tabelas
  - Interface principal para acesso à fonte
  - Métricas de fonte (ascender, descender, lineGap)
  - Acesso a glifos por índice ou codepoint
  - Utilitários de escala (points → pixels)
  - ✅ **Implementado e testado** (47 testes passando)

---

## � Fase 2: Motor de Layout de Texto - EM PROGRESSO

### Estruturas de Dados
- [x] `GlyphPlan` - `lib/src/typography/text_layout/glyph_plan.dart`
  - UnscaledGlyphPlan (unidades da fonte)
  - GlyphPlan (pixels escalados)
  - GlyphPlanSequence (sequência de glifos)
  - ✅ **Implementado e testado**

- [x] `GlyphIndexList` - `lib/src/typography/text_layout/glyph_index_list.dart`
  - Lista de índices de glifos
  - Mapeamento para codepoints originais
  - Suporte para substituição (ligaduras)
  - ✅ **Implementado e testado**

- [ ] `GlyphPosStream` - `lib/src/typography/text_layout/glyph_pos_stream.dart`
  - PENDENTE

### Motor Principal
- [x] `GlyphLayout` - `lib/src/typography/text_layout/glyph_layout.dart`
  - Conversão texto → codepoints → glifos
  - Geração de planos de layout
  - Suporte a surrogate pairs (emoji, etc.)
  - Escalamento para pixels
  - ✅ **Versão básica implementada e testada**
  - ⏳ GSUB/GPOS pendente

### Tabelas de Layout Avançado
- [x] `GSUB` - `lib/src/typography/openfont/tables/gsub.dart` (Substituição de Glifos)
  - ✅ Tipos de Lookup 1, 2, 3, 4 implementados
  - ✅ Ligaduras (fi, fl, ffi, etc.)
  - ✅ Substituições contextuais (parcial)
  - ✅ `ScriptList`, `FeatureList`, `CoverageTable`, `ClassDefTable` portados

- [ ] `GPOS` - `lib/src/typography/openfont/tables/gpos.dart` (Posicionamento de Glifos)
  - Kerning
  - Posicionamento de marcas
  - PENDENTE

- [ ] `GDEF` - `lib/src/typography/openfont/tables/gdef.dart`
  - Definições de glifos
  - PENDENTE

- [ ] `BASE` - `lib/src/typography/openfont/tables/base.dart`
  - Linhas de base
  - PENDENTE

---

## 🚀 Fase 3: AGG Core - EM PROGRESSO

### Primitives
- [x] `IColorType` - `lib/src/agg/primitives/i_color_type.dart`
- [x] `Color` - `lib/src/agg/primitives/color.dart`
- [x] `ColorF` - `lib/src/agg/primitives/color_f.dart`
- [x] `RectangleInt` - `lib/src/agg/primitives/rectangle_int.dart`
- [x] `RectangleDouble` - `lib/src/agg/primitives/rectangle_double.dart`
- [x] `Point2D` - `lib/src/agg/primitives/point2d.dart`

### Transform
- [x] `Affine` - `lib/src/agg/transform/affine.dart`
- [x] `Perspective` - `lib/src/agg/transform/perspective.dart`
- [x] `Bilinear` - `lib/src/agg/transform/bilinear.dart`

### Vertex Source
- [x] `PathCommands` - `lib/src/agg/vertex_source/path_commands.dart`
- [x] `VertexData` - `lib/src/agg/vertex_source/vertex_data.dart`
- [x] `IVertexSource` - `lib/src/agg/vertex_source/i_vertex_source.dart`
- [x] `VertexStorage` - `lib/src/agg/vertex_source/vertex_storage.dart`
- [x] `Arc` - `lib/src/agg/vertex_source/arc.dart`
- [x] `Ellipse` - `lib/src/agg/vertex_source/ellipse.dart`
- [x] `RoundedRect` - `lib/src/agg/vertex_source/rounded_rect.dart`

### Rasterizer
- [ ] `ImageLineRenderer` (faltar caps/joins fieis, spans via accessors)
- [x] `RasterizerCellsAA` (acumulador AA completo)
- [x] `VectorClipper` / `ClipLiangBarsky` (clipping de linhas)
- [x] `RasterizerScanline` (core + gamma)
- [x] `Scanline` caches (bin/packed/unpacked) + hit-test
- [ ] `Outline AA`
  - [x] `line_aa_basics.dart`
  - [x] `line_aa_vertex_sequence.dart`
  - [x] `agg_dda_line.dart`
  - [x] `rasterizer_outline_aa.dart` (estrutura; renderer pendente)
  - [x] `scanline_bin.dart` / `scanline_packed8.dart` / `scanline_unpacked8.dart`
  - [x] `scanline_hit_test.dart` (utilitário)

### Image
- [x] `ImageBuffer` (RGBA8888 básico)
- [x] `Blenders` (RGBA straight alpha inicial)

---

## 🎯 Fase 3: Finalização - NÃO INICIADO

- [ ] Extensões de Escala de Pixels
- [ ] API Pública (Barrel File) - `lib/typography.dart`
- [ ] Documentação completa
- [ ] Testes de integração

---

## 📊 Métricas do Projeto

### Arquivos Portados: 19/50+ (38%)
Atual: ~26/50 (52%) com rasterização AA, ImageBuffer, accessors e caps AA básicos.

**Fase 1 - Análise de Fontes:**
- ByteOrderSwappingBinaryReader ✅
- Utils ✅
- TableEntry ✅
- TableHeader ✅
- TableEntryCollection ✅
- OpenFontReader ✅
- Head ✅
- MaxProfile ✅
- HorizontalHeader ✅
- OS2Table ✅
- HorizontalMetrics ✅
- NameEntry ✅
- Cmap ✅
- GlyphLocations ✅
- Glyf ✅
- Glyph & GlyphPointF ✅
- Typeface ✅

**Fase 2 - Layout de Texto:**
- GlyphPlan ✅
- GlyphIndexList ✅
- **GlyphLayout** ✅ (versão básica)
- **GSUB** ✅ (parcial)
- ScriptList, FeatureList, CoverageTable, ClassDefTable ✅

### Testes: 69/69 passando (100%)

**Fase 1 - OpenFont Tables (47 testes):**
- ByteOrderSwappingBinaryReader: 5 testes ✅
- Utils: 4 testes ✅
- Bounds: 3 testes ✅
- Head: 3 testes ✅
- MaxProfile: 3 testes ✅
- HorizontalHeader: 2 testes ✅
- OS2Table: 4 testes ✅
- HorizontalMetrics: 5 testes ✅
- NameEntry: 4 testes ✅
- Cmap: 4 testes ✅
- GlyphLocations: 2 testes ✅
- Glyph & GlyphPointF: 4 testes ✅
- Typeface: 4 testes ✅

**Fase 2 - Text Layout (14 testes):**
- UnscaledGlyphPlan: 2 testes ✅
- UnscaledGlyphPlanList: 2 testes ✅
- GlyphPlan: 1 teste ✅
- GlyphIndexList: 4 testes ✅
- **GlyphLayout: 5 testes** ✅

### Próximos Passos Imediatos
1. Finalizar renderer para `RasterizerOutlineAA` (LineRenderer + blend).
2. Portar `ScanlineRenderer`/`ImageLineRenderer` e `RasterBufferAccessors` para gerar pixels.
3. Portar `ImageBuffer`/blenders e validar saídas das scanlines.
4. Avançar GSUB/GPOS integração completa no GlyphLayout (kerning/marks).


---

## 🐛 Problemas Conhecidos
Nenhum no momento.

---

## 📝 Notas Técnicas

### Diferenças C# → Dart
- **ref/out parameters**: Convertidos para retorno de objetos/records
- **struct → class**: Todas as structs C# viram classes Dart
- **unsafe code**: Substituído por Uint8List e ByteData
- **BinaryReader**: Substituído por ByteOrderSwappingBinaryReader customizado

### Decisões de Design
- Usar `int` para todos os tipos numéricos (Dart não diferencia uint/int em tempo de compilação)
- Usar `ByteData` com `Endian.big` para leitura big-endian
- Manter nomes de campos em camelCase (convenção Dart)
- Manter estrutura de pastas similar ao original

---

**Última Atualização:** 20 de Novembro de 2025 - 19:20  
**Responsável:** insinfo

---

## 🎉 Marcos Importantes

### ✅ Fase 1: Análise do Arquivo da Fonte - CONCLUÍDA!
- ✅ Todas as tabelas fundamentais de fontes TrueType/OpenType
- ✅ Leitura completa de glifos simples e compostos
- ✅ Mapeamento de caracteres Unicode para glifos
- ✅ Métricas horizontais completas
- ✅ Objeto Typeface central integrando tudo
- ✅ 47 testes unitários com 100% passando

### 🔄 Fase 2: Motor de Layout de Texto - EM PROGRESSO (20%)
- ✅ Estruturas de dados básicas (GlyphPlan, GlyphIndexList)
- ✅ Motor GlyphLayout básico funcional
- ✅ Suporte a texto simples e emoji (surrogate pairs)
- ✅ Escalamento de fontes para pixels
- ✅ 14 testes unitários com 100% passando
- 🔄 GSUB (ligaduras) - PARCIALMENTE IMPLEMENTADO
- ⏳ GPOS (kerning) - PENDENTE

### Próximo Marco:
**Completar Fase 2** - Implementar GSUB e GPOS para suporte completo a features OpenType (ligaduras, kerning, posicionamento de marcas, etc.)
