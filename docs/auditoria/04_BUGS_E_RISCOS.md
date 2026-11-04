# 04 - Bugs, divergências e riscos

## Estado mais recente: campanha e oficina validadas no desktop

- Corrigida incompatibilidade `int`/`float` na validação do nível após JSON;
  reservas também são comparadas numericamente por componente.
- Fila pula pedidos sem orçamento, tecnologia, bancada ou capacidade em vez
  de impedir atender um comprador elegível atrás deles.
- Guardar OS sem ordem válida não cria estado parcial; falha de gravação
  restaura reservas, estoque e perfil do dono. Pagamento/consumo são únicos.
- Montagem e assistência compartilham limite de quatro PCs. Técnico segue
  prioridade/chegada; montador não cria peças nem altera PC parcial sem solução.
- Porta aberta conserva estado e colisão após reabrir; editar/confirmar não deixa
  painel fantasma. Fechar sobre personagem/rotas é recusado; erro de save desfaz.
- Corrupção de perfil, reserva, prioridade ou nível recupera o backup validado
  sem perder as ordens pendentes nem sobrescrever o original corrompido.
- [Testes da campanha](../../tests/test_campaign.gd): 701 headless/705 renderizados,
  sem falhas. Regressões e testes de assets também aprovados.

Limites atuais: Android/safe area/desempenho ainda não homologados; uma unidade
e uma bancada ativa, quatro funções com um ocupante por função; navegação sem
avoidance completo. Campanha econômica de referência não garante todas as
estratégias; históricos crescem sem compactação. Recorrência preserva preferência
anterior, não cria novos gostos a cada visita. Portas provisórias e arte pendente
não foram redesenhadas. Não houve APK, commit ou push.

## Registro anterior: seis blocos adicionais

Calendário, fila/perfis, diagnósticos avançados, OS, salários/equipe, ampliações,
divisórias e imóvel maior já têm fluxo integrado e testes; não devem mais ser
tratados como ausências. As listas antigas abaixo são registros históricos.

Riscos/limites atuais:

1. **Alta — Android não verificado:** sem instalação, logs de aparelho, perfil
   de memória/FPS, safe area ou gestos de câmera. Não confundir desktop com aceite.
2. **Média — escopo delimitado:** uma unidade ativa e um atendimento/PC/OS por vez;
   cinco cenários representativos de serviço, três candidatos fixos. Técnico
   automatiza OS, não a montagem manual de PCs. Recorrência e reputação global
   ainda não estão concluídas.
3. **Média — navegação:** grade conservadora de 12 px; postos exigem acesso e
   funcionários internos são colocados em posições livres distintas. Não há
   avoidance dinâmico completo entre clientes em movimento.
4. **Média — balanceamento:** tarifas, salários, preços, requisitos e cadência
   de eventos são provisórios. Termodinâmica é simulação de gameplay determinística.
   Históricos/contas ainda não possuem compactação para campanhas muito longas.
5. **Arte pendente:** 33 vistas, gabinete gráfico, personagens por partes,
   guarda-chuvas e portas internas animadas. Nenhum substituto foi gerado.

Testes específicos cobrem consumo/pagamento único de OS, devolução de peças do
cliente sem estoque gratuito, desistência pré-autorização, folha após demissão,
salários em dívida, rollback de folha/ampliação em falha de escrita, compra
repetida de imóvel e restauração de unidade/planta. O acesso às Salas comerciais
e o catálogo ampliado tiveram suas expectativas históricas atualizadas nos
[testes de gameplay](../../tests/test_game.gd), preservando os demais controles.

Base: `b7fcb81`, 03/11/2026.
Severidade considera o protótipo atual e o planejamento, não vulnerabilidades de segurança.
**Defeito confirmado**, **lacuna de requisito** e **risco não reproduzido** são separados.

### Acompanhamento: quatro entregas autorizadas

- S2 foi concluído no desktop: três arquivos de partida, seleção persistida,
  manual/autosave, migração restrita ao slot 1 e recuperação por slot.
  Falhas na gravação da seleção não trocam a partida em memória.
- A parcela de R-03 sobre conectividade agora tem validação de rotas. O teste
  real de posicionamento rejeita um móvel que fecha um corredor sem sobrepor
  outros móveis, além de proteger jogador, entrada e estações. A grade de 12 px
  é conservadora: não representa prova de todos os corredores contínuos.
- Compras, recebimentos, reservas e pagamentos foram testados contra duplicação.
  Erro de escrita comercial desfaz saldo/estado em memória e informa a falha.
  Corrupção estrutural do bloco comercial aciona o backup validado.
- Primeira montagem e venda estão conectadas: compatibilidade, oito encaixes,
  cabos, boot/requisitos, cancelamento e configuração entregue persistida.
- [Testes novos](../../tests/test_progression.gd): 257 headless e 262 renderizados;
  regressões: 611 de gameplay e 162 de recuperação, sem falhas.

**Limites atuais:** Android, desempenho da navegação em aparelho, interrupção de
energia e falhas físicas continuam sem aceite. Não há avoidance entre atores
móveis, fila de clientes, múltiplas OS, calendário, reputação, salários, testes
avançados de temperatura/estabilidade ou arte final do gabinete. O cliente interno
é instanciado na entrada; não percorre fisicamente todo o trajeto da calçada.
Layouts antigos são preservados, não corrigidos silenciosamente.
As tabelas a seguir permanecem como diagnóstico histórico do SHA auditado.

## 1. Defeitos e divergências confirmados

| ID | Severidade | Natureza | Arquivos/evidência | Efeito e estratégia |
|---|---|---|---|---|
| B-01 | Alta | Geometria confirmada | [MovelIsometrico.gd](../../scripts/Moveis/MovelIsometrico.gd#L83), [catálogo](../../scripts/Imoveis/CatalogoSprites.gd#L16) | Ao girar balcão, diagonais da colisão passam de 128×64 a 64×128 em tela. Isso deixa de seguir os eixos do piso e diverge da aparência horizontal. Medir a base física e projetar no grid, com teste por vista; não alterar arte |
| B-02 | Alta para arte; não bloqueia parser | Inconsistência visual medida | [quatro PNGs](../../Assets/Moveis/Balcoes/balcao_pc_store), [normalizador legado](../../tools/prepare_assets.py#L45) | Mesma largura visível 156; alturas 71,5/144,3/74,75/130,65. Inspeção mostra diferença de apresentação frontal/profunda. Revisar referências e pivô; medidas sinalizam inconsistência, mas altura da bbox isolada não determina a escala correta |
| B-03 | Média | Portabilidade Git confirmada | Caminho rastreado `Assets/Personagens/README.md.`; sparse checkout local | `git archive HEAD` falha no Windows com `invalid path`. Renomear futuramente esse caminho de documentação, com autorização e preservação do conteúdo. Não foi alterado nesta etapa |
| B-04 | Média | Documentação desatualizada | [README](../../README.md), [catálogo](../../scripts/Imoveis/CatalogoSprites.gd), [arte pendente](../../ARTE_PENDENTE.md) | README ainda diz 11 itens e balcão apenas em saves antigos; runtime/teste mostram 12 compráveis. Parte do texto trata personagens já integrados como pendência. Atualizar somente após autorização, sem apagar histórico relevante |
| B-05 | Média | Divergência de direção artística | [BairroComercial.gd](../../scripts/BairroComercial.gd#L7), [metadados cafeteria](../../Assets/Cenarios/Bairro/cafeteria.json) | Exterior não usa 2:1 simétrico; cafeteria é transformada geometricamente. Não “corrigir” deformando fontes. Submeter decisão sobre preservar exceção do exterior ou planejar adequação autorizada |

### Reprodução objetiva de B-01/B-02

1. Entrar na loja, comprar **Balcão PC Store**, colocar em região livre.
2. Alternar Girar nas quatro vistas, mantendo o mesmo ponto.
3. Registrar imagem/contorno de colisão e aproximação do personagem por cada lado.
4. Comparar com o mesmo piso e com móveis iniciais; cancelar deve restaurar orientação.

Medição da sonda executada no Godot:

```text
angle=0   scale=(0.65,0.65) visible=(156,71.5)   collision=(128,64)
angle=90  scale=(0.65,0.65) visible=(156,144.3)  collision=(64,128)
angle=180 scale=(0.65,0.65) visible=(156,74.75)  collision=(128,64)
angle=270 scale=(0.65,0.65) visible=(156,130.65) collision=(64,128)
```

O PR #9 propõe só `escala=0.52`. Não muda colisão nem pivô, portanto não basta
considerá-lo correção completa. É necessário demonstrar encaixe, passagem e
coerência das quatro vistas antes de aprová-lo.

## 2. Lacunas de requisito, não regressões de código

| ID | Prioridade | Lacuna/evidência | Estratégia futura |
|---|---|---|---|
| L-01 | P1 | 11 móveis com uma vista; faltam 33 PNGs, conforme [inventário](03_AUDITORIA_SPRITES.md) | Aprovar por família, preservar 0°; integrar com giro/persistência reais |
| L-02 | P1 | [Leitura de save](../../scripts/Imoveis/GerenciadorImoveis.gd#L71) bloqueia principal inválido mesmo com `.bak` válido | Recuperação explícita validada, preservando principal corrompido e informando origem/resultado |
| L-03 | P2 | [Save fixo](../../scripts/Imoveis/GerenciadorImoveis.gd#L5), sem três slots ou botão manual | Evoluir esquema/UI com migração e isolamento entre slots |
| L-04 | P2 | [Câmera/input](../../scripts/RuaComercial.gd#L246) sem pinça, arraste de câmera ou construção livre | Separar gestos por estado, manter edição de móveis e D-pad |
| L-05 | P2 | [Menus](../../scripts/RuaComercial.gd#L564) de Montagem/Estoque/Menu são avisos | Não apresentar como sistemas concluídos; entregar uma fatia jogável por vez |
| L-06 | P2 | [Interior](../../scripts/Imoveis/InteriorModular.gd) modular, mas pisos/paredes não editáveis pelo jogador | Editor incremental com custo, limites, cancelamento e persistência |
| L-07 | P2 | Moeda mostra `R$`; prompt de continuidade menciona `R¥` | Mestre não fixa a grafia nessa seção; confirmar intenção antes de trocar exibição/testes |
| L-08 | P3 | Componentes comerciais fictícios não existem; prateleira tem marcas reais aparentes na arte | Definir hardware fictício e decisão sobre arte aprovada, sem alteração automática |

### Evidência específica de recuperação

A sonda criou um principal com JSON inválido e um `.bak` de esquema aceito.
`ler()` retornou `{}` e registrou erro; não abriu o backup.
Isso confirma a limitação de recuperação de leitura, **não perda de arquivo**.
A escrita já tem proteção e tentativa de restauração se o rename final falhar.
Não substituir esse comportamento por fallback silencioso.

## 3. Riscos e pendências de validação

| ID | Severidade potencial | Evidência e limite | Mitigação/teste necessário |
|---|---|---|---|
| R-01 | Alta | Android não executado; CI só importa/testa/exporta. Tela cinza atual em aparelho não foi reproduzida nem descartada | Instalar artefato do SHA auditado, coletar logcat, abrir/fechar/reabrir, testar entrada/saída |
| R-02 | Alta | [_can_place](../../scripts/RuaComercial.gd#L344) testa piso, sobreposição, jogador e ponto da saída; não testa rota global | Criar layouts que cercam saída/estações; aprovar só se navegação continuar conectada. Aprisionamento não foi reproduzido nesta auditoria |
| R-03 | Alta | [_validar](../../scripts/Imoveis/GerenciadorImoveis.gd#L121) valida ponto do móvel, não o polígono completo, sobreposições ou acesso | Testar save estruturalmente válido com layout impossível; definir migração para guardados/erro explícito |
| R-04 | Média | [Layout](../../scripts/RuaComercial.gd#L224) não consulta safe area, controles nas bordas | Dispositivos com notch/barra de gestos, resoluções/densidades distintas |
| R-05 | Média | Muitas faixas por fachada; máscaras grandes e `get_image()` no carregamento de personagens | Medir FPS/frame time/memória/bateria no aparelho-alvo antes de otimizar |
| R-06 | Média | [CI](../../.github/workflows/build-android.yml#L1) sem `pull_request`; mudanças só em ferramentas não acionam o filtro | Depois de autorizado, cobrir PR e ferramentas; manter exportação separável de validação |
| R-07 | Média | Teste de quatro PNGs só prova alfa/existência/conteúdo diferente | Acrescentar critérios de pivô/base/projeção e aprovação visual; não usar hashes como prova artística |
| R-08 | Média | Frames da porta são polígonos deformados; ordenação não tem teste visual contínuo de todos os frames | Gravar entrada/saída e posições antes/atrás da fachada; não substituir arte sem aceite |
| R-09 | Média | [Principal](../../scripts/RuaComercial.gd) concentra UI, input, transações e ciclo de vida | Novas fatias devem separar dados/simulação quando necessário, sem reescrita geral preventiva |
| R-10 | Média | Testes não simulam interrupção abrupta em cada etapa de escrita, falta de espaço ou três slots | Injeção de falhas de persistência e teste Android em segundo plano |
| R-11 | Baixa | 7 traduções de manifesto e recursos reservados exportados com `all_resources` | Medir conteúdo/tamanho do pacote; não apagar assets aprovados para “limpar” o projeto |
| R-12 | Baixa | [Preset de CI](../../.github/workflows/build-android.yml#L96) é debug, INTERNET ativo e versão estática | Release/versão/permissões precisam de decisão futura; não há uso de rede observado |

Não foi estabelecida meta de FPS ou memória pelo mestre; não inventar um número
de aprovação sem definir aparelho-alvo e orçamento.

## 4. Rechecagem dos problemas históricos

| Problema relatado | Estado observado agora |
|---|---|
| Jogador sobre a fachada ao entrar | Proteções atuais: colisão externa, fatias por base, bloqueio durante transição e troca no escuro. Suíte/capturas passaram; não reproduzido no desktop. Falta validação temporal Android |
| Transição externa/interna errada | Entrada/saída e contexto por ID passaram repetidamente, incluindo reentrada e reinício |
| Móveis sem quatro orientações | **Continua presente** para os 11 modulares; falta de arte é tratada explicitamente |
| Girar sem efeito | Corrigido no sentido de feedback: uma vista avisa sem inventar giro. Balcão de quatro vistas gira e persiste; requisito de todos girarem permanece parcial |
| Balcão ausente do catálogo | **Corrigido** pelo #8; teste confirma 12 itens e botão do balcão |
| Balcão desalinhado | Medições confirmam problema de footprint e inconsistência visual; escala final/pivô físico ainda sem aceite |
| Sprite invisível por ângulo salvo inexistente | #11 incorporado; sonda validou 33 combinações dos 11 IDs com 90°/180°/270°, normalizando para 0°, inclusive serialização |
| Sprites diferentes dos aprovados | Recortes RGB da fachada são preservados; fidelidade integral e aceite externo não verificáveis. Vizinhança tem acabamento mais simples, já documentado |
| Erros de carregamento/parsing | Nenhum encontrado na importação/suítes executadas no SHA atual |
| `Main.gd` com erro | Esse arquivo não existe na base atual; não atribuir erro antigo ao ponto de entrada atual |
| APK cinza/vazio | Desktop renderizou corretamente; APK atual não foi instalado nesta auditoria |
| Transparência/frestas | Móveis e kits têm alfa real; piso passou testes sem frestas. Cenários RGB completos não devem ser tratados como sprites isolados defeituosos |

## 5. Ordem de tratamento recomendada

1. B-01/B-02: estabelecer geometria/escala/pivô de referência do balcão, **antes
   de aprovar apenas a redução de escala do #9**.
2. R-01: verificar artefato existente no Android, sem gerar outro APK nesta etapa.
3. L-02/R-03/R-10: fortalecer recuperação e integridade de saves sem perder patrimônio.
4. L-01/R-07: produzir e aprovar vistas por família, nunca substituir 0°.
5. R-02/L-04/L-06: acesso e controles de construção.
6. Entregar comércio básico antes de IA avançada, clima e expansão.

Nenhum item desta lista foi corrigido por esta auditoria. Implementação depende
da aprovação do responsável.

## 6. Correção posterior autorizada - B-01

Após a auditoria, o responsável autorizou corrigir somente a projeção de colisão.
**B-01 está corrigido e validado no desktop na árvore de trabalho.** O histórico
da tabela inicial descreve o SHA auditado, antes dessa alteração.

O [componente](../../scripts/Moveis/MovelIsometrico.gd) agora projeta o quarto de
volta no grid 2:1 e compartilha a regra com o polígono confirmado/em prévia.
A base do balcão permanece 128×64 nos quatro ângulos. SVGs não isométricos
preservam a regra anterior; não há mudança de arte, preço, pivô, escala ou save.

Os testes novos detectaram 10 falhas no código antigo. Após a correção: 611
verificações headless, 632 renderizadas e 35 da ferramenta de medição passaram,
sem erros ou avisos. As [evidências finais](evidencias/balcao_corrigido/comparacao.png)
e as [medições](evidencias/balcao_corrigido/medidas.json) foram preservadas.

B-02, a aprovação do encaixe visual/pivô físico e R-01 (Android) continuam
pendentes. A geometria corrigida não transforma vistas frontais em isométricas.

## 7. Marco S1 - recuperação de saves concluída no desktop

A lacuna L-02 foi resolvida em árvore de trabalho, mantendo os arquivos e
migrações existentes. O [gerenciador](../../scripts/Imoveis/GerenciadorImoveis.gd)
agora prioriza principal válido; se inválido/ausente, valida e restaura `.bak`
antes de considerar o arquivo legado.

Proteções:

- Copia o backup para `.recuperacao.tmp` e valida a cópia antes de mover o principal.
- Preserva o danificado em `.corrompido`, `.corrompido.1` etc., sem sobrescrever
  arquivos ou pastas com nomes já ocupados.
- Mantém `.bak` intacto durante a recuperação; autosaves seguintes partem do
  principal válido restaurado, não da versão corrompida.
- Se a instalação final falhar após mover o original, tenta recolocá-lo;
  qualquer falha é informada, incluindo o caminho do arquivo preservado.
- Sem cópia válida ou sem conseguir restaurar, bloqueia a partida; não usa o
  saldo inicial como fallback nem volta silenciosamente a um legado mais antigo.
- HUD informa a recuperação; logs registram o motivo. Migração de backup v1
  mantém patrimônio guardado e preserva `.pre_modular`.

Validação: [162 verificações focadas](../../tests/test_save_recovery.gd) passaram
em modo headless e com renderização; 611 verificações de jogabilidade passaram.
Foram testados JSON truncado/vazio, raiz não objeto, esquema inválido, ausência
do principal, prioridade de arquivos, migração, nomes ocupados, autosave e
reinício, bloqueio sem cópia válida, falha simulada por destino temporário
indisponível e integração com o HUD.

Os avisos de recuperação nos logs são esperados. Erros terminais dos casos
negativos são suprimidos apenas no teste, com `ultimo_erro`, HUD e preservação
dos arquivos conferidos. Não houve erro de parsing ou script.

Limitações: não foi simulada queda de energia real em cada syscall, nem
falha real de disco/rename sob Android. R-03 (validação geométrica de layouts),
R-10 (injeção mais ampla de falhas) e o aceite Android permanecem pendentes.
Três slots e salvamento manual são o marco S2, não parte desta entrega.
