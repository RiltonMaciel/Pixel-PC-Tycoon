extends RefCounted
const MODULAR = preload("res://scripts/Imoveis/InteriorModular.gd")
const BAIRRO = preload("res://scripts/BairroComercial.gd")
# Cadastro central: cada instancia possui um ID unico e uma planta interna.
const IMOVEIS := {
    "pc_store_001": {
        "nome": "PC Store",
        "exterior_id": "rua_comercial",
        "interior_id": "loja_pc_base",
        "interior_cenario": "res://Assets/Cenarios/Loja_Base_Aprovada.png",
        "exterior_cenario": "res://Assets/Cenarios/Exterior/PC_Store_Com_Telhado.png",
        "origem": Vector2(700,240),
        "modulos": Vector2i(6,5),
        "entrada_uv": Vector2(5.2,2),
        "saida_uv": Vector2(5.8,2),
        "piso_legado": [Vector2(265,455), Vector2(792,240), Vector2(1170,425), Vector2(558,621)],
        "moveis_iniciais": [
            {"id":"balcao_atendimento","uv":Vector2(4,3.75)},
            {"id":"bancada_montagem_com_computador","uv":Vector2(2.75,1.5)},
            {"id":"mesa_notebook_com_cadeira","uv":Vector2(1.25,2.5)},
            {"id":"prateleira_componentes","uv":Vector2(1.25,4)}
        ],
    },
    "pc_store_002":{
        "nome":"PC Store - Salas comerciais","exterior_id":"rua_comercial","interior_id":"loja_pc_ampla",
        "interior_cenario":"res://Assets/Cenarios/Loja_Base_Aprovada.png",
        "origem":Vector2(700,240),"modulos":Vector2i(10,8),"entrada_uv":Vector2(9.2,2),"saida_uv":Vector2(9.8,2),
        "piso_legado":[],"moveis_iniciais":[],
        "entrada_bairro":Vector2(65,10),"preco":8500
    }
}

static func buscar(id: String, nivel: int = 0) -> Dictionary:
    if not IMOVEIS.has(id) or nivel < 0 or nivel > 2:
        push_error("Imovel desconhecido: " + id)
        return {}
    var dados: Dictionary = IMOVEIS[id].duplicate(true)
    dados["nivel"] = nivel
    dados["modulos"] += Vector2i(nivel * 2,nivel)
    dados["entrada_uv"].x += nivel * 2
    dados["saida_uv"].x += nivel * 2
    dados["piso_interno"] = MODULAR.poligono(dados["modulos"],dados["origem"])
    dados["entrada_interna"] = MODULAR.ponto(dados["entrada_uv"],dados["origem"])
    dados["saida_interna"] = MODULAR.ponto(dados["saida_uv"],dados["origem"])
    dados["porta_externa"] = BAIRRO.ponto(dados["entrada_bairro"]) + Vector2(0,28) if dados.has("entrada_bairro") else BAIRRO.local_loja(BAIRRO.PORTA_LOCAL)
    dados["saida_externa"] = BAIRRO.ponto(dados["entrada_bairro"]) + Vector2(0,50) if dados.has("entrada_bairro") else BAIRRO.local_loja(BAIRRO.SPAWN_LOCAL)
    dados["rota_cliente"] = BAIRRO.rota_cliente()
    return dados

static func estado_inicial(id: String) -> Dictionary:
    var dados := buscar(id)
    var moveis: Array[Dictionary] = []
    for item in dados["moveis_iniciais"]:
        var at := MODULAR.ponto(item["uv"],dados["origem"])
        moveis.append({"id":item["id"],"posicao":[at.x,at.y],"angulo":0})
    return {"moveis":moveis,"guardados":[]}

static func interior(id: String) -> Texture2D:
    var item := buscar(id)
    if item.is_empty():
        return null
    return load(str(item.get("interior_cenario", ""))) as Texture2D
