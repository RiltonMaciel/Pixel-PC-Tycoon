# Fase 1 — Revisão visual de sprites (amostra de 6)

Branch: `feature/auditoria-sprites-montagem-v05`.

## Arquivos examinados em ampliação nearest-neighbor sobre xadrez

- `cabinets/ironbox/alpha_aberto_vazio.png` (196×195)
- `motherboards/hexacore/h450m.png` (137×118)
- `cpus/vortex/c5_5600.png` (102×105)
- `thermal_paste/tp_05.png` (113×74)
- `cables/sata.png` (94×81)
- `hardware/trava_aberta.png` (109×65)

## Defeitos encontrados

1. **Perspectivas incompatíveis:** gabinete oblíquo, placa-mãe e CPU quase frontais. Apenas redimensionar e girar os PNGs não garante encaixe visual. Criar sprites próprios para o estado instalado.
2. **Resíduos opacos:** `tp_05` apresenta faixas laterais; `sata` contém polígono cinza/marrom; `trava_aberta` contém fundo cinza atrás da peça. A presença de transparência fora do objeto não comprova recorte limpo.
3. **Pasta térmica:** quadros `tp_00..tp_05` são estados estáticos. Aplicação com o dedo requer máscara dinâmica e avaliação de cobertura/quantidade.
4. **Alfa binário:** os seis PNGs inspecionados têm somente pixels opacos ou transparentes; artefatos de cor opacos não são detectados por auditoria do canal alfa.
5. **Encaixes ausentes:** tamanho em pixels não define escala física, pivôs, socket ou zonas de toque.

## Decisão

Os seis sprites examinados **não estão aprovados para composição final no Godot**. Manter originais; limpar os fundos indevidos; estabelecer geometria e pontos de encaixe do IronBox Alpha; criar versões instaladas coerentes da HexaCore H450M e Vortex C5; validar visualmente no Godot.

**Escopo restante:** 55 sprites ainda exigem revisão visual individual. Nenhum PNG foi corrigido ou enviado ao repositório; nenhum minigame foi implementado. A branch `main` permanece intocada.
