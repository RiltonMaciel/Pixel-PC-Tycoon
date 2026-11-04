extends RefCounted

const SEGUNDOS_DIA := 900.0
const DESPESAS := {"aluguel":100,"energia":20}
const EQUIPE = preload("res://scripts/Equipe.gd")
var estado: Dictionary = inicial()
var ultimo_erro := ""
var fechou_dia := false

static func inicial(balanco: Dictionary = {}) -> Dictionary:
    return {"versao":1,"dia":1,"segundos":0.0,"contas":[],"pagamentos":[],"fechamentos":[],
        "base_caixa":{"compras":int(balanco.get("compras",0)),"receita":int(balanco.get("receita",0)),"cmv":int(balanco.get("cmv",0))}}

func carregar(dados: Dictionary) -> bool:
    if not validar(dados):
        return _erro("Calendario/contas invalidos; progresso preservado.")
    estado = dados.duplicate(true)
    ultimo_erro = ""
    fechou_dia = false
    return true

func _erro(mensagem: String) -> bool:
    ultimo_erro = mensagem
    push_warning(mensagem)
    return false

func data() -> Dictionary:
    var indice := int(estado["dia"]) - 1
    var minutos := int(floorf(float(estado["segundos"]) * 1440.0 / SEGUNDOS_DIA))
    return {"dia":indice % 28 + 1,"semana":indice % 7 + 1,"mes":int(indice / 28.0) % 12 + 1,
        "ano":int(indice / 336.0) + 1,"hora":int(minutos / 60.0),"minuto":minutos % 60}

func avancar(delta: float, saldo: int, balanco: Dictionary, equipe: EQUIPE = null) -> int:
    ultimo_erro = ""
    fechou_dia = false
    if not is_finite(delta) or delta < 0 or saldo < 0 or not _balanco_valido(balanco):
        _erro("Tempo, saldo ou balanco invalido; calendario nao avancou.")
        return saldo
    var restante := delta
    while restante > 0:
        var passo := minf(restante,SEGUNDOS_DIA - float(estado["segundos"]))
        if equipe != null:
            equipe.avancar(passo,SEGUNDOS_DIA)
        estado["segundos"] = float(estado["segundos"]) + passo
        restante -= passo
        if float(estado["segundos"]) >= SEGUNDOS_DIA:
            var folha: Array[Dictionary] = []
            if equipe != null:
                folha = equipe.folha()
            saldo = _fechar_dia(saldo,balanco,folha)
            estado["dia"] = int(estado["dia"]) + 1
            estado["segundos"] = 0.0
            fechou_dia = true
    return saldo

func _fechar_dia(saldo: int, balanco: Dictionary, folha: Array[Dictionary] = []) -> int:
    var dia := int(estado["dia"])
    var despesas := 0
    for tipo in DESPESAS:
        var valor: int = DESPESAS[tipo]
        estado["contas"].append({"id":"%s_%d" % [tipo,dia],"dia":dia,"tipo":tipo,"valor":valor,"pago":0})
        despesas += valor
    for salario in folha:
        estado["contas"].append({"id":"salario_%s_%d" % [salario["funcionario"],dia],"dia":dia,"tipo":"salario",
            "funcionario":salario["funcionario"],"valor":salario["valor"],"pago":0})
        despesas += int(salario["valor"])
    saldo = _pagar(saldo)
    var anterior: Dictionary = estado["base_caixa"]
    var receita := int(balanco["receita"]) - int(anterior["receita"])
    var cmv := int(balanco["cmv"]) - int(anterior["cmv"])
    estado["fechamentos"].append({"dia":dia,"compras":int(balanco["compras"]) - int(anterior["compras"]),
        "receita":receita,"cmv":cmv,"despesas":despesas,"lucro":receita - cmv - despesas,
        "saldo":saldo,"divida":divida()})
    estado["base_caixa"] = {"compras":int(balanco["compras"]),"receita":int(balanco["receita"]),"cmv":int(balanco["cmv"])}
    return saldo

func divida() -> int:
    var total := 0
    for conta: Dictionary in estado["contas"]:
        total += int(conta["valor"]) - int(conta["pago"])
    return total

func pagar_contas(saldo: int) -> int:
    ultimo_erro = ""
    if saldo <= 0 or divida() == 0:
        _erro("Nao ha saldo disponivel ou contas pendentes para pagar.")
        return saldo
    return _pagar(saldo)

func _pagar(saldo: int) -> int:
    for conta: Dictionary in estado["contas"]:
        var valor := mini(saldo,int(conta["valor"]) - int(conta["pago"]))
        if valor > 0:
            conta["pago"] = int(conta["pago"]) + valor
            saldo -= valor
            estado["pagamentos"].append({"id":estado["pagamentos"].size() + 1,"conta":conta["id"],"dia":int(estado["dia"]),"valor":valor})
    return saldo

static func _inteiro(valor: Variant, minimo: int = 0) -> bool:
    return (valor is int or valor is float) and is_finite(float(valor)) and float(valor) >= minimo and float(valor) <= 9007199254740991.0 and float(valor) == floorf(float(valor))

static func _balanco_valido(dados: Dictionary) -> bool:
    return _inteiro(dados.get("compras")) and _inteiro(dados.get("receita")) and _inteiro(dados.get("cmv"))

static func validar(dados: Dictionary) -> bool:
    if dados.get("versao") != 1 or not _inteiro(dados.get("dia"),1):
        return false
    var segundos: Variant = dados.get("segundos")
    if not (segundos is float or segundos is int) or not is_finite(float(segundos)) or float(segundos) < 0 or float(segundos) >= SEGUNDOS_DIA:
        return false
    if not dados.get("base_caixa") is Dictionary or not _balanco_valido(dados["base_caixa"]):
        return false
    if not dados.get("contas") is Array or not dados.get("pagamentos") is Array or not dados.get("fechamentos") is Array:
        return false
    var contas: Dictionary = {}
    var pagos: Dictionary = {}
    for conta in dados["contas"]:
        if not conta is Dictionary or not _inteiro(conta.get("dia"),1):
            return false
        var tipo: Variant = conta.get("tipo")
        var id := ""
        if tipo == "salario":
            var funcionario: Variant = conta.get("funcionario")
            if not funcionario in EQUIPE.CANDIDATOS or not _inteiro(conta.get("valor"),1) or float(conta["valor"]) > float(EQUIPE.CANDIDATOS[funcionario]["salario"]):
                return false
            id = "salario_%s_%d" % [funcionario,int(conta["dia"])]
        elif tipo in DESPESAS:
            if conta.get("valor") != DESPESAS[tipo]:
                return false
            id = "%s_%d" % [tipo,int(conta["dia"])]
        else:
            return false
        if conta.get("id") != id or contas.has(id) or float(conta["dia"]) >= float(dados["dia"]):
            return false
        if not _inteiro(conta.get("pago")) or float(conta["pago"]) > float(conta["valor"]):
            return false
        contas[id] = conta
        pagos[id] = 0
    var sequencia := 1
    for pagamento in dados["pagamentos"]:
        if not pagamento is Dictionary or pagamento.get("id") != sequencia or not contas.has(pagamento.get("conta","")):
            return false
        if not _inteiro(pagamento.get("valor"),1) or not _inteiro(pagamento.get("dia"),1) or float(pagamento["dia"]) > float(dados["dia"]):
            return false
        pagos[pagamento["conta"]] += int(pagamento["valor"])
        sequencia += 1
    for id in contas:
        if pagos[id] != contas[id]["pago"]:
            return false
    if dados["fechamentos"].size() != int(dados["dia"]) - 1:
        return false
    sequencia = 1
    for fechamento in dados["fechamentos"]:
        if not fechamento is Dictionary or fechamento.get("dia") != sequencia:
            return false
        for campo in ["compras","receita","cmv","despesas","saldo","divida"]:
            if not _inteiro(fechamento.get(campo)):
                return false
        var total := 0
        for tipo in DESPESAS:
            if not contas.has("%s_%d" % [tipo,sequencia]):
                return false
        for conta: Dictionary in contas.values():
            if conta["dia"] == sequencia:
                total += int(conta["valor"])
        if fechamento["despesas"] != total or fechamento.get("lucro") != float(fechamento["receita"]) - float(fechamento["cmv"]) - total:
            return false
        sequencia += 1
    return true
