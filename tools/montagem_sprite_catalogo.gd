extends RefCounted
class_name MontagemSpriteCatalogo
## Catálogo visual isolado. Não altera o estoque nem a lógica comercial.
const ROOT := "res://assets/minigames/pc_assembly/"
const SPRITES := {
    "gabinete_vazio": "cabinets/ironbox/alpha_aberto_vazio.png",
    "gabinete_fechado": "cabinets/ironbox/alpha_fechado.png",
    "gabinete_tampa": "cabinets/ironbox/alpha_tampa.png",
    "placa_mae_h450m": "motherboards/hexacore/h450m.png",
    "cpu_c5_5600": "cpus/vortex/c5_5600.png",
    "cabo_sata": "cables/sata.png",
    "trava_aberta": "hardware/trava_aberta.png",
    "pasta_05": "thermal_paste/tp_05.png"
}

static func path_for(sprite_id: String) -> String:
    if not SPRITES.has(sprite_id):
        push_warning("Sprite desconhecido: " + sprite_id)
        return ""
    return ROOT + SPRITES[sprite_id]

static func texture_for(sprite_id: String) -> Texture2D:
    var path := path_for(sprite_id)
    if path.is_empty() or not ResourceLoader.exists(path):
        push_warning("Sprite ausente: " + path)
        return null
    return load(path) as Texture2D

static func validate() -> PackedStringArray:
    var missing := PackedStringArray()
    for sprite_id in SPRITES:
        var path: String = ROOT + SPRITES[sprite_id]
        if not ResourceLoader.exists(path):
            missing.append("%s -> %s" % [sprite_id, path])
    return missing
