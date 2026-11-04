# Fase 1 — Auditoria preliminar de sprites de montagem

Branch: `feature/auditoria-sprites-montagem-v05`
Origem: pacote externo `pixel_pc_tycoon_sprites_individuais.zip`, ainda não versionado nesta branch.

## Verificações realizadas
- 61 PNGs foram abertos e examinados programaticamente.
- Todos puderam ser convertidos para RGBA e possuem pixels transparentes.
- Dimensões dos recortes variam de 48 a 245 px de largura e de 62 a 196 px de altura.
- Nenhum sprite apresentou pixels opacos na borda externa do canvas.
- Isso **não** certifica qualidade: o algoritmo de recorte pode apagar detalhes escuros, preservar halos ou produzir peças com escala/perspectiva incompatíveis.
- Arquivos `alpha_placa_mae`, `alpha_montagem_parcial` e `alpha_completo` são imagens compostas; não devem ser usados como base para sobreposição dos mesmos componentes individuais.

## Próximas tarefas da Fase 1
1. Inspecionar visualmente cada recorte contra a prancha original, com zoom em bordas e detalhes.
2. Corrigir os PNGs defeituosos, preservando pixel art e transparência verdadeira.
3. Estabelecer uma escala-base, pivôs, orientação e pontos de encaixe para gabinete IronBox Alpha, placa HexaCore H450M e CPU Vortex C5.
4. Conferir associação dos nomes fictícios com os IDs existentes em `CatalogoPecas.gd`.
5. Validar sprites no Godot (importação nearest, composição em camadas e alinhamento) antes de aprovar.
6. Somente após essa validação, iniciar a cena da bancada e os minigames.

## Estado
Auditoria automática **preliminar concluída**. Revisão visual, correções, importação no Godot e APK **pendentes**. Nenhum PNG foi aprovado como sprite definitivo e nenhum código de montagem foi alterado.

O relatório completo por arquivo, com dimensões e percentuais de transparência, está disponível como artefato separado nesta conversa.