extends RefCounted

const CATEGORIAS := ["gabinete","placa","cpu","ram","fonte","ssd","gpu","cooler"]
const PRECO_PC := 2450
const PECAS := {
    "caixa_ninho": {"nome":"Ninho Mini","categoria":"gabinete","custo":180,"venda":230,"formatos":["mATX"],"gpu_max":280},
    "caixa_torre": {"nome":"Torre Horizonte","categoria":"gabinete","custo":300,"venda":390,"formatos":["mATX","ATX"],"gpu_max":360},
    "placa_aurora": {"nome":"Aurora M1","categoria":"placa","custo":260,"venda":340,"socket":"A1","ram":"DDR4","formato":"mATX","ssd":"SATA","pcie":1},
    "placa_nova": {"nome":"Nova M2","categoria":"placa","custo":400,"venda":520,"socket":"N2","ram":"DDR5","formato":"ATX","ssd":"NVMe","pcie":1},
    "cpu_aurora": {"nome":"Aurora Quad","categoria":"cpu","custo":340,"venda":440,"socket":"A1","watts":65,"pontos":100},
    "cpu_nova": {"nome":"Nova Hexa","categoria":"cpu","custo":540,"venda":700,"socket":"N2","watts":95,"pontos":160},
    "ram_brisa": {"nome":"Brisa 8 GB","categoria":"ram","custo":140,"venda":180,"tipo":"DDR4","gb":8},
    "ram_vento": {"nome":"Vento 16 GB","categoria":"ram","custo":240,"venda":310,"tipo":"DDR5","gb":16},
    "fonte_clara": {"nome":"Clara 450 W","categoria":"fonte","custo":200,"venda":260,"watts":450,"pcie":1},
    "fonte_fraca": {"nome":"Centelha 180 W","categoria":"fonte","custo":100,"venda":130,"watts":180,"pcie":0},
    "ssd_trilha": {"nome":"Trilha SATA 240","categoria":"ssd","custo":160,"venda":210,"conector":"SATA","gb":240},
    "ssd_veloz": {"nome":"Veloz NVMe 500","categoria":"ssd","custo":280,"venda":360,"conector":"NVMe","gb":500},
    "gpu_pixel": {"nome":"Pixel 100","categoria":"gpu","custo":420,"venda":550,"watts":100,"comprimento":220,"pcie":1,"pontos":100},
    "gpu_trovao": {"nome":"Trovao 300","categoria":"gpu","custo":950,"venda":1230,"watts":300,"comprimento":330,"pcie":2,"pontos":240},
    "cooler_neve": {"nome":"Neve 100","categoria":"cooler","custo":80,"venda":110,"socket":"A1","tdp":100},
    "cpu_aurora_pro": {"nome":"Aurora Pro","categoria":"cpu","custo":600,"venda":780,"socket":"A1","watts":95,"pontos":150},
    "ram_brisa16": {"nome":"Brisa 16 GB","categoria":"ram","custo":260,"venda":340,"tipo":"DDR4","gb":16},
    "ssd_trilha500": {"nome":"Trilha SATA 500","categoria":"ssd","custo":280,"venda":360,"conector":"SATA","gb":500},
    "gpu_pixel200": {"nome":"Pixel 200","categoria":"gpu","custo":650,"venda":850,"watts":170,"comprimento":260,"pcie":1,"pontos":170},
    "fonte_firme": {"nome":"Firme 700 W","categoria":"fonte","custo":350,"venda":460,"watts":700,"pcie":2},
    "cooler_nova": {"nome":"Polar N2","categoria":"cooler","custo":120,"venda":160,"socket":"N2","tdp":120},
    "cooler_neve_pro": {"nome":"Neve Pro 160","categoria":"cooler","custo":140,"venda":180,"socket":"A1","tdp":160},
    "fonte_limite": {"nome":"Margem 280 W","categoria":"fonte","custo":140,"venda":180,"watts":280,"pcie":1},
    "caixa_fechada": {"nome":"Compacto sem exaustao","categoria":"gabinete","custo":140,"venda":180,"formatos":["mATX"],"gpu_max":280,"calor":30},
    "kit_limpeza": {"nome":"Kit de limpeza","categoria":"insumo","custo":20,"venda":30},
    "pasta_termica": {"nome":"Pasta termica","categoria":"insumo","custo":30,"venda":45},
    "cpu_aurora_plus": {"nome":"Aurora Plus","categoria":"cpu","custo":680,"venda":890,"socket":"A1","watts":90,"pontos":180},
    "ssd_trilha1000": {"nome":"Trilha SATA 1000","categoria":"ssd","custo":460,"venda":600,"conector":"SATA","gb":1000},
    "ram_vento32": {"nome":"Vento 32 GB","categoria":"ram","custo":420,"venda":550,"tipo":"DDR5","gb":32},
    "gpu_trovao400": {"nome":"Trovao 400","categoria":"gpu","custo":1200,"venda":1560,"watts":260,"comprimento":330,"pcie":2,"pontos":300}
}

static func incompatibilidade(instaladas: Dictionary) -> String:
    for categoria in instaladas:
        if not PECAS.has(instaladas[categoria]) or PECAS[instaladas[categoria]]["categoria"] != categoria:
            return "Peca nao corresponde ao encaixe."
    var placa: Dictionary = PECAS.get(instaladas.get("placa",""),{})
    var cpu: Dictionary = PECAS.get(instaladas.get("cpu",""),{})
    var ram: Dictionary = PECAS.get(instaladas.get("ram",""),{})
    var gabinete: Dictionary = PECAS.get(instaladas.get("gabinete",""),{})
    var gpu: Dictionary = PECAS.get(instaladas.get("gpu",""),{})
    var fonte: Dictionary = PECAS.get(instaladas.get("fonte",""),{})
    var cooler: Dictionary = PECAS.get(instaladas.get("cooler",""),{})
    var ssd: Dictionary = PECAS.get(instaladas.get("ssd",""),{})
    if not placa.is_empty():
        if not cpu.is_empty() and cpu["socket"] != placa["socket"]:
            return "Socket da CPU incompativel com a placa."
        if not ram.is_empty() and ram["tipo"] != placa["ram"]:
            return "Tipo de RAM incompativel com a placa."
        if not gabinete.is_empty() and not placa["formato"] in gabinete["formatos"]:
            return "Formato da placa nao cabe no gabinete."
        if not ssd.is_empty() and ssd["conector"] != placa["ssd"]:
            return "Conector do SSD incompativel com a placa."
        if not gpu.is_empty() and int(placa["pcie"]) < 1:
            return "Placa sem slot para GPU."
    if not cpu.is_empty() and not cooler.is_empty():
        if cooler["socket"] != cpu["socket"] or int(cooler["tdp"]) < int(cpu["watts"]):
            return "Cooler incompativel com socket ou potencia da CPU."
    if not gabinete.is_empty() and not gpu.is_empty() and int(gpu["comprimento"]) > int(gabinete["gpu_max"]):
        return "GPU comprida demais para o gabinete."
    if not fonte.is_empty():
        var consumo := 100 + int(cpu.get("watts",0)) + int(gpu.get("watts",0))
        if consumo > int(fonte["watts"]):
            return "Fonte insuficiente: precisa de %d W." % consumo
        if int(gpu.get("pcie",0)) > int(fonte["pcie"]):
            return "Fonte sem os conectores PCIe necessarios."
    return ""
