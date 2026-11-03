extends Node2D
## Anima recortes da propria fachada; nao sobrepoe a porta SVG de outro predio.
const QUAD: Array[Vector2] = [Vector2(584,539),Vector2(744,590),Vector2(744,765),Vector2(584,715)]
var tween_abertura: Tween
var esquerda: Polygon2D
var direita: Polygon2D
var abertura: float = 0.0:
    set(valor):
        abertura = valor
        _atualizar()

func _ready() -> void:
    var vao := Polygon2D.new()
    vao.polygon = QUAD
    vao.color = Color("#15202c")
    add_child(vao)
    var textura := preload("res://Assets/Cenarios/Exterior/PC_Store_Com_Telhado.png")
    esquerda = Polygon2D.new()
    direita = Polygon2D.new()
    var meio_topo := (QUAD[0] + QUAD[1]) * 0.5
    var meio_base := (QUAD[2] + QUAD[3]) * 0.5
    esquerda.uv = PackedVector2Array([QUAD[0],meio_topo,meio_base,QUAD[3]])
    direita.uv = PackedVector2Array([meio_topo,QUAD[1],QUAD[2],meio_base])
    for folha in [esquerda, direita]:
        folha.texture = textura
        folha.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        add_child(folha)
    _atualizar()
    visible = false

func _atualizar() -> void:
    if esquerda == null:
        return
    var fator := abertura * 0.88
    var topo := (QUAD[0] + QUAD[1]) * 0.5
    var base := (QUAD[2] + QUAD[3]) * 0.5
    esquerda.polygon = PackedVector2Array([QUAD[0],topo.lerp(QUAD[0],fator),base.lerp(QUAD[3],fator),QUAD[3]])
    direita.polygon = PackedVector2Array([topo.lerp(QUAD[1],fator),QUAD[1],QUAD[2],base.lerp(QUAD[2],fator)])

func animar(abrir: bool) -> void:
    # Uma segunda interacao nao pode deixar dois tweens disputando as folhas.
    if tween_abertura != null and tween_abertura.is_running():
        tween_abertura.kill()
    visible = true
    abertura = 0.0 if abrir else 1.0
    tween_abertura = create_tween()
    tween_abertura.set_trans(Tween.TRANS_SINE)
    tween_abertura.set_ease(Tween.EASE_IN_OUT)
    tween_abertura.tween_property(self, "abertura", 1.0 if abrir else 0.0, 0.35)
    await tween_abertura.finished
    if not abrir:
        visible = false
