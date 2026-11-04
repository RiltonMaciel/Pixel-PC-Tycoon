extends RefCounted

const PASSO := 12.0
var piso := PackedVector2Array()
var formas: Array[PackedVector2Array] = []
var limites: Array[Rect2] = []
var origem := Vector2.ZERO
var inicio := Vector2.ZERO
var pais: Dictionary = {}
var livres: Dictionary = {}

func configurar(dados: Dictionary, obstaculos: Array[PackedVector2Array], entrada: Vector2) -> void:
    piso = dados["piso_interno"]
    formas = obstaculos
    limites.clear()
    pais.clear()
    livres.clear()
    origem = piso[0]
    for ponto in piso:
        origem = origem.min(ponto)
    inicio = entrada
    for forma in formas:
        var rect := Rect2(forma[0],Vector2.ZERO)
        for ponto in forma:
            rect = rect.expand(ponto)
        limites.append(rect.grow(0.01))
    if not ponto_livre(inicio):
        return
    var proximo := Vector2i(((inicio - origem) / PASSO).round())
    var fila: Array[Vector2i] = []
    for x in range(-1,2):
        for y in range(-1,2):
            var celula := proximo + Vector2i(x,y)
            if _celula_livre(celula) and segmento_livre(inicio,_ponto(celula)):
                pais[celula] = celula
                fila.append(celula)
    var indice := 0
    while indice < fila.size():
        var atual := fila[indice]
        indice += 1
        for direcao in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
            var vizinho: Vector2i = atual + direcao
            if not pais.has(vizinho) and _celula_livre(vizinho) and segmento_livre(_ponto(atual),_ponto(vizinho)):
                pais[vizinho] = atual
                fila.append(vizinho)

func ponto_livre(at: Vector2) -> bool:
    for offset in [Vector2.ZERO,Vector2(10,0),Vector2(-10,0),Vector2(0,10),Vector2(0,-10)]:
        if not Geometry2D.is_point_in_polygon(at + offset,piso):
            return false
    for i in range(formas.size()):
        if limites[i].has_point(at) and Geometry2D.is_point_in_polygon(at,formas[i]):
            return false
    return true

func segmento_livre(de: Vector2, ate: Vector2) -> bool:
    var passos := maxi(1,ceili(de.distance_to(ate) / 4.0))
    for i in range(passos + 1):
        if not ponto_livre(de.lerp(ate,float(i) / passos)):
            return false
    return true

func caminho_ate(alvo: Vector2, alcance: float = 0.0) -> PackedVector2Array:
    var melhor := Vector2i.ZERO
    var distancia := INF
    var encontrado := false
    for celula: Vector2i in pais:
        var ponto := _ponto(celula)
        var d := ponto.distance_to(alvo)
        if d >= distancia:
            continue
        if (alcance > 0 and d <= alcance) or (alcance == 0 and d <= PASSO * 2 and segmento_livre(ponto,alvo)):
            melhor = celula
            distancia = d
            encontrado = true
    if not encontrado:
        return PackedVector2Array()
    var caminho := PackedVector2Array()
    var atual := melhor
    caminho.append(_ponto(atual))
    while pais[atual] != atual:
        atual = pais[atual]
        caminho.append(_ponto(atual))
    caminho.append(inicio)
    caminho.reverse()
    if alcance == 0:
        caminho.append(alvo)
    return caminho

func _ponto(celula: Vector2i) -> Vector2:
    return origem + Vector2(celula) * PASSO

func _celula_livre(celula: Vector2i) -> bool:
    if not livres.has(celula):
        livres[celula] = ponto_livre(_ponto(celula))
    return livres[celula]
