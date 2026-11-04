extends RefCounted

const PECAS = preload("res://scripts/CatalogoPecas.gd")
const JOGOS = preload("res://scripts/CatalogoJogos.gd")
const FORNECEDORES := {
    "bairro":{"nome":"Distribuidora do bairro","nivel":1,"prazo":30.0},
    "regional":{"nome":"Rede regional","nivel":2,"prazo":25.0},
    "especialista":{"nome":"Laboratorio especialista","nivel":3,"prazo":20.0}
}
const AVANCADAS := ["caixa_torre","placa_nova","cpu_nova","ram_vento","ssd_veloz","gpu_trovao","fonte_firme","cooler_nova"]
const INTERMEDIARIAS := ["cpu_aurora_pro","gpu_pixel200","ssd_trilha500","cooler_neve_pro"]

static func inicial() -> Dictionary:
    return {"versao":1,"pecas_legadas":[],"jogos_legados":[],"fornecedor":"bairro","nivel":1}

static func migrar(comercio: Dictionary) -> Dictionary:
    var dados := inicial()
    var adquiridas: Array = comercio.get("estoque",{}).keys()
    for pedido: Dictionary in comercio.get("pedidos",[]):
        adquiridas.append(pedido["peca"])
    var configuracoes: Array = comercio.get("pcs",[]).duplicate()
    if not comercio.get("montagem",{}).is_empty():
        configuracoes.append(comercio["montagem"])
    for pc: Dictionary in configuracoes:
        adquiridas.append_array(pc["pecas"].values())
        var jogo: String = pc.get("jogo","")
        if not jogo.is_empty() and not jogo in dados["jogos_legados"]:
            dados["jogos_legados"].append(jogo)
    for id in adquiridas:
        if not id in dados["pecas_legadas"]:
            dados["pecas_legadas"].append(id)
    return dados

static func nivel(comercio: Dictionary, reputacao: int) -> int:
    var receita := 0
    for item: Dictionary in comercio["caixa"]:
        receita += maxi(0,int(item["valor"]))
    if reputacao >= 60 and (comercio["pcs"].size() >= 5 or receita >= 15000):
        return 3
    if reputacao >= 45 and (comercio["pcs"].size() >= 2 or receita >= 5000):
        return maxi(2,int(comercio.get("campanha",{}).get("nivel",1)))
    return int(comercio.get("campanha",{}).get("nivel",1))

static func nivel_peca(id: String) -> int:
    return 3 if id in AVANCADAS else 2 if id in INTERMEDIARIAS else 1

static func nivel_jogo(id: String) -> int:
    var jogo := JOGOS.buscar(id)
    return 3 if int(jogo["cpu"]) > 150 or int(jogo["gpu"]) > 170 else 2 if int(jogo["cpu"]) > 100 or int(jogo["gpu"]) > 100 or int(jogo["ram"]) > 8 or int(jogo["ssd"]) > 240 else 1

static func peca_liberada(id: String, dados: Dictionary, nivel_atual: int) -> bool:
    return id in dados["pecas_legadas"] or nivel_peca(id) <= nivel_atual

static func jogo_liberado(id: String, dados: Dictionary, nivel_atual: int) -> bool:
    return id.is_empty() or id in dados["jogos_legados"] or nivel_jogo(id) <= nivel_atual

static func validar(dados: Dictionary) -> bool:
    if dados.get("versao") != 1 or not dados.get("pecas_legadas") is Array or not dados.get("jogos_legados") is Array or not dados.get("fornecedor") in FORNECEDORES:
        return false
    var valor: Variant = dados.get("nivel",1)
    if not (valor is int or valor is float) or not float(valor) in [1.0,2.0,3.0]:
        return false
    for campo in ["pecas_legadas","jogos_legados"]:
        var encontrados: Array = []
        for id in dados[campo]:
            if not id is String or id in encontrados or not id in (PECAS.PECAS if campo == "pecas_legadas" else JOGOS.JOGOS):
                return false
            encontrados.append(id)
    return true

static func meta_diaria(salarios: int) -> Dictionary:
    var custo := 0
    for id in ["caixa_ninho","placa_aurora","cpu_aurora","ram_brisa","fonte_clara","ssd_trilha","gpu_pixel","cooler_neve"]:
        custo += int(PECAS.PECAS[id]["custo"])
    var margem := PECAS.PRECO_PC - custo
    var despesas := 120 + salarios
    return {"custo_pc":custo,"margem_pc":margem,"despesas":despesas,"equilibrio":ceili(float(despesas) / margem),
        "meta_pcs":2,"lucro_meta":margem * 2 - despesas,"reserva":custo * 2 + despesas}
