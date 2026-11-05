extends Node2D
## Simulacao exclusivamente manual: o controlador chama avancar, nao ha _process.
## Coordenadas das rotas sao locais ao bairro; este no deve compartilhar seu transform.
## configurar aceita BairroComercial pronto ou Dictionary com grid: Transform2D,
## tamanho: Vector2i, rua_inicio/fim: int, travessias: Array[int],
## obstaculos: Array[PackedVector2Array], piso_livre: Callable opcional,
## lojas: Array[{id: String, posicao: Vector2}], rotas_pedestres/rotas_trafego:
## Array[{pontos: PackedVector2Array, loja: String opcional}].
## Rotas omitidas sao derivadas; arrays vazios desabilitam aquele fluxo.
## BairroComercial fornece pc_store_001 e acesso caminhavel cadastrado de pc_store_002.
## IDs comerciais fornecidos sao preservados; lojas vizinhas mantem seus IDs proprios.
## Poligonos sao a garantia exata de colisao; Callable adicional e amostrado a 4px.
## A geometria e imutavel ate a proxima configurar. Nao altera economia nem o bairro.

signal pedestre_chegou_loja(pedestre_id: int, loja_id: String, posicao: Vector2)
## Evento adicional: nao altera o sinal legado nem dispara vendas automaticamente.
signal pedestre_avaliou_loja(pedestre_id: int, loja_id: String, decisao: String, pontuacao: float)

const BAIRRO = preload("res://scripts/BairroComercial.gd")
const IMOVEIS = preload("res://scripts/Imoveis/CatalogoImoveis.gd")
const CATALOGO = preload("res://scripts/CatalogoVizinhanca.gd")
const VISUAL = preload("res://scripts/CatalogoPreviaVisual.gd")
const PERSONAGEM = preload("res://scripts/PersonagemAnimado.gd")
const CALENDARIO = preload("res://scripts/CalendarioEconomia.gd")
const INTERESSE = preload("res://scripts/Neighborhood/NPCInteresse.gd")
const MAX_PEDESTRES := 32
const MAX_VEICULOS := 8
const ESPACO_PEDESTRE := 44.0
const ESPACO_VEICULO := 270.0
const PASSO_MAXIMO := 0.25
const PERSONAGENS := ["cliente_estudante", "cliente_mochila", "tecnico"]

@export_range(0, 32) var limite_pedestres := 18
@export_range(0, 8) var limite_veiculos := 4
@export var velocidade_pedestre := 48.0
@export var velocidade_veiculo := 115.0

var ultimo_erro := ""
var _grid := Transform2D.IDENTITY
var _inversa := Transform2D.IDENTITY
var _tamanho := Vector2i(72, 28)
var _rua_inicio := 13
var _rua_fim := 21
var _travessias: Array = [17, 41, 65]
var _obstaculos: Array[Dictionary] = []
var _piso_livre := Callable()
var _lojas: Array = []
var _rotas_pedestres: Array[Dictionary] = []
var _rotas_trafego: Array[Dictionary] = []
var _atores: Array[Dictionary] = []
var _suspenso := false
var _configurado := false
var _sequencia := 0
var _tempo_simulacao := 0.0
var _turno_pedestre := 0
var _turno_trafego := 0
var previa_visual := VISUAL.PADRAO

func definir_previa(ativa: bool) -> void:
    previa_visual = ativa
    for ator in _atores:
        if ator.trafego:
            _visual_veiculo(ator)

func _visual_veiculo(ator: Dictionary) -> void:
    var item := VISUAL.veiculo(ator.veiculo_id,previa_visual)
    ator.no.texture = item.textura
    ator.no.offset = -item.pivo
    ator.no.scale = Vector2.ONE * float(item.get("escala",0.65))

func configurar(bairro_ou_dados: Variant) -> bool:
    _limpar()
    ultimo_erro = ""
    var dados: Dictionary
    if bairro_ou_dados is BAIRRO:
        if not is_instance_valid(bairro_ou_dados.vizinhanca):
            return _erro("Bairro precisa estar pronto, com vizinhanca configurada.")
        dados = _dados_bairro(bairro_ou_dados)
    elif bairro_ou_dados is Dictionary:
        dados = bairro_ou_dados
    else:
        return _erro("Forneca BairroComercial ou Dictionary.")
    _grid = dados.get("grid", Transform2D(BAIRRO.U, BAIRRO.V, BAIRRO.ORIGEM))
    _tamanho = dados.get("tamanho", BAIRRO.TAMANHO)
    _rua_inicio = dados.get("rua_inicio", BAIRRO.RUA_INICIO)
    _rua_fim = dados.get("rua_fim", BAIRRO.RUA_FIM)
    _travessias = dados.get("travessias", BAIRRO.TRAVESSIAS).duplicate()
    if not _grid.x.is_finite() or not _grid.y.is_finite() or not _grid.origin.is_finite() \
            or absf(_grid.determinant()) < 0.001:
        return _erro("Grid invalido.")
    if _tamanho.x < 2 or _tamanho.y < 3 or _tamanho.x > 128 or _tamanho.y > 64 \
            or _rua_inicio < 1 or _rua_fim <= _rua_inicio or _rua_fim >= _tamanho.y:
        return _erro("Limites invalidos.")
    _inversa = _grid.affine_inverse()
    _piso_livre = dados.get("piso_livre", Callable())
    _lojas = dados.get("lojas", []).duplicate(true)
    for poligono in dados.get("obstaculos", []):
        if poligono.size() < 3:
            return _erro("Obstaculo precisa de pelo menos tres vertices.")
        var caixa := Rect2(poligono[0], Vector2.ZERO)
        for ponto: Vector2 in poligono:
            if not ponto.is_finite():
                return _erro("Obstaculo nao finito.")
            caixa = caixa.expand(ponto)
        _obstaculos.append({"poligono": PackedVector2Array(poligono), "caixa": caixa.grow(0.01)})
    if bairro_ou_dados is BAIRRO:
        var imovel := IMOVEIS.buscar("pc_store_002")
        for chave in ["porta_externa", "saida_externa"]:
            var acesso: Vector2 = imovel[chave]
            if ponto_valido(acesso):
                _lojas.append({"id": "pc_store_002", "posicao": acesso})
                break
    for loja in _lojas:
        if not loja.has("id") or not loja.get("posicao", Vector2(INF, INF)).is_finite():
            return _erro("Loja invalida.")
    _rotas_pedestres = _ler_rotas(dados.get("rotas_pedestres", []), false)
    _rotas_trafego = _ler_rotas(dados.get("rotas_trafego", []), true)
    if not ultimo_erro.is_empty():
        return false
    if not dados.has("rotas_pedestres"):
        _derivar_pedestres()
    if not dados.has("rotas_trafego"):
        _derivar_trafego()
    _configurado = true
    return true

func definir_suspensao(interior: bool, construcao: bool, app_pausado: bool) -> void:
    _suspenso = interior or construcao or app_pausado

## delta e tempo real de simulacao; segundos_do_dia segue o dia de 900s do calendario.
## clima_evento aceita "Chuva" ou {clima, evento}, como Ambiente.previsao.
## Strings ignoram caixa/espacos externos; demanda e metadado comercial, nao reaplicado.
## Grandes deltas descartam excesso (nao fazem catch-up), mantendo percurso continuo.
func avancar(delta: float, segundos_do_dia: float, clima_evento: Variant = {}) -> void:
    if not _configurado or _suspenso or (is_inside_tree() and get_tree().paused):
        return
    if not is_finite(delta) or delta <= 0 or not is_finite(segundos_do_dia):
        return
    var dt := minf(delta, PASSO_MAXIMO)
    _tempo_simulacao += dt
    var metas := densidade(segundos_do_dia, clima_evento)
    var eventos: Array[Dictionary] = []
    for trafego in [false, true]:
        var meta := int(metas.veiculos if trafego else metas.pedestres)
        var ativos := 0
        for ator in _atores:
            if ator.trafego == trafego and ator.ativo:
                ativos += 1
                if ativos > meta:
                    _desativar(ator)
        ativos = mini(ativos, meta)
        while ativos < meta and _ativar(trafego):
            ativos += 1
    for ator in _atores:
        if not ator.ativo:
            continue
        var velocidade := velocidade_veiculo if ator.trafego else velocidade_pedestre
        if not is_finite(velocidade):
            continue
        var distancia := clampf(velocidade, 0, 240) * dt
        if ator.trafego:
            distancia = _distancia_trafego(ator,distancia)
        var movimento := Vector2.ZERO
        var rota: PackedVector2Array = ator.rota.pontos
        while distancia > 0 and ator.indice < rota.size():
            var destino := rota[ator.indice]
            var deslocamento: Vector2 = destino - ator.no.position
            var trecho := deslocamento.length()
            if trecho <= distancia:
                ator.no.position = destino
                distancia -= trecho
                ator.indice += 1
            else:
                ator.no.position += deslocamento / trecho * distancia
                distancia = 0
            if trecho > 0.001:
                movimento = deslocamento
        if not ator.trafego:
            ator.no.atualizar(movimento, dt)
        ator.no.z_index = clampi(int(ator.no.position.y), -4096, 4096)
        if ator.indice >= rota.size():
            if not ator.trafego and not ator.rota.get("loja", "").is_empty():
                var avaliacao: Dictionary = INTERESSE.avaliar(ator.perfil, ator.rota.loja, _tempo_simulacao)
                if avaliacao.decisao != "continuar":
                    INTERESSE.registrar_visita(ator.perfil, ator.rota.loja, _tempo_simulacao)
                eventos.append({"id": ator.id, "loja": ator.rota.loja, "posicao": ator.no.position,
                    "decisao": avaliacao.decisao, "pontuacao": avaliacao.pontuacao})
            _desativar(ator)
    for evento in eventos:
        pedestre_chegou_loja.emit(evento.id, evento.loja, evento.posicao)
        pedestre_avaliou_loja.emit(evento.id, evento.loja, evento.decisao, evento.pontuacao)

func densidade(segundos_do_dia: float, clima_evento: Variant = {}) -> Dictionary:
    if not is_finite(segundos_do_dia):
        return {"pedestres": 0, "veiculos": 0}
    var hora := fposmod(segundos_do_dia, CALENDARIO.SEGUNDOS_DIA) * 24 / CALENDARIO.SEGUNDOS_DIA
    var fator := 1.0 if hora >= 8 and hora < 19 else 0.5 if hora >= 6 and hora < 22 else 0.15
    var clima := str(clima_evento.get("clima", "")) if clima_evento is Dictionary else str(clima_evento)
    var evento := str(clima_evento.get("evento", "")) if clima_evento is Dictionary else ""
    clima = clima.strip_edges().to_lower()
    evento = evento.strip_edges().to_lower()
    if clima == "chuva":
        fator *= 0.55
    if evento == "feira de tecnologia":
        fator *= 1.35
    elif evento == "dia tranquilo":
        fator *= 0.75
    return {
        "pedestres": mini(clampi(limite_pedestres, 0, MAX_PEDESTRES), int(ceil(clampi(limite_pedestres, 0, MAX_PEDESTRES) * fator))),
        "veiculos": mini(clampi(limite_veiculos, 0, MAX_VEICULOS), int(ceil(clampi(limite_veiculos, 0, MAX_VEICULOS) * fator)))
    }

## Copias para diagnostico/testes; nunca expor referencias mutaveis da simulacao.
func estado() -> Dictionary:
    var atores: Array[Dictionary] = []
    for ator in _atores:
        if ator.ativo:
            atores.append({"id": ator.id, "trafego": ator.trafego, "posicao": ator.no.position,
                "indice": ator.indice, "rota": ator.rota.duplicate(true)})
    return {"atores": atores, "nos": _atores.size(), "configurado": _configurado,
        "rotas_pedestres": _rotas_pedestres.duplicate(true), "rotas_trafego": _rotas_trafego.duplicate(true)}

func ponto_valido(ponto: Vector2, trafego: bool = false) -> bool:
    if not ponto.is_finite():
        return false
    var uv := _inversa * ponto
    if uv.x < 0 or uv.y < 0 or uv.x >= _tamanho.x or uv.y >= _tamanho.y:
        return false
    var asfalto := uv.y >= _rua_inicio and uv.y < _rua_fim
    if trafego:
        if not asfalto:
            return false
    elif asfalto:
        var faixa := false
        for inicio in _travessias:
            if uv.x >= inicio and uv.x < inicio + 2:
                faixa = true
        if not faixa:
            return false
    for obstaculo in _obstaculos:
        if obstaculo.caixa.has_point(ponto) and Geometry2D.is_point_in_polygon(ponto, obstaculo.poligono):
            return false
    return not _piso_livre.is_valid() or bool(_piso_livre.call(ponto))

func segmento_valido(a: Vector2, b: Vector2, trafego: bool = false) -> bool:
    if not ponto_valido(a, trafego) or not ponto_valido(b, trafego):
        return false
    var uv_a := _inversa * a
    var uv_b := _inversa * b
    if trafego:
        var direcao := uv_b - uv_a
        var meio := (_rua_inicio + _rua_fim) * 0.5
        if absf(direcao.y) > 0.001 or absf(direcao.x) < 0.001 \
                or (uv_a.y < meio and direcao.x < 0) or (uv_a.y >= meio and direcao.x > 0):
            return false
    else:
        # Dividir nas bordas do asfalto/faixas evita saltar intervalos estreitos.
        var cortes: Array[float] = [0.0, 1.0]
        if absf(uv_b.y - uv_a.y) > 0.00001:
            for y in [_rua_inicio, _rua_fim]:
                var t: float = (y - uv_a.y) / (uv_b.y - uv_a.y)
                if t > 0 and t < 1:
                    cortes.append(t)
        if absf(uv_b.x - uv_a.x) > 0.00001:
            for inicio in _travessias:
                for x in [inicio, inicio + 2]:
                    var t: float = (x - uv_a.x) / (uv_b.x - uv_a.x)
                    if t > 0 and t < 1:
                        cortes.append(t)
        cortes.sort()
        for i in range(1, cortes.size()):
            if not ponto_valido(a.lerp(b, (cortes[i - 1] + cortes[i]) * 0.5)):
                return false
    var caixa := Rect2(a, Vector2.ZERO).expand(b).grow(0.01)
    for obstaculo in _obstaculos:
        if not caixa.intersects(obstaculo.caixa):
            continue
        var poligono: PackedVector2Array = obstaculo.poligono
        for i in range(poligono.size()):
            if Geometry2D.segment_intersects_segment(a, b, poligono[i], poligono[(i + 1) % poligono.size()]) != null:
                return false
    var passos := maxi(1, int(ceil(a.distance_to(b) / 4.0)))
    if passos > 16384:
        return false
    for i in range(1, passos):
        if not ponto_valido(a.lerp(b, float(i) / passos), trafego):
            return false
    return true

func _ler_rotas(rotas: Array, trafego: bool) -> Array[Dictionary]:
    var resultado: Array[Dictionary] = []
    for rota in rotas:
        var pontos := PackedVector2Array(rota.get("pontos", []))
        if pontos.size() < 2 or pontos.size() > 4096:
            _erro("Rota deve ter de 2 a 4096 pontos.")
            return []
        for i in range(1, pontos.size()):
            if pontos[i - 1].distance_to(pontos[i]) < 0.01 or not segmento_valido(pontos[i - 1], pontos[i], trafego):
                _erro("Rota atravessa piso proibido, obstaculo ou faixa de trafego invalida.")
                return []
        var loja := str(rota.get("loja", ""))
        if not loja.is_empty():
            var encontrada := false
            for entrada in _lojas:
                if str(entrada.id) == loja and pontos[-1].distance_to(entrada.posicao) < 1:
                    encontrada = true
            if trafego or not encontrada:
                _erro("Destino comercial precisa coincidir com entrada declarada.")
                return []
        resultado.append({"pontos": pontos, "loja": loja})
    return resultado

func _derivar_pedestres() -> void:
    var grafo := AStar2D.new()
    for y in range(_tamanho.y):
        for x in range(_tamanho.x):
            var ponto := _grid * Vector2(x + 0.5, y + 0.5)
            if ponto_valido(ponto):
                grafo.add_point(y * _tamanho.x + x, ponto)
    for id in grafo.get_point_ids():
        for vizinho in [id + 1 if id % _tamanho.x < _tamanho.x - 1 else -1, id + _tamanho.x]:
            if grafo.has_point(vizinho) and segmento_valido(grafo.get_point_position(id), grafo.get_point_position(vizinho)):
                grafo.connect_points(id, vizinho)
    var portais: Array[int] = []
    for y in [_rua_inicio - 1, _rua_fim + 1]:
        for x in [0, _tamanho.x - 1]:
            var id: int = y * _tamanho.x + x
            if grafo.has_point(id):
                portais.append(id)
    for origem in portais:
        for destino in portais:
            if origem == destino:
                continue
            var pontos := grafo.get_point_path(origem, destino)
            if pontos.size() > 1:
                _rotas_pedestres.append({"pontos": pontos, "loja": ""})
        for entrada in _lojas:
            if not ponto_valido(entrada.posicao):
                continue
            var destino := grafo.get_closest_point(entrada.posicao)
            if destino < 0 or not segmento_valido(grafo.get_point_position(destino), entrada.posicao):
                continue
            var pontos := grafo.get_point_path(origem, destino)
            if pontos.size() > 1:
                if pontos[-1].distance_to(entrada.posicao) > 0.01:
                    pontos.append(entrada.posicao)
                _rotas_pedestres.append({"pontos": pontos, "loja": str(entrada.id)})

func _derivar_trafego() -> void:
    var largura := float(_rua_fim - _rua_inicio)
    for faixa in [0, 1]:
        var y := _rua_inicio + largura * (0.25 if faixa == 0 else 0.75)
        var trecho := PackedVector2Array()
        for i in range(_tamanho.x * 2):
            var x := 0.25 + i * 0.5
            if faixa == 1:
                x = _tamanho.x - x
            var ponto := _grid * Vector2(x, y)
            if _corredor_veiculo_livre(ponto) and (trecho.is_empty() or segmento_valido(trecho[-1], ponto, true)):
                trecho.append(ponto)
            else:
                _guardar_faixa(trecho)
                trecho = PackedVector2Array()
        _guardar_faixa(trecho)

func _guardar_faixa(pontos: PackedVector2Array) -> void:
    if pontos.size() > 3:
        _rotas_trafego.append({"pontos": pontos, "loja": ""})

func _corredor_veiculo_livre(posicao: Vector2) -> bool:
    var frente := _grid.x.normalized()*145
    var lateral := Vector2(-frente.y,frente.x).normalized()*45
    var carroceria := PackedVector2Array([posicao-frente-lateral,posicao+frente-lateral,
        posicao+frente+lateral,posicao-frente+lateral])
    var caixa := Rect2(carroceria[0],Vector2.ZERO)
    for ponto in carroceria:
        if not ponto_valido(ponto,true):
            return false
        caixa = caixa.expand(ponto)
    for obstaculo in _obstaculos:
        if caixa.intersects(obstaculo.caixa) and not Geometry2D.intersect_polygons(carroceria,obstaculo.poligono).is_empty():
            return false
    return true

func _ativar(trafego: bool) -> bool:
    var rotas := _rotas_trafego if trafego else _rotas_pedestres
    if rotas.is_empty():
        return false
    var turno := _turno_trafego if trafego else _turno_pedestre
    var indice_rota := -1
    for tentativa in range(rotas.size()):
        var indice: int = (turno+tentativa) % rotas.size()
        if _nascimento_livre(rotas[indice].pontos[0],trafego):
            indice_rota = indice
            break
    if indice_rota < 0:
        return false
    var ator: Dictionary = {}
    var quantidade := 0
    for existente in _atores:
        if existente.trafego == trafego:
            quantidade += 1
            if not existente.ativo:
                ator = existente
    if ator.is_empty():
        if quantidade >= (MAX_VEICULOS if trafego else MAX_PEDESTRES):
            return false
        var no: Sprite2D
        if trafego:
            no = Sprite2D.new()
            no.centered = false
            no.scale = Vector2.ONE * 0.65
        else:
            no = PERSONAGEM.new()
            no.configurar(PERSONAGENS[quantidade % PERSONAGENS.size()])
        no.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        no.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
        add_child(no)
        ator = {"no": no, "trafego": trafego, "ativo": false}
        _atores.append(ator)
    ator.rota = rotas[indice_rota]
    if trafego:
        _turno_trafego = indice_rota+1
        var movimento: Vector2 = ator.rota.pontos[1] - ator.rota.pontos[0]
        var id := "compacto_azul_baixo_direita" if (_inversa.basis_xform(movimento)).x > 0 else "compacto_branco_cima_esquerda"
        ator.veiculo_id = id
        _visual_veiculo(ator)
    else:
        _turno_pedestre = indice_rota+1
    _sequencia += 1
    ator.id = _sequencia
    if not trafego:
        # O no pode ser reutilizado, mas o perfil pertence ao novo pedestre.
        ator.perfil = INTERESSE.perfil(_sequencia)
    ator.indice = 1
    ator.ativo = true
    ator.no.position = ator.rota.pontos[0]
    ator.no.visible = true
    return true

func _nascimento_livre(posicao: Vector2, trafego: bool) -> bool:
    var espaco := ESPACO_VEICULO if trafego else ESPACO_PEDESTRE
    for outro in _atores:
        if outro.ativo and outro.trafego == trafego and posicao.distance_to(outro.no.position) < espaco:
            return false
    return true

func _distancia_trafego(ator: Dictionary, desejada: float) -> float:
    var destino: Vector2 = ator.rota.pontos[ator.indice]
    var frente: Vector2 = (destino-ator.no.position).normalized()
    var permitida := desejada
    for outro in _atores:
        if not outro.ativo or outro.id == ator.id:
            continue
        var uv: Vector2 = _inversa * outro.no.position
        if not outro.trafego and (uv.y < _rua_inicio or uv.y >= _rua_fim):
            continue
        var relativo: Vector2 = outro.no.position-ator.no.position
        var adiante := relativo.dot(frente)
        if adiante <= 0 or absf(relativo.cross(frente)) >= 70:
            continue
        var espaco := ESPACO_VEICULO if outro.trafego else 160.0
        permitida = minf(permitida,maxf(0,adiante-espaco))
    return permitida

func _desativar(ator: Dictionary) -> void:
    ator.ativo = false
    ator.no.visible = false

func _limpar() -> void:
    _configurado = false
    for ator in _atores:
        ator.no.free()
    _atores.clear()
    _obstaculos.clear()
    _rotas_pedestres.clear()
    _rotas_trafego.clear()
    _turno_pedestre = 0
    _turno_trafego = 0
    _tempo_simulacao = 0.0

func _erro(mensagem: String) -> bool:
    ultimo_erro = mensagem
    return false

func _dados_bairro(bairro: Node2D) -> Dictionary:
    var obstaculos: Array = bairro.vizinhanca.obstaculos.duplicate(true)
    for dados in [
        [BAIRRO.PREDIO, BAIRRO.LOJA_POS, BAIRRO.LOJA_ESCALA],
        [BAIRRO.BANCO, BAIRRO.LOJA_POS, BAIRRO.LOJA_ESCALA],
        [BAIRRO.CAFE_PREDIO, BAIRRO.CAFE_POS, BAIRRO.CAFE_ESCALA]
    ]:
        var poligono := PackedVector2Array()
        for ponto: Vector2 in dados[0]:
            poligono.append(dados[1] + ponto * dados[2])
        obstaculos.append(poligono)
    var caixas: Array[Rect2] = BAIRRO.OBSTACULOS.duplicate()
    caixas.append(Rect2(BAIRRO.POSTE_LOCAL - Vector2(22, 22), Vector2(44, 44)))
    for caixa in caixas:
        var poligono := PackedVector2Array()
        for ponto in [caixa.position, caixa.position + Vector2(caixa.size.x, 0), caixa.end, caixa.position + Vector2(0, caixa.size.y)]:
            poligono.append(BAIRRO.local_loja(ponto))
        obstaculos.append(poligono)
    var lojas: Array = [
        {"id": "pc_store_001", "posicao": BAIRRO.local_loja(BAIRRO.SPAWN_LOCAL)},
        {"id": "cafeteria", "posicao": BAIRRO.porta_cafe() + Vector2(0, 12)}
    ]
    for i in range(bairro.vizinhanca.entradas.size()):
        lojas.append({"id": bairro.vizinhanca.LOJAS[i].id, "posicao": bairro.vizinhanca.entradas[i].posicao})
    return {"grid": Transform2D(BAIRRO.U, BAIRRO.V, BAIRRO.ORIGEM), "tamanho": BAIRRO.TAMANHO,
        "rua_inicio": BAIRRO.RUA_INICIO, "rua_fim": BAIRRO.RUA_FIM,
        "travessias": BAIRRO.TRAVESSIAS, "obstaculos": obstaculos, "lojas": lojas}
