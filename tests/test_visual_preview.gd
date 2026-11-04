extends SceneTree

const GAME = preload("res://scripts/RuaComercial.gd")
const VISUAL = preload("res://scripts/CatalogoPreviaVisual.gd")
var passed := 0
var failed := 0
var pasta := "user://test_visual_" + str(Time.get_ticks_usec())
var game: GAME

func _initialize() -> void:
    root.size = Vector2i(432,768)
    root.content_scale_size = Vector2i(432,768)
    root.gui_embed_subwindows = true
    call_deferred("_run")

func check(ok: bool, texto: String) -> void:
    if ok:
        passed += 1
        print("PASS: ",texto)
    else:
        failed += 1
        printerr("FAIL: ",texto)

func _capture(nome: String) -> void:
    var destino := OS.get_environment("PIXEL_TEST_CAPTURE_DIR")
    if destino.is_empty() or DisplayServer.get_name() == "headless":
        return
    await process_frame
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png(destino.path_join(nome+".png")) == OK,"Captura "+nome)

func _run() -> void:
    create_timer(90).timeout.connect(func() -> void: quit(1))
    check(DirAccess.make_dir_absolute(pasta) == OK,"Criar fixture visual isolada")
    game = GAME.new()
    game.save_path = pasta.path_join("save.json")
    game.legacy_path = pasta.path_join("legado.save")
    root.add_child(game)
    game.set_physics_process(false)
    await process_frame
    game.relogio.estado["segundos"] = 450.0
    game._atualizar_ambiente()
    game._refresh()
    check(game.bairro.previa_visual and game.mundo_vivo.previa_visual,"Amostras fornecidas sao o padrao autorizado")
    check(game.bairro.vizinhanca.fachadas[0].get_child(0).texture == VISUAL.MERCADO["textura"],"Fachada recebida aparece na inicializacao")
    check(game._alternar_previa_visual(),"Selecionar originais para comparar")
    game.popup.hide()
    check(game._save(),"Gravar estado de referencia")
    var bytes := FileAccess.get_file_as_bytes(game.save_path)
    var dinheiro := game.money
    var comercio := game.loja.estado.duplicate(true)
    var imoveis := game.gestor_imoveis.estados.duplicate(true)
    var obstaculos := game.bairro.vizinhanca.obstaculos.duplicate(true)
    var entradas := game.bairro.vizinhanca.entradas.duplicate(true)
    var originais: Array[Dictionary] = []
    for sprite in game.bairro.vizinhanca.objetos:
        originais.append({"textura":sprite.texture,"escala":sprite.scale,"posicao":sprite.position,"pivo":sprite.offset})
    for id in ["farmacia","loja_roupas","restaurante","predio_comercial"]:
        check(VISUAL.loja(id,true) == VISUAL.ORIGINAL.ITENS[id],"Sem substituir fachada fora da amostra: "+id)
    check(VISUAL.MERCADO["pivo"] == Vector2(319,486),"Soleira da fachada usa pivo do pacote, nao do prototipo")
    for id in VISUAL.CARROS:
        check(VISUAL.CARROS[id].get_size() == Vector2(512,320),"Vista importada: "+id)
    game.mundo_vivo.avancar(.1,450)
    check(not game.mundo_vivo.estado()["atores"].is_empty(),"Circulacao original disponivel para comparacao")
    game.pos_player = GAME.BAIRRO.ponto(Vector2(29,10))+Vector2(0,55)
    game.player.position = game.pos_player
    game.player.z_index = int(game.pos_player.y)
    game.cam.position = GAME.BAIRRO.ponto(Vector2(29,10))+Vector2(60,-100)
    game.cam.zoom = Vector2(.60,.60)
    game.cam.force_update_scroll()
    await _capture("visual_01_original")
    game._abrir_financas()
    var botao: Button
    for filho in game.shop_list.get_children():
        if filho is Button and filho.text.begins_with("Visual do bairro:"):
            botao = filho
    check(botao != null,"Comparacao acessivel no painel de Financas")
    if botao != null:
        botao.pressed.emit()
    game.popup.hide()
    check(game.bairro.previa_visual and game.mundo_vivo.previa_visual,"Botao ativa bairro e trafego juntos")
    check(game.bairro.vizinhanca.fachadas[0].get_child(0).texture == VISUAL.MERCADO["textura"],"Mercado novo conectado a fachada real")
    check(game.mundo_vivo.estado()["configurado"],"Circulacao recalculada para o footprint real do novo mercado")
    game.mundo_vivo.avancar(.1,450)
    var quantidade_carros := 0
    for ator in game.mundo_vivo._atores:
        if ator.trafego:
            quantidade_carros += 1
            check(ator.no.texture in VISUAL.CARROS.values() and ator.no.scale == Vector2.ONE*VISUAL.ESCALA_VEICULOS,"Trafego usa PNG fornecido e escala comum")
            check(ator.no.offset == Vector2(-256,-250),"Trafego usa pivo do pacote")
    check(quantidade_carros > 0,"Trafego retoma depois da comparacao")
    for sprite in game.bairro.vizinhanca.objetos:
        if str(sprite.get_meta("catalogo_id")).begins_with("compacto_"):
            check(sprite.scale == Vector2.ONE*VISUAL.ESCALA_VEICULOS,"Carro estacionado usa a mesma escala do trafego")
            check(sprite.offset == Vector2(-256,-250),"Carro estacionado usa pivo do pacote")
    check(game.bairro.vizinhanca.obstaculos[0] != obstaculos[0] and game.bairro.vizinhanca.obstaculos.slice(1) == obstaculos.slice(1),"Somente colisao do mercado acompanha a nova fachada")
    var base := PackedVector2Array()
    var mercado: Dictionary = VISUAL.MERCADO
    for at in [mercado.frente,mercado.canto,mercado.fundo,mercado.frente+mercado.fundo-mercado.canto]:
        base.append(GAME.BAIRRO.ponto(Vector2(29,10))-mercado.pivo+at)
    check(base == game.bairro.vizinhanca.obstaculos[0],"Colisao coincide com os tres marcos fornecidos")
    check(game.bairro.vizinhanca.entradas == entradas,"Acessos comerciais preservados")
    check(game.money == dinheiro and game.loja.estado == comercio and game.gestor_imoveis.estados == imoveis,"Comparacao nao muda caixa, estoque ou propriedades")
    check(FileAccess.get_file_as_bytes(game.save_path) == bytes,"Previa nao reescreve saves")
    await _capture("visual_02_previa")
    game.cam.position = GAME.BAIRRO.ponto(Vector2(51,19))+Vector2(0,-100)
    game.cam.zoom = Vector2(.80,.80)
    game.cam.force_update_scroll()
    await _capture("visual_03_picape")
    game.transitioning = true
    check(not game._alternar_previa_visual() and game.bairro.previa_visual,"Troca bloqueada durante transicao")
    game.transitioning = false
    check(game._alternar_previa_visual(),"Restaurar visual original")
    game.popup.hide()
    for i in range(originais.size()):
        var sprite: Sprite2D = game.bairro.vizinhanca.objetos[i]
        var antes: Dictionary = originais[i]
        check(sprite.texture == antes.textura and sprite.scale == antes.escala and sprite.offset == antes.pivo and sprite.position == antes.posicao,"Objeto original restaurado: "+str(i))
    check(game.bairro.vizinhanca.obstaculos == obstaculos,"Colisao original restaurada junto com a arte")
    game.mundo_vivo.avancar(.1,450)
    for ator in game.mundo_vivo._atores:
        if ator.trafego:
            check(ator.no.texture not in VISUAL.CARROS.values() and ator.no.scale == Vector2(.65,.65),"Trafego original restaurado")
    for i in range(5):
        check(game._alternar_previa_visual() and game._alternar_previa_visual(),"Comparacao repetida sem acumular fachadas")
        await process_frame
    check(game.bairro.vizinhanca.fachadas.size() == 5 and game.bairro.vizinhanca.get_child_count() == originais.size()+5,"Sem nos de fachada duplicados")
    game.queue_free()
    await process_frame
    for nome in DirAccess.get_files_at(pasta):
        check(DirAccess.remove_absolute(pasta.path_join(nome)) == OK,"Limpar "+nome)
    check(DirAccess.remove_absolute(pasta) == OK,"Limpar fixture visual")
    print("RESULT: %d passed, %d failed" % [passed,failed])
    quit(1 if failed else 0)
