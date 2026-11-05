# Bairro Vivo 2.0 — baseline e plano de execução

Status: **BV-01 iniciado; auditoria visual e inventário ainda pendentes**.

## Objetivo
Dar vida à vizinhança do Pixel PC Tycoon com vegetação animada, NPCs avançados (rotinas, interesses, memória), trânsito, clima e eventos, mantendo Android vertical, Godot 4.4.x e funcionamento offline.

## Restrições obrigatórias
- Preservar as fachadas PC Store, cafeteria e mercadinho e todos os sprites aprovados. Não redesenhar, espelhar letreiros, deformar nem substituir artes existentes.
- Projeção **externa assimétrica** de referência: U=(64,20), V=(-64,32). **Interior** usa tiles isométricos 128×64 (2:1). Confirmar visualmente pivôs, soleiras e três cantos da base antes de integrar.
- Cada sprite novo: PNG RGBA com transparência real; uma peça por arquivo (spritesheet somente para animação); manifesto com dimensões, pivot de chão, footprint, direção, escala de importação, frames e status de aprovação.
- Não alterar `main`; apresentar PR e aguardar aprovação antes de merge.
- Não afirmar que testes, sprites ou APK estão prontos sem executá-los/produzi-los.

## BV-01 — auditoria
- [x] Criar branch isolada `feature/bairro-vivo-2`.
- [x] Confirmar `project.godot`: Godot 4.4, viewport 432×768, cena inicial `scenes/RuaComercial.tscn`.
- [ ] Inventariar cenas, scripts e assets reais do bairro; registrar caminho, tamanho, import scale, pivô, orientação e estado.
- [ ] Identificar componentes existentes para evitar duplicação de NPC, navegação, tráfego e clima.
- [ ] Conferir visualmente fachadas e animações com imagens aprovadas.
- [ ] Registrar baseline de erros, testes e captura Android.

## BV-02 — primeiro incremento de vegetação
1. Selecionar uma árvore existente **sem modificar o PNG original**.
2. Criar variação animada derivada em arquivos separados e manifesto, com 6 frames de copa para vento leve e moderado; tronco e sombra imóveis.
3. Criar cena `AnimatedTree.tscn` com `AnimatedSprite2D` ou `AnimationPlayer`, pivot no chão e variação de fase por instância.
4. Integrar uma instância de teste sem quebrar profundidade, colisões e projeção.
5. Testar Godot headless, navegação, renderização e Android; comparar com arte aprovada.

## BV-03 — NPC avançado (planejado)
Máquina de estados: SPAWN → WALK → NOTICE_SHOP → LOOK_WINDOW → DECIDE → ENTER/CONTINUE → SHOP/WAIT/SERVICE → EXIT. Perfis de interesse, orçamento, paciência, horário e memória de visitas. Decisões ponderadas, cooldown para evitar loops e persistência apenas de NPCs relevantes. Simulação distante simplificada.

## Critérios de aceite
- Árvores animadas com base estável, sem deformação e com ciclos dessincronizados.
- NPCs com trajetos válidos, decisões coerentes, sem travar entradas e sem loops.
- Nenhuma fachada/sprite aprovado alterado; projeções respeitadas.
- Saves offline preservados e desempenho Android medido.
- PR revisável antes de merge; APK somente após validação.

## Pendências
Este arquivo é planejamento/baseline inicial, **não comprova implementação das animações ou conclusão da auditoria**.
