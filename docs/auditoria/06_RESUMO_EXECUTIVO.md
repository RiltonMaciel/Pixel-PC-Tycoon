# 06 - Resumo executivo

## Estado atual após a evolução da campanha

Foram entregues os seis avanços solicitados:

1. Campanha econômica de referência com sete dias, compras reais, lucro,
   despesas/salários e reserva de capital mostrada em Finanças.
2. Clientes retornando com a mesma identidade; satisfação/reputação afetam
   movimento, paciência e desbloqueios de pedidos.
3. Três níveis tecnológicos permanentes e fornecedores de 30/25/20 segundos,
   preservando aquisições de saves antigos.
4. Quatro PCs/OS simultâneos, com peças reservadas, prioridades e retomada.
5. Seis candidatos, especializações e montador automático usando as regras
   de instalação, orçamento, temperatura e estabilidade.
6. Pinça/arraste/recentralização e portas internas com recursos aprovados,
   fechamento seguro e estado persistente.

Validação desta etapa: **2.180 verificações Godot headless + 10 testes de
imagens**, sem falhas. Também **967 verificações renderizadas**, nove capturas.
Contagens repetem cenários entre modos, não requisitos únicos.
Os 142 PNGs originais foram preservados.

**Ainda não é o jogo final:** uma unidade/bancada ativa, serviços representativos,
montagem esquemática, portas provisórias e arte pendente. Faltam gabinete gráfico,
calendário de lançamentos, circulação/IA ampliadas, tráfego, eventos narrativos
e homologação Android. A campanha econômica testada não promete lucro em toda
estratégia. Próximo passo recomendado: teste autorizado em aparelho-alvo.
Não houve APK, commit ou push.

## Registro anterior: seis blocos iniciais de simulação

O jogo já tem **um ciclo de gerenciamento jogável**, além da exploração e dos
móveis. As seções da auditoria original abaixo são históricas.

- Relógio de 15 minutos, calendário, fechamento, despesas e dívida sem caixa negativo.
- Clientes com orçamento/preferência/paciência, fila, histórico e fidelidade.
- Vinte jogos fictícios e montagem com temperatura, estabilidade e correções.
- Cinco serviços: upgrade, diagnóstico, reparo de fonte, limpeza e manutenção.
- Contratação, salário proporcional, habilidades por função e automação de
  caixa, recebimento e assistência.
- Ampliações, divisória, compra/entrada no imóvel maior existente no bairro,
  dia/noite, chuva e eventos que alteram chegadas.

**Não é o jogo final completo.** Há uma unidade ativa e um atendimento por vez,
serviços/candidatos iniciais delimitados e bancada esquemática. Faltam recorrência,
progressão/reputação completas, múltiplas OS, arte final, gestos, polimento e
homologação Android. Estimativas por módulo e prioridades foram atualizadas no
[roadmap](05_ROADMAP_IMPLEMENTACAO.md).

Validação final: **1.479 verificações Godot headless + 10 testes de assets**,
sem falhas; também **716 verificações renderizadas**, com onze capturas.
As execuções repetem cenários entre modos, não são contagens de requisitos únicos.
Os **142 PNGs originais mantêm os mesmos hashes**.

Os sistemas foram ligados à cena existente e testados no desktop. Saves antigos,
sprites aprovados e fachadas foram preservados. Não houve APK, commit ou push.
A próxima etapa recomendada é testar uma campanha e seu ciclo de vida em aparelho
Android, com geração/instalação somente quando autorizadas.

Auditoria de 03/11/2026, commit `b7fcb81`.

## Diagnóstico em uma frase

**O Pixel PC Tycoon já tem uma base jogável de exploração e organização de
loja, mas ainda não possui o ciclo de gerenciamento comercial que define o tycoon.**
Não é necessário recomeçar: há código, arte, persistência e testes úteis para evoluir.

## O que já funciona, com evidência

- Projeto Godot 4.4.1 vertical, D-pad e botão A.
- Bairro explorável, colisões, três travessias, PC Store, cafeteria e cinco
  fachadas vizinhas; 36 objetos decorativos adicionais.
- Entrada/saída com fade e bloqueio de movimento.
- Interior modular 6×5, não uma imagem única esticada.
- Quatro móveis iniciais e **12 itens compráveis**.
- Comprar, arrastar, confirmar, cancelar, revender e persistir móveis.
- Balcão PC Store troca quatro texturas ao girar.
- Save de saldo/layout, backup de escrita e migrações de móveis antigos.
- CI do SHA atual concluiu testes e exportação debug com sucesso.

Validação desta auditoria: **10 testes de imagens**, **567 verificações Godot
headless**, **588 com renderização desktop** e **40 verificações adicionais**.
Foram feitas 13 capturas reais do jogo. Nenhum erro de parser/carregamento foi
observado nas suítes originais.

**Android não foi executado nesta auditoria.** CI verde e desktop funcionando
não provam que o APK abre corretamente em todos os aparelhos.

## O que está parcialmente pronto

- Construção: móveis editáveis, mas sem edição jogável de pisos, paredes e ampliações.
- Câmera: segue externamente; interior fixo, sem pinça/arraste/câmera livre.
- NPC: anda e conversa, mas não compra nem entra na loja como cliente.
- Persistência: um arquivo; faltam três slots, salvamento manual e recuperação de leitura.
- Direção visual: base reaproveitável, mas exterior tem eixos diferentes do 2:1 interno.
- Porta: animação funcional, arte ainda provisória por deformação de recortes.

## O que está com problema

1. **Footprint do balcão:** ao girar, a colisão troca de 128×64 para 64×128 em
   coordenadas de tela, deixando de acompanhar o piso isométrico.
2. **Proporção entre vistas do balcão:** todas têm largura opaca 156 no mundo,
   mas alturas de aproximadamente 72 a 144. Pivô comum no canvas não comprova
   base física comum. Precisa de revisão, não só redução de escala.
3. **11 móveis têm uma só vista.** O botão Girar informa a limitação; não há
   rotação falsa. Faltam **33 PNGs**.
4. **Save corrompido bloqueia a partida mesmo com backup válido.** Preserva os
   arquivos, mas não oferece recuperação pelo jogo.
5. Existe um nome de arquivo terminado em ponto que dificulta checkout/archive
   no Windows; a cópia local usa sparse checkout para excluí-lo.

Os problemas históricos de transição, balcão ausente do catálogo e textura
invisível por ângulo salvo têm correções atuais verificadas no desktop.
A tela cinza no APK **não foi confirmada nem descartada em aparelho**.

## Arte disponível e faltante

Disponíveis: **142 PNGs e 15 SVGs**. Entre os PNGs há 50 recursos de vizinhança,
36 quadros de personagens, sete peças de interior, 11 móveis modulares e quatro
vistas do balcão PC Store, além de cenários, fontes e recursos legados.
Os três modelos de veículos já possuem quatro vistas, mas estão parados.

Faltam principalmente:

- 33 vistas dos móveis, preservando o original 0°.
- Componentes separados e ícones para montagem de PCs.
- Partes combináveis para NPCs procedurais.
- Estados de uso/serviço, clima, eventos e interface de gerenciamento.
- Quadros finais de porta, se aprovados como próxima etapa artística.

Não foram gerados nem modificados sprites. Nomes de “aprovado” e presença de
alfa não substituem revisão humana com as referências.

## O que ainda precisa ser desenvolvido

Estoque, fornecedores digitais, recebimento/entrega, vendas a clientes, caixa
comercial, despesas/lucro/reputação, hardware fictício e compatibilidade,
montagem manual, assistência técnica, clientes recorrentes, funcionários,
aparência procedural, relógio de 15 minutos/dia, clima, eventos, tecnologia,
missões e mudança de imóvel.

Os botões Montagem, Estoque e Menu atualmente avisam que a integração está pendente.
Não há um sistema comercial escondido por trás deles.

## Estimativa de conclusão

**Estimativas funcionais, não medição exata nem prazo:**

| Grupo | Cobertura estimada |
|---|---:|
| Entrada/saída e interior inicial | 75–85% |
| Plataforma/controles/câmera Android | 45–60% |
| Exterior e mundo vivo | 30–40% |
| Móveis/construção completa | 25–40% |
| Save/offline completo | 20–35% |
| Imóveis/mudança | 10–20% |
| Economia/estoque/fornecedores | 0–5% |
| Clientes comerciais | 0–5% |
| Hardware, montagem, serviços, equipe, tempo/clima/progressão | 0% de fluxo funcional em cada módulo |

Não há percentual global confiável. A maior parte do trabalho de simulação
comercial continua à frente; detalhes de cada módulo estão no [roadmap](05_ROADMAP_IMPLEMENTACAO.md).

## Ordem recomendada

1. Aprovar esta auditoria e a primeira tarefa.
2. Medir/corrigir o encaixe do balcão; validar o APK existente em aparelho.
3. Recuperação de saves e três slots.
4. Quatro vistas por família, acesso/câmera e construção incremental.
5. Relógio, estoque, fornecedores e primeira venda.
6. Hardware, montagem manual e pedidos.
7. Clientes recorrentes, funcionários e assistência.
8. Mundo vivo, progressão, expansão e polimento Android.

**Primeira tarefa técnica:** validar base, pivô, colisão e proporção do balcão PC
Store nas quatro vistas antes de incorporar o PR #9. Ele permanece aberto e
altera apenas escala. O PR #11 já está incorporado.

## Entrega e preservação

Apenas os seis documentos desta pasta foram adicionados ao projeto. Não houve
mudança no jogo/documento mestre, atualização de branch, exclusão de arquivos,
geração de APK, commit ou push.

Leitura complementar:
[estado técnico](01_ESTADO_ATUAL.md),
[matriz de requisitos](02_GAP_ANALYSIS.md),
[inventário visual](03_AUDITORIA_SPRITES.md),
[bugs e riscos](04_BUGS_E_RISCOS.md),
[plano incremental](05_ROADMAP_IMPLEMENTACAO.md).

**Aguardando aprovação antes de qualquer alteração no jogo.**

### Acompanhamento após autorização para seguir

A primeira medição foi executada, sem alterar gameplay ou sprites. Foram
adicionados uma ferramenta diagnóstica e cinco imagens de evidência, além das
medições em JSON. As 35 verificações funcionais passaram, mas a geometria do
balcão em 90°/270° foi reprovada. O PR #9 permanece sem aplicação.
Veja a [comparação visual](evidencias/balcao/comparacao.png) e o
[registro detalhado](03_AUDITORIA_SPRITES.md#9-acompanhamento-a1---baseline-reproduzível-do-balcão).
Ao encerrar essa medição, o ajuste de colisão e a aprovação de escala/pivô
artístico ainda não haviam sido feitos.

### Correção técnica autorizada e concluída

Depois da medição, foi autorizada a correção apenas da projeção de colisão.
O balcão agora mantém uma base de **128×64 alinhada ao grid nas quatro vistas**.
Os sprites, pivôs e escala 0,65 permanecem intactos.

Validação final: **611 verificações headless, 632 com renderização e 35 medições
funcionais passaram**, sem falhas; 142/142 PNGs originais mantêm seus hashes.
Veja a [comparação corrigida](evidencias/balcao_corrigido/comparacao.png).

A fidelidade artística entre vistas e o teste Android continuam pendentes.
Não houve APK, commit, push ou aplicação do PR #9.

### Marco S1 - recuperação segura de saves

O jogo agora recupera automaticamente o último `.bak` válido quando o principal
está inválido ou ausente. Preserva o arquivo danificado em um nome único, avisa
no HUD e permite continuar salvando sem transformar a corrupção no novo backup.
Se não houver cópia válida ou a restauração falhar, mantém a partida bloqueada
com erro explícito, sem sobrescrever o progresso por uma partida nova.

Foram aprovadas **162 verificações de recuperação headless, 162 com renderização
e 611 de regressão de jogabilidade**. As migrações antigas continuam funcionando.
A [suíte dedicada](../../tests/test_save_recovery.gd) também foi adicionada ao
workflow, ainda não executado remotamente nesta etapa.

Sprites não foram alterados; não houve APK, commit ou push.
**Próxima entrega: três slots e salvamento manual.**
O teste Android e a aprovação artística do balcão continuam pendentes.

### Sequência autorizada concluída: slots, construção, comércio e primeiro PC

Agora existem três partidas independentes com salvar manualmente e autosave.
O progresso antigo pertence ao slot 1; não é copiado para os outros. O último
slot escolhido é reaberto, mantendo a recuperação segura já implementada.

Posicionar/mover/girar móveis não pode fechar o caminho do jogador, entrada ou
estações. O cliente também fica protegido contra aprisionamento pela construção.
Não foram inventadas vistas para móveis com apenas uma orientação.

O notebook abre um fornecedor de 15 componentes fictícios. Comprar debita o
caixa; a entrega de 30 segundos ativos só vira estoque ao receber. Um cliente
entra, pede a peça, espera no balcão, paga uma vez e sai. Compras, receita, CMV e
lucro bruto aparecem no painel. Preços/prazos são parâmetros iniciais de teste.

O primeiro pedido de PC vai da compra das peças à montagem manual na bancada,
com oito encaixes, compatibilidade, cabos, boot e entrega por R$ 2450.
As peças do conjunto inicial custam R$ 1780: lucro bruto de R$ 670.
Reserva de peças, montagem parcial, teste e configuração entregue persistem
entre reinícios e slots. Cancelar devolve as peças sem duplicação.

**Não é o jogo inteiro concluído.** A montagem usa cartões, não novos sprites
finais do gabinete. Faltam Android, múltiplos clientes/OS, perfis, funcionários,
dia/noite, progressão, diagnósticos avançados e produção artística autorizada.

Validação aprovada: **257 verificações novas headless, 262 renderizadas,
611 de gameplay e 162 de recuperação**. As cinco capturas da interface foram
inspecionadas. [Como jogar e limites](../../README.md);
[testes integrados](../../tests/test_progression.gd).

Nenhum sprite aprovado foi alterado; não houve APK, commit ou push.
A próxima prioridade recomendada é testar os quatro fluxos em Android.
