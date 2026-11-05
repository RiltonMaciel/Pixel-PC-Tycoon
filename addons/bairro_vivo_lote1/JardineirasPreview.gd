extends Node2D
## Previa isolada dos oito PNGs do Lote 1. Nao altera artes aprovadas.
const BAIRRO = preload("res://scripts/BairroComercial.gd")
const RAIZ := "res://Assets/BairroVivo21/Vegetacao/Jardineiras/"
const IDS := ["jardineira_rosa", "jardineira_vermelha", "jardineira_amarela", "jardineira_azul", "jardineira_branca", "jardineira_lavanda", "jardineira_mista", "jardineira_verde"]
const PIVOS := {
    "jardineira_rosa": Vector2(69,108),
    "jardineira_vermelha": Vector2(67,108),
    "jardineira_amarela": Vector2(67,105),
    "jardineira_azul": Vector2(67,109),
    "jardineira_branca": Vector2(64,104),
    "jardineira_lavanda": Vector2(67,113),
    "jardineira_mista": Vector2(68,106),
    "jardineira_verde": Vector2(68,109),
}
var instancias: Array[Sprite2D] = []
var exibir_pivos := false

func _ready() -> void:
    z_as_relative = false
    for i in range(IDS.size()):
        var id: String = IDS[i]
        var caminho: String = RAIZ + id + ".png"
        if not ResourceLoader.exists(caminho):
            push_warning("Bairro Vivo 2.1: sprite ausente: " + caminho)
            continue
        var textura := load(caminho) as Texture2D
        if textura == null:
            continue
        var sprite := Sprite2D.new()
        sprite.name = id
        sprite.texture = textura
        sprite.centered = false
        sprite.offset = -PIVOS[id]
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        sprite.position = BAIRRO.ponto(Vector2(26 + i * 2, 11.2))
        sprite.z_index = clampi(int(sprite.position.y), -4096, 4096)
        add_child(sprite)
        instancias.append(sprite)
    queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F6:
        exibir_pivos = not exibir_pivos
        queue_redraw()

func _draw() -> void:
    if not exibir_pivos:
        return
    for sprite in instancias:
        draw_line(sprite.position + Vector2(-8,0),sprite.position + Vector2(8,0),Color.RED,2)
        draw_line(sprite.position + Vector2(0,-8),sprite.position + Vector2(0,8),Color.RED,2)
