# 01 - Estado atual e inventário técnico

## Estado vigente: evolução da campanha e mundo vivo

Base desta entrega: `93294bf` (PR #12 integrado). Os registros abaixo desta
seção preservam a evolução histórica; não descrevem todos o estado vigente.

| Sistema integrado | Evidência | Escopo validado no desktop |
|---|---|---|
| Objetivos e guia | [Objetivos](../../scripts/Objetivos.gd), [InterfaceJogo](../../scripts/InterfaceJogo.gd), [RuaComercial](../../scripts/RuaComercial.gd) | Seis metas opcionais, seis orientações, persistência por slot |
| Calendário tecnológico | [Campanha](../../scripts/Campanha.gd), [Catálogo](../../scripts/CatalogoJogos.gd) | Quatro componentes datados, dois novos jogos viáveis; 22 jogos, 30 componentes/insumos |
| Investigação | [Serviços](../../scripts/CatalogoServicos.gd), [Comércio](../../scripts/Comercio.gd) | Três defeitos, ensaios, evidências, reparo específico, reserva e pagamento único |
| Acabamentos | [Reforma](../../scripts/Reforma.gd), [Interior](../../scripts/Imoveis/InteriorModular.gd) | Três pisos existentes por célula, setores, cobrança/rollback e estado por imóvel |
| Aparência e gabinete | [Aparência](../../scripts/Aparencia.gd), [Gabinete](../../scripts/GabineteVisual.gd) | Acessórios nativos opcionais e oito encaixes reais no diagrama; não arte final |
| Mundo | [MundoVivo](../../scripts/MundoVivo.gd), [Controlador](../../scripts/RuaComercial.gd) | Pedestres, tráfego limitado, visitas comerciais e funcionários seguindo rotas |
| Ciclo de vida | [Evolução](../../scripts/Evolucao.gd), [Gerenciador](../../scripts/Imoveis/GerenciadorImoveis.gd) | Migração opcional, slots, pausa/salvamento/retomada; cálculo de safe area |

Validação: **3.090 verificações headless, 1.419 renderizadas, 10 testes de
imagens**, 13 capturas; sem falhas. Oito suítes incluem
[evolution](../../tests/test_evolution.gd), com 56 dias/112 PCs, salários,
especialistas, dívida e investimentos reais no segundo imóvel/ampliações.
Os 142 PNGs originais mantêm os hashes. Contagens repetem cenários entre modos.
Sem APK local nem homologação Android. A arte final pendente continua explícita.

## Atualização mais recente: campanha, progressão e oficina

Os seis blocos seguintes foram integrados à cena existente, sem refazer o jogo:

| Sistema | Evidência | Escopo verificado |
|---|---|---|
| Campanha e tecnologia | [Campanha](../../scripts/Campanha.gd) | Sete dias com compras reais, dois PCs/dia, folha/contas, três níveis permanentes e três fornecedores |
| Recorrência/reputação | [Clientes](../../scripts/Clientes.gd) | Retorno da mesma identidade por calendário, satisfação, demanda e pedidos por nível |
| Oficina | [Comércio](../../scripts/Comercio.gd) | Limite conjunto de quatro PCs/OS, reservas separadas, prioridades e retomada |
| Equipe ampliada | [Equipe](../../scripts/Equipe.gd), [integração](../../scripts/RuaComercial.gd) | Seis candidatos, quatro funções, montagem automática usando estoque e regras manuais |
| Câmera/portas | [Gestos](../../scripts/CameraGestos.gd), [móvel](../../scripts/Moveis/MovelIsometrico.gd) | Pinça/arraste, limites de zoom, recentralização, porta com abertura persistente e fechamento seguro |

O catálogo tem agora 14 objetos de construção. OS guardadas mantêm o perfil do
dono e os insumos fora do estoque vendável. Uma bancada/atendimento e uma unidade
operam por vez; não há várias montagens simultâneas. Aquisições antigas permanecem
acessíveis na migração, sem perda de funcionários ou imóveis.

Evidência: [campanha](../../tests/test_campaign.gd), **701 verificações**, mais
448 de simulação, 257 de progressão, 612 de gameplay e 162 de recuperação:
**2.180 headless**, todas aprovadas, além de 10 testes de imagens.
Nesta etapa renderizada: **705 + 262 verificações**, nove capturas. As contagens
repetem cenários entre modos e não medem requisitos únicos.
Arte final continua pendente; 142 PNGs originais preservados. Sem APK ou teste Android.

## Registro anterior: seis blocos adicionais autorizados

A árvore de trabalho agora inclui calendário/contas, perfis/fila/histórico,
20 pedidos por jogos fictícios, diagnósticos térmicos/estabilidade, cinco serviços,
equipe e reforma/mundo. São primeiras fatias utilizáveis, não o jogo final.
O inventário original abaixo permanece identificado como histórico.

| Sistema integrado | Fonte principal | Comportamento utilizável |
|---|---|---|
| Relógio/economia | [CalendarioEconomia](../../scripts/CalendarioEconomia.gd) | 900 s/dia; calendário 7/28/12; aluguel 100, energia 20, salários proporcionais, dívida e fechamento |
| Clientes | [Clientes](../../scripts/Clientes.gd) | Orçamento, preferência, paciência, fila de quatro, histórico e fidelidade persistentes |
| Montagem ampliada | [CatalogoJogos](../../scripts/CatalogoJogos.gd), [Comercio](../../scripts/Comercio.gd) | 20 jogos, configurações possíveis verificadas, temperatura e reserva elétrica corrigíveis |
| Assistência | [CatalogoServicos](../../scripts/CatalogoServicos.gd), [Comercio](../../scripts/Comercio.gd) | Upgrade RAM, diagnóstico, fonte, limpeza e manutenção; autorização, consumo, teste e pagamento único |
| Funcionários | [Equipe](../../scripts/Equipe.gd) | Três candidatos, contratos, funções flexíveis, experiência, salários e tarefas automáticas reais |
| Reforma/mundo | [Cadastro](../../scripts/Imoveis/CatalogoImoveis.gd), [Ambiente](../../scripts/Ambiente.gd), [controlador](../../scripts/RuaComercial.gd) | Duas ampliações por imóvel, divisória com duas vistas aprovadas, segundo imóvel pela fachada existente, noite/chuva/eventos afetando demanda |

O fornecedor passou a 26 produtos/consumíveis. O catálogo de construção tem
13 itens isométricos, incluindo a divisória. Novos blocos opcionais de save:
`calendario`, `clientes`, `equipe`; OS integram `comercio`, e nível/planta integram
o estado de cada imóvel. A unidade ativa também persiste. Migrações e recuperação
anteriores foram mantidas. Uma unidade e um atendimento operam por vez.

Evidência atual: [simulação](../../tests/test_simulation.gd), [progressão](../../tests/test_progression.gd),
[gameplay](../../tests/test_game.gd), [recuperação](../../tests/test_save_recovery.gd)
e [assets](../../tests/test_assets.py). Android continua sem execução local;
não houve geração de APK, commit, push ou alteração dos PNGs.

Resultado final desta atualização: **448 + 257 + 612 + 162 verificações Godot
headless**, respectivamente; **10 testes de imagens**. Renderização:
**454 de simulação e 262 de progressão**, incluindo onze capturas. Todas passaram,
sem erros de parser/carregamento. Os **142 hashes SHA-256** originais coincidiram.

Data: 03/11/2026. Base auditada: `b7fcb81263965e82d5eb4fbb8857ae94fb16b9f8`.
Escopo: auditoria e planejamento; nenhuma implementação, alteração de arte, exportação, commit ou push.

Este arquivo registra o estado inicial do SHA acima. Os acompanhamentos
posteriormente autorizados, incluindo a correção de colisão em árvore de trabalho,
estão no [registro visual](03_AUDITORIA_SPRITES.md) e no
[resumo executivo](06_RESUMO_EXECUTIVO.md).

### Atualização autorizada: slots, construção, comércio e primeiro PC

O inventário abaixo continua sendo o retrato inicial. Na árvore de trabalho,
foram adicionados [Partidas](../../scripts/Partidas.gd),
[NavegacaoInterior](../../scripts/Imoveis/NavegacaoInterior.gd),
[CatalogoPecas](../../scripts/CatalogoPecas.gd),
[Comercio](../../scripts/Comercio.gd) e
[CartaoPeca](../../scripts/CartaoPeca.gd), integrados ao
[controlador existente](../../scripts/RuaComercial.gd), sem substituir a cena.

São utilizáveis três slots/manual, validação de rotas, fornecedor de 15 peças,
entrega, estoque, cliente comercial, caixa e primeira montagem manual de oito
componentes com teste e entrega. O [save existente](../../scripts/Imoveis/GerenciadorImoveis.gd)
mantém migrações/backup e inclui o bloco comercial opcional.

A [nova suíte](../../tests/test_progression.gd) passou com 257 verificações
headless e 262 renderizadas, incluindo cinco capturas; as regressões passaram
com 611 e 162 verificações. Não houve APK, commit, push ou alteração de sprites.
Detalhes e limites estão no [README](../../README.md) e na
[matriz atualizada](02_GAP_ANALYSIS.md); não é declaração de jogo completo.

## 1. Fontes e método

Foram lidos integralmente, em Downloads, `PIXEL_PC_TYCOON_DOCUMENTO_MESTRE.md`
(versão 1.0, seções 0 a 21) e `PIXEL_PC_TYCOON_PROMPT_MESTRE.md`.
O documento mestre é a referência de requisitos. As instruções de implementação
do prompt de continuidade não foram executadas, pois esta auditoria proíbe mudanças no jogo.
Esses documentos externos não foram copiados nem modificados.

Foram examinados todos os scripts GDScript, a cena principal, configurações,
catálogos, manifestos, importadores, testes e o workflow. Os 142 PNGs foram
medidos e inspecionados em painéis de miniaturas sobre fundo contrastante;
capturas reais do jogo desktop complementaram a inspeção. Isso não equivale a
aprovação artística pelo responsável, nem a teste Android.

Distinções usadas:

- **Implementação:** código conectado à cena e acessível ao jogador.
- **Validação:** teste efetivamente executado, com o escopo declarado.
- **Aprovação visual:** decisão do responsável, não inferida de nomes de arquivos.
- A árvore de arquitetura da seção 15 do mestre é uma **proposta**, não obrigação
  de reescrever a estrutura existente.

## 2. Git e estado remoto

| Item | Constatação |
|---|---|
| Repositório ativo | `RiltonMaciel/Pixel-PC-Tycoon`, remoto `https://github.com/RiltonMaciel/Pixel-PC-Tycoon.git` |
| Branch local | `fix/validar-encaixe-balcao`, sem upstream indicado em `branch -vv` |
| HEAD, `main`, `origin/main` | Todos no commit `b7fcb81` |
| Alterações iniciais | Nenhuma alteração local reportada por `git status --short --branch` |
| Consulta remota real | `git ls-remote --heads origin`: `main` em `b7fcb81263965e82d5eb4fbb8857ae94fb16b9f8` |
| PR #8 | Incorporado; disponibilizou o balcão PC Store no catálogo |
| PR #9 | **Aberto**; `8d721e0`, propõe escala 0,65 → 0,52; não aplicado |
| PR #10 | Incorporado; preparação de caminhos para vistas extras, não produção das imagens |
| PR #11 | Incorporado em 03/11/2026 às 04:38:26 UTC; normaliza orientação salva sem textura |

O histórico recente inclui `fc45a70` (#10), `edf7f1f` (#8), `5ac162b` (#7) e
`3384f56` (correção do #11). As branches remotas desses trabalhos e de porta,
testes e escala foram consultadas. Não houve checkout, fetch/prune, pull, merge,
stash, commit ou push. A consulta `ls-remote` evita alterar referências locais.

**Estratégia de atualização:** não atualizar agora: a base local já coincide com
a `main` remota. Se a remota avançar, preservar estes relatórios e demais mudanças,
reconsultar o estado e propor fast-forward com autorização. O PR #9 precisa de
validação geométrica/visual antes de qualquer incorporação; CI verde não aprova a escala.

### Particularidade Windows

O Git contém `Assets/Personagens/README.md.` (nome terminado em ponto).
Ele está marcado `skip-worktree`, excluído pelo sparse checkout não-cone local.
`git archive HEAD` falhou com `invalid path` por esse nome. Nenhum arquivo foi
apagado ou renomeado para contornar isso; a validação utilizou cópia dos arquivos
presentes na árvore de trabalho. O documento omitido não foi lido/reconstruído.
Isso limita a completude documental e a portabilidade de um checkout Windows convencional.

## 3. Inventário versionado e arquitetura

367 caminhos rastreados antes dos relatórios:

| Tipo | Quantidade | Uso |
|---|---:|---|
| Cena `.tscn` | 1 | [RuaComercial.tscn](../../scenes/RuaComercial.tscn), nó raiz com script |
| GDScript `.gd` | 12 | 11 scripts de produção e 1 suíte |
| UID `.uid` | 12 | Identificadores dos scripts |
| PNG | 142 | Cenários, móveis, personagens e vizinhança |
| SVG | 15 | 8 itens legados de catálogo e 7 quadros legados de porta |
| `.import` | 158 | 157 texturas e importação do CSV |
| `.translation` | 7 | Saídas versionadas da importação do manifesto CSV |
| JSON / CSV | 3 / 1 | Manifestos visuais e metadados |
| Python | 6 | 5 ferramentas de assets e 1 suíte |
| Workflow | 1 | Build Android |
| `.tres` versionado | 0 | Não há recursos desse tipo no projeto rastreado |
| Autoload configurado | 0 | Não existe seção `[autoload]` |

Outros caminhos são documentação, configuração e metadados. O cache local
`.godot` não representa código-fonte versionado nem sistemas adicionais.

### Fluxo real

[project.godot](../../project.godot) → [cena principal](../../scenes/RuaComercial.tscn)
→ [RuaComercial.gd](../../scripts/RuaComercial.gd).

O script principal instancia bairro, interior, jogador, cliente, porta, câmera e
HUD em tempo de execução. Exterior e interior são **subárvores independentes na
mesma cena**, alternadas por visibilidade e contexto; não existem duas cenas
`.tscn` separadas de exterior/interior.

| Arquivo | Responsabilidade efetiva |
|---|---|
| [RuaComercial.gd](../../scripts/RuaComercial.gd#L50) | Orquestração, movimento, HUD, interação, compra/edição, transição e chamadas de save |
| [BairroComercial.gd](../../scripts/BairroComercial.gd) | Mapa 72 × 28, PC Store, cafeteria, piso, três travessias, máscaras e colisão externa |
| [VizinhancaComercial.gd](../../scripts/VizinhancaComercial.gd) | Cinco fachadas adicionais, 36 instâncias decorativas, obstáculos e avisos |
| [CatalogoVizinhanca.gd](../../scripts/CatalogoVizinhanca.gd) | 50 definições geradas de texturas, pivôs e pontos de base |
| [CatalogoImoveis.gd](../../scripts/Imoveis/CatalogoImoveis.gd) | Único imóvel funcional `pc_store_001`, sala 6 × 5 e quatro móveis iniciais |
| [GerenciadorImoveis.gd](../../scripts/Imoveis/GerenciadorImoveis.gd) | Contexto de imóvel, estados, JSON, backup, validação e migração |
| [InteriorModular.gd](../../scripts/Imoveis/InteriorModular.gd) | Piso e paredes por peças; transformação 2:1 |
| [CatalogoSprites.gd](../../scripts/Imoveis/CatalogoSprites.gd) | 20 definições; 12 itens isométricos compráveis, 8 SVGs legados |
| [MovelIsometrico.gd](../../scripts/Moveis/MovelIsometrico.gd) | Texturas por vista, pivô, edição, colisão, seleção por alfa e serialização |
| [PersonagemAnimado.gd](../../scripts/PersonagemAnimado.gd) | Quatro direções, quadros idle/passo e escala visual |
| [PortaLoja.gd](../../scripts/PortaLoja.gd) | Tween de polígonos amostrando a própria fachada |

Não há `Main.gd` na base atual. Não foram encontrados módulos ocultos de
estoque, montagem, equipe, clima ou economia comercial fora desse fluxo.

## 4. O que o jogador realmente consegue fazer

1. Caminhar com teclado ou D-pad virtual; colisão é calculada geometricamente,
   não por `CharacterBody2D`/corpos físicos.
2. Explorar calçadas, três travessias e as sete fachadas: PC Store, cafeteria e
   cinco estabelecimentos adicionais.
3. Interagir com um NPC que percorre uma rota externa e responde com uma frase.
4. Entrar/sair da PC Store por A, com bloqueio de movimento, animação e fade.
5. Ver a sala modular inicial com balcão, bancada, notebook e prateleira.
6. Comprar 12 móveis/equipamentos; arrastar, confirmar, cancelar e revender.
7. Girar o balcão PC Store por quatro texturas. Os outros 11 itens informam
   explicitamente que não possuem vistas suficientes.
8. Retomar saldo e layout, inclusive recuperação manual de móveis migrados pelo catálogo.

Os botões Montagem, Estoque e Menu respondem **“integração pendente”**.
O notebook, bancada, prateleira e caixa não executam serviços ou vendas.
Ter esses sprites no mapa não significa ter esses sistemas.

## 5. Persistência atual

[GerenciadorImoveis.gd](../../scripts/Imoveis/GerenciadorImoveis.gd#L37):

- Um arquivo `user://pixel_pc_tycoon_v1.json`, esquema `versao: 2`.
- Persiste dinheiro e, por imóvel, móveis colocados/guardados, posições e ângulos.
- Escrita temporária, flush, preservação `.bak` e tentativa de restauração se a
  substituição final falhar.
- Migra formatos v1/v042 para móveis guardados, com cópia `.pre_modular`.
- Salva após confirmar compra/edição, vender, sair da loja e perder foco/pausar.
- Rejeita save inválido e bloqueia a partida em vez de sobrescrever progresso.
- **Não recupera automaticamente `.bak` na leitura**, não possui seletor de três
  slots nem comando de salvamento manual para o jogador.
- Não persiste os sistemas de gerenciamento ainda inexistentes.

## 6. Godot, Android e CI

- Engine executada: **4.4.1.stable.official.49a5bc7b6**, Standard.
- Projeto: compatibilidade OpenGL, referência **432 × 768**, retrato,
  stretch `canvas_items`, importação ETC2/ASTC habilitada.
- Não há preset Android persistente na raiz; o
  [workflow](../../.github/workflows/build-android.yml#L96) cria-o durante o CI.
- Android: Java 17 no CI, templates Godot 4.4.1, export debug sem Gradle,
  pacote `com.pixelpctycoon.game`, ARM64 + ARMv7, versão **0.4.8 / código 48**.
- Permissão INTERNET habilitada no preset gerado. Não foi encontrado uso de rede
  no jogo; permissão não prova dependência de internet.
- Não há publicação release/AAB/Play Store nesse workflow.
- CI dispara por `push` com filtro de caminhos e manualmente; não há gatilho
  `pull_request`, e `tools/**` não faz parte do filtro.

Consulta ao GitHub: [run 41579305130](https://github.com/RiltonMaciel/Pixel-PC-Tycoon/actions/runs/41579305130),
mesmo SHA auditado, concluído com sucesso. Steps de imagens, importação/parsing,
smoke, suíte Godot, export debug e upload concluídos com sucesso.
Artefato histórico: `Pixel-PC-Tycoon-V048-APK`, ID `13204818764`,
71.106.367 bytes, não expirado na consulta.
**Não foi gerado nem instalado APK nesta auditoria.**

Não foi localizado `adb` no PATH nem configuração de SDK por `ANDROID_HOME`/
`ANDROID_SDK_ROOT`. Isso não prova que inexista SDK em outro diretório.
Não houve dispositivo/emulador Android conectado e validado.

## 7. Validação realizada

Para evitar reimportar recursos originais ou acessar o progresso do jogador,
Godot rodou em cópia isolada no diretório de sessão. Os testes existentes
substituem os caminhos de save antes de adicionar o jogo à árvore.
Não foi executado smoke direto sobre o save padrão do jogador.

| Verificação | Resultado observado |
|---|---|
| `python -B .\tests\test_assets.py` | **10 testes, OK**, Pillow já disponível |
| Godot `--headless --path <copia> --editor --import --quit` | Exit 0; sem erros/avisos encontrados no log |
| Godot `--headless --path <copia> --script res://tests/test_game.gd` | **567 passed, 0 failed**, exit 0 |
| Mesma suíte sem `--headless`, com `PIXEL_TEST_CAPTURE_DIR` | **588 passed, 0 failed**, exit 0; 13 capturas reais |
| Sonda adicional isolada | **40 verificações passaram**: inicialização por 30 frames físicos, 33 combinações de orientação salva, catálogo, corrupção/backup e limpeza |
| Referências literais `res://` completas em scripts/cena | Nenhum caminho ausente; caminhos dinâmicos usados pelo jogo cobertos pela importação/suítes |
| Duplicados de PNG por pixels RGBA decodificados | Nenhum entre os 142 arquivos |
| Execução Android/tela cinza em aparelho | **Não verificável neste ambiente** |

As 21 verificações adicionais do teste renderizado incluem 13 capturas e oito
amostragens de pixels das faixas; não são 21 funcionalidades novas.
A sonda de corrupção produziu intencionalmente:

```text
ERROR: Save invalido. Arquivo preservado: user://audit_<id>/corrupt.json
```

Esse erro foi esperado para verificar o bloqueio e a ausência de recuperação
automática; não é falha espontânea do projeto. As suítes originais não emitiram
`SCRIPT ERROR`, `Parse Error`, `WARNING` ou `FAIL`.

Logs e imagens de apoio ficaram no armazenamento da sessão, não no repositório.
Os resultados essenciais foram transcritos aqui para o relatório continuar útil
sem esses arquivos temporários. Não houve instalação de dependências.

## 8. Limites da conclusão

Os testes confirmam uma base funcional de **exploração e organização de móveis**,
não um tycoon completo. O parser histórico e a tela vazia **não foram reproduzidos
no desktop atual**. Aprovação artística, quatro vistas corretas do balcão,
performance móvel, safe area, ciclo de vida Android e partida offline no aparelho
continuam sem aceite. Veja a [matriz](02_GAP_ANALYSIS.md),
[sprites](03_AUDITORIA_SPRITES.md) e [riscos](04_BUGS_E_RISCOS.md).
