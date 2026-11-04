extends Node2D
const CALENDARIO = preload("res://scripts/CalendarioEconomia.gd")

var chovendo := false
var tempo := 0.0

static func previsao(dia: int) -> Dictionary:
    var clima: String = ["Limpo","Nublado","Chuva","Limpo"][(dia-1) % 4]
    var semana := (dia-1) % 7 + 1
    var evento := "Feira de tecnologia" if semana == 7 else "Dia tranquilo" if semana == 3 else "Rotina"
    var demanda := (1.5 if semana == 7 else 0.75 if semana == 3 else 1.0) * (0.75 if clima == "Chuva" else 1.0)
    return {"clima":clima,"evento":evento,"demanda":demanda}

static func iluminacao(segundos: float) -> Color:
    var hora := segundos * 24.0 / CALENDARIO.SEGUNDOS_DIA
    var luz := clampf(minf((hora-5.0)/2.0,(20.0-hora)/2.0),0.0,1.0)
    return Color(0.48,0.55,0.75).lerp(Color.WHITE,luz)

func _process(delta: float) -> void:
    tempo = fmod(tempo + delta,1000.0)
    if chovendo:
        queue_redraw()

func _draw() -> void:
    if not chovendo:
        return
    var size := get_viewport_rect().size
    for i in range(60):
        var ponto := Vector2(fposmod(i * 83.0 - tempo * 55.0,size.x + 30.0) - 15.0,
            fposmod(i * 137.0 + tempo * 360.0,size.y + 30.0) - 15.0)
        draw_line(ponto,ponto + Vector2(-3,12),Color(0.75,0.85,1.0,0.45),1.0)
