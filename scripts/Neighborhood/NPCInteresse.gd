extends RefCounted
## BV-03: perfis e decisoes deterministicas por NPC, sem servicos online.
## A pontuacao e 0..1. A decisao nao modifica economia ou estado de loja.
const PERFIS := [
    {"tipo":"gamer", "interesse_pc":0.95, "orcamento":0.75, "curiosidade":0.8, "paciencia":0.65},
    {"tipo":"estudante", "interesse_pc":0.7, "orcamento":0.35, "curiosidade":0.7, "paciencia":0.7},
    {"tipo":"trabalhador", "interesse_pc":0.5, "orcamento":0.65, "curiosidade":0.35, "paciencia":0.3},
    {"tipo":"morador", "interesse_pc":0.45, "orcamento":0.55, "curiosidade":0.65, "paciencia":0.8}
]

static func perfil(id: int) -> Dictionary:
    var base: Dictionary = PERFIS[posmod(id, PERFIS.size())].duplicate(true)
    base["id"] = id
    base["visitas"] = {}
    base["ultima_loja"] = ""
    base["espera_ate"] = -1.0
    return base

static func interesse_loja(npc: Dictionary, loja_id: String, reputacao: float = 0.5) -> float:
    var interesse := float(npc.get("interesse_pc",0.5)) if loja_id.begins_with("pc_store") else float(npc.get("curiosidade",0.5))
    var orcamento := clampf(float(npc.get("orcamento",0.5)),0.0,1.0)
    var paciencia := clampf(float(npc.get("paciencia",0.5)),0.0,1.0)
    var visitas: Dictionary = npc.get("visitas",{})
    var historico := mini(int(visitas.get(loja_id,0)),3)
    return clampf(interesse * 0.55 + orcamento * 0.15 + paciencia * 0.1 +
        clampf(reputacao,0.0,1.0) * 0.2 - historico * 0.08, 0.0, 1.0)

static func avaliar(npc: Dictionary, loja_id: String, instante: float, reputacao: float = 0.5) -> Dictionary:
    if loja_id.is_empty() or not is_finite(instante):
        return {"decisao":"continuar", "motivo":"entrada_invalida", "pontuacao":0.0}
    if instante < float(npc.get("espera_ate",-1.0)) and str(npc.get("ultima_loja","")) == loja_id:
        return {"decisao":"continuar", "motivo":"cooldown", "pontuacao":0.0}
    var pontuacao := interesse_loja(npc,loja_id,reputacao)
    var decisao := "entrar" if pontuacao >= 0.66 else "observar" if pontuacao >= 0.4 else "continuar"
    return {"decisao":decisao,"motivo":"perfil", "pontuacao":pontuacao}

static func registrar_visita(npc: Dictionary, loja_id: String, instante: float, intervalo: float = 90.0) -> void:
    if loja_id.is_empty() or not is_finite(instante):
        return
    var visitas: Dictionary = npc.get("visitas",{})
    visitas[loja_id] = int(visitas.get(loja_id,0)) + 1
    npc["visitas"] = visitas
    npc["ultima_loja"] = loja_id
    npc["espera_ate"] = instante + maxf(intervalo,0.0)
