extends RefCounted

const PECAS = preload("res://scripts/CatalogoPecas.gd")
const JOGOS = preload("res://scripts/CatalogoJogos.gd")
const SERVICOS = preload("res://scripts/CatalogoServicos.gd")
const NOMES := ["Alex","Bia","Cris","Dani","Emi","Fran","Gui","Iara"]
var estado: Dictionary = inicial()
var ultimo_erro := ""

static func inicial() -> Dictionary:
    return {"versao":1,"proximo":1,"perfis":{},"fila":[],"atual":"","historico":[],"reputacao":50}

func carregar(dados: Dictionary) -> bool:
    if not validar(dados):
        ultimo_erro = "Perfis/fila invalidos; progresso preservado."
        push_warning(ultimo_erro)
        return false
    estado = dados.duplicate(true)
    if not estado.has("reputacao"):
        estado["reputacao"] = 50
        for item: Dictionary in estado["historico"]:
            _satisfacao(item["resultado"])
    ultimo_erro = ""
    return true

func adicionar(preferencia: String, orcamento: int, paciencia: float = 120.0) -> String:
    if estado["fila"].size() >= 4 or not preferencia in PECAS.CATEGORIAS + ["insumo"] or orcamento <= 0 or not is_finite(paciencia) or paciencia <= 0:
        ultimo_erro = "Fila cheia ou perfil de cliente invalido."
        push_warning(ultimo_erro)
        return ""
    var id := _perfil(preferencia,orcamento,paciencia)
    estado["fila"].append(id)
    return id

func _perfil(preferencia: String, orcamento: int, paciencia: float) -> String:
    var numero := int(estado["proximo"])
    var id := "cliente_%d" % numero
    estado["proximo"] = numero + 1
    estado["perfis"][id] = {"nome":NOMES[(numero-1) % NOMES.size()],"preferencia":preferencia,
        "orcamento":orcamento,"paciencia":paciencia,"restante":paciencia,"fidelidade":0,"retorno":0,"visitas":0}
    return id

func vincular_manual(produto: String, pc: bool, preco: int) -> void:
    var preferencia := "pc" if pc else str(PECAS.PECAS[produto]["categoria"])
    estado["atual"] = _perfil(preferencia,preco,900.0 if pc else 180.0)

func vincular_servico(preco: int) -> void:
    estado["atual"] = _perfil("servico",preco,300.0)

func ativar(id: String) -> bool:
    if not estado["atual"].is_empty() or not id in estado["fila"]:
        ultimo_erro = "Cliente nao pertence a fila ou atendimento ocupado."
        push_warning(ultimo_erro)
        return false
    estado["fila"].erase(id)
    estado["atual"] = id
    estado["perfis"][id]["retorno"] = 0
    return true

func oferta(id: String, estoque: Dictionary) -> String:
    var perfil: Dictionary = estado["perfis"][id]
    var escolhido := ""
    var preco := 2147483647
    for produto in estoque:
        var dados: Dictionary = PECAS.PECAS[produto]
        if int(estoque[produto]) > 0 and dados["categoria"] == perfil["preferencia"] and int(dados["venda"]) <= int(perfil["orcamento"]) and int(dados["venda"]) < preco:
            escolhido = produto
            preco = int(dados["venda"])
    return escolhido

func avancar(delta: float, servico_autorizado: bool = false) -> Array[String]:
    var expirados: Array[String] = []
    var ids: Array = estado["fila"].duplicate()
    if not estado["atual"].is_empty() and not servico_autorizado:
        ids.append(estado["atual"])
    for id in ids:
        var perfil: Dictionary = estado["perfis"][id]
        perfil["restante"] = maxf(0,float(perfil["restante"]) - delta)
        if float(perfil["restante"]) == 0:
            expirados.append(id)
    return expirados

func finalizar(id: String, dia: int, resultado: String, produto: String = "", valor: int = 0, pc_id: int = 0) -> void:
    var perfil: Dictionary = estado["perfis"][id]
    perfil["fidelidade"] = mini(100,int(perfil["fidelidade"]) + 5) if resultado == "compra" else maxi(0,int(perfil["fidelidade"]) - 2)
    perfil["visitas"] = int(perfil.get("visitas",0)) + 1
    perfil["retorno"] = dia + (1 + int(id.trim_prefix("cliente_")) % 3 if resultado == "compra" else 4)
    _satisfacao(resultado)
    estado["historico"].append({"cliente":id,"dia":dia,"resultado":resultado,"produto":produto,"valor":valor,"pc_id":pc_id})
    estado["fila"].erase(id)
    if estado["atual"] == id:
        estado["atual"] = ""

func _satisfacao(resultado: String) -> void:
    estado["reputacao"] = clampi(int(estado["reputacao"]) + (2 if resultado == "compra" else -4 if resultado == "desistencia" else -1),0,100)

func demanda() -> float:
    return 0.6 + float(estado["reputacao"]) / 125.0

func retornar(dia: int) -> String:
    if estado["fila"].size() >= 4:
        return ""
    for id in estado["perfis"]:
        var perfil: Dictionary = estado["perfis"][id]
        if int(perfil.get("retorno",0)) <= 0 or int(perfil["retorno"]) > dia or id == estado["atual"] or id in estado["fila"]:
            continue
        perfil["restante"] = perfil["paciencia"]
        perfil["retorno"] = 0
        estado["fila"].append(id)
        return id
    return ""

static func _inteiro(valor: Variant, minimo: int = 0) -> bool:
    return (valor is int or valor is float) and is_finite(float(valor)) and float(valor) >= minimo and float(valor) <= 2147483647 and float(valor) == floorf(float(valor))

static func validar(dados: Dictionary) -> bool:
    if dados.get("versao") != 1 or not _inteiro(dados.get("proximo"),1) or not dados.get("perfis") is Dictionary or not dados.get("fila") is Array or not dados.get("historico") is Array:
        return false
    if dados["fila"].size() > 4 or not dados.get("atual") is String:
        return false
    if not _inteiro(dados.get("reputacao",50)) or float(dados.get("reputacao",50)) > 100:
        return false
    for id in dados["perfis"]:
        var perfil: Variant = dados["perfis"][id]
        if not id is String or not perfil is Dictionary or not perfil.get("nome") is String:
            return false
        if not id.begins_with("cliente_") or not id.trim_prefix("cliente_").is_valid_int():
            return false
        var numero := int(id.trim_prefix("cliente_"))
        if numero < 1 or numero >= int(dados["proximo"]):
            return false
        if not perfil.get("preferencia") in PECAS.CATEGORIAS + ["insumo","pc","servico"]:
            return false
        if not _inteiro(perfil.get("orcamento"),1) or not _inteiro(perfil.get("fidelidade")) or float(perfil["fidelidade"]) > 100:
            return false
        if not _inteiro(perfil.get("retorno",0)) or not _inteiro(perfil.get("visitas",0)):
            return false
        if perfil.has("jogo") and (not perfil["jogo"] is String or (perfil["jogo"] != "" and not JOGOS.JOGOS.has(perfil["jogo"]))):
            return false
        if perfil.has("servico") and not SERVICOS.ITENS.has(perfil["servico"]):
            return false
        for campo in ["paciencia","restante"]:
            var valor: Variant = perfil.get(campo)
            if not (valor is float or valor is int) or not is_finite(float(valor)) or float(valor) < 0:
                return false
        if float(perfil["paciencia"]) == 0 or float(perfil["restante"]) > float(perfil["paciencia"]):
            return false
    var ids: Dictionary = {}
    for id in dados["fila"]:
        if not dados["perfis"].has(id) or ids.has(id):
            return false
        ids[id] = true
    if not dados["atual"].is_empty() and (not dados["perfis"].has(dados["atual"]) or ids.has(dados["atual"])):
        return false
    for item in dados["historico"]:
        if not item is Dictionary or not dados["perfis"].has(item.get("cliente","")) or not _inteiro(item.get("dia"),1) or not item.get("resultado") in ["compra","cancelado","desistencia"]:
            return false
        if not item.get("produto") is String or not _inteiro(item.get("valor")) or not _inteiro(item.get("pc_id")):
            return false
    return true
