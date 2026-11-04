extends RefCounted

const JOGOS := {
    "circuitos_aurora":{"nome":"Circuitos da Aurora","cpu":100,"gpu":100,"ram":8,"ssd":240,"orcamento":2450},
    "vale_bits":{"nome":"Vale dos Bits","cpu":100,"gpu":100,"ram":8,"ssd":240,"orcamento":2500},
    "ilha_vetorial":{"nome":"Ilha Vetorial","cpu":100,"gpu":100,"ram":8,"ssd":240,"orcamento":2600},
    "torre_logica":{"nome":"Torre Logica","cpu":100,"gpu":100,"ram":8,"ssd":240,"orcamento":2550},
    "jardim_pixels":{"nome":"Jardim de Pixels","cpu":100,"gpu":100,"ram":8,"ssd":240,"orcamento":2500},
    "corrida_neon":{"nome":"Corrida de Neon","cpu":120,"gpu":140,"ram":8,"ssd":240,"orcamento":3200},
    "ferrovias_nuvem":{"nome":"Ferrovias nas Nuvens","cpu":140,"gpu":100,"ram":16,"ssd":240,"orcamento":3300},
    "oceano_silicio":{"nome":"Oceano de Silicio","cpu":120,"gpu":140,"ram":16,"ssd":500,"orcamento":3600},
    "oficina_orbital":{"nome":"Oficina Orbital","cpu":140,"gpu":140,"ram":16,"ssd":500,"orcamento":3700},
    "arquipelago_digital":{"nome":"Arquipelago Digital","cpu":140,"gpu":140,"ram":16,"ssd":500,"orcamento":3600},
    "cavaleiros_cobre":{"nome":"Cavaleiros de Cobre","cpu":140,"gpu":170,"ram":16,"ssd":500,"orcamento":3800},
    "cidade_hexagonal":{"nome":"Cidade Hexagonal","cpu":150,"gpu":170,"ram":16,"ssd":500,"orcamento":3900},
    "horizonte_quantico":{"nome":"Horizonte Quantico","cpu":150,"gpu":170,"ram":16,"ssd":500,"orcamento":4000},
    "expedicao_lunar":{"nome":"Expedicao Lunar","cpu":150,"gpu":170,"ram":16,"ssd":500,"orcamento":4100},
    "guardioes_cache":{"nome":"Guardioes do Cache","cpu":150,"gpu":170,"ram":16,"ssd":500,"orcamento":4000},
    "tempestade_binaria":{"nome":"Tempestade Binaria","cpu":160,"gpu":220,"ram":16,"ssd":500,"orcamento":4800},
    "galaxia_poligonal":{"nome":"Galaxia Poligonal","cpu":160,"gpu":220,"ram":16,"ssd":500,"orcamento":5000},
    "fronteira_fotonica":{"nome":"Fronteira Fotonica","cpu":160,"gpu":220,"ram":16,"ssd":500,"orcamento":5100},
    "imperio_cristal":{"nome":"Imperio de Cristal","cpu":160,"gpu":220,"ram":16,"ssd":500,"orcamento":5200},
    "universo_malha":{"nome":"Universo em Malha","cpu":160,"gpu":220,"ram":16,"ssd":500,"orcamento":5300},
    "oficina_orbital_ii":{"nome":"Oficina Orbital II","cpu":180,"gpu":220,"ram":16,"ssd":500,"orcamento":5600,"lancamento":14},
    "universo_malha_ii":{"nome":"Universo em Malha II","cpu":180,"gpu":300,"ram":16,"ssd":1000,"orcamento":6500,"lancamento":28}
}

static func buscar(id: String) -> Dictionary:
    if id.is_empty():
        return {"nome":"PC de entrada","cpu":100,"gpu":100,"ram":8,"ssd":240,"orcamento":2450}
    return JOGOS[id]
