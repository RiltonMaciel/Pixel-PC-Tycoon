extends RefCounted

const ORIGINAL = preload("res://scripts/CatalogoVizinhanca.gd")
const BASE := "res://Assets/Cenarios/AmostrasV1/"
const PADRAO := true
const ESCALA_VEICULOS := 0.85
const CARROS := {
    "carro_azul_baixo_direita":preload(BASE+"veiculos/compacto_azul/baixo_direita.png"),
    "carro_azul_baixo_esquerda":preload(BASE+"veiculos/compacto_azul/baixo_esquerda.png"),
    "carro_azul_cima_direita":preload(BASE+"veiculos/compacto_azul/cima_direita.png"),
    "carro_azul_cima_esquerda":preload(BASE+"veiculos/compacto_azul/cima_esquerda.png"),
    "picape_vermelha_baixo_direita":preload(BASE+"veiculos/picape_vermelha/baixo_direita.png"),
    "picape_vermelha_baixo_esquerda":preload(BASE+"veiculos/picape_vermelha/baixo_esquerda.png"),
    "picape_vermelha_cima_direita":preload(BASE+"veiculos/picape_vermelha/cima_direita.png"),
    "picape_vermelha_cima_esquerda":preload(BASE+"veiculos/picape_vermelha/cima_esquerda.png")
}
const MERCADO := {
    "textura":preload(BASE+"fachadas/mercadinho/mercadinho.png"),"pivo":Vector2(319,486),
    "frente":Vector2(52,407),"canto":Vector2(538,559),
    "fundo":Vector2(661,497)
}

static func loja(id: String, previa: bool) -> Dictionary:
    return MERCADO if previa and id == "mercadinho" else ORIGINAL.ITENS[id]

static func veiculo(id: String, previa: bool) -> Dictionary:
    var novo := id.replace("compacto_azul","carro_azul").replace("compacto_branco","picape_vermelha")
    if previa and CARROS.has(novo):
        return {"textura":CARROS[novo],"pivo":Vector2(256,250),"escala":ESCALA_VEICULOS}
    return ORIGINAL.ITENS[id]
