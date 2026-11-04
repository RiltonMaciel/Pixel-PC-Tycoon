extends SceneTree

const GAME = preload("res://scripts/RuaComercial.gd")
const BASE := ["caixa_ninho","placa_aurora","cpu_aurora","ram_brisa","fonte_clara","ssd_trilha","gpu_pixel","cooler_neve"]
var passed := 0
var failed := 0
var pasta := "user://test_evolucao_" + str(Time.get_ticks_usec())
var game: GAME
var campanha: Dictionary = {}

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

func _novo() -> GAME:
    var instance := GAME.new()
    instance.save_path = pasta.path_join("save.json")
    instance.legacy_path = pasta.path_join("sem_legado.save")
    root.add_child(instance)
    instance.set_physics_process(false)
    return instance

func _posto(tipo: String) -> void:
    game.pos_player = game._navegacao().caminho_ate(game._estacao(tipo).position,85)[-1]

func _aguardar(fase: String) -> void:
    for i in range(300):
        if game.loja.estado["cliente"].is_empty() or game.loja.estado["cliente"]["fase"] == fase:
            return
        game._cliente_comercial(0.25)

func _capture(nome: String) -> void:
    var destino := OS.get_environment("PIXEL_TEST_CAPTURE_DIR")
    if destino.is_empty() or DisplayServer.get_name() == "headless":
        return
    await process_frame
    await RenderingServer.frame_post_draw
    check(root.get_texture().get_image().save_png(destino.path_join(nome+".png")) == OK,"Captura " + nome)

func _run() -> void:
    create_timer(180).timeout.connect(func() -> void: quit(1))
    check(DirAccess.make_dir_absolute(pasta) == OK,"Criar fixtures isoladas")
    _assistencia()
    _campanha_longa()
    _validadores()
    await _integracao()
    for nome in DirAccess.get_files_at(pasta):
        check(DirAccess.remove_absolute(pasta.path_join(nome)) == OK,"Limpar " + nome)
    check(DirAccess.remove_absolute(pasta) == OK,"Limpar fixtures")
    print("RESULT: %d passed, %d failed" % [passed,failed])
    quit(1 if failed else 0)

func _assistencia() -> void:
    for caso in GAME.COMERCIO.SERVICOS.CASOS:
        var loja := GAME.COMERCIO.new()
        check(loja.abrir_os("reparo",caso),"Receber defeito investigativo " + caso)
        check(loja.SERVICOS.nome(loja.estado["servico"]) == loja.SERVICOS.CASOS[caso]["nome"],"Nome da OS descreve o defeito real")
        loja.estado["cliente"]["fase"] = "aguardando"
        check(not loja.diagnosticar_os(),"Diagnostico exige evidencias")
        for ensaio in loja.SERVICOS.ENSAIOS:
            check(loja.investigar_os(ensaio),"Ensaio " + ensaio)
        check(loja.diagnosticar_os() and loja.aprovar_os(),"Evidencias liberam orcamento")
        var antes := loja.estado.duplicate(true)
        check(not loja.executar_os() and loja.estado == antes,"Sem peca o reparo nao muda PC nem custo")
        for id in loja.SERVICOS.necessarios(loja.estado["servico"]):
            loja.estado["estoque"][id] = 1
        check(loja.estacionar_os(),"Reserva de reparo especifica por defeito")
        var numero := loja.proxima_os()
        var dados: Dictionary = JSON.parse_string(JSON.stringify(loja.estado))
        check(loja.carregar(dados) and loja.retomar_os(numero),"Defeito e evidencias sobrevivem a JSON")
        check(loja.executar_os() and loja.testar_os(),"Reparo corrige medidas simuladas")
        check(loja.estado["servico"]["devolvidos"].size() == 1,"Peca removida permanece com o cliente")
        var preco: int = loja.SERVICOS.CASOS[caso]["preco"]
        check(loja.vender() == preco and loja.vender() == 0,"Receita unica do reparo")
        check(GAME.COMERCIO.validar(loja.estado),"Reparo entregue permanece valido")
        var invalido := loja.estado.duplicate(true)
        invalido["servico"]["ensaios"] = ["desconhecido"]
        check(not GAME.COMERCIO.validar(invalido),"Ensaio corrompido rejeitado")

func _campanha_longa() -> void:
    var loja := GAME.COMERCIO.new()
    var calendario := GAME.CALENDARIO.new()
    var equipe := GAME.EQUIPE.new()
    var clientes := GAME.CLIENTES.new()
    var objetivos := GAME.EVOLUCAO.OBJETIVOS.new()
    var saldo := 6500
    for id in ["lia","rui","sol"]:
        equipe.contratar(id)
    for dia in range(1,57):
        if dia == 8:
            check(equipe.contratar("nina"),"Campanha contrata montadora apos primeira semana")
        if dia == 28:
            check(equipe.demitir("rui") and equipe.contratar("ivo"),"Campanha substitui tecnico por especialista sem funcao duplicada")
        for pc in range(2):
            for id in BASE:
                saldo += loja.comprar(id,saldo)
            check(saldo >= 0 and loja.ultimo_erro.is_empty(),"Dia %d compra com capital real" % dia)
            loja.avancar(30)
            saldo = calendario.avancar(30,saldo,loja.resumo(),equipe)
            for pedido: Dictionary in loja.estado["pedidos"]:
                if not pedido["recebido"]:
                    loja.receber(int(pedido["id"]))
            loja.criar_cliente("",true)
            clientes.vincular_manual("",true,2450)
            for i in range(BASE.size()):
                loja.instalar(BASE[i],GAME.PECAS.CATEGORIAS[i])
            check(loja.conectar() and loja.testar(),"Dia %d PC passa em teste completo" % dia)
            loja.estado["cliente"]["fase"] = "aguardando"
            var receita := loja.vender()
            saldo += receita
            clientes.finalizar(clientes.estado["atual"],dia,"compra","",receita,int(loja.estado["montagem"]["id"]))
            loja.estado["cliente"] = {}
        saldo = calendario.avancar(840,saldo,loja.resumo(),equipe)
        loja.estado["campanha"]["nivel"] = GAME.CAMPANHA.nivel(loja.estado,int(clientes.estado["reputacao"]))
        objetivos.atualizar(loja.estado,clientes.estado,equipe.estado,dia)
        check(GAME.COMERCIO.validar(loja.estado) and GAME.CALENDARIO.validar(calendario.estado) and GAME.CLIENTES.validar(clientes.estado) and GAME.EQUIPE.validar(equipe.estado),"Dia %d fecha com estados validos" % dia)
        check(calendario.divida() == 0 and saldo > 6500,"Dia %d paga contas sem renda artificial" % dia)
    check(loja.estado["pcs"].size() == 112 and calendario.estado["dia"] == 57,"Oito semanas completas, 112 PCs, sem duplicacao")
    check(objetivos.concluido("primeiro_pc") and objetivos.concluido("emprego"),"Objetivos usam progresso real da campanha longa")
    campanha = {"saldo":saldo,"comercio":loja.estado.duplicate(true),"calendario":calendario.estado.duplicate(true),"clientes":clientes.estado.duplicate(true),"equipe":equipe.estado.duplicate(true)}
    var divida := GAME.CALENDARIO.new()
    var caixa := 0
    var sem_vendas := GAME.COMERCIO.new()
    for i in range(56):
        caixa = divida.avancar(900,caixa,sem_vendas.resumo(),GAME.EQUIPE.new())
    check(caixa == 0 and divida.divida() == 6720,"Oito semanas sem vendas acumulam divida sem caixa negativo")

func _validadores() -> void:
    var reforma := {"0,0":{"piso":2,"setor":"Oficina"}}
    check(GAME.REFORMA.validar(reforma,Vector2i(6,5)),"Acabamento valido")
    check(not GAME.REFORMA.validar({"6,0":{"piso":0,"setor":""}},Vector2i(6,5)),"Reforma fora da planta rejeitada")
    check(not GAME.REFORMA.validar({"0,0":{"piso":0.5,"setor":""}},Vector2i(6,5)),"Piso fracionario rejeitado")
    var segura := GAME.INTERFACE.area_util(Vector2(432,768),Vector2(1080,1920),Rect2(0,100,1080,1720))
    check(segura == Rect2(0,40,432,688),"Safe area fisica convertida para coordenadas do jogo")

func _integracao() -> void:
    game = _novo()
    await game._change_area(true)
    var caixa := game.money
    check(game._reformar(0,0,2,"Oficina") and game.money == caixa-20,"Reforma cobra uma vez e persiste setor")
    check(game._reformar(0,0,2,"Estoque") and game.money == caixa-20,"Alterar setor nao cobra piso novamente")
    check(not game._reformar(99,0,1,"Oficina"),"Controlador rejeita celula fora da planta")
    var caminho := game.save_path
    var antes := game.acabamentos.duplicate(true)
    game.save_path = pasta
    var imprimir := Engine.print_error_messages
    Engine.print_error_messages = false
    var ok := game._reformar(0,0,1,"Vendas")
    Engine.print_error_messages = imprimir
    check(not ok and game.acabamentos == antes and game.money == caixa-20,"Falha de gravacao desfaz reforma e cobranca")
    game.save_path = caminho
    check(game._preferencia("tutorial",3) and game._preferencia("aparencia",4),"Tutorial e acessorio configurados pelo jogador")
    game.popup.hide()
    check(game.player.estilo == 4,"Camada de aparencia aplicada sem trocar PNG")
    game._trocar_slot(2)
    check(game.evolucao["tutorial"] == 0 and game.player.estilo == 0,"Preferencias nao vazam para outro slot")
    game._trocar_slot(1)
    check(game.evolucao["tutorial"] == 3 and game.player.estilo == 4,"Voltar ao slot restaura personalizacao")
    await game._change_area(true)
    check(game.acabamentos["0,0"]["setor"] == "Estoque","Reabrir interior restaura acabamento")
    var segundos: float = game.relogio.estado["segundos"]
    game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
    check(not game._avancar_simulacao(10) and game.relogio.estado["segundos"] == segundos,"App pausado nao simula tempo nem salarios")
    game._notification(Node.NOTIFICATION_APPLICATION_RESUMED)
    check(game._avancar_simulacao(10),"Retomar aplicativo libera simulacao")
    _posto("balcao")
    check(game._operacao_comercial("abrir_os","reparo","memoria"),"Controlador recebe reparo investigativo")
    _aguardar("aguardando")
    _posto("bancada")
    check(not game._operacao_comercial("diagnosticar_os"),"Controlador exige ensaio antes do diagnostico")
    check(game._operacao_comercial("investigar_os","memoria") and game._operacao_comercial("diagnosticar_os"),"Ensaio e diagnostico ligados a bancada")
    _posto("balcao")
    game.loja.estado["estoque"]["ram_brisa"] = 1
    check(game._operacao_comercial("aprovar_os") and game._operacao_comercial("guardar_os"),"Reparo investigativo guarda cliente e reserva correta")
    _posto("bancada")
    check(game._operacao_comercial("retomar_os",str(game.loja.proxima_os())) and game._operacao_comercial("executar_os") and game._operacao_comercial("testar_os"),"Retomar preserva defeito e permite reparo/teste")
    game._abrir_servicos()
    await _capture("evolution_reparo")
    game.popup.hide()
    _posto("balcao")
    check(game._operacao_comercial("vender"),"Entregar reparo investigativo registra receita e objetivo")
    check(game.evolucao["objetivos"]["concluidos"].size() >= 2,"Venda e OS completam objetivos sem premio financeiro")
    _aguardar("")
    for id in BASE:
        game.loja.estado["estoque"][id] = 1
    _posto("balcao")
    check(game._operacao_comercial("pedido_pc"),"Pedido aceita visualizacao do gabinete")
    _posto("bancada")
    game._abrir_gabinete()
    await process_frame
    await process_frame
    var origem := game.shop_list.find_child("VisualPeca_caixa_ninho",true,false) as Button
    var destino := game.shop_list.find_child("Visual_gabinete",true,false) as Button
    check(origem != null and destino != null,"Gabinete visual oferece origem e encaixe reais")
    if origem != null and destino != null:
        var lista := game.shop_list.get_parent() as ScrollContainer
        lista.ensure_control_visible(game.shop_list.get_child(1) as Control)
        await process_frame
        await process_frame
        var de := origem.get_global_rect().get_center()+Vector2(game.popup.position)
        var ate := destino.get_global_rect().get_center()+Vector2(game.popup.position)
        var toque := InputEventMouseButton.new()
        toque.button_index = MOUSE_BUTTON_LEFT
        toque.position = de
        toque.pressed = true
        root.push_input(toque,true)
        var movimento := InputEventMouseMotion.new()
        movimento.position = de+Vector2(16,0)
        movimento.relative = Vector2(16,0)
        movimento.button_mask = MOUSE_BUTTON_MASK_LEFT
        root.push_input(movimento,true)
        await process_frame
        movimento = movimento.duplicate()
        movimento.position = ate
        movimento.relative = ate-de-Vector2(16,0)
        root.push_input(movimento,true)
        await process_frame
        check(game.popup.gui_is_dragging(),"Gabinete visual usa drag-and-drop nativo")
        toque = toque.duplicate()
        toque.position = ate
        toque.pressed = false
        root.push_input(toque,true)
        await process_frame
        await process_frame
        check(game.loja.estado["montagem"]["pecas"].get("gabinete") == "caixa_ninho","Drop no esquema instala gabinete e reserva estoque")
    await _capture("evolution_gabinete")
    game._abrir_progresso()
    await _capture("evolution_guia")
    game.popup.hide()
    await game._change_area(false)
    for i in range(120):
        game.mundo_vivo.avancar(0.25,450,{"clima":"Limpo","evento":"Feira de tecnologia"})
    check(game.mundo_vivo.get_child_count() <= 40,"Mundo integrado conserva limite de populacao")
    await _capture("evolution_bairro")
    game.queue_free()
    await process_frame
    game = GAME.new()
    game.save_path = pasta.path_join("campanha.json")
    game.legacy_path = pasta.path_join("sem_legado.save")
    root.add_child(game)
    game.set_physics_process(false)
    game.money = int(campanha["saldo"])
    check(game.loja.carregar(campanha["comercio"]) and game.relogio.carregar(campanha["calendario"]) and game.clientes.carregar(campanha["clientes"]) and game.equipe.carregar(campanha["equipe"]),"Controlador recebe capital e estados realmente produzidos em oito semanas")
    check(game._save(),"Persistir campanha longa integrada")
    var saldo := game.money
    game.pos_player = GAME.CATALOGO.buscar("pc_store_002")["porta_externa"]
    check(game._comprar_imovel() and game.money == saldo-8500,"Campanha compra imovel maior com lucro acumulado")
    game.popup.hide()
    await game._change_area(true,"pc_store_002")
    check(game._ampliar_imovel() and game._ampliar_imovel() and game.money == saldo-13900,"Campanha paga duas ampliacoes sem dinheiro injetado")
    check(game._save(),"Gravar patrimonio e campanha apos investimentos")
    game.queue_free()
    await process_frame
