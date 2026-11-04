extends Node2D

const CORES := [Color("#da9947"),Color("#478bc9"),Color("#b45a86"),Color("#5c9b73")]
var estilo := 0
var direcao := "frente"

func configurar(valor: int, lado: String) -> void:
    if estilo == valor and direcao == lado:
        return
    estilo = valor
    direcao = lado
    queue_redraw()

func _draw() -> void:
    if estilo == 0:
        return
    var cor: Color = CORES[(estilo-1)%CORES.size()]
    var centro := Vector2(0,-178)
    if direcao == "esquerda":
        centro.x = -6
    elif direcao == "direita":
        centro.x = 6
    if estilo <= 4:
        draw_rect(Rect2(centro+Vector2(-19,-18),Vector2(38,13)),cor)
        draw_line(centro+Vector2(-24,-5),centro+Vector2(24,-5),cor,5)
    elif direcao != "costas":
        draw_rect(Rect2(centro+Vector2(-17,5),Vector2(13,9)),Color("#233143"),false,2)
        draw_rect(Rect2(centro+Vector2(4,5),Vector2(13,9)),Color("#233143"),false,2)
        draw_line(centro+Vector2(-4,9),centro+Vector2(4,9),cor,2)
