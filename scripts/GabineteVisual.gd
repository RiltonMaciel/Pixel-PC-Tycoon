extends Control

const CARTAO = preload("res://scripts/CartaoPeca.gd")
const PECAS = preload("res://scripts/CatalogoPecas.gd")
const POSICOES := {
    "gabinete":Vector2(12,12),"placa":Vector2(112,12),"cpu":Vector2(12,70),"ram":Vector2(112,70),
    "fonte":Vector2(12,128),"ssd":Vector2(112,128),"gpu":Vector2(12,186),"cooler":Vector2(112,186)
}

func configurar(montagem: Dictionary, instalar: Callable) -> void:
    custom_minimum_size = Vector2(220,250)
    for categoria in POSICOES:
        var encaixe := CARTAO.new()
        encaixe.name = "Visual_" + categoria
        encaixe.categoria = categoria
        encaixe.receber = instalar
        encaixe.position = POSICOES[categoria]
        encaixe.size = Vector2(96,50)
        encaixe.add_theme_font_size_override("font_size",9)
        var id: String = montagem["pecas"].get(categoria,"")
        encaixe.text = categoria + "\n" + (PECAS.PECAS[id]["nome"] if not id.is_empty() else "Encaixe vazio")
        add_child(encaixe)
    queue_redraw()

func _draw() -> void:
    var contorno := PackedVector2Array([Vector2(4,4),Vector2(210,4),Vector2(218,12),Vector2(218,245),Vector2(210,245),Vector2(4,245),Vector2(4,4)])
    draw_colored_polygon(contorno,Color("#263848"))
    draw_polyline(contorno,Color("#90b8cc"),2)
    draw_line(Vector2(210,4),Vector2(210,245),Color("#90b8cc"),2)
