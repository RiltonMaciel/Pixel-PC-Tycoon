# Arte pendente - prompts para a outra IA

## Prioridade vigente: carros, fachadas e proporcoes

Foi autorizada a criacao de novos sprites respeitando o traco do jogo.
A primeira entrega e uma **previa reversivel, pendente de aprovacao visual**:
carro azul e picape vermelha em quatro vistas cada, mercadinho e acabamento
do passeio. Acesso em `Financas > Previa visual do bairro`.

[Recursos](Assets/Cenarios/PreviaVisual/) separados dos originais; oito vistas
renderizadas a partir de geometria, nao rotacoes de PNG. Pivos/landmarks mantem
o footprint existente; veiculos novos parados/em movimento usam escala comum.
O exterior continua nos eixos (64,20)/(-64,32), nao no grid interno 2:1.

O [gerador](tools/create_visual_preview.py) produz amostras procedurais, sem
modelo generativo externo. **Nao equivale ao acabamento da referencia enviada**.
Ainda sao necessarios refinamento artistico/aprovacao para substituir o padrao
e ampliar farmacia, roupas, restaurante, predio comercial e furgao.
Preservados os 142 PNGs aprovados. As 33 vistas de moveis, portas definitivas,
gabinete final e corpo/roupa/cabelo modulares continuam pendentes.
As secoes anteriores abaixo sao historicas; trafego/dia-noite ja foram
integrados posteriormente e nao sao ausencia atual.

## Direcao atual: interior modular

O exterior foi reorganizado como rua reta com duas pistas, calcadas largas e
tres travessias. Os tiles do bairro v1 foram preservados, mas o piso atual usa
materiais continuos, sem contornos de losangos no asfalto. Marcacoes e bordas
sao geometricas: nao e necessario pedir uma nova rua inteira a IA.

A cafeteria enviada foi integrada como fachada decorativa, sem interior. A fonte
com transparencia real foi preservada; uma copia recebeu limpeza de residuos e
correcao geometrica para acompanhar a rua. E uma adaptacao provisoria, nao uma
nova perspectiva redesenhada. Sua porta tem altura equivalente a da PC Store.
O exterior usa eixos (64,20)/(-64,32), diferentes do grid interno 2:1.

O pacote Vizinhanca Comercial v2 foi aprovado como arte provisoria e integrado
ao mapa principal: mercadinho, farmacia, loja de roupas, restaurante e salas
comerciais, mais vegetacao, mobiliario e tres veiculos parados. Os 50 PNGs
foram preservados sem alteracao; escala, posicionamento e colisoes sao do jogo.
As fachadas geometricas tem acabamento mais simples que a PC Store; uma futura
revisao artistica deve manter os pivos e a perspectiva e aumentar a variedade,
sem incorporar ruas, personagens ou decoracao aos predios.
As orientacoes extras dos carros e estados alternativos foram importados,
mas nao ha transito, ciclo noturno ou novas lojas funcionais nesta etapa.

O kit modular v1, os 36 quadros de personagens e os 11 moveis/equipamentos
foram integrados. Nao e necessario gerar outro interior, piso ou personagem
para testar esta etapa. A loja usa as pecas do kit, nao uma imagem completa.

Os moveis novos tem uma vista cada. Para permitir giro, faltam as outras
orientacoes do MESMO objeto, na projecao 2:1 do kit e com escala/pivo constantes.
Use cada PNG de `Assets/Moveis/Modulares/` e o kit como referencia, nao o
balcao RGB antigo. As vistas precisam ser revisadas antes de definir colisao.

A animacao de porta externa ainda e provisoria. O pedido da secao 2 continua
aplicavel. Os recortes de alguns personagens tinham bordas apertadas; as margens
foram normalizadas, mas isso nao reconstroi pixels ausentes no original.

## Prompts anteriores (historico)

O pedido de balcao abaixo se refere ao modelo antigo, preservado para compatibilidade.
Nao o use para substituir os moveis novos sem decidir explicitamente por esse visual.

## 1. Balcao: quatro orientacoes isometricas coerentes

**Anexar a IA:** a prancha original `02_Balcao_4_Angulos_Arte_Referencia.png`
e o interior `Assets/Cenarios/Loja_Base_Aprovada.png`.
Nao usar apenas os nomes dos arquivos como referencia: anexar as imagens.

### Prompt para copiar

Estou criando Pixel PC Tycoon, jogo Android vertical em pixel art isometrica.
Preciso finalizar um unico balcao de atendimento PC STORE em quatro orientacoes,
preservando fielmente a identidade da prancha anexada. Nao invente outro movel.

ENTREGA:
- Quatro PNGs separados: 0.png, 90.png, 180.png, 270.png.
- Canvas identico de 512 x 512 pixels em todos.
- Fundo realmente transparente, canal alfa. Nenhum quadriculado, cor solida,
  cenario, legenda, numero ou moldura desenhados no fundo.
- Ocupacao aproximada de 400 pixels de largura na vista mais larga, sem cortar
  planta, cadeira, monitor, base ou sombra. Margem minima de 24 pixels.
- Fornecer tambem uma prancha de preview em fundo cinza escuro, separada dos PNGs.

CAMERA E ORIENTACAO:
- Camera ortografica fixa em vista isometrica, olhando de cima, compativel com
  o piso do interior anexado. Arestas horizontais do mundo projetadas nas duas
  diagonais do piso, aproximadamente +30 e -30 graus. Sem ponto de fuga.
- E o movel que gira em torno do seu eixo vertical, nunca a camera ou o arquivo.
- 0 graus: frente do atendimento visivel, com painel PC STORE; lateral direita
  e tampo visiveis; a cadeira fica atras.
- 90 graus: gire esse mesmo objeto um quarto de volta no sentido horario,
  mantendo a camera fixa; mostre a lateral correspondente e parte do verso.
- 180 graus: verso de trabalho visivel, com gavetas, portas, teclado e cadeira;
  o painel frontal nao deve reaparecer no verso.
- 270 graus: ultimo quarto de volta, mostrando o lado oposto ao de 90 graus.
- Nao misture vista frontal ortografica com vista isometrica. Nao espelhe texto.
- Antes da finalizacao, apresente um esquema simples identificando frente,
  verso, esquerda e direita em cada orientacao para verificarmos a continuidade.

DESENHO E MATERIAIS:
- Balcao comprido com tampo cinza, estrutura escura e ripas verticais de madeira
  quente numa extremidade.
- Painel frontal azul-escuro com simbolo de monitor e texto PC STORE branco,
  exatamente nessa ordem e legivel; faixa azul/ciano luminosa sob o tampo.
- Faixa luminosa alaranjada junto ao rodape, preservando a referencia.
- Modulo-vitrine de vidro na outra extremidade, com prateleiras e pequenas caixas
  de componentes, incluindo ventoinhas e perifericos.
- Sobre o tampo: monitor preto, terminal de pagamento, pequeno expositor,
  fone com detalhes vermelhos, placa vertical com icone de monitor e vaso
  branco com planta verde. Preserve a posicao relativa de cada objeto nas vistas.
- Atras: cadeira azul de escritorio e espaco de trabalho. A cadeira faz parte
  deste sprite composto e tambem gira junto com o conjunto.
- Verso com portas e gavetas coerentes com a geometria; nao acrescentar outra
  vitrine, planta ou cadeira quando mudar a orientacao.

CONSISTENCIA TECNICA:
- Mesmas dimensoes no mundo, proporcoes, detalhes e escala nos quatro arquivos.
- A base deve assentar no mesmo plano. O centro da base fisica deve ocupar
  a mesma coordenada (256,400) nos quatro canvases. Informe a caixa ocupada
  pelos pixels visiveis de cada vista; nao estique para igualar suas larguras.
- Luz fixa vinda do alto/esquerda da tela, nao girando junto com o movel.
- Sombra curta e suave apenas junto a base, com alfa; nada de placa opaca.
- Bordas de pixel art limpas e paleta consistente; sem borrado, render 3D
  fotorrealista, fragmentos soltos ou restos de outros objetos.
- Se nao conseguir exportar PNG com alfa real, avise explicitamente.

## 2. Porta da fachada: frames finais de abertura

**Anexar a IA:** `01_PC_Store_Exterior_Com_Telhado.png`.
O jogo usa hoje uma animacao provisoria por recortes dessa imagem.

### Prompt para copiar

Preciso animar SOMENTE a porta de vidro de duas folhas da PC STORE da imagem
anexada. Preserve a fachada aprovada: nao redesenhe predio, placa, vitrine,
telhado, calcada, vasos ou iluminacao. A camera permanece fixa.

Crie uma sequencia de abertura de porta de duas folhas, com dobradicas nas
laterais externas e folhas abrindo para dentro da loja. O centro deve liberar
uma passagem; nao invente uma porta frontal reta sem a perspectiva da fachada.

ENTREGA:
- 7 PNGs RGBA individuais: porta_00.png ate porta_06.png.
- Respectivamente fechada, 15, 30, 45, 60, 75 e 90 graus de abertura aproximada.
  O jogo reproduzira esses mesmos frames ao contrario para fechar.
- Canvas de 1536 x 1024, exatamente igual ao exterior anexado.
- Apenas os pixels da porta e seu vao interno; todo o resto transparente.
- Manter a porta na posicao original do cenario, aproximadamente entre x=580
  e x=750, y=535 e y=770. Esses valores sao referencia: respeite os contornos
  exatos da imagem anexada, inclusive a inclinacao do topo e da soleira.
- Entregar uma preview separada dos frames sobre a fachada original.

APARENCIA:
- Duas folhas de vidro, caixilhos azul-escuros, puxadores metalicos verticais,
  reflexos discretos e luz interior quente, seguindo a imagem.
- Em porta fechada, o encaixe deve ficar visualmente identico ao original.
- Ao abrir, mostrar a espessura das folhas e o vao escuro com sugestao discreta
  de piso interno; nao pintar um balcao ou personagem fixo nessa passagem.
- O vao precisa cobrir os pixels da porta fechada que permanecem no fundo:
  use uma regiao opaca dentro da abertura, nao transparencia que revele a
  porta antiga por baixo. Transparencia apenas fora da regiao da porta.
- Nao mover dobradicas, soleira, camera ou enquadramento entre frames.
- Nenhum fundo quadriculado desenhado, borda branca, texto extra, sombra externa
  gigante ou elemento da fachada cortado.

## Como entregar

Envie os PNGs originais, preferencialmente em ZIP, junto com a preview.
Nao envie apenas um screenshot da prancha. Os arquivos serao inspecionados
quanto a alfa, recorte, escala, alinhamento e perspectiva antes da integracao.

Os personagens atuais sao temporarios; um pacote de animacao do jogador e
cliente pode ser especificado depois, sem bloquear a validacao desta etapa.
