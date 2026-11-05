extends SceneTree
## Godot --headless --path . --script res://tests/test_bairro_vitrine.gd
## Verifica transicao real caminhando -> observando -> retornando -> desativado.
const MUNDO = preload("res://scripts/MundoVivo.gd")
const INTERESSE = preload("res://scripts/Neighborhood/NPCInteresse.gd")
var erros := 0

func _initialize() -> void:
    call_deferred("_executar")

func _check(condicao: bool, mensagem: String) -> void:
    if not condicao:
        erros += 1
        printerr("FAIL: ", mensagem)

func _executar() -> void:
    var mundo := MUNDO.new()
    root.add_child(mundo)
    mundo.limite_pedestres = 1
    mundo.limite_veiculos = 0
    var grid := Transform2D(Vector2(20, 6), Vector2(-20, 10), Vector2(400, 0))
    var destino := grid * Vector2(3, 2)
    var dados := {
        "grid": grid, "tamanho": Vector2i(16, 10),
        "rua_inicio": 4, "rua_fim": 8, "travessias": [6, 12],
        "obstaculos": [], "lojas": [{"id": "pc_store_001", "posicao": destino}],
        "rotas_pedestres": [{"pontos": PackedVector2Array([grid * Vector2(2, 2), destino]), "loja": "pc_store_001"}],
        "rotas_trafego": []
    }
    _check(mundo.configurar(dados), "rota de vitrine valida")
    var avaliacoes: Array[String] = []
    mundo.pedestre_avaliou_loja.connect(func(_id: int, _loja: String, decisao: String, _pontos: float) -> void:
        avaliacoes.append(decisao))
    mundo.avancar(0.1, 450.0)
    _check(mundo.estado().atores.size() == 1, "pedestre ativo")
    _check(mundo.estado().atores[0].estado_npc == "caminhando", "comeca caminhando")
    var encontrou := false
    for i in range(80):
        mundo.avancar(0.25, 450.0)
        for ator in mundo.estado().atores:
            if ator.estado_npc == "observando":
                encontrou = true
                _check(ator.posicao.distance_to(destino) < 0.01, "observa na entrada")
                break
        if encontrou:
            break
    _check(encontrou, "estudante observa vitrine")
    _check(avaliacoes == ["observar"], "avaliacao unica na chegada")
    var posicao: Vector2 = mundo.estado().atores[0].posicao if encontrou else Vector2.ZERO
    mundo.avancar(0.25, 450.0)
    if encontrou:
        _check(mundo.estado().atores[0].posicao == posicao, "observacao sem movimento")
        var observador: Node = null
        for ator in mundo._atores:
            if ator.ativo and not ator.trafego:
                observador = ator.no
                break
        _check(observador != null, "sprite do observador acessivel")
        if observador != null:
            _check(observador.direcao == "frente", "observacao inicia olhando para frente")
            mundo.avancar(0.25, 450.0)
            mundo.avancar(0.25, 450.0)
            mundo.avancar(0.25, 450.0)
            _check(observador.direcao == "esquerda", "observador olha para esquerda")
            _check(observador.position == posicao, "olhar nao altera a posicao")
            mundo.avancar(0.25, 450.0)
            mundo.avancar(0.25, 450.0)
            mundo.avancar(0.25, 450.0)
            _check(observador.direcao == "direita", "observador olha para direita")
            _check(observador.position == posicao, "olhar preserva posicao na vitrine")
    # Mantem a meta ativa ate o fim da observacao; reduzir a meta agora
    # desativaria o pedestre antes de ele poder iniciar o retorno.
    var retornou := false
    var posicao_retorno: Vector2 = destino
    for i in range(20):
        mundo.avancar(0.25, 450.0)
        for ator in mundo.estado().atores:
            if ator.estado_npc == "retornando":
                retornou = true
                _check(mundo.ponto_valido(ator.posicao), "retorno permanece em piso caminhavel")
                _check(mundo.segmento_valido(posicao_retorno, ator.posicao), "retorno nao atravessa obstaculos")
                posicao_retorno = ator.posicao
    _check(retornou, "observador retorna caminhando pela calcada")
    _check(posicao_retorno.distance_to(destino) > 0.01, "observador se afasta da vitrine")
    # Ao encerrar o fluxo, nao deve restar nenhum ator ativo.
    mundo.limite_pedestres = 0
    mundo.avancar(0.25, 450.0)
    _check(mundo.estado().atores.is_empty(), "observador sai ao encerrar fluxo")
    # Reinicia o cenario para isolar a decisao gamer: a densidade pode
    # criar novos observadores enquanto aguardamos o retorno do primeiro.
    _check(mundo.configurar(dados), "cenario gamer configurado")
    avaliacoes.clear()
    mundo.limite_pedestres = 1
    mundo.avancar(0.1, 450.0)
    _check(mundo.estado().atores.size() == 1, "novo pedestre ativo")
    for ator in mundo._atores:
        if ator.ativo and not ator.trafego:
            ator.perfil = INTERESSE.perfil(4)
    var entrou := false
    for i in range(80):
        mundo.avancar(0.25, 450.0)
        if "entrar" in avaliacoes:
            entrou = true
            break
    _check(entrou, "gamer entra em vez de observar")
    _check(avaliacoes == ["entrar"], "gamer emite apenas decisao de entrada")
    mundo.free()
    print("BV-03 vitrine: ", "OK" if erros == 0 else "FALHOU")
    quit(0 if erros == 0 else 1)
