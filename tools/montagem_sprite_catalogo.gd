extends RefCounted
class_name MontagemSpriteCatalogo
## 61 sprites do pacote inicial; qualidade artística ainda exige validação.
const ROOT := "res://assets/minigames/pc_assembly/"
const SPRITES := {
    "alpha_fechado": "cabinets/ironbox/alpha_fechado.png",
    "alpha_aberto_vazio": "cabinets/ironbox/alpha_aberto_vazio.png",
    "alpha_placa_mae": "cabinets/ironbox/alpha_placa_mae.png",
    "alpha_montagem_parcial": "cabinets/ironbox/alpha_montagem_parcial.png",
    "alpha_completo": "cabinets/ironbox/alpha_completo.png",
    "alpha_tampa": "cabinets/ironbox/alpha_tampa.png",
    "h450m": "motherboards/hexacore/h450m.png",
    "b670": "motherboards/hexacore/b670.png",
    "x990": "motherboards/hexacore/x990.png",
    "c3_3200": "cpus/vortex/c3_3200.png",
    "c5_5600": "cpus/vortex/c5_5600.png",
    "c7_7700": "cpus/vortex/c7_7700.png",
    "c9_9900x": "cpus/vortex/c9_9900x.png",
    "socket_aberto": "assembly/socket/socket_aberto.png",
    "cpu_socket": "assembly/socket/cpu_socket.png",
    "seringa_pasta": "assembly/socket/seringa_pasta.png",
    "pasta_aplicada": "assembly/socket/pasta_aplicada.png",
    "air_s120": "coolers/frostbyte/air_s120.png",
    "air_d240": "coolers/frostbyte/air_d240.png",
    "water_t240": "coolers/frostbyte/water_t240.png",
    "water_t360": "coolers/frostbyte/water_t360.png",
    "8gb": "ram/voltix/8gb.png",
    "16gb": "ram/voltix/16gb.png",
    "fury": "ram/voltix/fury.png",
    "rgb": "ram/voltix/rgb.png",
    "gtv_1760": "gpu/nebula/gtv_1760.png",
    "rtv_5560": "gpu/nebula/rtv_5560.png",
    "rtv_9090": "gpu/nebula/rtv_9090.png",
    "550w": "psu/powerforge/550w.png",
    "650w": "psu/powerforge/650w.png",
    "850w": "psu/powerforge/850w.png",
    "ssd_256": "storage/flashon/ssd_256.png",
    "ssd_512": "storage/flashon/ssd_512.png",
    "nvme_1tb": "storage/flashon/nvme_1tb.png",
    "nvme_2tb": "storage/flashon/nvme_2tb.png",
    "atx_24p": "cables/atx_24p.png",
    "cpu_8p": "cables/cpu_8p.png",
    "pcie_8p": "cables/pcie_8p.png",
    "sata": "cables/sata.png",
    "energia_ssd": "cables/energia_ssd.png",
    "fan_3p": "cables/fan_3p.png",
    "fan_4p": "cables/fan_4p.png",
    "parafuso_solto": "hardware/parafuso_solto.png",
    "parafuso_apertado": "hardware/parafuso_apertado.png",
    "presilha_aberta": "hardware/presilha_aberta.png",
    "presilha_fechada": "hardware/presilha_fechada.png",
    "trava_aberta": "hardware/trava_aberta.png",
    "trava_fechada": "hardware/trava_fechada.png",
    "chave_phillips": "tools/chave_phillips.png",
    "chave_fenda": "tools/chave_fenda.png",
    "pincel": "tools/pincel.png",
    "soprador": "tools/soprador.png",
    "pano": "tools/pano.png",
    "alcool": "tools/alcool.png",
    "multimetro": "tools/multimetro.png",
    "tp_00": "thermal_paste/tp_00.png",
    "tp_01": "thermal_paste/tp_01.png",
    "tp_02": "thermal_paste/tp_02.png",
    "tp_03": "thermal_paste/tp_03.png",
    "tp_04": "thermal_paste/tp_04.png",
    "tp_05": "thermal_paste/tp_05.png",
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
