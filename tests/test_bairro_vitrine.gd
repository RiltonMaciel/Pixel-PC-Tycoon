extends SceneTree
## Godot --headless --path . --script res://tests/test_bairro_vitrine.gd
## Verifica transicao real caminhando -> observando -> desativado.
const MUNDO = preload("res://scripts/MundoVivo.gd")
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
    var posicao := mundo.estado().atores[0].posicao if encontrou else Vector2.ZERO
    mundo.avancar(0.25, 450.0)
    if encontrou:
        _check(mundo.estado().atores[0].posicao == posicao, "observacao sem movimento")
    # Desabilita novos nascimentos para conferir a desativacao do observador.
    mundo.limite_pedestres = 0
    for i in range(12):
        mundo.avancar(0.25, 450.0)
    _check(mundo.estado().atores.is_empty(), "observador sai apos espera")
    mundo.free()
    print("BV-03 vitrine: ", "OK" if erros == 0 else "FALHOU")
    quit(0 if erros == 0 else 1)
