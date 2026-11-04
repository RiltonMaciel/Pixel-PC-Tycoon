# 02 - Gap analysis e matriz de rastreabilidade

## Matriz vigente complementar: dez frentes autorizadas

Estados referem-se ao escopo delimitado, com testes desktop nas suítes
[evolution](../../tests/test_evolution.gd), [objectives](../../tests/test_objectives.gd)
e [world](../../tests/test_world.gd). As matrizes anteriores permanecem históricas.

| ID | Funcionalidade | Requisito do MD | Estado atual | Evidência no código | Problemas | Próxima ação |
|---|---|---|---|---|---|---|
| EV01 | Missões/conquistas | Progressão sem bloquear jogo livre | IMPLEMENTADO E VALIDADO | [Objetivos](../../scripts/Objetivos.gd), [Evolução](../../scripts/Evolucao.gd) | Seis metas, sem campanha narrativa | Ampliar objetivos após playtest |
| EV02 | Calendário tecnológico | Novas gerações/requisitos | IMPLEMENTADO E VALIDADO | [Campanha](../../scripts/Campanha.gd), [Jogos](../../scripts/CatalogoJogos.gd) | Quatro lançamentos e dois jogos adicionais; não gerações ilimitadas | Balancear datas/demanda |
| EV03 | Assistência profunda | Diagnóstico/reparo por defeito | IMPLEMENTADO E VALIDADO | [Serviços](../../scripts/CatalogoServicos.gd), [Comércio](../../scripts/Comercio.gd) | Três cenários simulados, não diagnóstico universal | Mais casos por evidência |
| EV04 | Pisos e setores | Construção/acabamentos | PARCIAL | [Reforma](../../scripts/Reforma.gd), [Interior](../../scripts/Imoveis/InteriorModular.gd) | Pisos/setores testados; pintura/acabamentos de paredes não entregues | Definir arte/acabamentos restantes |
| EV05 | Personagens modulares | Aparência persistente | PARCIAL | [Aparência](../../scripts/Aparencia.gd), [Personagem](../../scripts/PersonagemAnimado.gd) | Acessórios nativos, não corpo/roupa/cabelo finais | Produzir arte mediante aprovação |
| EV06 | Tutorial e telas | UX/touch/Android | PARCIAL | [Interface](../../scripts/InterfaceJogo.gd), [Controlador](../../scripts/RuaComercial.gd) | Guia/HUD testados; notch/paineis sem aparelho | Homologar tamanhos e notch |
| EV07 | Campanhas longas | Economia/crescimento | IMPLEMENTADO E VALIDADO | [Teste de evolução](../../tests/test_evolution.gd) | 56 dias determinísticos, não teste humano/mercado completo | Campanhas com outras estratégias |
| EV08 | Preparação release | Desempenho/persistência/exportação | PARCIAL | [Workflow](../../.github/workflows/build-android.yml), [CI sem APK](../../.github/workflows/validate-game.yml) | Pausa e diagnóstico locais; sem SDK/aparelho/keystore para homologar | Medir bateria/memória/FPS e instalar release autorizado |
| EV09 | Mundo/IA | Circulação, trânsito, eventos | PARCIAL | [Mundo](../../scripts/MundoVivo.gd), [Controlador](../../scripts/RuaComercial.gd) | Rotas/visitas/tráfego testados; sem avoidance e eventos narrativos | Validar densidade e interação dos atores |
| EV10 | Arte aprovada | Quatro vistas/gabinete/portas | PARCIAL | [Arte pendente](../../ARTE_PENDENTE.md), [Gabinete](../../scripts/GabineteVisual.gd) | 33 vistas e arte final ainda faltam; diagrama funcional não as substitui | Obter aprovação para arte final |

Resultado global: **3.090 verificações headless + 1.419 renderizadas + 10 testes
de imagens**, sem falhas. Não equivale ao documento mestre inteiro concluído.

Base auditada: `b7fcb81`, 03/11/2026. Referência: Documento Mestre v1.0.
Matriz atualizada para a árvore de trabalho após os seis blocos autorizados.
Os estados validados referem-se às fatias delimitadas e testes desktop,
nunca ao escopo final inteiro ou à homologação Android.
As seções referenciadas abaixo pertencem ao mestre externo lido integralmente.
Requisitos **PROPOSTA** e **FUTURO** não são tratados como defeitos obrigatórios do primeiro marco.

## Convenções

- **IMPLEMENTADO E VALIDADO**: teste executado para o comportamento delimitado na linha; não significa aceite Android.
- **IMPLEMENTADO, MAS NÃO VALIDADO**: implementação conectada, sem teste suficiente do requisito.
- **PARCIAL**: apenas uma parte do requisito está utilizável.
- **COM DEFEITO**: divergência técnica demonstrada.
- **NÃO IMPLEMENTADO**: ausência confirmada no conjunto de fontes e fluxo examinados.
- **NÃO VERIFICÁVEL**: depende de dispositivo, referência/aprovação externa ou evidência indisponível.

Evidências abreviadas:
[R](../../scripts/RuaComercial.gd),
[B](../../scripts/BairroComercial.gd),
[V](../../scripts/VizinhancaComercial.gd),
[CI](../../scripts/Imoveis/CatalogoImoveis.gd),
[CS](../../scripts/Imoveis/CatalogoSprites.gd),
[G](../../scripts/Imoveis/GerenciadorImoveis.gd),
[M](../../scripts/Moveis/MovelIsometrico.gd),
[I](../../scripts/Imoveis/InteriorModular.gd),
[P](../../scripts/PersonagemAnimado.gd),
[D](../../scripts/PortaLoja.gd),
[T](../../tests/test_game.gd),
[A](../../tests/test_assets.py).
Todos os componentes visuais atuais são instanciados a partir da
[única cena principal](../../scenes/RuaComercial.tscn); linhas de funcionalidades
ausentes não apontam para cenas fictícias.

## Matriz

| ID | Funcionalidade | Requisito do MD | Estado atual | Evidência no código | Problemas | Próxima ação |
|---|---|---|---|---|---|---|
| PL-01 | Projeto Godot nativo/retrato | §2.1 APROVADO | IMPLEMENTADO E VALIDADO | [Configuração](../../project.godot); importação e execução desktop | APK não executado localmente | Manter Godot 4.4.1 na reprodução |
| PL-02 | APK abre e funciona no Android | §2.1, §17 | NÃO VERIFICÁVEL | [CI](../../.github/workflows/build-android.yml); run do SHA atual aprovado | Build não testa instalação ou tela inicial | Instalar artefato existente com autorização |
| CT-01 | D-pad contínuo e colisões | §2.1 APROVADO | IMPLEMENTADO E VALIDADO | [R: movimento](../../scripts/RuaComercial.gd#L112), [T](../../tests/test_game.gd) | Toque sintetizado, não aparelho | Repetir em Android |
| CT-02 | Diagonais e multitouch | §2.1 APROVADO | IMPLEMENTADO, MAS NÃO VALIDADO | [R: direção](../../scripts/RuaComercial.gd#L330), limite vetorial e índices de dedos | Suíte não demonstra todos os pares de dedos/diagonais reais | Testes de gestos simultâneos |
| CT-03 | A para portas e estações | §2.1 APROVADO | IMPLEMENTADO E VALIDADO | [Interação](../../scripts/RuaComercial.gd), [regressão](../../tests/test_game.gd), [comércio](../../tests/test_progression.gd) | Portas, notebook e bancada validados no desktop; balcao abre atendimento; NPC externo mantém conversa simples | Repetir em Android |
| CT-04 | Safe areas e densidades | §2.1 PROPOSTA | NÃO IMPLEMENTADO | [R: layout](../../scripts/RuaComercial.gd#L224) usa tamanho do viewport | Não consulta área segura do display | Avaliar notch/barras e telas-alvo |
| CA-01 | Câmera acompanha jogador suavemente | §2.2 APROVADO | PARCIAL | [R](../../scripts/RuaComercial.gd), [gestos](../../scripts/CameraGestos.gd) | Segue no exterior até gesto livre; recentralizar retoma seguimento; interior enquadrado com gestos livres | Avaliar suavização e legibilidade em aparelho |
| CA-02 | Arraste, pinça, recentralizar | §2.2 APROVADO | IMPLEMENTADO E VALIDADO | [Gestos](../../scripts/CameraGestos.gd), [integração/testes](../../tests/test_campaign.gd) | Eventos reais de viewport, D-pad preservado, limites de zoom; aparelho pendente | Homologar toque em Android |
| CA-03 | Câmera livre de construção | §2.2 APROVADO | PARCIAL | [Gestos](../../scripts/CameraGestos.gd), [R](../../scripts/RuaComercial.gd) | Câmera livre em área vazia; edição de móvel mantém seu dedo e não vira arraste de câmera | Polir interação durante reformas em aparelho |
| CA-04 | Visão de bancada/montagem | §2.2 APROVADO | PARCIAL | [Bancada integrada](../../scripts/RuaComercial.gd), [cartões](../../scripts/CartaoPeca.gd), [teste](../../tests/test_progression.gd) | Painel esquemático utilizável; não é a visão gráfica final do gabinete | Aprovar arte e interação espacial detalhada |
| MU-01 | Quarteirão explorável e travessias | §3.1 APROVADO | IMPLEMENTADO E VALIDADO | [B](../../scripts/BairroComercial.gd), [V](../../scripts/VizinhancaComercial.gd), [T](../../tests/test_game.gd) | Mais de 1100 células conectadas; mundo ainda estático | Preservar geometria e testes |
| MU-02 | Transição exterior/interior | §4.1, §15.2 | IMPLEMENTADO E VALIDADO | [R: transição](../../scripts/RuaComercial.gd#L481), [D](../../scripts/PortaLoja.gd), [T](../../tests/test_game.gd) | Subárvores separadas, não duas cenas; teste visual temporal ainda limitado | Regressão em vídeo no Android |
| MU-03 | Porta animada | §4.1, §14 | PARCIAL | [D](../../scripts/PortaLoja.gd), testes de tween/textura | Deformação de recortes, não quadros finais de arte | Solicitar aprovação antes de produzir frames |
| MU-04 | Pedestres que olham/entram | §3.1 APROVADO, §3.2 PROPOSTA | PARCIAL | [NPC comercial](../../scripts/RuaComercial.gd), [rotas](../../scripts/Imoveis/NavegacaoInterior.gd), [teste](../../tests/test_progression.gd) | Um visual reaproveitado; cliente interno entra/atende/sai; não há fluxo contínuo da calçada para dentro nem múltiplos pedestres | Expandir população e transição física externa |
| MU-05 | Tráfego e variação por hora/clima | §3.1 APROVADO | NÃO IMPLEMENTADO | [V](../../scripts/VizinhancaComercial.gd) instancia três veículos estáticos | Arte existe, simulação não | Tráfego após relógio e rotas |
| MU-06 | Árvores/ambiente animados | §3.1 APROVADO | NÃO IMPLEMENTADO | [V](../../scripts/VizinhancaComercial.gd) cria sprites estáticos | Sem oscilação/animação ambiental | Pequeno ciclo visual autorizado |
| MU-07 | Interiores vizinhos/roupas | §3.1 FUTURO | PARCIAL | [Cadastro](../../scripts/Imoveis/CatalogoImoveis.gd), [integração](../../tests/test_simulation.gd) | Salas comerciais têm interior comprável; outros comércios/roupas permanecem indisponíveis | Não confundir compra de imóvel com serviços de vizinhos |
| TE-01 | Dia de 900 s, noite azulada | §3.3 APROVADO | IMPLEMENTADO E VALIDADO | [Relógio](../../scripts/CalendarioEconomia.gd), [ambiente](../../scripts/Ambiente.gd), [teste](../../tests/test_simulation.gd) | Dia exato, calendário 7/28/12, persistência e tint externo testados; sem Android | Homologar ciclo de vida e visibilidade em aparelho |
| TE-02 | Chuva/guarda-chuva | §3.3 APROVADO | PARCIAL | [Chuva procedural](../../scripts/Ambiente.gd), [captura/teste](../../tests/test_simulation.gd) | Efeito e demanda ligados ao calendário; faltam guarda-chuvas e reação visual dos NPCs | Arte apenas mediante aprovação |
| TE-03 | Eventos com efeito na demanda | §3.3 APROVADO | IMPLEMENTADO E VALIDADO | [Previsão/eventos](../../scripts/Ambiente.gd), [fila](../../scripts/RuaComercial.gd), [teste](../../tests/test_simulation.gd) | Feira/dia tranquilo/chuva alteram intervalo real; eventos narrativos e balanceamento pendentes | Expandir após medir campanha |
| IM-01 | Microloja modular inicial | §4.1 APROVADO | IMPLEMENTADO E VALIDADO | [CI](../../scripts/Imoveis/CatalogoImoveis.gd), [I](../../scripts/Imoveis/InteriorModular.gd), [T](../../tests/test_game.gd) | Sala inicial preservada; estações têm atividades reais | Preservar layouts e migrações |
| IM-02 | Compra/mover/cancelar/vender móveis | §4.2 APROVADO | IMPLEMENTADO E VALIDADO | [R: edição](../../scripts/RuaComercial.gd#L389), [M](../../scripts/Moveis/MovelIsometrico.gd), [T](../../tests/test_game.gd) | Validação desktop; não valida todos os layouts possíveis | Matriz Android e layouts extremos |
| IM-03 | Quatro vistas de todos os móveis | §4.2, §14 APROVADO | PARCIAL | [CS](../../scripts/Imoveis/CatalogoSprites.gd), [M](../../scripts/Moveis/MovelIsometrico.gd), [A](../../tests/test_assets.py) | 11 móveis originais têm só 0°; faltam 33 PNGs; divisória adicional usa duas paredes reais aprovadas | Aprovar arte por família, sem girar PNGs |
| IM-04 | Giro do balcão troca textura | §14 APROVADO | IMPLEMENTADO E VALIDADO | [T](../../tests/test_game.gd), quatro voltas e persistência | Funcionamento não garante arte geometricamente correta | Manter regressão de giro |
| IM-05 | Projeção isométrica da colisão do balcão ao girar | §14, §15.2 | IMPLEMENTADO E VALIDADO | [Componente corrigido](../../scripts/Moveis/MovelIsometrico.gd), [regressão](../../tests/test_game.gd), [medição final](evidencias/balcao_corrigido/medidas.json) | Correção autorizada em árvore de trabalho: 128×64 nas quatro vistas; aprovação artística continua separada em IM-06 | Validar em Android e decidir coerência visual das vistas |
| IM-06 | Pivô/escala visual aprovados do balcão | §4.1 AUDITAR, §14 | NÃO VERIFICÁVEL | [CS](../../scripts/Imoveis/CatalogoSprites.gd#L16), imagens e sonda | Pivô comum não comprova eixo físico; escala 0,52 só no PR #9 | Comparar quatro vistas lado a lado, sem alterar PNGs |
| IM-07 | Pisos/divisórias/portas editáveis | §4.2 APROVADO | PARCIAL | [Catálogo](../../scripts/Imoveis/CatalogoSprites.gd), [colisão/porta](../../scripts/Moveis/MovelIsometrico.gd), [teste](../../tests/test_campaign.gd) | Divisória e porta compráveis, editáveis e persistentes; fechamento seguro testado; pisos individuais e arte final pendentes | Aprovar arte sem substituir painéis aprovados |
| IM-08 | Construção instantânea | §4.2 APROVADO | IMPLEMENTADO E VALIDADO | [UI](../../scripts/RuaComercial.gd), [testes](../../tests/test_simulation.gd) | Móveis/divisórias/ampliações aplicados na confirmação; reforma completa ainda parcial | Homologar toque e custos em aparelho |
| IM-09 | Corredores/acesso a áreas de trabalho | §4.2 PROPOSTA | IMPLEMENTADO E VALIDADO | [Navegação](../../scripts/Imoveis/NavegacaoInterior.gd), [validação real](../../scripts/RuaComercial.gd), [teste](../../tests/test_progression.gd) | Rotas verificadas no desktop para jogador, entrada, saída, cliente e estações; amostragem conservadora de 12 px | Medir desempenho e repetir layouts no Android |
| IM-10 | Ampliação e mudança de imóvel | §4.2–4.3 APROVADO | PARCIAL | [Dois imóveis](../../scripts/Imoveis/CatalogoImoveis.gd), [UI](../../scripts/RuaComercial.gd), [teste](../../tests/test_simulation.gd) | Duas ampliações por imóvel, compra de sala 10×8 e estados separados; uma unidade ativa; sem frota de lojas/aluguel específico | Balancear aquisição e validar plantas no Android |
| EC-01 | Caixa de compra/revenda de móveis | §5, parte preparatória | IMPLEMENTADO E VALIDADO | [R](../../scripts/RuaComercial.gd#L389), [T](../../tests/test_game.gd) | Não confundir revenda de decoração com venda a clientes | Reutilizar transações sem duplicação |
| EC-02 | Economia, despesas, lucro, reputação | §5 APROVADO | IMPLEMENTADO E VALIDADO | [Calendário](../../scripts/CalendarioEconomia.gd), [campanha](../../scripts/Campanha.gd), [teste](../../tests/test_campaign.gd) | Contas/dívida/reputação e campanha econômica de sete dias testadas; não prova todas as estratégias ou demanda garantida | Medir balanceamento em sessões reais longas |
| EC-03 | Estoque e reservas | §5 APROVADO/PROPOSTA | IMPLEMENTADO E VALIDADO | [Comércio](../../scripts/Comercio.gd), [teste](../../tests/test_campaign.gd) | Reservas individuais de OS e montagem fora do estoque vendável, cancelamento e rollback; limite quatro PCs/OS | Homologar oficina em aparelho |
| EC-04 | Fornecedores digitais e entrega | §5 APROVADO | IMPLEMENTADO E VALIDADO | [Campanha](../../scripts/Campanha.gd), [comércio](../../scripts/Comercio.gd), [teste](../../tests/test_campaign.gd) | Três fornecedores por nível, 30/25/20 s ativos; 26 produtos, legados preservados; sem avanço fechado | Validar UX Android |
| EC-05 | Fornecedor presencial/logística ampliada | §5 FUTURO | NÃO IMPLEMENTADO | Nenhum estabelecimento fornecedor funcional | Não bloqueia protótipo inicial | Adiar |
| HW-01 | Hardware fictício/compatibilidade inicial | §6.1 APROVADO | IMPLEMENTADO E VALIDADO | [Catálogo/regras](../../scripts/CatalogoPecas.gd), [montagem](../../scripts/Comercio.gd), [teste](../../tests/test_progression.gd) | Compatibilidade testada; catálogo/progressão final não concluídos | Expandir gerações com balanceamento |
| HW-02 | Cerca de 20 jogos e requisitos | §6.1 APROVADO | IMPLEMENTADO E VALIDADO | [20 jogos](../../scripts/CatalogoJogos.gd), [configurações testadas](../../tests/test_simulation.gd) | Cada pedido tem configuração acessível verificada; dificuldade e preços provisórios | Playtest de progressão |
| HW-03 | Calendário tecnológico e desbloqueios | §6.2 APROVADO | PARCIAL | [Campanha](../../scripts/Campanha.gd), [teste](../../tests/test_campaign.gd) | Peças/fornecedores/jogos desbloqueados por reputação e vendas, permanentemente; ainda sem lançamentos/datagem de gerações | Expandir calendário tecnológico sem remover aquisições |
| PC-01 | Primeira montagem manual arrastar/instalar | §7 APROVADO | IMPLEMENTADO E VALIDADO | [Cartões arrastáveis](../../scripts/CartaoPeca.gd), [bancada](../../scripts/RuaComercial.gd), [modelo](../../scripts/Comercio.gd), [teste](../../tests/test_progression.gd) | Oito componentes, cabos, remoção/cancelamento e retomada; interface esquemática, não arte final dentro do gabinete | Aceite Android e evolução visual autorizada |
| PC-02 | Boot, estabilidade, erros progressivos | §7 APROVADO/PROPOSTA | PARCIAL | [Diagnóstico](../../scripts/Comercio.gd), [falhas/correções testadas](../../tests/test_simulation.gd) | Boot, requisitos, térmica e reserva elétrica reais de gameplay; não é simulação física completa | Balancear dificuldade e expandir casos |
| OS-01 | Montagem/upgrade/diagnóstico/reparo/limpeza/manutenção | §8 APROVADO | PARCIAL | [Serviços](../../scripts/CatalogoServicos.gd), [modelo](../../scripts/Comercio.gd), [teste](../../tests/test_campaign.gd) | Cinco serviços e montagem; quatro PCs/OS com reservas e prioridade; uma bancada ativa; cenários representativos | Variar defeitos e diagnósticos |
| CL-01 | Orçamento/paciência/preferências/compra | §9.1 APROVADO | IMPLEMENTADO E VALIDADO | [Perfis](../../scripts/Clientes.gd), [rotas/UI](../../scripts/RuaComercial.gd), [teste](../../tests/test_simulation.gd) | Orçamento, preferência, fila de quatro, paciência e desistência com devolução; avoidance dinâmico pendente | Validar campanha e movimento em aparelho |
| CL-02 | Pedido especial e pagamento único | §9.1 APROVADO | IMPLEMENTADO E VALIDADO | [Pedidos/caixa](../../scripts/Comercio.gd), [20 jogos](../../scripts/CatalogoJogos.gd), [teste](../../tests/test_campaign.gd) | Peças, PCs por jogo e OS com pagamento único; quatro PCs/OS, uma transação de bancada por vez | Homologar fila e reservas em Android |
| CL-03 | Recorrência/histórico/fidelidade | §9.2 APROVADO | IMPLEMENTADO E VALIDADO | [Clientes](../../scripts/Clientes.gd), [teste de retorno integrado](../../tests/test_campaign.gd) | Mesma identidade retorna por calendário, acumula visitas/fidelidade; satisfação afeta demanda e desbloqueios | Ampliar variação de preferências e testar campanhas longas |
| EQ-01 | Contratar/demitir/habilidades/prioridades/ordens | §10 APROVADO | PARCIAL | [Equipe](../../scripts/Equipe.gd), [tarefas/UI](../../scripts/RuaComercial.gd), [teste](../../tests/test_campaign.gd) | Seis candidatos, quatro funções, especialistas, folha/XP e montagem automática com estoque; um ocupante por função; aparência procedural pendente | Ampliar IA e aparência após aceite Android |
| NP-01 | Aparência modular/procedural | §11 APROVADO | NÃO IMPLEMENTADO | [P](../../scripts/PersonagemAnimado.gd) carrega personagens completos | Pasta “Modulares” contém quadros inteiros, não partes combináveis | Pacote de camadas aprovado |
| NP-02 | Personagens em quatro direções | §11, base visual | IMPLEMENTADO E VALIDADO | [P](../../scripts/PersonagemAnimado.gd), [A](../../tests/test_assets.py), [T](../../tests/test_game.gd) | Protagonista, estudante e técnico usados; todos são sprites completos | Não gerar substitutos desnecessários |
| PR-01 | Missões/desafios/conquistas opcionais | §12 APROVADO | NÃO IMPLEMENTADO | Sem módulo de progressão nas fontes | Não há primeira venda/PC para premiar | Eventos de domínio após ciclo comercial |
| SV-01 | Save mínimo, autosave e migração | §13 APROVADO | IMPLEMENTADO E VALIDADO | [G](../../scripts/Imoveis/GerenciadorImoveis.gd), [T](../../tests/test_game.gd), 33 verificações extras de ângulos | Cobertura limitada a saldo/móveis | Preservar migrações existentes |
| SV-02 | Três slots e salvar manualmente | §13 APROVADO | IMPLEMENTADO E VALIDADO | [Seleção](../../scripts/Partidas.gd), [Menu](../../scripts/RuaComercial.gd), [teste](../../tests/test_progression.gd) | Slot 1 reutiliza arquivo existente; 2/3 separados; manual e autosave usam o mesmo arquivo por slot; não são snapshots distintos | Aceite de ciclo de vida Android |
| SV-03 | Recuperação do último backup válido | §13 APROVADO | IMPLEMENTADO E VALIDADO | [Gerenciador](../../scripts/Imoveis/GerenciadorImoveis.gd), [recuperação](../../tests/test_save_recovery.gd), [slots/comércio](../../tests/test_progression.gd) | Backup validado por slot, incluindo estado comercial; original preservado e aviso; Android não executado | Validar ciclo de vida Android |
| SV-04 | Persistência integral da simulação | §13 APROVADO | PARCIAL | [Save](../../scripts/Imoveis/GerenciadorImoveis.gd), [integração](../../tests/test_simulation.gd) | Sistemas atuais, contas, perfis, OS, equipe, imóveis e unidade ativa persistem; escopo final ainda incompleto; jogador retorna ao exterior | Ampliar esquema junto dos próximos módulos |
| SV-05 | Funcionamento offline | §1, §13 APROVADO | PARCIAL | Nenhum uso de rede no código; execução local sem serviço remoto | Simulação completa inexiste; Android offline não testado | Modo avião e reabertura em aparelho |
| SV-06 | Backup nuvem/exportar-importar | §13 FUTURO | NÃO IMPLEMENTADO | Sem integração de nuvem ou UI de backup | Fora da prioridade inicial | Adiar, mantendo offline independente |
| AR-01 | Grid interior 128 × 64 e sem frestas | §14 APROVADO | IMPLEMENTADO E VALIDADO | [I](../../scripts/Imoveis/InteriorModular.gd), [A](../../tests/test_assets.py), salas 6×5/8×7 | Nenhuma fresta interna detectada nos casos testados | Preservar manifestos e testes |
| AR-02 | Exterior estritamente 2:1 | §14 APROVADO | PARCIAL | [B: eixos](../../scripts/BairroComercial.gd#L7) usa `(64,20)`/`(-64,32)` | Divergência explícita para preservar fachada; cafeteria transformada | Decisão artística autorizada, sem conversão automática |
| AR-03 | Transparência dos sprites isolados | §14 APROVADO | IMPLEMENTADO E VALIDADO | 142 PNGs medidos, [A](../../tests/test_assets.py) | Fontes/cenários completos têm opacidade intencional; fidelidade não decorre de alfa | Manter fontes e PNGs finais separados |
| AR-04 | Fidelidade às referências aprovadas | §14 APROVADO/AUDITAR | NÃO VERIFICÁVEL | Recortes preservam RGB da fonte em [A](../../tests/test_assets.py); inspeção de capturas | Referências externas/aceite de todos os recursos não comprovados; marcas reais visíveis em caixas | Revisão humana com referências sem redesenho |
| QA-01 | Parsing/importação/referências | §17 | IMPLEMENTADO E VALIDADO | Godot 4.4.1, import exit 0, suítes verdes | Não cobre toda entrada inválida futura | Repetir após alterações autorizadas |
| QA-02 | FPS/memória/bateria/toque Android | §17 | NÃO VERIFICÁVEL | Sem execução em aparelho nesta auditoria | CI exporta, não mede runtime Android | Perfil em aparelho-alvo |

## Interpretação por marco

- **Marco 0:** esta documentação entrega o diagnóstico; não aprova automaticamente arte ou APK.
- **Marco 1:** base desktop demonstrável; câmera híbrida e aceite Android ainda faltam.
- **Marco 2:** edição de móveis utilizável, porém quatro vistas e construção estrutural incompletas.
- **Marcos 3–8:** predominam requisitos não implementados; há apenas fundações reutilizáveis.
- **Marco 9:** testes úteis existem, mas não substituem QA móvel e balanceamento.

Não usar a contagem de linhas verdes como percentual global: requisitos têm
complexidades muito diferentes. As estimativas por módulo estão no
[roadmap](05_ROADMAP_IMPLEMENTACAO.md), com premissas explícitas.

Atualização posterior à auditoria inicial: IM-05 foi corrigido e validado no
desktop, sem commit, sprites novos, alteração de escala ou aplicação do PR #9.
A linha agora mede a projeção técnica, não a fidelidade artística do footprint.
Os demais resultados continuam referentes à base auditada e às limitações declaradas.

Atualização do marco S1: SV-03 também foi implementado após autorização, ainda
sem commit. Principal inválido/ausente recupera `.bak` validado; o danificado
recebe nome único e não é substituído silenciosamente. Sem cópia válida ou com
falha de restauração, a partida continua bloqueada. Foram executadas 162
verificações de recuperação em modo headless e outras 162 com renderização,
além das 611 verificações de regressão de jogabilidade. SV-02 (três slots e
salvamento manual) continua **NÃO IMPLEMENTADO**.
