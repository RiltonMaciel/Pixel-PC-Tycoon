extends Button

const CATALOGO = preload("res://scripts/CatalogoPecas.gd")
var peca := ""
var categoria := ""
var receber: Callable

func _get_drag_data(_at: Vector2) -> Variant:
    if peca.is_empty() or disabled:
        return null
    var preview := Label.new()
    preview.text = CATALOGO.PECAS[peca]["nome"]
    set_drag_preview(preview)
    return {"peca":peca}

func _can_drop_data(_at: Vector2, data: Variant) -> bool:
    return not categoria.is_empty() and data is Dictionary and CATALOGO.PECAS.has(data.get("peca","")) and CATALOGO.PECAS[data["peca"]]["categoria"] == categoria

func _drop_data(_at: Vector2, data: Variant) -> void:
    receber.call(str(data["peca"]),categoria)
