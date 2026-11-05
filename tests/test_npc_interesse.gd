extends SceneTree
## Executar: godot --headless --path . --script res://tests/test_npc_interesse.gd
const INTERESSE = preload("res://scripts/Neighborhood/NPCInteresse.gd")

func _initialize() -> void:
    var ok := true
    var gamer := INTERESSE.perfil(0)
    ok = _check(gamer.tipo == "gamer","perfil gamer") and ok
    var entrada := INTERESSE.avaliar(gamer,"pc_store_001",100.0)
    ok = _check(entrada.decisao == "entrar","gamer interessado") and ok
    INTERESSE.registrar_visita(gamer,"pc_store_001",100.0)
    var repeticao := INTERESSE.avaliar(gamer,"pc_store_001",101.0)
    ok = _check(repeticao.motivo == "cooldown","cooldown impede repeticao") and ok
    ok = _check(gamer.visitas["pc_store_001"] == 1,"memoria da visita") and ok
    var invalido := INTERESSE.avaliar(gamer,"",100.0)
    ok = _check(invalido.decisao == "continuar","entrada invalida") and ok
    print("BV-03 interesse NPC: ", "OK" if ok else "FALHOU")
    quit(0 if ok else 1)

func _check(condicao: bool, descricao: String) -> bool:
    if not condicao:
        push_error(descricao)
    return condicao
