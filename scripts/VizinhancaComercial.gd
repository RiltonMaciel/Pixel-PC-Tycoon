extends Node2D

const CATALOGO = preload("res://scripts/CatalogoVizinhanca.gd")
const VISUAL = preload("res://scripts/CatalogoPreviaVisual.gd")
const LOJAS := [
    {"id":"mercadinho","nome":"Mercadinho","uv":Vector2(29,10)},
    {"id":"farmacia","nome":"Farmacia","uv":Vector2(38,10)},
    {"id":"loja_roupas","nome":"Loja de roupas","uv":Vector2(47,10)},
    {"id":"restaurante","nome":"Restaurante","uv":Vector2(56,10)},
    {"id":"predio_comercial","nome":"Salas comerciais","uv":Vector2(65,10)}
]
var obstaculos: Array[PackedVector2Array] = []
var entradas: Array[Dictionary] = []
var objetos: Array[Sprite2D] = []
var fachadas: Array[Node2D] = []
var grid: Transform2D
var previa_visual := false
var construtor_fachada: Callable

func configurar(transformacao: Transform2D, criar_fachada: Callable) -> void:
    grid = transformacao
    construtor_fachada = criar_fachada
    for loja in LOJAS:
        var item: Dictionary = CATALOGO.ITENS[loja.id]
        fachadas.append(_criar_loja(loja))
        var origem: Vector2 = grid * loja.uv - item.pivo
        var poligono := PackedVector2Array()
        for at in [item.frente,item.canto,item.fundo,item.frente+item.fundo-item.canto]:
            poligono.append(origem+at)
        obstaculos.append(poligono)
        entradas.append({"nome":loja.nome,"posicao":grid*loja.uv+Vector2(0,28)})
    for u in [26,35,46,55,62]:
        _objeto("arvore_copa_redonda",Vector2(u,11),Vector2(18,12),0.9)
    for u in [10,25,37,51,63]:
        _objeto("arvore_florida",Vector2(u,25),Vector2(16,11),0.95)
    for u in [12,31,49,60]:
        _objeto("poste_iluminacao",Vector2(u,25.5),Vector2(12,9),0.8)
    for u in [15,34,53]:
        _objeto("banco_madeira",Vector2(u,24),Vector2(39,18),1,85)
        _objeto("lixeira_publica",Vector2(u+1.6,24),Vector2(20,13),1,70)
    for u in [16.4,19.5,40.4,43.5]:
        _objeto("balizador",Vector2(u,12.3),Vector2(10,8),1,52)
    _objeto("mesa_externa",Vector2(20.3,11.1),Vector2(35,20),1,65)
    _objeto("cadeira_externa",Vector2(19.6,11.1),Vector2(19,12),1,80)
    _objeto("cadeira_externa",Vector2(21.05,11.1),Vector2(19,12),1,80)
    _objeto("cardapio_cavalete",Vector2(24,11),Vector2(24,12),1,80)
    _objeto("caixa_frutas",Vector2(27,10.8),Vector2(35,18),0.45)
    _objeto("caixa_frutas",Vector2(28.1,10.8),Vector2(35,18),0.45)
    _objeto("jardineira_retangular",Vector2(36,11),Vector2(58,25),0.55)
    _objeto("canteiro_flores",Vector2(14,26),Vector2(58,25),0.55)
    _objeto("bicicleta",Vector2(32,24),Vector2(60,18),0.7)
    _objeto("compacto_azul_baixo_direita",Vector2(32,15),Vector2(110,42),0.9)
    _objeto("compacto_branco_cima_esquerda",Vector2(51,19),Vector2(110,42),0.9)
    _objeto("furgao_entregas_cima_esquerda",Vector2(12,19),Vector2(125,48),0.9)

func _objeto(id: String, uv: Vector2, base: Vector2, escala: float = 1.0, altura: float = 0.0) -> void:
    var item: Dictionary = CATALOGO.ITENS[id]
    if altura > 0:
        escala = altura / float(item.altura)
    var sprite := Sprite2D.new()
    sprite.name = id + "_" + str(objetos.size())
    sprite.texture = item.textura
    sprite.centered = false
    sprite.offset = -item.pivo
    sprite.position = grid * uv
    sprite.scale = Vector2.ONE * escala
    sprite.z_index = int(sprite.position.y)
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
    sprite.set_meta("catalogo_id",id)
    sprite.set_meta("escala_original",escala)
    add_child(sprite)
    objetos.append(sprite)
    obstaculos.append(PackedVector2Array([sprite.position+Vector2(-base.x,0),
        sprite.position+Vector2(0,-base.y),sprite.position+Vector2(base.x,0),
        sprite.position+Vector2(0,base.y)]))

func _criar_loja(loja: Dictionary) -> Node2D:
    var item := VISUAL.loja(loja.id,previa_visual)
    var textura: Texture2D = item.textura
    var grupo: Node2D = construtor_fachada.call(textura,grid*loja.uv-item.pivo,1.0,0,textura.get_width(),_base_predio.bind(item))
    grupo.reparent(self,false)
    grupo.name = loja.id
    return grupo

func definir_previa(ativa: bool) -> void:
    if previa_visual == ativa:
        return
    previa_visual = ativa
    for i in range(LOJAS.size()):
        var anterior := fachadas[i]
        remove_child(anterior)
        anterior.queue_free()
        fachadas[i] = _criar_loja(LOJAS[i])
    for sprite in objetos:
        var id: String = sprite.get_meta("catalogo_id")
        var item := VISUAL.veiculo(id,ativa)
        sprite.texture = item.textura
        sprite.offset = -item.pivo
        sprite.scale = Vector2.ONE * float(item.get("escala",sprite.get_meta("escala_original")))

func _base_predio(x: float, item: Dictionary) -> float:
    var a: Vector2 = item.frente if x < item.canto.x else item.canto
    var b: Vector2 = item.canto if x < item.canto.x else item.fundo
    return lerpf(a.y,b.y,clampf((x-a.x)/(b.x-a.x),0,1))

func piso_livre(at: Vector2) -> bool:
    for obstaculo in obstaculos:
        if Geometry2D.is_point_in_polygon(at,obstaculo):
            return false
    return true

func loja_proxima(at: Vector2) -> String:
    for entrada in entradas:
        if at.distance_to(entrada.posicao) < 85:
            return entrada.nome
    return ""
