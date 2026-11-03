extends Node2D

const BAIRRO = preload("res://scripts/BairroComercial.gd")
const CATALOGO = preload("res://scripts/Imoveis/CatalogoImoveis.gd")
const SPRITES = preload("res://scripts/Imoveis/CatalogoSprites.gd")
const GERENCIADOR = preload("res://scripts/Imoveis/GerenciadorImoveis.gd")
const MOVEL = preload("res://scripts/Moveis/MovelIsometrico.gd")
const PORTA = preload("res://scripts/PortaLoja.gd")
const PERSONAGEM = preload("res://scripts/PersonagemAnimado.gd")
const INTERIOR = preload("res://scripts/Imoveis/InteriorModular.gd")
const LOJA_ID := "pc_store_001"

var cadastro: Dictionary = CATALOGO.buscar(LOJA_ID)
var gestor_imoveis = GERENCIADOR.new()
var save_path: String = GERENCIADOR.SAVE_PATH
var legacy_path: String = GERENCIADOR.LEGACY_PATH
var pos_player: Vector2 = cadastro["saida_externa"]
var pos_customer: Vector2 = cadastro["rota_cliente"][0]
var money := 6500
var indoors := false
var transitioning := false
var save_bloqueado := false
var move := Vector2.ZERO
var finger := -1
var drag_finger := -1
var drag_offset := Vector2.ZERO
var route_index := 0
var route_wait := 0.0
var guardados: Array = []
var recuperando := -1
var moveis: Array[MOVEL] = []
var selecionado: MOVEL
var comprando := false
var player: PERSONAGEM
var customer: PERSONAGEM
var cam: Camera2D
var layer: CanvasLayer
var top_label: Label
var info: Label
var popup: AcceptDialog
var pad_center := Vector2.ZERO
var bairro: BAIRRO
var sala: INTERIOR
var porta: PORTA
var fade: ColorRect
var edit_bar: HBoxContainer
var exit_marker: Label
var shop_list: VBoxContainer

func _ready() -> void:
    RenderingServer.set_default_clear_color(Color("#192331"))
    bairro = BAIRRO.new()
    add_child(bairro)
    porta = PORTA.new()
    porta.position = BAIRRO.LOJA_POS
    porta.scale = Vector2.ONE * BAIRRO.LOJA_ESCALA
    porta.z_index = int(BAIRRO.local_loja(Vector2(650,760)).y)
    add_child(porta)
    sala = INTERIOR.new()
    add_child(sala)
    sala.configurar(cadastro)
    sala.visible = false
    player = _personagem("protagonista",pos_player)
    player.name = "Jogador_Independente"
    customer = _personagem("cliente_estudante",pos_customer)
    customer.name = "Cliente_Independente"
    exit_marker = Label.new()
    exit_marker.text = "SAIDA [A]"
    exit_marker.position = Vector2(cadastro["saida_interna"]) + Vector2(-32,0)
    exit_marker.add_theme_font_size_override("font_size",14)
    exit_marker.z_index = 1
    exit_marker.visible = false
    add_child(exit_marker)
    cam = Camera2D.new()
    cam.position = pos_player
    add_child(cam)
    _camera_exterior()
    layer = CanvasLayer.new()
    add_child(layer)
    _hud()
    get_viewport().size_changed.connect(_layout)
    _layout()
    _load()
    _refresh()

func _personagem(id: String, at: Vector2) -> PERSONAGEM:
    var sprite := PERSONAGEM.new()
    sprite.configurar(id)
    sprite.position = at
    sprite.atualizar(Vector2.ZERO,0)
    add_child(sprite)
    return sprite

func _no_piso(at: Vector2) -> bool:
    if indoors:
        return Geometry2D.is_point_in_polygon(at,cadastro["piso_interno"])
    return BAIRRO.piso_livre(at) and bairro.vizinhanca.piso_livre(at)

func _walkable(at: Vector2) -> bool:
    for offset in [Vector2.ZERO,Vector2(10,0),Vector2(-10,0),Vector2(0,10),Vector2(0,-10)]:
        if not _no_piso(at + offset):
            return false
    if indoors:
        for movel in moveis:
            if movel == selecionado and comprando:
                continue
            var ponto := movel.posicao_confirmada if movel.em_edicao else movel.position
            if Geometry2D.is_point_in_polygon(at,movel.poligono_colisao(ponto,8,movel.em_edicao)):
                return false
    return true

func _physics_process(delta: float) -> void:
    var bloqueado := transitioning or popup.visible or save_bloqueado or (selecionado != null and selecionado.em_edicao)
    var direction := Vector2.ZERO if bloqueado else (move + Input.get_vector("ui_left","ui_right","ui_up","ui_down")).limit_length(1)
    var distance := direction * 205.0 * delta
    var anterior := pos_player
    var steps := maxi(1,ceili(distance.length() / 5.0))
    for i in range(steps):
        var step := distance / float(steps)
        if _walkable(pos_player + Vector2(step.x,0)):
            pos_player.x += step.x
        if _walkable(pos_player + Vector2(0,step.y)):
            pos_player.y += step.y
    player.position = pos_player
    player.atualizar(pos_player - anterior,delta)
    if not indoors and not transitioning and not save_bloqueado:
        _npc(delta)
    if not indoors:
        cam.position = cam.position.lerp(pos_player,minf(1.0,delta * 5.0))

func _npc(delta: float) -> void:
    if route_wait > 0:
        route_wait -= delta
        customer.atualizar(Vector2.ZERO,delta)
        return
    var route: PackedVector2Array = cadastro["rota_cliente"]
    var diff := route[route_index] - pos_customer
    if diff.length() < 5:
        route_index = (route_index + 1) % route.size()
        route_wait = 1.0
        return
    var step := diff.normalized() * minf(68 * delta,diff.length())
    if _walkable(pos_customer + step):
        pos_customer += step
        customer.position = pos_customer
        customer.atualizar(step,delta)
    else:
        push_warning("Rota do cliente bloqueada; retornando ao ponto anterior.")
        route_index = (route_index + 1) % route.size()
        route_wait = 1.0

func _button(label: String, callback: Callable, parent: Node) -> Button:
    var button := Button.new()
    button.text = label
    button.custom_minimum_size = Vector2(0,44)
    button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    button.add_theme_font_size_override("font_size",12)
    button.pressed.connect(callback)
    parent.add_child(button)
    return button

func _hud() -> void:
    var header := PanelContainer.new()
    header.name = "Header"
    layer.add_child(header)
    var v := VBoxContainer.new()
    header.add_child(v)
    top_label = Label.new()
    top_label.add_theme_font_size_override("font_size",17)
    v.add_child(top_label)
    info = Label.new()
    info.custom_minimum_size = Vector2(380,40)
    info.text = "Rua | Use as faixas para atravessar. A na PC Store entra."
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    info.add_theme_font_size_override("font_size",13)
    v.add_child(info)
    var menu := HBoxContainer.new()
    menu.name = "Menu"
    layer.add_child(menu)
    for label in ["Loja","Cliente","Montagem","Estoque","Menu"]:
        _button(label,_menu.bind(label),menu)
    var action := _button("A",_interact,layer)
    action.name = "Action"
    action.add_theme_font_size_override("font_size",24)
    var pad := Panel.new()
    pad.name = "Pad"
    pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var pad_style := StyleBoxFlat.new()
    pad_style.bg_color = Color("#20364b")
    pad_style.border_color = Color("#7daccb")
    pad_style.set_border_width_all(3)
    pad_style.set_corner_radius_all(54)
    pad.add_theme_stylebox_override("panel",pad_style)
    layer.add_child(pad)
    var arrows := Label.new()
    arrows.text = "    ▲\n◀       ▶\n    ▼"
    arrows.name = "Arrows"
    arrows.mouse_filter = Control.MOUSE_FILTER_IGNORE
    arrows.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    arrows.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    pad.add_child(arrows)
    popup = AcceptDialog.new()
    popup.title = "Moveis e equipamentos"
    popup.ok_button_text = "Fechar"
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(340,300)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    popup.add_child(scroll)
    shop_list = VBoxContainer.new()
    shop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(shop_list)
    layer.add_child(popup)
    edit_bar = HBoxContainer.new()
    edit_bar.name = "Edicao"
    layer.add_child(edit_bar)
    for label in ["Mover","Girar","Vender","Cancelar","OK"]:
        _button(label,_edit_action.bind(label),edit_bar)
    edit_bar.visible = false
    fade = ColorRect.new()
    fade.color = Color(0,0,0,0)
    fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(fade)

func _layout() -> void:
    var size := get_viewport_rect().size
    var header := layer.get_node("Header") as Control
    header.position = Vector2(6,6)
    header.size = Vector2(size.x - 12,82)
    var menu := layer.get_node("Menu") as Control
    menu.position = Vector2(6,size.y - 66)
    menu.size = Vector2(size.x - 12,58)
    var pad := layer.get_node("Pad") as Control
    pad.position = Vector2(18,size.y - 187)
    pad.size = Vector2(108,108)
    (pad.get_node("Arrows") as Control).size = pad.size
    pad_center = pad.position + pad.size * 0.5
    var action := layer.get_node("Action") as Control
    action.position = Vector2(size.x - 104,size.y - 166)
    action.size = Vector2(75,75)
    edit_bar.position = Vector2(6,100)
    edit_bar.size = Vector2(size.x - 12,48)
    fade.size = size
    if indoors:
        _camera_interior()

func _camera_interior() -> void:
    var bounds := sala.limites()
    var viewport := get_viewport_rect().size
    var zoom := minf((viewport.x - 24) / bounds.size.x,(viewport.y - 330) / bounds.size.y)
    cam.zoom = Vector2.ONE * zoom
    cam.limit_left = -10000
    cam.limit_top = -10000
    cam.limit_right = 10000
    cam.limit_bottom = 10000
    cam.position = bounds.get_center() + Vector2(0,24 / zoom)
    cam.force_update_scroll()

func _camera_exterior() -> void:
    var bounds := BAIRRO.limites()
    cam.zoom = Vector2(0.65,0.65)
    cam.limit_left = int(bounds.position.x)
    cam.limit_top = int(bounds.position.y)
    cam.limit_right = int(bounds.end.x)
    cam.limit_bottom = int(bounds.end.y)
    cam.force_update_scroll()

func _input(event: InputEvent) -> void:
    # Captura liberacoes mesmo quando o dedo termina sobre um botao.
    if event is InputEventScreenTouch and not event.pressed:
        if event.index == finger:
            finger = -1
            move = Vector2.ZERO
        if event.index == drag_finger:
            drag_finger = -1
    elif event is InputEventScreenDrag:
        if event.index == finger:
            _direction(event.position)
            get_viewport().set_input_as_handled()
        elif event.index == drag_finger:
            _drag(event.position)
            get_viewport().set_input_as_handled()
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
        if finger == -2:
            finger = -1
            move = Vector2.ZERO
        if drag_finger == -2:
            drag_finger = -1
    elif event is InputEventMouseMotion:
        if finger == -2:
            _direction(event.position)
            get_viewport().set_input_as_handled()
        elif drag_finger == -2:
            _drag(event.position)
            get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
    if transitioning or popup.visible or save_bloqueado:
        return
    if event.is_action_pressed("ui_cancel"):
        _cancel_edit()
    elif event.is_action_pressed("ui_accept"):
        _interact()
    elif event is InputEventScreenTouch and event.pressed:
        _pointer_down(event.position,event.index)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.device != -1:
        _pointer_down(event.position,-2)

func _pointer_down(screen: Vector2, pointer: int) -> void:
    if screen.distance_to(pad_center) < 58:
        finger = pointer
        _direction(screen)
        return
    if not indoors:
        return
    var world := get_canvas_transform().affine_inverse() * screen
    if selecionado != null and selecionado.em_edicao:
        drag_finger = pointer
        drag_offset = selecionado.position - world if selecionado.contem_ponto(world) else Vector2.ZERO
        _drag(screen)
        return
    var encontrado: MOVEL
    for movel in moveis:
        if movel.contem_ponto(world) and (encontrado == null or movel.position.y > encontrado.position.y):
            encontrado = movel
    selecionado = encontrado
    edit_bar.visible = selecionado != null
    if selecionado != null:
        info.text = "Escolha Mover, Girar, Vender ou Cancelar."

func _direction(at: Vector2) -> void:
    var diff := at - pad_center
    move = diff.normalized() if diff.length() > 15 else Vector2.ZERO

func _snap(at: Vector2) -> Vector2:
    var grid := Transform2D(INTERIOR.U * 0.25,INTERIOR.V * 0.25,cadastro["origem"])
    return grid * (grid.affine_inverse() * at).round()

func _drag(screen: Vector2) -> void:
    if selecionado == null or not selecionado.em_edicao:
        return
    selecionado.position = _snap(get_canvas_transform().affine_inverse() * screen + drag_offset)
    selecionado.indicar_validade(_can_place(selecionado))

func _can_place(movel: MOVEL) -> bool:
    if not indoors:
        return false
    var shape := movel.poligono_colisao(movel.position,4)
    var saida: Vector2 = cadastro["saida_interna"]
    for ponto in shape:
        if not Geometry2D.is_point_in_polygon(ponto,cadastro["piso_interno"]):
            return false
    if Geometry2D.is_point_in_polygon(pos_player,movel.poligono_colisao(movel.position,24)):
        return false
    # Reserva circulacao e acesso a porta, inclusive quando a base e alongada.
    if Geometry2D.is_point_in_polygon(saida,movel.poligono_colisao(movel.position,40)):
        return false
    for outro in moveis:
        if outro != movel and not Geometry2D.intersect_polygons(shape,outro.poligono_colisao(outro.position,4)).is_empty():
            return false
    return true

func _buy(id: String = "balcao_pc_store", estoque: int = -1) -> void:
    popup.hide()
    if not indoors or transitioning or save_bloqueado or selecionado != null:
        info.text = "Entre na loja e conclua a edicao antes de comprar."
        return
    var preco := int(SPRITES.dados(id)["preco"]) if estoque < 0 else 0
    if money < preco:
        info.text = "Dinheiro insuficiente."
        return
    recuperando = estoque
    var angle := int(guardados[estoque]["angulo"]) if estoque >= 0 else 0
    selecionado = _create_furniture(id,_snap(pos_player + Vector2(-96,-48)),angle)
    comprando = true
    selecionado.iniciar_edicao()
    edit_bar.visible = true
    selecionado.indicar_validade(_can_place(selecionado))
    _stop_input()
    info.text = "Arraste no piso. Girar troca a vista; OK confirma."

func _create_furniture(id: String, at: Vector2, angle: int) -> MOVEL:
    var movel := MOVEL.new()
    movel.configurar(id,at,angle)
    add_child(movel)
    movel.visible = indoors
    moveis.append(movel)
    return movel

func _edit_action(action: String) -> void:
    if selecionado == null or transitioning or save_bloqueado:
        return
    match action:
        "Mover", "Girar":
            if action == "Girar" and SPRITES.orientacoes_disponiveis(selecionado.item_id).size() < 2:
                info.text = "Este sprite tem uma vista. Giro aguarda arte adicional."
                return
            if not selecionado.em_edicao:
                selecionado.iniciar_edicao()
            if action == "Girar":
                selecionado.girar()
            selecionado.indicar_validade(_can_place(selecionado))
            _stop_input()
            info.text = "Arraste o movel; OK confirma; Cancelar desfaz."
        "Cancelar":
            _cancel_edit()
        "OK":
            if not _can_place(selecionado):
                info.text = "Posicao invalida: libere piso, jogador e saida."
                return
            if comprando and recuperando < 0:
                var preco := int(SPRITES.dados(selecionado.item_id)["preco"])
                if money < preco:
                    info.text = "Dinheiro insuficiente."
                    return
                money -= preco
            if recuperando >= 0:
                guardados.remove_at(recuperando)
                recuperando = -1
            selecionado.confirmar()
            selecionado = null
            comprando = false
            recuperando = -1
            edit_bar.hide()
            _stop_input()
            _refresh()
            if _save():
                info.text = "Movel posicionado e salvo."
        "Vender":
            if comprando:
                _cancel_edit()
                return
            var dados := SPRITES.dados(selecionado.item_id)
            money += int(dados.get("revenda",int(dados["preco"]) / 2))
            moveis.erase(selecionado)
            selecionado.queue_free()
            selecionado = null
            edit_bar.hide()
            _stop_input()
            _refresh()
            if _save():
                info.text = "Movel vendido e progresso salvo."

func _cancel_edit() -> void:
    if selecionado == null:
        return
    if comprando:
        moveis.erase(selecionado)
        selecionado.queue_free()
    else:
        selecionado.cancelar()
    selecionado = null
    comprando = false
    edit_bar.hide()
    _stop_input()
    info.text = "Edicao cancelada; nada foi cobrado ou alterado."

func _interact() -> void:
    if transitioning or popup.visible or save_bloqueado:
        return
    if selecionado != null:
        _edit_action("OK")
    elif indoors and pos_player.distance_to(cadastro["saida_interna"]) < 80:
        _change_area(false)
    elif not indoors and pos_player.distance_to(cadastro["porta_externa"]) < 85:
        _change_area(true)
    elif not indoors and pos_player.distance_to(BAIRRO.porta_cafe()) < 85:
        info.text = "Cafeteria | Fachada em teste; interior ainda indisponivel."
    elif not indoors and not bairro.vizinhanca.loja_proxima(pos_player).is_empty():
        info.text = bairro.vizinhanca.loja_proxima(pos_player) + " | Em breve; interior ainda indisponivel."
    elif not indoors and pos_player.distance_to(pos_customer) < 95:
        route_wait = 1.5
        info.text = "Cliente: Ola! Procuro um computador."
    else:
        info.text = "Aproxime-se da porta ou do cliente e pressione A."

func _stop_input() -> void:
    move = Vector2.ZERO
    finger = -1
    drag_finger = -1

func _change_area(enter: bool) -> void:
    if transitioning or enter == indoors:
        return
    if selecionado != null:
        info.text = "Confirme ou cancele a edicao antes de sair."
        return
    transitioning = true
    _stop_input()
    if not enter and not _save():
        transitioning = false
        return
    if enter:
        await porta.animar(true)
    await _fade_to(1.0)
    var dados: Dictionary = gestor_imoveis.entrar(LOJA_ID) if enter else gestor_imoveis.sair()
    if dados.is_empty():
        info.text = "Erro ao localizar imovel."
        await _fade_to(0.0)
        transitioning = false
        return
    indoors = enter
    bairro.visible = not enter
    sala.visible = enter
    exit_marker.visible = enter
    customer.visible = not enter
    porta.visible = false
    pos_player = dados["entrada_interna"] if enter else dados["saida_externa"]
    player.position = pos_player
    player.z_index = int(pos_player.y)
    cam.position = pos_player
    cam.reset_smoothing()
    if enter:
        _restore_furniture()
        _camera_interior()
    else:
        for movel in moveis:
            movel.queue_free()
        moveis.clear()
        _camera_exterior()
        porta.abertura = 1.0
        porta.visible = true
    await _fade_to(0.0)
    if not enter:
        await porta.animar(false)
    info.text = "Interior | Loja compra; toque no movel para editar." if enter else "Rua | Use as faixas para atravessar. A na PC Store entra."
    if enter and not guardados.is_empty():
        info.text = "Moveis preservados: Loja > Recuperar, sem custo."
    transitioning = false

func _fade_to(alpha: float) -> void:
    var tween := create_tween()
    tween.tween_property(fade,"color:a",alpha,0.18)
    await tween.finished

func _restore_furniture() -> void:
    for movel in moveis:
        movel.queue_free()
    moveis.clear()
    var estado := gestor_imoveis.carregar_estado(LOJA_ID)
    if estado.is_empty():
        estado = {"moveis":[],"guardados":[]}
    guardados = estado.get("guardados",[]).duplicate(true)
    for dados in estado.get("moveis",[]):
        var coords: Array = dados["posicao"]
        _create_furniture(dados["id"],Vector2(coords[0],coords[1]),int(dados["angulo"]))

func _populate_shop() -> void:
    for child in shop_list.get_children():
        shop_list.remove_child(child)
        child.queue_free()
    for i in range(guardados.size()):
        var id: String = guardados[i]["id"]
        var nome: String = SPRITES.dados(id).get("nome",id)
        _button("Recuperar: " + nome,_buy.bind(id,i),shop_list)
    for id in SPRITES.ITENS:
        var dados: Dictionary = SPRITES.ITENS[id]
        if not dados.get("isometrico",false):
            continue
        _button("%s | R$ %d" % [dados["nome"],dados["preco"]],_buy.bind(id),shop_list)

func _refresh() -> void:
    top_label.text = "PIXEL PC TYCOON | R$ " + str(money)

func _menu(label: String) -> void:
    if transitioning or save_bloqueado:
        return
    if label == "Loja":
        if not indoors:
            info.text = "Entre na PC Store para comprar moveis."
        elif selecionado != null:
            info.text = "Confirme ou cancele a edicao atual."
        else:
            _stop_input()
            _populate_shop()
            popup.popup_centered(Vector2i(370,380))
    elif label == "Cliente":
        info.text = "Na rua, aproxime-se do cliente e pressione A."
    else:
        info.text = label + " - integracao pendente"

func _save() -> bool:
    if save_bloqueado:
        return false
    if indoors:
        var itens: Array[Dictionary] = []
        for movel in moveis:
            if movel == selecionado and comprando:
                continue
            itens.append(movel.serializar())
        gestor_imoveis.salvar_estado(LOJA_ID,{"moveis":itens,"guardados":guardados})
    if not gestor_imoveis.gravar(money,save_path):
        info.text = "ERRO: progresso nao salvo. " + gestor_imoveis.ultimo_erro
        return false
    return true

func _load() -> void:
    var dados := gestor_imoveis.ler(save_path,legacy_path)
    if dados.is_empty():
        save_bloqueado = true
        info.text = "ERRO NO SAVE: arquivo preservado. " + gestor_imoveis.ultimo_erro
        return
    money = int(dados["dinheiro"])
    if not gestor_imoveis.aviso.is_empty():
        info.text = gestor_imoveis.aviso

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
        _stop_input()
        if is_node_ready():
            _save()
