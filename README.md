# Pixel-PC-Tycoon

Prototipo Android em Godot **4.4.1 Standard**, GDScript e pixel art.
Resolucao de referencia: 432 x 768, retrato. Nao usa .NET nem HTML.

## Previa visual do bairro (pendente de aprovacao)

Em `Financas > Previa visual do bairro: ativar`, compare o visual original com:

- Carro azul e picape vermelha, oito PNGs transparentes de quatro vistas
  independentes do modelo, sem girar uma imagem para simular outra vista.
- Mercadinho com prateleiras, letreiro, toldo, esquadrias e cobertura detalhados.
- Escala comum entre os novos carros estacionados e em movimento; piso tatil
  e juntas do meio-fio, mantendo as colisoes e entradas existentes.

Sao **amostras procedurais de pixel art, nao a arte final no nivel de detalhe
da imagem de referencia**. So um comercio e dois modelos participam da amostra;
as demais fachadas e o furgao continuam originais. A previa inicia desligada,
pode ser revertida no mesmo botao e nao reescreve saves. Os 142 PNGs aprovados
foram preservados. Recursos novos em [PreviaVisual](Assets/Cenarios/PreviaVisual/);
geracao reproduzivel: `python tools/create_visual_preview.py` (Pillow).

Validacao desta entrega: nove suites, **3175 verificacoes headless**; teste
da previa renderizada com **87 verificacoes** e duas capturas; **12 testes
de imagens**, sem falhas. Nao foi gerado APK. A aprovacao estetica continua
humana; testes de pixels/projecao nao comprovam qualidade artistica.

## Abrir e jogar

1. Importe `project.godot` no Godot 4.4.1.
2. Pressione F5. Nao e necessario instalar o SDK Android para jogar no PC.
3. Use as setas ou o D-pad (mouse/toque). Clique em A ou pressione Enter para interagir.
4. Perto da porta da PC Store, A entra. No interior, aproxime-se de `SAIDA [A]`.
5. Dentro da loja, `Loja` abre 14 moveis/divisorias/portas e acesso a ampliacao. Toque num item para comprar.
6. Arraste pelo piso. `Girar` troca a textura quando existem vistas adicionais; `OK` ou A confirma.
   Vermelho indica colisao ou bloqueio da entrada. O dinheiro so e descontado na confirmacao.
7. Toque/clique em um movel existente: `Mover`, `Girar`, `Vender`, `Cancelar`, `OK`.
   Cancelar restaura tanto a posicao quanto a orientacao. Escape tambem cancela.

O pacote de vizinhanca v2 esta integrado ao mapa principal, nao apenas a uma
montagem de demonstracao. Se o jogo ja estava aberto, pare com F8 e execute F5
novamente. Siga a calcada da PC Store para baixo/direita: depois da cafeteria
ficam mercadinho, farmacia, loja de roupas, restaurante e salas comerciais.
O nome historico da janela (V0.4.8) foi mantido para preservar o caminho dos saves;
nao indica que as fachadas novas estao ausentes.

O primeiro ciclo comercial e a primeira montagem manual estao integrados.
As imagens legadas e os sprites aprovados foram preservados.

## Partidas, comercio e primeiro PC

- `Menu` oferece tres partidas independentes e `Salvar agora`. A ultima partida
  escolhida e restaurada ao reabrir; trocar de slot salva a anterior primeiro.
  Conclua ou cancele edicoes antes da troca. O retorno e ao exterior da loja,
  nao a uma posicao de personagem persistida.
- A construcao verifica rotas entre jogador, entrada, saida e estacoes.
  Fechar corredores ou prender o cliente impede confirmar, sem cobrar.
  Remover um obstaculo continua permitido; layouts antigos nao sao rearranjados.
- Aproxime-se da mesa com notebook e pressione A, ou abra `Estoque`.
  Tres fornecedores oferecem 30 componentes/consumiveis ficticios, com desbloqueios por nivel e data.
  Cada clique encomenda uma unidade
  e debita o custo; a peca ainda nao entra no estoque.
- A entrega leva **30, 25 ou 20 segundos de simulacao ativa**, conforme fornecedor. Em `Estoque`, use
  `Receber` quando estiver pronta. Receber novamente nao duplica a quantidade.
  O prazo restante persiste; nao ha avanco de entregas com o aplicativo fechado.
- No balcao, `Cliente` permite chamar um comprador para uma peca disponivel.
  Tambem chegam clientes a fila de ate quatro pessoas, se houver estoque.
  O intervalo-base de 20 segundos varia com clima/eventos e reputacao. Cada perfil possui
  orcamento, preferencia e paciencia; o primeiro com oferta acessivel e atendido.
  Ele caminha por rotas livres e espera.
  Aproxime-se e escolha `Vender e receber`; estoque e dinheiro mudam uma vez.
- Aceite `Pedido PC` em `Cliente`. Orcamento inicial: R$ 2450; requisitos:
  CPU/GPU 100 pontos, RAM 8 GB e SSD 240 GB. So ha um atendimento por vez.
- Compre e receba: Ninho Mini, Aurora M1, Aurora Quad, Brisa 8 GB, Clara 450 W,
  Trilha SATA 240, Pixel 100 e Neve 100. Custo total: R$ 1780.
- Aproxime-se da bancada e pressione A ou `Montagem`. Arraste cada cartao de
  componente ao encaixe, ou toque na opcao para instalar individualmente.
  Comece pelo gabinete e placa; CPU antes do cooler. Toque num encaixe instalado
  para remover a peca, respeitando as dependencias.
- O jogo verifica socket, RAM, formato da placa, tamanho da GPU, conectores,
  potencia e cooler. Pecas instaladas saem do estoque vendavel. Cancelar o
  pedido devolve as pecas; nao existe taxa de cancelamento nesta primeira entrega.
- Conecte os cabos e execute o teste de boot/requisitos. Volte ao balcao para
  entregar o PC testado. Sua configuracao permanece salva; pagamento nao se repete.
  Alterar componentes invalida cabos/teste anteriores.
- `Estoque` mostra compras, receita, custo das mercadorias vendidas (CMV) e
  lucro bruto comercial. `Financas` separa despesas e fechamento diario.
  Os precos e prazos deste primeiro ciclo sao parametros provisorios de balanceamento.

A bancada usa **cartoes esquematicos**, nao novos sprites finais de hardware.
O painel `Gabinete visual` permite arrastar pecas para oito encaixes no diagrama;
nao e a arte final do interior do gabinete. As fatias adicionais abaixo nao equivalem ao
escopo final completo do documento mestre.

## Calendario, clientes, servicos e equipe

- Dia de **900 segundos reais**, semana de 7 dias, mes de 28 e ano de 12 meses.
  Editar/construir moveis pausa relogio, entregas, paciencia e funcionarios.
  Outros paineis nao pausam o dia. Nao ha avanco com o aplicativo fechado.
- Em `Financas`, consulte os ultimos sete fechamentos, pague contas e abra
  funcionarios/imoveis. Cada virada cobra **R$ 100 de aluguel + R$ 20 de energia**
  da operacao, mais salarios. Sem dinheiro, o restante vira divida, nunca caixa
  negativo. Reabrir nao cobra novamente. Lucro liquido aqui desconta CMV e essas
  despesas; compras de moveis, ampliacoes e imoveis sao investimentos separados.
- Perfis e historico persistem. Compra soma 2 de reputacao; desistencia tira 4 e
  cancelamento tira 1. Compradores retornam com a mesma identidade em 1 a 3 dias;
  os demais em 4 dias. Reputacao afeta demanda, paciencia de novos clientes e
  desbloqueios de pedidos. A fila aparece no interior; falta avoidance dinamico completo.
- A oficina aceita **quatro PCs/OS simultaneos**, contando a montagem ativa.
  Depois de autorizar uma OS, `Guardar PC` reserva seus insumos e libera o balcao.
  Reservas nao podem ser vendidas nem consumidas por outra ordem. Retome na bancada;
  prioridade urgente/normal/baixa orienta o tecnico, com desempate por chegada.
  Cancelar antes do consumo devolve a reserva uma unica vez.
  Ha uma bancada/atendimento ativo por vez; nao e uma fila de montagens completas.
- `Cliente` oferece **22 jogos ficticios**, todos com configuracao compativel
  e financeiramente possivel verificada. Na bancada, o teste mede requisitos,
  temperatura e reserva da fonte. Trocar cooler/fonte corrige falhas reais de
  gameplay; alterar pecas invalida cabos e diagnostico anteriores.
- `Cliente > Assistencia tecnica / OS`: receba upgrade de RAM, diagnostico,
  troca de fonte, limpeza ou manutencao preventiva. Diagnostique na bancada,
  aprove no balcao, execute com pecas/insumos, teste e entregue no balcao.
  Cada tipo tem um cenario inicial representativo, nao diagnostico universal.
  Pecas removidas pertencem ao cliente; nunca entram como estoque gratuito.
  Cancelar antes do consumo nao gera receita; depois da autorizacao a paciencia
  do cliente fica pausada durante a execucao/retirada.
- `Financas > Funcionarios`: seis candidatos. Lia/Rui/Sol custam R$ 50/80/40 por dia;
  Nina/Ivo/Luz, especialistas liberados no nivel 2, custam R$ 100/110/75.
  O contrato so e efetivado por sua escolha. Caixa aprova OS e
  recebe vendas prontas; tecnico diagnostica/executa/testa OS; estoquista recebe
  entregas. Montador instala pecas do estoque, conecta e testa com as mesmas regras
  manuais; nao compra nem cria pecas. Se o PC parcial nao puder atender ao pedido,
  aguarda revisao manual, sem desmontar componentes por conta propria.
  Atribuicoes sao flexiveis, sem dois ocupantes da mesma funcao.
  Habilidade por funcao cresce a cada cinco tarefas e reduz o intervalo de acao.
  Tecnico e montador esperam quando o painel manual de montagem/OS esta aberto.
  Salario e proporcional ao tempo contratado, arredondado para real inteiro no
  fechamento; demissao nao apaga valores devidos. Sem posto/insumo a tarefa
  aguarda, mas o salario continua devido. Tarefas fora da camera sao simuladas
  com os postos salvos; dentro, exigem funcionario em posicao livre no posto.

## Reforma, imovel maior e ambiente

- Em `Loja > Ampliar planta`, cada imovel admite duas ampliacoes instantaneas:
  R$ 1800 e R$ 3600. A planta inicial passa de 6 x 5 para 8 x 6 e 10 x 7;
  moveis continuam no lugar, entrada/camera acompanham os modulos novos.
  Novas rotas sao verificadas; falha de gravacao desfaz compra e planta.
- A divisoria reutiliza as duas paredes diagonais aprovadas, com colisao na
  base projetada e duas vistas reais. Use `Girar`; deixe vaos para circulacao.
  A porta interna custa R$ 180 e reutiliza esses paineis. A abre/fecha uma porta
  proxima; ao selecionar uma porta, a barra oferece `Porta`. Aberta libera passagem;
  fechar sobre ator ou bloquear rotas e recusado. Estado aberto persiste.
  E uma representacao provisoria, sem nova arte/animacao nem editor de acabamento.
- Nas **Salas comerciais**, no extremo direito do bairro, A abre a compra do
  imovel de 10 x 8 por R$ 8500. Ele vem vazio, aceita ampliacoes e tem
  entrada/saida pela fachada existente. Cada propriedade preserva seus moveis.
  Equipe, estoque e atendimento pertencem a **uma unidade ativa por vez**,
  restaurada ao reabrir. Termine atendimentos/fila antes de trocar de unidade.
  O custo diario fixo de operacao nao multiplica por imovel adquirido.
- O exterior tem dia/noite e chuva procedural, sem PNGs novos; interior e HUD
  permanecem iluminados. Previsao/evento sao derivados do calendario salvo.
  Feira semanal aumenta chegadas; dia tranquilo/chuva reduzem a demanda.
  Ainda nao ha guarda-chuvas, transito ou eventos narrativos completos.
- A [suite de simulacao](tests/test_simulation.gd) cobre estes blocos, persistencia,
  salarios/dividas, falhas de escrita e integracao real de OS/equipe/imoveis.
  Android e desempenho em aparelho continuam pendentes.

## Campanha, tecnologia e camera

- `Financas` mostra margem, ponto de equilibrio e reserva de capital. O ensaio
  deterministico de sete dias compra/recebe/monta/vende dois PCs-base por dia,
  sem injetar estoque ou caixa: custo R$ 1780, venda R$ 2450, margem R$ 670.
  Com Lia/Rui/Sol, despesas sao R$ 290/dia; lucro R$ 1050/dia.
  Caixa inicial R$ 6500 chega a R$ 13850. E uma campanha economica de referencia,
  nao garantia de demanda nem validacao de todas as estrategias.
- Nivel 2: reputacao >=45 e dois PCs entregues ou receita >=R$ 5000.
  Nivel 3: reputacao >=60 e cinco PCs ou receita >=R$ 15000.
  Cada limiar de receita/PCs exige tambem a reputacao indicada.
  Desbloqueios sao permanentes; `Estoque` permite escolher fornecedor do nivel.
  Pedidos de jogos e pecas avancadas respeitam o nivel no controlador e na UI.
  Saves antigos mantem pecas adquiridas/recompraveis, pedidos de jogos existentes,
  funcionarios e propriedades; nao ha confisco nem reinicio.
- Arraste em area livre para mover a camera; dois dedos fazem pinca.
  No PC, use arraste com botao direito, roda ou gestos do trackpad.
  D-pad e edicao de moveis mantem seus dedos; paineis bloqueiam gestos do mundo.
  `Financas > Recentralizar camera` restaura enquadramento e seguimento externo.
  Zoom vai de 0,75 a 4 vezes o enquadramento-base.

## Evolucao da campanha e mundo vivo

- `Financas > Guia, objetivos, aparencia e acabamentos`: guia opcional de seis
  passos e seis conquistas persistentes, sem bloquear o jogo livre nem criar dinheiro.
- Novas pecas nos dias 8/14/21/28 e dois jogos nos dias 14/28. Data, nivel e
  fornecedor sao exigidos; aquisicoes antigas continuam acessiveis.
- Assistencia inclui memoria, superaquecimento e SSD degradado. Ensaios de
  memoria/carga/disco produzem evidencias simuladas; diagnostico exige o ensaio
  correspondente, e cada reparo usa sua propria peca e teste final.
- No guia, dentro da loja, edite piso por coordenadas U/V e setores
  Vendas/Oficina/Estoque. Reutiliza tres pisos aprovados: trocar variante custa
  R$ 20 por modulo; setor e gratuito. Sem alterar colisoes. Persiste por imovel.
- Nove aparencias opcionais de acessorios nativos, salvas por partida.
  Clientes e funcionarios tem variacoes estaveis. Corpo/roupa/cabelo modulares
  finais continuam pendentes; os sprites aprovados nao foram substituidos.
- Pedestres percorrem calcadas/travessias; visitas a loja alimentam o atendimento
  real quando ha capacidade/estoque. Veiculos circulam nas pistas; clima/eventos
  influenciam o movimento. Limites: 32 pedestres e oito veiculos. Funcionarios
  percorrem rotas ate seus postos. Nao ha avoidance dinamico completo.
- Pausar o aplicativo interrompe simulacao e salva. Reabrir nao avanca tempo
  offline. HUD/controles consideram safe area; notch real e paineis em aparelhos
  variados ainda precisam de homologacao. O guia mostra FPS/memoria local.
- Ensaio automatizado de 56 dias: 112 PCs com compras/recebimentos reais,
  despesas, especialistas, compra do segundo imovel e duas ampliacoes com lucro
  acumulado. Cenario sem vendas acumula R$ 6720 de divida. Nao garante demanda
  ou lucro em todas as estrategias.

Validacao desktop: **3090 verificacoes headless, 1419 renderizadas e 10 testes
de imagens**, sem falhas; 13 capturas. Repeticoes entre modos nao sao requisitos
unicos. Os 142 PNGs originais mantem os hashes. Android, bateria e release
assinado ainda nao foram testados; nao foi gerado APK nesta etapa.

### Integracao continua e release

A falha do Actions #67 foi no teste de drag-and-drop: o cartao estava fora da
area visivel do scroll. O teste agora rola a linha e confirma que os centros
estao visiveis antes do arraste real; nao ignora instalacao/compatibilidade.

PRs executam [.github/workflows/validate-game.yml](.github/workflows/validate-game.yml),
com importacao, imagens e oito suites, **sem gerar APK**. A exportacao automatica
de [.github/workflows/build-android.yml](.github/workflows/build-android.yml) ocorre
somente em pushes para `main`; feature branches nao geram APK automaticamente.
Disparo manual permite `debug` ou `release`. Release exige os secrets
`ANDROID_RELEASE_KEYSTORE_B64`, `ANDROID_RELEASE_ALIAS` e
`ANDROID_RELEASE_PASSWORD`; senha da chave e do keystore devem ser iguais para
o exportador Godot. Nenhum segredo deve ser commitado. A configuracao nao
equivale a assinatura, instalacao ou publicacao homologadas.

No bairro, caminhe nas calcadas e atravesse pelas faixas brancas. O asfalto fora
das travessias, o predio, banco, poste, vasos e lixeira bloqueiam os pes do personagem.
Ha tres veiculos decorativos parados, alem do transito animado. As outras lojas nao funcionam
internamente, exceto o imovel compravel das Salas comerciais.

## O que foi integrado

- Rua reta em um mapa de 72 x 28 modulos, com duas pistas de sentidos opostos,
  oito modulos de largura total e tres travessias completas. Mais de 1100
  celulas conectadas sao alcancaveis desde a loja. As calcadas continuam ate
  as extremidades, com espaco reservado para futuros estabelecimentos.
  O asfalto e uma superficie continua; as marcacoes sao desenhadas separadamente,
  sem contornos de tiles. O mundo vivo acrescenta circulacao limitada nas pistas.
- Cafeteria decorativa ao lado da PC Store, com colisao e aviso ao interagir:
  nao possui interior, atendimento ou compra. A altura da porta foi ajustada
  para diferir menos de 3 pixels da porta da PC Store (aproximadamente 132 pixels).
  Seu PNG passou por limpeza de alfa e adaptacao geometrica, nao redesenho.
- Cinco fachadas comerciais e 36 objetos urbanos adicionais no mapa principal:
  vegetacao, bancos, postes, lixeiras, mesas, cadeiras, detalhes de comercio,
  bicicleta e tres veiculos parados. Escalas de objetos pequenos foram ajustadas
  em relacao ao personagem; colisoes aproximam apenas a base, nao a copa/telhado.
  Os 50 sprites originais do kit v2 foram importados sem modificar os PNGs;
  os estados alternativos e orientacoes nao utilizados ficam disponiveis no catalogo.
  O acabamento e provisorio e mais simples que o da PC Store.
- Fachada com telhado, banco e poste recortados da imagem aprovada. A imagem
  original permanece intacta. A profundidade da fachada acompanha sua base,
  evitando desenhar o jogador sobre o telhado ao passar atras.
- Transicao com movimento bloqueado; troca do cenario ocorre com a tela escura.
- Interior construido com o kit modular: 30 pisos, 11 paredes, canto e soleira.
  Sala inicial 6 x 5; dimensoes e geometria derivadas do cadastro, sem esticar uma imagem.
  A camera interna enquadra a sala inteira, enquanto a externa acompanha o jogador.
- Nova partida inclui balcao, bancada, mesa com notebook e prateleira.
  Moveis iniciais sao independentes, editaveis e salvos; nao reaparecem depois de vendidos.
- Protagonista e cliente com quadros reais de idle/caminhada em quatro direcoes.
  Os outros dois personagens tambem foram importados, sem adicionar funcionarios automaticamente.
  A escala usa 112 pixels de altura visivel no mundo (medida no idle), nao
  o tamanho transparente do PNG. Personagens compartilham a escala fisica
  entre interior e exterior; o pivo continua nos pes.
- Moveis com pivo na base, selecao por pixel,
  arraste por mouse/toque, grade invisivel, profundidade por Y e colisao.
- Catalogo de recursos/precos e persistencia por ID de imovel.

**Limitacoes:** os 11 moveis novos possuem uma unica vista: girar informa a falta
de arte e nao altera a colisao nem simula rotacao. O balcao antigo de quatro vistas
continua compravel e compativel com saves anteriores. A animacao da porta usa
recortes deformados da propria fachada, nao frames finais de um artista.
Notebook, balcao e bancada agora abrem as atividades descritas acima. Seus
PNGs compostos continuam intactos; nao ha encaixe visual de objetos sobre mesas
nem encaixe grafico de hardware dentro do gabinete.
Veja [os prompts de arte](ARTE_PENDENTE.md).

O giro da colisao isometrica respeita a projecao 2:1, sem trocar diretamente
largura e altura da tela. A base do balcao PC Store permanece 128 x 64 nas quatro
orientacoes; PNGs, pivos e escala 0,65 foram preservados. Isso nao aprova a
coerencia artistica das vistas. A [ferramenta de medicao](tools/medir_balcao.gd)
registra colisao, giro, cancelamento e recarga com saves isolados; veja as
[evidencias e instrucoes](docs/auditoria/03_AUDITORIA_SPRITES.md).

## Saves

- Arquivo: `user://pixel_pc_tycoon_v1.json` (nome mantido), agora com `versao: 2`,
  dinheiro, `imoveis` e o bloco opcional `comercio` (versao interna 1).
- Slot 1 reutiliza o arquivo original, sem copiar o progresso para outras partidas.
  Slots 2 e 3 usam os sufixos `.slot2` e `.slot3`, cada um com seus proprios backups.
  Somente o slot 1 importa saves legados.
- A escolha do slot fica em `.slots.cfg`, com escrita temporaria e backup.
  Se essa selecao estiver invalida, o jogo informa o problema e permite escolher
  um slot pelo Menu; nao sobrescreve os saves para resolver a selecao.
- Manual e autosave escrevem o mesmo arquivo do slot ativo. Nao sao dois pontos
  de restauracao separados. Comercio persiste estoque, entregas, caixa,
  cliente ativo, pecas reservadas, cabos, teste e configuracoes entregues.
- Cada imovel possui `moveis` e `guardados`: `id`, `posicao: [x,y]` e `angulo`.
- Escrita temporaria e backup `.bak`. Erros sao mostrados no HUD e no log.
- Se o principal estiver invalido ou ausente, o jogo tenta recuperar o `.bak`
  validado antes de procurar um save legado. O HUD e o log informam a recuperacao.
- O principal danificado fica preservado em `.corrompido`, com sufixos numericos
  se o nome ja existir. O backup e copiado e validado em `.recuperacao.tmp` antes
  de restaurar o principal; um autosave posterior nao substitui o backup por lixo.
- Sem copia valida ou se a restauracao falhar, a partida continua bloqueada,
  com erro explicito e arquivos preservados. Nao inicia uma partida nova por cima
  dos arquivos danificados. Pelo Menu, outro slot valido continua acessivel.
- Saves v1 e v042 preservam saldo e moveis. Como a planta mudou, moveis antigos
  ficam guardados; use `Loja > Recuperar` para posiciona-los sem pagar novamente.
  Cancelar a recuperacao mantem o objeto guardado. O aviso aparece ao entrar.
  Antes da primeira gravacao, a origem e copiada para `.pre_modular`, sem sobrescrever
  esse backup nas gravacoes seguintes. O arquivo legado nao e apagado.
- Uma compra em previa nao e salva nem cobrada. Edicoes nao confirmadas
  salvam a ultima posicao/orientacao confirmada.
- No Windows, `user://` normalmente fica em
  `%APPDATA%\Godot\app_userdata\Pixel PC Tycoon - Cena V0.4.8`.

## Validacao

Com o executavel Godot disponivel no PATH:

```powershell
godot --headless --path . --editor --import --quit
godot --headless --path . --quit-after 30
godot --headless --path . --script .\tests\test_game.gd
godot --headless --path . --script .\tests\test_save_recovery.gd
godot --headless --path . --script .\tests\test_progression.gd
godot --headless --path . --script .\tests\test_simulation.gd
godot --headless --path . --script .\tests\test_campaign.gd
```

Validacao atual, em copia isolada do projeto:
701 verificacoes de campanha, 448 de simulacao, 612 de gameplay, 257 de progressao e 162 de
recuperacao, todas headless e sem falhas, mais 10 testes de assets.
Com renderizacao nesta etapa: 705 de campanha e 262 de progressao, incluindo nove
capturas no conjunto. Importacao sem erros de parsing/carregamento;
SHA-256 dos 142 PNGs originais inalterado. O workflow inclui a nova suite,
mas nao foi acionado para produzir APK nesta entrega.

A suite `test_campaign.gd` cobre sete dias economicamente sustentaveis, retorno
de clientes no controlador, desbloqueios/legados, quatro OS com reservas/prioridade,
rollback e recuperacao de perfis/reservas/prioridades/nivel corrompidos,
montador para os 20 jogos, pinca/arraste reais, limites de zoom e portas
com colisao, edicao e restauracao. Os cenarios renderizados repetem verificacoes
headless; essas contagens nao sao numeros de requisitos unicos.

A suite `test_progression.gd` cobre slots, migracao, falhas de selecao/escrita,
corredor bloqueado sem sobreposicao, rotas do cliente, entrega de fornecedor,
estoque, livro-caixa, pagamento unico, compatibilidade e montagem parcial.
Valida drag-and-drop real dentro da janela, boot, entrega e recuperacao comercial.
Foram aprovadas 257 verificacoes headless e 262 renderizadas com cinco capturas.
As suites existentes passaram com 611 e 162 verificacoes. O workflow foi
atualizado, mas nao executado remotamente; Android continua sem aceite.

Os testes criam e removem seus proprios saves; nao usam o progresso do jogador.
Para QA de importacao/inicializacao, prefira uma copia isolada do projeto.
Verifica entrada/saida, piso, rota do NPC, controles, compra, colisao, giro,
cancelamento, venda, reinicio e migracao. Nao substitui teste em aparelho Android.
Tambem verifica sala modular em dois tamanhos, layout inicial, enquadramento,
sprites direcionais e recuperacao de moveis de saves antigos.
A suite `test_save_recovery.gd` verifica principal valido, corrupcao de JSON e
estrutura, backup ausente/invalido, migracao v1, preservacao sem sobrescrita,
falha de restauracao, autosave posterior e mensagens/bloqueio na cena principal.
Os avisos de recuperacao sao esperados; os erros terminais esperados sao
suprimidos apenas durante as chamadas negativas do teste e conferidos pelo HUD
e por `ultimo_erro`. Os erros reais de script continuam reprovando a validacao.
O bairro tem testes de proporcao personagem/banco/portas, conectividade das
tres travessias e das extremidades das calcadas, limites, obstaculos e movimento
bloqueado fora das faixas. O teste renderizado tambem amostra os pixels das
listras e dos intervalos da faixa de pedestres.
O teste carrega a cena principal configurada no projeto (a mesma do F5), com
save isolado. Confere cinco lojas e 36 objetos novos, acesso a cada fachada,
colisoes, profundidade e limites dos recortes. Nao carrega o save real.
Para capturas reais, defina `PIXEL_TEST_CAPTURE_DIR` para uma pasta existente
e execute o teste **sem** `--headless`.

A Action [build-android.yml](.github/workflows/build-android.yml) importa,
executa os testes e exporta um APK debug. Um build antigo bem-sucedido nao
valida alteracoes locais ainda nao enviadas.

## Recursos e desenvolvimento

- [RuaComercial.gd](scripts/RuaComercial.gd): fluxo, interface e controles.
- [CatalogoImoveis.gd](scripts/Imoveis/CatalogoImoveis.gd): cenarios e geometria por imovel.
- [GerenciadorImoveis.gd](scripts/Imoveis/GerenciadorImoveis.gd): estados e armazenamento.
- [CatalogoSprites.gd](scripts/Imoveis/CatalogoSprites.gd): precos, texturas, pivos e dimensoes.
- [MovelIsometrico.gd](scripts/Moveis/MovelIsometrico.gd): visual, orientacao e edicao.
- [PortaLoja.gd](scripts/PortaLoja.gd): animacao provisoria extraida da fachada.
- [InteriorModular.gd](scripts/Imoveis/InteriorModular.gd): montagem das pecas e geometria da sala.
- [PersonagemAnimado.gd](scripts/PersonagemAnimado.gd): quadros de caminhada e idle.
- [BairroComercial.gd](scripts/BairroComercial.gd): mapa, travessias, recortes e colisao externa.
- [VizinhancaComercial.gd](scripts/VizinhancaComercial.gd): lojas, decoracao, bases de colisao e avisos.
- [CatalogoVizinhanca.gd](scripts/CatalogoVizinhanca.gd): catalogo gerado com texturas e pivos do kit v2.

Para reimportar os novos pacotes locais (requer Pillow):

```powershell
python .\tools\import_modular_assets.py "C:\Users\RILTON\Downloads"
python .\tests\test_assets.py
```

O importador espera o kit `Pixel_PC_Tycoon_Kit_Modular_Cenario_v1` e os ZIPs
`05_personagens.zip` e `03_moveis_e_equipamentos.zip`. Copia as pecas do kit
sem alteracao; remove fragmentos desconectados dos sprites e acrescenta margens,
sem redesenhar nem sobrescrever os pacotes originais. Personagens usam canvas
160 x 240 e pivo (80,232). O teste de imagens verifica alfa, medidas, margens
e ausencia de frestas internas em pisos 6 x 5 e 8 x 7.

Para reimportar o kit externo:

```powershell
python .\tools\import_neighborhood.py "C:\Users\RILTON\Downloads\Pixel_PC_Tycoon_Kit_Bairro_Comercial_v1.zip"
```

Para reimportar a vizinhanca comercial v2:

```powershell
python .\tools\import_vizinhanca.py "C:\Users\RILTON\Downloads\Pixel_PC_Tycoon_Vizinhanca_Comercial_v2.zip"
```

O importador valida os 50 PNGs e o manifesto antes da copia, preserva as imagens
e documentacao em `Assets/Cenarios/Vizinhanca`, e gera `CatalogoVizinhanca.gd`.
Nao editar o catalogo gerado manualmente. Os pontos de base dos predios foram
ajustados ao kit geometrico v2; outro pacote exige rever esses pontos e colisoes.
A composicao e as escalas no jogo ficam em `VizinhancaComercial.gd`.

Os 20 tiles anteriores ficam preservados em `Assets/Cenarios/Bairro`, mas a
rua reta usa materiais continuos e marcacoes geometricas. Banco/poste/PC Store
continuam sendo mascaras da arte existente, nao redesenhos. Os testes verificam
que seus pixels RGB continuam identicos a fonte.

Para reproduzir os materiais novos e a adaptacao da cafeteria (requer Pillow):

```powershell
python .\tools\prepare_commercial_street.py .\Assets\Cenarios\Bairro\Fontes\cafeteria_original.png .\Assets\Cenarios\Bairro\Fontes\asfalto_original.png
python .\tests\test_assets.py
```

O preparador preserva as fontes e registra o hash, a transformacao e os pontos
de referencia em `cafeteria.json`. Os pontos pertencem especificamente a imagem
aprovada de 1152 x 768; outra fachada exige medir novos pontos, nao apenas trocar
o arquivo. A transparencia residual e removida sem alterar o original.
O asfalto de 256 x 256 e repetido por reflexao em 512 x 512 para igualar suas bordas;
a calcada e preparada com textura discreta e juntas, sem placas opacas por sprite.

A projecao externa usa vetores `(64,20)` e `(-64,32)`, proximos da fachada original,
em vez de impor o grid interno 2:1 a uma arte com outra perspectiva. A cafeteria
foi adaptada a esses vetores com cisalhamento vertical e escala; isso nao equivale
a uma nova vista desenhada pelo artista. O interior conserva `(64,32)` e `(-64,32)`.
Colisao, piso, travessias e limites externos compartilham a mesma transformacao.
Os saves internos e a escala dos personagens nao foram alterados.

O preparador de arte requer Pillow e recebe a pasta do pacote original:

```powershell
python .\tools\prepare_assets.py "C:\caminho\Pixel_PC_Tycoon_Prompt_e_Imagens"
```

Ele copia a fachada e remove componentes desconectados dos recortes, normalizando
os PNGs em 256 x 256 com pivo (128,248). Nao redesenha a arte e nao modifica o pacote.
Nao execute sobre sprites finais de um artista sem revisar as transformacoes.

Versione os metadados `.import` e `.gd.uid`; nao versione `.godot/`, APKs nem chaves.
No clone Windows atual, apenas o arquivo legado com nome terminado em ponto
(`Assets/Personagens/README.md.`) foi excluido por sparse checkout.
