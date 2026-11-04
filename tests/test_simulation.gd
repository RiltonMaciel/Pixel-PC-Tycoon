extends SceneTree

const CLOCK = preload("res://scripts/CalendarioEconomia.gd")
const GAME = preload("res://scripts/RuaComercial.gd")
const MANAGER = preload("res://scripts/Imoveis/GerenciadorImoveis.gd")
var passed := 0
var failed := 0
var temp_dir := "user://test_simulacao_" + str(Time.get_ticks_usec())
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
        printerr("FAIL: Simulacao excedeu 90 segundos.")
        quit(1))
    check(DirAccess.make_dir_absolute(temp_dir) == OK,"Criar pasta isolada")
    _test_calendario()
    _test_dividas()
    _test_clientes()
    _test_montagem_avancada()
    _test_servicos()
    _test_equipe()
    await _test_integracao()
    await _test_fila_integrada()
    await _test_equipe_integrada()
    await _test_mundo_integrado()
    game.queue_free()
    await process_frame
    for nome in DirAccess.get_files_at(temp_dir):
        check(DirAccess.remove_absolute(temp_dir.path_join(nome)) == OK,"Limpar " + nome)
    check(DirAccess.remove_absolute(temp_dir) == OK,"Limpar pasta isolada")
    print("RESULT: %d passed, %d failed" % [passed,failed])
    quit(1 if failed else 0)

func _test_equipe() -> void:
    var equipe := GAME.EQUIPE.new()
    var clock := CLOCK.new()
    var balanco := {"compras":0,"receita":0,"cmv":0}
    for id in ["lia","rui","sol"]:
        check(equipe.contratar(id),"Contratar " + id)
    var saldo := clock.avancar(450,6500,balanco,equipe)
    check(equipe.demitir("lia"),"Demissao preserva salario proporcional")
    saldo = clock.avancar(450,saldo,balanco,equipe)
    check(saldo == 6235 and clock.estado["fechamentos"][0]["despesas"] == 265,"Folha proporcional: 25 + 80 + 40, alem das despesas 120")
    check(CLOCK.validar(clock.estado) and GAME.EQUIPE.validar(equipe.estado),"Calendario com salarios e contratos validos")
    check(clock.avancar(900,saldo,balanco,equipe) == 5995,"Funcionario demitido nao gera novos salarios")
    check(equipe.contratar("lia"),"Recontratacao preserva experiencia e contrato")
    var habilidade := equipe.habilidade("lia")
    for i in range(5):
        equipe.registrar("lia","Venda salva",true)
    check(equipe.habilidade("lia") == habilidade + 1,"Cinco tarefas aumentam habilidade da funcao")
    check(not equipe.atribuir("lia","tecnico"),"Nao permite dois funcionarios no mesmo posto")
    var invalido := equipe.estado.duplicate(true)
    invalido["contratos"]["rui"]["experiencia"]["tecnico"] = -1
    check(not GAME.EQUIPE.validar(invalido),"Experiencia negativa rejeitada")
    equipe = GAME.EQUIPE.new()
    clock = CLOCK.new()
    equipe.contratar("lia")
    check(clock.avancar(1800,0,balanco,equipe) == 0 and clock.divida() == 340,"Dois dias sem caixa geram salario em divida, sem saldo negativo")
    check(CLOCK.validar(clock.estado),"Salarios em divida sao validos")

func _test_equipe_integrada() -> void:
    game._trocar_slot(3)
    await game._change_area(true)
    for id in ["lia","rui","sol"]:
        check(game._alterar_equipe("contratar",id,""),"Contratacao integrada: " + id)
    check(game.equipe_visuais.size() == 3 and game.popup.title.contains("Funcionarios"),"Equipe visivel com interface de contratos")
    await _capture("06_equipe")
    game.popup.hide()
    var contratos := game.equipe.estado.duplicate(true)
    game._buy("banqueta")
    check(not game._avancar_simulacao(900) and game.equipe.estado == contratos,"Construcao tambem pausa salarios e tarefas da equipe contratada")
    game._cancel_edit()
    check(not game._operacao_comercial("receber","1","","lia"),"Caixa nao recebe privilegios da funcao de estoque")
    game.loja.estado["estoque"] = {"kit_limpeza":1}
    var balcao := game._estacao("balcao")
    game.pos_player = game._navegacao().caminho_ate(balcao.position,85)[-1]
    check(game._operacao_comercial("abrir_os","upgrade"),"Receber OS ainda nao autorizada")
    var perfil: String = game.clientes.estado["atual"]
    game.clientes.estado["perfis"][perfil]["restante"] = 0.1
    game._processar_fila(0.2)
    check(game.loja.estado["servico"]["fase"] == "cancelado" and game.clientes.estado["atual"].is_empty(),"Desistencia antes da autorizacao cancela OS sem consumir recursos")
    for i in range(200):
        if game.loja.estado["cliente"].is_empty():
            break
        game._cliente_comercial(0.25)
    check(game._operacao_comercial("abrir_os","limpeza"),"Recepcao de OS pela interface integrada")
    game._abrir_servicos()
    await _capture("07_assistencia")
    game.popup.hide()
    for i in range(200):
        if game.loja.estado["cliente"]["fase"] == "aguardando":
            break
        game._cliente_comercial(0.25)
    check(game.loja.estado["cliente"]["fase"] == "aguardando","Cliente da OS chega fisicamente ao balcao")
    var saldo := game.money
    for i in range(8):
        game._avancar_simulacao(10)
        game._processar_funcionarios(10)
    check(game.loja.estado["servico"]["fase"] == "entregue" and game.money == saldo + 90,"Tecnico e caixa concluem OS automaticamente, com um pagamento")
    check(game.loja.quantidade("kit_limpeza") == 0 and game.loja.estado["ordens_servico"].size() == 1,"Consumo e historico da OS sem duplicacao")
    check(game.clientes.estado["historico"][-1]["resultado"] == "compra","OS integrada registra historico do cliente")
    var notebook := game._estacao("notebook")
    game.pos_player = game._navegacao().caminho_ate(notebook.position,85)[-1]
    check(game._operacao_comercial("comprar","ram_brisa"),"Compra destinada ao estoquista")
    await game._change_area(false)
    check(game.equipe_visuais.is_empty(),"Funcionarios nao aparecem na rua")
    game._avancar_simulacao(30)
    game._processar_funcionarios(30)
    check(game.loja.quantidade("ram_brisa") == 1,"Estoquista recebe fora da camera, sem exigir jogador no notebook")
    check(game._save(),"Persistir equipe, experiencia e salarios proporcionais")
    var pasta := temp_dir.path_join("bloqueio_folha")
    check(DirAccess.make_dir_absolute(pasta) == OK,"Criar bloqueio no fechamento da folha")
    var path := game.save_path
    var antes := game.equipe.estado.duplicate(true)
    saldo = game.money
    game.save_path = pasta
    var imprimir := Engine.print_error_messages
    Engine.print_error_messages = false
    var resultado := game._avancar_simulacao(900 - float(game.relogio.estado["segundos"]))
    Engine.print_error_messages = imprimir
    check(not resultado and game.equipe.estado == antes and game.money == saldo,"Falha no fechamento restaura salario acumulado, experiencia e caixa")
    game.save_path = path
    game._salvar_manual()
    check(DirAccess.remove_absolute(pasta) == OK,"Limpar bloqueio da folha")
    game.queue_free()
    await process_frame
    game = _new_game()
    check(game.equipe.ativo("rui") and game.equipe.estado["contratos"]["rui"]["experiencia"]["tecnico"] == 3,"Reabrir preserva contrato e experiencia real")
    check(game.loja.estado["ordens_servico"].size() == 1,"Reabrir preserva OS entregue sem novo pagamento")

func _test_mundo_integrado() -> void:
    game._trocar_slot(1)
    await game._change_area(true)
    var moveis := game.moveis.size()
    var saldo := game.money
    var saida: Vector2 = game.cadastro["saida_interna"]
    check(game._ampliar_imovel(),"Comprar ampliacao com validacao das rotas")
    check(game.money == saldo - 1800 and game.sala.tamanho == Vector2i(8,6),"Ampliacao cobra uma vez e adiciona modulos reais")
    check(game.moveis.size() == moveis and game.cadastro["saida_interna"] != saida,"Ampliacao preserva moveis e reposiciona entrada")
    check(game._walkable(game.cadastro["entrada_interna"]),"Entrada ampliada permite personagem")
    game.popup.hide()
    game._buy("divisoria_modular")
    var divisoria := game.selecionado
    check(divisoria != null,"Divisoria disponivel para compra")
    var forma := divisoria.poligono_colisao(Vector2.ZERO)
    check(Geometry2D.is_point_in_polygon(Vector2(30,15),forma) and not Geometry2D.is_point_in_polygon(Vector2(-30,15),forma),"Base da primeira parede acompanha o eixo U, nao um retangulo de tela")
    check(divisoria.girar(),"Divisoria usa duas vistas aprovadas, sem rotacionar PNG")
    forma = divisoria.poligono_colisao(Vector2.ZERO)
    check(Geometry2D.is_point_in_polygon(Vector2(-30,15),forma) and not Geometry2D.is_point_in_polygon(Vector2(30,15),forma),"Giro da divisoria troca o eixo da base para V")
    var nav := game._navegacao()
    var colocada := false
    for u in range(1,8):
        for v in range(1,6):
            divisoria.position = GAME.INTERIOR.ponto(Vector2(u,v),game.cadastro["origem"])
            if nav.ponto_livre(divisoria.position) and game._can_place(divisoria):
                colocada = true
                break
        if colocada:
            break
    check(colocada,"Divisoria encontra piso seguro sem fechar caminhos")
    game._edit_action("OK")
    check(game.selecionado == null and game.moveis.size() == moveis + 1 and game.money == saldo - 1920,"Confirmar divisoria cobra R$ 120 uma vez")
    check(not game._walkable(divisoria.position),"Divisoria bloqueia os pes pela base isometrica")
    game._abrir_imovel()
    await _capture("08_ampliacao")
    game.popup.hide()
    await _capture("09_divisoria")
    game.queue_free()
    await process_frame
    game = _new_game()
    check(game.cadastro["nivel"] == 1 and game.gestor_imoveis.estados[GAME.LOJA_ID]["moveis"].size() == moveis + 1,"Reabrir preserva ampliacao e divisoria")
    await game._change_area(true)
    var pasta := temp_dir.path_join("bloqueio_ampliacao")
    check(DirAccess.make_dir_absolute(pasta) == OK,"Bloqueio para testar compra atomica de ampliacao")
    var path := game.save_path
    game.save_path = pasta
    saldo = game.money
    var imprimir := Engine.print_error_messages
    Engine.print_error_messages = false
    var resultado := game._ampliar_imovel()
    Engine.print_error_messages = imprimir
    check(not resultado and game.money == saldo and game.cadastro["nivel"] == 1 and game.sala.tamanho == Vector2i(8,6),"Falha de escrita desfaz custo, nivel e planta")
    game.save_path = path
    check(DirAccess.remove_absolute(pasta) == OK,"Limpar bloqueio de ampliacao")
    await game._change_area(false)
    var nova := GAME.CATALOGO.buscar("pc_store_002")
    game.pos_player = nova["porta_externa"]
    check(game._walkable(game.pos_player),"Entrada do imovel maior existe na calcada real do bairro")
    check(not game._comprar_imovel() and not game.gestor_imoveis.estados.has("pc_store_002"),"Compra recusa caixa insuficiente sem criar propriedade")
    game.money = 10000
    check(game._comprar_imovel() and game.money == 1500,"Compra de imovel maior pelo acesso da fachada")
    check(not game._comprar_imovel() and game.money == 1500,"Compra repetida nao cobra novamente")
    game.popup.hide()
    await game._change_area(true,"pc_store_002")
    check(game.indoors and game.unidade_id == "pc_store_002" and game.sala.tamanho == Vector2i(10,8),"Imovel adquirido possui entrada e interior maiores reais")
    check(game.moveis.is_empty() and game.gestor_imoveis.estados[GAME.LOJA_ID]["moveis"].size() == moveis + 1,"Plantas e moveis de cada imovel sao independentes")
    await _capture("10_imovel_maior")
    await game._change_area(false)
    check(game.pos_player == nova["saida_externa"],"Saida retorna a fachada correta, nao a PC Store original")
    game.queue_free()
    await process_frame
    game = _new_game()
    check(game.unidade_id == "pc_store_002" and game.money == 1500,"Reabrir preserva unidade ativa e propriedade")
    await game._change_area(true,GAME.LOJA_ID)
    check(game.moveis.size() == moveis + 1 and game.cadastro["nivel"] == 1,"Retornar ao imovel anterior restaura planta e divisoria")
    game.loja.estado["estoque"] = {"ram_brisa":4}
    game.relogio.carregar(CLOCK.inicial(game.loja.resumo()))
    game.cliente_espera = 0
    game._processar_fila(14)
    check(game.clientes.estado["fila"].is_empty(),"Rotina nao gera cliente antes de 20 segundos")
    game.money = game.relogio.avancar(13 * 900,game.money,game.loja.resumo(),game.equipe)
    game._processar_fila(0)
    check(game.clientes.estado["fila"].size() == 1,"Feira aumenta demanda real: chegada antes dos 20 segundos")
    game.relogio.estado["segundos"] = 450.0
    game._refresh()
    check(game.iluminacao.color == Color.WHITE,"Meio-dia sem filtro noturno")
    game.relogio.estado["segundos"] = 0.0
    game._refresh()
    check(game.iluminacao.color == Color.WHITE,"Interior permanece iluminado a noite")
    await game._change_area(false)
    check(game.iluminacao.color != Color.WHITE,"Exterior escurece a noite sem escurecer HUD")
    game._avancar_simulacao(900)
    check(game.ambiente.chovendo and GAME.AMBIENTE.previsao(15)["demanda"] < 1.0,"Chuva visivel reduz demanda")
    await _capture("11_chuva_noturna")
    game.relogio.estado["segundos"] = 0.0

func _test_calendario() -> void:
    var clock := CLOCK.new()
    var balanco := {"compras":0,"receita":0,"cmv":0}
    var saldo := clock.avancar(899,6500,balanco)
    check(saldo == 6500 and clock.estado["dia"] == 1 and not clock.fechou_dia,"899 s nao fecham um dia")
    saldo = clock.avancar(1,saldo,balanco)
    check(saldo == 6380 and clock.estado["dia"] == 2 and clock.estado["segundos"] == 0,"900 s exatos fecham dia e cobram R$ 120")
    check(clock.estado["fechamentos"].size() == 1 and clock.estado["contas"].size() == 2,"Uma unica fatura de cada tipo por dia")
    saldo = clock.avancar(0,saldo,balanco)
    check(saldo == 6380 and clock.estado["pagamentos"].size() == 2,"Repetir frame na virada nao cobra duas vezes")
    check(CLOCK.validar(clock.estado),"Calendario fechado e valido")
    clock = CLOCK.new()
    clock.avancar(900 * 7,6500,balanco)
    check(clock.data()["semana"] == 1 and clock.data()["dia"] == 8,"Semana tem sete dias")
    clock = CLOCK.new()
    clock.avancar(900 * 28,6500,balanco)
    check(clock.data()["dia"] == 1 and clock.data()["mes"] == 2,"Mes tem 28 dias")
    clock = CLOCK.new()
    clock.avancar(900 * 336,6500,balanco)
    check(clock.data()["dia"] == 1 and clock.data()["mes"] == 1 and clock.data()["ano"] == 2,"Ano tem 12 meses de 28 dias")
    check(CLOCK.validar(clock.estado),"Ano com dividas permanece valido")
    clock = CLOCK.new()
    clock.avancar(37.5,6500,balanco)
    check(clock.data()["hora"] == 1 and clock.data()["minuto"] == 0,"Uma hora de jogo equivale a 37,5 segundos")
    var base := {"compras":100,"receita":180,"cmv":140}
    clock.carregar(CLOCK.inicial(base))
    clock.avancar(900,6500,{"compras":200,"receita":500,"cmv":340})
    var fechamento: Dictionary = clock.estado["fechamentos"][0]
    check(fechamento["receita"] == 320 and fechamento["cmv"] == 200 and fechamento["lucro"] == 0,"Fechamento separa lucro bruto, despesas e historico anterior")
    for campo in ["segundos","dia","pagamentos"]:
        var invalido := CLOCK.inicial()
        invalido[campo] = "invalido"
        check(not CLOCK.validar(invalido),"Tipo invalido rejeitado: " + campo)
    var invalido := clock.estado.duplicate(true)
    invalido["pagamentos"].append(invalido["pagamentos"][0].duplicate(true))
    check(not CLOCK.validar(invalido),"Pagamento duplicado rejeitado")

func _test_dividas() -> void:
    var clock := CLOCK.new()
    var balanco := {"compras":0,"receita":0,"cmv":0}
    var saldo := clock.avancar(900,50,balanco)
    check(saldo == 0 and clock.divida() == 70,"Sem saldo negativo: R$ 50 pagos, R$ 70 em divida")
    check(clock.estado["contas"][0]["pago"] == 50 and clock.estado["contas"][1]["pago"] == 0,"Pagamento parcial respeita ordem das contas")
    saldo = clock.pagar_contas(25)
    check(saldo == 0 and clock.divida() == 45,"Novo saldo quita parte da divida")
    saldo = clock.pagar_contas(100)
    check(saldo == 55 and clock.divida() == 0,"Quitar devolve saldo excedente")
    check(CLOCK.validar(clock.estado),"Contas e pagamentos parciais conferem")
    clock.pagar_contas(saldo)
    check(not clock.ultimo_erro.is_empty() and clock.divida() == 0,"Repetir quitacao nao paga de novo")

func _test_integracao() -> void:
    game = _new_game()
    check(game.relogio.estado["dia"] == 1 and game.money == 6500,"Save antigo/novo inicia calendario sem cobrar retroativamente")
    game._menu("Financas")
    check(game.popup.visible and game.popup.title.contains("Calendario"),"Financas acessiveis pela interface")
    game.popup.hide()
    await game._change_area(true)
    game._buy("banqueta")
    var segundos := float(game.relogio.estado["segundos"])
    game._avancar_simulacao(900)
    check(game.relogio.estado["segundos"] == segundos and game.money == 6500,"Construcao pausa dia e despesas")
    game._cancel_edit()
    check(game._avancar_simulacao(899),"Simulacao retoma depois de cancelar construcao")
    check(game.money == 6500,"Sem cobranca antes de 900 s")
    check(game._avancar_simulacao(1) and game.money == 6380,"Virada integrada salva despesas")
    check(game.gestor_imoveis.calendario["dia"] == 2,"Save inclui calendario e contas")
    game.queue_free()
    await process_frame
    game = _new_game()
    check(game.relogio.estado["dia"] == 2 and game.money == 6380,"Reabrir nao repete cobranca")
    game._trocar_slot(2)
    check(game.relogio.estado["dia"] == 1 and game.money == 6500,"Slots isolam tempo e despesas")
    game._trocar_slot(1)
    check(game.relogio.estado["dia"] == 2 and game.money == 6380,"Retorno restaura calendario do slot")
    var path := game.save_path
    var pasta := temp_dir.path_join("bloqueio")
    check(DirAccess.make_dir_absolute(pasta) == OK,"Criar bloqueio de escrita")
    game.save_path = pasta
    var imprimir := Engine.print_error_messages
    Engine.print_error_messages = false
    var resultado := game._avancar_simulacao(900)
    Engine.print_error_messages = imprimir
    check(not resultado and game.relogio_bloqueado,"Falha no fechamento pausa simulacao explicitamente")
    check(game.money == 6380 and game.relogio.estado["dia"] == 2,"Falha desfaz cobranca e virada em memoria")
    check(game.info.text.contains("Relogio pausado"),"Erro de fechamento informa como retomar")
    game.save_path = path
    game._salvar_manual()
    check(not game.relogio_bloqueado,"Salvar manual retoma apos resolver escrita")
    check(game._avancar_simulacao(900) and game.money == 6260,"Retentativa cobra somente uma vez")
    check(DirAccess.remove_absolute(pasta) == OK,"Remover bloqueio vazio")
    var backup_path := temp_dir.path_join("calendario_backup.json")
    var gestor := MANAGER.new()
    gestor.estados = game.gestor_imoveis.estados.duplicate(true)
    gestor.calendario = game.relogio.estado.duplicate(true)
    check(gestor.gravar(6260,backup_path) and gestor.gravar(6260,backup_path),"Preparar backup com contas")
    var dados: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(backup_path))
    dados["calendario"]["pagamentos"].append(dados["calendario"]["pagamentos"][0].duplicate(true))
    var arquivo := FileAccess.open(backup_path,FileAccess.WRITE)
    arquivo.store_string(JSON.stringify(dados))
    arquivo.close()
    var recuperado := gestor.ler(backup_path,"")
    check(recuperado.get("dinheiro") == 6260 and gestor.calendario["dia"] == 3,"Calendario danificado recupera backup valido")
    check(FileAccess.file_exists(backup_path + ".corrompido"),"Calendario danificado preservado")

func _test_clientes() -> void:
    var clientes := GAME.CLIENTES.new()
    var primeiro := clientes.adicionar("ram",150,30)
    check(not primeiro.is_empty(),"Perfil com preferencia, orcamento e paciencia")
    check(clientes.oferta(primeiro,{"ram_brisa":1}).is_empty(),"Cliente recusa produto acima do orcamento")
    clientes.estado["perfis"][primeiro]["orcamento"] = 200
    check(clientes.oferta(primeiro,{"ram_brisa":1,"ssd_trilha":2}) == "ram_brisa","Oferta respeita categoria preferida e orcamento")
    for i in range(3):
        check(not clientes.adicionar("ssd",300,30).is_empty(),"Fila aceita cliente %d" % i)
    check(clientes.adicionar("ram",200).is_empty(),"Fila tem limite de quatro clientes")
    check(clientes.ativar(primeiro) and clientes.estado["fila"].size() == 3,"Primeiro da fila entra em atendimento")
    check(not clientes.ativar(clientes.estado["fila"][0]),"Nao inicia segundo atendimento no mesmo balcao")
    check(clientes.avancar(29).is_empty(),"Paciencia nao expira antecipadamente")
    check(clientes.avancar(1).size() == 4,"Fila e cliente ativo expiram no limite exato")
    clientes.finalizar(primeiro,1,"compra","ram_brisa",180)
    check(clientes.estado["atual"].is_empty() and clientes.estado["historico"].size() == 1,"Historico mantem identidade apos atendimento")
    check(clientes.estado["perfis"][primeiro]["fidelidade"] == 5,"Compra aumenta fidelidade do perfil correto")
    check(GAME.CLIENTES.validar(clientes.estado),"Estado com fila e historico e salvavel")
    var invalido := clientes.estado.duplicate(true)
    invalido["fila"].append(invalido["fila"][0])
    check(not GAME.CLIENTES.validar(invalido),"Duplicacao de pessoa na fila rejeitada")

func _test_fila_integrada() -> void:
    game._trocar_slot(2)
    await game._change_area(true)
    game.loja.estado["estoque"] = {"ram_brisa":4}
    game._processar_fila(20)
    check(game.clientes.estado["fila"].size() == 1 and game.fila_visuais.size() == 1,"Fila persistente possui personagem real no interior")
    game.popup.hide()
    game._atender_fila()
    check(not game.clientes.estado["atual"].is_empty() and game.loja.estado["cliente"]["fase"] == "entrando","Perfil da fila ligado ao comprador em cena")
    for i in range(200):
        if game.loja.estado["cliente"]["fase"] == "aguardando":
            break
        game._cliente_comercial(0.25)
    check(game.loja.estado["cliente"]["fase"] == "aguardando","Cliente da fila chega ao balcao")
    game.pos_player = game.customer.position
    var saldo := game.money
    check(game._operacao_comercial("vender") and game.money == saldo + 180,"Comprador com orcamento paga uma vez")
    check(game.clientes.estado["historico"].size() == 1 and game.clientes.estado["historico"][0]["valor"] == 180,"Historico ligado ao pagamento real")
    game.queue_free()
    await process_frame
    game = _new_game()
    check(game.clientes.estado["historico"].size() == 1 and game.clientes.estado["historico"][0]["valor"] == 180,"Reabrir preserva historico e identidade")
    await game._change_area(true)
    for i in range(200):
        if game.loja.estado["cliente"].is_empty():
            break
        game._cliente_comercial(0.25)
    var balcao := game._estacao("balcao")
    var rota := game._navegacao().caminho_ate(balcao.position,85)
    game.pos_player = rota[rota.size()-1]
    check(game._operacao_comercial("pedido_pc"),"Pedido de PC possui perfil com prazo maior")
    game.loja.estado["estoque"]["caixa_ninho"] = 1
    var bancada := game._estacao("bancada")
    rota = game._navegacao().caminho_ate(bancada.position,85)
    game.pos_player = rota[rota.size()-1]
    check(game._operacao_comercial("instalar","caixa_ninho","gabinete"),"Montagem ativa reserva componente")
    var perfil: String = game.clientes.estado["atual"]
    game.clientes.estado["perfis"][perfil]["restante"] = 0.1
    game._processar_fila(0.2)
    check(game.loja.estado["cliente"]["fase"] == "saindo" and game.clientes.estado["atual"].is_empty(),"Cliente sem paciencia desiste e sai")
    check(game.loja.quantidade("caixa_ninho") == 1 and game.money == saldo + 180,"Desistencia devolve reserva sem pagamento")
    check(game.clientes.estado["historico"][-1]["resultado"] == "desistencia","Desistencia registrada no historico")
    check(GAME.CLIENTES.validar(game.clientes.estado),"Fila integrada permanece valida apos desistir")

func _test_montagem_avancada() -> void:
    check(GAME.JOGOS.JOGOS.size() == 22,"Catalogo possui vinte jogos e duas continuacoes")
    for jogo_id in GAME.JOGOS.JOGOS:
        var modelo := GAME.COMERCIO.new()
        var jogo: Dictionary = GAME.JOGOS.JOGOS[jogo_id]
        check(modelo.criar_cliente("",true,jogo_id),"Pedido aceita jogo " + jogo_id)
        var pecas := ["caixa_ninho","placa_aurora","cpu_aurora","ram_brisa","fonte_clara","ssd_trilha","gpu_pixel","cooler_neve"]
        if int(jogo["cpu"]) > 150:
            pecas = ["caixa_torre","placa_nova","cpu_nova","ram_vento","fonte_firme","ssd_veloz","gpu_trovao","cooler_nova"]
        elif int(jogo["cpu"]) > 100 or int(jogo["gpu"]) > 100 or int(jogo["ram"]) > 8:
            pecas = ["caixa_ninho","placa_aurora","cpu_aurora_pro","ram_brisa16","fonte_clara","ssd_trilha500","gpu_pixel200","cooler_neve"]
        if jogo.has("lancamento"):
            for id in GAME.PECAS.PECAS:
                modelo.estado["estoque"][id] = 1
            var plano := modelo.plano_automatico()
            check(plano.size() == 8,"Continuacao possui configuracao acessivel: " + jogo_id)
            if plano.size() != 8:
                continue
            pecas.clear()
            for categoria in GAME.PECAS.CATEGORIAS:
                pecas.append(plano[categoria])
        for id in pecas:
            modelo.estado["estoque"][id] = 1
            check(modelo.instalar(id,GAME.PECAS.PECAS[id]["categoria"]),"Instalar " + id + " para " + jogo_id)
        check(modelo.conectar() and modelo.testar(),"Configuracao alcancavel dentro do orcamento: " + jogo_id)
        check(GAME.COMERCIO.validar(modelo.estado),"Pedido e diagnostico salvaveis: " + jogo_id)
    var falha := GAME.COMERCIO.new()
    falha.criar_cliente("",true)
    for id in ["caixa_fechada","placa_aurora","cpu_aurora","ram_brisa","fonte_limite","ssd_trilha","gpu_pixel","cooler_neve"]:
        falha.estado["estoque"][id] = 1
        check(falha.instalar(id,GAME.PECAS.PECAS[id]["categoria"]),"Instalar componente compativel de configuracao problematica")
    falha.conectar()
    check(not falha.testar() and falha.ultimo_erro.contains("Superaquecimento"),"Compatibilidade nao mascara problema termico")
    check(falha.estado["montagem"]["diagnostico"]["cpu_c"] > 80,"Temperatura simulada medida contra limite real do teste")
    falha.estado["estoque"]["cooler_neve_pro"] = 1
    check(falha.instalar("cooler_neve_pro","cooler"),"Trocar cooler recupera falha sem perder outras pecas")
    falha.conectar()
    check(not falha.testar() and falha.ultimo_erro.contains("Instabilidade"),"Teste identifica margem insuficiente da fonte")
    falha.estado["estoque"]["fonte_clara"] = 1
    check(falha.instalar("fonte_clara","fonte"),"Fonte melhor corrige instabilidade")
    falha.conectar()
    check(falha.testar() and falha.estado["montagem"]["fase"] == "testado","Repetir testes aprova PC corrigido")
    check(falha.quantidade("cooler_neve") == 1 and falha.quantidade("fonte_limite") == 1,"Trocas devolvem componentes antigos sem duplica-los")
    check(GAME.COMERCIO.validar(falha.estado),"Configuracao corrigida pode ser salva")

func _test_servicos() -> void:
    for tipo in GAME.COMERCIO.SERVICOS.ITENS:
        var modelo := GAME.COMERCIO.new()
        var dados: Dictionary = GAME.COMERCIO.SERVICOS.ITENS[tipo]
        check(modelo.abrir_os(tipo),"Recepcao de OS: " + tipo)
        check(not modelo.executar_os(),"OS nao executa sem diagnostico e aprovacao")
        check(modelo.diagnosticar_os(),"Diagnostico do PC do cliente: " + tipo)
        modelo.estado["cliente"]["fase"] = "aguardando"
        check(modelo.aprovar_os(),"Orcamento aprovado no balcao: " + tipo)
        if not dados["necessarios"].is_empty():
            check(not modelo.executar_os() and modelo.estado["servico"]["custo"] == 0,"Falta de peca/insumo nao consome parcialmente")
        for id in dados["necessarios"]:
            modelo.estado["estoque"][id] = int(dados["necessarios"][id])
        check(modelo.executar_os(),"Executar " + tipo + " com recursos reais")
        var custo := int(modelo.estado["servico"]["custo"])
        check(not modelo.executar_os() and int(modelo.estado["servico"]["custo"]) == custo,"Executar novamente nao duplica consumo")
        check(modelo.testar_os(),"Teste final do servico: " + tipo)
        check(modelo.vender() == int(dados["preco"]),"Entrega credita preco da OS: " + tipo)
        check(modelo.vender() == 0,"OS nao paga duas vezes")
        check(modelo.estado["ordens_servico"].size() == 1 and modelo.resumo()["cmv"] == custo,"Historico de OS e CMV preservados")
        if tipo in ["upgrade","reparo"]:
            check(not modelo.estado["servico"]["devolvidos"].is_empty(),"Peca antiga pertence ao cliente")
        check(GAME.COMERCIO.validar(modelo.estado),"OS entregue e salvavel: " + tipo)
    var cancelado := GAME.COMERCIO.new()
    cancelado.abrir_os("limpeza")
    check(cancelado.cancelar_os() and cancelado.estado["servico"]["fase"] == "cancelado","Cancelar OS antes de consumir e seguro")
