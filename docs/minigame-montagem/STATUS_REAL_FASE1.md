# Status real da Fase 1 — 2026-11-04

## Concluído
- Branch isolada `feature/auditoria-sprites-montagem-v05`.
- Auditoria inicial e inspeção ampliada de seis sprites, com problemas documentados.
- Inventário local de 61 PNGs: todos decodificados, com alfa opaco e transparente; SHA-256 e dimensões registrados em pacote ZIP entregue na conversa.
- Catálogo GDScript na branch mapeia os 61 caminhos.
- Ferramenta Python de auditoria e cena de inspeção adicionadas à branch.

## Pendente — NÃO DECLARAR FASE CONCLUÍDA
- Upload dos 61 PNGs binários ao GitHub na branch (o pacote ZIP está disponível na conversa, não versionado).
- Revisão visual individual dos 55 PNGs restantes.
- Remoção/edição dos resíduos de recorte e correção das perspectivas incompatíveis.
- Criação e validação de pivôs, escala e âncoras de encaixe.
- Importação e teste de renderização no Godot; não há Godot executável no ambiente desta execução.
- Testes em Android/APK.

## Critério de aceite
Todos os PNGs devem estar na branch, com recortes corrigidos e coerentes; uma cena Godot deve carregar o catálogo sem recursos faltantes; gabinete, placa e CPU devem compor sem sobreposição indevida; teste Godot e Android devem passar.

Não houve alteração na `main`.
