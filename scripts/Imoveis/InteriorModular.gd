extends Node2D

const BASE := "res://Assets/Cenarios/Modular/"
const PISOS := [
    preload(BASE + "piso_madeira_clara_a.png"),
    preload(BASE + "piso_madeira_clara_b.png"),
    preload(BASE + "piso_madeira_clara_c.png")
]
const ESQUERDA = preload(BASE + "parede_diagonal_esquerda.png")
const DIREITA = preload(BASE + "parede_diagonal_direita.png")
const CANTO = preload(BASE + "canto_interno_uniao.png")
const SOLEIRA = preload(BASE + "soleira_entrada_2_modulos.png")
const U := Vector2(64,32)
const V := Vector2(-64,32)
var tamanho := Vector2i(6,5)
var origem := Vector2(700,240)
var acabamentos: Dictionary = {}

func aplicar_acabamentos(dados: Dictionary) -> void:
    acabamentos = dados.duplicate(true)
    configurar({"modulos":tamanho,"origem":origem})

static func ponto(uv: Vector2, inicio: Vector2) -> Vector2:
    return inicio + U * uv.x + V * uv.y

static func poligono(dimensoes: Vector2i, inicio: Vector2) -> PackedVector2Array:
    return PackedVector2Array([inicio, ponto(Vector2(dimensoes.x,0),inicio),
        ponto(Vector2(dimensoes),inicio), ponto(Vector2(0,dimensoes.y),inicio)])

func configurar(dados: Dictionary) -> void:
    tamanho = dados["modulos"]
    origem = dados["origem"]
    for child in get_children():
        remove_child(child)
        child.queue_free()
    for u in range(tamanho.x):
        for v in range(tamanho.y):
            var celula: Dictionary = preload("res://scripts/Reforma.gd").celula(acabamentos,u,v)
            _peca(PISOS[int(celula["piso"])],ponto(Vector2(u,v),origem) - Vector2(64,0),-20)
            if not celula["setor"].is_empty():
                var rotulo := Label.new()
                rotulo.text = celula["setor"]
                rotulo.position = ponto(Vector2(u+0.5,v+0.5),origem) - Vector2(25,4)
                rotulo.add_theme_font_size_override("font_size",9)
                rotulo.z_index = -15
                rotulo.mouse_filter = Control.MOUSE_FILTER_IGNORE
                add_child(rotulo)
    for u in range(tamanho.x):
        _peca(DIREITA,ponto(Vector2(u,0),origem) - Vector2(32,144),-10)
    for v in range(tamanho.y):
        _peca(ESQUERDA,ponto(Vector2(0,v),origem) - Vector2(96,144),-10)
    _peca(CANTO,origem - Vector2(64,144),-9)
    _peca(SOLEIRA,ponto(Vector2(tamanho.x,1),origem) - Vector2(160,40),-8)

func _peca(textura: Texture2D, at: Vector2, depth: int) -> void:
    var sprite := Sprite2D.new()
    sprite.texture = textura
    sprite.centered = false
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.position = at
    sprite.z_index = depth
    add_child(sprite)

func limites() -> Rect2:
    return Rect2(origem + Vector2(-tamanho.y * 64,-100),
        Vector2((tamanho.x + tamanho.y) * 64,(tamanho.x + tamanho.y) * 32 + 100))
