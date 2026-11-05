# BV-01 — inspeção inicial do código do bairro

Inspeção parcial realizada por leitura dos arquivos da branch `feature/bairro-vivo-2`. Não equivale a auditoria completa de imagens ou execução no Godot.

## Evidências
- `scripts/VizinhancaComercial.gd`: cinco fachadas vizinhas, árvores `arvore_copa_redonda` e `arvore_florida`, objetos urbanos e veículos estáticos. Os objetos são `Sprite2D`, com `catalogo_id`, pivô e escala do catálogo visual.
- `scripts/CatalogoVizinhanca.gd`: catálogo de vegetação com oito IDs, incluindo `arvore_copa_alongada`, `arvore_copa_redonda` e `arvore_florida`; caminhos PNG originais preservados.
- `scripts/MundoVivo.gd`: simulação manual de pedestres e veículos, densidade por horário/clima/evento, rotas e sinal de chegada à loja. Não substituir por outro gerenciador paralelo.
- `docs/auditoria/03_AUDITORIA_SPRITES.md`: inventário histórico e ressalvas de aprovação artística; não usar contagens históricas como inventário atualizado sem conferência.

## Implementação experimental
- `scripts/Neighborhood/VentoCopa.gd`: componente **opt-in**, anexável como filho de `Sprite2D`, com shader temporário que desloca pixels no alto da copa, sem alterar arquivos PNG nem posições de chão.
- Não está ligado às instâncias de `VizinhancaComercial`. Não existem frames PNG de animação aprovados nesta entrega.
- O efeito é uma **prévia técnica reversível**, não a animação definitiva em spritesheets. É preciso validar se o deslocamento preserva a aparência pixel art; se não, substituir por quadros de copa desenhados individualmente.

## Próximas verificações antes da integração
1. Renderizar a árvore original e a prévia lado a lado em Godot 4.4.x.
2. Confirmar que o material de `Sprite2D` não está sendo usado por outro efeito e que o filtro nearest permanece.
3. Validar pivô/footprint e orientação externa U=(64,20), V=(-64,32).
4. Verificar Godot headless e renderização; inspecionar erros de shader.
5. Aprovar a aparência antes de habilitar no mapa; medir FPS em Android.
6. Para NPCs avançados, mapear funções atuais de `MundoVivo.gd` e ampliar estados sem quebrar rotas e testes existentes.

**Não executado nesta etapa:** testes Godot, APK, auditoria visual completa e integração das árvores na cena.
