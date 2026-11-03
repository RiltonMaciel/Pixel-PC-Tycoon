extends Node2D
## Movel modular para interiores isometricos. A orientacao troca a textura,
## nunca gira a imagem 2D (o que distorceria a perspectiva).
signal orientacao_alterada(nova_orientacao: int)
const CATALOGO = preload("res://scripts/Imoveis/CatalogoSprites.gd")
const ANGULOS := [0, 90, 180, 270]
var item_id: String = ""
var orientacao: int = 0
var orientacao_confirmada: int = 0
var posicao_confirmada: Vector2 = Vector2.ZERO
var em_edicao: bool = false
var visual: Sprite2D

func _ready() -> void:
    visual = Sprite2D.new()
    visual.name = "Visual"
    visual.centered = false
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
    # Saves antigos podem referenciar um angulo cuja arte ainda nao existe.
    # Normaliza para a primeira vista real antes de renderizar.
    var disponiveis := CATALOGO.orientacoes_disponiveis(item_id)
    if not disponiveis.is_empty() and not disponiveis.has(ANGULOS[orientacao]):
        orientacao = ANGULOS.find(disponiveis[0])
    orientacao_confirmada = orientacao
    if is_node_ready():
        _atualizar()

func girar(sentido: int = 1) -> bool:
    var disponiveis := CATALOGO.orientacoes_disponiveis(item_id)
    if disponiveis.size() < 2:
        return false
    var indice := disponiveis.find(ANGULOS[orientacao])
    if indice < 0:
        # Um save antigo pode conter uma orientacao sem sprite correspondente.
        # Retorna ao primeiro angulo real em vez de inventar uma rotacao.
        indice = 0
        orientacao = ANGULOS.find(disponiveis[indice])
    else:
        orientacao = ANGULOS.find(disponiveis[posmod(indice + sentido,disponiveis.size())])
    _atualizar()
    orientacao_alterada.emit(ANGULOS[orientacao])
    return true

func iniciar_edicao() -> void:
    posicao_confirmada = position
    orientacao_confirmada = orientacao
    em_edicao = true
    modulate.a = 0.65

func confirmar() -> void:
    posicao_confirmada = position
    orientacao_confirmada = orientacao
    em_edicao = false
    modulate = Color.WHITE

func cancelar() -> void:
    position = posicao_confirmada
    orientacao = orientacao_confirmada
    em_edicao = false
    modulate = Color.WHITE
    _atualizar()

func dimensoes_colisao() -> Vector2:
    var dados: Dictionary = CATALOGO.dados(item_id)
    var tamanho: Vector2 = dados.get("colisao", Vector2(48, 32))
    return Vector2(tamanho.y, tamanho.x) if orientacao % 2 == 1 else tamanho

func serializar() -> Dictionary:
    var at := posicao_confirmada if em_edicao else position
    var angle := orientacao_confirmada if em_edicao else orientacao
    return {"id": item_id, "posicao": [at.x, at.y], "angulo": ANGULOS[angle]}

func poligono_colisao(at: Vector2, margem: float = 0.0, confirmado: bool = false) -> PackedVector2Array:
    var dados := CATALOGO.dados(item_id)
    var dimensoes: Vector2 = dados.get("colisao",Vector2(48,32))
    var angle := orientacao_confirmada if confirmado else orientacao
    if angle % 2 == 1:
        dimensoes = Vector2(dimensoes.y,dimensoes.x)
    if dados.get("isometrico",false):
        var centro := at - Vector2(0,dimensoes.y * 0.5)
        var raio := dimensoes * 0.5 + Vector2.ONE * margem * 2.0
        return PackedVector2Array([centro + Vector2(0,-raio.y),centro + Vector2(raio.x,0),centro + Vector2(0,raio.y),centro + Vector2(-raio.x,0)])
    var size := dimensoes * 0.5 + Vector2.ONE * margem
    return PackedVector2Array([at + Vector2(-size.x,-size.y), at + Vector2(size.x,-size.y), at + Vector2(size.x,margem), at + Vector2(-size.x,margem)])

func contem_ponto(at: Vector2) -> bool:
    if visual == null or visual.texture == null:
        return false
    var local := visual.to_local(at)
    return visual.get_rect().has_point(local) and visual.is_pixel_opaque(local)

func indicar_validade(valido: bool) -> void:
    modulate = Color(1,1,1,0.65) if valido else Color(1,0.3,0.3,0.65)

func _process(_delta: float) -> void:
    z_index = int(position.y)

func _atualizar() -> void:
    if visual == null:
        return
    visual.texture = CATALOGO.textura_orientada(item_id, ANGULOS[orientacao])
    var dados: Dictionary = CATALOGO.dados(item_id)
    if visual.texture == null:
        push_warning("Sprite ausente para movel: " + item_id)
        return
    var tamanho := visual.texture.get_size()
    visual.offset = -Vector2(dados.get("pivo", Vector2(tamanho.x * 0.5, tamanho.y - 8 if dados.has("largura") else tamanho.y)))
    var escala := float(dados.get("largura",tamanho.x)) / tamanho.x if dados.has("largura") else float(dados.get("escala",1.0))
    visual.scale = Vector2.ONE * escala
    visual.z_index = 0
