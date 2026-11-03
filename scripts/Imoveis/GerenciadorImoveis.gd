extends RefCounted
# Mantem contexto de entrada/saida e estados independentes por imovel.
const Catalogo = preload("res://scripts/Imoveis/CatalogoImoveis.gd")
const Sprites = preload("res://scripts/Imoveis/CatalogoSprites.gd")
const SAVE_PATH := "user://pixel_pc_tycoon_v1.json"
const LEGACY_PATH := "user://pixel_pc_tycoon_v042.save"
var ultimo_erro := ""
var aviso := ""
var imovel_atual: String = ""
var cena_exterior: String = "rua_comercial"
var estados: Dictionary = {}
var backup_migracao := ""

func entrar(id: String) -> Dictionary:
    var dados := Catalogo.buscar(id)
    if dados.is_empty():
        return {}
    imovel_atual = id
    cena_exterior = str(dados.get("exterior_id", "rua_comercial"))
    return dados

func sair() -> Dictionary:
    var dados := Catalogo.buscar(imovel_atual)
    imovel_atual = ""
    return dados

func salvar_estado(id: String, estado: Dictionary) -> void:
    estados[id] = estado.duplicate(true)

func carregar_estado(id: String) -> Dictionary:
    return (estados.get(id, {}) as Dictionary).duplicate(true)

func _erro(mensagem: String) -> void:
    ultimo_erro = mensagem
    push_error(mensagem)

func gravar(dinheiro: int, caminho: String = SAVE_PATH) -> bool:
    ultimo_erro = ""
    if not backup_migracao.is_empty() and not FileAccess.file_exists(backup_migracao + ".pre_modular"):
        var copia := DirAccess.copy_absolute(backup_migracao,backup_migracao + ".pre_modular")
        if copia != OK:
            _erro("Nao foi possivel preservar o save antes da migracao: " + error_string(copia))
            return false
    var temporario := caminho + ".tmp"
    var arquivo := FileAccess.open(temporario, FileAccess.WRITE)
    if arquivo == null:
        _erro("Nao foi possivel abrir o save: " + error_string(FileAccess.get_open_error()))
        return false
    arquivo.store_string(JSON.stringify({"versao":2,"dinheiro":dinheiro,"imoveis":estados}))
    arquivo.flush()
    var erro := arquivo.get_error()
    arquivo.close()
    if erro != OK:
        _erro("Falha ao escrever o save: " + error_string(erro))
        return false
    if FileAccess.file_exists(caminho):
        erro = DirAccess.rename_absolute(caminho, caminho + ".bak")
        if erro != OK:
            _erro("Falha ao preservar save anterior: " + error_string(erro))
            return false
    erro = DirAccess.rename_absolute(temporario, caminho)
    if erro != OK:
        _erro("Falha ao concluir save: " + error_string(erro))
        if FileAccess.file_exists(caminho + ".bak"):
            var restauracao := DirAccess.rename_absolute(caminho + ".bak", caminho)
            if restauracao != OK:
                _erro("Falha ao restaurar backup: " + error_string(restauracao))
        return false
    return true

func ler(caminho: String = SAVE_PATH, legado: String = LEGACY_PATH) -> Dictionary:
    ultimo_erro = ""
    aviso = ""
    backup_migracao = ""
    var migrar := not FileAccess.file_exists(caminho) and FileAccess.file_exists(legado)
    var origem := legado if migrar else caminho
    if not FileAccess.file_exists(origem):
        if FileAccess.file_exists(caminho + ".bak"):
            _erro("Save principal ausente. Backup preservado; recupere-o antes de continuar.")
            return {}
        estados = {"pc_store_001":Catalogo.estado_inicial("pc_store_001")}
        return {"versao":2,"dinheiro":6500,"imoveis":estados.duplicate(true)}
    var arquivo := FileAccess.open(origem,FileAccess.READ)
    if arquivo == null:
        _erro("Nao foi possivel ler o save: " + error_string(FileAccess.get_open_error()))
        return {}
    var json := JSON.new()
    var resultado := json.parse(arquivo.get_as_text())
    arquivo.close()
    if resultado != OK or not json.data is Dictionary:
        _erro("Save invalido. Arquivo preservado: " + origem)
        return {}
    var dados: Dictionary = json.data
    if migrar:
        if not _numero(dados.get("cash")) or not dados.get("owns_counter") is bool:
            _erro("Save legado invalido; migracao cancelada.")
            return {}
        var moveis: Array = []
        if dados["owns_counter"]:
            # O piso e as coordenadas mudaram. Mantem a compra em um ponto seguro.
            moveis.append({"id":"balcao_pc_store","posicao":[700,400],"angulo":0})
        dados = {"versao":1,"dinheiro":dados["cash"],"imoveis":{"pc_store_001":{"moveis":moveis}}}
        aviso = "Save antigo importado; balcao realocado no novo piso."
    if not _validar(dados):
        _erro("Estrutura de save invalida. O arquivo original nao foi alterado.")
        return {}
    if dados["versao"] == 1:
        backup_migracao = origem
        for id in dados["imoveis"]:
            var estado: Dictionary = dados["imoveis"][id]
            estado["guardados"] = estado["moveis"].duplicate(true)
            estado["moveis"] = []
        dados["versao"] = 2
        aviso = "Sala nova: moveis antigos guardados. Use Loja > Recuperar, sem custo."
    estados = (dados["imoveis"] as Dictionary).duplicate(true)
    return dados

func _numero(valor: Variant) -> bool:
    return (valor is int or valor is float) and is_finite(float(valor))

func _validar(dados: Dictionary) -> bool:
    if (dados.get("versao") != 1 and dados.get("versao") != 2) or not _numero(dados.get("dinheiro")):
        return false
    if float(dados["dinheiro"]) < 0 or float(dados["dinheiro"]) > 2147483647 or float(dados["dinheiro"]) != floorf(float(dados["dinheiro"])):
        return false
    if not dados.get("imoveis") is Dictionary:
        return false
    for id in dados["imoveis"]:
        if not Catalogo.IMOVEIS.has(id):
            return false
        var estado: Variant = dados["imoveis"][id]
        if not estado is Dictionary or not estado.get("moveis") is Array:
            return false
        if dados["versao"] == 2 and not estado.get("guardados",[]) is Array:
            return false
        var itens: Array = estado["moveis"].duplicate()
        var colocados: int = itens.size()
        if dados["versao"] == 2:
            itens.append_array(estado.get("guardados",[]))
        var indice := 0
        for movel in itens:
            if not movel is Dictionary or not Sprites.ITENS.has(movel.get("id","")):
                return false
            var ponto: Variant = movel.get("posicao")
            if not ponto is Array or ponto.size() != 2 or not _numero(ponto[0]) or not _numero(ponto[1]):
                return false
            var angulo: Variant = movel.get("angulo")
            # JSON.parse devolve numeros float; Array.has distingue float de int.
            if not _numero(angulo) or not float(angulo) in [0.0,90.0,180.0,270.0]:
                return false
            if indice < colocados:
                var cadastro := Catalogo.buscar(id)
                var piso: PackedVector2Array = cadastro["piso_legado"] if dados["versao"] == 1 else cadastro["piso_interno"]
                if not Geometry2D.is_point_in_polygon(Vector2(ponto[0],ponto[1]),piso):
                    return false
            indice += 1
    return true
