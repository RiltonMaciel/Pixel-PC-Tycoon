extends SceneTree
## Executar apenas este teste: Godot --headless --path . --script res://tests/test_world.gd
const MUNDO = preload("res://scripts/MundoVivo.gd")
const BAIRRO = preload("res://scripts/BairroComercial.gd")
const IMOVEIS = preload("res://scripts/Imoveis/CatalogoImoveis.gd")
const AMBIENTE = preload("res://scripts/Ambiente.gd")
const DIA := 900.0
var passed := 0
var failed := 0
var chegadas: Array[Dictionary] = []

func _initialize() -> void:
    call_deferred("_run")

func check(ok: bool, texto: String) -> void:
    if ok:
        passed += 1
        print("PASS: ", texto)
    else:
        failed += 1
        printerr("FAIL: ", texto)

func _dados() -> Dictionary:
    return {"grid": Transform2D(Vector2(20, 6), Vector2(-20, 10), Vector2(400, 0)),
        "tamanho": Vector2i(16, 10), "rua_inicio": 4, "rua_fim": 8, "travessias": [6, 12],
        "obstaculos": [], "lojas": []}

func _novo() -> MUNDO:
    var mundo := MUNDO.new()
    root.add_child(mundo)
    return mundo

func _run() -> void:
    _rotas_fornecidas()
    _densidade()
    await _movimento_pausa_pool()
    _bairro_real()
    check(passed + failed >= 50, "Todos os grupos de teste foram executados")
    print("RESULT: %d passed, %d failed" % [passed, failed])
    quit(1 if failed else 0)

func _rotas_fornecidas() -> void:
    var mundo := _novo()
    var dados := _dados()
    var grid: Transform2D = dados.grid
    dados.rotas_pedestres = [{"pontos": PackedVector2Array([
        grid * Vector2(2, 3), grid * Vector2(7, 3), grid * Vector2(7, 8.5)])}]
    dados.rotas_trafego = [{"pontos": PackedVector2Array([
        grid * Vector2(0.5, 5), grid * Vector2(15.5, 5)])}]
    check(mundo.configurar(dados), "Aceita rota de calcada/faixa e faixa de asfalto")
    check(not mundo.ponto_valido(grid * Vector2(-0.1, 3)), "Limite esquerdo")
    check(not mundo.ponto_valido(grid * Vector2(16, 3)), "Limite direito exclusivo")
    check(not mundo.ponto_valido(grid * Vector2(2, 10)), "Limite inferior exclusivo")
    check(not mundo.ponto_valido(grid * Vector2(2, -0.1)), "Limite superior")
    check(not mundo.ponto_valido(Vector2(NAN, 1)), "Rejeita NaN")
    check(not mundo.ponto_valido(grid * Vector2(3, 5)), "Pedestre nao anda no asfalto sem faixa")
    check(mundo.ponto_valido(grid * Vector2(7, 5)), "Pedestre anda na faixa")
    check(not mundo.ponto_valido(grid * Vector2(7, 3), true), "Carro nao anda na calcada")
    check(not mundo.segmento_valido(grid * Vector2(3, 3), grid * Vector2(3, 9)), "Rejeita atalho pela rua")
    check(not mundo.segmento_valido(grid * Vector2(7, 3), grid * Vector2(13, 9)), "Rejeita diagonal entre faixas")
    check(not mundo.segmento_valido(grid * Vector2(2, 5), grid * Vector2(3, 6), true), "Carro nao muda de faixa")
    check(not mundo.segmento_valido(grid * Vector2(3, 5), grid * Vector2(2, 5), true), "Rejeita contramao")
    check(mundo.segmento_valido(grid * Vector2(3, 7), grid * Vector2(2, 7), true), "Faixa oposta respeita sentido")
    dados.obstaculos = [PackedVector2Array([grid * Vector2(4, 2), grid * Vector2(5, 2),
        grid * Vector2(5, 3.5), grid * Vector2(4, 3.5)])]
    check(not mundo.configurar(dados) and not mundo.ultimo_erro.is_empty(), "Rota fornecida nao atravessa obstaculo")
    check(not mundo.estado().configurado, "Erro de configuracao deixa simulacao inativa")
    dados.obstaculos = []
    dados.rotas_pedestres = [{"pontos": PackedVector2Array([grid * Vector2(2, 3), grid * Vector2(INF, 2)])}]
    check(not mundo.configurar(dados), "Rejeita rota infinita")
    dados.rotas_pedestres = [{"pontos": PackedVector2Array([grid * Vector2(2, 3), grid * Vector2(2, 3)])}]
    check(not mundo.configurar(dados), "Rejeita segmento nulo")
    dados.rotas_pedestres = []
    dados.rotas_trafego = []
    check(mundo.configurar(dados), "Arrays vazios desabilitam fluxos")
    mundo.avancar(1, DIA / 2)
    check(mundo.estado().nos == 0, "Sem rotas nao aloca atores")
    dados.lojas = [{"id": "pc_store", "posicao": grid * Vector2(3, 3)}]
    dados.rotas_pedestres = [{"pontos": PackedVector2Array([grid * Vector2(1, 3), grid * Vector2(2, 3)]), "loja": "pc_store"}]
    check(not mundo.configurar(dados), "Chegada nao pode ser emitida longe da entrada")
    dados.rotas_pedestres = [{"pontos": PackedVector2Array([grid * Vector2(1, 3), grid * Vector2(3, 3)]), "loja": "pc_store"}]
    check(mundo.configurar(dados), "Destino comercial coincide com entrada segura")
    var copia := mundo.estado()
    copia.rotas_pedestres[0].loja = "alterado"
    check(mundo.estado().rotas_pedestres[0].loja == "pc_store", "Diagnostico nao permite alterar rotas internas")
    dados.grid = Transform2D(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
    check(not mundo.configurar(dados), "Rejeita grid singular")
    mundo.free()

func _densidade() -> void:
    var mundo := _novo()
    var dia := mundo.densidade(DIA / 2)
    var noite := mundo.densidade(0)
    var chuva := mundo.densidade(DIA / 2, {"clima": "Chuva"})
    check(mundo.densidade(DIA / 2, {"clima": "  cHuVa \n"}) == chuva, "Normaliza caixa e espacos do clima")
    check(mundo.densidade(DIA / 2, " CHUVA ") == chuva, "Normaliza clima fornecido como String")
    check(mundo.densidade(DIA / 2, {"clima": " NUBLADO ", "evento": " ROTINA ", "demanda": 1.0}) == dia, "Aceita Nublado/Rotina e metadados da previsao")
    check(mundo.densidade(DIA / 2, {"clima": " limpo ", "evento": " DIA TRANQUILO "}) \
        == mundo.densidade(DIA / 2, {"clima": "Limpo", "evento": "Dia tranquilo"}), "Normaliza strings de evento")
    check(mundo.densidade(0, {"evento": " FEIRA DE TECNOLOGIA "}) \
        == mundo.densidade(0, {"evento": "Feira de tecnologia"}), "Normaliza feira sem alterar efeito")
    check(mundo.densidade(DIA / 2, {"clima": "Chuva", "evento": "Dia tranquilo", "demanda": 0.5625}) \
        == mundo.densidade(DIA / 2, {"clima": "Chuva", "evento": "Dia tranquilo"}), "Demanda comercial nao duplica multiplicadores de densidade")
    check(dia.pedestres > noite.pedestres and dia.veiculos > noite.veiculos, "Ciclo dia/noite reduz populacao")
    check(chuva.pedestres < dia.pedestres and chuva.veiculos < dia.veiculos, "Chuva reduz densidade")
    check(mundo.densidade(DIA / 2, AMBIENTE.previsao(3)).pedestres < dia.pedestres, "Integra previsao existente")
    check(mundo.densidade(DIA / 2) == mundo.densidade(DIA * 1.5), "Horario normalizado por dia")
    check(mundo.densidade(-DIA / 2) == dia, "Horario negativo finito normalizado")
    check(mundo.densidade(NAN) == {"pedestres": 0, "veiculos": 0}, "Horario NaN nao cria populacao")
    mundo.limite_pedestres = 9999
    mundo.limite_veiculos = 9999
    var feira := mundo.densidade(DIA / 2, {"evento": "Feira de tecnologia"})
    check(feira.pedestres == MUNDO.MAX_PEDESTRES and feira.veiculos == MUNDO.MAX_VEICULOS, "Tetos resistem a limites externos e eventos")
    mundo.limite_pedestres = -1
    mundo.limite_veiculos = -1
    check(mundo.densidade(DIA / 2) == {"pedestres": 0, "veiculos": 0}, "Limites negativos desabilitam populacao")
    mundo.free()

func _movimento_pausa_pool() -> void:
    var mundo := _novo()
    var outro := _novo()
    var dados := _dados()
    var grid: Transform2D = dados.grid
    dados.lojas = [{"id": "pc_store_001", "posicao": grid * Vector2(3, 2)},
        {"id": "pc_store_002", "posicao": grid * Vector2(4, 2)}]
    dados.rotas_pedestres = [{"pontos": PackedVector2Array([
        grid * Vector2(2, 3), grid * Vector2(3, 3), grid * Vector2(3, 2)]), "loja": "pc_store_001"},
        {"pontos": PackedVector2Array([grid * Vector2(2, 3), grid * Vector2(4, 3),
            grid * Vector2(4, 2)]), "loja": "pc_store_002"}]
    dados.rotas_trafego = [{"pontos": PackedVector2Array([
        grid * Vector2(0.5, 5), grid * Vector2(15.5, 5)])}]
    mundo.limite_pedestres = 2
    mundo.limite_veiculos = 1
    outro.limite_pedestres = 2
    outro.limite_veiculos = 1
    check(mundo.configurar(dados) and outro.configurar(dados), "Configura fixture deterministica")
    mundo.pedestre_chegou_loja.connect(func(id: int, loja: String, posicao: Vector2) -> void:
        chegadas.append({"id": id, "loja": loja, "posicao": posicao}))
    mundo.avancar(0.1, DIA / 2)
    outro.avancar(0.1, DIA / 2)
    check(mundo.estado() == outro.estado(), "Mesma entrada produz mesmos atores sem RNG global")
    var antes := mundo.estado()
    await process_frame
    await process_frame
    check(mundo.estado() == antes, "Sem processamento proprio duplicado")
    for motivo in [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)]:
        mundo.definir_suspensao(motivo.x > 0, motivo.y > 0, motivo.z > 0)
        mundo.avancar(60, 0, "Chuva")
        check(mundo.estado() == antes, "Suspende interior/construcao/app: " + str(motivo))
    mundo.definir_suspensao(false, false, false)
    paused = true
    mundo.avancar(5, 0)
    check(mundo.estado() == antes, "Respeita pausa de SceneTree mesmo com chamada manual")
    paused = false
    for delta in [0.0, -1.0, NAN, INF]:
        mundo.avancar(delta, DIA / 2)
    mundo.avancar(1, NAN)
    check(mundo.estado() == antes, "Deltas invalidos e horario NaN nao alteram estado")
    mundo.avancar(1.0e20, DIA / 2)
    var depois := mundo.estado()
    var continuo := true
    for ator in depois.atores:
        for anterior in antes.atores:
            if ator.id == anterior.id:
                var limite := mundo.velocidade_veiculo if ator.trafego else mundo.velocidade_pedestre
                continuo = continuo and ator.posicao.is_finite() \
                    and ator.posicao.distance_to(anterior.posicao) <= limite * MUNDO.PASSO_MAXIMO + 0.01
    check(continuo, "Passo enorme descarta excesso, sem NaN nem teleporte")
    var seguro := true
    var segmentos := true
    var populacao := true
    for i in range(3000):
        var historico: Array = mundo.estado().atores
        mundo.avancar(0.25, DIA / 2 if i % 200 < 100 else 0, {"clima": "Chuva" if i % 7 == 0 else "Limpo"})
        var metas := mundo.densidade(DIA / 2 if i % 200 < 100 else 0, {"clima": "Chuva" if i % 7 == 0 else "Limpo"})
        var contagem := [0, 0]
        for ator in mundo.estado().atores:
            contagem[1 if ator.trafego else 0] += 1
            seguro = seguro and mundo.ponto_valido(ator.posicao, ator.trafego)
            for anterior in historico:
                if ator.id != anterior.id:
                    continue
                # Cada perna consumida, nao a corda entre duas pernas, deve ser legal.
                var pontos: PackedVector2Array = ator.rota.pontos
                var inicio: Vector2 = anterior.posicao
                for j in range(anterior.indice, ator.indice):
                    segmentos = segmentos and mundo.segmento_valido(inicio, pontos[j], ator.trafego)
                    inicio = pontos[j]
                if inicio.distance_to(ator.posicao) > 0.01:
                    segmentos = segmentos and mundo.segmento_valido(inicio, ator.posicao, ator.trafego)
        populacao = populacao and contagem[0] <= metas.pedestres and contagem[1] <= metas.veiculos
    check(seguro and segmentos, "Simulacao longa permanece em segmentos validos inclusive nas esquinas")
    check(populacao, "Populacao ativa acompanha limites de hora e clima")
    check(not chegadas.is_empty(), "Emite chegada comercial sem depender de economia")
    var ids: Dictionary = {}
    var lojas_emitidas: Dictionary = {}
    var eventos_validos := true
    for chegada in chegadas:
        var destino: Vector2 = dados.lojas[0].posicao if chegada.loja == "pc_store_001" else dados.lojas[1].posicao
        eventos_validos = eventos_validos and chegada.loja in ["pc_store_001", "pc_store_002"] \
            and chegada.posicao.distance_to(destino) < 0.01 and not ids.has(chegada.id)
        ids[chegada.id] = true
        lojas_emitidas[chegada.loja] = true
    check(eventos_validos, "Uma chegada por identidade, somente na entrada declarada")
    check(lojas_emitidas.has("pc_store_001") and lojas_emitidas.has("pc_store_002"), "Sinal preserva IDs comerciais das duas lojas explicitamente configuradas")
    check(mundo.get_child_count() == 3 and mundo.estado().nos == 3, "Pool nao cresce apos milhares de passos")
    dados.rotas_pedestres = []
    dados.rotas_trafego = []
    check(mundo.configurar(dados) and mundo.get_child_count() == 0, "Reconfiguracao libera pool imediatamente")
    mundo.free()
    outro.free()

func _bairro_real() -> void:
    var bairro := BAIRRO.new()
    root.add_child(bairro)
    var mundo := _novo()
    check(mundo.configurar(bairro), "Deriva mundo do bairro real com arte aprovada")
    var estado := mundo.estado()
    check(not estado.rotas_pedestres.is_empty() and not estado.rotas_trafego.is_empty(), "Gera pedestres e trafego reais")
    var seguro := true
    var cruzou := false
    var destino_pc := false
    var destino_amplo := false
    var imovel_amplo := IMOVEIS.buscar("pc_store_002")
    var acesso_amplo: Vector2 = imovel_amplo.porta_externa
    if not mundo.ponto_valido(acesso_amplo):
        acesso_amplo = imovel_amplo.saida_externa
    var sentido_positivo := false
    var sentido_negativo := false
    for rota in estado.rotas_pedestres:
        destino_pc = destino_pc or rota.loja == "pc_store_001"
        if rota.loja == "pc_store_002":
            destino_amplo = true
            seguro = seguro and rota.pontos[-1].distance_to(acesso_amplo) < 0.01
        for i in range(1, rota.pontos.size()):
            seguro = seguro and mundo.segmento_valido(rota.pontos[i - 1], rota.pontos[i])
        for ponto in rota.pontos:
            seguro = seguro and BAIRRO.piso_livre(ponto) and bairro.vizinhanca.piso_livre(ponto)
            cruzou = cruzou or BAIRRO.rua(BAIRRO.celula(ponto).y)
    for rota in estado.rotas_trafego:
        var movimento: Vector2 = rota.pontos[1] - rota.pontos[0]
        sentido_positivo = sentido_positivo or movimento.x > 0
        sentido_negativo = sentido_negativo or movimento.x < 0
        for i in range(1, rota.pontos.size()):
            seguro = seguro and mundo.segmento_valido(rota.pontos[i - 1], rota.pontos[i], true)
        for ponto in rota.pontos:
            seguro = seguro and BAIRRO.rua(BAIRRO.celula(ponto).y) and bairro.vizinhanca.piso_livre(ponto)
    check(seguro, "Rotas derivadas respeitam predios, objetos, faixas e limites existentes")
    check(cruzou, "Pedestres cruzam por faixa valida")
    check(destino_pc, "Deriva chegada valida a loja principal")
    check(destino_amplo and mundo.ponto_valido(acesso_amplo), "Deriva rota caminhavel ate acesso cadastrado de pc_store_002")
    check(sentido_positivo and sentido_negativo, "Trafego usa duas faixas com sentidos opostos")
    mundo.avancar(0.1, DIA / 2)
    var sprites := true
    for filho in mundo.get_children():
        sprites = sprites and filho is Sprite2D and filho.texture != null
    check(sprites and mundo.get_child_count() > 0, "Atores usam texturas existentes, nao marcadores")
    var limitado := true
    var chegada_ampla := [false]
    mundo.pedestre_chegou_loja.connect(func(_id: int, loja: String, posicao: Vector2) -> void:
        if loja == "pc_store_002" and posicao.distance_to(acesso_amplo) < 0.01:
            chegada_ampla[0] = true)
    for i in range(400):
        mundo.avancar(1.0e12, float(i) * 5, AMBIENTE.previsao(i % 7 + 1))
        limitado = limitado and mundo.get_child_count() <= MUNDO.MAX_PEDESTRES + MUNDO.MAX_VEICULOS
        for ator in mundo.estado().atores:
            limitado = limitado and ator.posicao.is_finite() and mundo.ponto_valido(ator.posicao, ator.trafego)
    check(limitado, "Bairro permanece valido e limitado durante ciclo de dias/climas")
    for i in range(1200):
        mundo.avancar(0.25, DIA / 2, {"clima": "Limpo", "evento": "Rotina"})
        if chegada_ampla[0]:
            break
    check(chegada_ampla[0], "Emite chegada real ao imovel maior sem teleporte")
    var porta_ampla: Vector2 = imovel_amplo.porta_externa
    bairro.vizinhanca.obstaculos.append(PackedVector2Array([
        porta_ampla + Vector2(-4, -4), porta_ampla + Vector2(4, -4),
        porta_ampla + Vector2(4, 4), porta_ampla + Vector2(-4, 4)]))
    check(mundo.configurar(bairro), "Reconfigura bairro com porta do imovel maior bloqueada")
    var usou_saida := false
    for rota in mundo.estado().rotas_pedestres:
        if rota.loja == "pc_store_002":
            usou_saida = true
            check(rota.pontos[-1].distance_to(imovel_amplo.saida_externa) < 0.01,
                "Porta bloqueada usa exclusivamente saida externa caminhavel")
    check(usou_saida, "Deriva alternativa caminhavel quando porta nao e pedestre")
    var saida_ampla: Vector2 = imovel_amplo.saida_externa
    bairro.vizinhanca.obstaculos.append(PackedVector2Array([
        saida_ampla + Vector2(-4, -4), saida_ampla + Vector2(4, -4),
        saida_ampla + Vector2(4, 4), saida_ampla + Vector2(-4, 4)]))
    check(mundo.configurar(bairro), "Reconfigura bairro com ambos acessos bloqueados")
    var omitiu_bloqueada := true
    for rota in mundo.estado().rotas_pedestres:
        omitiu_bloqueada = omitiu_bloqueada and rota.loja != "pc_store_002"
    check(omitiu_bloqueada, "Sem acesso caminhavel nao cria rota artificial ao imovel maior")
    mundo.free()
    bairro.free()
