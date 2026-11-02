extends RefCounted
# Catalogo de sprites modulares; recursos SVG sao provisórios e transparentes.
# Cada entrada possui caminho unico, categoria e preco para futura loja de moveis.
const ITENS := {
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
    var candidato: String = base.path_join(nome).path_join(str(angulo) + ".png")
    if ResourceLoader.exists(candidato):
        return load(candidato) as Texture2D
    return textura(id)

static func orientacoes_disponiveis(id: String) -> Array[int]:
    var resultado: Array[int] = []
    var item: Dictionary = dados(id)
    if item.is_empty():
        return resultado
    var arquivo: String = str(item["arquivo"])
    var pasta: String = arquivo.get_base_dir().path_join(arquivo.get_file().get_basename())
    for angulo in [0, 90, 180, 270]:
        if ResourceLoader.exists(pasta.path_join(str(angulo) + ".png")):
            resultado.append(angulo)
    return resultado
