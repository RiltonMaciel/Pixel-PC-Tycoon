extends SceneTree
## Regressao de conexao comercial: Godot --headless --path . --script res://tests/test_bairro_fluxo_comercial.gd
## Teste estrutural; fluxo completo exige simulacao e testes de integracao.
func _initialize() -> void:
    var rua := FileAccess.get_file_as_string("res://scripts/RuaComercial.gd")
    var mundo := FileAccess.get_file_as_string("res://scripts/MundoVivo.gd")
    var ok := true
    ok = _verificar(rua.contains("pedestre_avaliou_loja.connect(_cliente_avaliado_da_rua)"), "evento de avaliacao conectado") and ok
    ok = _verificar(not rua.contains("pedestre_chegou_loja.connect(_cliente_da_rua)"), "evento legado nao cria clientes") and ok
    ok = _verificar(rua.contains("if decisao != \"entrar\":"), "decisao de entrada filtrada") and ok
    ok = _verificar(mundo.contains("pedestre_avaliou_loja.emit("), "evento emitido") and ok
    print("BV-03 regressao comercial: ", "OK" if ok else "FALHOU")
    quit(0 if ok else 1)

func _verificar(condicao: bool, descricao: String) -> bool:
    if not condicao:
        push_error(descricao)
    return condicao
