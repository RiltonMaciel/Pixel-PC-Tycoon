# Bairro Vivo 2.0 — incremento BV-03 (parada de vitrine)

## Implementado nesta branch
- `MundoVivo.gd` continua responsavel pela navegacao e pelo pool de pedestres; nao foi criado um segundo simulador.
- `NPCInteresse.gd` fornece perfis e decisoes iniciais `entrar`, `observar` e `continuar`.
- Ao chegar a uma rota de loja e decidir **observar**, o pedestre permanece no ponto final por 2,5 segundos e depois e desativado. Nao atravessa a fachada.
- Ao reutilizar um no do pool, o novo pedestre recebe um perfil novo. A memoria antiga nao vaza para outra identidade.
- O sinal legado `pedestre_chegou_loja` permanece; `pedestre_avaliou_loja` informa a decisao sem registrar venda.
- Teste `tests/test_npc_interesse.gd` ampliado para identidade e memoria independentes.

## Limites conhecidos
- A decisao `entrar` ainda **nao** aciona transicao para interior; apenas emite evento. A decisao `observar` usa o sprite parado existente, sem frames novos de olhar a vitrine.
- Memoria e apenas de instancia; nao ha persistencia no save. O pool pode reaproveitar o no visual, nao a identidade.
- O sinal legado e emitido independentemente da decisao; consumidores devem consultar o sinal novo antes de tratar uma chegada como visita real.
- O efeito de vento nas arvores e experimental; requer inspecao visual e testes de renderizacao.
- Nenhum teste Godot/Android foi executado nesta entrega, nenhum APK gerado, nenhum sprite aprovado modificado.

## Proximo passo
Verificar integracao com controlador da cena e consumidores de `pedestre_chegou_loja`; separar visualmente as decisoes sem gerar entradas fantasmas. Executar suites headless e testes renderizados em Godot 4.4.x, validar APK e registrar capturas antes de marcar BV-02/BV-03 como concluidos.
