extends RefCounted

var camera: Camera2D
var limites := Rect2()
var tela := Vector2.ZERO
var zoom_base := 1.0
var posicao_base := Vector2.ZERO
var toques: Dictionary = {}
var origens: Dictionary = {}
var livre := false
var arrastando := false

func configurar(cam: Camera2D, area: Rect2, tamanho: Vector2) -> void:
    camera = cam
    limites = area
    tela = tamanho
    zoom_base = cam.zoom.x
    posicao_base = cam.position
    livre = false
    limpar()

func limpar() -> void:
    toques.clear()
    origens.clear()
    arrastando = false

func pressionar(indice: int, ponto: Vector2) -> void:
    toques[indice] = ponto
    origens[indice] = ponto
    if toques.size() > 1:
        arrastando = true

func soltar(indice: int) -> void:
    toques.erase(indice)
    origens.erase(indice)
    if toques.is_empty():
        arrastando = false

func mover(indice: int, ponto: Vector2) -> bool:
    if not toques.has(indice) or camera == null:
        return false
    var anterior: Vector2 = toques[indice]
    if toques.size() >= 2:
        var ids := toques.keys()
        var a: Vector2 = toques[ids[0]]
        var b: Vector2 = toques[ids[1]]
        toques[indice] = ponto
        var novo_a: Vector2 = toques[ids[0]]
        var novo_b: Vector2 = toques[ids[1]]
        var distancia := a.distance_to(b)
        if distancia > 1:
            ampliar(novo_a.distance_to(novo_b) / distancia,(a+b)*0.5,(novo_a+novo_b)*0.5)
        return true
    toques[indice] = ponto
    if not arrastando:
        if ponto.distance_to(origens[indice]) < 8:
            return false
        anterior = origens[indice]
        arrastando = true
    deslocar(ponto - anterior)
    return true

func deslocar(delta: Vector2) -> void:
    camera.position -= delta / camera.zoom
    livre = true
    _conter()

func ampliar(fator: float, ancora: Vector2, nova_ancora: Vector2) -> void:
    if camera == null or not is_finite(fator) or fator <= 0:
        push_warning("Fator de zoom invalido; camera preservada.")
        return
    var anterior := camera.zoom.x
    var novo := clampf(anterior * fator,zoom_base * 0.75,zoom_base * 4.0)
    camera.position += (ancora - tela*0.5) / anterior - (nova_ancora - tela*0.5) / novo
    camera.zoom = Vector2.ONE * novo
    livre = true
    _conter()

func _conter() -> void:
    camera.position = camera.position.clamp(limites.position - Vector2.ONE*96,limites.end + Vector2.ONE*96)
    camera.force_update_scroll()

func recentralizar() -> void:
    if camera == null:
        return
    camera.zoom = Vector2.ONE * zoom_base
    camera.position = posicao_base
    camera.force_update_scroll()
    livre = false
    limpar()
