extends RefCounted
# Mantem contexto de entrada/saida e estados independentes por imovel.
const Catalogo = preload("res://scripts/Imoveis/CatalogoImoveis.gd")
var imovel_atual: String = ""
var cena_exterior: String = "rua_comercial"
var estados: Dictionary = {}

func entrar(id: String) -> Dictionary:
    var dados := Catalogo.buscar(id)
    if dados.is_empty():
        return {}
    imovel_atual = id
    cena_exterior = str(dados.get("exterior_id", "rua_comercial"))
    return dados

func sair() -> Dictionary:
    var dados := Catalogo.buscar(imovel_atual)
    imovel_atual = ""
    return dados

func salvar_estado(id: String, estado: Dictionary) -> void:
    estados[id] = estado.duplicate(true)

func carregar_estado(id: String) -> Dictionary:
    return (estados.get(id, {}) as Dictionary).duplicate(true)
