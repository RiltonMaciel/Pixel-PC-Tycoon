extends SceneTree

const GAME = preload("res://scripts/RuaComercial.gd")
const MANAGER = preload("res://scripts/Imoveis/GerenciadorImoveis.gd")
const SPRITES = preload("res://scripts/Imoveis/CatalogoSprites.gd")
var failed := 0
var passed := 0
var temp_dir := "user://test_pixel_" + str(Time.get_ticks_usec())
var game: GAME

func _initialize() -> void:
    root.size = Vector2i(432,768)
    root.content_scale_size = Vector2i(432,768)
    root.gui_embed_subwindows = true
    call_deferred("_run")

func check(condition: bool, message: String) -> void:
    if condition:
        passed += 1
        print("PASS: ",message)
    else:
        failed += 1
        printerr("FAIL: ",message)

func _new_game() -> GAME:
    var scene := load(str(ProjectSettings.get_setting("application/run/main_scene"))) as PackedScene
    var instance: GAME = scene.instantiate()
    instance.save_path = temp_dir.path_join("save.json")
    instance.legacy_path = temp_dir.path_join("legacy.save")
    root.add_child(instance)
    instance.set_physics_process(false)
    return instance

func _capture(name: String) -> void:
    var output := OS.get_environment("PIXEL_TEST_CAPTURE_DIR")
    if output.is_empty() or DisplayServer.get_name() == "headless":
        return
    await process_frame
    await RenderingServer.frame_post_draw
    var result := root.get_texture().get_image().save_png(output.path_join(name + ".png"))
    check(result == OK,"Captura " + name)

func _run() -> void:
    create_timer(45.0).timeout.connect(func() -> void:
        printerr("FAIL: Testes excederam 45 segundos.")
        quit(1))
    check(DirAccess.make_dir_absolute(temp_dir) == OK,"Pasta isolada de testes")
    game = _new_game()
    await process_frame
    await _test_bairro()
    await _test_modular()
    game.queue_free()
    await process_frame
    var empty := FileAccess.open(temp_dir.path_join("save.json"),FileAccess.WRITE)
    empty.store_string(JSON.stringify({"versao":2,"dinheiro":6500,"imoveis":{"pc_store_001":{"moveis":[],"guardados":[]}}}))
    empty.close()
    game = _new_game()
    await process_frame
    check(root.get_visible_rect().size == Vector2(432,768),"Viewport de teste 432x768")
    check(not game.save_bloqueado and game.money == 6500,"Novo jogo sem afetar save real")
    check((game.layer.get_node("Header") as Control).size.y < 100,"Cabecalho nao cobre o mundo nem intercepta toques")
    check(game._walkable(game.pos_player),"Spawn externo caminhavel")
    var pad_touch := InputEventScreenTouch.new()
    pad_touch.index = 7
    pad_touch.pressed = true
    pad_touch.position = game.pad_center + Vector2(30,0)
    root.push_input(pad_touch,true)
    await process_frame
    check(game.finger == 7 and game.move == Vector2.RIGHT,"D-pad recebe toque real")
    pad_touch.pressed = false
    pad_touch.position = Vector2(20,20)
    root.push_input(pad_touch,true)
    await process_frame
    check(game.move == Vector2.ZERO and game.finger == -1,"D-pad solta mesmo sobre cabecalho")
    check(not game._walkable(GAME.BAIRRO.local_loja(Vector2(900,600))),"Interior do predio externo bloqueado")
    check(not game._walkable(GAME.BAIRRO.local_loja(Vector2(650,700))),"Fachada bloqueada")
    var route: PackedVector2Array = game.cadastro["rota_cliente"]
    for i in range(route.size()):
        for step in range(21):
            check(game._walkable(route[i].lerp(route[(i+1)%route.size()],float(step)/20.0)),"Rota NPC %s/%s" % [i,step])
    game._buy()
    check(game.moveis.is_empty() and game.money == 6500,"Compra bloqueada na rua")
    await _capture("01_exterior")
    # O sprite da porta deve amostrar a mesma textura usada na fachada em cena.
    var fachada_sprite := game.bairro.predio.get_child(0) as Sprite2D
    check(fachada_sprite != null,"Fachada PC Store renderizada na rua")
    if fachada_sprite != null:
        check(game.porta.esquerda.texture == fachada_sprite.texture and game.porta.direita.texture == fachada_sprite.texture,"Porta e fachada usam exatamente a mesma textura")
        check(is_equal_approx(game.porta.scale.x, GAME.BAIRRO.LOJA_ESCALA) and game.porta.position.is_equal_approx(GAME.BAIRRO.LOJA_POS),"Porta usa mesma escala e origem da fachada")
    game.porta.visible = true
    game.porta.abertura = 1.0
    await _capture("02_porta")
    game.porta.visible = false
    # A porta deve preservar o estado visual tanto na abertura quanto no fechamento.
    await game.porta.animar(true)
    check(game.porta.visible and is_equal_approx(game.porta.abertura,1.0),"Porta termina aberta e visivel")
    check(game.porta.esquerda.polygon.size() == 4 and game.porta.direita.polygon.size() == 4,"Folhas da porta mantem quatro vertices")
    await game.porta.animar(false)
    check(not game.porta.visible and is_equal_approx(game.porta.abertura,0.0),"Porta fecha e oculta recortes sem sobreposicao")
    game.transitioning = true
    var before := game.pos_player
    game.move = Vector2.RIGHT
    game._physics_process(1.0)
    check(game.pos_player == before,"Movimento bloqueado durante transicao")
    game.transitioning = false
    await game._change_area(true)
    check(game.indoors and not game.transitioning,"Entrada termina no interior")
    check(game.fade.color.a == 0.0,"Fade termina transparente")
    check(game._walkable(game.pos_player),"Spawn interno no piso")
    check(not game._walkable(Vector2(400,700)),"Parede interna bloqueada")
    check(game.gestor_imoveis.imovel_atual == GAME.LOJA_ID,"Interior vinculado ao ID")
    await _capture("03_interior_vazio")
    var shop_button := game.layer.get_node("Menu").get_child(0) as Button
    var click := InputEventMouseButton.new()
    click.button_index = MOUSE_BUTTON_LEFT
    click.position = shop_button.get_global_rect().get_center()
    click.pressed = true
    root.push_input(click,true)
    click = click.duplicate()
    click.pressed = false
    root.push_input(click,true)
    await process_frame
    check(game.popup.visible,"Botao Loja abre compra por clique real")
    await _capture("05_loja")
    game.popup.hide()
    game.money = 0
    game._buy()
    check(game.moveis.is_empty(),"Saldo insuficiente nao cria movel")
    game.money = 6500
    game._buy()
    check(game.selecionado != null and game.comprando,"Compra cria previa")
    check(game.money == 6500,"Previa nao cobra")
    game._cancel_edit()
    check(game.moveis.is_empty() and game.money == 6500,"Cancelar compra nao cobra")
    game._buy()
    var item = game.selecionado
    item.position = Vector2(700,400)
    check(game._can_place(item),"Posicao valida no piso")
    await _capture("06_edicao")
    item.position = game.pos_player
    check(not game._can_place(item),"Movel nao sobrepoe jogador")
    item.position = game.cadastro["saida_interna"]
    check(not game._can_place(item),"Movel nao bloqueia saida")
    item.position = Vector2(800,200)
    check(not game._can_place(item),"Movel nao atravessa parede")
    game._edit_action("OK")
    check(game.comprando and game.money == 6500,"Confirmacao invalida nao cobra")
    item.position = Vector2(700,400)
    var textures: Array[Texture2D] = []
    for angle in [0,90,180,270]:
        textures.append(item.visual.texture)
        check(item.ANGULOS[item.orientacao] == angle,"Orientacao %d" % angle)
        check(item.rotation == 0.0 and item.visual.rotation == 0.0,"PNG nao gira em 2D")
        check(item.visual.offset == Vector2(-128,-248),"Pivo consistente")
        check(item.visual.texture.get_size() == Vector2(256,256),"Canvas consistente")
        game._edit_action("Girar")
    check(textures[0] != textures[1] and textures[1] != textures[2] and textures[2] != textures[3],"Quatro texturas distintas")
    game._edit_action("Girar")
    game._edit_action("OK")
    check(game.money == 6050 and not item.em_edicao,"Compra cobra uma vez")
    check(FileAccess.file_exists(game.save_path),"Compra salva em disco")
    check(not game._walkable(Vector2(700,390)),"Movel bloqueia caminhada")
    await _capture("04_balcao")
    var selected_at: Vector2 = item.position + Vector2(0,-35)
    game.cam.force_update_scroll()
    var screen: Vector2 = game.get_canvas_transform() * selected_at
    var touch := InputEventScreenTouch.new()
    touch.index = 3
    touch.pressed = true
    touch.position = screen
    root.push_input(touch,true)
    await process_frame
    check(game.selecionado == item,"Toque seleciona sprite do movel")
    game._edit_action("Mover")
    root.push_input(touch,true)
    await process_frame
    check(game.drag_finger == 3,"Arraste captura dedo")
    var drag := InputEventScreenDrag.new()
    drag.index = 3
    drag.position = screen + Vector2(48,24)
    root.push_input(drag,true)
    await process_frame
    check(item.position != Vector2(700,400),"Arraste move a previa")
    touch.pressed = false
    root.push_input(touch,true)
    await process_frame
    check(game.drag_finger == -1,"Soltar encerra arraste")
    game._edit_action("Girar")
    check(item.orientacao == 2,"Giro altera previa")
    check(game._save(),"Salvar durante edicao")
    var reader := MANAGER.new()
    var data := reader.ler(game.save_path,game.legacy_path)
    var saved_item: Dictionary = data["imoveis"][GAME.LOJA_ID]["moveis"][0]
    check(saved_item["angulo"] == 90 and Vector2(saved_item["posicao"][0],saved_item["posicao"][1]) == Vector2(700,400),"Save ignora posicao e giro nao confirmados")
    game._cancel_edit()
    check(item.position == Vector2(700,400) and item.orientacao == 1,"Cancelar restaura posicao e orientacao")
    game._buy()
    var second = game.selecionado
    second.position = item.position
    check(not game._can_place(second),"Sobreposicao entre moveis bloqueada")
    check(game._save(),"Save durante segunda compra")
    data = reader.ler(game.save_path,game.legacy_path)
    check(data["imoveis"][GAME.LOJA_ID]["moveis"].size() == 1 and data["dinheiro"] == 6050,"Save exclui compra ainda nao confirmada")
    game._cancel_edit()
    await game._change_area(false)
    check(not game.indoors and game.pos_player == game.cadastro["saida_externa"],"Saida retorna a entrada externa")
    check(game.moveis.is_empty() and not game.porta.visible,"Exterior nao mostra moveis nem sobreposicao da porta")
    await game._change_area(true)
    check(game.moveis.size() == 1 and game.moveis[0].orientacao == 1,"Reentrada restaura movel e orientacao")
    game.queue_free()
    await process_frame
    game = _new_game()
    check(game.money == 6050,"Reinicio restaura saldo")
    await game._change_area(true)
    check(game.moveis.size() == 1 and game.moveis[0].position == Vector2(700,400),"Reinicio restaura imovel")
    game.selecionado = game.moveis[0]
    game._edit_action("Vender")
    check(game.money == 6275 and game.moveis.is_empty(),"Venda devolve R$225 e remove movel")
    data = reader.ler(game.save_path,game.legacy_path)
    check(data["imoveis"][GAME.LOJA_ID]["moveis"].is_empty(),"Venda persiste")
    check(reader._validar({"versao":1,"dinheiro":-1,"imoveis":{}}) == false,"Save rejeita saldo negativo")
    check(reader._validar({"versao":1,"dinheiro":1.5,"imoveis":{}}) == false,"Save rejeita saldo fracionario")
    check(reader._validar({"versao":1,"dinheiro":6500,"imoveis":{"inexistente":{"moveis":[]}}}) == false,"Save rejeita imovel inexistente")
    var legacy := FileAccess.open(game.legacy_path,FileAccess.WRITE)
    legacy.store_string(JSON.stringify({"cash":5000,"owns_counter":true,"furniture_position":[670,405]}))
    legacy.close()
    data = reader.ler(temp_dir.path_join("migrado.json"),game.legacy_path)
    check(data["dinheiro"] == 5000 and data["imoveis"][GAME.LOJA_ID]["guardados"].size() == 1,"Migracao preserva saldo e compra em armazenamento")
    check(FileAccess.file_exists(game.legacy_path),"Migracao preserva arquivo legado")
    check(reader.gravar(5000,temp_dir.path_join("migrado.json")),"Migracao grava formato modular")
    check(FileAccess.file_exists(game.legacy_path + ".pre_modular"),"Backup pre-modular preservado")
    await _test_migration()
    game.queue_free()
    await process_frame
    for filename in DirAccess.get_files_at(temp_dir):
        check(DirAccess.remove_absolute(temp_dir.path_join(filename)) == OK,"Limpeza de " + filename)
    check(DirAccess.remove_absolute(temp_dir) == OK,"Limpeza da pasta isolada")
    print("RESULT: %d passed, %d failed" % [passed,failed])
    quit(1 if failed else 0)

func _test_modular() -> void:
    check(game.sala.get_child_count() == 43,"Sala construida de 30 pisos, 11 paredes, canto e soleira")
    var dados := game.cadastro.duplicate(true)
    dados["modulos"] = Vector2i(8,7)
    game.sala.configurar(dados)
    check(game.sala.get_child_count() == 73,"Dimensoes da sala geram novas pecas, nao uma imagem esticada")
    game.sala.configurar(game.cadastro)
    check(game.player.texture.get_size() == Vector2(160,240),"Protagonista usa sprite normalizado")
    var initial := game.player.texture
    game.player.atualizar(Vector2.RIGHT,0.2)
    check(game.player.direcao == "direita" and game.player.texture != initial,"Animacao usa quadro real da direcao")
    game.player.atualizar(Vector2.ZERO,0.1)
    check(game.player.tempo == 0.0,"Parada retorna ao idle")
    check(game.player.offset == Vector2(-80,-232),"Pivo dos personagens na base")
    for id in ["tecnico","cliente_mochila"]:
        var personagem = GAME.PERSONAGEM.new()
        personagem.configurar(id)
        check(personagem.quadros.size() == 4,"Quatro direcoes importadas: " + id)
        personagem.free()
    await game._change_area(true)
    check(game.moveis.size() == 4,"Nova partida inicia com quatro moveis separados")
    check(game.sala.visible and not game.bairro.visible,"Interior modular substitui bairro")
    for item in game.moveis:
        check(game._can_place(item),"Movel inicial em posicao valida: " + item.item_id)
        check(not item.girar() and item.orientacao == 0,"Giro indisponivel nao inventa textura: " + item.item_id)
    game._populate_shop()
    check(game.shop_list.get_child_count() == 11,"Todos os 11 moveis no catalogo da loja")
    game.cam.force_update_scroll()
    var bounds: Rect2 = game.sala.limites()
    var transform := game.get_canvas_transform()
    check((transform * bounds.position).x >= 0 and (transform * bounds.end).x <= 432,"Sala inteira cabe horizontalmente")
    check((transform * bounds.position).y > 90 and (transform * bounds.end).y < 581,"Sala nao fica sob HUD ou D-pad")
    var position_before := game.cam.position
    game.move = Vector2(-1,0)
    game._physics_process(0.1)
    check(game.cam.position == position_before,"Camera interna preserva visao ampla")
    game._stop_input()
    await _capture("07_sala_modular")
    check(game._save(),"Layout inicial salvo")
    await game._change_area(false)
    await game._change_area(true)
    check(game.moveis.size() == 4,"Reentrada nao duplica moveis iniciais")
    game.selecionado = game.moveis[0]
    var selected = game.selecionado
    game._edit_action("Girar")
    check(not selected.em_edicao and selected.orientacao == 0,"Giro ausente informa sem abrir edicao")
    game._cancel_edit()
    game._menu("Loja")
    await process_frame
    var buy_button := game.shop_list.get_child(0) as Button
    var click := InputEventMouseButton.new()
    click.button_index = MOUSE_BUTTON_LEFT
    click.position = Vector2(game.popup.position) + buy_button.get_global_rect().get_center()
    click.pressed = true
    root.push_input(click,true)
    click = click.duplicate()
    click.pressed = false
    root.push_input(click,true)
    await process_frame
    check(game.selecionado != null and game.selecionado.item_id == "balcao_atendimento","Catalogo compra sprite novo por evento de mouse")
    game._cancel_edit()
    game.popup.hide()
    game._buy("banqueta")
    var stool = game.selecionado
    var target := GAME.INTERIOR.ponto(Vector2(4,4.5),game.cadastro["origem"])
    game._drag(game.get_canvas_transform() * target)
    check(stool.position == target and game._can_place(stool),"Arraste de movel novo respeita grade do kit")
    var cash := game.money
    game._edit_action("OK")
    check(game.money == cash - 90 and game.moveis.size() == 5,"Compra de banqueta cobra preco do catalogo")
    await game._change_area(false)
    await game._change_area(true)
    check(game.moveis.size() == 5 and game.moveis[4].item_id == "banqueta" and game.moveis[4].position == target,"Novo movel persiste ao sair e entrar")
    game.selecionado = game.moveis[4]
    game._edit_action("Vender")
    check(game.money == cash - 45 and game.moveis.size() == 4,"Revenda do novo movel usa metade do preco")
    var start := game.pos_player
    game.pos_player = game.cadastro["saida_interna"]
    game._interact()
    await create_timer(1.0).timeout
    check(not game.indoors,"Botao A na soleira sai para o bairro")
    game._interact()
    await create_timer(1.0).timeout
    check(game.indoors and game._walkable(game.pos_player),"Botao A externo retorna a entrada modular")
    game.pos_player = start

func _test_migration() -> void:
    var path := temp_dir.path_join("old_v1.json")
    var old := {"versao":1,"dinheiro":4321,"imoveis":{"pc_store_001":{"moveis":[
        {"id":"balcao_pc_store","posicao":[700,400],"angulo":90},
        {"id":"balcao_pc_store","posicao":[600,450],"angulo":180}
    ]}}}
    var file := FileAccess.open(path,FileAccess.WRITE)
    var original := JSON.stringify(old)
    file.store_string(original)
    file.close()
    var instance := GAME.new()
    instance.save_path = path
    instance.legacy_path = temp_dir.path_join("no_legacy.save")
    root.add_child(instance)
    instance.set_physics_process(false)
    await instance._change_area(true)
    check(instance.moveis.is_empty() and instance.guardados.size() == 2,"Save v1 nao perde moveis ao trocar geometria")
    instance._buy("balcao_pc_store",0)
    instance._cancel_edit()
    check(instance.guardados.size() == 2 and instance.money == 4321,"Cancelar recuperacao preserva armazenamento e saldo")
    instance._buy("balcao_pc_store",0)
    instance.selecionado.position = Vector2(700,400)
    check(instance._save(),"Salvar durante recuperacao")
    var manager := MANAGER.new()
    var data := manager.ler(path,instance.legacy_path)
    check(data["imoveis"][GAME.LOJA_ID]["guardados"].size() == 2 and data["imoveis"][GAME.LOJA_ID]["moveis"].is_empty(),"Previa de recuperacao nao duplica nem perde item")
    instance._edit_action("OK")
    check(instance.guardados.size() == 1 and instance.moveis.size() == 1 and instance.money == 4321,"Recuperacao confirma sem cobrar")
    check(instance.moveis[0].orientacao == 1,"Recuperacao preserva orientacao")
    check(FileAccess.get_file_as_string(path + ".pre_modular") == original,"Backup da migracao e identico ao save original")
    instance.queue_free()
    await process_frame
    instance = GAME.new()
    instance.save_path = path
    instance.legacy_path = temp_dir.path_join("no_legacy.save")
    root.add_child(instance)
    instance.set_physics_process(false)
    await instance._change_area(true)
    check(instance.moveis.size() == 1 and instance.guardados.size() == 1,"Reinicio preserva colocados e guardados")
    instance.queue_free()
    await process_frame

func _test_bairro() -> void:
    const bairro = GAME.BAIRRO
    check(game.bairro.get_child_count() == 5,"Cena principal F5 inclui vizinhanca, PC Store e cafeteria")
    var vizinhanca = game.bairro.vizinhanca
    check(vizinhanca.fachadas.size() == 5 and vizinhanca.objetos.size() == 36,"Cinco lojas e 36 objetos no mapa principal")
    check(vizinhanca.CATALOGO.ITENS.size() == 50,"Catalogo preserva os 50 sprites do ZIP")
    for i in range(vizinhanca.fachadas.size()):
        var corpo: PackedVector2Array = vizinhanca.obstaculos[i]
        check(not game._walkable((corpo[0]+corpo[2])*0.5),"Novo predio bloqueia caminhada " + str(i))
        var entrada: Dictionary = vizinhanca.entradas[i]
        check(game._walkable(entrada.posicao),"Entrada comercial acessivel: " + entrada.nome)
        var old_position := game.pos_player
        game.pos_player = entrada.posicao
        game._interact()
        check(not game.indoors and game.info.text.contains(entrada.nome),"Loja informa interior indisponivel: " + entrada.nome)
        game.pos_player = old_position
        var grupo: Node2D = vizinhanca.fachadas[i]
        for parte: Sprite2D in grupo.get_children():
            check(parte.region_rect.end.x <= parte.texture.get_width(),"Recorte da fachada nao repete pixels fora do PNG")
    for objeto: Sprite2D in vizinhanca.objetos:
        check(not game._walkable(objeto.position),"Objeto urbano bloqueia os pes: " + objeto.name)
        check(objeto.z_index == int(objeto.position.y),"Objeto ordenado pela base: " + objeto.name)
        if objeto.name.begins_with("balizador"):
            check(absf(objeto.texture.get_image().get_used_rect().size.y*objeto.scale.y-52) < 0.1,"Balizador menor que personagem")
    check(bairro.TAMANHO == Vector2i(72,28),"Rua ampliada longitudinalmente para 72 x 28")
    check(bairro.RUA_FIM-bairro.RUA_INICIO == 8,"Duas pistas ocupam oito modulos de largura")
    check(absf(bairro.V.cross(bairro.U))/bairro.U.length()*4 >= 180,"Cada pista tem pelo menos 180 pixels de largura perpendicular")
    var height := game.player.texture.get_image().get_used_rect().size.y * game.player.scale.y
    var banco_altura := (632.0-535.0) * bairro.LOJA_ESCALA
    var porta_altura := (715.0-539.0) * bairro.LOJA_ESCALA
    check(height >= 108 and height <= 112.1,"Personagem com altura visivel proxima de 112 pixels")
    check(height / banco_altura >= 1.4 and height / banco_altura <= 1.8,"Personagem maior que encosto do banco na mesma escala")
    check(height / porta_altura >= 0.75 and height / porta_altura <= 0.9,"Personagem cabe na porta sem parecer minusculo")
    var npc_height := game.customer.texture.get_image().get_used_rect().size.y * game.customer.scale.y
    check(absf(npc_height-height) < 8,"NPC e protagonista com alturas coerentes")
    check(not game._walkable(bairro.local_loja(bairro.BANCO_LOCAL)),"Banco tem colisao independente")
    check(not game._walkable(bairro.local_loja(bairro.POSTE_LOCAL)),"Poste tem colisao independente")
    for obstaculo in bairro.OBSTACULOS:
        check(not game._walkable(bairro.local_loja(obstaculo.get_center())),"Vaso ou lixeira bloqueia passagem")
    check(game.player.z_index == int(game.pos_player.y),"Profundidade correta ja no primeiro frame")
    check(not game._walkable(bairro.CAFE_POS+(bairro.CAFE_FRENTE+bairro.CAFE_FUNDO)*0.5*bairro.CAFE_ESCALA),"Cafeteria bloqueia entrada pela fachada")
    var cafe_meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://Assets/Cenarios/Bairro/cafeteria.json"))
    var cafe_bottom: Array = cafe_meta["door_bottom"]
    var cafe_top: Array = cafe_meta["door_top"]
    var cafe_door_height: float = (float(cafe_bottom[1])-float(cafe_top[1]))*bairro.CAFE_ESCALA
    check(absf(cafe_door_height-porta_altura) < 3,"Portas da cafeteria e PC Store diferem menos de 3 pixels em altura")
    var meta_front: Array = cafe_meta["front_left"]
    check(bairro.CAFE_FRENTE.distance_to(Vector2(meta_front[0],meta_front[1])) < 0.01,"Pivo do jogo corresponde ao PNG preparado")
    check(absf((bairro.CAFE_CANTO-bairro.CAFE_FRENTE).normalized().cross(bairro.U.normalized())) < 0.001,"Fachada da cafeteria acompanha a rua reta")
    var reachable: Dictionary = {}
    var start: Vector2i = bairro.celula(game.pos_player)
    var pending: Array[Vector2i] = [start]
    reachable[start] = true
    while not pending.is_empty():
        var current: Vector2i = pending.pop_front()
        for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
            var next: Vector2i = current + delta
            if reachable.has(next) or next.x < 0 or next.y < 0 or next.x >= bairro.TAMANHO.x or next.y >= bairro.TAMANHO.y:
                continue
            var a: Vector2 = bairro.ponto(Vector2(current)+Vector2(0.5,0.5))
            var b: Vector2 = bairro.ponto(Vector2(next)+Vector2(0.5,0.5))
            var clear := true
            for step in range(9):
                if not game._walkable(a.lerp(b,step/8.0)):
                    clear = false
                    break
            if clear:
                reachable[next] = true
                pending.append(next)
    check(reachable.size() > 1100,"Mais de 1100 celulas conectadas acessiveis desde a loja")
    for entrada in vizinhanca.entradas:
        check(reachable.has(bairro.celula(entrada.posicao)),"Loja conectada a PC Store pela calcada: " + entrada.nome)
    for cell in [Vector2i(1,12),Vector2i(70,12),Vector2i(1,23),Vector2i(70,23)]:
        check(reachable.has(cell),"Calcada continua ate a extremidade: " + str(cell))
    for inicio in bairro.TRAVESSIAS:
        for v in range(bairro.RUA_INICIO,bairro.RUA_FIM+1):
            check(reachable.has(Vector2i(inicio+1,v)),"Travessia completa alcancavel %s/%s" % [inicio,v])
    for cell in [Vector2i(2,15),Vector2i(20,15),Vector2i(7,17),Vector2i(7,20),Vector2i(71,13)]:
        check(not game._walkable(bairro.ponto(Vector2(cell)+Vector2(0.5,0.5))),"Asfalto sem faixa bloqueado: " + str(cell))
    check(not game._walkable(bairro.ponto(Vector2(-1,5))),"Limite do mapa bloqueado")
    check(not game._walkable(bairro.ponto(Vector2(72.5,12))),"Extremidade distante do mapa bloqueada")
    var spawn := game.pos_player
    game.pos_player = bairro.local_loja(Vector2(170,710))
    check(game._walkable(game.pos_player),"Posicao de comparacao junto ao banco e caminhavel")
    game.player.position = game.pos_player
    game.player.atualizar(Vector2.ZERO,0)
    game.cam.position = game.pos_player
    game.cam.force_update_scroll()
    await _capture("08_personagem_banco")
    game.pos_player = bairro.ponto(Vector2(18,12))
    game.player.position = game.pos_player
    game.player.atualizar(Vector2.ZERO,0)
    game.cam.position = game.pos_player
    game.cam.force_update_scroll()
    await _capture("09_travessia_bairro")
    var rua_start := bairro.ponto(Vector2(20.5,12.5))
    game.pos_player = rua_start
    game.move = bairro.V.normalized()
    game._physics_process(4.0)
    check(not bairro.rua(bairro.celula(game.pos_player).y),"Movimento continuo nao atravessa asfalto bloqueado")
    game.pos_player = bairro.ponto(Vector2(18,12.5))
    game.move = bairro.V.normalized()
    game._physics_process(3.5)
    check(bairro.celula(game.pos_player).y >= bairro.RUA_FIM,"Movimento continuo atravessa as duas pistas pela faixa")
    game._stop_input()
    game.pos_player = bairro.porta_cafe()+Vector2(0,30)
    check(game._walkable(game.pos_player),"Calcada diante da porta da cafeteria acessivel")
    game._interact()
    check(not game.indoors and game.info.text.contains("Cafeteria"),"Cafeteria avisa que o interior ainda nao esta disponivel")
    game.player.position = game.pos_player
    game.player.atualizar(Vector2.ZERO,0)
    game.cam.position = game.pos_player+Vector2(0,-100)
    game.cam.force_update_scroll()
    await _capture("11_cafeteria")
    root.size = Vector2i(1280,720)
    root.content_scale_size = Vector2i(1280,720)
    game.cam.zoom = Vector2.ONE*0.55
    game.cam.position = bairro.ponto(Vector2(17,11))+Vector2(0,-160)
    game.cam.force_update_scroll()
    await _capture("10_rua_comercial")
    if DisplayServer.get_name() != "headless":
        await process_frame
        await RenderingServer.frame_post_draw
        var image := root.get_texture().get_image()
        for stripe in [0,3,6,9]:
            var v: float = bairro.RUA_INICIO+stripe*(bairro.RUA_FIM-bairro.RUA_INICIO)/12.0
            var white: Vector2i = Vector2i(game.get_canvas_transform()*bairro.ponto(Vector2(18,v+0.3)))
            var gap: Vector2i = Vector2i(game.get_canvas_transform()*bairro.ponto(Vector2(18,v+0.6)))
            check(image.get_pixelv(white).r > 0.8,"Faixa desenhada transversalmente ao fluxo de pedestres")
            check(image.get_pixelv(gap).r < 0.5,"Intervalo entre listras mostra asfalto, nao trilhos continuos")
    game.cam.zoom = Vector2.ONE*0.25
    game.cam.position = bairro.ponto(Vector2(35,12))+Vector2(0,-100)
    game.cam.force_update_scroll()
    await _capture("15_vizinhanca_integrada")
    root.size = Vector2i(432,768)
    root.content_scale_size = Vector2i(432,768)
    game._camera_exterior()
    game.pos_player = vizinhanca.entradas[0].posicao
    game.player.position = game.pos_player
    game.player.atualizar(Vector2.ZERO,0)
    game.cam.position = game.pos_player
    game.cam.force_update_scroll()
    game._interact()
    await _capture("16_mercadinho_jogavel")
    game.pos_player = spawn
    game.player.position = spawn
    game.player.atualizar(Vector2.ZERO,0)
    game.cam.position = spawn
    game.cam.force_update_scroll()
