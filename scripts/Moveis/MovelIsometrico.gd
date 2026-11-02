extends Node2D
## Movel modular para interiores isometricos. A orientacao troca a textura,
## nunca gira a imagem 2D (o que distorceria a perspectiva).
signal orientacao_alterada(nova_orientacao: int)
const CATALOGO = preload("res://scripts/Imoveis/CatalogoSprites.gd")
const ANGULOS := [0, 90, 180, 270]
var item_id: String = ""
var orientacao: int = 0
var posicao_confirmada: Vector2 = Vector2.ZERO
var em_edicao: bool = false
var visual: Sprite2D

func _ready() -> void:
    visual = Sprite2D.new()
    visual.name = "Visual"
    visual.centered = true
    visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(visual)
    _atualizar()

func configurar(id: String, posicao: Vector2, angulo: int = 0) -> void:
    item_id = id
    position = posicao
    posicao_confirmada = posicao
    orientacao = ANGULOS.find(angulo)
    if orientacao < 0:
        orientacao = 0
    if is_node_ready():
        _atualizar()

func girar(sentido: int = 1) -> void:
    orientacao = posmod(orientacao + sentido, 4)
    _atualizar()
    orientacao_alterada.emit(ANGULOS[orientacao])

func iniciar_edicao() -> void:
    em_edicao = true
    modulate.a = 0.65

func confirmar() -> void:
    posicao_confirmada = position
    em_edicao = false
    modulate = Color.WHITE

func cancelar() -> void:
    position = posicao_confirmada
    em_edicao = false
    modulate = Color.WHITE

func dimensoes_colisao() -> Vector2:
    var dados: Dictionary = CATALOGO.dados(item_id)
    var tamanho: Vector2 = dados.get("colisao", Vector2(48, 32))
    return Vector2(tamanho.y, tamanho.x) if orientacao % 2 == 1 else tamanho

func serializar() -> Dictionary:
    return {"id": item_id, "posicao": [position.x, position.y], "angulo": ANGULOS[orientacao]}

func _atualizar() -> void:
    if visual == null:
        return
    visual.texture = CATALOGO.textura_orientada(item_id, ANGULOS[orientacao])
    visual.z_index = 0
