extends RefCounted

const CATALOGO = preload("res://scripts/CatalogoPecas.gd")
const JOGOS = preload("res://scripts/CatalogoJogos.gd")
const SERVICOS = preload("res://scripts/CatalogoServicos.gd")
const CAMPANHA = preload("res://scripts/Campanha.gd")
const MAX_OS := 4
const PRAZO_ENTREGA := 30.0
var estado: Dictionary = inicial()
var ultimo_erro := ""
var teste_executado := false

static func inicial() -> Dictionary:
    return {"versao":1,"estoque":{},"pedidos":[],"proximo":1,"cliente":{},"montagem":{},"pcs":[],"caixa":[],"servico":{},"ordens_servico":[],"fila_os":[],"campanha":CAMPANHA.inicial()}

func carregar(dados: Dictionary) -> bool:
    if not validar(dados):
        return _erro("Estado comercial invalido; progresso preservado.")
    estado = dados.duplicate(true)
    if not estado.has("servico"):
        estado["servico"] = {}
    if not estado.has("ordens_servico"):
        estado["ordens_servico"] = []
    if not estado.has("fila_os"):
        estado["fila_os"] = []
    if not estado.has("campanha"):
        estado["campanha"] = CAMPANHA.migrar(estado)
    ultimo_erro = ""
    return true

func _erro(mensagem: String) -> bool:
    ultimo_erro = mensagem
    push_warning(mensagem)
    return false

func _id() -> int:
    var id := int(estado["proximo"])
    estado["proximo"] = id + 1
    return id

func quantidade(id: String) -> int:
    return int(estado["estoque"].get(id,0))

func comprar(id: String, saldo: int, fornecedor: String = "bairro") -> int:
    ultimo_erro = ""
    if not CATALOGO.PECAS.has(id) or not CAMPANHA.FORNECEDORES.has(fornecedor):
        _erro("Peca desconhecida.")
        return 0
    var custo: int = CATALOGO.PECAS[id]["custo"]
    if saldo < custo:
        _erro("Dinheiro insuficiente para o fornecedor.")
        return 0
    var numero := _id()
    estado["pedidos"].append({"id":numero,"peca":id,"restante":CAMPANHA.FORNECEDORES[fornecedor]["prazo"],"recebido":false,"fornecedor":fornecedor})
    estado["caixa"].append({"id":"compra_%d" % numero,"tipo":"compra","valor":-custo,"custo":0})
    return -custo

func avancar(delta: float) -> void:
    for pedido: Dictionary in estado["pedidos"]:
        if not pedido["recebido"]:
            pedido["restante"] = maxf(0,float(pedido["restante"]) - delta)

func receber(numero: int) -> bool:
    ultimo_erro = ""
    for pedido: Dictionary in estado["pedidos"]:
        if int(pedido["id"]) != numero:
            continue
        if pedido["recebido"]:
            return _erro("Entrega ja recebida; estoque nao foi duplicado.")
        if float(pedido["restante"]) > 0:
            return _erro("Pedido ainda esta em transporte.")
        pedido["recebido"] = true
        var id: String = pedido["peca"]
        estado["estoque"][id] = quantidade(id) + 1
        return true
    return _erro("Pedido de fornecedor inexistente.")

func criar_cliente(id: String = "", pc: bool = false, jogo: String = "") -> bool:
    ultimo_erro = ""
    if not estado["cliente"].is_empty():
        return _erro("Aguarde o cliente atual sair.")
    if pc and total_os() >= MAX_OS:
        return _erro("Oficina lotada: limite de quatro OS/PCs em andamento.")
    if not pc and (not CATALOGO.PECAS.has(id) or quantidade(id) < 1):
        return _erro("Receba uma peca em estoque antes de chamar o cliente.")
    if pc and not jogo.is_empty() and not JOGOS.JOGOS.has(jogo):
        return _erro("Jogo solicitado desconhecido.")
    var numero := _id()
    estado["cliente"] = {"id":numero,"produto":id,"tipo":"pc" if pc else "peca","fase":"entrando"}
    if pc:
        estado["montagem"] = {"id":numero,"fase":"montando","pecas":{},"conectado":false,"preco":JOGOS.buscar(jogo)["orcamento"],"jogo":jogo,"diagnostico":{}}
    return true

func vender() -> int:
    ultimo_erro = ""
    var cliente: Dictionary = estado["cliente"]
    if cliente.is_empty() or cliente["fase"] != "aguardando":
        _erro("Cliente ainda nao esta no balcao.")
        return 0
    for lancamento: Dictionary in estado["caixa"]:
        if lancamento["id"] == "venda_%d" % int(cliente["id"]):
            _erro("Pagamento desse cliente ja registrado.")
            return 0
    if cliente["tipo"] == "servico":
        var servico: Dictionary = estado["servico"]
        if servico["fase"] != "pronto":
            _erro("Conclua e teste a OS antes de entregar.")
            return 0
        servico["fase"] = "entregue"
        estado["ordens_servico"].append(servico.duplicate(true))
        cliente["fase"] = "saindo"
        var valor := int(servico["preco"])
        estado["caixa"].append({"id":"venda_%d" % int(cliente["id"]),"tipo":"servico","valor":valor,"custo":int(servico["custo"])})
        return valor
    if cliente["tipo"] == "pc":
        var montagem: Dictionary = estado["montagem"]
        if montagem.is_empty() or montagem["fase"] != "testado":
            _erro("Monte, conecte e teste o PC antes da entrega.")
            return 0
        montagem["fase"] = "entregue"
        estado["pcs"].append(montagem.duplicate(true))
        cliente["fase"] = "saindo"
        var preco := int(montagem["preco"])
        estado["caixa"].append({"id":"venda_%d" % int(cliente["id"]),"tipo":"pc","valor":preco,"custo":custo_pc()})
        return preco
    var id: String = cliente["produto"]
    if quantidade(id) < 1:
        _erro("Produto solicitado sem estoque.")
        return 0
    estado["estoque"][id] = quantidade(id) - 1
    cliente["fase"] = "saindo"
    var dados: Dictionary = CATALOGO.PECAS[id]
    estado["caixa"].append({"id":"venda_%d" % int(cliente["id"]),"tipo":"venda","valor":int(dados["venda"]),"custo":int(dados["custo"])})
    return int(dados["venda"])

func instalar(id: String, categoria: String) -> bool:
    ultimo_erro = ""
    var montagem: Dictionary = estado["montagem"]
    if not categoria in CATALOGO.CATEGORIAS:
        return _erro("Encaixe de hardware desconhecido.")
    if montagem.is_empty() or not montagem["fase"] in ["montando","testado"]:
        return _erro("Receba um pedido de PC antes de instalar pecas.")
    if not CATALOGO.PECAS.has(id) or CATALOGO.PECAS[id]["categoria"] != categoria:
        return _erro("Peca nao corresponde ao encaixe.")
    if quantidade(id) < 1:
        return _erro("Peca indisponivel; pode estar reservada na montagem.")
    var pecas: Dictionary = montagem["pecas"].duplicate()
    if categoria != "gabinete" and not pecas.has("gabinete"):
        return _erro("Instale o gabinete primeiro.")
    if categoria in ["cpu","ram","gpu","ssd"] and not pecas.has("placa"):
        return _erro("Instale a placa-mae primeiro.")
    if categoria == "cooler" and not pecas.has("cpu"):
        return _erro("Instale a CPU antes do cooler.")
    pecas[categoria] = id
    var erro := CATALOGO.incompatibilidade(pecas)
    if not erro.is_empty():
        return _erro(erro)
    var custo := 0
    for peca in pecas.values():
        custo += int(CATALOGO.PECAS[peca]["custo"])
    if custo > int(montagem["preco"]):
        return _erro("Pecas excedem o orcamento do pedido.")
    if montagem["pecas"].has(categoria):
        var anterior: String = montagem["pecas"][categoria]
        estado["estoque"][anterior] = quantidade(anterior) + 1
    estado["estoque"][id] = quantidade(id) - 1
    montagem["pecas"] = pecas
    montagem["conectado"] = false
    montagem["diagnostico"] = {}
    montagem["fase"] = "montando"
    return true

func remover(categoria: String) -> bool:
    ultimo_erro = ""
    var montagem: Dictionary = estado["montagem"]
    if montagem.is_empty() or not montagem["fase"] in ["montando","testado"] or not montagem["pecas"].has(categoria):
        return _erro("Nao ha peca removivel nesse encaixe.")
    if categoria == "gabinete" and montagem["pecas"].size() > 1:
        return _erro("Remova os componentes antes do gabinete.")
    if categoria == "placa":
        for dependente in ["cpu","ram","gpu","ssd"]:
            if montagem["pecas"].has(dependente):
                return _erro("Remova CPU, RAM, GPU e SSD antes da placa.")
    if categoria == "cpu" and montagem["pecas"].has("cooler"):
        return _erro("Remova o cooler antes da CPU.")
    var id: String = montagem["pecas"][categoria]
    estado["estoque"][id] = quantidade(id) + 1
    montagem["pecas"].erase(categoria)
    montagem["conectado"] = false
    montagem["diagnostico"] = {}
    montagem["fase"] = "montando"
    return true

func conectar() -> bool:
    ultimo_erro = ""
    if not _completo():
        return _erro("Instale os oito componentes antes de conectar os cabos.")
    estado["montagem"]["conectado"] = true
    return true

func testar() -> bool:
    ultimo_erro = ""
    teste_executado = false
    if not _completo() or not estado["montagem"]["conectado"]:
        return _erro("PC incompleto ou com cabos desconectados.")
    var pecas: Dictionary = estado["montagem"]["pecas"]
    var jogo := JOGOS.buscar(estado["montagem"].get("jogo",""))
    var diagnostico := medir(pecas,jogo)
    estado["montagem"]["diagnostico"] = diagnostico
    teste_executado = true
    estado["montagem"]["fase"] = "montando"
    if not diagnostico["temperatura"]:
        return _erro("Superaquecimento: CPU %.1f C, GPU %.1f C. Troque cooler ou gabinete e teste novamente." % [diagnostico["cpu_c"],diagnostico["gpu_c"]])
    if not diagnostico["estabilidade"]:
        return _erro("Instabilidade: fonte sem margem de 10%%. Consumo %d W; margem %d W." % [diagnostico["consumo_w"],diagnostico["margem_w"]])
    if not diagnostico["desempenho"]:
        return _erro("PC abaixo dos requisitos de " + str(jogo["nome"]) + ". Melhore as pecas e repita o teste.")
    estado["montagem"]["fase"] = "testado"
    return true

static func medir(pecas: Dictionary, jogo: Dictionary) -> Dictionary:
    var cpu: Dictionary = CATALOGO.PECAS[pecas["cpu"]]
    var gpu: Dictionary = CATALOGO.PECAS[pecas["gpu"]]
    var cooler: Dictionary = CATALOGO.PECAS[pecas["cooler"]]
    var fonte: Dictionary = CATALOGO.PECAS[pecas["fonte"]]
    var calor := float(CATALOGO.PECAS[pecas["gabinete"]].get("calor",0))
    var cpu_c := 35.0 + float(cpu["watts"]) / float(cooler["tdp"]) * 35.0 + calor
    var gpu_c := 35.0 + float(gpu["watts"]) * 0.15 + calor
    var consumo := 100 + int(cpu["watts"]) + int(gpu["watts"])
    var margem := int(fonte["watts"]) - consumo
    var desempenho := int(cpu["pontos"]) >= int(jogo["cpu"]) and int(gpu["pontos"]) >= int(jogo["gpu"]) and int(CATALOGO.PECAS[pecas["ram"]]["gb"]) >= int(jogo["ram"]) and int(CATALOGO.PECAS[pecas["ssd"]]["gb"]) >= int(jogo["ssd"])
    return {"boot":true,"temperatura":cpu_c <= 80 and gpu_c <= 85,"estabilidade":margem >= ceili(consumo * 0.1),"desempenho":desempenho,"cpu_c":cpu_c,"gpu_c":gpu_c,"consumo_w":consumo,"margem_w":margem}

func plano_automatico() -> Dictionary:
    if estado["montagem"].is_empty() or estado["montagem"]["fase"] != "montando":
        return {}
    return _buscar_plano({},0,0,JOGOS.buscar(estado["montagem"].get("jogo","")))

func _buscar_plano(pecas: Dictionary, indice: int, custo: int, jogo: Dictionary) -> Dictionary:
    if indice == CATALOGO.CATEGORIAS.size():
        var diagnostico := medir(pecas,jogo)
        return pecas if diagnostico["temperatura"] and diagnostico["estabilidade"] and diagnostico["desempenho"] else {}
    var categoria: String = CATALOGO.CATEGORIAS[indice]
    var opcoes: Array = []
    var instaladas: Dictionary = estado["montagem"]["pecas"]
    for id in CATALOGO.PECAS:
        if CATALOGO.PECAS[id]["categoria"] != categoria:
            continue
        if instaladas.has(categoria):
            if instaladas[categoria] == id:
                opcoes.append(id)
        elif quantidade(id) > 0:
            opcoes.append(id)
    opcoes.sort_custom(func(a: String,b: String) -> bool: return int(CATALOGO.PECAS[a]["custo"]) < int(CATALOGO.PECAS[b]["custo"]))
    for id in opcoes:
        var total := custo + int(CATALOGO.PECAS[id]["custo"])
        if total > int(estado["montagem"]["preco"]):
            continue
        var candidato := pecas.duplicate()
        candidato[categoria] = id
        if not CATALOGO.incompatibilidade(candidato).is_empty():
            continue
        var plano := _buscar_plano(candidato,indice + 1,total,jogo)
        if not plano.is_empty():
            return plano
    return {}

func cancelar_montagem() -> bool:
    ultimo_erro = ""
    var montagem: Dictionary = estado["montagem"]
    if montagem.is_empty() or not montagem["fase"] in ["montando","testado"]:
        return _erro("Nao ha montagem ativa para cancelar.")
    for id in montagem["pecas"].values():
        estado["estoque"][id] = quantidade(id) + 1
    montagem["pecas"] = {}
    montagem["conectado"] = false
    montagem["diagnostico"] = {}
    montagem["fase"] = "cancelado"
    estado["cliente"]["fase"] = "saindo"
    return true

func _completo() -> bool:
    var montagem: Dictionary = estado["montagem"]
    return not montagem.is_empty() and montagem["fase"] in ["montando","testado"] and montagem["pecas"].size() == CATALOGO.CATEGORIAS.size() and CATALOGO.incompatibilidade(montagem["pecas"]).is_empty()

func custo_pc() -> int:
    var custo := 0
    for id in estado["montagem"].get("pecas",{}).values():
        custo += int(CATALOGO.PECAS[id]["custo"])
    return custo

func resumo() -> Dictionary:
    var totais := {"compras":0,"receita":0,"cmv":0,"lucro":0}
    for item: Dictionary in estado["caixa"]:
        if item["tipo"] == "compra":
            totais["compras"] -= int(item["valor"])
        else:
            totais["receita"] += int(item["valor"])
            totais["cmv"] += int(item["custo"])
    totais["lucro"] = totais["receita"] - totais["cmv"]
    return totais

static func _inteiro(valor: Variant, minimo: int = 0) -> bool:
    return (valor is int or valor is float) and is_finite(float(valor)) and float(valor) >= minimo and float(valor) <= 2147483647 and float(valor) == floorf(float(valor))

static func validar(dados: Dictionary) -> bool:
    if dados.get("versao") != 1 or not _inteiro(dados.get("proximo"),1) or not dados.get("estoque") is Dictionary:
        return false
    if dados.has("campanha") and (not dados["campanha"] is Dictionary or not CAMPANHA.validar(dados["campanha"])):
        return false
    for id in dados["estoque"]:
        if not CATALOGO.PECAS.has(id) or not _inteiro(dados["estoque"][id]):
            return false
    if not dados.get("pedidos") is Array or not dados.get("caixa") is Array or not dados.get("pcs") is Array:
        return false
    var ids: Dictionary = {}
    for pedido in dados["pedidos"]:
        if not pedido is Dictionary or not _inteiro(pedido.get("id"),1) or not CATALOGO.PECAS.has(pedido.get("peca","")) or not pedido.get("recebido") is bool:
            return false
        var restante: Variant = pedido.get("restante")
        if not (restante is float or restante is int) or not is_finite(float(restante)) or float(restante) < 0 or float(restante) > PRAZO_ENTREGA:
            return false
        if ids.has(pedido["id"]) or float(pedido["id"]) >= float(dados["proximo"]):
            return false
        if not pedido.get("fornecedor","bairro") in CAMPANHA.FORNECEDORES:
            return false
        ids[pedido["id"]] = true
    ids.clear()
    for item in dados["caixa"]:
        if not item is Dictionary or not item.get("id") is String or ids.has(item["id"]) or not item.get("tipo") in ["compra","venda","pc","servico"] or not _inteiro(item.get("custo")):
            return false
        var valor: Variant = item.get("valor")
        if not (valor is int or valor is float):
            return false
        if not _inteiro(-float(valor) if item["tipo"] == "compra" else valor,1):
            return false
        ids[item["id"]] = true
    var lancamentos := ids.duplicate()
    if not dados.get("cliente") is Dictionary or not dados.get("montagem") is Dictionary:
        return false
    var cliente: Dictionary = dados["cliente"]
    if not cliente.is_empty():
        if not _inteiro(cliente.get("id"),1) or float(cliente["id"]) >= float(dados["proximo"]) or not cliente.get("fase") in ["entrando","aguardando","saindo"] or not cliente.get("tipo") in ["peca","pc","servico"]:
            return false
        if cliente["tipo"] == "peca" and not CATALOGO.PECAS.has(cliente.get("produto","")):
            return false
        if cliente["tipo"] == "servico" and not SERVICOS.ITENS.has(cliente.get("produto","")):
            return false
        if cliente["fase"] != "saindo" and lancamentos.has("venda_%d" % int(cliente["id"])):
            return false
    var montagem: Dictionary = dados["montagem"]
    if not _validar_montagem(montagem):
        return false
    if not montagem.is_empty() and float(montagem["id"]) >= float(dados["proximo"]):
        return false
    if not montagem.is_empty() and montagem["fase"] in ["montando","testado"]:
        if cliente.is_empty() or cliente["tipo"] != "pc" or montagem["id"] != cliente["id"]:
            return false
    ids.clear()
    for pc in dados["pcs"]:
        if not pc is Dictionary or not _validar_montagem(pc) or pc.is_empty() or pc["fase"] != "entregue" or ids.has(pc["id"]):
            return false
        if not lancamentos.has("venda_%d" % int(pc["id"])):
            return false
        ids[pc["id"]] = true
    if not dados.get("servico",{}) is Dictionary or not dados.get("ordens_servico",[]) is Array:
        return false
    var servico: Dictionary = dados.get("servico",{})
    if not _validar_os(servico):
        return false
    if not servico.is_empty() and not servico["fase"] in ["entregue","cancelado"]:
        if cliente.is_empty() or cliente["tipo"] != "servico" or cliente["id"] != servico["id"]:
            return false
    ids.clear()
    for os_dados in dados.get("ordens_servico",[]):
        if not os_dados is Dictionary or os_dados.is_empty() or not _validar_os(os_dados) or os_dados["fase"] != "entregue" or ids.has(os_dados["id"]) or not lancamentos.has("venda_%d" % int(os_dados["id"])):
            return false
        ids[os_dados["id"]] = true
    if not dados.get("fila_os",[]) is Array or dados.get("fila_os",[]).size() + (1 if not servico.is_empty() and not servico["fase"] in ["entregue","cancelado"] else 0) + (1 if montagem.get("fase") in ["montando","testado"] else 0) > MAX_OS:
        return false
    for pacote in dados.get("fila_os",[]):
        if not pacote is Dictionary or not pacote.get("os") is Dictionary or not pacote.get("cliente") is Dictionary:
            return false
        var ordem: Dictionary = pacote["os"]
        var dono: Dictionary = pacote["cliente"]
        if ordem.is_empty() or not _validar_os(ordem) or ordem["fase"] != "execucao" or ids.has(ordem["id"]) or float(ordem["id"]) >= float(dados["proximo"]):
            return false
        if dono.get("id") != ordem["id"] or dono.get("tipo") != "servico" or dono.get("fase") != "aguardando" or dono.get("produto") != ordem["tipo"]:
            return false
        if not servico.is_empty() and servico["id"] == ordem["id"] or not ordem.has("reservas") or lancamentos.has("venda_%d" % int(ordem["id"])):
            return false
        ids[ordem["id"]] = true
    return true

func abrir_os(tipo: String, caso: String = "") -> bool:
    ultimo_erro = ""
    if not caso.is_empty() and (tipo != "reparo" or not SERVICOS.CASOS.has(caso)):
        return _erro("Cenario de reparo desconhecido.")
    if total_os() >= MAX_OS:
        return _erro("Oficina lotada: limite de quatro OS/PCs em andamento.")
    if not SERVICOS.ITENS.has(tipo) or not estado["cliente"].is_empty():
        return _erro("Tipo de servico invalido ou atendimento ocupado.")
    var id := _id()
    estado["cliente"] = {"id":id,"produto":tipo,"tipo":"servico","fase":"entrando"}
    estado["servico"] = {"id":id,"tipo":tipo,"fase":"recepcao","preco":SERVICOS.ITENS[tipo]["preco"],"pecas":SERVICOS.pc_inicial(tipo),
        "poeira":80 if tipo in ["limpeza","manutencao"] else 20,"relatorio":"","custo":0,"consumidos":{},"devolvidos":{},"teste":false,"pasta_trocada":false}
    if not caso.is_empty():
        var ordem: Dictionary = estado["servico"]
        ordem["caso"] = caso
        ordem["ensaios"] = []
        ordem["corrigido"] = false
        ordem["preco"] = SERVICOS.CASOS[caso]["preco"]
        ordem["pecas"]["fonte"] = "fonte_clara"
    return true

func investigar_os(ensaio: String) -> bool:
    ultimo_erro = ""
    var ordem: Dictionary = estado["servico"]
    if ordem.is_empty() or not ordem.has("caso") or ordem["fase"] != "recepcao" or not ensaio in SERVICOS.ENSAIOS:
        return _erro("Selecione uma OS investigativa e um ensaio valido na recepcao.")
    if not ensaio in ordem["ensaios"]:
        ordem["ensaios"].append(ensaio)
    var medidas := SERVICOS.medir_caso(ordem["caso"],false)
    var resultados: PackedStringArray = []
    for realizado in ordem["ensaios"]:
        match realizado:
            "memoria": resultados.append("Memoria: %d erros" % medidas["erros_memoria"])
            "carga": resultados.append("CPU: %d C" % medidas["cpu_c"])
            "disco": resultados.append("Saude SSD: %d%%" % medidas["saude_ssd"])
    ordem["relatorio"] = "Medicoes simuladas: " + "; ".join(resultados)
    return true

func diagnosticar_os() -> bool:
    ultimo_erro = ""
    var os_dados: Dictionary = estado["servico"]
    if os_dados.is_empty() or os_dados["fase"] != "recepcao":
        return _erro("Receba uma OS antes do diagnostico.")
    var tipo: String = os_dados["tipo"]
    if os_dados.has("caso"):
        if not SERVICOS.CASOS[os_dados["caso"]]["ensaio"] in os_dados["ensaios"]:
            return _erro("Execute o ensaio indicado para comprovar o defeito antes do orcamento.")
        os_dados["fase"] = "orcamento"
        return true
    os_dados["relatorio"] = "Fonte com margem insuficiente para estabilidade." if tipo in ["reparo","diagnostico"] else "RAM atual 8 GB; solicitado upgrade para 16 GB." if tipo == "upgrade" else "Acumulo de poeira: %d%%." % int(os_dados["poeira"])
    os_dados["fase"] = "orcamento"
    return true

func aprovar_os() -> bool:
    ultimo_erro = ""
    if estado["servico"].is_empty() or estado["servico"]["fase"] != "orcamento" or estado["cliente"]["fase"] != "aguardando":
        return _erro("Diagnostique antes de aprovar o orcamento.")
    estado["servico"]["fase"] = "execucao"
    return true

func executar_os() -> bool:
    ultimo_erro = ""
    var os_dados: Dictionary = estado["servico"]
    if os_dados.is_empty() or os_dados["fase"] != "execucao":
        return _erro("Aprove o orcamento antes de executar.")
    var tipo: String = os_dados["tipo"]
    var necessarios: Dictionary = SERVICOS.necessarios(os_dados)
    for id in necessarios:
        if int(os_dados.get("reservas",{}).get(id,0)) + quantidade(id) < int(necessarios[id]):
            return _erro("Falta para executar a OS: " + str(CATALOGO.PECAS[id]["nome"]))
    for id in necessarios:
        var quantidade_usada := int(necessarios[id])
        if os_dados.get("reservas",{}).has(id):
            os_dados["reservas"].erase(id)
        else:
            estado["estoque"][id] = quantidade(id) - quantidade_usada
        os_dados["consumidos"][id] = quantidade_usada
        os_dados["custo"] = int(os_dados["custo"]) + int(CATALOGO.PECAS[id]["custo"]) * quantidade_usada
    if os_dados.has("caso"):
        var caso: Dictionary = SERVICOS.CASOS[os_dados["caso"]]
        var categoria: String = caso["categoria"]
        os_dados["devolvidos"][categoria] = os_dados["pecas"][categoria]
        os_dados["pecas"][categoria] = caso["peca"]
        os_dados["corrigido"] = true
    elif tipo in ["upgrade","reparo"]:
        var categoria := "ram" if tipo == "upgrade" else "fonte"
        os_dados["devolvidos"][categoria] = os_dados["pecas"][categoria]
        os_dados["pecas"][categoria] = "ram_brisa16" if tipo == "upgrade" else "fonte_clara"
    if tipo in ["limpeza","manutencao"]:
        os_dados["poeira"] = 0
    if tipo == "manutencao":
        os_dados["pasta_trocada"] = true
    os_dados["fase"] = "teste"
    return true

func testar_os() -> bool:
    ultimo_erro = ""
    var os_dados: Dictionary = estado["servico"]
    if os_dados.is_empty() or os_dados["fase"] != "teste":
        return _erro("Execute o servico antes do teste final.")
    var tipo: String = os_dados["tipo"]
    var ok := false
    match tipo:
        "diagnostico": ok = not os_dados["relatorio"].is_empty()
        "upgrade": ok = int(CATALOGO.PECAS[os_dados["pecas"]["ram"]]["gb"]) >= 16
        "reparo": ok = os_dados["pecas"]["fonte"] == "fonte_clara"
        "limpeza","manutencao": ok = int(os_dados["poeira"]) == 0
    if tipo == "manutencao":
        ok = ok and os_dados["pasta_trocada"]
    if os_dados.has("caso"):
        var medidas := SERVICOS.medir_caso(os_dados["caso"],os_dados["corrigido"])
        ok = os_dados["corrigido"] and medidas["erros_memoria"] == 0 and medidas["cpu_c"] <= 80 and medidas["saude_ssd"] >= 80
        os_dados["relatorio"] += "\nApos reparo: memoria %d erros; CPU %d C; SSD %d%%. Peca antiga devolvida ao cliente." % [medidas["erros_memoria"],medidas["cpu_c"],medidas["saude_ssd"]]
    if not ok:
        return _erro("Teste final reprovou o resultado do servico.")
    os_dados["teste"] = true
    os_dados["fase"] = "pronto"
    return true

func cancelar_os() -> bool:
    ultimo_erro = ""
    var os_dados: Dictionary = estado["servico"]
    if os_dados.is_empty() or not os_dados["fase"] in ["recepcao","orcamento","execucao"]:
        return _erro("OS executada deve ser testada e entregue; cancelamento so antes do consumo.")
    for id in os_dados.get("reservas",{}):
        estado["estoque"][id] = quantidade(id) + int(os_dados["reservas"][id])
    os_dados["reservas"] = {}
    os_dados["fase"] = "cancelado"
    estado["cliente"]["fase"] = "saindo"
    return true

func total_os() -> int:
    return estado["fila_os"].size() + (1 if not estado["servico"].is_empty() and not estado["servico"]["fase"] in ["cancelado","entregue"] else 0) + (1 if estado["montagem"].get("fase") in ["montando","testado"] else 0)

func estacionar_os() -> bool:
    ultimo_erro = ""
    var ordem: Dictionary = estado["servico"]
    if ordem.is_empty() or ordem["fase"] != "execucao" or estado["cliente"].get("fase") != "aguardando":
        return _erro("Aprove a OS com o cliente antes de guardar o PC na oficina.")
    var necessarios: Dictionary = SERVICOS.necessarios(ordem)
    if not ordem.has("reservas"):
        for id in necessarios:
            if quantidade(id) < int(necessarios[id]):
                return _erro("Falta estoque para reservar a OS: " + str(CATALOGO.PECAS[id]["nome"]))
        ordem["reservas"] = necessarios.duplicate()
        for id in necessarios:
            estado["estoque"][id] = quantidade(id) - int(necessarios[id])
    ordem["prioridade"] = int(ordem.get("prioridade",1))
    estado["fila_os"].append({"os":ordem.duplicate(true),"cliente":estado["cliente"].duplicate(true)})
    estado["servico"] = {}
    estado["cliente"] = {}
    return true

func retomar_os(numero: int) -> bool:
    ultimo_erro = ""
    if not estado["cliente"].is_empty():
        return _erro("Libere o atendimento antes de retomar outra OS.")
    for i in range(estado["fila_os"].size()):
        var pacote: Dictionary = estado["fila_os"][i]
        if int(pacote["os"]["id"]) == numero:
            estado["servico"] = pacote["os"].duplicate(true)
            estado["cliente"] = pacote["cliente"].duplicate(true)
            estado["fila_os"].remove_at(i)
            return true
    return _erro("OS pendente inexistente.")

func priorizar_os(numero: int, prioridade: int) -> bool:
    ultimo_erro = ""
    if prioridade < 0 or prioridade > 2:
        return _erro("Prioridade invalida: use urgente, normal ou baixa.")
    for pacote: Dictionary in estado["fila_os"]:
        if int(pacote["os"]["id"]) == numero:
            pacote["os"]["prioridade"] = prioridade
            return true
    return _erro("OS pendente inexistente.")

func proxima_os() -> int:
    var escolhida: Dictionary = {}
    for pacote: Dictionary in estado["fila_os"]:
        var ordem: Dictionary = pacote["os"]
        if escolhida.is_empty() or int(ordem["prioridade"]) < int(escolhida["prioridade"]) or (ordem["prioridade"] == escolhida["prioridade"] and int(ordem["id"]) < int(escolhida["id"])):
            escolhida = ordem
    return int(escolhida.get("id",0))

static func _validar_os(os_dados: Dictionary) -> bool:
    if os_dados.is_empty():
        return true
    if not _inteiro(os_dados.get("id"),1) or not SERVICOS.ITENS.has(os_dados.get("tipo","")) or not os_dados.get("fase") in ["recepcao","orcamento","execucao","teste","pronto","entregue","cancelado"]:
        return false
    if os_dados.has("caso"):
        if os_dados["tipo"] != "reparo" or not SERVICOS.CASOS.has(os_dados["caso"]) or not os_dados.get("ensaios") is Array or not os_dados.get("corrigido") is bool:
            return false
        var vistos: Array = []
        for ensaio in os_dados["ensaios"]:
            if not ensaio in SERVICOS.ENSAIOS or ensaio in vistos:
                return false
            vistos.append(ensaio)
        if os_dados["fase"] in ["orcamento","execucao","teste","pronto","entregue"] and not SERVICOS.CASOS[os_dados["caso"]]["ensaio"] in vistos:
            return false
        if os_dados["fase"] in ["teste","pronto","entregue"] and not os_dados["corrigido"]:
            return false
    if not _inteiro(os_dados.get("preco"),1) or not _inteiro(os_dados.get("custo")) or not _inteiro(os_dados.get("poeira")) or float(os_dados["poeira"]) > 100 or not os_dados.get("relatorio") is String or not os_dados.get("teste") is bool or not os_dados.get("pasta_trocada") is bool:
        return false
    if not os_dados.get("pecas") is Dictionary or os_dados["pecas"].size() != 8 or not CATALOGO.incompatibilidade(os_dados["pecas"]).is_empty():
        return false
    if not _inteiro(os_dados.get("prioridade",1)) or float(os_dados.get("prioridade",1)) > 2 or not os_dados.get("perfil","") is String or not os_dados.get("reservas",{}) is Dictionary:
        return false
    var reservas: Dictionary = os_dados.get("reservas",{})
    if os_dados.has("reservas") and os_dados["fase"] == "execucao":
        var necessarios: Dictionary = SERVICOS.necessarios(os_dados)
        if reservas.size() != necessarios.size():
            return false
        for id in reservas:
            if not necessarios.has(id) or not _inteiro(reservas[id],1) or reservas[id] != necessarios[id]:
                return false
    elif not reservas.is_empty():
        return false
    for campo in ["consumidos","devolvidos"]:
        if not os_dados.get(campo) is Dictionary:
            return false
    for id in os_dados["consumidos"]:
        if not CATALOGO.PECAS.has(id) or not _inteiro(os_dados["consumidos"][id],1):
            return false
    for categoria in os_dados["devolvidos"]:
        var id: Variant = os_dados["devolvidos"][categoria]
        if not CATALOGO.PECAS.has(id) or CATALOGO.PECAS[id]["categoria"] != categoria:
            return false
    return not os_dados["fase"] in ["pronto","entregue"] or os_dados["teste"]

static func _validar_montagem(montagem: Dictionary) -> bool:
    if montagem.is_empty():
        return true
    if not _inteiro(montagem.get("id"),1) or not montagem.get("fase") in ["montando","testado","entregue","cancelado"] or not montagem.get("pecas") is Dictionary or not montagem.get("conectado") is bool or not _inteiro(montagem.get("preco"),1):
        return false
    if not montagem.get("jogo","") is String or (not montagem.get("jogo","").is_empty() and not JOGOS.JOGOS.has(montagem["jogo"])):
        return false
    if montagem.has("diagnostico"):
        if not montagem["diagnostico"] is Dictionary:
            return false
        var diagnostico: Dictionary = montagem["diagnostico"]
        if not diagnostico.is_empty():
            for campo in ["boot","temperatura","estabilidade","desempenho"]:
                if not diagnostico.get(campo) is bool or (montagem["fase"] in ["testado","entregue"] and not diagnostico[campo]):
                    return false
            for campo in ["cpu_c","gpu_c","consumo_w","margem_w"]:
                var valor: Variant = diagnostico.get(campo)
                if not (valor is int or valor is float) or not is_finite(float(valor)) or float(valor) < 0:
                    return false
    var pecas: Dictionary = montagem["pecas"]
    if not CATALOGO.incompatibilidade(pecas).is_empty():
        return false
    var custo := 0
    for id in pecas.values():
        custo += int(CATALOGO.PECAS[id]["custo"])
    if custo > int(montagem["preco"]) or (montagem["fase"] == "cancelado" and not pecas.is_empty()):
        return false
    if montagem["fase"] in ["testado","entregue"] and (pecas.size() != CATALOGO.CATEGORIAS.size() or not montagem["conectado"]):
        return false
    return true
