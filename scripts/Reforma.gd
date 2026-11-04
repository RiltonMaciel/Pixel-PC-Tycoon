extends RefCounted

const SETORES := ["","Vendas","Oficina","Estoque"]

static func validar(dados: Dictionary, tamanho: Vector2i) -> bool:
    for chave in dados:
        if not chave is String:
            return false
        var uv: PackedStringArray = chave.split(",")
        if uv.size() != 2 or not uv[0].is_valid_int() or not uv[1].is_valid_int():
            return false
        var u := int(uv[0])
        var v := int(uv[1])
        if chave != "%d,%d" % [u,v] or u < 0 or v < 0 or u >= tamanho.x or v >= tamanho.y:
            return false
        var celula: Variant = dados[chave]
        if not celula is Dictionary or not celula.get("setor") in SETORES:
            return false
        var piso: Variant = celula.get("piso")
        if not (piso is int or piso is float) or not float(piso) in [0.0,1.0,2.0]:
            return false
    return true

static func celula(dados: Dictionary, u: int, v: int) -> Dictionary:
    return dados.get("%d,%d" % [u,v],{"piso":(u*7+v*11)%3,"setor":""}).duplicate(true)
