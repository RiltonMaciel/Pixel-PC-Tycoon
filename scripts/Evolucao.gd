extends RefCounted

const OBJETIVOS = preload("res://scripts/Objetivos.gd")

static func inicial() -> Dictionary:
    return {"versao":1,"tutorial":0,"aparencia":0,"objetivos":OBJETIVOS.inicial()}

static func validar(dados: Dictionary) -> bool:
    if dados.get("versao") != 1 or not dados.get("objetivos") is Dictionary or not OBJETIVOS.validar(dados["objetivos"]):
        return false
    for campo in ["tutorial","aparencia"]:
        var valor: Variant = dados.get(campo)
        if not (valor is int or valor is float) or not is_finite(float(valor)) or float(valor) != floorf(float(valor)) or float(valor) < 0 or float(valor) > (6 if campo == "tutorial" else 8):
            return false
    return true
