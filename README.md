# Pixel-PC-Tycoon

Prototipo Android em Godot **4.4.1 Standard**, GDScript e pixel art.
Resolucao de referencia: 432 x 768, retrato. Nao usa .NET nem HTML.

## Abrir e jogar

1. Importe `project.godot` no Godot 4.4.1.
2. Pressione F5. Nao e necessario instalar o SDK Android para jogar no PC.
3. Use as setas ou o D-pad (mouse/toque). Clique em A ou pressione Enter para interagir.
4. Perto da porta da PC Store, A entra. No interior, aproxime-se de `SAIDA [A]`.
5. Dentro da loja, `Loja` abre o catalogo com 11 moveis/equipamentos. Toque num item para comprar.
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

Montagem, Estoque e atendimento comercial continuam pendentes; o NPC apenas conversa.
As imagens legadas foram preservadas.

No bairro, caminhe nas calcadas e atravesse pelas faixas brancas. O asfalto fora
das travessias, o predio, banco, poste, vasos e lixeira bloqueiam os pes do personagem.
Ha tres veiculos decorativos parados, sem transito. As outras lojas nao funcionam
internamente: A nas fachadas informa que o interior ainda esta indisponivel.

## O que foi integrado

- Rua reta em um mapa de 72 x 28 modulos, com duas pistas de sentidos opostos,
  oito modulos de largura total e tres travessias completas. Mais de 1100
  celulas conectadas sao alcancaveis desde a loja. As calcadas continuam ate
  as extremidades, com espaco reservado para futuros estabelecimentos.
  O asfalto e uma superficie continua; as marcacoes sao desenhadas separadamente,
  sem contornos de tiles. Ainda nao ha simulacao de transito.
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
continua disponivel para saves anteriores. A animacao da porta usa
recortes deformados da propria fachada, nao frames finais de um artista.
Os equipamentos compostos ainda sao decorativos: esta etapa nao implementa montagem,
uso do notebook, encaixe de objetos sobre mesas nem expansao compravel.
Veja [os prompts de arte](ARTE_PENDENTE.md).

## Saves

- Arquivo: `user://pixel_pc_tycoon_v1.json` (nome mantido), agora com `versao: 2`,
  dinheiro e `imoveis`.
- Cada imovel possui `moveis` e `guardados`: `id`, `posicao: [x,y]` e `angulo`.
- Escrita temporaria e backup `.bak`. Erros sao mostrados no HUD e no log.
- Save invalido bloqueia a partida para nao sobrescrever o original.
  Preserve o arquivo e restaure um backup valido antes de continuar.
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
```

O teste cria e remove seus proprios saves; nao usa o progresso do jogador.
Verifica entrada/saida, piso, rota do NPC, controles, compra, colisao, giro,
cancelamento, venda, reinicio e migracao. Nao substitui teste em aparelho Android.
Tambem verifica sala modular em dois tamanhos, layout inicial, enquadramento,
sprites direcionais e recuperacao de moveis de saves antigos.
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
