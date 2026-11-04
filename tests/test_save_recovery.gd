extends SceneTree

const MANAGER = preload("res://scripts/Imoveis/GerenciadorImoveis.gd")
const GAME = preload("res://scripts/RuaComercial.gd")
var passed := 0
var failed := 0
var temp_dir := "user://test_recuperacao_" + str(Time.get_ticks_usec())

func _initialize() -> void:
    root.size = Vector2i(432,768)
    root.content_scale_size = Vector2i(432,768)
    root.gui_embed_subwindows = true
    call_deferred("_run")

func check(condicao: bool, mensagem: String) -> bool:
    if condicao:
        passed += 1
        print("PASS: ",mensagem)
    else:
        failed += 1
        printerr("FAIL: ",mensagem)
    return condicao

func _save(saldo: int = 4321) -> Dictionary:
    return {"versao":2,"dinheiro":saldo,"imoveis":{"pc_store_001":{
        "moveis":[{"id":"balcao_pc_store","posicao":[700,400],"angulo":90}],
        "guardados":[{"id":"balcao_atendimento","posicao":[700,400],"angulo":180}]
    }}}

func _escrever(caminho: String, texto: String) -> void:
    var arquivo := FileAccess.open(caminho,FileAccess.WRITE)
    if not check(arquivo != null,"Abrir fixture " + caminho.get_file()):
        return
    arquivo.store_string(texto)
    arquivo.close()

func _ler_erro_esperado(gestor: MANAGER, caminho: String, legado: String) -> Dictionary:
    var imprimir := Engine.print_error_messages
    Engine.print_error_messages = false
    var dados := gestor.ler(caminho,legado)
    Engine.print_error_messages = imprimir
    return dados

func _run() -> void:
    create_timer(45).timeout.connect(func() -> void:
        printerr("FAIL: Testes de recuperacao excederam 45 segundos.")
        quit(1))
    if not check(DirAccess.make_dir_absolute(temp_dir) == OK,"Pasta isolada de recuperacao"):
        quit(1)
        return
    _test_principal_valido()
    _test_corrupcao()
    _test_ausente_e_legado()
    _test_backup_v1()
    _test_bloqueios()
    _test_falha_restauracao()
    _test_preservacao_unica()
    await _test_interface()
    for nome in DirAccess.get_files_at(temp_dir):
        check(DirAccess.remove_absolute(temp_dir.path_join(nome)) == OK,"Limpeza de " + nome)
    check(DirAccess.remove_absolute(temp_dir) == OK,"Limpeza da pasta isolada")
    print("RESULT: %d passed, %d failed" % [passed,failed])
    quit(1 if failed else 0)

func _test_principal_valido() -> void:
    var path := temp_dir.path_join("valido.json")
    var original := JSON.stringify(_save(6000), "  ")
    _escrever(path,original)
    _escrever(path + ".bak","backup invalido")
    var gestor := MANAGER.new()
    var dados := gestor.ler(path,temp_dir.path_join("sem_legado"))
    check(dados.get("dinheiro") == 6000,"Principal valido tem prioridade sobre backup invalido")
    check(FileAccess.get_file_as_string(path) == original,"Leitura valida nao regrava principal")
    check(FileAccess.get_file_as_string(path + ".bak") == "backup invalido","Leitura valida nao modifica backup")
    check(gestor.aviso.is_empty() and gestor.ultimo_erro.is_empty(),"Leitura valida nao informa recuperacao")

func _test_corrupcao() -> void:
    var corrupcoes := [
        "{invalido",
        "",
        "[]",
        JSON.stringify({"versao":2,"dinheiro":-1,"imoveis":{}}),
        JSON.stringify({"versao":2,"dinheiro":1,"imoveis":{"desconhecido":{"moveis":[]}}})
    ]
    for indice in range(corrupcoes.size()):
        var path := temp_dir.path_join("corrompido_%d.json" % indice)
        var backup := JSON.stringify(_save(),"  ")
        _escrever(path,corrupcoes[indice])
        _escrever(path + ".bak",backup)
        var gestor := MANAGER.new()
        var dados := gestor.ler(path,temp_dir.path_join("sem_legado"))
        var esperado: Dictionary = JSON.parse_string(backup)
        check(dados.get("dinheiro") == 4321,"Backup recupera saldo %d" % indice)
        check(gestor.carregar_estado("pc_store_001") == esperado["imoveis"]["pc_store_001"],
            "Backup preserva moveis, guardados, posicoes e angulos %d" % indice)
        check(FileAccess.get_file_as_string(path) == backup,"Principal restaurado e identico ao backup %d" % indice)
        check(FileAccess.get_file_as_string(path + ".corrompido") == corrupcoes[indice],
            "Original corrompido preservado byte a byte %d" % indice)
        check(FileAccess.get_file_as_string(path + ".bak") == backup,"Backup nao e substituido pela corrupcao %d" % indice)
        check(gestor.aviso.contains("recuperado do backup") and gestor.ultimo_erro.is_empty(),
            "Recuperacao informa origem e limpa erro terminal %d" % indice)
        if indice == 0:
            check(gestor.gravar(5000,path),"Autosave funciona apos recuperar")
            check(FileAccess.get_file_as_string(path + ".bak") == backup,"Autosave mantem copia valida anterior")
            var leitor := MANAGER.new()
            check(leitor.ler(path,temp_dir.path_join("sem_legado")).get("dinheiro") == 5000,
                "Reinicio apos recuperar restaura progresso novo")
            check(leitor.aviso.is_empty(),"Reinicio nao repete aviso de recuperacao ja concluida")
            check(FileAccess.get_file_as_string(path + ".corrompido") == corrupcoes[indice],
                "Autosave nao altera original preservado")

func _test_ausente_e_legado() -> void:
    var path := temp_dir.path_join("ausente.json")
    var legado := temp_dir.path_join("antigo.save")
    var backup := JSON.stringify(_save())
    _escrever(path + ".bak",backup)
    _escrever(legado,JSON.stringify({"cash":999,"owns_counter":true}))
    var gestor := MANAGER.new()
    var dados := gestor.ler(path,legado)
    check(dados.get("dinheiro") == 4321,"Backup tem prioridade sobre legado quando principal esta ausente")
    check(FileAccess.get_file_as_string(path) == backup,"Principal ausente e restaurado")
    check(not FileAccess.file_exists(path + ".corrompido"),"Ausencia nao cria falso arquivo corrompido")
    check(FileAccess.file_exists(legado),"Recuperacao nao modifica arquivo legado")
    check(gestor.aviso.contains("recuperado do backup"),"Principal ausente informa recuperacao")
    var novo := MANAGER.new()
    check(novo.ler(temp_dir.path_join("novo.json"),temp_dir.path_join("sem_legado")).get("dinheiro") == 6500,
        "Sem principal, backup ou legado inicia partida nova")
    var migrado := MANAGER.new()
    check(migrado.ler(temp_dir.path_join("legado.json"),legado).get("dinheiro") == 999,
        "Sem backup mantem migracao do legado")

func _test_backup_v1() -> void:
    var path := temp_dir.path_join("versao1.json")
    var antigo := _save(3000)
    antigo["versao"] = 1
    antigo["imoveis"]["pc_store_001"].erase("guardados")
    var backup := JSON.stringify(antigo,"  ")
    _escrever(path,"original danificado")
    _escrever(path + ".bak",backup)
    var gestor := MANAGER.new()
    var dados := gestor.ler(path,temp_dir.path_join("sem_legado"))
    check(dados.get("versao") == 2 and dados.get("dinheiro") == 3000,"Backup v1 recupera e migra saldo")
    var estado := gestor.carregar_estado("pc_store_001")
    check(estado.get("moveis",[]).is_empty() and estado.get("guardados",[]).size() == 1,
        "Backup v1 preserva patrimonio em guardados")
    check(gestor.aviso.contains("recuperado do backup") and gestor.aviso.contains("moveis antigos guardados"),
        "Aviso combina recuperacao e migracao")
    check(gestor.gravar(3000,path),"Primeira gravacao apos recuperar v1")
    check(FileAccess.get_file_as_string(path + ".pre_modular") == backup,"Pre-modular preserva backup v1 original")
    check(FileAccess.get_file_as_string(path + ".corrompido") == "original danificado",
        "Migracao nao altera arquivo corrompido preservado")

func _test_bloqueios() -> void:
    for indice in range(3):
        var path := temp_dir.path_join("bloqueado_%d.json" % indice)
        var legado := temp_dir.path_join("legado_bloqueado_%d.save" % indice)
        if indice != 1:
            _escrever(path,"principal invalido")
        if indice != 2:
            _escrever(path + ".bak","backup invalido")
        _escrever(legado,JSON.stringify({"cash":999,"owns_counter":true}))
        var gestor := MANAGER.new()
        check(_ler_erro_esperado(gestor,path,legado).is_empty(),"Sem copia valida bloqueia partida %d" % indice)
        check(not gestor.ultimo_erro.is_empty(),"Bloqueio informa erro explicito %d" % indice)
        check(gestor.aviso.is_empty(),"Bloqueio nao informa recuperacao bem-sucedida %d" % indice)
        if indice != 1:
            check(FileAccess.get_file_as_string(path) == "principal invalido","Bloqueio preserva principal %d" % indice)
        if indice != 2:
            check(FileAccess.get_file_as_string(path + ".bak") == "backup invalido","Bloqueio preserva backup %d" % indice)
        check(not FileAccess.file_exists(path + ".corrompido"),"Bloqueio nao move original sem backup valido %d" % indice)

func _test_falha_restauracao() -> void:
    var path := temp_dir.path_join("falha.json")
    var backup := JSON.stringify(_save())
    _escrever(path,"original protegido")
    _escrever(path + ".bak",backup)
    check(DirAccess.make_dir_absolute(path + ".recuperacao.tmp") == OK,"Simular destino temporario indisponivel")
    var gestor := MANAGER.new()
    check(_ler_erro_esperado(gestor,path,temp_dir.path_join("sem_legado")).is_empty(),
        "Falha de restauracao bloqueia carregamento")
    check(not gestor.ultimo_erro.is_empty() and gestor.aviso.is_empty(),"Falha de restauracao nao retorna sucesso")
    check(FileAccess.get_file_as_string(path) == "original protegido","Falha de restauracao preserva principal")
    check(FileAccess.get_file_as_string(path + ".bak") == backup,"Falha de restauracao preserva backup")
    check(DirAccess.remove_absolute(path + ".recuperacao.tmp") == OK,"Limpeza do destino bloqueado")

func _test_preservacao_unica() -> void:
    var path := temp_dir.path_join("repetido.json")
    _escrever(path,"corrupcao nova")
    _escrever(path + ".bak",JSON.stringify(_save()))
    _escrever(path + ".corrompido","corrupcao anterior")
    check(DirAccess.make_dir_absolute(path + ".corrompido.1") == OK,"Nome de preservacao ja ocupado por pasta")
    var gestor := MANAGER.new()
    check(not gestor.ler(path,temp_dir.path_join("sem_legado")).is_empty(),"Recuperacao usa nome de preservacao livre")
    check(FileAccess.get_file_as_string(path + ".corrompido") == "corrupcao anterior","Preservacao anterior nao e sobrescrita")
    check(FileAccess.get_file_as_string(path + ".corrompido.2") == "corrupcao nova","Nova corrupcao recebe nome unico")
    check(DirAccess.remove_absolute(path + ".corrompido.1") == OK,"Limpeza da pasta de nome ocupado")

func _test_interface() -> void:
    var path := temp_dir.path_join("interface.json")
    _escrever(path,"save da interface invalido")
    _escrever(path + ".bak",JSON.stringify(_save()))
    var jogo := GAME.new()
    jogo.save_path = path
    jogo.legacy_path = temp_dir.path_join("sem_legado")
    root.add_child(jogo)
    jogo.set_physics_process(false)
    check(not jogo.save_bloqueado and jogo.money == 4321,"Cena principal usa saldo recuperado")
    check(jogo.info.text.contains("recuperado do backup"),"HUD informa recuperacao ao jogador")
    await jogo._change_area(true)
    check(jogo.moveis.size() == 1 and jogo.moveis[0].orientacao == 1 and jogo.guardados.size() == 1,
        "Interior carrega patrimonio e angulo recuperados")
    check(jogo._save(),"Cena salva normalmente apos recuperacao")
    jogo.queue_free()
    await process_frame
    path = temp_dir.path_join("interface_bloqueada.json")
    _escrever(path,"principal invalido")
    _escrever(path + ".bak","backup invalido")
    jogo = GAME.new()
    jogo.save_path = path
    jogo.legacy_path = temp_dir.path_join("sem_legado")
    var imprimir := Engine.print_error_messages
    Engine.print_error_messages = false
    root.add_child(jogo)
    Engine.print_error_messages = imprimir
    jogo.set_physics_process(false)
    check(jogo.save_bloqueado and jogo.info.text.contains("ERRO NO SAVE"),"HUD bloqueia e informa ausencia de copia valida")
    check(not jogo._save(),"Cena bloqueada nao grava partida nova")
    check(FileAccess.get_file_as_string(path) == "principal invalido"
        and FileAccess.get_file_as_string(path + ".bak") == "backup invalido","Cena bloqueada preserva ambos os arquivos")
    jogo.queue_free()
    await process_frame
