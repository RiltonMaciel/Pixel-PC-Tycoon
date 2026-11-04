extends RefCounted
# Mantem contexto de entrada/saida e estados independentes por imovel.
const Catalogo = preload("res://scripts/Imoveis/CatalogoImoveis.gd")
const Sprites = preload("res://scripts/Imoveis/CatalogoSprites.gd")
const Comercio = preload("res://scripts/Comercio.gd")
const Calendario = preload("res://scripts/CalendarioEconomia.gd")
const Clientes = preload("res://scripts/Clientes.gd")
const Equipe = preload("res://scripts/Equipe.gd")
const Evolucao = preload("res://scripts/Evolucao.gd")
const Reforma = preload("res://scripts/Reforma.gd")
const SAVE_PATH := "user://pixel_pc_tycoon_v1.json"
const LEGACY_PATH := "user://pixel_pc_tycoon_v042.save"
var ultimo_erro := ""
var aviso := ""
var imovel_atual: String = ""
var cena_exterior: String = "rua_comercial"
var estados: Dictionary = {}
var backup_migracao := ""
var comercio: Dictionary = {}
var calendario: Dictionary = {}
var clientes: Dictionary = {}
var equipe: Dictionary = {}
var unidade_id := "pc_store_001"
var evolucao: Dictionary = {}

func entrar(id: String) -> Dictionary:
    var dados := Catalogo.buscar(id,int(estados.get(id,{}).get("nivel",0)))
    if dados.is_empty():
        return {}
    imovel_atual = id
    cena_exterior = str(dados.get("exterior_id", "rua_comercial"))
    return dados

func sair() -> Dictionary:
    var dados := Catalogo.buscar(imovel_atual,int(estados.get(imovel_atual,{}).get("nivel",0)))
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
    if not evolucao.is_empty() and not Evolucao.validar(evolucao):
        _erro("Objetivos/tutorial/aparencia invalidos; save preservado.")
        return false
    for id in estados:
        if not Catalogo.IMOVEIS.has(id) or not estados[id] is Dictionary or not _numero(estados[id].get("nivel",0)) or not float(estados[id].get("nivel",0)) in [0.0,1.0,2.0]:
            _erro("Estado de imovel invalido; save preservado.")
            return false
        if not Reforma.validar(estados[id].get("acabamentos",{}),Catalogo.buscar(id,int(estados[id].get("nivel",0)))["modulos"]):
            _erro("Acabamentos invalidos; save preservado.")
            return false
    if not comercio.is_empty() and not Comercio.validar(comercio):
        _erro("Estado comercial invalido; gravacao cancelada e save preservado.")
        return false
    if not calendario.is_empty() and not Calendario.validar(calendario):
        _erro("Calendario/contas invalidos; gravacao cancelada e save preservado.")
        return false
    if not clientes.is_empty() and not Clientes.validar(clientes):
        _erro("Clientes invalidos; gravacao cancelada e save preservado.")
        return false
    if not equipe.is_empty() and not Equipe.validar(equipe):
        _erro("Equipe invalida; gravacao cancelada e save preservado.")
        return false
    if not _vinculos_oficina(comercio,clientes):
        _erro("Vinculos de clientes da oficina invalidos; save preservado.")
        return false
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
    var dados := {"versao":2,"dinheiro":dinheiro,"imoveis":estados}
    if unidade_id != "pc_store_001":
        dados["unidade"] = unidade_id
    if not comercio.is_empty():
        dados["comercio"] = comercio
    if not calendario.is_empty():
        dados["calendario"] = calendario
    if not clientes.is_empty():
        dados["clientes"] = clientes
    if not equipe.is_empty():
        dados["equipe"] = equipe
    if not evolucao.is_empty():
        dados["evolucao"] = evolucao
    arquivo.store_string(JSON.stringify(dados))
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
    comercio = {}
    calendario = {}
    clientes = {}
    equipe = {}
    evolucao = {}
    unidade_id = "pc_store_001"
    var principal_existe := FileAccess.file_exists(caminho) or DirAccess.dir_exists_absolute(caminho)
    var backup_existe := FileAccess.file_exists(caminho + ".bak") or DirAccess.dir_exists_absolute(caminho + ".bak")
    var origem := caminho
    var dados: Dictionary = {}
    if principal_existe:
        dados = _ler_arquivo(caminho)
    if dados.is_empty() and backup_existe:
        var motivo := ultimo_erro if principal_existe else "Save principal ausente."
        dados = _ler_arquivo(caminho + ".bak")
        if dados.is_empty():
            _erro(motivo + " Backup invalido: " + ultimo_erro + " Arquivos preservados.")
            return {}
        dados = _restaurar_backup(caminho)
        if dados.is_empty():
            _erro(ultimo_erro)
            return {}
        ultimo_erro = ""
        push_warning(aviso + " Motivo: " + motivo)
    elif dados.is_empty() and principal_existe:
        _erro(ultimo_erro)
        return {}
    elif dados.is_empty() and FileAccess.file_exists(legado):
        origem = legado
        dados = _ler_arquivo(legado,true)
        if dados.is_empty():
            _erro(ultimo_erro)
            return {}
    elif dados.is_empty():
        estados = {"pc_store_001":Catalogo.estado_inicial("pc_store_001")}
        return {"versao":2,"dinheiro":6500,"imoveis":estados.duplicate(true)}
    if dados["versao"] == 1:
        backup_migracao = origem
        for id in dados["imoveis"]:
            var estado: Dictionary = dados["imoveis"][id]
            estado["guardados"] = estado["moveis"].duplicate(true)
            estado["moveis"] = []
        dados["versao"] = 2
        aviso += (" " if not aviso.is_empty() else "") + "Sala nova: moveis antigos guardados. Use Loja > Recuperar, sem custo."
    estados = (dados["imoveis"] as Dictionary).duplicate(true)
    comercio = (dados.get("comercio",{}) as Dictionary).duplicate(true)
    calendario = (dados.get("calendario",{}) as Dictionary).duplicate(true)
    clientes = (dados.get("clientes",{}) as Dictionary).duplicate(true)
    equipe = (dados.get("equipe",{}) as Dictionary).duplicate(true)
    evolucao = (dados.get("evolucao",{}) as Dictionary).duplicate(true)
    unidade_id = str(dados.get("unidade","pc_store_001"))
    return dados

func _ler_arquivo(origem: String, migrar: bool = false) -> Dictionary:
    var arquivo := FileAccess.open(origem,FileAccess.READ)
    if arquivo == null:
        ultimo_erro = "Nao foi possivel ler " + origem + ": " + error_string(FileAccess.get_open_error())
        return {}
    var texto := arquivo.get_as_text()
    var erro := arquivo.get_error()
    arquivo.close()
    if erro != OK and erro != ERR_FILE_EOF:
        ultimo_erro = "Falha ao ler " + origem + ": " + error_string(erro)
        return {}
    var json := JSON.new()
    var resultado := json.parse(texto)
    if resultado != OK or not json.data is Dictionary:
        ultimo_erro = "Save invalido. Arquivo preservado: " + origem
        return {}
    var dados: Dictionary = json.data
    if migrar:
        if not _numero(dados.get("cash")) or not dados.get("owns_counter") is bool:
            ultimo_erro = "Save legado invalido; migracao cancelada: " + origem
            return {}
        var moveis: Array = []
        if dados["owns_counter"]:
            # O piso e as coordenadas mudaram. Mantem a compra em um ponto seguro.
            moveis.append({"id":"balcao_pc_store","posicao":[700,400],"angulo":0})
        dados = {"versao":1,"dinheiro":dados["cash"],"imoveis":{"pc_store_001":{"moveis":moveis}}}
    if not _validar(dados):
        ultimo_erro = "Estrutura de save invalida. Arquivo preservado: " + origem
        return {}
    return dados

func _restaurar_backup(caminho: String) -> Dictionary:
    var temporario := caminho + ".recuperacao.tmp"
    if DirAccess.dir_exists_absolute(caminho) or DirAccess.dir_exists_absolute(temporario):
        ultimo_erro = "Nao foi possivel recuperar o save: o destino e uma pasta. Backup preservado."
        return {}
    var erro := DirAccess.copy_absolute(caminho + ".bak",temporario)
    if erro != OK:
        ultimo_erro = "Nao foi possivel preparar a recuperacao: " + error_string(erro) + ". Backup preservado."
        return {}
    var dados := _ler_arquivo(temporario)
    if dados.is_empty():
        return {}
    var preservado := ""
    if FileAccess.file_exists(caminho):
        preservado = caminho + ".corrompido"
        var indice := 1
        while FileAccess.file_exists(preservado) or DirAccess.dir_exists_absolute(preservado):
            preservado = caminho + ".corrompido." + str(indice)
            indice += 1
        erro = DirAccess.rename_absolute(caminho,preservado)
        if erro != OK:
            ultimo_erro = "Nao foi possivel preservar o save corrompido: " + error_string(erro)
            return {}
    erro = DirAccess.rename_absolute(temporario,caminho)
    if erro != OK:
        ultimo_erro = "Nao foi possivel concluir a recuperacao: " + error_string(erro) + ". Backup preservado."
        if not preservado.is_empty():
            var restauracao := DirAccess.rename_absolute(preservado,caminho)
            if restauracao != OK:
                ultimo_erro += " Falha ao restaurar original: " + error_string(restauracao) + ". Arquivo preservado em " + preservado
        return {}
    aviso = "Save recuperado do backup."
    if not preservado.is_empty():
        aviso += " Original preservado em " + preservado
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
    if dados.has("unidade") and (not dados["unidade"] in Catalogo.IMOVEIS or not dados["imoveis"].has(dados["unidade"])):
        return false
    if dados.has("comercio") and (not dados["comercio"] is Dictionary or not Comercio.validar(dados["comercio"])):
        return false
    if dados.has("calendario") and (not dados["calendario"] is Dictionary or not Calendario.validar(dados["calendario"])):
        return false
    if dados.has("clientes") and (not dados["clientes"] is Dictionary or not Clientes.validar(dados["clientes"])):
        return false
    if dados.has("equipe") and (not dados["equipe"] is Dictionary or not Equipe.validar(dados["equipe"])):
        return false
    if dados.has("evolucao") and (not dados["evolucao"] is Dictionary or not Evolucao.validar(dados["evolucao"])):
        return false
    if not _vinculos_oficina(dados.get("comercio",{}),dados.get("clientes",{})):
        return false
    for id in dados["imoveis"]:
        if not Catalogo.IMOVEIS.has(id):
            return false
        var estado: Variant = dados["imoveis"][id]
        if not estado is Dictionary or not estado.get("moveis") is Array:
            return false
        if not _numero(estado.get("nivel",0)) or not float(estado.get("nivel",0)) in [0.0,1.0,2.0]:
            return false
        if not estado.get("acabamentos",{}) is Dictionary or not Reforma.validar(estado.get("acabamentos",{}),Catalogo.buscar(id,int(estado.get("nivel",0)))["modulos"]):
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
            if movel.has("aberta") and (movel["id"] != "porta_interna" or not movel["aberta"] is bool):
                return false
            var ponto: Variant = movel.get("posicao")
            if not ponto is Array or ponto.size() != 2 or not _numero(ponto[0]) or not _numero(ponto[1]):
                return false
            var angulo: Variant = movel.get("angulo")
            # JSON.parse devolve numeros float; Array.has distingue float de int.
            if not _numero(angulo) or not float(angulo) in [0.0,90.0,180.0,270.0]:
                return false
            if indice < colocados:
                var cadastro := Catalogo.buscar(id,int(estado.get("nivel",0)))
                var piso: PackedVector2Array = cadastro["piso_legado"] if dados["versao"] == 1 else cadastro["piso_interno"]
                if not Geometry2D.is_point_in_polygon(Vector2(ponto[0],ponto[1]),piso):
                    return false
            indice += 1
    return true

static func _vinculos_oficina(dados: Dictionary, pessoas: Dictionary) -> bool:
    var perfis: Dictionary = pessoas.get("perfis",{})
    var vistos: Array = []
    for pacote: Dictionary in dados.get("fila_os",[]):
        var perfil: String = pacote["os"].get("perfil","")
        if not perfis.has(perfil) or perfil in vistos or perfil == pessoas.get("atual","") or perfil in pessoas.get("fila",[]) or int(perfis[perfil].get("retorno",0)) != 0:
            return false
        vistos.append(perfil)
    return true
