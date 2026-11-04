extends RefCounted

const ORIGINAL = preload("res://scripts/CatalogoVizinhanca.gd")
const BASE := "res://Assets/Cenarios/PreviaVisual/"
const CARROS := {
    "carro_azul_baixo_direita":preload(BASE+"carro_azul_baixo_direita.png"),
    "carro_azul_baixo_esquerda":preload(BASE+"carro_azul_baixo_esquerda.png"),
    "carro_azul_cima_direita":preload(BASE+"carro_azul_cima_direita.png"),
    "carro_azul_cima_esquerda":preload(BASE+"carro_azul_cima_esquerda.png"),
    "picape_vermelha_baixo_direita":preload(BASE+"picape_vermelha_baixo_direita.png"),
    "picape_vermelha_baixo_esquerda":preload(BASE+"picape_vermelha_baixo_esquerda.png"),
    "picape_vermelha_cima_direita":preload(BASE+"picape_vermelha_cima_direita.png"),
    "picape_vermelha_cima_esquerda":preload(BASE+"picape_vermelha_cima_esquerda.png")
}
const MERCADO := {
    "textura":preload(BASE+"mercadinho.png"),"pivo":Vector2(259,463),
    "frente":Vector2(62,404.4375),"canto":Vector2(456,527.5625),
    "fundo":Vector2(624,443.5625)
}

static func loja(id: String, previa: bool) -> Dictionary:
    return MERCADO if previa and id == "mercadinho" else ORIGINAL.ITENS[id]

static func veiculo(id: String, previa: bool) -> Dictionary:
    var novo := id.replace("compacto_azul","carro_azul").replace("compacto_branco","picape_vermelha")
    if previa and CARROS.has(novo):
        return {"textura":CARROS[novo],"pivo":Vector2(256,220),"escala":1.0}
    return ORIGINAL.ITENS[id]
