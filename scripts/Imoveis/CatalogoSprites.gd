extends RefCounted
# Catalogo de sprites modulares; recursos SVG sao provisórios e transparentes.
# Cada entrada possui caminho unico, categoria e preco para futura loja de moveis.
const ITENS := {
    "balcao_atendimento": {"nome":"Balcao de atendimento","arquivo":"res://Assets/Moveis/Modulares/balcao_atendimento.png","preco":450,"largura":180,"colisao":Vector2(170,70),"isometrico":true},
    "bancada_montagem_com_computador": {"nome":"Bancada de montagem","arquivo":"res://Assets/Moveis/Modulares/bancada_montagem_com_computador.png","preco":900,"largura":150,"colisao":Vector2(140,64),"isometrico":true},
    "mesa_notebook_com_cadeira": {"nome":"Mesa com notebook","arquivo":"res://Assets/Moveis/Modulares/mesa_notebook_com_cadeira.png","preco":650,"largura":110,"colisao":Vector2(100,58),"isometrico":true},
    "prateleira_componentes": {"nome":"Prateleira de componentes","arquivo":"res://Assets/Moveis/Modulares/prateleira_componentes.png","preco":500,"largura":145,"colisao":Vector2(135,54),"isometrico":true},
    "armario_pecas_gavetas": {"nome":"Armario de pecas","arquivo":"res://Assets/Moveis/Modulares/armario_pecas_gavetas.png","preco":350,"largura":75,"colisao":Vector2(66,38),"isometrico":true},
    "estante_metalica_estoque": {"nome":"Estante de estoque","arquivo":"res://Assets/Moveis/Modulares/estante_metalica_estoque.png","preco":600,"largura":85,"colisao":Vector2(75,42),"isometrico":true},
    "vitrine_gpu": {"nome":"Vitrine de GPU","arquivo":"res://Assets/Moveis/Modulares/vitrine_gpu.png","preco":750,"largura":95,"colisao":Vector2(85,44),"isometrico":true},
    "cadeira_escritorio": {"nome":"Cadeira de escritorio","arquivo":"res://Assets/Moveis/Modulares/cadeira_escritorio.png","preco":180,"largura":48,"colisao":Vector2(42,30),"isometrico":true},
    "banqueta": {"nome":"Banqueta","arquivo":"res://Assets/Moveis/Modulares/banqueta.png","preco":90,"largura":35,"colisao":Vector2(30,20),"isometrico":true},
    "caixa_registradora": {"nome":"Caixa registradora (decoracao)","arquivo":"res://Assets/Moveis/Modulares/caixa_registradora.png","preco":250,"largura":48,"colisao":Vector2(40,24),"isometrico":true},
    "pc_monitor_teclado": {"nome":"PC e monitor (decoracao)","arquivo":"res://Assets/Moveis/Modulares/pc_monitor_teclado.png","preco":1000,"largura":65,"colisao":Vector2(58,30),"isometrico":true},
    "balcao_pc_store": {"nome":"Balcao PC Store (arte provisoria)","arquivo":"res://Assets/Moveis/Balcoes/balcao_pc_store/0.png","pasta_angulos":"res://Assets/Moveis/Balcoes/balcao_pc_store","categoria":"balcoes","preco":450,"revenda":225,"colisao":Vector2(128,64),"escala":0.65,"pivo":Vector2(128,248)},
    "balcao_simples": {"arquivo":"res://Assets/Moveis/Balcoes/balcao_simples.svg","categoria":"balcoes","preco":450,"colisao":Vector2(96,45)},
    "mesa_exposicao": {"arquivo":"res://Assets/Moveis/Mesas/mesa_exposicao.svg","categoria":"mesas","preco":650,"colisao":Vector2(100,45)},
    "estante_pecas": {"arquivo":"res://Assets/Moveis/Prateleiras/estante_pecas.svg","categoria":"prateleiras","preco":850,"colisao":Vector2(80,55)},
    "vitrine_fechada": {"arquivo":"res://Assets/Moveis/Vitrines/vitrine_fechada.svg","categoria":"vitrines","preco":1100,"colisao":Vector2(105,50)},
    "sofa_azul": {"arquivo":"res://Assets/Moveis/Assentos/sofa_azul.svg","categoria":"assentos","preco":390,"colisao":Vector2(105,52)},
    "planta_01": {"arquivo":"res://Assets/Decoracao/Plantas/planta_01.svg","categoria":"decoracao","preco":95,"colisao":Vector2(42,35)},
    "gabinete_rgb": {"arquivo":"res://Assets/Equipamentos/Computadores/gabinete_rgb.svg","categoria":"computadores","preco":1200,"colisao":Vector2(55,55)},
    "monitor": {"arquivo":"res://Assets/Equipamentos/Monitores/monitor.svg","categoria":"monitores","preco":450,"colisao":Vector2(72,34)}
}

static func dados(id: String) -> Dictionary:
    if not ITENS.has(id):
        push_error("Movel desconhecido: " + id)
    return ITENS.get(id, {})

static func textura(id: String) -> Texture2D:
    var item := dados(id)
    if item.is_empty():
        return null
    return load(str(item["arquivo"])) as Texture2D

static func criar_sprite(id: String, posicao: Vector2) -> Sprite2D:
    var tex := textura(id)
    if tex == null:
        return null
    var sprite := Sprite2D.new()
    sprite.name = id
    sprite.texture = tex
    sprite.position = posicao
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    return sprite

## Busca os quatro angulos em pastas individuais; enquanto nao houver PNGs
## definitivos, usa o SVG legado como placeholder, sem simular perspectiva.
static func textura_orientada(id: String, angulo: int = 0) -> Texture2D:
    var item: Dictionary = dados(id)
    if item.is_empty():
        return null
    var arquivo: String = str(item["arquivo"])
    var base: String = arquivo.get_base_dir()
    var nome: String = arquivo.get_file().get_basename()
    var pasta: String = str(item.get("pasta_angulos", base.path_join(nome)))
    var candidato: String = pasta.path_join(str(angulo) + ".png")
    if ResourceLoader.exists(candidato):
        return load(candidato) as Texture2D
    return textura(id)

static func orientacoes_disponiveis(id: String) -> Array[int]:
    var resultado: Array[int] = []
    var item: Dictionary = dados(id)
    if item.is_empty():
        return resultado if not resultado.is_empty() else [0]
    var arquivo: String = str(item["arquivo"])
    var pasta: String = str(item.get("pasta_angulos", arquivo.get_base_dir().path_join(arquivo.get_file().get_basename())))
    for angulo in [0, 90, 180, 270]:
        if ResourceLoader.exists(pasta.path_join(str(angulo) + ".png")):
            resultado.append(angulo)
    return resultado
