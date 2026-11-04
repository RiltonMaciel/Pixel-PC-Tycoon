extends Node2D
const VIZINHANCA = preload("res://scripts/VizinhancaComercial.gd")

const BASE := "res://Assets/Cenarios/Bairro/"
const ORIGEM := Vector2(1100,0)
# O exterior acompanha a fachada aprovada; o interior mantem seu grid 2:1.
const U := Vector2(64,20)
const V := Vector2(-64,32)
const TAMANHO := Vector2i(72,28)
const RUA_INICIO := 13
const RUA_FIM := 21
const TRAVESSIAS := [17,41,65]
const LOJA_ESCALA := 0.75
const LOJA_POS := ORIGEM + U * 7 + V * 10 - Vector2(234,640) * LOJA_ESCALA
const PORTA_LOCAL := Vector2(650,797)
const SPAWN_LOCAL := Vector2(650,817)
const BANCO_LOCAL := Vector2(163,622)
const POSTE_LOCAL := Vector2(245,743)
const PREDIO: Array[Vector2] = [Vector2(234,640),Vector2(990,870),Vector2(1465,648),Vector2(710,420)]
const BANCO: Array[Vector2] = [Vector2(89,589),Vector2(213,637),Vector2(239,609),Vector2(121,564)]
const OBSTACULOS: Array[Rect2] = [Rect2(474,700,78,47),Rect2(748,775,89,58),Rect2(935,875,71,68)]
const CALCADA := preload(BASE+"calcada_continua.png")
const ASFALTO := preload(BASE+"asfalto_continuo.png")
const CAFE_ESCALA := 0.68
const CAFE_FRENTE := Vector2(198,709.008)
const CAFE_CANTO := Vector2(762,885.258)
const CAFE_FUNDO := Vector2(1049,741.758)
const CAFE_PORTA := Vector2(652,846.258)
const CAFE_POS := ORIGEM + U * 19 + V * 10 - CAFE_FRENTE * CAFE_ESCALA
const CAFE_PREDIO: Array[Vector2] = [CAFE_FRENTE,CAFE_CANTO,CAFE_FUNDO,CAFE_FRENTE+CAFE_FUNDO-CAFE_CANTO]
var predio: Node2D
var cafeteria: Node2D
var banco: Sprite2D
var poste: Sprite2D
var vizinhanca: VIZINHANCA
var previa_visual := false

static func ponto(uv: Vector2) -> Vector2:
    return ORIGEM + U * uv.x + V * uv.y

static func local_loja(at: Vector2) -> Vector2:
    return LOJA_POS + at * LOJA_ESCALA

static func celula(at: Vector2) -> Vector2i:
    var grid := Transform2D(U,V,ORIGEM)
    return Vector2i((grid.affine_inverse() * at).floor())

static func rua(indice: int) -> bool:
    return indice >= RUA_INICIO and indice < RUA_FIM

static func faixa(uv: Vector2i) -> bool:
    if not rua(uv.y):
        return false
    for inicio in TRAVESSIAS:
        if uv.x >= inicio and uv.x < inicio + 2:
            return true
    return false

static func porta_cafe() -> Vector2:
    return CAFE_POS + CAFE_PORTA * CAFE_ESCALA

static func piso_livre(at: Vector2) -> bool:
    var uv := celula(at)
    if uv.x < 0 or uv.y < 0 or uv.x >= TAMANHO.x or uv.y >= TAMANHO.y:
        return false
    if rua(uv.y) and not faixa(uv):
        return false
    if Geometry2D.is_point_in_polygon((at-CAFE_POS)/CAFE_ESCALA,CAFE_PREDIO):
        return false
    var local := (at - LOJA_POS) / LOJA_ESCALA
    if Geometry2D.is_point_in_polygon(local,PREDIO) or Geometry2D.is_point_in_polygon(local,BANCO):
        return false
    for obstaculo in OBSTACULOS:
        if obstaculo.has_point(local):
            return false
    return local.distance_to(POSTE_LOCAL) > 22

static func rota_cliente() -> PackedVector2Array:
    return PackedVector2Array([ponto(Vector2(10,12)),ponto(Vector2(15,12)),
        ponto(Vector2(15,12.5)),ponto(Vector2(10,12.5))])

func _ready() -> void:
    texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    predio = _fachada(preload(BASE+"pc_store_recorte.png"),LOJA_POS,LOJA_ESCALA,224,1472,_base_fachada)
    cafeteria = _fachada(preload(BASE+"cafeteria.png"),CAFE_POS,CAFE_ESCALA,176,1072,_base_cafe)
    banco = _objeto(preload(BASE+"banco_recorte.png"),BANCO_LOCAL)
    poste = _objeto(preload(BASE+"poste_recorte.png"),POSTE_LOCAL)
    vizinhanca = VIZINHANCA.new()
    add_child(vizinhanca)
    vizinhanca.configurar(Transform2D(U,V,ORIGEM),_fachada)

func _draw() -> void:
    _piso(Rect2(0,0,TAMANHO.x,RUA_INICIO),Color.WHITE,CALCADA)
    _piso(Rect2(0,RUA_INICIO,TAMANHO.x,RUA_FIM-RUA_INICIO),Color.WHITE,ASFALTO)
    _piso(Rect2(0,RUA_FIM,TAMANHO.x,TAMANHO.y-RUA_FIM),Color.WHITE,CALCADA)
    _piso(Rect2(0,RUA_INICIO-0.16,TAMANHO.x,0.16),Color("#d3d0c3"))
    _piso(Rect2(0,RUA_INICIO,TAMANHO.x,0.08),Color("#313337"))
    _piso(Rect2(0,RUA_FIM,TAMANHO.x,0.16),Color("#d3d0c3"))
    for u in range(TAMANHO.x):
        if faixa(Vector2i(u,17)):
            continue
        _piso(Rect2(u+0.12,16.96,0.66,0.08),Color("#e2bd65"))
    for inicio in TRAVESSIAS:
        for stripe in range(12):
            _piso(Rect2(inicio+0.12,RUA_INICIO+0.15+stripe*(RUA_FIM-RUA_INICIO)/12.0,1.76,0.35),Color("#e8e5d7"))
    for u in [10,34,58]:
        _seta(Vector2(u,15),1)
        _seta(Vector2(u,19),-1)
    _detalhes_rua()
    if previa_visual:
        _acabamento_calcadas()

func definir_previa(ativa: bool) -> void:
    previa_visual = ativa
    vizinhanca.definir_previa(ativa)
    queue_redraw()


# Acabamento urbano discreto, desenhado sobre o mapa existente.
# Nao altera malha de colisao, faixas de travessia ou sprites aprovados.
func _detalhes_rua() -> void:
    # Guias: borda clara e sombra do desnivel junto ao asfalto.
    _piso(Rect2(0,RUA_INICIO-0.08,TAMANHO.x,0.08),Color("#aaa69b"))
    _piso(Rect2(0,RUA_FIM-0.06,TAMANHO.x,0.06),Color("#4b4b4a"))
    # Juntas sutis das placas da calcada, sem criar uma grade de losangos.
    for u in range(0,TAMANHO.x,2):
        for v in [RUA_INICIO-0.95,RUA_FIM+0.65]:
            _piso(Rect2(u+0.04,v,0.025,0.60),Color("#8e8e8b",0.38))
    # Drenos junto ao meio-fio, longe das travessias.
    for u in [7,29,53,70]:
        for v in [RUA_INICIO+0.22,RUA_FIM-0.45]:
            _piso(Rect2(u,v,0.66,0.26),Color("#34373a"))
            for i in range(4):
                _piso(Rect2(u+0.09+i*0.14,v+0.035,0.045,0.18),Color("#737779"))
    # Piso tatil nos dois lados de cada travessia.
    for inicio in TRAVESSIAS:
        for v in [RUA_INICIO-0.44,RUA_FIM+0.17]:
            _piso(Rect2(inicio+0.12,v,1.76,0.20),Color("#c9a54d"))
            for i in range(9):
                _piso(Rect2(inicio+0.18+i*0.19,v+0.06,0.075,0.06),Color("#edcf77"))

func _acabamento_calcadas() -> void:
    for v in [RUA_INICIO-0.42,RUA_FIM+0.28]:
        _piso(Rect2(0,v,TAMANHO.x,0.12),Color("#cba653"))
        for u in range(TAMANHO.x):
            _piso(Rect2(u+0.08,v+0.035,0.80,0.025),Color("#e2bd65"))
    for v in [RUA_INICIO-0.16,RUA_FIM]:
        for u in range(TAMANHO.x):
            _piso(Rect2(u+0.97,v,0.025,0.16),Color("#8c8a83"))
    for inicio in TRAVESSIAS:
        for v in [RUA_INICIO-0.28,RUA_FIM+0.16]:
            _piso(Rect2(inicio+0.12,v,1.76,0.12),Color("#dfba66"))

func _piso(rect: Rect2, cor: Color, textura: Texture2D = null) -> void:
    var grid := PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),
        rect.end,rect.position+Vector2(0,rect.size.y)])
    var pontos := PackedVector2Array()
    var uv := PackedVector2Array()
    for at in grid:
        pontos.append(ponto(at))
        uv.append(at / (8.0 if textura == ASFALTO else 4.0))
    draw_polygon(pontos,PackedColorArray([cor]),uv,textura)

func _seta(at: Vector2, sentido: float) -> void:
    var vertices := PackedVector2Array()
    for offset in [Vector2(-0.65,-0.10),Vector2(0.1,-0.10),Vector2(0.1,-0.4),
            Vector2(0.7,0),Vector2(0.1,0.4),Vector2(0.1,0.10),Vector2(-0.65,0.10)]:
        vertices.append(ponto(at+Vector2(offset.x*sentido,offset.y)))
    draw_colored_polygon(vertices,Color("#bdbdb7"))

func _fachada(textura: Texture2D, origem: Vector2, escala: float, inicio: int, fim: int, base: Callable) -> Node2D:
    var grupo := Node2D.new()
    add_child(grupo)
    # Cada faixa vertical usa a profundidade da base da fachada, nao a do telhado.
    for x in range(inicio,fim,16):
        var parte := Sprite2D.new()
        parte.texture = textura
        parte.region_enabled = true
        parte.region_rect = Rect2(x,0,mini(16,fim-x),textura.get_height())
        parte.centered = false
        parte.position = origem + Vector2(x,0) * escala
        parte.scale = Vector2.ONE * escala
        parte.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        parte.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
        parte.z_index = int(origem.y + float(base.call(x+8)) * escala)
        grupo.add_child(parte)
    return grupo

func _base_cafe(x: float) -> float:
    if x < CAFE_CANTO.x:
        return lerpf(CAFE_FRENTE.y,CAFE_CANTO.y,clampf((x-CAFE_FRENTE.x)/(CAFE_CANTO.x-CAFE_FRENTE.x),0,1))
    return lerpf(CAFE_CANTO.y,CAFE_FUNDO.y,clampf((x-CAFE_CANTO.x)/(CAFE_FUNDO.x-CAFE_CANTO.x),0,1))

func _objeto(textura: Texture2D, base: Vector2) -> Sprite2D:
    var sprite := Sprite2D.new()
    sprite.texture = textura
    sprite.centered = false
    sprite.position = LOJA_POS
    sprite.scale = Vector2.ONE * LOJA_ESCALA
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.z_index = int(local_loja(base).y)
    add_child(sprite)
    return sprite

func _base_fachada(x: float) -> float:
    for obstaculo in OBSTACULOS:
        if x >= obstaculo.position.x and x <= obstaculo.end.x:
            return obstaculo.end.y
    if x < 990:
        return lerpf(640,870,clampf((x-234)/756,0,1))
    return lerpf(870,648,clampf((x-990)/475,0,1))

static func limites() -> Rect2:
    return Rect2(ORIGEM + Vector2(-TAMANHO.y*64,-128),
        Vector2((TAMANHO.x+TAMANHO.y)*64,TAMANHO.x*U.y+TAMANHO.y*V.y+256))
