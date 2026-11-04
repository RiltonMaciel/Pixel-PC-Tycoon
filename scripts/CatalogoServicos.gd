extends RefCounted

const ITENS := {
    "upgrade":{"nome":"Upgrade de RAM para 16 GB","preco":520,"necessarios":{"ram_brisa16":1}},
    "diagnostico":{"nome":"Diagnostico completo","preco":120,"necessarios":{}},
    "reparo":{"nome":"Reparo: substituir fonte instavel","preco":460,"necessarios":{"fonte_clara":1}},
    "limpeza":{"nome":"Limpeza interna","preco":90,"necessarios":{"kit_limpeza":1}},
    "manutencao":{"nome":"Manutencao preventiva","preco":140,"necessarios":{"kit_limpeza":1,"pasta_termica":1}}
}

static func pc_inicial(tipo: String) -> Dictionary:
    return {"gabinete":"caixa_ninho","placa":"placa_aurora","cpu":"cpu_aurora","ram":"ram_brisa",
        "fonte":"fonte_limite" if tipo in ["reparo","diagnostico"] else "fonte_clara",
        "ssd":"ssd_trilha","gpu":"gpu_pixel","cooler":"cooler_neve"}
