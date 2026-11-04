extends SceneTree

const GAME = preload("res://scripts/RuaComercial.gd")
const MANAGER = preload("res://scripts/Imoveis/GerenciadorImoveis.gd")
var passed := 0
var failed := 0
var temp_dir := "user://test_progressao_" + str(Time.get_ticks_usec())
var game: GAME

func _initialize() -> void:
    root.size = Vector2i(432,768)
    root.content_scale_size = Vector2i(432,768)
    root.gui_embed_subwindows = true
    call_deferred("_run")

func check(condicao: bool, mensagem: String) -> void:
    if condicao:
        passed += 1
        print("PASS: ",mensagem)
    else:
        failed += 1
        printerr("FAIL: ",mensagem)

func _new_game() -> GAME:
    var instance := GAME.new()
    instance.save_path = temp_dir.path_join("save.json")
    instance.legacy_path = temp_dir.path_join("legacy.save")
    root.add_child(instance)
    instance.set_physics_process(false)
    return instance

func _capture(nome: String) -> void:
    var pasta := OS.get_environment("PIXEL_TEST_CAPTURE_DIR")
    if pasta.is_empty() or DisplayServer.get_name() == "headless":
        return
    await process_frame
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png(pasta.path_join(nome + ".png")) == OK,"Captura " + nome)

func _run() -> void:
    create_timer(90).timeout.connect(func() -> void:
        printerr("FAIL: Testes de progressao excederam 90 segundos.")
        quit(1))
    check(DirAccess.make_dir_absolute(temp_dir) == OK,"Criar pasta isolada")
    game = _new_game()
    await process_frame
    await _test_migracao_slots()
    await _test_slots()
    await _test_construcao()
    await _test_comercio()
    await _test_montagem()
    _test_validacao_e_recuperacao()
    game.queue_free()
    await process_frame
    for nome in DirAccess.get_files_at(temp_dir):
        check(DirAccess.remove_absolute(temp_dir.path_join(nome)) == OK,"Limpar " + nome)
    check(DirAccess.remove_absolute(temp_dir) == OK,"Limpar pasta isolada")
    print("RESULT: %d passed, %d failed" % [passed,failed])
    quit(1 if failed else 0)

func _test_slots() -> void:
    check(game.partidas.atual == 1,"Save existente pertence ao slot 1")
    game.money = 5432
    game._salvar_manual()
    check(game.info.text.contains("salvo manualmente"),"Salvar manual informa sucesso")
    var original := FileAccess.get_file_as_string(game.save_path)
    game._menu("Menu")
    check(game.popup.visible and game.shop_list.get_child_count() == 4,"Menu oferece salvar e tres slots")
    await _capture("01_slots")
    (game.shop_list.get_child(2) as Button).pressed.emit()
    check(game.partidas.atual == 2 and game.money == 6500,"Botao inicia slot 2 independente")
    game.money = 4321
    game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
    game._trocar_slot(3)
    check(game.partidas.atual == 3 and game.money == 6500,"Slot 3 independente")
    game.money = 3210
    check(game._save(),"Gravar slot 3")
    game._trocar_slot(1)
    check(game.money == 5432 and game.partidas.atual == 1,"Slot 1 mantem saldo original")
    check(FileAccess.get_file_as_string(game.save_path) == original,"Troca de slots preserva conteudo original")
    game._trocar_slot(2)
    check(game.money == 4321,"Autosave do slot 2 nao cruza dados")
    game.queue_free()
    await process_frame
    game = _new_game()
    check(game.partidas.atual == 2 and game.money == 4321,"Reabrir restaura slot escolhido")
    await game._change_area(true)
    game._buy("banqueta")
    game._trocar_slot(1)
    check(game.partidas.atual == 2 and game.selecionado != null,"Troca nao descarta previa")
    game._cancel_edit()
    game._trocar_slot(1)
    check(not game.indoors and game.moveis.is_empty(),"Troca limpa interior e moveis da partida anterior")
    var segundo := game.partidas.caminho(2)
    var arquivo := FileAccess.open(segundo,FileAccess.WRITE)
    arquivo.store_string("{corrompido")
    arquivo.close()
    game._trocar_slot(2)
    check(game.partidas.atual == 2 and game.money == 4321,"Recuperacao funciona separadamente por slot")
    check(FileAccess.file_exists(segundo + ".corrompido"),"Original danificado do slot 2 preservado")
    var terceiro := game.partidas.caminho(3)
    for path in [terceiro,terceiro + ".bak"]:
        arquivo = FileAccess.open(path,FileAccess.WRITE)
        arquivo.store_string("invalido")
        arquivo.close()
    var imprimir := Engine.print_error_messages
    Engine.print_error_messages = false
    game._trocar_slot(3)
    Engine.print_error_messages = imprimir
    check(game.partidas.atual == 2 and game.money == 4321,"Slot danificado nao substitui partida atual")
    check(game.info.text.contains("nao carregado"),"Falha de troca aparece no HUD")
    game._trocar_slot(0)
    check(game.partidas.atual == 2 and game.info.text.contains("invalido"),"Slot fora do intervalo rejeitado")
    var config := game.partidas.base + ".slots.cfg"
    var selecao := FileAccess.get_file_as_string(config)
    check(DirAccess.make_dir_absolute(config + ".tmp") == OK,"Criar bloqueio temporario da selecao")
    imprimir = Engine.print_error_messages
    Engine.print_error_messages = false
    game._trocar_slot(1)
    Engine.print_error_messages = imprimir
    check(game.partidas.atual == 2 and game.money == 4321,"Falha de selecao nao troca dados em memoria")
    check(FileAccess.get_file_as_string(config) == selecao and game.info.text.contains("Falha"),"Falha preserva selecao persistida e informa jogador")
    check(DirAccess.remove_absolute(config + ".tmp") == OK,"Remover bloqueio temporario vazio")

func _test_migracao_slots() -> void:
    var legado := temp_dir.path_join("antigo.save")
    var original := JSON.stringify({"cash":5000,"owns_counter":true})
    var arquivo := FileAccess.open(legado,FileAccess.WRITE)
    arquivo.store_string(original)
    arquivo.close()
    var migrado := GAME.new()
    migrado.save_path = temp_dir.path_join("migrado.json")
    migrado.legacy_path = legado
    root.add_child(migrado)
    migrado.set_physics_process(false)
    check(migrado.partidas.atual == 1 and migrado.money == 5000,"Legado pertence somente ao slot 1")
    migrado._trocar_slot(2)
    check(migrado.money == 6500 and migrado.gestor_imoveis.carregar_estado(GAME.LOJA_ID)["guardados"].is_empty(),"Slot 2 nao importa compras do legado")
    check(FileAccess.get_file_as_string(legado) == original and FileAccess.get_file_as_string(legado + ".pre_modular") == original,"Migracao preserva arquivo e backup legados")
    migrado._trocar_slot(1)
    check(migrado.money == 5000 and migrado.gestor_imoveis.carregar_estado(GAME.LOJA_ID)["guardados"].size() == 1,"Slot 1 restaura patrimonio migrado")
    migrado.queue_free()
    await process_frame

func _ir_estacao(tipo: String) -> void:
    var estacao := game._estacao(tipo)
    if estacao == null:
        check(false,"Estacao existe: " + tipo)
        return
    var rota := game._navegacao().caminho_ate(estacao.position,85)
    check(not rota.is_empty(),"Estacao acessivel: " + tipo)
    if not rota.is_empty():
        game.pos_player = rota[rota.size()-1]
        game.player.position = game.pos_player

func _caminhar_cliente(fase: String) -> void:
    for i in range(250):
        var cliente: Dictionary = game.loja.estado["cliente"]
        if (fase.is_empty() and cliente.is_empty()) or (not cliente.is_empty() and cliente["fase"] == fase):
            return
        game._cliente_comercial(0.5)
        if not game.loja.estado["cliente"].is_empty():
            check(game._walkable(game.customer.position),"Cliente segue piso livre, sem atravessar moveis")
    check(false,"Cliente chegou a fase " + fase)

func _test_comercio() -> void:
    _ir_estacao("notebook")
    game._interact()
    check(game.popup.visible and game.popup.title.contains("fornecedor"),"Fornecedor conectado ao menu e notebook")
    await _capture("02_fornecedor")
    var saldo := game.money
    check(game._operacao_comercial("comprar","ram_brisa"),"Comprar primeira peca")
    check(game.money == saldo - 140 and game.loja.quantidade("ram_brisa") == 0,"Compra debita uma vez, sem adiantar estoque")
    var pedido := int(game.loja.estado["pedidos"][0]["id"])
    check(not game._operacao_comercial("receber",str(pedido)),"Recebimento antecipado rejeitado")
    game.loja.avancar(29)
    check(float(game.loja.estado["pedidos"][0]["restante"]) == 1,"Prazo de entrega medido em segundos ativos")
    check(game._save(),"Persistir entrega em transporte")
    game.popup.hide()
    game.queue_free()
    await process_frame
    game = _new_game()
    check(game.loja.quantidade("ram_brisa") == 0 and float(game.loja.estado["pedidos"][0]["restante"]) == 1,"Reabrir preserva prazo sem antecipar estoque")
    await game._change_area(true)
    game.loja.avancar(1)
    check(game._operacao_comercial("receber",str(pedido)),"Receber entrega pronta")
    check(game.loja.quantidade("ram_brisa") == 1 and game.money == saldo - 140,"Recebimento nao cobra de novo")
    check(not game._operacao_comercial("receber",str(pedido)) and game.loja.quantidade("ram_brisa") == 1,"Duplo recebimento nao duplica estoque")
    var dinheiro := game.money
    game.money = 0
    check(not game._operacao_comercial("comprar","cpu_aurora") and game.loja.estado["pedidos"].size() == 1,"Saldo insuficiente nao cria pedido")
    game.money = dinheiro
    _ir_estacao("balcao")
    check(game._operacao_comercial("cliente","ram_brisa"),"Cliente solicita produto em estoque")
    check(not game._operacao_comercial("vender"),"Nao paga antes de chegar ao balcao")
    _caminhar_cliente("aguardando")
    check(game.loja.estado["cliente"]["fase"] == "aguardando","Cliente realmente entra e espera atendimento")
    game.popup.hide()
    await _capture("03_cliente_balcao")
    game.selecionado = game._estacao("balcao")
    game._edit_action("Vender")
    check(game.moveis.has(game.selecionado),"Balcao em atendimento nao pode ser vendido")
    game.selecionado = null
    check(game._operacao_comercial("vender"),"Venda completa no balcao")
    check(game.money == saldo + 40 and game.loja.quantidade("ram_brisa") == 0,"Venda baixa estoque e credita receita com lucro")
    check(not game._operacao_comercial("vender") and game.money == saldo + 40,"Clique repetido nao duplica pagamento")
    var resumo := game.loja.resumo()
    check(resumo["compras"] == 140 and resumo["receita"] == 180 and resumo["cmv"] == 140 and resumo["lucro"] == 40,"Livro-caixa separa compra, receita, CMV e lucro bruto")
    game.popup.hide()
    game.queue_free()
    await process_frame
    game = _new_game()
    check(game.money == saldo + 40 and game.loja.quantidade("ram_brisa") == 0,"Reinicio preserva caixa e estoque vendido")
    await game._change_area(true)
    _caminhar_cliente("")
    check(game.loja.estado["cliente"].is_empty(),"Cliente sai apos pagar sem novo pagamento")
    _ir_estacao("notebook")
    var original_path := game.save_path
    var pasta := temp_dir.path_join("destino_pasta")
    check(DirAccess.make_dir_absolute(pasta) == OK,"Criar bloqueio de escrita isolado")
    game.save_path = pasta
    var imprimir := Engine.print_error_messages
    Engine.print_error_messages = false
    var resultado := game._operacao_comercial("comprar","ram_brisa")
    Engine.print_error_messages = imprimir
    check(not resultado and game.money == saldo + 40 and game.loja.estado["pedidos"].size() == 1,"Falha de escrita desfaz transacao em memoria")
    check(game.info.text.contains("ERRO") and DirAccess.dir_exists_absolute(pasta),"Falha e explicita e preserva destino")
    game.save_path = original_path
    check(DirAccess.remove_absolute(pasta) == OK,"Remover apenas diretorio de teste vazio")

func _test_montagem() -> void:
    for caso in [
        [{"placa":"placa_aurora","cpu":"cpu_nova"},"Socket"],
        [{"placa":"placa_aurora","ram":"ram_vento"},"RAM"],
        [{"gabinete":"caixa_ninho","placa":"placa_nova"},"Formato"],
        [{"gabinete":"caixa_ninho","gpu":"gpu_trovao"},"comprida"],
        [{"cpu":"cpu_aurora","gpu":"gpu_pixel","fonte":"fonte_fraca"},"Fonte"],
        [{"gpu":"gpu_trovao","fonte":"fonte_clara"},"conectores"],
        [{"placa":"placa_aurora","ssd":"ssd_veloz"},"Conector"],
        [{"cpu":"cpu_nova","cooler":"cooler_neve"},"Cooler"]
    ]:
        check(GAME.PECAS.incompatibilidade(caso[0]).contains(caso[1]),"Compatibilidade: " + caso[1])
    _ir_estacao("balcao")
    check(game._operacao_comercial("pedido_pc"),"Aceitar pedido de PC do cliente")
    _caminhar_cliente("aguardando")
    check(not game._operacao_comercial("vender"),"PC incompleto nao pode ser entregue")
    _ir_estacao("notebook")
    var pecas := ["caixa_ninho","placa_aurora","cpu_aurora","ram_brisa","fonte_clara","ssd_trilha","gpu_pixel","cooler_neve"]
    var saldo := game.money
    for id in pecas:
        check(game._operacao_comercial("comprar",id),"Encomendar " + id)
    check(game.money == saldo - 1780,"Custo do primeiro PC calculado com pecas reais")
    game.loja.avancar(30)
    for pedido: Dictionary in game.loja.estado["pedidos"]:
        if not pedido["recebido"]:
            check(game._operacao_comercial("receber",str(int(pedido["id"]))),"Receber componente " + str(pedido["peca"]))
    _ir_estacao("bancada")
    check(not game._operacao_comercial("instalar","cpu_aurora","cpu"),"CPU nao instala sem gabinete e placa")
    game._interact()
    check(game.popup.visible and game.popup.title.contains("Montagem"),"Botao A abre bancada mais proxima")
    await process_frame
    await process_frame
    await _capture("04_montagem_manual")
    var origem := game.shop_list.find_child("Peca_caixa_ninho",true,false) as Button
    var destino := game.shop_list.find_child("Encaixe_gabinete",true,false) as Button
    check(origem != null and destino != null,"Peca em estoque e encaixe manual aparecem na bancada")
    if origem != null and destino != null:
        var lista := game.shop_list.get_parent() as ScrollContainer
        lista.ensure_control_visible(destino.get_parent() as Control)
        await process_frame
        await process_frame
        check(lista.get_global_rect().has_point(origem.get_global_rect().get_center()) and lista.get_global_rect().has_point(destino.get_global_rect().get_center()),"Origem e destino visiveis antes do arraste real")
        var de := origem.get_global_rect().get_center() + Vector2(game.popup.position)
        var ate := destino.get_global_rect().get_center() + Vector2(game.popup.position)
        var toque := InputEventMouseButton.new()
        toque.button_index = MOUSE_BUTTON_LEFT
        toque.position = de
        toque.pressed = true
        root.push_input(toque,true)
        var movimento := InputEventMouseMotion.new()
        movimento.position = de + Vector2(16,0)
        movimento.relative = Vector2(16,0)
        movimento.button_mask = MOUSE_BUTTON_MASK_LEFT
        root.push_input(movimento,true)
        await process_frame
        movimento = movimento.duplicate()
        movimento.position = ate
        movimento.relative = ate - de - Vector2(16,0)
        root.push_input(movimento,true)
        await process_frame
        check(game.popup.gui_is_dragging(),"Arrastar inicia drag-and-drop real do Godot")
        toque = toque.duplicate()
        toque.position = ate
        toque.pressed = false
        root.push_input(toque,true)
        await process_frame
        await process_frame
    check(game.loja.estado["montagem"]["pecas"].get("gabinete") == "caixa_ninho","Soltar no encaixe instala o gabinete")
    check(game.loja.quantidade("caixa_ninho") == 0,"Peca instalada fica reservada, fora do estoque vendavel")
    for id in pecas.slice(1):
        var categoria: String = GAME.PECAS.PECAS[id]["categoria"]
        check(game._operacao_comercial("instalar",id,categoria),"Instalar manualmente " + id)
        if id == "ram_brisa":
            game.popup.hide()
            game.queue_free()
            await process_frame
            game = _new_game()
            check(game.loja.estado["montagem"]["pecas"].size() == 4 and game.loja.quantidade("cpu_aurora") == 0,"Reabrir montagem parcial mantem reserva das pecas")
            await game._change_area(true)
            _ir_estacao("bancada")
    check(game.loja.estado["montagem"]["pecas"].size() == 8,"Oito pecas instaladas individualmente")
    check(not game._operacao_comercial("testar"),"Boot rejeita cabos desconectados")
    check(game._operacao_comercial("conectar"),"Conectar cabos manualmente")
    check(game._operacao_comercial("testar"),"Teste de boot e requisitos aprova PC compativel")
    check(game.loja.estado["montagem"]["fase"] == "testado","Resultado de teste persistido")
    game._abrir_montagem()
    await _capture("05_pc_testado")
    check(not game._operacao_comercial("remover","","placa"),"Placa nao sai com componentes ainda instalados")
    game.popup.hide()
    game._trocar_slot(1)
    check(game.loja.estado["montagem"].is_empty() and game.loja.estado["estoque"].is_empty(),"Estoque e montagem nao vazam para outro slot")
    game._trocar_slot(2)
    check(game.loja.estado["montagem"]["fase"] == "testado" and game.loja.estado["montagem"]["conectado"],"Troca de slots restaura PC testado e cabos")
    await game._change_area(true)
    _ir_estacao("balcao")
    check(game._operacao_comercial("vender"),"Entregar PC testado ao cliente")
    check(game.money == saldo + 670 and game.loja.estado["pcs"].size() == 1,"Entrega credita uma vez e preserva configuracao do PC")
    check(not game._operacao_comercial("vender") and game.money == saldo + 670,"PC nao pode ser pago duas vezes")
    var resumo := game.loja.resumo()
    check(resumo["receita"] == 2630 and resumo["cmv"] == 1920 and resumo["lucro"] == 710,"Lucro acumulado confere para peca e PC")
    var simulacao := GAME.COMERCIO.new()
    for id in pecas:
        simulacao.estado["estoque"][id] = 1
    check(simulacao.criar_cliente("",true),"Criar pedido isolado para cancelamento")
    check(simulacao.instalar("caixa_ninho","gabinete") and simulacao.instalar("placa_aurora","placa"),"Montagem parcial reserva pecas")
    simulacao.estado["estoque"]["cpu_nova"] = 1
    check(not simulacao.instalar("cpu_nova","cpu") and simulacao.quantidade("cpu_nova") == 1,"Socket incompativel nao consome peca")
    check(simulacao.cancelar_montagem() and simulacao.quantidade("caixa_ninho") == 1 and simulacao.quantidade("placa_aurora") == 1,"Cancelar devolve todas as pecas reservadas")
    check(not simulacao.cancelar_montagem() and simulacao.quantidade("caixa_ninho") == 1,"Cancelar duas vezes nao duplica pecas")
    check(GAME.COMERCIO.validar(simulacao.estado),"Cancelamento permanece salvavel")

func _test_validacao_e_recuperacao() -> void:
    check(GAME.COMERCIO.validar(game.loja.estado),"Estado integrado valido")
    for estoque in [{"ram_brisa":-1},{"ram_brisa":0.5},{"desconhecida":1}]:
        var invalido := GAME.COMERCIO.inicial()
        invalido["estoque"] = estoque
        check(not GAME.COMERCIO.validar(invalido),"Estoque invalido rejeitado: " + str(estoque))
    var invalido := game.loja.estado.duplicate(true)
    invalido["caixa"].append(invalido["caixa"][0].duplicate(true))
    check(not GAME.COMERCIO.validar(invalido),"Lancamento duplicado rejeitado")
    invalido = game.loja.estado.duplicate(true)
    invalido["caixa"][0]["valor"] = {}
    check(not GAME.COMERCIO.validar(invalido),"Valor financeiro de tipo invalido rejeitado sem erro de script")
    invalido = game.loja.estado.duplicate(true)
    invalido["cliente"]["fase"] = "aguardando"
    check(not GAME.COMERCIO.validar(invalido),"Cliente ja pago nao pode reaparecer aguardando pagamento")
    var gestor := MANAGER.new()
    gestor.estados = game.gestor_imoveis.estados.duplicate(true)
    gestor.comercio = game.loja.estado.duplicate(true)
    var path := temp_dir.path_join("comercio_backup.json")
    check(gestor.gravar(1000,path) and gestor.gravar(1250,path),"Gravar comercio com backup independente")
    var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
    dados["comercio"]["estoque"]["ram_brisa"] = -1
    var arquivo := FileAccess.open(path,FileAccess.WRITE)
    arquivo.store_string(JSON.stringify(dados))
    arquivo.close()
    var recuperado := gestor.ler(path,"")
    check(recuperado.get("dinheiro") == 1000,"Corrupcao comercial recupera backup valido")
    check(recuperado["comercio"]["pcs"].size() == 1 and recuperado["comercio"]["montagem"]["fase"] == "entregue","Recuperacao preserva PC entregue e estoque")
    check(FileAccess.file_exists(path + ".corrompido"),"Estado comercial danificado preservado")

func _test_construcao() -> void:
    await game._change_area(true)
    for item in game.moveis:
        check(game._can_place(item),"Layout inicial mantem acesso: " + item.item_id)
    var dados := {"piso_interno":PackedVector2Array([Vector2(0,0),Vector2(300,0),Vector2(300,300),Vector2(0,300)])}
    var parede := PackedVector2Array([Vector2(140,0),Vector2(160,0),Vector2(160,300),Vector2(140,300)])
    var formas: Array[PackedVector2Array] = [parede]
    var nav := GAME.NAVEGACAO.new()
    nav.configurar(dados,formas,Vector2(40,150))
    check(not nav.caminho_ate(Vector2(80,150)).is_empty(),"Rota livre encontrada")
    check(nav.caminho_ate(Vector2(260,150)).is_empty(),"Barreira continua rejeita jogador preso")
    check(nav.caminho_ate(Vector2(260,150),85).is_empty(),"Estacao isolada nao e considerada acessivel")
    formas = [PackedVector2Array([Vector2(140,0),Vector2(160,0),Vector2(160,220),Vector2(140,220)])]
    nav.configurar(dados,formas,Vector2(40,150))
    var rota := nav.caminho_ate(Vector2(260,150))
    check(not rota.is_empty(),"Desvio em torno da parede e permitido")
    for i in range(1,rota.size()):
        check(nav.segmento_livre(rota[i-1],rota[i]),"Rota nao corta quinas nem colisoes")
    formas = [PackedVector2Array([Vector2(140,0),Vector2(160,0),Vector2(160,292),Vector2(140,292)])]
    nav.configurar(dados,formas,Vector2(40,150))
    check(nav.caminho_ate(Vector2(260,150)).is_empty(),"Fresta menor que o personagem nao vira passagem")
    game._buy("balcao_pc_store")
    var previa := game.selecionado
    previa.position = game.cadastro["entrada_interna"]
    for angle in range(4):
        check(not game._can_place(previa),"Entrada protegida no giro %d" % angle)
        previa.girar()
    var saldo := game.money
    game._edit_action("OK")
    check(game.money == saldo and game.comprando,"Layout invalido nao cobra nem confirma")
    game._cancel_edit()
    for item in game.moveis:
        item.queue_free()
    game.moveis.clear()
    var deslocamento := 35.0 / 64.0
    for v in [0.75,4.05]:
        game._create_furniture("balcao_atendimento",GAME.INTERIOR.ponto(Vector2(3 + deslocamento,v + deslocamento),game.cadastro["origem"]),0)
    game.pos_player = GAME.INTERIOR.ponto(Vector2(1,2.5),game.cadastro["origem"])
    check(not game._navegacao().caminho_ate(game.pos_player).is_empty(),"Corredor aberto liga jogador a entrada antes da construcao")
    var fechamento := game._create_furniture("balcao_atendimento",GAME.INTERIOR.ponto(Vector2(3 + deslocamento,2.4 + deslocamento),game.cadastro["origem"]),0)
    var separado := true
    for outro in game.moveis:
        if outro != fechamento:
            separado = separado and Geometry2D.intersect_polygons(fechamento.poligono_colisao(fechamento.position,4),outro.poligono_colisao(outro.position,4)).is_empty()
    check(separado,"Movel que fecha corredor nao sobrepoe os outros")
    check(not game._can_place(fechamento) and game.motivo_construcao.contains("rota"),"Validacao real rejeita fechar corredor sem colisao direta")
    game._restore_furniture()
    game.pos_player = game.cadastro["entrada_interna"]
