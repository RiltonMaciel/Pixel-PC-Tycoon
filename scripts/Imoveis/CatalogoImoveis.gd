extends RefCounted
# Cadastro central: cada instancia possui um ID unico e uma planta interna.
const IMOVEIS := {
    "pc_store_001": {
        "nome": "PC Store",
        "exterior_id": "rua_comercial",
        "interior_id": "loja_pc_base",
        "interior_cenario": "res://Assets/Cenarios/Loja_Base_Aprovada.png",
        "porta_externa": Vector2(920, 695),
        "saida_externa": Vector2(920, 715),
        "entrada_interna_normalizada": Vector2(0.50, 0.62),
        "saida_interna_normalizada": Vector2(0.50, 0.68)
    }
}

static func buscar(id: String) -> Dictionary:
    return IMOVEIS.get(id, {})

static func interior(id: String) -> Texture2D:
    var item := buscar(id)
    if item.is_empty():
        return null
    return load(str(item.get("interior_cenario", ""))) as Texture2D
