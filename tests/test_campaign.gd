extends SceneTree

const GAME = preload("res://scripts/RuaComercial.gd")
const BASE := ["caixa_ninho","placa_aurora","cpu_aurora","ram_brisa","fonte_clara","ssd_trilha","gpu_pixel","cooler_neve"]
var passed := 0
var failed := 0
var pasta := "user://test_campanha_" + str(Time.get_ticks_usec())
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

func _novo(nome: String) -> GAME:
    var instance := GAME.new()
    instance.save_path = pasta.path_join(nome + ".json")
    instance.legacy_path = pasta.path_join("sem_legado.save")
    root.add_child(instance)
    instance.set_physics_process(false)
    return instance

func _capture(nome: String) -> void:
    var destino := OS.get_environment("PIXEL_TEST_CAPTURE_DIR")
    if destino.is_empty() or DisplayServer.get_name() == "headless":
        return
    await process_frame
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png(destino.path_join(nome + ".png")) == OK,"Captura " + nome)

func _run() -> void:
    create_timer(180).timeout.connect(func() -> void:
        printerr("FAIL: Campanha excedeu 180 segundos.")
        quit(1))
    check(DirAccess.make_dir_absolute(pasta) == OK,"Criar fixtures isoladas")
    _campanha_sete_dias()
    _recorrencia()
    _oficina()
    _protecao_modelos()
    _montador()
    await _integracao()
    await _camera_porta()
    for nome in DirAccess.get_files_at(pasta):
        check(DirAccess.remove_absolute(pasta.path_join(nome)) == OK,"Limpar " + nome)
    check(DirAccess.remove_absolute(pasta) == OK,"Limpar pasta")
    print("RESULT: %d passed, %d failed" % [passed,failed])
    quit(1 if failed else 0)

func _campanha_sete_dias() -> void:
    var loja := GAME.COMERCIO.new()
    var equipe := GAME.EQUIPE.new()
    var clock := GAME.CALENDARIO.new()
    var clientes := GAME.CLIENTES.new()
    var saldo := 6500
    for id in ["lia","rui","sol"]:
        check(equipe.contratar(id),"Contratar equipe-base na campanha")
    var meta := GAME.CAMPANHA.meta_diaria(170)
    check(meta["margem_pc"] == 670 and meta["equilibrio"] == 1 and meta["lucro_meta"] == 1050,"Preco, CMV e folha permitem campanha sustentavel sem alterar historico")
    for dia in range(1,8):
        for pedido in range(2):
            for id in BASE:
                saldo += loja.comprar(id,saldo)
                check(loja.ultimo_erro.is_empty() and saldo >= 0,"Campanha compra com caixa real: " + id)
            loja.avancar(30)
            saldo = clock.avancar(30,saldo,loja.resumo(),equipe)
            for entrega: Dictionary in loja.estado["pedidos"]:
                if not entrega["recebido"]:
                    check(loja.receber(int(entrega["id"])),"Receber compra sem estoque injetado")
            check(loja.criar_cliente("",true),"Pedido de PC na campanha")
            clientes.vincular_manual("",true,2450)
            for i in range(BASE.size()):
                check(loja.instalar(BASE[i],GAME.PECAS.CATEGORIAS[i]),"Instalar peca comprada na campanha")
            check(loja.conectar() and loja.testar(),"PC da campanha passa pelo teste real")
            loja.estado["cliente"]["fase"] = "aguardando"
            var receita := loja.vender()
            saldo += receita
            clientes.finalizar(clientes.estado["atual"],dia,"compra","",receita,int(loja.estado["montagem"]["id"]))
            loja.estado["cliente"] = {}
            loja.estado["campanha"]["nivel"] = GAME.CAMPANHA.nivel(loja.estado,int(clientes.estado["reputacao"]))
        saldo = clock.avancar(840,saldo,loja.resumo(),equipe)
        check(saldo == 6500 + dia * 1050 and clock.divida() == 0,"Dia %d fecha com lucro 1050 e sem dividas" % dia)
        check(GAME.COMERCIO.validar(loja.estado) and GAME.CALENDARIO.validar(clock.estado),"Campanha permanece salvavel no dia %d" % dia)
    check(saldo == 13850 and loja.estado["pcs"].size() == 14,"Sete dias, quatorze PCs, caixa 13850 sem renda/estoque artificiais")
    check(loja.estado["campanha"]["nivel"] == 3,"Campanha desbloqueia tecnologia por vendas e satisfacao reais")
    var legado := loja.estado.duplicate(true)
    legado.erase("campanha")
    check(loja.carregar(legado) and "cpu_aurora" in loja.estado["campanha"]["pecas_legadas"],"Migrar preserva acesso a aquisicoes antigas")

func _recorrencia() -> void:
    var clientes := GAME.CLIENTES.new()
    var id := clientes.adicionar("ram",200,180)
    clientes.ativar(id)
    clientes.finalizar(id,1,"compra","ram_brisa",180)
    var retorno := int(clientes.estado["perfis"][id]["retorno"])
    check(clientes.estado["reputacao"] == 52 and clientes.retornar(retorno-1).is_empty(),"Satisfacao aumenta reputacao e retorno respeita calendario")
    check(clientes.retornar(retorno) == id and clientes.retornar(retorno).is_empty(),"Cliente retorna com a mesma identidade uma unica vez")
    clientes.ativar(id)
    clientes.finalizar(id,retorno,"compra","ram_brisa",180)
    check(clientes.estado["perfis"][id]["visitas"] == 2 and clientes.estado["perfis"][id]["fidelidade"] == 10,"Visitas e fidelidade acumulam no perfil original")
    var demanda := clientes.demanda()
    clientes.finalizar(id,retorno,"desistencia")
    check(clientes.demanda() < demanda and GAME.CLIENTES.validar(clientes.estado),"Desistencia reduz satisfacao e chegadas sem invalidar save")
    var invalido := clientes.estado.duplicate(true)
    invalido["reputacao"] = 101
    check(not GAME.CLIENTES.validar(invalido),"Reputacao fora da faixa rejeitada")
    invalido = clientes.estado.duplicate(true)
    invalido["perfis"][id]["jogo"] = "jogo_inexistente"
    check(not GAME.CLIENTES.validar(invalido),"Pedido recorrente com jogo desconhecido rejeitado")
    invalido["perfis"][id].erase("jogo")
    invalido["perfis"][id]["servico"] = "servico_inexistente"
    check(not GAME.CLIENTES.validar(invalido),"Servico recorrente desconhecido rejeitado")

func _oficina() -> void:
    var loja := GAME.COMERCIO.new()
    loja.estado["estoque"] = {"kit_limpeza":4}
    var ids: Array[int] = []
    for i in range(4):
        check(loja.abrir_os("limpeza"),"Receber OS %d" % i)
        loja.estado["cliente"]["fase"] = "aguardando"
        check(loja.diagnosticar_os() and loja.aprovar_os(),"Diagnosticar e autorizar OS")
        ids.append(int(loja.estado["servico"]["id"]))
        check(loja.estacionar_os(),"Reservar e guardar PC da OS")
    check(loja.total_os() == 4 and loja.quantidade("kit_limpeza") == 0,"Quatro PCs guardados com reservas separadas fora do estoque")
    check(not loja.abrir_os("diagnostico"),"Quinta OS recusada sem perder as quatro existentes")
    check(not loja.criar_cliente("",true),"Montagem tambem respeita o limite total de quatro PCs")
    check(loja.priorizar_os(ids[2],0) and loja.proxima_os() == ids[2],"Urgencia antecede ordem de chegada")
    var serializado: Dictionary = JSON.parse_string(JSON.stringify(loja.estado))
    check(loja.carregar(serializado),"Reservas sobrevivem a JSON sem conflito int/float")
    check(loja.retomar_os(ids[2]) and loja.executar_os() and loja.testar_os(),"Retomar consome a reserva, mesmo com estoque vendavel zero")
    check(loja.vender() == 90 and loja.vender() == 0,"Pagamento unico por OS, inclusive apos retomada")
    check(loja.estado["ordens_servico"][0]["custo"] == 20,"CMV registra uma unica unidade reservada")
    loja.estado["cliente"] = {}
    check(loja.retomar_os(ids[0]) and loja.cancelar_os(),"Cancelar OS reservada antes de executar")
    check(loja.quantidade("kit_limpeza") == 1 and not loja.cancelar_os(),"Cancelamento devolve reserva uma unica vez")
    check(GAME.COMERCIO.validar(loja.estado),"Oficina parcial com historico e reservas valida")

func _protecao_modelos() -> void:
    var loja := GAME.COMERCIO.new()
    loja.abrir_os("manutencao")
    loja.estado["cliente"]["fase"] = "aguardando"
    loja.diagnosticar_os()
    loja.aprovar_os()
    loja.estado["estoque"]["kit_limpeza"] = 1
    var anterior := loja.estado.duplicate(true)
    check(not loja.estacionar_os() and loja.estado == anterior,"Reserva sem todos os insumos nao retira estoque parcialmente")
    var legado := GAME.COMERCIO.inicial()
    legado.erase("campanha")
    legado["estoque"]["cpu_nova"] = 1
    check(loja.carregar(legado) and GAME.CAMPANHA.peca_liberada("cpu_nova",loja.estado["campanha"],1),"Migracao preserva peca avancada adquirida sem desbloquear tudo")
    check(not GAME.CAMPANHA.peca_liberada("gpu_trovao",loja.estado["campanha"],1),"Migracao nao libera peca avancada nunca adquirida")
    loja.estado["campanha"]["nivel"] = 3
    check(GAME.CAMPANHA.nivel(loja.estado,0) == 3,"Reputacao baixa nao remove tecnologia ja desbloqueada")
    var invalido := loja.estado.duplicate(true)
    invalido["campanha"]["nivel"] = 1.5
    check(not GAME.COMERCIO.validar(invalido),"Nivel fracionario de campanha rejeitado")

func _montador() -> void:
    for jogo in GAME.JOGOS.JOGOS:
        var loja := GAME.COMERCIO.new()
        for id in GAME.PECAS.PECAS:
            loja.estado["estoque"][id] = 2
        loja.criar_cliente("",true,jogo)
        var plano := loja.plano_automatico()
        check(plano.size() == 8,"Montador encontra configuracao de estoque para " + jogo)
        if plano.size() != 8:
            continue
        for categoria in GAME.PECAS.CATEGORIAS:
            check(loja.instalar(plano[categoria],categoria),"Automacao usa instalacao normal: " + categoria)
        check(loja.conectar() and loja.testar(),"Configuracao automatica atende orcamento, temperatura e estabilidade: " + jogo)

func _chegar() -> void:
    for i in range(300):
        if game.loja.estado["cliente"].is_empty() or game.loja.estado["cliente"]["fase"] == "aguardando":
            return
        game._cliente_comercial(0.25)

func _posto(tipo: String) -> void:
    game.pos_player = game._navegacao().caminho_ate(game._estacao(tipo).position,85)[-1]

func _integracao() -> void:
    game = _novo("integracao")
    await game._change_area(true)
    _posto("notebook")
    check(not game._operacao_comercial("comprar","cpu_nova"),"Compra bloqueada no controlador, nao apenas no botao")
    check(not game._alterar_equipe("contratar","nina",""),"Especialista indisponivel antes do nivel 2")
    game.loja.estado["estoque"] = {"kit_limpeza":4}
    for i in range(4):
        _posto("balcao")
        check(game._operacao_comercial("abrir_os","limpeza"),"Recepcao integrada de OS")
        _chegar()
        _posto("bancada")
        check(game._operacao_comercial("diagnosticar_os"),"Diagnostico integrado")
        _posto("balcao")
        check(game._operacao_comercial("aprovar_os"),"Autorizar OS integrada")
        if i == 0:
            var caminho := game.save_path
            var comercio := game.loja.estado.duplicate(true)
            var perfis := game.clientes.estado.duplicate(true)
            game.save_path = pasta
            var imprimir := Engine.print_error_messages
            Engine.print_error_messages = false
            var resultado := game._operacao_comercial("guardar_os")
            Engine.print_error_messages = imprimir
            check(not resultado and game.loja.estado == comercio and game.clientes.estado == perfis,"Falha de save desfaz reservas e preserva dono/atendimento")
            game.save_path = caminho
        check(game._operacao_comercial("guardar_os"),"Reserva integrada ao perfil correto")
    check(game.clientes.estado["atual"].is_empty() and game.loja.total_os() == 4,"Balcao livre com quatro PCs aguardando")
    game._abrir_servicos()
    await _capture("01_oficina_quatro_pcs")
    game.popup.hide()
    var numero := game.loja.proxima_os()
    _posto("balcao")
    check(game._operacao_comercial("priorizar_os",str(numero),"0"),"Prioridade acessivel pelo controlador")
    _posto("bancada")
    check(game._operacao_comercial("retomar_os",str(numero)),"Retomada restaura cliente e ordem")
    check(not game.clientes.estado["atual"].is_empty(),"Perfil do dono do PC restaurado")
    check(game._operacao_comercial("cancelar_os"),"Cancelar devolve peca e registra satisfacao")
    for i in range(300):
        if game.loja.estado["cliente"].is_empty():
            break
        game._cliente_comercial(0.25)
    check(game._alterar_equipe("contratar","rui",""),"Tecnico contratado para fila pendente")
    game.popup.hide()
    var saldo := game.money
    for i in range(30):
        game._avancar_simulacao(10)
        game._processar_funcionarios(10)
        game._cliente_comercial(0.25)
        if game.loja.estado["servico"].get("fase") == "pronto":
            break
    check(game.loja.estado["servico"].get("fase") == "pronto","Tecnico retoma a proxima OS e usa suas reservas automaticamente")
    _posto("balcao")
    check(game._operacao_comercial("vender") and game.money == saldo + 90,"OS automatizada recebe somente na entrega")
    check(game._save(),"Persistir fila com perfis e reservas")
    game.queue_free()
    await process_frame
    game = _novo("integracao")
    check(game.loja.total_os() == 2 and game.loja.estado["ordens_servico"].size() == 1,"Reabrir preserva PCs pendentes e pagamento anterior")
    for campo in ["perfil","reserva","prioridade","nivel"]:
        check(game._save(),"Preparar backup valido para corrupcao de " + campo)
        var caminho := game.save_path
        var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(caminho))
        var ordem: Dictionary = dados["comercio"]["fila_os"][0]["os"]
        match campo:
            "perfil": ordem["perfil"] = "cliente_inexistente"
            "reserva": ordem["reservas"]["kit_limpeza"] = 2
            "prioridade": ordem["prioridade"] = 4
            "nivel": dados["comercio"]["campanha"]["nivel"] = 1.5
        game.queue_free()
        await process_frame
        var arquivo := FileAccess.open(caminho,FileAccess.WRITE)
        check(arquivo != null,"Abrir fixture de corrupcao de " + campo)
        if arquivo == null:
            return
        arquivo.store_string(JSON.stringify(dados))
        arquivo.close()
        game = _novo("integracao")
        check(not game.save_bloqueado and game.loja.total_os() == 2 and float(game.loja.estado["fila_os"][0]["os"]["prioridade"]) in [0.0,1.0,2.0],"Corrupcao de %s recupera backup e preserva oficina" % campo)
    game.queue_free()
    await process_frame
    game = _novo("montador")
    await game._change_area(true)
    _posto("notebook")
    game.loja.estado["campanha"]["nivel"] = 3
    check(game._operacao_comercial("fornecedor","especialista") and game._operacao_comercial("comprar","cpu_nova"),"Nivel e fornecedor corretos liberam compra avancada")
    check(game.loja.estado["pedidos"][-1]["restante"] == 20.0,"Fornecedor especialista aplica entrega de vinte segundos")
    check(game._alterar_equipe("contratar","nina",""),"Especialista contratado apos desbloqueio")
    check(game._alterar_equipe("demitir","nina",""),"Demissao libera funcao sem apagar experiencia")
    for id in BASE:
        game.loja.estado["estoque"][id] = 1
    check(game._alterar_equipe("contratar","rui","") and game._alterar_equipe("atribuir","rui","montador"),"Funcao montador disponivel por reatribuicao")
    game.popup.hide()
    _posto("balcao")
    check(game._operacao_comercial("pedido_pc"),"Pedido de PC para automacao")
    for i in range(12):
        game._avancar_simulacao(10)
        game._processar_funcionarios(10)
    check(game.loja.estado["montagem"]["fase"] == "testado" and game.loja.custo_pc() == 1780,"Funcionario instala oito pecas, conecta e testa com as regras manuais")
    _posto("bancada")
    game._abrir_montagem()
    await _capture("02_pc_montado_por_funcionario")
    game.popup.hide()
    game._abrir_financas()
    await _capture("03_campanha_e_equilibrio")
    game.queue_free()
    await process_frame

func _touch(indice: int, ponto: Vector2, pressionado: bool) -> void:
    var evento := InputEventScreenTouch.new()
    evento.index = indice
    evento.position = ponto
    evento.pressed = pressionado
    root.push_input(evento,true)

func _camera_porta() -> void:
    game = _novo("porta")
    await game._change_area(true)
    var impossivel := game.clientes.adicionar("ram",1,180)
    game.clientes.estado["perfis"][impossivel]["preferencia"] = "pc"
    game.loja.estado["estoque"]["ram_brisa"] = 1
    var comprador := game.clientes.adicionar("ram",200,180)
    game._atender_fila()
    check(game.clientes.estado["atual"] == comprador and impossivel in game.clientes.estado["fila"],"Pedido sem orcamento nao bloqueia comprador elegivel atras dele")
    _chegar()
    _posto("balcao")
    check(game._operacao_comercial("vender"),"Venda real agenda retorno do perfil atendido")
    check(game._avancar_simulacao((int(game.clientes.estado["perfis"][comprador]["retorno"]) - int(game.relogio.estado["dia"])) * 900.0),"Avancar dias pelo fechamento real ate a proxima visita")
    game._processar_fila(30)
    check(comprador in game.clientes.estado["fila"] and game.clientes.estado["perfis"].size() == 2,"Calendario/controlador geram nova visita sem duplicar identidade")
    game.clientes.estado = GAME.CLIENTES.inicial()
    game.loja.estado = GAME.COMERCIO.inicial()
    game._preparar_cliente()
    _posto("balcao")
    check(not game._operacao_comercial("guardar_os") and game.loja.estado["servico"].is_empty(),"Guardar sem OS informa erro sem criar ordem invalida")
    game.popup.hide()
    var zoom := game.cam.zoom
    _touch(7,Vector2(250,170),true)
    _touch(8,Vector2(300,170),true)
    var evento := InputEventScreenDrag.new()
    evento.index = 8
    evento.position = Vector2(350,170)
    root.push_input(evento,true)
    check(game.cam.zoom.x > zoom.x and game.gestos.livre,"Pinca real roteada pelo viewport amplia a camera")
    _touch(7,Vector2(250,170),false)
    _touch(8,Vector2(350,170),false)
    game._recentralizar_camera()
    check(game.cam.zoom == zoom and not game.gestos.livre and game.gestos.toques.is_empty(),"Recentralizar restaura enquadramento e limpa dedos")
    var posicao := game.cam.position
    _touch(10,Vector2(280,170),true)
    evento.index = 10
    evento.position = Vector2(310,180)
    root.push_input(evento,true)
    check(game.cam.position != posicao,"Arraste real move a camera sem mover o personagem")
    _touch(10,Vector2(310,180),false)
    game.gestos.ampliar(1000,Vector2(216,384),Vector2(216,384))
    check(is_equal_approx(game.cam.zoom.x,zoom.x*4),"Zoom maximo e quatro vezes o enquadramento base")
    game.gestos.ampliar(0.0001,Vector2(216,384),Vector2(216,384))
    check(is_equal_approx(game.cam.zoom.x,zoom.x*0.75),"Zoom minimo preserva limite configurado")
    game._stop_input()
    check(game.gestos.toques.is_empty(),"Perda de input limpa todos os dedos")
    game._recentralizar_camera()
    _touch(9,game.pad_center + Vector2(30,0),true)
    check(game.finger == 9 and not game.gestos.toques.has(9),"Gestos nao roubam o dedo do D-pad")
    _touch(9,game.pad_center,false)
    game._buy("porta_interna")
    var porta := game.selecionado
    var achou := false
    for u in range(1,6):
        for v in range(1,5):
            porta.position = GAME.INTERIOR.ponto(Vector2(u,v),game.cadastro["origem"])
            if game._can_place(porta):
                achou = true
                break
        if achou:
            break
    check(achou,"Porta encontra posicao que preserva rotas")
    game._edit_action("OK")
    check(game.selecionado == null and not game._walkable(porta.position),"Porta fechada confirmada bloqueia passagem")
    game.selecionado = porta
    check(game._alternar_porta() and game._walkable(porta.position),"Abrir porta libera colisao e navegacao")
    porta.iniciar_edicao()
    check(porta.visual.visible,"Edicao mostra painel fantasma da porta aberta")
    porta.confirmar()
    check(not porta.visual.visible and porta.porta_aberta,"Confirmacao retira fantasma sem fechar passagem")
    var caminho := game.save_path
    var posicao_player := game.pos_player
    game.save_path = pasta
    game.selecionado = porta
    var imprimir := Engine.print_error_messages
    Engine.print_error_messages = false
    var resultado := game._alternar_porta()
    Engine.print_error_messages = imprimir
    check(not resultado and porta.porta_aberta,"Falha de save restaura porta aberta")
    game.save_path = caminho
    game.pos_player = posicao_player
    game.pos_player = porta.position
    game.selecionado = porta
    check(not game._alternar_porta() and porta.porta_aberta,"Porta nao fecha sobre o personagem")
    game.selecionado = null
    await _capture("04_porta_aberta")
    check(game._save(),"Salvar porta aberta")
    game.queue_free()
    await process_frame
    game = _novo("porta")
    await game._change_area(true)
    check(game.moveis[-1].item_id == "porta_interna" and game.moveis[-1].porta_aberta and game._walkable(game.moveis[-1].position),"Reabrir restaura estado aberto e colisao correta")
    game.queue_free()
    await process_frame
