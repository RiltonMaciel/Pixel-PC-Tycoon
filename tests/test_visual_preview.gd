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
    check(not game.bairro.previa_visual and not game.mundo_vivo.previa_visual,"Originais sao o padrao ate aprovacao")
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
    var original: Dictionary = VISUAL.ORIGINAL.ITENS["mercadinho"]
    for marco in ["frente","canto","fundo"]:
        check((VISUAL.MERCADO[marco]-VISUAL.MERCADO["pivo"]).is_equal_approx(original[marco]-original["pivo"]),"Footprint mundial identico: "+marco)
    for id in VISUAL.CARROS:
        check(VISUAL.CARROS[id].get_size() == Vector2(512,320),"Vista importada: "+id)
    game.mundo_vivo.avancar(.1,450)
    var trafego: Array[Dictionary] = []
    for ator in game.mundo_vivo._atores:
        if ator.trafego:
            trafego.append({"no":ator.no,"textura":ator.no.texture,"posicao":ator.no.position})
    check(not trafego.is_empty(),"Trafego real disponivel para comparacao")
    game.cam.position = GAME.BAIRRO.ponto(Vector2(29,10))+Vector2(60,-100)
    game.cam.zoom = Vector2(.60,.60)
    game.cam.force_update_scroll()
    await _capture("visual_01_original")
    game._abrir_financas()
    var botao: Button
    for filho in game.shop_list.get_children():
        if filho is Button and filho.text.begins_with("Previa visual do bairro:"):
            botao = filho
    check(botao != null,"Comparacao acessivel no painel de Financas")
    if botao != null:
        botao.pressed.emit()
    game.popup.hide()
    check(game.bairro.previa_visual and game.mundo_vivo.previa_visual,"Botao ativa bairro e trafego juntos")
    check(game.bairro.vizinhanca.fachadas[0].get_child(0).texture == VISUAL.MERCADO["textura"],"Mercado novo conectado a fachada real")
    for ator in trafego:
        check(ator.no.texture != ator.textura and ator.no.scale == Vector2.ONE,"Troca veiculos ativos sem reiniciar trafego e com escala comum")
        check(ator.no.position == ator.posicao,"Comparacao preserva a posicao do veiculo")
    for sprite in game.bairro.vizinhanca.objetos:
        if str(sprite.get_meta("catalogo_id")).begins_with("compacto_"):
            check(sprite.scale == Vector2.ONE,"Carro estacionado usa a mesma escala do trafego")
    check(game.bairro.vizinhanca.obstaculos == obstaculos and game.bairro.vizinhanca.entradas == entradas,"Comparacao nao muda colisao nem entradas")
    check(game.money == dinheiro and game.loja.estado == comercio and game.gestor_imoveis.estados == imoveis,"Comparacao nao muda caixa, estoque ou propriedades")
    check(FileAccess.get_file_as_bytes(game.save_path) == bytes,"Previa nao reescreve saves")
    await _capture("visual_02_previa")
    game.transitioning = true
    check(not game._alternar_previa_visual() and game.bairro.previa_visual,"Troca bloqueada durante transicao")
    game.transitioning = false
    check(game._alternar_previa_visual(),"Restaurar visual original")
    game.popup.hide()
    for i in range(originais.size()):
        var sprite: Sprite2D = game.bairro.vizinhanca.objetos[i]
        var antes: Dictionary = originais[i]
        check(sprite.texture == antes.textura and sprite.scale == antes.escala and sprite.offset == antes.pivo and sprite.position == antes.posicao,"Objeto original restaurado: "+str(i))
    for ator in trafego:
        check(ator.no.texture == ator.textura and ator.no.scale == Vector2(.65,.65),"Trafego original restaurado")
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
