# 03 - Auditoria de sprites e recursos visuais

## Integração mais recente: porta interna e interface da oficina

A porta interna reaproveita os mesmos painéis diagonais aprovados da divisória:
duas vistas reais, pivô `(64,160)`, sem gerar PNG nem rotacionar imagem para
inventar vista. Fechada mostra o painel; aberta esconde o painel, mostra rótulo
e uma linha nativa indicando o vão. É representação provisória, não arte final
de porta nem animação articulada.

Edição mostra o painel fantasma; confirmar/cancelar restaura a visibilidade
coerente com o estado aberto. O vão continua reservado contra outros móveis,
mas deixa passar atores. Capturas desktop verificaram OS guardadas, PC montado
por funcionário, finanças e porta aberta. As 33 vistas faltantes e o hardware
final continuam pendentes de aprovação. Nenhum recurso aprovado foi substituído.

## Integração visual dos seis blocos adicionais

- Nenhum PNG novo/substituído. Equipe reutiliza o personagem técnico aprovado;
  nomes, contratos, requisitos, encaixes e relatórios usam UI esquemática.
- A divisória usa os PNGs já aprovados `parede_diagonal_direita` e
  `parede_diagonal_esquerda`, 128×192, pivô `(64,160)`. São duas vistas reais,
  não uma rotação de imagem. Sua colisão projeta uma faixa de 1×0,12 módulo nos
  eixos `(64,32)`/`(-64,32)`, acompanhando a base da parede em cada vista.
- Ampliações reutilizam pisos/paredes modulares, sem esticar o cenário.
  O imóvel maior abre pela fachada existente das Salas comerciais.
- Noite usa modulação do canvas do mundo, sem escurecer HUD/interior.
  Chuva usa traços procedurais; não cria/substitui sprites.
- Capturas desktop verificaram assistência, equipe, divisória, ampliação,
  imóvel maior e chuva noturna. Isso não é aprovação artística ou teste Android.

Continuam faltando as 33 vistas dos 11 móveis originais, hardware final para
montagem gráfica, partes de personagens, guarda-chuvas e portas internas.
Os inventários e medições históricos abaixo não foram substituídos.

Base: `b7fcb81`, 03/11/2026. **Nenhum sprite foi alterado, substituído ou gerado para o jogo.**
Os painéis de inspeção são apenas miniaturas temporárias da arte existente.

Atualização após slots/comércio/montagem: a nova bancada usa cartões de interface
com nomes/encaixes, não sprites novos de hardware nem uma imagem rotacionada.
Notebook, balcão, bancada e cliente reutilizam os recursos aprovados. Os 142
PNGs originais permanecem preservados; as 33 vistas faltantes continuam pendentes.
O fluxo foi capturado em execução desktop; isso não aprova a arte final da montagem.

## 1. Resultado geral

- **142 PNGs**, **15 SVGs**, **158 metadados `.import`**.
- Dos PNGs, **137 RGBA** e **5 RGB**. Os 135 RGBA isolados com máximo 255 têm
  alfa mínimo 0; dois RGBA de referência/fonte chegam a 254.
- Nenhum PNG repetido por conteúdo RGBA decodificado.
- Alfa real não prova ausência de um fundo falso desenhado dentro da região
  opaca. A inspeção dos painéis não revelou fundos quadriculados nos sprites
  isolados; não foi feito laudo artístico por pixel de cada desenho.
- Todos os PNGs foram abertos e medidos. As dimensões de vizinhança e seus
  pivôs individuais estão no [manifesto existente](../../Assets/Cenarios/Vizinhanca/manifesto.csv);
  os encaixes internos no [manifesto modular](../../Assets/Cenarios/Modular/manifest_encaixes.json).

## 2. Inventário de todas as famílias PNG

As contagens abaixo somam 142; fontes e recursos legados não são confundidos
com sprites efetivamente desenhados no jogo.

| Pasta/família | PNGs | Dimensões de canvas | Alfa e finalidade/uso atual |
|---|---:|---|---|
| [Bairro](../../Assets/Cenarios/Bairro) | 26 | 20 de 128×64; 3 de 1536×1024; 512×512; 128×128; 1168×1012 | 20 tiles preservados, três máscaras da fachada/banco/poste, materiais contínuos e cafeteria |
| [Fontes do bairro](../../Assets/Cenarios/Bairro/Fontes) | 2 | Asfalto 256×256; cafeteria 1152×768 | Asfalto RGB; cafeteria RGBA alfa 0–254; fontes de preparação, não sprites runtime diretos |
| [Exterior](../../Assets/Cenarios/Exterior) | 1 | 1536×1024 | Fachada completa PC Store RGB, referência preservada; runtime usa máscara |
| [Cenários, raiz](../../Assets/Cenarios) | 2 | 1536×1024 | `Loja_Base_Aprovada` RGBA 0–254; `Rua_Comercial_Aprovada` RGB; referências legadas, não montagem atual |
| [Interior modular](../../Assets/Cenarios/Modular) | 7 | 3 pisos 128×64; 2 paredes+canto 128×192; soleira 192×128 | RGBA alfa binário 0/255; todos usados |
| [Prédios v2](../../Assets/Cenarios/Vizinhanca/01_predios) | 5 | 612×528, 580×524, 638×534, 622×752, 656×556 | Farmácia, roupas, mercadinho, prédio comercial e restaurante; cinco usados |
| [Vegetação](../../Assets/Cenarios/Vizinhanca/02_vegetacao) | 8 | 126×146 a 316×198; árvore alongada 202×414 | Oito definições; quatro IDs usados, demais reservados |
| [Mobiliário urbano](../../Assets/Cenarios/Vizinhanca/03_mobiliario_urbano) | 12 | 100×184 a 326×198; poste 114×466 | 12 definições; cinco IDs usados em múltiplas instâncias |
| [Detalhes comerciais](../../Assets/Cenarios/Vizinhanca/04_detalhes_comerciais) | 10 | 164×172 a 380×436 | Mesa, cadeira, frutas e cavalete usados; demais reservados |
| [Compacto azul](../../Assets/Cenarios/Vizinhanca/05_veiculos/compacto_azul) | 4 | 342×244, 338×264, 338×258, 342×238 | Quatro vistas; uma usada, estática |
| [Compacto branco](../../Assets/Cenarios/Vizinhanca/05_veiculos/compacto_branco) | 4 | 370×238, 366×260, 366×262, 370×234 | Quatro vistas; uma usada, estática |
| [Furgão](../../Assets/Cenarios/Vizinhanca/05_veiculos/furgao_entregas) | 4 | 374×286, 370×312, 370×290, 374×270 | Quatro vistas; uma usada, estática |
| [Estados externos](../../Assets/Cenarios/Vizinhanca/06_estados) | 3 | Placas 228×228; poste aceso 114×466 | Reservados, não alternados em runtime |
| [Móveis, raiz](../../Assets/Moveis) | 1 | 96×80 | `balcao_pixel_art`, legado sem uso no fluxo atual |
| [Balcão PC Store](../../Assets/Moveis/Balcoes/balcao_pc_store) | 4 | 256×256 cada | RGBA real, quatro texturas diferentes, comprável e girável |
| [Móveis modulares](../../Assets/Moveis/Modulares) | 11 | Ver tabela individual | Todos compráveis; quatro começam colocados |
| [Personagens, raiz](../../Assets/Personagens) | 2 | 32×48 | Temporários legados, não usados pelo personagem atual |
| [Cliente estudante](../../Assets/Personagens/Modulares/cliente_estudante) | 8 | 160×240 | Quatro direções × idle/passo; NPC atual |
| [Cliente mochila](../../Assets/Personagens/Modulares/cliente_mochila) | 8 | 160×240 | Carregável/testado, não instanciado pelo fluxo normal |
| [Protagonista](../../Assets/Personagens/Modulares/protagonista) | 12 | 160×240 | Quatro direções × idle/passo_a/passo_b; jogador atual |
| [Técnico](../../Assets/Personagens/Modulares/tecnico) | 8 | 160×240 | Carregável/testado, sem sistema de funcionário |

### Detalhamento dos conjuntos externos

Os 20 tiles 128×64 do bairro são:
`calcada_concreto_{a,b,c}`, `asfalto_{a,b,c}`,
`transicao_borda_{topo,direita,base,esquerda}`,
`transicao_canto_{topo_direita,direita_base,base_esquerda,esquerda_topo}`,
`travessia_orientacao_{a,b}_lado_{1,2}` e `acesso_calcada_orientacao_{a,b}`.
Não são o piso renderizado da rua atual; o piso atual usa materiais contínuos e
marcações desenhadas pelo código de [bairro](../../scripts/BairroComercial.gd#L96).

Além deles há `pc_store_recorte`, `banco_recorte`, `poste_recorte`,
`cafeteria`, `asfalto_continuo` e `calcada_continua`.

O catálogo de 50 itens da [vizinhança](../../scripts/CatalogoVizinhanca.gd) contém:

- Prédios: `farmacia`, `loja_roupas`, `mercadinho`, `predio_comercial`, `restaurante`.
- Vegetação: `arbusto_baixo`, `arvore_copa_alongada`, `arvore_copa_redonda`,
  `arvore_florida`, `canteiro_flores`, `jardineira_retangular`, `vaso_grande`, `vaso_pequeno`.
- Urbano: `balizador`, `banco_madeira`, `bicicleta`, `bicicletario`, `bueiro`,
  `coletor_reciclagem`, `cone`, `hidrante`, `lixeira_publica`,
  `placa_estacionamento`, `placa_pedestres`, `poste_iluminacao`.
- Comércio: `ar_condicionado_externo`, `cadeira_externa`, `caixa_frutas`,
  `caixas_entrega`, `cardapio_cavalete`, `carrinho_carga`, `guarda_sol`,
  `mesa_externa`, `saco_lixo_fechado`, `vaso_pendurado`.
- Veículos: três modelos × `baixo_direita`, `baixo_esquerda`, `cima_direita`, `cima_esquerda`.
- Estados: `placa_aberto`, `placa_fechado`, `poste_iluminacao_aceso`.

São 36 **instâncias** de objetos + cinco fachadas, não 41 assets únicos usados.
São usados quatro IDs de vegetação, cinco urbanos, quatro comerciais e três
vistas de veículos: com os cinco prédios, **21 dos 50 IDs aparecem no mapa**.
Os outros 29 permanecem no catálogo/preloads; disponibilidade não equivale a uso visual.

## 3. Os 11 móveis originais

Todos têm RGBA com alfa 0–255 e bbox visível `(8,8,w-8,h-8)`.
O código preserva o arquivo original como 0° e procura `90.png`, `180.png`,
`270.png` na subpasta do mesmo nome. **Nenhuma dessas 33 vistas existe.**

A largura é parâmetro runtime aplicado ao **canvas**, não à bbox opaca.
Pivô derivado: `(w/2,h-8)`. Colisão abaixo é a dimensão de referência do catálogo,
não medição artística validada da base física.

| ID / PNG em móveis modulares | Canvas | Largura runtime | Colisão | Vistas existentes | Faltantes |
|---|---|---:|---|---|---|
| `balcao_atendimento` | 456×362 | 180 | 170×70 | 0° | 90°, 180°, 270° |
| `bancada_montagem_com_computador` | 426×430 | 150 | 140×64 | 0° | 90°, 180°, 270° |
| `mesa_notebook_com_cadeira` | 263×302 | 110 | 100×58 | 0° | 90°, 180°, 270° |
| `prateleira_componentes` | 332×226 | 145 | 135×54 | 0° | 90°, 180°, 270° |
| `armario_pecas_gavetas` | 156×168 | 75 | 66×38 | 0° | 90°, 180°, 270° |
| `estante_metalica_estoque` | 222×390 | 85 | 75×42 | 0° | 90°, 180°, 270° |
| `vitrine_gpu` | 216×240 | 95 | 85×44 | 0° | 90°, 180°, 270° |
| `cadeira_escritorio` | 132×180 | 48 | 42×30 | 0° | 90°, 180°, 270° |
| `banqueta` | 98×123 | 35 | 30×20 | 0° | 90°, 180°, 270° |
| `caixa_registradora` | 166×172 | 48 | 40×24 | 0° | 90°, 180°, 270° |
| `pc_monitor_teclado` | 184×200 | 65 | 58×30 | 0° | 90°, 180°, 270° |

Fonte: [catálogo](../../scripts/Imoveis/CatalogoSprites.gd#L5) e
[renderização](../../scripts/Moveis/MovelIsometrico.gd#L108).
Eles mantêm o mesmo eixo de base técnico; a conformidade artística exata 2:1 e o
footprint de cada objeto ainda precisam de medição com a arte, não apenas de `isometrico=true`.

A inspeção encontrou inscrições/logotipos aparentes de fabricantes reais em
caixas da prateleira. O mestre exige catálogo de hardware fictício; não se deve
alterar a arte aprovada automaticamente. Registrar e pedir decisão artística
antes de reutilizar esses detalhes como identidade dos futuros produtos.

## 4. Balcão PC Store: giro funciona, geometria ainda não aprovada

Os quatro PNGs têm alfa real, são distintos e usam canvas 256×256 e pivô
`(128,248)`. A sonda no Godot confirmou escala **0,65** em todas as vistas.

| Vista | Bbox alfa no PNG | Tamanho opaco no mundo | Colisão sem margem |
|---|---|---|---|
| 0° | `(8,138,248,248)` | 156×71,50 | 128×64 |
| 90° | `(8,26,248,248)` | 156×144,30 | 64×128 |
| 180° | `(8,133,248,248)` | 156×74,75 | 128×64 |
| 270° | `(8,47,248,248)` | 156×130,65 | 64×128 |

Constatações:

1. O teste comprova troca real de textura, sem `rotation` 2D.
2. 0°/180° têm apresentação quase frontal; 90°/270° mostram profundidade muito
   maior. As quatro vistas não podem ser aprovadas apenas porque os hashes diferem.
3. O [preparador legado](../../tools/prepare_assets.py#L45) normaliza cada
   recorte para largura 240 independentemente. Isso não prova escala física
   consistente entre ângulos.
4. A colisão troca largura/altura em coordenadas **de tela**, criando em 90°/270°
   um losango vertical 64×128, que não acompanha as diagonais do piso 2:1.
5. Escala visual e dimensões de colisão são independentes no código. O PR #9 só
   muda a escala para 0,52: reduziria a largura visível para 124,8, mas manteria
   as colisões 128×64/64×128. Portanto, **não demonstra resolver o encaixe**.
6. Um pivô na mesma coordenada de canvas não comprova que o mesmo ponto físico
   da base esteja ancorado nas quatro imagens.

Conclusão: defeito geométrico de footprint confirmado; proporção/pivô artístico
precisam de revisão autorizada. Não substituir nem redesenhar os PNGs.

## 5. Perspectiva, âncoras e profundidade

### Interior

- Pisos 128×64, eixos `(64,32)` e `(-64,32)`, sala inicial 6×5.
- Testes pixel a pixel não encontraram frestas internas em salas 6×5 e 8×7.
- Parede esquerda ancora em `(96,144)`, direita em `(32,144)`, canto `(64,144)`;
  soleira `(160,40)`, conforme [manifesto](../../Assets/Cenarios/Modular/manifest_encaixes.json).
- Piso e paredes usam camadas fixas negativas; jogador/móveis usam Y da base.
  Isso funciona nos cenários testados, mas não fornece oclusão geral de
  divisórias editáveis, ainda inexistentes.
- Seleção de móvel testa pixel opaco; o retângulo transparente não basta.

### Exterior

- Eixos reais `(64,20)` e `(-64,32)`: **não é grid 2:1 simétrico**.
- [Cafeteria](../../Assets/Cenarios/Bairro/cafeteria.json) passou por cisalhamento
  vertical `0,1633125` e escala Y `1,0517718`. Fonte original preservada e hash
  verificado pelo teste. É adaptação geométrica preexistente, não nova vista artística.
- As portas da cafeteria/PC Store diferem menos de três pixels de altura no teste.
  Isso valida alinhamento técnico, não aprova a perspectiva como 2:1.
- Fachadas são fatiadas verticalmente e ordenadas pela linha da base, não pelo telhado.
  Banco, poste e objetos têm profundidade/colisão independentes.
- Os recortes da PC Store, banco e poste mantêm RGB idêntico à fachada de origem;
  alteram máscara alfa, não o desenho RGB.

### Personagens

- Canvas 160×240, pivô nos pés `(80,232)`.
- Escala calculada pela maior altura opaca idle, para referência de 112 pixels.
- Quatro direções desenhadas; nenhuma aparência procedural por partes.
- 36 quadros não significam 36 NPCs nem sistema de funcionários.

## 6. Importação

157 metadados de textura compartilham:

```text
compress/mode=0
mipmaps/generate=false
process/fix_alpha_border=true
process/premult_alpha=false
process/size_limit=0
```

Sprites runtime usam filtro nearest; materiais do piso exterior permitem repeat,
mas fachadas/objetos o desabilitam. Não há redimensionamento de importação por
`size_limit`. O alto canvas transparente das três máscaras 1536×1024 é custo
potencial de memória/desenho; **não foi medido impacto Android**.

O CSV foi importado também como traduções, gerando sete `.translation`
versionados. São metadados do manifesto, não interface localizada; não se
identificou consumo deles pelo jogo.

## 7. SVGs e recursos preservados sem uso atual

Os oito itens SVG legados são
[balcão](../../Assets/Moveis/Balcoes/balcao_simples.svg),
[mesa](../../Assets/Moveis/Mesas/mesa_exposicao.svg),
[estante](../../Assets/Moveis/Prateleiras/estante_pecas.svg),
[vitrine](../../Assets/Moveis/Vitrines/vitrine_fechada.svg),
[sofá](../../Assets/Moveis/Assentos/sofa_azul.svg),
[planta](../../Assets/Decoracao/Plantas/planta_01.svg),
[gabinete](../../Assets/Equipamentos/Computadores/gabinete_rgb.svg) e
[monitor](../../Assets/Equipamentos/Monitores/monitor.svg).
Todos esses oito SVGs têm canvas/viewBox 128×128.
Continuam no catálogo para compatibilidade, mas são filtrados da compra normal
por não terem `isometrico=true`. Não representam arte final adicional.

Os sete [SVGs da porta](../../Assets/Portas) têm canvas/viewBox 96×128 e são legados;
a porta atual usa textura da fachada em polígonos, não esses arquivos.
Preservar também cenários aprovados completos, tiles antigos, personagens
temporários e recursos reservados: “sem uso” não autoriza exclusão.

## 8. Recursos faltantes

| Prioridade | Recurso | Quantidade/estado verificável |
|---|---|---|
| P1 | Outras vistas dos móveis originais | **33 PNGs**: três para cada um dos 11 originais |
| P1 | Referência geométrica por móvel/vista | Medir footprint, eixo/pivô, altura e proporção; quantidade de manifestos não fixa |
| P2 | Quadros finais da porta | Sete estados solicitados na documentação de arte; não existem como PNG final |
| P2 | Construção estrutural | Acabamentos, divisórias, portas/janelas editáveis e variantes ainda a especificar |
| P2 | Hardware e montagem | Ícones e peças separadas CPU/RAM/GPU/placa-mãe/SSD/fonte/gabinete/cooler; arte composta não atende |
| P2 | NPC procedural | Corpo, cabelo, roupas e acessórios separados por direção/estado; nenhum pacote desse tipo encontrado |
| P3 | Serviços | Estados de diagnóstico, limpeza, reparo, ferramentas e efeitos; quantidade depende do primeiro fluxo |
| P3 | Clima/eventos | Guarda-chuvas, respingos e decoração temporária; chuva pode usar partículas |
| P3 | Estados de uso de móveis | Bancada ocupada, estante vazia/parcial/cheia, caixa e equipamentos em operação |
| P3 | UI de gerenciamento | Ícones/painéis de inventário, pedidos, equipe, saves e construção; atual UI é gerada com controles Godot |
| Futuro | Novos interiores e roupas compráveis | Não necessários para corrigir o protótipo atual |

Não faltam “mais três vistas” dos veículos: já há quatro por modelo.
Não é necessário gerar outra fachada PC Store, outro interior completo ou
substituir os personagens para testar a base.

**Regra de aprovação:** preservar o original 0° byte a byte; novas vistas devem
ser desenhos coerentes do mesmo objeto, não cópias, espelhamentos de texto ou
rotação plana. Comparar proporções no jogo, obter autorização e só então integrar.
Esta auditoria não aprovou nem produziu qualquer nova arte.

## 9. Acompanhamento A1 - baseline reproduzível do balcão

Executado após autorização para seguir com a primeira tarefa, em 03/11/2026.
O código do jogo e os sprites permanecem na base `b7fcb81`; somente a ferramenta
de diagnóstico e as evidências abaixo foram adicionadas.

- [Comparação ampliada das quatro vistas](evidencias/balcao/comparacao.png).
- Capturas completas no mesmo piso, câmera e posição:
  [0°](evidencias/balcao/balcao_000.png),
  [90°](evidencias/balcao/balcao_090.png),
  [180°](evidencias/balcao/balcao_180.png),
  [270°](evidencias/balcao/balcao_270.png).
- [Medições brutas](evidencias/balcao/medidas.json).
- [Ferramenta reproduzível](../../tools/medir_balcao.gd), sem conexão com a cena de produção.

As linhas amarelas representam o **polígono real de colisão sem margem**; ciano,
a bbox alfa renderizada; a cruz vermelha, o pivô; azul, a grade 128×64.
O painel ampliado é um recorte nearest-neighbor das capturas, não arte nova.
A pasta de evidências possui `.gdignore` para não importar essas capturas como
recursos do jogo.

Todos os ângulos usam posição mundial `(700,400)`, escala 0,65 e pivô de canvas
`(128,248)`. Não foi aplicado o PR #9. Os polígonos locais medidos foram:

| Ângulos | Vértices relativos ao pivô | Inclinação absoluta das arestas | Resultado no grid |
|---|---|---:|---|
| 0° e 180° | `(0,-64)`, `(64,-32)`, `(0,0)`, `(-64,-32)` | 0,5 | Alinhados com os eixos 2:1 |
| 90° e 270° | `(0,-128)`, `(32,-64)`, `(0,0)`, `(-32,-64)` | 2,0 | **Reprovados** |

O alinhamento de 0°/180° é apenas matemático: não aprova a correspondência da
colisão com a base desenhada, porque essas duas imagens têm apresentação quase
frontal. O pivô físico artístico continua **não aprovado em todas as vistas**.
Não é possível certificar um footprint físico consistente apenas a partir de
igual largura e igual ponto inferior no canvas.

### Comportamentos testados

**35 verificações passaram, zero falhas de comportamento:** colocação em área
livre, quatro giros retornando à mesma textura, cancelar restaurando posição e
orientação, gravação e leitura isoladas nas quatro vistas, bloqueio no centro
da colisão, piso afastado livre, quatro capturas e limpeza dos saves de teste.
O último log não apresentou erros de parsing, script, renderização ou avisos.

A ferramenta terminou com **exit 2**, intencionalmente: o diagnóstico geométrico
foi **REPROVADO**, apesar de os comportamentos passarem. Não confundir o resultado
funcional verde com aprovação de encaixe.

Para repetir, em uma cópia isolada do projeto já importada:

```powershell
New-Item -ItemType Directory -Force -Path 'C:\evidencias-balcao'
$env:PIXEL_BALCAO_OUTPUT_DIR = 'C:\evidencias-balcao'
godot --path 'C:\copia-isolada-do-projeto' --script res://tools/medir_balcao.gd
```

O executável precisa estar no PATH ou ser substituído pelo seu caminho completo.
Não usar `--headless`: são necessárias capturas renderizadas. A pasta de saída
deve existir e ser dedicada às evidências, pois os arquivos têm nomes estáveis.
O teste cria saves próprios e não lê nem grava o progresso do jogador.
Exit 0 significa geometria alinhada e comportamento aprovado; exit 1, erro de
execução/verificação; exit 2, geometria reprovada.

**Decisão necessária ao encerrar A1:** corrigir somente a projeção de colisão preservando sprites
e escala, com pendência artística explícita, ou validar as referências das quatro
vistas antes de qualquer ajuste de comportamento. Não redesenhar, deformar ou
substituir os sprites para encobrir a divergência.

## 10. Acompanhamento A2 - projeção de colisão corrigida

O responsável escolheu corrigir **somente a colisão**, preservando sprites e
escala e mantendo a pendência visual explícita. A alteração está na árvore de
trabalho; não houve commit, push, APK nem aplicação do PR #9.

Em [MovelIsometrico.gd](../../scripts/Moveis/MovelIsometrico.gd), as dimensões da
colisão passaram a usar um único cálculo para renderização lógica/validação e
para o estado confirmado. Um quarto de volta no grid 2:1 transforma as diagonais
projetadas `(largura,altura)` em `(2×altura,largura/2)`, em vez de simplesmente
trocar largura/altura da tela.

- No balcão, 128×64 permanece **128×64 nos quatro ângulos**.
- As vistas 0°/180° e os demais móveis atualmente com uma única vista não mudam.
- A rotação dos SVGs não isométricos continua trocando largura/altura como antes.
- A colisão da posição/orientação confirmada continua independente da prévia.
- Nenhum preço, save, textura, pivô, escala ou fluxo de interação foi alterado.
- Isso corrige a projeção conhecida, **não certifica a base física da arte**.

Evidências finais, separadas da baseline:

- [Comparação após correção](evidencias/balcao_corrigido/comparacao.png).
- [0°](evidencias/balcao_corrigido/balcao_000.png),
  [90°](evidencias/balcao_corrigido/balcao_090.png),
  [180°](evidencias/balcao_corrigido/balcao_180.png),
  [270°](evidencias/balcao_corrigido/balcao_270.png).
- [Medições após correção](evidencias/balcao_corrigido/medidas.json).

### Validação do ajuste

| Verificação | Resultado |
|---|---|
| Novos testes executados contra código antigo | **601 passaram, 10 falharam**; defeito reproduzido antes do ajuste |
| Importação/parsing após ajuste | Exit 0, sem erros ou avisos |
| Suíte Godot headless após ajuste | **611 passaram, 0 falharam** |
| Suíte Godot renderizada após ajuste | **632 passaram, 0 falharam** |
| Ferramenta das quatro vistas | **35 passaram, 0 falharam**, exit 0; projeção de colisão aprovada |
| Inclinação das arestas sem margem | **0,5 em todos os ângulos**, compatível com o piso 2:1 |
| PNGs originais | **142/142 hashes SHA-256 preservados** |
| Android | Não executado nesta etapa |

As regressões cobrem quatro ângulos, limites da base, posição válida no piso,
estado confirmado durante prévia, caso isométrico não quadrado e manutenção da
regra dos SVGs legados. O caso de móvel modular sem vistas adicionais é apenas
um teste geométrico isolado: não habilita giro nem cria arte inexistente.

**Pendência mantida:** as vistas quase frontais de 0°/180° e a proporção entre as
quatro imagens exigem decisão artística antes de declarar o encaixe visual final.
