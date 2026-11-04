extends RefCounted

const CANDIDATOS := {
    "lia":{"nome":"Lia","funcao":"caixa","salario":50,"habilidades":{"caixa":65,"tecnico":20,"estoque":35}},
    "rui":{"nome":"Rui","funcao":"tecnico","salario":80,"habilidades":{"caixa":25,"tecnico":70,"estoque":30}},
    "sol":{"nome":"Sol","funcao":"estoque","salario":40,"habilidades":{"caixa":35,"tecnico":25,"estoque":65}},
    "nina":{"nome":"Nina - montagem","funcao":"montador","salario":100,"habilidades":{"caixa":25,"tecnico":60,"estoque":35,"montador":90}},
    "ivo":{"nome":"Ivo - diagnostico","funcao":"tecnico","salario":110,"habilidades":{"caixa":30,"tecnico":90,"estoque":40,"montador":55}},
    "luz":{"nome":"Luz - atendimento","funcao":"caixa","salario":75,"habilidades":{"caixa":90,"tecnico":30,"estoque":45,"montador":25}}
}
const POSTOS := {"caixa":"balcao","tecnico":"bancada","estoque":"notebook","montador":"bancada"}
var estado: Dictionary = inicial()
var ultimo_erro := ""

static func inicial() -> Dictionary:
    return {"versao":1,"contratos":{}}

func carregar(dados: Dictionary) -> bool:
    if not validar(dados):
        return _erro("Contratos de funcionarios invalidos; progresso preservado.")
    estado = dados.duplicate(true)
    for contrato: Dictionary in estado["contratos"].values():
        if not contrato["experiencia"].has("montador"):
            contrato["experiencia"]["montador"] = 0
    return true

func _erro(texto: String) -> bool:
    ultimo_erro = texto
    push_warning(texto)
    return false

func contratar(id: String) -> bool:
    ultimo_erro = ""
    if not CANDIDATOS.has(id) or ativo(id):
        return _erro("Candidato inexistente ou ja contratado.")
    var funcao: String = CANDIDATOS[id]["funcao"]
    if ocupado(funcao):
        return _erro("A funcao ja possui um funcionario. Reatribua ou demita primeiro.")
    if not estado["contratos"].has(id):
        estado["contratos"][id] = {"ativo":true,"funcao":funcao,"acumulado":0.0,"progresso":0.0,
            "experiencia":{"caixa":0,"tecnico":0,"estoque":0,"montador":0},"atividade":"Aguardando tarefa"}
    else:
        estado["contratos"][id]["ativo"] = true
        estado["contratos"][id]["funcao"] = funcao
    return true

func ativo(id: String) -> bool:
    return estado["contratos"].has(id) and estado["contratos"][id]["ativo"]

func ocupado(funcao: String, exceto: String = "") -> bool:
    for id in estado["contratos"]:
        if id != exceto and ativo(id) and estado["contratos"][id]["funcao"] == funcao:
            return true
    return false

func atribuir(id: String, funcao: String) -> bool:
    ultimo_erro = ""
    if not ativo(id) or not POSTOS.has(funcao) or ocupado(funcao,id):
        return _erro("Funcionario/funcao invalida ou posto ocupado.")
    estado["contratos"][id]["funcao"] = funcao
    estado["contratos"][id]["progresso"] = 0.0
    return true

func demitir(id: String) -> bool:
    ultimo_erro = ""
    if not ativo(id):
        return _erro("Funcionario nao contratado.")
    estado["contratos"][id]["ativo"] = false
    estado["contratos"][id]["progresso"] = 0.0
    estado["contratos"][id]["atividade"] = "Demitido; salario devido mantido"
    return true

func habilidade(id: String) -> int:
    var contrato: Dictionary = estado["contratos"][id]
    var funcao: String = contrato["funcao"]
    return mini(100,int(CANDIDATOS[id]["habilidades"].get(funcao,20)) + int(float(contrato["experiencia"].get(funcao,0)) / 5.0))

func avancar(delta: float, segundos_dia: float) -> void:
    for id in estado["contratos"]:
        if ativo(id):
            var contrato: Dictionary = estado["contratos"][id]
            contrato["acumulado"] = float(contrato["acumulado"]) + float(CANDIDATOS[id]["salario"]) * delta / segundos_dia
            contrato["progresso"] = minf(10.0,float(contrato["progresso"]) + delta)

func folha() -> Array[Dictionary]:
    var resultado: Array[Dictionary] = []
    for id in estado["contratos"]:
        var contrato: Dictionary = estado["contratos"][id]
        # A moeda do jogo usa reais inteiros; neutraliza apenas o ruido de ponto flutuante.
        var valor := ceili(snappedf(float(contrato["acumulado"]),0.000001))
        if valor > 0:
            resultado.append({"funcionario":id,"valor":valor})
        contrato["acumulado"] = 0.0
    return resultado

func pronto(id: String) -> bool:
    return ativo(id) and float(estado["contratos"][id]["progresso"]) >= 8.0 - habilidade(id) * 0.04

func registrar(id: String, texto: String, sucesso: bool) -> void:
    var contrato: Dictionary = estado["contratos"][id]
    contrato["progresso"] = 0.0
    contrato["atividade"] = texto
    if sucesso:
        contrato["experiencia"][contrato["funcao"]] += 1

static func _numero(valor: Variant) -> bool:
    return (valor is int or valor is float) and is_finite(float(valor)) and float(valor) >= 0 and float(valor) <= 9007199254740991.0

static func validar(dados: Dictionary) -> bool:
    if dados.get("versao") != 1 or not dados.get("contratos") is Dictionary:
        return false
    var ocupados: Array = []
    for id in dados["contratos"]:
        var contrato: Variant = dados["contratos"][id]
        if not CANDIDATOS.has(id) or not contrato is Dictionary or not contrato.get("ativo") is bool or not contrato.get("funcao") in POSTOS:
            return false
        if not _numero(contrato.get("acumulado")) or not _numero(contrato.get("progresso")) or float(contrato["progresso"]) > 10 or not contrato.get("atividade") is String:
            return false
        if not contrato.get("experiencia") is Dictionary:
            return false
        for funcao in POSTOS:
            var xp: Variant = contrato["experiencia"].get(funcao,0 if funcao == "montador" else null)
            if not _numero(xp) or float(xp) != floorf(float(xp)):
                return false
        if contrato["ativo"]:
            if contrato["funcao"] in ocupados:
                return false
            ocupados.append(contrato["funcao"])
    return true
