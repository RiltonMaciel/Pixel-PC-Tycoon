extends RefCounted

const COMERCIO = preload("res://scripts/Comercio.gd")
const CLIENTES = preload("res://scripts/Clientes.gd")
const EQUIPE = preload("res://scripts/Equipe.gd")
const CAMPANHA = preload("res://scripts/Campanha.gd")
const METAS := {
    "primeira_venda":{"nome":"Primeira venda","opcional":true},
    "primeiro_pc":{"nome":"Primeiro PC entregue","opcional":true},
    "primeira_os":{"nome":"Primeira OS entregue","opcional":true},
    "reputacao":{"nome":"Alcancar reputacao 60","opcional":true},
    "emprego":{"nome":"Contratar um funcionario","opcional":true},
    "crescimento":{"nome":"Alcancar o segundo nivel da campanha","opcional":true}
}
var estado: Dictionary = inicial()
var ultimo_erro := ""

static func inicial() -> Dictionary:
    return {"versao":1,"concluidos":[]}

# Recebe o envelope do save. Somente a ausencia do bloco permite migracao vazia.
static func migrar(save: Dictionary) -> Dictionary:
    if not save.has("objetivos"):
        return inicial()
    return save["objetivos"].duplicate(true) if save["objetivos"] is Dictionary else {}

func carregar(dados: Variant) -> bool:
    if not validar(dados):
        ultimo_erro = "Objetivos invalidos; progresso preservado."
        return false
    estado = dados.duplicate(true)
    ultimo_erro = ""
    return true

func carregar_save(save: Dictionary) -> bool:
    return carregar(migrar(save))

func concluido(id: String) -> bool:
    for registro: Dictionary in estado["concluidos"]:
        if registro["id"] == id:
            return true
    return false

# Registra o dia de reconhecimento, inclusive para conquistas anteriores a migracao.
# Nao modifica os modelos recebidos nem concede dinheiro, estoque ou desbloqueios.
func atualizar(comercio: Dictionary, clientes: Dictionary, equipe: Dictionary, dia: int = 1) -> Array[String]:
    var novos: Array[String] = []
    ultimo_erro = ""
    if not validar(estado) or not _inteiro(dia,1) or not COMERCIO.validar(comercio) or not CLIENTES.validar(clientes) or not EQUIPE.validar(equipe):
        ultimo_erro = "Estado real ou dia invalido; objetivos preservados."
        return novos
    for registro: Dictionary in estado["concluidos"]:
        if float(registro["dia"]) > dia:
            ultimo_erro = "Dia anterior ao ultimo reconhecimento; objetivos preservados."
            return novos
    var pagamentos: Dictionary = {}
    for item: Dictionary in comercio["caixa"]:
        if item["tipo"] in ["venda","pc","servico"] and float(item["valor"]) > 0:
            pagamentos[item["id"]] = item["tipo"]
    var pc_entregue := false
    for pc: Dictionary in comercio["pcs"]:
        if pc["fase"] == "entregue" and pagamentos.get("venda_%d" % int(pc["id"])) == "pc":
            pc_entregue = true
    var os_entregue := false
    for ordem: Dictionary in comercio.get("ordens_servico",[]):
        if ordem["fase"] == "entregue" and pagamentos.get("venda_%d" % int(ordem["id"])) == "servico":
            os_entregue = true
    var reputacao := int(clientes.get("reputacao",50))
    var atingidas := {
        "primeira_venda":not pagamentos.is_empty(),
        "primeiro_pc":pc_entregue,
        "primeira_os":os_entregue,
        "reputacao":reputacao >= 60,
        "emprego":not equipe["contratos"].is_empty(),
        "crescimento":CAMPANHA.nivel(comercio,reputacao) >= 2
    }
    for id in METAS:
        if atingidas[id] and not concluido(id):
            estado["concluidos"].append({"id":id,"dia":dia})
            novos.append(id)
    return novos

static func _inteiro(valor: Variant, minimo: int = 0) -> bool:
    return (valor is int or valor is float) and is_finite(float(valor)) and float(valor) >= minimo and float(valor) <= 9007199254740991.0 and float(valor) == floorf(float(valor))

static func validar(dados: Variant) -> bool:
    if not dados is Dictionary or dados.size() != 2 or not _inteiro(dados.get("versao"),1) or dados["versao"] != 1 or not dados.get("concluidos") is Array:
        return false
    if dados["concluidos"].size() > METAS.size():
        return false
    var ids: Array = []
    var dia_anterior := 1
    for registro in dados["concluidos"]:
        if not registro is Dictionary or registro.size() != 2 or not registro.get("id") is String or not METAS.has(registro["id"]) or registro["id"] in ids or not _inteiro(registro.get("dia"),1):
            return false
        if float(registro["dia"]) < dia_anterior:
            return false
        dia_anterior = int(registro["dia"])
        ids.append(registro["id"])
    return true
