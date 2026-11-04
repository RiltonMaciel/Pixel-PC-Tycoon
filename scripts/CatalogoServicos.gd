extends RefCounted

const ITENS := {
    "upgrade":{"nome":"Upgrade de RAM para 16 GB","preco":520,"necessarios":{"ram_brisa16":1}},
    "diagnostico":{"nome":"Diagnostico completo","preco":120,"necessarios":{}},
    "reparo":{"nome":"Reparo: substituir fonte instavel","preco":460,"necessarios":{"fonte_clara":1}},
    "limpeza":{"nome":"Limpeza interna","preco":90,"necessarios":{"kit_limpeza":1}},
    "manutencao":{"nome":"Manutencao preventiva","preco":140,"necessarios":{"kit_limpeza":1,"pasta_termica":1}}
}
const CASOS := {
    "memoria":{"nome":"Erros intermitentes de memoria","ensaio":"memoria","necessarios":{"ram_brisa":1},"categoria":"ram","peca":"ram_brisa","preco":320},
    "termico":{"nome":"Superaquecimento por falha do cooler","ensaio":"carga","necessarios":{"cooler_neve_pro":1},"categoria":"cooler","peca":"cooler_neve_pro","preco":360},
    "armazenamento":{"nome":"SSD com saude degradada","ensaio":"disco","necessarios":{"ssd_trilha":1},"categoria":"ssd","peca":"ssd_trilha","preco":450}
}
const ENSAIOS := ["memoria","carga","disco"]

static func nome(ordem: Dictionary) -> String:
    return CASOS[ordem["caso"]]["nome"] if ordem.has("caso") else ITENS[ordem["tipo"]]["nome"]

static func necessarios(ordem: Dictionary) -> Dictionary:
    return CASOS[ordem["caso"]]["necessarios"] if ordem.has("caso") else ITENS[ordem["tipo"]]["necessarios"]

static func medir_caso(caso: String, corrigido: bool) -> Dictionary:
    return {"erros_memoria":24 if caso == "memoria" and not corrigido else 0,
        "cpu_c":98 if caso == "termico" and not corrigido else 58,
        "saude_ssd":12 if caso == "armazenamento" and not corrigido else 100}

static func pc_inicial(tipo: String) -> Dictionary:
    return {"gabinete":"caixa_ninho","placa":"placa_aurora","cpu":"cpu_aurora","ram":"ram_brisa",
        "fonte":"fonte_limite" if tipo in ["reparo","diagnostico"] else "fonte_clara",
        "ssd":"ssd_trilha","gpu":"gpu_pixel","cooler":"cooler_neve"}
