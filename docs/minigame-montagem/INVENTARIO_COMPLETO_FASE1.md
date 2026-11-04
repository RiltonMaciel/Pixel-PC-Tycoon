# Fase 1 — Inventário completo e plano de correção

Branch: `feature/auditoria-sprites-montagem-v05`.

## Inventário
- **61 PNGs** foram medidos individualmente (largura, altura, porcentagem de pixels opacos e semitransparentes).
- Foi gerado relatório completo por arquivo (`AUDITORIA_61_SPRITES_COMPLETA.md`) e planilha CSV para conferência local; ainda não adicionados ao GitHub.
- Foram geradas **3 pranchas** de inspeção, numeradas, com todos os 61 recortes.
- **9 arquivos** recebem alerta preliminar: 6 analisados visualmente e 3 estados compostos do gabinete.
- Os demais **52 arquivos** permanecem **sem aprovação visual**. A verificação automática não equivale a revisão artística.

## Alertas prioritários
1. `cabinets/ironbox/alpha_aberto_vazio.png`: estabelecer escala, pivô e âncoras.
2. `motherboards/hexacore/h450m.png`: criar variante instalada com perspectiva coerente.
3. `cpus/vortex/c5_5600.png`: criar variante instalada no socket.
4. `thermal_paste/tp_05.png`: investigar áreas retangulares opacas.
5. `cables/sata.png`: investigar polígono cinza junto ao cabo.
6. `hardware/trava_aberta.png`: investigar região cinza atrás da trava.
7–9. `cabinets/ironbox/alpha_placa_mae.png`, `alpha_montagem_parcial.png`, `alpha_completo.png`: estados compostos, não devem ser sobrepostos aos componentes individuais já representados.

## Próximo marco
- Revisar visualmente os 52 arquivos ainda não avaliados em detalhe.
- Corrigir os resíduos e preservar os originais para comparação.
- Definir escala, pivôs e encaixes do primeiro conjunto.
- Importar no Godot e validar antes de declarar a fase concluída.

**Nenhum PNG foi corrigido nem integrado ao jogo neste marco. A branch `main` permanece inalterada.**
