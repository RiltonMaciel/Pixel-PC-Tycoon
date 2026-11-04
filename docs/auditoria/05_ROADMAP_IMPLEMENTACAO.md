# 05 - Roadmap incremental de implementação

## Ordem vigente solicitada: visual antes das outras expansoes

1. **Visual do bairro:** previa reversivel entregue com dois carros/quatro
   vistas cada, um mercado e acabamento do passeio. Aprovar/refinar o resultado
   antes de substituir originais e ampliar outras fachadas. Commit/PR separado,
   sem merge automatico. Amostras procedurais nao equivalem a arte final.
2. **IA e circulacao:** espacamento entre atores, filas, funcionarios e
   veiculos; validar ausencia de sobreposicao/bloqueio sem reduzir o jogo a
   atores imoveis ou alterar silenciosamente a demanda.
3. **Construcao e arte:** paredes/acabamentos, 33 vistas, portas e gabinete
   definitivos, com aprovacao visual e preservacao dos recursos existentes.
4. **Campanhas variadas:** estrategias de demanda, salarios, divida e expansao,
   complementando a referencia de 56 dias.
5. **Preparacao de release:** assinatura e instalacao/atualizacao preservando
   saves, checklist; depende de keystore/aparelhos e autorizacao para APK.
6. **Eventos e decisoes:** falta de pecas, contratos, atrasos e consequencias.
7. **Assistencia ampliada:** defeitos combinados, resultados inconclusivos e
   diagnosticos alternativos.
8. **Personalizacao completa:** corpo, cabelo, roupas e uniformes com arte propria.
9. **Gestao:** relatorios por produto/servico, giro, margem e previsao de contas.
10. **Varias lojas simultaneas:** estoque transferivel/equipes por unidade,
    diferente do sistema atual de uma unidade ativa.
11. **Acessibilidade/opcoes:** texto, volume, vibracao, contraste e controles.
12. **Audio:** musica/ambiencia/passos/ferramentas e feedback.
13. **Progressao adicional:** objetivos, contratos maiores e mais geracoes.

Os itens 2-13 nao sao declarados concluidos por esta entrega visual.
Integracao da previa testada em nove suites (3.175 verificacoes headless),
87 verificacoes renderizadas e 12 testes de imagens. Android continua pendente.

## Próximas entregas após evolução da campanha/mundo

Já integrados: metas opcionais, calendário datado, investigação por ensaios,
pisos/setores, acessórios, diagrama interativo, guia, pausa/safe area, mundo
limitado e ensaio de oito semanas. Isso não encerra a visão oficial.

| Prioridade | Entrega restante | Dependência | Critério de aprovação |
|---|---|---|---|
| 1 | CI Linux do novo PR | Publicação desta branch | Importação, imagens e oito suítes verdes sem exportar APK |
| 2 | Homologação Android | Aparelho/SDK e autorização para gerar APK | Abrir, pausar, reabrir, trocar slots e usar UI com notch; medir FPS, memória/bateria |
| 3 | Arte definitiva | Aprovação específica | 33 vistas coerentes, portas, hardware e corpo/roupa/cabelo; pivôs/colisões testados; sem rotações falsas |
| 4 | IA/densidade | Rotas e visitas já entregues | Evitar sobreposição dinâmica; campanhas orgânicas e eventos narrativos sem bloqueio |
| 5 | Acabamentos restantes | Arte e decisões visuais | Paredes/acabamentos individuais sem perder saves ou abrir colisões indevidas |
| 6 | Balanceamento humano prolongado | Campanha automatizada de 56 dias | Diferentes estratégias, dívidas, especialistas/imóveis, sem renda criada por teste |
| 7 | Release assinado | Keystore em secrets e homologação Android | Exportação release autorizada, instalação/atualização e persistência verificadas |

CI de PR não gera APK; exportação automática ficou restrita a `main`.
Release manual exige `ANDROID_RELEASE_KEYSTORE_B64`, `ANDROID_RELEASE_ALIAS`
e `ANDROID_RELEASE_PASSWORD` (senha igual para chave/keystore). Não executado
nesta etapa. Critérios Android/arte permanecem abertos, não marcados como concluídos.

Referência medida: **3.090 verificações headless, 1.419 renderizadas, 10 testes
de imagens**, 142 PNGs intactos. As etapas anteriores abaixo são históricas.

## Atualização mais recente: seis evoluções entregues

Campanha econômica → recorrência/reputação → níveis/fornecedores → quatro OS →
especialistas/montador → gestos/portas foram integrados e testados.
O ensaio econômico é uma referência de sete dias sem injeção de recursos,
não uma campanha narrativa final ou garantia de lucro para qualquer estratégia.

**Estimativa revisada de cobertura funcional do mestre**, não medição de código
ou prazo; não calcular média simples:

| Módulo | Estimativa | Evidência e restante |
|---|---:|---|
| Economia | 75–85% | Campanha, margens, folha/contas; sessões longas e diversidade de estratégias pendentes |
| Clientes | 60–75% | Retorno, reputação, orçamento, filas; circulação/variação comportamental ampliadas pendentes |
| Tecnologia/montagem | 60–75% | Níveis permanentes, três fornecedores, 20 jogos, montagem automática; calendário de lançamentos e gabinete gráfico pendentes |
| Assistência | 60–75% | Quatro PCs/OS, reservas, prioridades; diagnósticos variados e maior profundidade pendentes |
| Funcionários | 50–65% | Seis candidatos, quatro funções, montador e especializações; aparência procedural/IA ampliada pendentes |
| Construção/mundo | 50–65% | Gestos, portas seguras, ampliações e clima; arte final, pisos editáveis, tráfego e eventos narrativos pendentes |

Próxima entrega recomendada: homologação Android autorizada com percurso
completo, quatro OS, pinça/D-pad, porta, fechamento e pausa/reabertura.
Medir memória/FPS e corrigir somente problemas reproduzidos antes de ampliar
tráfego, diagnósticos ou campanha narrativa. Produção de arte exige aprovação;
geração/instalação de APK não foi executada.

## Registro anterior: seis primeiras fatias adicionais entregues

Relógio/economia → clientes → montagem ampliada → assistência → equipe →
reforma/mundo foram implementados consecutivamente na árvore de trabalho,
reaproveitando os sistemas anteriores. O plano/percentuais originais abaixo
permanecem históricos, não descrevem mais a ausência desses módulos.

**Estimativa atual de cobertura do escopo final, não prazo nem porcentagem
medida de código:**

| Módulo | Estimativa | Evidência e restante principal |
|---|---:|---|
| Relógio/economia | 65–80% | Calendário, fechamento, dívida, salários; balanceamento e reputação global pendentes |
| Clientes | 45–60% | Fila/perfis/paciência/histórico; falta recorrência real e circulação dinâmica completa |
| Montagem | 50–65% | Oito encaixes, 20 jogos, térmica/estabilidade; gabinete gráfico e progressão tecnológica pendentes |
| Assistência | 45–60% | Cinco serviços com orçamento/consumo/teste/pagamento; casos variados e múltiplas OS pendentes |
| Funcionários | 35–50% | Contratos, salários, funções/XP e automação; candidatos/aparência procedural e IA ampliada pendentes |
| Construção/mundo | 40–55% | Ampliação, divisória, segundo imóvel, clima/eventos; portas internas, acabamento, gestos e tráfego pendentes |

Próxima ordem recomendada:

1. Homologação Android autorizada, sem assumir APK desktop-equivalente:
   entrada/saída de ambos os imóveis, toque/arraste, fechamento, OS/equipe,
   pausa/reabertura e modo avião; medir FPS/memória.
2. Corrigir problemas reproduzidos de UX/desempenho, depois balancear a primeira
   campanha sem injetar estoque/dinheiro de testes.
3. Recorrência/reputação/progressão e múltiplas OS, com contratos de reserva.
4. Arte pendente por família, somente com aprovação; gabinete gráfico,
   aparência procedural, portas e gestos de câmera.

Primeira tarefa técnica seguinte: preparar uma matriz de teste de aparelho-alvo
e executar um percurso comercial completo com gravação/reabertura. Geração de
APK, alterações de arte e publicação não foram executadas nesta entrega.

Base: `b7fcb81`, 03/11/2026. **Plano, não autorização de implementação.**
Reaproveitar bairro, sala modular, personagens, catálogo, edição e migrações.
Não reconstruir o jogo nem reorganizar toda a árvore para imitar a proposta do mestre.

## 1. Estimativa de conclusão por módulo

**Estimativas de cobertura funcional**, não métricas de código, prazo ou garantia.
Consideram o escopo final do mestre, com intervalos deliberadamente amplos.
Teste desktop aumenta confiança, não elimina trabalho Android/arte.
Sistemas marcados 0% não têm um fluxo funcional; assets preparatórios são citados
separadamente. Não calcular média simples desses números.

| Módulo | Estimativa concluída | Base observável e maior restante |
|---|---:|---|
| Plataforma, controles e câmera Android | 45–60% | Projeto retrato, D-pad/A e desktop testados; gestos, safe area e runtime Android pendentes |
| Exterior explorável e mundo vivo | 30–40% | Mapa conectado e decoração; só um NPC cíclico, sem tráfego/clima/animação/fluxo comercial |
| Entrada/saída e interior inicial | 75–85% | Transição e sala testadas; porta provisória, validação visual móvel pendente |
| Móveis e construção completa | 25–40% | Comprar/mover/vender/cancelar/salvar prontos; faltam 33 vistas, footprint correto, estrutura editável e câmera livre |
| Imóveis e mudança patrimonial | 10–20% | Cadastro/estados por ID; único imóvel, sem compra/aluguel/mudança |
| Economia comercial, estoque e fornecedores | 0–5% | Saldo e transações de decoração são fundação; nenhum ciclo de compra/recebimento/venda de produtos |
| Hardware fictício e progressão tecnológica | 0% | Nenhum catálogo/compatibilidade/desbloqueio utilizável |
| Montagem interativa | 0% | Bancada decorativa; sem peças, montagem ou testes |
| Assistência técnica/OS | 0% | Nenhum dos seis serviços executável |
| Clientes comerciais/recorrência | 0–5% | Um NPC visual e conversa; sem compra, orçamento, fila ou histórico |
| Funcionários e aparência procedural | 0% | Técnico/cliente mochila têm arte pronta, mas não contratação/IA/camadas de aparência |
| Tempo, clima, eventos e missões | 0% | Sem relógio, demanda dinâmica ou progressão |
| Save/offline do escopo completo | 20–35% | Saldo/layout/migração e escrita protegida; faltam slots, comando manual, recuperação e simulação completa |
| Arte e integração visual do escopo completo | 20–35% | 142 PNGs úteis/preservados; várias famílias essenciais de hardware, NPC por partes, serviços e clima inexistem |
| QA, distribuição e polimento final | 20–35% | CI debug e suítes úteis; falta QA Android, performance, release, balanceamento e aceite visual |

Não há estimativa responsável de data final sem medir ao menos duas ou três
entregas verticais, definir aparelho-alvo e obter aprovações artísticas.
Produção de 33 vistas e sistemas de gerenciamento pesa muito mais que seus nomes sugerem.

## 2. Entregas pequenas, dependências e aceite

| Etapa | Entrega delimitada | Depende de | Critério objetivo de aprovação |
|---|---|---|---|
| A0 | Aprovar diagnóstico e prioridade | Leitura dos seis relatórios | Responsável aceita escopo e autoriza a primeira alteração; arte preservada |
| A1 | Baseline geométrica do balcão | A0 | Quatro capturas no mesmo ponto/piso, base/pivô medidos por vista, contornos sobrepostos, giro completo, cancelar e reload demonstrados; nenhuma mudança de PNG |
| A2 | Corrigir footprint/pivô/escala autorizados | A1 e decisão sobre #9 | Colisão projetada nos eixos do piso em quatro vistas; jogador bloqueado apenas pela base física; sem sobreposição/fora do piso; proporção aprovada |
| A3 | Aceite Android do protótipo | A0; pode ocorrer em paralelo a A1 | Artefato do SHA identificado abre sem tela vazia; D-pad/A, entrada/saída, compra/giro/save/reabertura e modo avião funcionam; logs sem erros de script/recurso |
| S1 | Recuperar save válido sem destruir original | A0 | Principal corrompido/ausente + backup válido recuperável com aviso; ambos inválidos bloqueiam; erro de escrita explícito; saldo/móveis preservados |
| S2 | Três slots e salvar manualmente | S1 | Três partidas independentes; autosave/manual não cruzam dados; migração do arquivo atual testada; pausar/reabrir restaura slot escolhido |
| F1 | Aprovar uma família de quatro vistas | A1, referência artística aprovada | Começar por `balcao_atendimento`: original 0° com hash idêntico; 90/180/270 coerentes, alfa real, base constante; aprovação humana antes de integração |
| F2 | Integrar essa família no jogo | F1, A2 | Compra, quatro giros, retorno a 0°, mover/cancelar/vender/save/reload; footprint e profundidade corretos no desktop e Android |
| F3 | Completar demais famílias em lotes pequenos | F2 | Repetir o mesmo aceite, na ordem bancada, mesa, prateleira, armário, estante, vitrine, cadeira, banqueta, caixa, PC; 33 vistas adicionais no total |
| C1 | Conectividade e acesso no modo edição | A2 | Layouts que fecham entrada/rota a estação são rejeitados; layouts válidos permanecem editáveis; jogador não fica preso |
| C2 | Gestos/câmera e safe area | A3, C1 | Pinça/arraste/recentralizar/construção livre funcionam sem mover móvel indevidamente ou travar D-pad; teste em telas/dispositivos definidos |
| C3 | Editar piso e ampliar sala permitida | C1, S2 | Uma ação estrutural por vez, instantânea; limites/custo/cancelamento/save corretos; móveis inválidos não são perdidos |
| C4 | Divisórias/portas e setores | C3 | Construção mantém acessos, profundidade e pontos de trabalho; reload restaura estrutura |
| E1 | Relógio e livro-caixa mínimo | S1 | Dia completo em **900 segundos reais**; pausa de construção decidida explicitamente; entradas/saídas financeiras idempotentes e persistentes |
| E2 | Catálogo de peças e estoque | E1 | IDs e quantidades; compra, recebimento e reserva não duplicam estoque; patrimônio de móveis separado de produtos |
| E3 | Fornecedor digital e entrega básica | E2 | Notebook abre catálogo real; dinheiro debitado uma vez; estoque aumenta só no recebimento; prazo/estado sobrevivem ao reload |
| E4 | Primeira venda comercial completa | E2, base NPC existente | Cliente entra, solicita item disponível, paga uma vez, sai; estoque e caixa conferem; cancelamento/falta de estoque têm resultado explícito |
| H1 | Hardware fictício e compatibilidade mínima | E2, decisão de design | CPU/socket, RAM, potência, gabinete/conectores têm casos compatíveis/incompatíveis testados; catálogo inicial pequeno, expansível |
| P1 | Primeiro pedido de PC manual | E3, E4, H1 | Receber pedido/orçamento, reservar peças, arrastar/instalar, testar boot e entregar; custo/lucro e pagamento único corretos |
| P2 | Ampliar montagem/testes progressivos | P1 | Temperatura/estabilidade/desempenho e falhas recuperáveis; nenhum pedido perde componentes no reload |
| N1 | Clientes dinâmicos e recorrentes | E4, P1 | Orçamento/paciência, filas/desistência/retorno; histórico do mesmo cliente/PC persiste |
| N2 | Aparência procedural | N1 e pacote de camadas aprovado | Mesma seed reproduz aparência em quatro direções, sem offsets incoerentes; atributos separados da aparência |
| Q1 | Primeiro funcionário/uma função | E4, S2 | Contratar, atribuir caixa, concluir pagamento sem duplicar; salário e habilidade persistem; nenhum posto ocupado em duplicidade |
| Q2 | Prioridades e ordens manuais | Q1, P1 | Uma tarefa indivisível termina antes de ordem conflitante; sem bancada dupla, falta de peças ou fila travada |
| O1 | Uma OS de upgrade/diagnóstico | P2, N1 | Recepção → orçamento → execução → teste → pagamento/entrega, com prazo e configuração do PC preservados |
| O2 | Reparo, limpeza e prevenção | O1 | Um serviço por incremento; retrabalho e custo/reputação testados |
| W1 | Dia/noite e tráfego | E1, A3 | Iluminação azulada noturna; carros realmente percorrem rotas; densidade por horário respeita orçamento de desempenho definido |
| W2 | Chuva e eventos com demanda | W1, E4 | Chuva muda estado visual/comportamental; evento altera demanda, não só decoração |
| W3 | Tecnologia, jogos e missões opcionais | H1, N1, E1 | Novas gerações/desbloqueios e pedidos de jogos fictícios; missões não impedem jogo livre |
| X1 | Mudar para segundo imóvel | C4, E2, Q1, S2 | Estado por ID, transferência sem duplicação de dinheiro/estoque/móveis/equipe; voltar restaura planta correta |
| Z1 | Polimento/release | Fatias funcionais aprovadas | Metas de FPS/memória/bateria em aparelhos definidos, regressões Android, recuperação, balanceamento e build release rastreável |

As dependências são técnicas; A3, S1 e preparação artística podem ser trabalhadas
independentemente depois da autorização. Não iniciar simultaneamente todos os sistemas.

## 3. Primeira tarefa recomendada

**Validar e documentar o encaixe físico do balcão PC Store nas quatro vistas,
antes de alterar escala ou incorporar o PR #9.**

Superfícies:
[catálogo](../../scripts/Imoveis/CatalogoSprites.gd),
[componente](../../scripts/Moveis/MovelIsometrico.gd),
[validação de posição](../../scripts/RuaComercial.gd#L344) e
[testes](../../tests/test_game.gd).

Entrega inicial pequena: referência mensurada de base/pivô por ângulo e
reprodução visual com contornos no mesmo piso. Só depois, ajuste de código
autorizado e testes por vista. Caso a arte não permita uma transformação física
coerente, registrar o impedimento e pedir autorização artística; não deformar o
sprite nem trocar o original.

Em paralelo administrativo, testar o **APK já existente** em aparelho para
encerrar a dúvida sobre tela cinza. Isso não exige gerar um APK durante a auditoria.

## 4. Contrato de cada implementação futura

1. Autorizar escopo e preservar hashes dos sprites de referência.
2. Alterar apenas superfícies necessárias; manter saves antigos.
3. Acrescentar teste do requisito exato, inclusive erro/cancelamento/reload.
4. Executar imagens, importação/parsing e suíte focada; renderizar se houver impacto visual.
5. Validar em aparelho quando a mudança afetar toque/renderização/ciclo de vida.
6. Registrar SHA, evidências e limitações. Commit, push, PR e APK somente quando autorizados.

Não tratar a criação de um script, um botão com aviso ou um recurso importado
como conclusão da entrega.

## 5. Acompanhamento após autorização - A1

A baseline técnica foi executada: quatro capturas no mesmo ponto, medidas por
vista, contornos sobrepostos e 35 verificações de giro/cancelamento/persistência.
As [evidências e limitações](03_AUDITORIA_SPRITES.md#9-acompanhamento-a1---baseline-reproduzível-do-balcão)
confirmam a reprovação geométrica de 90°/270°.

**A1 tem evidência técnica entregue, mas o aceite do pivô/base físicos ainda está
bloqueado pela inconsistência artística das vistas.** Ao encerrar A1, A2 não havia sido iniciada, o PR #9
não foi aplicado e nenhum sprite ou script de gameplay foi alterado.
É necessária decisão explícita entre corrigir apenas a colisão conhecida,
mantendo a pendência visual, e revisar primeiro as referências artísticas.

## 6. Acompanhamento A2 - parcela técnica aprovada

O responsável escolheu corrigir somente a projeção de colisão, preservando
sprites/escala. Essa parcela foi concluída e testada: a base do balcão é 128×64
nas quatro vistas. Os novos testes falhavam antes e passam após o ajuste;
a ferramenta terminou com exit 0 e 35 verificações aprovadas.

A2 **não recebe aceite visual completo**: permanecem pendentes o pivô físico,
a coerência das quatro vistas e o teste Android. Escala segue 0,65; PR #9
continua sem aplicação. Nenhum commit/push/APK foi feito.
Ver [resultados e capturas](03_AUDITORIA_SPRITES.md).

## 7. Acompanhamento S1 - recuperação segura concluída

Implementado no [gerenciador existente](../../scripts/Imoveis/GerenciadorImoveis.gd),
sem introduzir um serviço de save paralelo. Principal válido permanece prioritário;
principal inválido/ausente pode ser restaurado a partir de `.bak` validado,
preservando o danificado em nome único e informando o jogador.
Sem cópia válida ou com erro de restauração, o bloqueio permanece.

Aceite desktop:

- Saldo, móveis, guardados, posições e ângulos preservados.
- Original e backup conferidos após recuperação, autosave e reinício.
- Migração de backup v1 preservada, incluindo `.pre_modular`.
- Erros de leitura/restauração não retornam sucesso nem iniciam partida nova.
- HUD exibe recuperação ou bloqueio conforme o resultado.
- 162 verificações focadas headless, 162 renderizadas e 611 de regressão passaram.
- A nova suíte foi conectada ao workflow; o workflow remoto **não foi executado**
  nesta etapa, pois não houve commit/push nem geração de APK.

S1 está concluído e validado no desktop, com limitações de falhas físicas e Android
registradas em [bugs e riscos](04_BUGS_E_RISCOS.md).
**Próxima entrega: S2, três slots independentes e salvamento manual**, preservando
a migração do arquivo atual. A autorização de arte e o ajuste de escala do PR #9
continuam separados deste trabalho.

## 8. Quatro entregas seguintes autorizadas e executadas

O responsável autorizou seguir S2 → construção segura → primeiro ciclo comercial
→ primeira montagem, sem nova pausa entre entregas. Resultado desktop:

| Entrega | Resultado delimitado |
|---|---|
| S2 | Três slots isolados, escolha persistida, salvar manual, migração do arquivo atual para o slot 1 sem duplicar legado nos demais; backup e erro explícito mantidos |
| C1 | Conectividade de entrada/saída, jogador, cliente e estações; bloqueio de corredor sem sobreposição detectado; alterações inválidas não confirmam nem cobram |
| E2–E4 iniciais | 15 peças fictícias, pedidos pagos, prazo ativo de 30 s, recebimento manual, estoque, caixa/CMV/lucro bruto e uma venda completa por atendimento |
| H1/P1 iniciais | Socket/RAM/potência/formato/dimensões/conectores/cooler, oito peças instaladas manualmente por arraste/toque, cabos, boot/requisitos, entrega paga e configuração persistida |

Validação: [257 verificações headless e 262 renderizadas](../../tests/test_progression.gd),
mais 611 de gameplay e 162 de recuperação. Cinco capturas foram inspecionadas
no ambiente de validação. Workflow atualizado, sem execução remota ou APK.

**Não equivalem ao escopo final desses módulos.** E1 tem apenas o livro-caixa
comercial; o relógio de 900 s, despesas e períodos continuam pendentes.
P1 usa bancada esquemática e orçamento inicial fixo, não arte final, vinte jogos,
funcionários nem dificuldade progressiva. N1/fidelidade e OS adicionais continuam
no backlog. As estimativas da seção 1 são o retrato inicial, não percentuais
recalculados automaticamente pelas novas entregas.

Próxima prioridade recomendada: aceite Android dos quatro fluxos, antes de
expandir relógio/economia, variedade de pedidos e diagnósticos. Não foi gerado APK;
arte aprovada, decisão visual do balcão e PR #9 continuam separados.
