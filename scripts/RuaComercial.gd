extends Node2D

const BAIRRO = preload("res://scripts/BairroComercial.gd")
const CATALOGO = preload("res://scripts/Imoveis/CatalogoImoveis.gd")
const SPRITES = preload("res://scripts/Imoveis/CatalogoSprites.gd")
const GERENCIADOR = preload("res://scripts/Imoveis/GerenciadorImoveis.gd")
const MOVEL = preload("res://scripts/Moveis/MovelIsometrico.gd")
const PORTA = preload("res://scripts/PortaLoja.gd")
const PERSONAGEM = preload("res://scripts/PersonagemAnimado.gd")
const INTERIOR = preload("res://scripts/Imoveis/InteriorModular.gd")
const PARTIDAS = preload("res://scripts/Partidas.gd")
const NAVEGACAO = preload("res://scripts/Imoveis/NavegacaoInterior.gd")
const COMERCIO = preload("res://scripts/Comercio.gd")
const PECAS = preload("res://scripts/CatalogoPecas.gd")
const CARTAO = preload("res://scripts/CartaoPeca.gd")
const CALENDARIO = preload("res://scripts/CalendarioEconomia.gd")
const CLIENTES = preload("res://scripts/Clientes.gd")
const JOGOS = preload("res://scripts/CatalogoJogos.gd")
const EQUIPE = preload("res://scripts/Equipe.gd")
const AMBIENTE = preload("res://scripts/Ambiente.gd")
const CAMPANHA = preload("res://scripts/Campanha.gd")
const CAMERA_GESTOS = preload("res://scripts/CameraGestos.gd")
const EVOLUCAO = preload("res://scripts/Evolucao.gd")
const REFORMA = preload("res://scripts/Reforma.gd")
const INTERFACE = preload("res://scripts/InterfaceJogo.gd")
const MUNDO_VIVO = preload("res://scripts/MundoVivo.gd")
const LOJA_ID := "pc_store_001"

var cadastro: Dictionary = CATALOGO.buscar(LOJA_ID)
var gestor_imoveis: GERENCIADOR = GERENCIADOR.new()
var save_path: String = GERENCIADOR.SAVE_PATH
var legacy_path: String = GERENCIADOR.LEGACY_PATH
var partidas: PARTIDAS = PARTIDAS.new()
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
var motivo_construcao := ""
var loja: COMERCIO = COMERCIO.new()
var cliente_rota := PackedVector2Array()
var cliente_fase_visual := ""
var cliente_rota_valida := false
var cliente_espera := 0.0
var entrega_botoes: Dictionary = {}
var painel_atual := ""
var mensagem_comercial := ""
var relogio: CALENDARIO = CALENDARIO.new()
var relogio_bloqueado := false
var clientes: CLIENTES = CLIENTES.new()
var fila_visuais: Array[PERSONAGEM] = []
var fila_labels: Dictionary = {}
var equipe: EQUIPE = EQUIPE.new()
var equipe_visuais: Array[PERSONAGEM] = []
var cliente_tempo_oculto := 0.0
var unidade_id := LOJA_ID
var iluminacao: CanvasModulate
var ambiente: AMBIENTE
var gestos: CAMERA_GESTOS = CAMERA_GESTOS.new()
var porta_botao: Button
var evolucao: Dictionary = EVOLUCAO.inicial()
var acabamentos: Dictionary = {}
var app_pausado := false
var mundo_vivo: MUNDO_VIVO

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
    iluminacao = CanvasModulate.new()
    add_child(iluminacao)
    var clima_layer := CanvasLayer.new()
    clima_layer.layer = 0
    add_child(clima_layer)
    ambiente = AMBIENTE.new()
    clima_layer.add_child(ambiente)
    _hud()
    get_viewport().size_changed.connect(_layout)
    _layout()
    partidas.configurar(save_path,legacy_path)
    if partidas.ler_selecao():
        save_path = partidas.caminho(partidas.atual)
        legacy_path = partidas.caminho_legado(partidas.atual)
    else:
        save_bloqueado = true
        info.text = partidas.ultimo_erro
        _refresh()
        return
    _load()
    mundo_vivo = MUNDO_VIVO.new()
    add_child(mundo_vivo)
    # Sincroniza a simulacao urbana com a aparencia inicial do bairro.
    mundo_vivo.definir_previa(bairro.previa_visual)
    if not mundo_vivo.configurar(bairro):
        info.text = "ERRO: nao foi possivel configurar a circulacao do bairro."
    mundo_vivo.pedestre_chegou_loja.connect(_cliente_da_rua)
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
            if movel.item_id == "porta_interna" and movel.porta_aberta:
                continue
            if movel == selecionado and comprando:
                continue
            var ponto := movel.posicao_confirmada if movel.em_edicao else movel.position
            if Geometry2D.is_point_in_polygon(at,movel.poligono_colisao(ponto,8,movel.em_edicao)):
                return false
    return true

func _physics_process(delta: float) -> void:
    if app_pausado:
        return
    mundo_vivo.definir_suspensao(indoors or transitioning,selecionado != null,save_bloqueado)
    mundo_vivo.avancar(delta,float(relogio.estado["segundos"]),AMBIENTE.previsao(int(relogio.estado["dia"])))
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
    if not save_bloqueado and not transitioning:
        if _avancar_simulacao(delta):
            _atualizar_entregas()
            if indoors:
                _cliente_comercial(delta)
            _processar_funcionarios(delta)
    if not indoors and not gestos.livre:
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
    top_label.add_theme_font_size_override("font_size",14)
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
    for label in ["Loja","Cliente","Montagem","Estoque","Financas","Menu"]:
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
    porta_botao = _button("Porta",_edit_action.bind("Porta"),edit_bar)
    porta_botao.visible = false
    edit_bar.visible = false
    fade = ColorRect.new()
    fade.color = Color(0,0,0,0)
    fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(fade)

func _layout() -> void:
    var size := get_viewport_rect().size
    var area := Rect2(Vector2.ZERO,size)
    if OS.get_name() == "Android":
        area = INTERFACE.area_util(size,Vector2(DisplayServer.screen_get_size()),Rect2(DisplayServer.get_display_safe_area()))
    var header := layer.get_node("Header") as Control
    header.position = area.position + Vector2(6,6)
    header.size = Vector2(area.size.x - 12,82)
    info.custom_minimum_size.x = maxf(0,area.size.x-24)
    var menu := layer.get_node("Menu") as Control
    menu.position = area.position + Vector2(6,area.size.y - 66)
    menu.size = Vector2(area.size.x - 12,58)
    var pad := layer.get_node("Pad") as Control
    pad.position = area.position + Vector2(18,area.size.y - 187)
    pad.size = Vector2(108,108)
    (pad.get_node("Arrows") as Control).size = pad.size
    pad_center = pad.position + pad.size * 0.5
    var action := layer.get_node("Action") as Control
    action.position = area.position + Vector2(area.size.x - 104,area.size.y - 166)
    action.size = Vector2(75,75)
    edit_bar.position = area.position + Vector2(6,100)
    edit_bar.size = Vector2(area.size.x - 12,48)
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
    gestos.configurar(cam,bounds,viewport)

func _camera_exterior() -> void:
    var bounds := BAIRRO.limites()
    cam.zoom = Vector2(0.65,0.65)
    cam.limit_left = int(bounds.position.x)
    cam.limit_top = int(bounds.position.y)
    cam.limit_right = int(bounds.end.x)
    cam.limit_bottom = int(bounds.end.y)
    cam.force_update_scroll()
    gestos.configurar(cam,bounds,get_viewport_rect().size)

func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and not event.pressed:
        gestos.soltar(event.index)
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
        gestos.soltar(-3)
    if not transitioning and not popup.visible and not save_bloqueado and not (selecionado != null and selecionado.em_edicao):
        var arrastou := false
        if event is InputEventScreenDrag and event.index != finger and event.index != drag_finger:
            arrastou = gestos.mover(event.index,event.position)
        elif event is InputEventMouseMotion and gestos.toques.has(-3):
            arrastou = gestos.mover(-3,event.position)
        if arrastou:
            selecionado = null
            edit_bar.hide()
            get_viewport().set_input_as_handled()
            return
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
        if event.index != finger and event.index != drag_finger and not (selecionado != null and selecionado.em_edicao):
            gestos.pressionar(event.index,event.position)
    elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed and event.device != -1:
        _pointer_down(event.position,-2)
    elif event is InputEventMouseButton and event.pressed and not (selecionado != null and selecionado.em_edicao):
        if event.button_index == MOUSE_BUTTON_RIGHT:
            gestos.pressionar(-3,event.position)
        elif event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
            gestos.ampliar(1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0/1.15,event.position,event.position)
    elif event is InputEventMagnifyGesture and not (selecionado != null and selecionado.em_edicao):
        gestos.ampliar(event.factor,event.position,event.position)
    elif event is InputEventPanGesture and not (selecionado != null and selecionado.em_edicao):
        gestos.deslocar(event.delta * 8.0)

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
    porta_botao.visible = selecionado != null and selecionado.item_id == "porta_interna"
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
    motivo_construcao = "Posicao invalida: libere piso, jogador e saida."
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
    var navegacao := _navegacao(movel)
    for ponto in [pos_player,cadastro["entrada_interna"]]:
        if navegacao.caminho_ate(ponto).is_empty():
            motivo_construcao = "Construcao bloqueada: mantenha uma rota entre jogador, entrada e saida."
            return false
    if not loja.estado["cliente"].is_empty() and customer.visible:
        if Geometry2D.is_point_in_polygon(customer.position,movel.poligono_colisao(movel.position,24)) or navegacao.caminho_ate(customer.position).is_empty():
            motivo_construcao = "Construcao bloqueada: mantenha o cliente livre e com acesso a saida."
            return false
    for pessoa in fila_visuais + equipe_visuais:
        if Geometry2D.is_point_in_polygon(pessoa.position,movel.poligono_colisao(movel.position,24)) or navegacao.caminho_ate(pessoa.position).is_empty():
            motivo_construcao = "Construcao bloqueada: mantenha a fila livre e com acesso a saida."
            return false
    for estacao in moveis:
        if _eh_estacao(estacao) and navegacao.caminho_ate(estacao.position,85).is_empty():
            motivo_construcao = "Construcao bloqueada: mantenha acesso a " + str(SPRITES.dados(estacao.item_id).get("nome",estacao.item_id))
            return false
    motivo_construcao = ""
    return true

func _eh_estacao(movel: MOVEL) -> bool:
    return movel.item_id in ["balcao_atendimento","balcao_pc_store","balcao_simples","bancada_montagem_com_computador","mesa_notebook_com_cadeira","prateleira_componentes","estante_metalica_estoque","armario_pecas_gavetas","caixa_registradora"]

func _navegacao(candidato: MOVEL = null, inicio: Vector2 = Vector2.INF) -> NAVEGACAO:
    var formas: Array[PackedVector2Array] = []
    for movel in moveis:
        if movel == selecionado and comprando and movel != candidato:
            continue
        if movel.item_id == "porta_interna" and movel.porta_aberta and movel != candidato:
            continue
        var confirmado := movel != candidato and movel.em_edicao
        formas.append(movel.poligono_colisao(movel.posicao_confirmada if confirmado else movel.position,8,confirmado))
    var navegacao := NAVEGACAO.new()
    navegacao.configurar(cadastro,formas,cadastro["saida_interna"] if inicio == Vector2.INF else inicio)
    return navegacao

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
    if action == "Porta":
        _alternar_porta()
        return
    if selecionado == null or transitioning or save_bloqueado:
        return
    match action:
        "Mover", "Girar":
            if action == "Girar" and SPRITES.orientacoes_disponiveis(selecionado.item_id).size() < 2:
                info.text = "Este movel so possui um angulo. O balcao PC Store ja permite girar em 4 direcoes."
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
                info.text = motivo_construcao
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
            _recalcular_cliente()
            if _save():
                info.text = "Movel posicionado e salvo."
                _atualizar_funcionarios()
        "Vender":
            if comprando:
                _cancel_edit()
                return
            if not loja.estado["cliente"].is_empty() and (_tipo_estacao(selecionado) == "balcao" or (_tipo_estacao(selecionado) == "bancada" and loja.estado["cliente"]["tipo"] in ["pc","servico"])):
                info.text = "Conclua o atendimento antes de vender esta estacao."
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
                _atualizar_funcionarios()

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
        _edit_action("Porta" if selecionado.item_id == "porta_interna" and not selecionado.em_edicao else "OK")
    elif indoors and pos_player.distance_to(cadastro["saida_interna"]) < 80:
        _change_area(false)
    elif not indoors and pos_player.distance_to(CATALOGO.buscar(LOJA_ID)["porta_externa"]) < 85:
        _change_area(true,LOJA_ID)
    elif not indoors and pos_player.distance_to(CATALOGO.buscar("pc_store_002")["porta_externa"]) < 85:
        if gestor_imoveis.estados.has("pc_store_002"):
            _change_area(true,"pc_store_002")
        else:
            _abrir_imovel()
    elif not indoors and pos_player.distance_to(BAIRRO.porta_cafe()) < 85:
        info.text = "Cafeteria | Fachada em teste; interior ainda indisponivel."
    elif not indoors and not bairro.vizinhanca.loja_proxima(pos_player).is_empty():
        info.text = bairro.vizinhanca.loja_proxima(pos_player) + " | Em breve; interior ainda indisponivel."
    elif not indoors and pos_player.distance_to(pos_customer) < 95:
        route_wait = 1.5
        info.text = "Cliente: Ola! Procuro um computador."
    elif indoors:
        for movel in moveis:
            if movel.item_id == "porta_interna" and pos_player.distance_to(movel.position) < 90:
                selecionado = movel
                _alternar_porta()
                return
        var tipo := _estacao_mais_proxima()
        match tipo:
            "balcao": _abrir_cliente()
            "bancada": _abrir_montagem()
            "notebook": _abrir_estoque()
            _: info.text = "Aproxime-se do balcao, notebook ou bancada."
    else:
        info.text = "Aproxime-se da porta ou do cliente e pressione A."

func _stop_input() -> void:
    gestos.limpar()
    move = Vector2.ZERO
    finger = -1
    drag_finger = -1

func _change_area(enter: bool, destino: String = "") -> void:
    if transitioning or enter == indoors:
        return
    if selecionado != null:
        info.text = "Confirme ou cancele a edicao antes de sair."
        return
    if enter:
        destino = unidade_id if destino.is_empty() else destino
        if destino != LOJA_ID and not gestor_imoveis.estados.has(destino):
            info.text = "Compre o imovel pela entrada das Salas comerciais."
            return
        if destino != unidade_id:
            if not loja.estado["cliente"].is_empty() or not clientes.estado["fila"].is_empty():
                info.text = "Conclua atendimentos e fila antes de mudar a unidade ativa."
                return
            var anterior := unidade_id
            _definir_unidade(destino)
            if not _save():
                _definir_unidade(anterior)
                return
    transitioning = true
    _stop_input()
    if not enter and not _save():
        transitioning = false
        return
    if enter and unidade_id == LOJA_ID:
        await porta.animar(true)
    await _fade_to(1.0)
    var dados: Dictionary = gestor_imoveis.entrar(unidade_id) if enter else gestor_imoveis.sair()
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
    if not enter:
        customer.position = pos_customer
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
        porta.visible = unidade_id == LOJA_ID
    await _fade_to(0.0)
    if not enter and unidade_id == LOJA_ID:
        await porta.animar(false)
    info.text = "Interior | Loja compra; toque no movel para editar." if enter else "Rua | Use as faixas para atravessar. A na PC Store entra."
    if enter and not guardados.is_empty():
        info.text = "Moveis preservados: Loja > Recuperar, sem custo."
    cliente_fase_visual = ""
    if enter:
        _preparar_cliente()
    else:
        _atualizar_fila_visual()
    _atualizar_funcionarios()
    _atualizar_ambiente()
    transitioning = false

func _fade_to(alpha: float) -> void:
    var tween := create_tween()
    tween.tween_property(fade,"color:a",alpha,0.18)
    await tween.finished

func _restore_furniture() -> void:
    for movel in moveis:
        movel.queue_free()
    moveis.clear()
    var estado := gestor_imoveis.carregar_estado(unidade_id)
    if estado.is_empty():
        estado = {"moveis":[],"guardados":[]}
    guardados = estado.get("guardados",[]).duplicate(true)
    for dados in estado.get("moveis",[]):
        var coords: Array = dados["posicao"]
        var movel := _create_furniture(dados["id"],Vector2(coords[0],coords[1]),int(dados["angulo"]))
        if movel.item_id == "porta_interna":
            movel.porta_aberta = dados.get("aberta",false)
            movel._atualizar()

func _populate_shop() -> void:
    for child in shop_list.get_children():
        shop_list.remove_child(child)
        child.queue_free()
    _button("Ampliar planta e consultar imoveis",_abrir_imovel,shop_list)
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
    var data := relogio.data()
    top_label.text = "PC TYCOON | Slot %d | R$ %d\n%02d/%02d/%d | %02d:%02d%s" % [partidas.atual,money,data["dia"],data["mes"],data["ano"],data["hora"],data["minuto"]," | PAUSADO" if _tempo_pausado() else ""]
    _atualizar_ambiente()

func _limpar_painel(titulo: String) -> void:
    _stop_input()
    popup.title = titulo
    entrega_botoes.clear()
    fila_labels.clear()
    (shop_list.get_parent() as ScrollContainer).scroll_vertical = 0
    for child in shop_list.get_children():
        shop_list.remove_child(child)
        child.queue_free()

func _salvar_manual() -> void:
    if _save():
        relogio_bloqueado = false
        _refresh()
        info.text = "Slot %d salvo manualmente." % partidas.atual

func _trocar_slot(slot: int) -> void:
    if slot < 1 or slot > 3:
        info.text = "Slot invalido: escolha de 1 a 3."
        return
    if transitioning or selecionado != null:
        info.text = "Conclua ou cancele a edicao antes de trocar de partida."
        return
    if not save_bloqueado and not _save():
        return
    var candidato := GERENCIADOR.new()
    var dados := candidato.ler(partidas.caminho(slot),partidas.caminho_legado(slot))
    if dados.is_empty():
        info.text = "Slot %d nao carregado. %s" % [slot,candidato.ultimo_erro]
        return
    if not partidas.selecionar(slot):
        info.text = partidas.ultimo_erro
        return
    popup.hide()
    fila_labels.clear()
    entrega_botoes.clear()
    painel_atual = ""
    _stop_input()
    for movel in moveis:
        movel.queue_free()
    moveis.clear()
    guardados.clear()
    gestor_imoveis = candidato
    _definir_unidade(gestor_imoveis.unidade_id)
    save_path = partidas.caminho(slot)
    legacy_path = partidas.caminho_legado(slot)
    save_bloqueado = false
    money = int(dados["dinheiro"])
    loja.carregar(dados.get("comercio",COMERCIO.inicial()))
    relogio.carregar(dados.get("calendario",CALENDARIO.inicial(loja.resumo())))
    _carregar_clientes(dados)
    equipe.carregar(dados.get("equipe",EQUIPE.inicial()))
    evolucao = dados.get("evolucao",EVOLUCAO.inicial()).duplicate(true)
    player.personalizar(int(evolucao["aparencia"]))
    relogio_bloqueado = false
    cliente_fase_visual = ""
    cliente_rota.clear()
    mensagem_comercial = ""
    indoors = false
    bairro.visible = true
    sala.visible = false
    exit_marker.visible = false
    customer.visible = true
    customer.position = pos_customer
    _atualizar_fila_visual()
    _atualizar_funcionarios()
    porta.visible = false
    pos_player = cadastro["saida_externa"]
    player.position = pos_player
    player.z_index = int(pos_player.y)
    _camera_exterior()
    _refresh()
    info.text = "Slot %d carregado. %s" % [slot,candidato.aviso]

func _menu(label: String) -> void:
    if transitioning or (save_bloqueado and label != "Menu"):
        return
    if label == "Menu":
        if selecionado != null:
            info.text = "Conclua ou cancele a edicao antes de abrir as partidas."
            return
        _limpar_painel("Partidas e salvamento")
        if not save_bloqueado:
            _button("Salvar agora - Slot %d" % partidas.atual,_salvar_manual,shop_list)
        for slot in range(1,4):
            var existe := FileAccess.file_exists(partidas.caminho(slot)) or FileAccess.file_exists(partidas.caminho(slot) + ".bak")
            _button("Slot %d - %s%s" % [slot,"Continuar" if existe else "Nova partida"," (atual)" if slot == partidas.atual else ""],_trocar_slot.bind(slot),shop_list)
        popup.popup_centered(Vector2i(370,380))
        return
    if label == "Loja":
        if not indoors:
            info.text = "Entre na PC Store para comprar moveis."
        elif selecionado != null:
            info.text = "Confirme ou cancele a edicao atual."
        else:
            _stop_input()
            popup.title = "Moveis e equipamentos"
            _populate_shop()
            popup.popup_centered(Vector2i(370,380))
    elif label == "Cliente":
        _abrir_cliente()
    elif label == "Estoque":
        _abrir_estoque()
    elif label == "Montagem":
        _abrir_montagem()
    elif label == "Financas":
        _abrir_financas()
    else:
        info.text = label + " - integracao pendente"

func _save() -> bool:
    if save_bloqueado:
        return false
    if not EVOLUCAO.validar(evolucao):
        info.text = "ERRO: objetivos/tutorial/aparencia invalidos; progresso preservado."
        return false
    if indoors:
        var itens: Array[Dictionary] = []
        for movel in moveis:
            if movel == selecionado and comprando:
                continue
            itens.append(movel.serializar())
        gestor_imoveis.salvar_estado(unidade_id,{"moveis":itens,"guardados":guardados,"nivel":cadastro["nivel"],"acabamentos":acabamentos.duplicate(true)})
    gestor_imoveis.unidade_id = unidade_id
    loja.estado["campanha"]["nivel"] = _nivel_campanha()
    gestor_imoveis.comercio = loja.estado.duplicate(true)
    gestor_imoveis.calendario = relogio.estado.duplicate(true)
    gestor_imoveis.clientes = clientes.estado.duplicate(true)
    gestor_imoveis.equipe = equipe.estado.duplicate(true)
    var evolucao_anterior := evolucao.duplicate(true)
    var objetivos := EVOLUCAO.OBJETIVOS.new()
    objetivos.carregar(evolucao["objetivos"])
    objetivos.atualizar(loja.estado,clientes.estado,equipe.estado,int(relogio.estado["dia"]))
    evolucao["objetivos"] = objetivos.estado.duplicate(true)
    gestor_imoveis.evolucao = evolucao.duplicate(true)
    if not gestor_imoveis.gravar(money,save_path):
        evolucao = evolucao_anterior
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
    evolucao = dados.get("evolucao",EVOLUCAO.inicial()).duplicate(true)
    player.personalizar(int(evolucao["aparencia"]))
    _definir_unidade(gestor_imoveis.unidade_id)
    if not loja.carregar(dados.get("comercio",COMERCIO.inicial())):
        save_bloqueado = true
        info.text = loja.ultimo_erro
        return
    if not relogio.carregar(dados.get("calendario",CALENDARIO.inicial(loja.resumo()))):
        save_bloqueado = true
        info.text = relogio.ultimo_erro
        return
    if not _carregar_clientes(dados):
        save_bloqueado = true
        info.text = clientes.ultimo_erro
        return
    if not equipe.carregar(dados.get("equipe",EQUIPE.inicial())):
        save_bloqueado = true
        info.text = equipe.ultimo_erro
        return
    if not gestor_imoveis.aviso.is_empty():
        info.text = gestor_imoveis.aviso

func _tipo_estacao(movel: MOVEL) -> String:
    return _tipo_item(movel.item_id)

func _tipo_item(id: String) -> String:
    if id in ["balcao_atendimento","balcao_pc_store","balcao_simples"]:
        return "balcao"
    if id == "bancada_montagem_com_computador":
        return "bancada"
    if id == "mesa_notebook_com_cadeira":
        return "notebook"
    return ""

func _estacao(tipo: String) -> MOVEL:
    for movel in moveis:
        if _tipo_estacao(movel) == tipo and not (movel == selecionado and comprando):
            return movel
    return null

func _perto_estacao(tipo: String) -> bool:
    for movel in moveis:
        if _tipo_estacao(movel) == tipo and pos_player.distance_to(movel.position) <= 120:
            return true
    return false

func _estacao_mais_proxima() -> String:
    var tipo := ""
    var distancia := 120.0
    for movel in moveis:
        var candidato := _tipo_estacao(movel)
        var atual := pos_player.distance_to(movel.position)
        if not candidato.is_empty() and atual <= distancia:
            tipo = candidato
            distancia = atual
    return tipo

func _comercio_disponivel() -> bool:
    if not indoors or transitioning or save_bloqueado or selecionado != null:
        info.text = "Entre na loja e conclua a edicao para usar o comercio."
        return false
    return true

func _texto_painel(texto: String) -> Label:
    var label := Label.new()
    label.text = texto
    label.custom_minimum_size.x = 320
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size",13)
    shop_list.add_child(label)
    return label

func _abrir_estoque() -> void:
    if not _comercio_disponivel():
        return
    painel_atual = "Estoque"
    _limpar_painel("Estoque e fornecedor offline")
    _texto_painel("Compras: aproxime-se da mesa com notebook. Prazo: 30 s de jogo ativo; receber nao cobra novamente.")
    if not mensagem_comercial.is_empty():
        _texto_painel(mensagem_comercial)
    var totais := loja.resumo()
    _texto_painel("Compras R$ %d | Receita R$ %d\nCMV R$ %d | Lucro bruto R$ %d" % [totais["compras"],totais["receita"],totais["cmv"],totais["lucro"]])
    _texto_painel("Tecnologia nivel %d | Reputacao %d/100\nN2: 2 PCs ou receita 5000, reputacao 45.\nN3: 5 PCs ou receita 15000, reputacao 60.\nDesbloqueios e aquisicoes antigas sao preservados." % [_nivel_campanha(),clientes.estado["reputacao"]])
    for fornecedor in CAMPANHA.FORNECEDORES:
        var oferta: Dictionary = CAMPANHA.FORNECEDORES[fornecedor]
        var botao := _button("%s - %d s%s" % [oferta["nome"],oferta["prazo"]," (selecionado)" if loja.estado["campanha"]["fornecedor"] == fornecedor else ""],_operacao_comercial.bind("fornecedor",fornecedor),shop_list)
        botao.disabled = int(oferta["nivel"]) > _nivel_campanha()
    for pedido: Dictionary in loja.estado["pedidos"]:
        if pedido["recebido"]:
            continue
        var id := int(pedido["id"])
        entrega_botoes[id] = _button("",_operacao_comercial.bind("receber",str(id)),shop_list)
    _atualizar_entregas()
    for id in PECAS.PECAS:
        var dados: Dictionary = PECAS.PECAS[id]
        var botao := _button("%s x%d | Comprar 1: R$ %d%s" % [dados["nome"],loja.quantidade(id),dados["custo"]," (bloqueado/fornecedor)" if not _compra_liberada(id) else ""],_operacao_comercial.bind("comprar",id),shop_list)
        botao.disabled = not _compra_liberada(id)
    popup.popup_centered(Vector2i(370,460))

func _atualizar_entregas() -> void:
    for pedido: Dictionary in loja.estado["pedidos"]:
        var id := int(pedido["id"])
        if not entrega_botoes.has(id):
            continue
        var botao: Button = entrega_botoes[id]
        botao.text = "%s #%d: %s" % [PECAS.PECAS[pedido["peca"]]["nome"],id,"Receber" if float(pedido["restante"]) <= 0 else "%d s" % ceili(float(pedido["restante"]))]
        botao.disabled = pedido["recebido"] or float(pedido["restante"]) > 0

func _abrir_cliente() -> void:
    if not _comercio_disponivel():
        return
    painel_atual = "Cliente"
    _limpar_painel("Atendimento no balcao")
    if not mensagem_comercial.is_empty():
        _texto_painel(mensagem_comercial)
    var atual: String = clientes.estado["atual"]
    if not atual.is_empty():
        var perfil: Dictionary = clientes.estado["perfis"][atual]
        fila_labels[atual] = _texto_painel("%s | Prefere %s | Orcamento R$ %d\nPaciencia: %d s | Fidelidade %d" % [perfil["nome"],perfil["preferencia"],perfil["orcamento"],ceili(float(perfil["restante"])),perfil["fidelidade"]])
    for id in clientes.estado["fila"]:
        var perfil: Dictionary = clientes.estado["perfis"][id]
        fila_labels[id] = _texto_painel("Fila: %s | %s | R$ %d | %d s" % [perfil["nome"],perfil["preferencia"],perfil["orcamento"],ceili(float(perfil["restante"]))])
    _button("Historico dos clientes",_abrir_historico_clientes,shop_list)
    _button("Assistencia tecnica / OS",_abrir_servicos,shop_list)
    var cliente: Dictionary = loja.estado["cliente"]
    if cliente.is_empty():
        _texto_painel("Chame um cliente para uma peca disponivel ou aceite o primeiro pedido de PC. O cliente caminha ate o balcao.")
        for id in PECAS.PECAS:
            if loja.quantidade(id) > 0:
                _button("Cliente: %s | R$ %d" % [PECAS.PECAS[id]["nome"],PECAS.PECAS[id]["venda"]],_operacao_comercial.bind("cliente",id),shop_list)
        _button("Pedido PC: 8 pecas | Orcamento R$ %d" % PECAS.PRECO_PC,_operacao_comercial.bind("pedido_pc"),shop_list)
        for id in JOGOS.JOGOS:
            var jogo: Dictionary = JOGOS.JOGOS[id]
            var botao := _button("%s | PC R$ %d | N%d" % [jogo["nome"],jogo["orcamento"],CAMPANHA.nivel_jogo(id)],_operacao_comercial.bind("pedido_pc",id),shop_list)
            botao.disabled = not CAMPANHA.jogo_liberado(id,loja.estado["campanha"],_nivel_campanha(),int(relogio.estado["dia"]))
    else:
        var pedido := "PC: " + str(JOGOS.buscar(loja.estado["montagem"].get("jogo",""))["nome"]) if cliente["tipo"] == "pc" else loja.SERVICOS.nome(loja.estado["servico"]) if cliente["tipo"] == "servico" else str(PECAS.PECAS[cliente["produto"]]["nome"])
        _texto_painel("Cliente #%d | %s\nPedido: %s" % [int(cliente["id"]),cliente["fase"],pedido])
        _button("Entregar PC e receber" if cliente["tipo"] == "pc" else "Vender e receber",_operacao_comercial.bind("vender"),shop_list)
    popup.popup_centered(Vector2i(370,420))

func _abrir_montagem() -> void:
    if not _comercio_disponivel():
        return
    if not _perto_estacao("bancada"):
        info.text = "Aproxime-se da bancada de montagem e pressione A ou Montagem."
        return
    painel_atual = "Montagem"
    _limpar_painel("Montagem manual - bancada")
    if not mensagem_comercial.is_empty():
        _texto_painel(mensagem_comercial)
    var montagem: Dictionary = loja.estado["montagem"]
    if montagem.is_empty() or not montagem["fase"] in ["montando","testado"]:
        _texto_painel("Sem montagem ativa. Aceite um pedido no balcao, em Cliente. PCs entregues: %d." % loja.estado["pcs"].size())
        _button("Assistencia tecnica / OS",_abrir_servicos,shop_list)
    else:
        _texto_painel("Pedido #%d | %s | Pecas R$ %d / %d\nArraste ou toque para instalar. O montador automatiza pecas, cabos e teste quando este painel esta fechado." % [int(montagem["id"]),montagem["fase"],loja.custo_pc(),montagem["preco"]])
        var jogo := JOGOS.buscar(montagem.get("jogo",""))
        _texto_painel("%s | CPU %d / GPU %d\nRAM %d GB | SSD %d GB" % [jogo["nome"],jogo["cpu"],jogo["gpu"],jogo["ram"],jogo["ssd"]])
        var diagnostico: Dictionary = montagem.get("diagnostico",{})
        if not diagnostico.is_empty():
            _texto_painel("CPU %.1f C | GPU %.1f C\nConsumo %d W | Margem %d W\nTemperatura: %s | Estabilidade: %s | Desempenho: %s" % [diagnostico["cpu_c"],diagnostico["gpu_c"],diagnostico["consumo_w"],diagnostico["margem_w"],"OK" if diagnostico["temperatura"] else "FALHOU","OK" if diagnostico["estabilidade"] else "FALHOU","OK" if diagnostico["desempenho"] else "FALHOU"])
        for categoria in PECAS.CATEGORIAS:
            var linha := HBoxContainer.new()
            shop_list.add_child(linha)
            var encaixe := CARTAO.new()
            encaixe.name = "Encaixe_" + categoria
            encaixe.categoria = categoria
            encaixe.receber = _instalar_peca
            encaixe.text = categoria + "\n" + str(PECAS.PECAS.get(montagem["pecas"].get(categoria,""),{}).get("nome","Arraste aqui"))
            encaixe.custom_minimum_size = Vector2(150,54)
            encaixe.add_theme_font_size_override("font_size",11)
            encaixe.pressed.connect(_operacao_comercial.bind("remover","",categoria))
            linha.add_child(encaixe)
            var opcoes := VBoxContainer.new()
            opcoes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
            linha.add_child(opcoes)
            for id in PECAS.PECAS:
                if PECAS.PECAS[id]["categoria"] != categoria or loja.quantidade(id) < 1:
                    continue
                var origem := CARTAO.new()
                origem.name = "Peca_" + id
                origem.peca = id
                origem.text = "%s x%d" % [PECAS.PECAS[id]["nome"],loja.quantidade(id)]
                origem.custom_minimum_size.y = 54
                origem.add_theme_font_size_override("font_size",11)
                origem.pressed.connect(_instalar_peca.bind(id,categoria))
                opcoes.add_child(origem)
        _button("1. Conectar cabos" + (" - OK" if montagem["conectado"] else ""),_operacao_comercial.bind("conectar"),shop_list)
        _button("2. Testar boot, temperatura, estabilidade e jogo",_operacao_comercial.bind("testar"),shop_list)
        _button("3. Voltar ao atendimento",_abrir_cliente,shop_list)
        _button("Ver gabinete esquematico",_abrir_gabinete,shop_list)
        _button("Cancelar pedido e devolver pecas",_operacao_comercial.bind("cancelar_pc"),shop_list)
    popup.popup_centered(Vector2i(390,540))

func _instalar_peca(id: String, categoria: String) -> void:
    _operacao_comercial("instalar",id,categoria)

func _operacao_comercial(acao: String, id: String = "", categoria: String = "", funcionario: String = "") -> bool:
    var automatico := not funcionario.is_empty()
    if not automatico and not _comercio_disponivel():
        return false
    if acao == "comprar" and not _compra_liberada(id) or acao == "pedido_pc" and not CAMPANHA.jogo_liberado(id,loja.estado["campanha"],_nivel_campanha(),int(relogio.estado["dia"])):
        info.text = "Tecnologia ainda bloqueada ou fornecedor inadequado; consulte Estoque."
        return false
    var tipo := "bancada" if acao in ["instalar","remover","conectar","testar","cancelar_pc","diagnosticar_os","investigar_os","executar_os","testar_os","retomar_os"] else "notebook" if acao in ["comprar","receber","fornecedor"] else "balcao"
    if automatico and not _funcionario_autorizado(funcionario,acao,tipo):
        info.text = "Funcionario sem atribuicao ou posto disponivel para esta tarefa."
        return false
    if not automatico and acao != "receber" and not _perto_estacao(tipo):
        mensagem_comercial = "Aproxime-se da estacao: " + tipo
        info.text = mensagem_comercial
        _reabrir_comercio.call_deferred()
        return false
    if acao in ["cliente","pedido_pc","abrir_os"] and (_estacao("balcao") == null or (acao in ["pedido_pc","abrir_os"] and _estacao("bancada") == null)):
        info.text = "Instale balcao e bancada para iniciar o atendimento."
        return false
    if not automatico and acao == "vender" and pos_player.distance_to(customer.position) > 120:
        info.text = "Aproxime-se do cliente no balcao para concluir o pagamento."
        return false
    var anterior := loja.estado.duplicate(true)
    var clientes_anteriores := clientes.estado.duplicate(true)
    var saldo := money
    var ok := true
    var delta := 0
    match acao:
        "comprar":
            delta = loja.comprar(id,money,loja.estado["campanha"]["fornecedor"])
            ok = loja.ultimo_erro.is_empty()
        "fornecedor":
            ok = CAMPANHA.FORNECEDORES.has(id) and int(CAMPANHA.FORNECEDORES.get(id,{}).get("nivel",99)) <= _nivel_campanha()
            if ok:
                loja.estado["campanha"]["fornecedor"] = id
            else:
                loja.ultimo_erro = "Fornecedor ainda bloqueado ou inexistente."
        "receber":
            ok = loja.receber(int(id))
        "cliente":
            ok = loja.criar_cliente(id)
        "pedido_pc":
            ok = loja.criar_cliente("",true,id)
        "vender":
            delta = loja.vender()
            ok = loja.ultimo_erro.is_empty()
        "instalar":
            ok = loja.instalar(id,categoria)
        "remover":
            ok = loja.remover(categoria)
        "conectar":
            ok = loja.conectar()
        "testar":
            ok = loja.testar()
        "cancelar_pc":
            ok = loja.cancelar_montagem()
        "abrir_os":
            ok = loja.abrir_os(id,categoria)
        "investigar_os":
            ok = loja.investigar_os(id)
        "diagnosticar_os":
            ok = loja.diagnosticar_os()
        "aprovar_os":
            ok = loja.aprovar_os()
        "executar_os":
            ok = loja.executar_os()
        "testar_os":
            ok = loja.testar_os()
        "cancelar_os":
            ok = loja.cancelar_os()
        "guardar_os":
            ok = loja.estacionar_os()
            if ok:
                loja.estado["fila_os"][-1]["os"]["perfil"] = clientes.estado["atual"]
        "retomar_os":
            ok = loja.retomar_os(int(id))
        "priorizar_os":
            ok = loja.priorizar_os(int(id),int(categoria))
        _:
            info.text = "Operacao comercial desconhecida: " + acao
            return false
    if not ok:
        mensagem_comercial = loja.ultimo_erro
        if acao == "testar" and loja.teste_executado:
            if not _save():
                mensagem_comercial = info.text
                loja.estado = anterior
    else:
        money += delta
        if acao in ["cliente","pedido_pc"]:
            clientes.vincular_manual(id,acao == "pedido_pc",int(loja.estado["montagem"]["preco"]) if acao == "pedido_pc" else int(PECAS.PECAS[id]["venda"]))
            if acao == "pedido_pc":
                clientes.estado["perfis"][clientes.estado["atual"]]["jogo"] = id
        elif acao == "abrir_os":
            clientes.vincular_servico(int(loja.estado["servico"]["preco"]))
            clientes.estado["perfis"][clientes.estado["atual"]]["servico"] = id
            if not categoria.is_empty():
                clientes.estado["perfis"][clientes.estado["atual"]]["caso"] = categoria
        elif acao == "guardar_os":
            clientes.estado["atual"] = ""
        elif acao == "retomar_os":
            clientes.estado["atual"] = loja.estado["servico"].get("perfil","")
        elif acao in ["vender","cancelar_pc","cancelar_os"] and not clientes.estado["atual"].is_empty():
            var atendido: Dictionary = loja.estado["cliente"]
            clientes.finalizar(clientes.estado["atual"],int(relogio.estado["dia"]),"compra" if acao == "vender" else "cancelado",str(atendido["produto"]),delta,int(loja.estado["montagem"].get("id",0)) if atendido["tipo"] == "pc" else 0)
        if money < 0 or money > 2147483647:
            mensagem_comercial = "Operacao excede os limites do saldo."
            ok = false
        elif not _save():
            mensagem_comercial = info.text
            ok = false
            if automatico:
                relogio_bloqueado = true
        else:
            mensagem_comercial = "Operacao salva: " + acao
            if acao == "testar":
                mensagem_comercial = "Boot aprovado. Requisitos atendidos; PC pronto para entregar no balcao."
            if acao in ["cliente","pedido_pc","vender","cancelar_pc","abrir_os","cancelar_os","guardar_os","retomar_os"]:
                cliente_fase_visual = ""
                _preparar_cliente()
            if acao == "vender" and indoors:
                var moeda := Label.new()
                moeda.text = "+ R$ %d" % delta
                moeda.modulate = Color.GOLD
                moeda.position = customer.position - Vector2(25,120)
                moeda.z_index = 4095
                add_child(moeda)
                var tween := create_tween()
                tween.tween_property(moeda,"position:y",moeda.position.y - 35,1.0)
                tween.tween_callback(moeda.queue_free)
    if not ok and not (acao == "testar" and loja.teste_executado):
        loja.estado = anterior
        clientes.estado = clientes_anteriores
        money = saldo
    info.text = mensagem_comercial
    _refresh()
    if popup.visible:
        _reabrir_comercio.call_deferred()
    return ok

func _reabrir_comercio() -> void:
    if not popup.visible:
        return
    match painel_atual:
        "Estoque": _abrir_estoque()
        "Cliente": _abrir_cliente()
        "Montagem": _abrir_montagem()
        "Gabinete": _abrir_gabinete()
        "Servicos": _abrir_servicos()

func _preparar_cliente() -> void:
    _atualizar_fila_visual()
    cliente_rota.clear()
    cliente_rota_valida = false
    var cliente: Dictionary = loja.estado["cliente"]
    customer.visible = not indoors or not cliente.is_empty()
    if not indoors or cliente.is_empty():
        return
    customer.personalizar(int(clientes.estado["atual"].trim_prefix("cliente_")) % 9)
    var balcao := _estacao("balcao")
    if balcao == null:
        info.text = "Cliente aguardando: recoloque um balcao acessivel."
        return
    var nav := _navegacao(null,cadastro["entrada_interna"])
    var atendimento := nav.caminho_ate(balcao.position,85)
    if atendimento.is_empty():
        info.text = "Cliente sem rota ao balcao. Corrija o layout."
        return
    var ponto := atendimento[atendimento.size()-1]
    if cliente_fase_visual.is_empty():
        customer.position = ponto if cliente["fase"] in ["aguardando","saindo"] else Vector2(cadastro["entrada_interna"])
    cliente_fase_visual = cliente["fase"]
    if cliente["fase"] == "saindo":
        cliente_rota = _navegacao(null,customer.position).caminho_ate(cadastro["saida_interna"])
    elif cliente["fase"] == "entrando":
        cliente_rota = _navegacao(null,customer.position).caminho_ate(ponto)
    cliente_rota_valida = cliente["fase"] == "aguardando" or not cliente_rota.is_empty()
    customer.z_index = int(customer.position.y)

func _cliente_comercial(delta: float) -> void:
    if selecionado != null:
        return
    _processar_fila(delta)
    if relogio_bloqueado:
        return
    var cliente: Dictionary = loja.estado["cliente"]
    if cliente.is_empty():
        customer.visible = false
        _atender_fila()
        return
    if cliente_fase_visual != cliente["fase"]:
        _preparar_cliente()
    if not cliente_rota_valida:
        return
    if cliente["fase"] == "aguardando":
        customer.atualizar(Vector2.ZERO,delta)
        return
    if not cliente_rota.is_empty():
        var destino := cliente_rota[0]
        var passo := (destino - customer.position).limit_length(68 * delta)
        customer.position += passo
        customer.atualizar(passo,delta)
        if customer.position.distance_to(destino) < 0.1:
            cliente_rota.remove_at(0)
        return
    var anterior := loja.estado.duplicate(true)
    if cliente["fase"] == "entrando":
        cliente["fase"] = "aguardando"
    else:
        loja.estado["cliente"] = {}
        customer.visible = false
        cliente_espera = 0
    if not _save():
        loja.estado = anterior
        return
    if not loja.estado["cliente"].is_empty():
        mensagem_comercial = "Cliente no balcao. Use Cliente para atender."
        info.text = mensagem_comercial
    cliente_fase_visual = ""
    _preparar_cliente()
    if popup.visible and painel_atual == "Cliente":
        _reabrir_comercio.call_deferred()

func _recalcular_cliente() -> void:
    _atualizar_fila_visual()
    if loja.estado["cliente"].is_empty():
        return
    if loja.estado["cliente"]["fase"] == "aguardando":
        loja.estado["cliente"]["fase"] = "entrando"
    _preparar_cliente()

func _carregar_clientes(dados: Dictionary) -> bool:
    if not clientes.carregar(dados.get("clientes",CLIENTES.inicial())):
        return false
    var atendimento: Dictionary = loja.estado["cliente"]
    if not atendimento.is_empty() and atendimento["fase"] != "saindo" and clientes.estado["atual"].is_empty():
        if atendimento["tipo"] == "servico":
            clientes.vincular_servico(int(loja.estado["servico"]["preco"]))
        else:
            clientes.vincular_manual(atendimento["produto"],atendimento["tipo"] == "pc",int(loja.estado["montagem"]["preco"]) if atendimento["tipo"] == "pc" else int(PECAS.PECAS[atendimento["produto"]]["venda"]))
    return true

func _processar_fila(delta: float) -> void:
    var vai_expirar := false
    var acompanhados: Array = clientes.estado["fila"].duplicate()
    if not clientes.estado["atual"].is_empty():
        acompanhados.append(clientes.estado["atual"])
    for id in acompanhados:
        vai_expirar = vai_expirar or float(clientes.estado["perfis"][id]["restante"]) <= delta
    var anterior: Dictionary = clientes.estado.duplicate(true) if vai_expirar else {}
    var comercio_anterior: Dictionary = loja.estado.duplicate(true) if vai_expirar else {}
    var os_dados: Dictionary = loja.estado["servico"]
    var expirados := clientes.avancar(delta,not os_dados.is_empty() and os_dados["fase"] in ["execucao","teste","pronto"])
    for id in fila_labels:
        var perfil: Dictionary = clientes.estado["perfis"][id]
        var label: Label = fila_labels[id]
        label.text = "%s | %s | Orcamento R$ %d\nPaciencia %d s | Fidelidade %d" % [perfil["nome"],perfil["preferencia"],perfil["orcamento"],ceili(float(perfil["restante"])),perfil["fidelidade"]]
    for id in expirados:
        if clientes.estado["atual"] == id and not loja.estado["cliente"].is_empty():
            if loja.estado["cliente"]["tipo"] == "pc" and loja.estado["montagem"]["fase"] in ["montando","testado"]:
                loja.cancelar_montagem()
            elif loja.estado["cliente"]["tipo"] == "servico":
                loja.cancelar_os()
            loja.estado["cliente"]["fase"] = "saindo"
        clientes.finalizar(id,int(relogio.estado["dia"]),"desistencia")
    if not expirados.is_empty():
        if not _save():
            clientes.estado = anterior
            loja.estado = comercio_anterior
            relogio_bloqueado = true
            info.text += " Simulacao pausada; salve para retomar."
            return
        info.text = "Cliente desistiu por falta de paciencia."
        cliente_fase_visual = ""
        _preparar_cliente()
    cliente_espera += delta
    var demanda: float = AMBIENTE.previsao(int(relogio.estado["dia"]))["demanda"] * clientes.demanda()
    if cliente_espera < 20.0 / demanda or clientes.estado["fila"].size() >= 4 or _estacao("balcao") == null:
        return
    cliente_espera = 0
    var anteriores := clientes.estado.duplicate(true)
    if not clientes.retornar(int(relogio.estado["dia"])).is_empty():
        if not _save():
            clientes.estado = anteriores
        else:
            _atualizar_fila_visual()
        return
    for id in PECAS.PECAS:
        if loja.quantidade(id) < 1:
            continue
        var preco := int(PECAS.PECAS[id]["venda"])
        var orcamento := int(preco * (0.8 + (int(clientes.estado["proximo"]) % 4) * 0.2))
        var copia := clientes.estado.duplicate(true)
        if not clientes.adicionar(PECAS.PECAS[id]["categoria"],orcamento,180.0 + int(clientes.estado["reputacao"]) * 0.6).is_empty():
            if not _save():
                clientes.estado = copia
            else:
                _atualizar_fila_visual()
        break

func _atender_fila() -> void:
    if popup.visible or clientes.estado["fila"].is_empty():
        return
    var id := ""
    var produto := ""
    for candidato in clientes.estado["fila"]:
        var perfil: Dictionary = clientes.estado["perfis"][candidato]
        var oferta := clientes.oferta(candidato,loja.estado["estoque"])
        var disponivel := not oferta.is_empty()
        if perfil["preferencia"] == "pc":
            var jogo: String = perfil.get("jogo","")
            disponivel = _estacao("bancada") != null and loja.total_os() < COMERCIO.MAX_OS and CAMPANHA.jogo_liberado(jogo,loja.estado["campanha"],_nivel_campanha(),int(relogio.estado["dia"])) and int(perfil["orcamento"]) >= int(JOGOS.buscar(jogo)["orcamento"])
        elif perfil["preferencia"] == "servico":
            var servico: String = perfil.get("servico","diagnostico")
            var caso: String = perfil.get("caso","")
            var preco: int = loja.SERVICOS.CASOS[caso]["preco"] if not caso.is_empty() else loja.SERVICOS.ITENS[servico]["preco"]
            disponivel = _estacao("bancada") != null and loja.total_os() < COMERCIO.MAX_OS and int(perfil["orcamento"]) >= preco
        if disponivel:
            id = candidato
            produto = oferta
            break
    if id.is_empty():
        return
    var anterior := loja.estado.duplicate(true)
    var perfis := clientes.estado.duplicate(true)
    var perfil: Dictionary = clientes.estado["perfis"][id]
    var ok := false
    if perfil["preferencia"] == "pc":
        var jogo: String = perfil.get("jogo","")
        ok = loja.criar_cliente("",true,jogo)
    elif perfil["preferencia"] == "servico":
        var servico: String = perfil.get("servico","diagnostico")
        ok = loja.abrir_os(servico,perfil.get("caso",""))
    else:
        ok = loja.criar_cliente(produto)
    if not ok or not clientes.ativar(id) or not _save():
        loja.estado = anterior
        clientes.estado = perfis
        return
    cliente_fase_visual = ""
    _preparar_cliente()

func _atualizar_fila_visual() -> void:
    for pessoa in fila_visuais:
        pessoa.queue_free()
    fila_visuais.clear()
    if not indoors or clientes.estado["fila"].is_empty() or _estacao("balcao") == null:
        return
    var rota := _navegacao(null,cadastro["entrada_interna"]).caminho_ate(_estacao("balcao").position,85)
    if rota.is_empty():
        return
    for i in range(clientes.estado["fila"].size()):
        var at := rota[mini(rota.size()-1,i*3 + 2)]
        var pessoa := _personagem("cliente_estudante",at)
        pessoa.name = clientes.estado["fila"][i]
        pessoa.personalizar(int(pessoa.name.trim_prefix("cliente_")) % 9)
        fila_visuais.append(pessoa)

func _abrir_historico_clientes() -> void:
    _limpar_painel("Historico dos clientes")
    var historico: Array = clientes.estado["historico"]
    _texto_painel("Reputacao %d/100 | Demanda %.0f%%\nAtendimentos registrados: %d. Compras +2; desistencias -4; cancelamentos -1. Clientes retornam em 1 a 3 dias apos compras." % [clientes.estado["reputacao"],clientes.demanda() * 100,historico.size()])
    for i in range(historico.size()-1,maxi(-1,historico.size()-21),-1):
        var item: Dictionary = historico[i]
        _texto_painel("Dia %d | %s | %s | %s | R$ %d | PC #%d" % [item["dia"],clientes.estado["perfis"][item["cliente"]]["nome"],item["resultado"],item["produto"],item["valor"],item["pc_id"]])
    popup.popup_centered(Vector2i(390,460))

func _abrir_servicos() -> void:
    if not _comercio_disponivel():
        return
    painel_atual = "Servicos"
    _limpar_painel("Assistencia tecnica - ordens de servico")
    if not mensagem_comercial.is_empty():
        _texto_painel(mensagem_comercial)
    var os_dados: Dictionary = loja.estado["servico"]
    _texto_painel("Oficina %d/%d | Pecas reservadas ficam fora do estoque vendavel.\nPrioridade: urgente, normal, baixa; desempate por chegada." % [loja.total_os(),COMERCIO.MAX_OS])
    for pacote: Dictionary in loja.estado["fila_os"]:
        var ordem: Dictionary = pacote["os"]
        _texto_painel("PC/OS #%d | %s | %s | Reservas %s" % [ordem["id"],loja.SERVICOS.nome(ordem),["Urgente","Normal","Baixa"][int(ordem["prioridade"])],str(ordem["reservas"])])
        _button("Retomar OS #%d na bancada" % ordem["id"],_operacao_comercial.bind("retomar_os",str(int(ordem["id"]))),shop_list)
        for prioridade in range(3):
            _button("OS #%d: %s" % [ordem["id"],["Urgente","Normal","Baixa"][prioridade]],_operacao_comercial.bind("priorizar_os",str(int(ordem["id"])),str(prioridade)),shop_list)
    if os_dados.is_empty() or os_dados["fase"] in ["entregue","cancelado"]:
        _texto_painel("Receba no balcao. Diagnostico/execucao/teste na bancada; aprove o orcamento e entregue no balcao.")
        for id in loja.SERVICOS.ITENS:
            var dados: Dictionary = loja.SERVICOS.ITENS[id]
            var botao := _button("%s | Orcamento R$ %d" % [dados["nome"],dados["preco"]],_operacao_comercial.bind("abrir_os",id),shop_list)
            botao.disabled = loja.total_os() >= COMERCIO.MAX_OS or not loja.estado["cliente"].is_empty()
        for caso in loja.SERVICOS.CASOS:
            var botao := _button("Investigar: %s | R$ %d" % [loja.SERVICOS.CASOS[caso]["nome"],loja.SERVICOS.CASOS[caso]["preco"]],_operacao_comercial.bind("abrir_os","reparo",caso),shop_list)
            botao.disabled = loja.total_os() >= COMERCIO.MAX_OS or not loja.estado["cliente"].is_empty()
        _texto_painel("OS entregues: %d. Configuracao e componentes devolvidos ficam registrados." % loja.estado["ordens_servico"].size())
    else:
        _texto_painel("OS #%d | %s\n%s | Orcamento R$ %d | Custo R$ %d\n%s" % [os_dados["id"],os_dados["fase"],loja.SERVICOS.nome(os_dados),os_dados["preco"],os_dados["custo"],os_dados["relatorio"]])
        _texto_painel("Apos aprovar, a paciencia fica pausada durante a execucao e retirada. Pecas antigas sao devolvidas ao cliente, nao ao estoque da loja.")
        for id in loja.SERVICOS.necessarios(os_dados):
            _texto_painel("Necessario: %s | Estoque %d" % [PECAS.PECAS[id]["nome"],loja.quantidade(id)])
        if os_dados.has("caso") and os_dados["fase"] == "recepcao":
            _texto_painel("Sintoma: " + loja.SERVICOS.CASOS[os_dados["caso"]]["nome"] + ". Realize o ensaio correspondente; metricas sao simuladas.")
            for ensaio in loja.SERVICOS.ENSAIOS:
                _button("Ensaio: " + ensaio,_operacao_comercial.bind("investigar_os",ensaio),shop_list)
        match os_dados["fase"]:
            "recepcao": _button("Diagnosticar na bancada",_operacao_comercial.bind("diagnosticar_os"),shop_list)
            "orcamento": _button("Aprovar com o cliente no balcao",_operacao_comercial.bind("aprovar_os"),shop_list)
            "execucao":
                _button("Guardar PC, reservar pecas e liberar atendimento",_operacao_comercial.bind("guardar_os"),shop_list)
                _button("Executar na bancada",_operacao_comercial.bind("executar_os"),shop_list)
            "teste": _button("Teste final na bancada",_operacao_comercial.bind("testar_os"),shop_list)
            "pronto": _button("Entregar e receber no balcao",_operacao_comercial.bind("vender"),shop_list)
        if os_dados["fase"] in ["recepcao","orcamento","execucao"]:
            _button("Cancelar antes do consumo",_operacao_comercial.bind("cancelar_os"),shop_list)
    popup.popup_centered(Vector2i(390,500))

func _tempo_pausado() -> bool:
    return app_pausado or relogio_bloqueado or (selecionado != null and selecionado.em_edicao)

func _avancar_simulacao(delta: float) -> bool:
    if _tempo_pausado():
        _refresh()
        return false
    var vai_fechar := float(relogio.estado["segundos"]) + delta >= CALENDARIO.SEGUNDOS_DIA
    var anterior: Dictionary = relogio.estado.duplicate(true) if vai_fechar else {}
    var comercio_anterior: Dictionary = loja.estado.duplicate(true) if vai_fechar else {}
    var equipe_anterior: Dictionary = equipe.estado.duplicate(true) if vai_fechar else {}
    var saldo := money
    money = relogio.avancar(delta,money,loja.resumo(),equipe)
    if not relogio.ultimo_erro.is_empty():
        info.text = relogio.ultimo_erro
        relogio_bloqueado = true
        _refresh()
        return false
    loja.avancar(delta)
    if relogio.fechou_dia:
        if not _save():
            relogio.estado = anterior
            loja.estado = comercio_anterior
            equipe.estado = equipe_anterior
            money = saldo
            relogio_bloqueado = true
            info.text += " Relogio pausado; use Salvar agora para retomar."
            _refresh()
            return false
        info.text = "Dia fechado e salvo. Divida pendente: R$ %d." % relogio.divida()
    _refresh()
    return true

func _abrir_financas() -> void:
    if transitioning or save_bloqueado:
        return
    painel_atual = "Financas"
    _limpar_painel("Calendario e fechamento do caixa")
    var data := relogio.data()
    _texto_painel("Dia %d | %02d/%02d/%d | Semana: %d\n%02d:%02d | 1 dia = 15 minutos reais.\nConstrucao pausa o tempo e as entregas." % [int(relogio.estado["dia"]),data["dia"],data["mes"],data["ano"],data["semana"],data["hora"],data["minuto"]])
    _texto_painel("Aluguel R$ 100 + energia R$ 20 por dia.\nDivida: R$ %d. O caixa nunca fica negativo." % relogio.divida())
    var salarios := 0
    for id in equipe.estado["contratos"]:
        if equipe.ativo(id):
            salarios += int(EQUIPE.CANDIDATOS[id]["salario"])
    var meta := CAMPANHA.meta_diaria(salarios)
    _texto_painel("Plano de campanha: PC inicial custa %d e rende margem %d.\nDespesas/dia com equipe atual: %d. Equilibrio: %d PC(s).\nMeta: 2 PCs/dia; lucro previsto %d/dia.\nReserve %d para pecas e contas antes de expandir.\nProjecao, nao renda garantida; demanda/estoque dependem do jogador." % [meta["custo_pc"],meta["margem_pc"],meta["despesas"],meta["equilibrio"],meta["lucro_meta"],meta["reserva"]])
    _button("Funcionarios: contratar e atribuir tarefas",_abrir_equipe,shop_list)
    _button("Guia, objetivos, aparencia e acabamentos",_abrir_progresso,shop_list)
    _button("Previa visual do bairro: " + ("desativar" if bairro.previa_visual else "ativar"),_alternar_previa_visual,shop_list)
    _button("Imoveis, ampliacao e ambiente",_abrir_imovel,shop_list)
    _button("Recentralizar camera (arraste/pinca/roda)",_recentralizar_camera,shop_list)
    if relogio_bloqueado:
        _texto_painel("Relogio pausado por erro de gravacao. Corrija o armazenamento e salve para retomar.")
        _button("Salvar agora e retomar",_salvar_manual,shop_list)
    var pagar := _button("Pagar contas pendentes",_pagar_contas,shop_list)
    pagar.disabled = relogio.divida() == 0 or money == 0
    var fechamentos: Array = relogio.estado["fechamentos"]
    for i in range(fechamentos.size()-1,maxi(-1,fechamentos.size()-8),-1):
        var dia: Dictionary = fechamentos[i]
        _texto_painel("Dia %d: receita %d | CMV %d | despesas %d\nLucro liquido %d | Caixa %d | Divida %d" % [dia["dia"],dia["receita"],dia["cmv"],dia["despesas"],dia["lucro"],dia["saldo"],dia["divida"]])
    popup.popup_centered(Vector2i(390,480))

func _pagar_contas() -> void:
    if save_bloqueado or transitioning:
        return
    var anterior := relogio.estado.duplicate(true)
    var saldo := money
    money = relogio.pagar_contas(money)
    if not relogio.ultimo_erro.is_empty():
        info.text = relogio.ultimo_erro
        return
    if not _save():
        relogio.estado = anterior
        money = saldo
        return
    info.text = "Pagamento salvo. Divida restante: R$ %d." % relogio.divida()
    _refresh()
    _abrir_financas()

func _posto_existe(tipo: String) -> bool:
    if indoors:
        var posto := _estacao(tipo)
        return posto != null and not _navegacao().caminho_ate(posto.position,85).is_empty()
    for item: Dictionary in gestor_imoveis.carregar_estado(unidade_id).get("moveis",[]):
        if _tipo_item(str(item["id"])) == tipo:
            return true
    return false

func _funcionario_autorizado(id: String, acao: String, posto: String) -> bool:
    if not equipe.ativo(id) or transitioning or save_bloqueado or _tempo_pausado() or selecionado != null:
        return false
    var funcao: String = equipe.estado["contratos"][id]["funcao"]
    var acoes := {"caixa":["vender","aprovar_os"],"tecnico":["diagnosticar_os","investigar_os","executar_os","testar_os","retomar_os"],"estoque":["receber"],"montador":["instalar","conectar","testar"]}
    if not acao in acoes[funcao] or EQUIPE.POSTOS[funcao] != posto or not _posto_existe(posto):
        return false
    if not indoors:
        return true
    for visual in equipe_visuais:
        if visual.get_meta("funcionario","") == id:
            return _walkable(visual.position) and visual.position.distance_to(_estacao(posto).position) <= 120
    return false

func _abrir_equipe() -> void:
    if save_bloqueado or transitioning:
        return
    painel_atual = "Equipe"
    _limpar_painel("Funcionarios e tarefas")
    _texto_painel("Salario diario proporcional ao tempo contratado, arredondado para R$ inteiro no fechamento. Demitir nao apaga salarios devidos.\nCaixa: vendas/orcamentos. Tecnico: OS por prioridade. Estoque: recebimento. Montador: pecas/cabos/teste de PC.\nUma unidade ativa, um funcionario por funcao e uma bancada trabalhando por vez.\nExperiencia melhora a velocidade; sem posto ou insumos, a tarefa aguarda.")
    for id in EQUIPE.CANDIDATOS:
        var candidato: Dictionary = EQUIPE.CANDIDATOS[id]
        if not equipe.ativo(id):
            var botao := _button("Contratar %s - %s - R$ %d/dia%s" % [candidato["nome"],candidato["funcao"],candidato["salario"]," (N2)" if id in ["nina","ivo","luz"] else ""],_alterar_equipe.bind("contratar",id,""),shop_list)
            botao.disabled = id in ["nina","ivo","luz"] and _nivel_campanha() < 2 and not equipe.estado["contratos"].has(id)
            continue
        var contrato: Dictionary = equipe.estado["contratos"][id]
        _texto_painel("%s | %s | Habilidade %d/100\nR$ %d/dia | Devido ate agora R$ %.2f\n%s" % [candidato["nome"],contrato["funcao"],equipe.habilidade(id),candidato["salario"],contrato["acumulado"],contrato["atividade"]])
        for funcao in EQUIPE.POSTOS:
            if funcao != contrato["funcao"]:
                _button("Atribuir " + funcao,_alterar_equipe.bind("atribuir",id,funcao),shop_list)
        _button("Demitir " + str(candidato["nome"]),_alterar_equipe.bind("demitir",id,""),shop_list)
    _button("Atualizar atividades",_abrir_equipe,shop_list)
    popup.popup_centered(Vector2i(390,480))

func _alterar_equipe(acao: String, id: String, funcao: String) -> bool:
    if save_bloqueado or transitioning or selecionado != null:
        info.text = "Conclua a edicao/transicao antes de alterar a equipe."
        return false
    if acao in ["contratar","atribuir"]:
        if acao == "contratar" and id in ["nina","ivo","luz"] and _nivel_campanha() < 2 and not equipe.estado["contratos"].has(id):
            info.text = "Especialistas sao desbloqueados no nivel 2."
            return false
        var destino: String = EQUIPE.CANDIDATOS.get(id,{}).get("funcao","") if acao == "contratar" else funcao
        if not EQUIPE.POSTOS.has(destino) or not _posto_existe(EQUIPE.POSTOS[destino]):
            info.text = "Instale e libere acesso ao posto antes de contratar/atribuir."
            return false
    var anterior := equipe.estado.duplicate(true)
    var ok := false
    match acao:
        "contratar": ok = equipe.contratar(id)
        "atribuir": ok = equipe.atribuir(id,funcao)
        "demitir": ok = equipe.demitir(id)
        _:
            info.text = "Alteracao de equipe desconhecida."
            return false
    if not ok:
        info.text = equipe.ultimo_erro
        return false
    if not _save():
        equipe.estado = anterior
        return false
    _atualizar_funcionarios()
    _abrir_equipe()
    info.text = "Contrato/atribuicao salvo."
    return true

func _atualizar_funcionarios() -> void:
    var anteriores: Dictionary = {}
    for visual in equipe_visuais:
        anteriores[visual.get_meta("funcionario")] = visual.position
        visual.queue_free()
    equipe_visuais.clear()
    if not indoors:
        return
    var nav := _navegacao()
    for id in equipe.estado["contratos"]:
        if not equipe.ativo(id):
            continue
        var posto := _estacao(EQUIPE.POSTOS[equipe.estado["contratos"][id]["funcao"]])
        if posto == null:
            continue
        var rota := nav.caminho_ate(posto.position,85)
        if rota.is_empty():
            continue
        var ponto: Vector2 = rota[-1]
        var posicao := Vector2.INF
        var balcao := _estacao("balcao")
        var rota_cliente := nav.caminho_ate(balcao.position,85) if balcao != null else PackedVector2Array()
        for offset in [Vector2(-36,0),Vector2(36,0),Vector2(0,36),Vector2(0,-36),Vector2(-36,36),Vector2(36,36),Vector2.ZERO]:
            var caminho := nav.caminho_ate(ponto + offset)
            if caminho.is_empty():
                continue
            var destino := caminho[-1]
            if destino.distance_to(posto.position) > 120 or destino.distance_to(pos_player) < 24:
                continue
            if not rota_cliente.is_empty() and destino.distance_to(rota_cliente[-1]) < 30:
                continue
            var livre := true
            for pessoa in equipe_visuais + fila_visuais:
                livre = livre and destino.distance_to(pessoa.position) >= 30
            if livre:
                posicao = destino
                break
        if posicao == Vector2.INF:
            equipe.registrar(id,"Sem espaco livre para ocupar o posto",false)
            continue
        var visual := _personagem("tecnico",posicao)
        visual.personalizar(EQUIPE.CANDIDATOS.keys().find(id) % 8 + 1)
        var inicio: Vector2 = anteriores.get(id,cadastro["entrada_interna"] + Vector2(-30*(equipe_visuais.size()+1),0))
        if _walkable(inicio):
            var caminho := _navegacao(null,inicio).caminho_ate(posicao)
            if not caminho.is_empty():
                visual.position = inicio
                visual.set_meta("rota_posto",caminho)
        visual.set_meta("funcionario",id)
        var nome := Label.new()
        nome.text = EQUIPE.CANDIDATOS[id]["nome"]
        nome.position = Vector2(-40,-270)
        visual.add_child(nome)
        equipe_visuais.append(visual)

func _processar_funcionarios(delta: float) -> void:
    if _tempo_pausado() or transitioning or save_bloqueado or selecionado != null:
        return
    for visual in equipe_visuais:
        var rota: PackedVector2Array = visual.get_meta("rota_posto",PackedVector2Array())
        var restante := 72.0 * delta
        var anterior := visual.position
        while not rota.is_empty() and restante > 0:
            var distancia := visual.position.distance_to(rota[0])
            var passo := minf(restante,distancia)
            visual.position = visual.position.move_toward(rota[0],passo)
            restante -= passo
            if distancia <= passo:
                rota.remove_at(0)
        visual.set_meta("rota_posto",rota)
        visual.atualizar(visual.position-anterior,delta)
    var cliente: Dictionary = loja.estado["cliente"]
    if not indoors and not cliente.is_empty() and cliente["fase"] in ["entrando","saindo"] and _posto_existe("balcao"):
        cliente_tempo_oculto += delta
        if cliente_tempo_oculto >= 3:
            var anterior := cliente.duplicate(true)
            if cliente["fase"] == "entrando":
                cliente["fase"] = "aguardando"
            elif cliente["fase"] == "saindo":
                loja.estado["cliente"] = {}
            if not _save():
                loja.estado["cliente"] = anterior
                relogio_bloqueado = true
                return
            cliente_tempo_oculto = 0.0
    else:
        cliente_tempo_oculto = 0.0
    for id in equipe.estado["contratos"]:
        if not equipe.pronto(id):
            continue
        var contrato: Dictionary = equipe.estado["contratos"][id]
        var funcao: String = contrato["funcao"]
        var acao := ""
        var argumento := ""
        var categoria := ""
        if not _posto_existe(EQUIPE.POSTOS[funcao]):
            equipe.registrar(id,"Aguardando posto acessivel",false)
            continue
        cliente = loja.estado["cliente"]
        var os_dados: Dictionary = loja.estado["servico"]
        if funcao == "estoque":
            for pedido: Dictionary in loja.estado["pedidos"]:
                if not pedido["recebido"] and float(pedido["restante"]) == 0:
                    acao = "receber"
                    argumento = str(int(pedido["id"]))
                    break
        elif funcao == "caixa" and not cliente.is_empty() and cliente["fase"] == "aguardando":
            if cliente["tipo"] == "servico":
                if os_dados["fase"] == "orcamento":
                    acao = "aprovar_os"
                elif os_dados["fase"] == "pronto":
                    acao = "vender"
            elif cliente["tipo"] == "peca" or loja.estado["montagem"].get("fase") == "testado":
                acao = "vender"
        elif funcao == "tecnico" and not (popup.visible and painel_atual in ["Montagem","Servicos","Gabinete"]):
            if cliente.is_empty() and loja.proxima_os() > 0:
                acao = "retomar_os"
                argumento = str(loja.proxima_os())
            match os_dados.get("fase",""):
                "recepcao":
                    acao = "diagnosticar_os"
                    if os_dados.has("caso"):
                        var ensaio: String = loja.SERVICOS.CASOS[os_dados["caso"]]["ensaio"]
                        if not ensaio in os_dados["ensaios"]:
                            acao = "investigar_os"
                            argumento = ensaio
                "execucao":
                    var disponivel := true
                    for insumo in loja.SERVICOS.necessarios(os_dados):
                        if loja.quantidade(insumo) + int(os_dados.get("reservas",{}).get(insumo,0)) < int(loja.SERVICOS.necessarios(os_dados)[insumo]):
                            disponivel = false
                    if disponivel:
                        acao = "executar_os"
                "teste": acao = "testar_os"
        elif funcao == "montador" and cliente.get("tipo") == "pc" and not (popup.visible and painel_atual in ["Montagem","Servicos","Gabinete"]):
            var montagem: Dictionary = loja.estado["montagem"]
            if montagem["fase"] == "montando":
                var plano := loja.plano_automatico()
                if plano.is_empty():
                    equipe.registrar(id,"Aguardando configuracao compativel, estoque ou revisao manual",false)
                    continue
                for encaixe in PECAS.CATEGORIAS:
                    if not montagem["pecas"].has(encaixe):
                        acao = "instalar"
                        argumento = plano[encaixe]
                        categoria = encaixe
                        break
                if acao.is_empty():
                    acao = "testar" if montagem["conectado"] else "conectar"
        if acao.is_empty():
            equipe.registrar(id,"Aguardando tarefa, insumos ou liberacao manual da bancada",false)
            continue
        var anterior := equipe.estado.duplicate(true)
        equipe.registrar(id,acao,true)
        if not _operacao_comercial(acao,argumento,categoria,id):
            equipe.estado = anterior
            equipe.registrar(id,"Falha: " + info.text,false)
        if relogio_bloqueado:
            return

func _alternar_porta() -> bool:
    if selecionado == null or selecionado.item_id != "porta_interna" or selecionado.em_edicao or save_bloqueado or transitioning:
        info.text = "Selecione uma porta confirmada, fora da edicao."
        return false
    var porta_interna := selecionado
    var anterior := porta_interna.porta_aberta
    porta_interna.porta_aberta = not anterior
    if not porta_interna.porta_aberta and not _can_place(porta_interna):
        porta_interna.porta_aberta = anterior
        info.text = "Porta nao pode fechar: " + motivo_construcao
        return false
    if not _save():
        porta_interna.porta_aberta = anterior
        return false
    porta_interna._atualizar()
    selecionado = null
    edit_bar.hide()
    _recalcular_cliente()
    _atualizar_funcionarios()
    info.text = "Porta aberta e salva." if porta_interna.porta_aberta else "Porta fechada e salva."
    return true

func _recentralizar_camera() -> void:
    popup.hide()
    if indoors:
        _camera_interior()
    else:
        cam.position = pos_player
        _camera_exterior()
    _stop_input()
    info.text = "Camera recentralizada."

func _nivel_campanha() -> int:
    return CAMPANHA.nivel(loja.estado,int(clientes.estado["reputacao"]))

func _compra_liberada(id: String) -> bool:
    if not PECAS.PECAS.has(id):
        return false
    var campanha: Dictionary = loja.estado["campanha"]
    if id in campanha["pecas_legadas"]:
        return true
    return CAMPANHA.peca_liberada(id,campanha,_nivel_campanha(),int(relogio.estado["dia"])) and int(CAMPANHA.FORNECEDORES[campanha["fornecedor"]]["nivel"]) >= CAMPANHA.nivel_peca(id)

func _definir_unidade(id: String) -> void:
    unidade_id = id
    gestor_imoveis.unidade_id = id
    cadastro = CATALOGO.buscar(id,int(gestor_imoveis.estados.get(id,{}).get("nivel",0)))
    acabamentos = gestor_imoveis.estados.get(id,{}).get("acabamentos",{}).duplicate(true)
    sala.acabamentos = acabamentos.duplicate(true)
    sala.configurar(cadastro)
    exit_marker.position = Vector2(cadastro["saida_interna"]) + Vector2(-32,0)

func _atualizar_ambiente() -> void:
    if iluminacao == null or ambiente == null:
        return
    iluminacao.color = Color.WHITE if indoors else AMBIENTE.iluminacao(float(relogio.estado["segundos"]))
    var chuva: bool = not indoors and AMBIENTE.previsao(int(relogio.estado["dia"]))["clima"] == "Chuva"
    if ambiente.chovendo != chuva:
        ambiente.chovendo = chuva
        ambiente.queue_redraw()

func _abrir_imovel() -> void:
    if save_bloqueado or transitioning or selecionado != null:
        info.text = "Conclua a edicao antes de alterar a planta."
        return
    painel_atual = "Imovel"
    _limpar_painel("Imoveis, construcao e ambiente")
    var previsao := AMBIENTE.previsao(int(relogio.estado["dia"]))
    _texto_painel("Unidade ativa: %s\nPlanta: %d x %d | Ampliacao %d/2\nClima: %s | Evento: %s\nDemanda: %.0f%% da rotina.\nEquipe/estoque compartilhados; uma unidade atende por vez." % [cadastro["nome"],cadastro["modulos"].x,cadastro["modulos"].y,cadastro["nivel"],previsao["clima"],previsao["evento"],previsao["demanda"] * 100])
    if indoors and int(cadastro["nivel"]) < 2:
        _button("Ampliar planta - R$ %d" % (1800 * (int(cadastro["nivel"]) + 1)),_ampliar_imovel,shop_list)
    _texto_painel("Divisorias: compre em Loja, posicione e gire entre as duas paredes aprovadas. Deixe vaos livres para portas/circulacao; bloqueios de pessoas e postos sao recusados.")
    if not gestor_imoveis.estados.has("pc_store_002"):
        _texto_painel("Salas comerciais: imovel de 10 x 8, vazio, por R$ 8500. Visite a fachada no extremo direito do bairro para comprar e entrar.")
        _button("Comprar Salas comerciais - R$ 8500",_comprar_imovel,shop_list)
    else:
        _texto_painel("Salas comerciais adquiridas. Entre pela fachada existente; moveis e ampliacoes de cada imovel sao independentes.")
    popup.popup_centered(Vector2i(390,480))

func _ampliar_imovel() -> bool:
    if not indoors or transitioning or save_bloqueado or selecionado != null or int(cadastro["nivel"]) >= 2:
        info.text = "Amplie dentro do imovel, fora da edicao, ate o nivel 2."
        return false
    var custo := 1800 * (int(cadastro["nivel"]) + 1)
    if money < custo:
        info.text = "Caixa insuficiente para ampliar."
        return false
    var anterior := cadastro.duplicate(true)
    var estados_anteriores := gestor_imoveis.estados.duplicate(true)
    cadastro = CATALOGO.buscar(unidade_id,int(cadastro["nivel"]) + 1)
    var nav := _navegacao()
    var alvos: Array[Vector2] = [pos_player,cadastro["entrada_interna"]]
    for pessoa in fila_visuais + equipe_visuais:
        alvos.append(pessoa.position)
    if not loja.estado["cliente"].is_empty() and customer.visible:
        alvos.append(customer.position)
    var acessivel := true
    for alvo in alvos:
        acessivel = acessivel and not nav.caminho_ate(alvo).is_empty()
    for movel in moveis:
        if _eh_estacao(movel):
            acessivel = acessivel and not nav.caminho_ate(movel.position,85).is_empty()
    if not acessivel:
        cadastro = anterior
        info.text = "Ampliacao recusada: a nova entrada precisa manter acesso a pessoas e postos."
        return false
    money -= custo
    if not _save():
        money += custo
        cadastro = anterior
        gestor_imoveis.estados = estados_anteriores
        return false
    sala.configurar(cadastro)
    exit_marker.position = Vector2(cadastro["saida_interna"]) + Vector2(-32,0)
    _camera_interior()
    _recalcular_cliente()
    _atualizar_funcionarios()
    _refresh()
    info.text = "Ampliacao paga e salva; moveis e estoque preservados."
    _abrir_imovel()
    return true

func _comprar_imovel() -> bool:
    var novo := CATALOGO.buscar("pc_store_002")
    if indoors or transitioning or save_bloqueado or selecionado != null or pos_player.distance_to(novo["porta_externa"]) >= 85:
        info.text = "Visite a entrada das Salas comerciais no extremo direito do bairro."
        return false
    if gestor_imoveis.estados.has("pc_store_002") or money < int(novo["preco"]):
        info.text = "Imovel ja adquirido ou caixa insuficiente."
        return false
    money -= int(novo["preco"])
    gestor_imoveis.salvar_estado("pc_store_002",CATALOGO.estado_inicial("pc_store_002"))
    if not _save():
        money += int(novo["preco"])
        gestor_imoveis.estados.erase("pc_store_002")
        return false
    _refresh()
    info.text = "Salas comerciais adquiridas e salvas. Feche o painel e pressione A para entrar."
    _abrir_imovel()
    return true

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_RESUMED:
        app_pausado = false
    if what == NOTIFICATION_APPLICATION_PAUSED:
        app_pausado = true
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
        _stop_input()
        if is_node_ready():
            _save()

func _cliente_da_rua(_pedestre: int, id_loja: String, _ponto: Vector2) -> void:
    if save_bloqueado or transitioning or _tempo_pausado() or id_loja != unidade_id or clientes.estado["fila"].size() >= 4:
        return
    var anterior := clientes.estado.duplicate(true)
    var visitante := clientes.retornar(int(relogio.estado["dia"]))
    if visitante.is_empty():
        for id in loja.estado["estoque"]:
            if loja.quantidade(id) > 0:
                visitante = clientes.adicionar(PECAS.PECAS[id]["categoria"],int(PECAS.PECAS[id]["venda"]),180.0 + int(clientes.estado["reputacao"])*0.6)
                break
    if not visitante.is_empty():
        if not _save():
            clientes.estado = anterior
        else:
            _atualizar_fila_visual()

func _abrir_gabinete() -> void:
    if not _comercio_disponivel() or not _perto_estacao("bancada"):
        info.text = "Aproxime-se da bancada para visualizar o gabinete."
        return
    var montagem: Dictionary = loja.estado["montagem"]
    if montagem.is_empty() or not montagem["fase"] in ["montando","testado"]:
        info.text = "Sem PC em montagem."
        return
    _limpar_painel("Gabinete - esquema funcional")
    painel_atual = "Gabinete"
    _texto_painel("Esquema de encaixes, nao arte final. Arraste pecas aos encaixes ou instale pelo painel manual. As mesmas regras de compatibilidade e estoque se aplicam.")
    var linha := HBoxContainer.new()
    shop_list.add_child(linha)
    var gabinete := preload("res://scripts/GabineteVisual.gd").new()
    gabinete.configurar(montagem,_instalar_peca)
    linha.add_child(gabinete)
    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(110,250)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    linha.add_child(scroll)
    var estoque := VBoxContainer.new()
    scroll.add_child(estoque)
    for id in loja.estado["estoque"]:
        if loja.quantidade(id) < 1 or not PECAS.PECAS[id]["categoria"] in PECAS.CATEGORIAS:
            continue
        var origem := CARTAO.new()
        origem.name = "VisualPeca_" + id
        origem.peca = id
        origem.text = PECAS.PECAS[id]["categoria"] + " x%d" % loja.quantidade(id)
        origem.tooltip_text = PECAS.PECAS[id]["nome"]
        origem.add_theme_font_size_override("font_size",9)
        origem.custom_minimum_size.y = 44
        origem.pressed.connect(_instalar_peca.bind(id,PECAS.PECAS[id]["categoria"]))
        estoque.add_child(origem)
    _button("Conectar cabos",_operacao_comercial.bind("conectar"),shop_list)
    _button("Testar PC",_operacao_comercial.bind("testar"),shop_list)
    _button("Montagem manual detalhada",_abrir_montagem,shop_list)
    popup.popup_centered(Vector2i(390,600))

func _alternar_previa_visual() -> bool:
    if transitioning or selecionado != null:
        info.text = "Conclua a edicao/transicao antes de comparar os visuais."
        return false
    bairro.definir_previa(not bairro.previa_visual)
    mundo_vivo.definir_previa(bairro.previa_visual)
    info.text = "Previa visual nesta sessao; arte pendente de aprovacao. Originais preservados." if bairro.previa_visual else "Visual original restaurado."
    _abrir_financas()
    return true

func _abrir_progresso() -> void:
    if save_bloqueado or transitioning or selecionado != null:
        info.text = "Conclua a edicao/transicao antes de abrir o guia."
        return
    _limpar_painel("Guia, objetivos e personalizacao")
    var passo := int(evolucao["tutorial"])
    _texto_painel("Tutorial opcional %d/6: %s" % [mini(passo+1,6),INTERFACE.PASSOS[passo] if passo < 6 else "Concluido. Continue jogando livremente."])
    if passo < 6:
        _button("Proxima orientacao",_preferencia.bind("tutorial",passo+1),shop_list)
    _button("Rever guia",_preferencia.bind("tutorial",0),shop_list)
    var objetivos := EVOLUCAO.OBJETIVOS.new()
    objetivos.carregar(evolucao["objetivos"])
    _texto_painel("Objetivos opcionais: sem bloqueio do jogo livre ou dinheiro artificial.")
    for id in EVOLUCAO.OBJETIVOS.METAS:
        _texto_painel("%s %s" % ["[OK]" if objetivos.concluido(id) else "[ ]",EVOLUCAO.OBJETIVOS.METAS[id]["nome"]])
    _texto_painel("Lancamentos tecnologicos: precisam de data, nivel e fornecedor. Aquisicoes antigas continuam acessiveis.")
    for dia in [8,14,21,28]:
        var nomes: PackedStringArray = []
        for id in CAMPANHA.lancamentos_no_dia(dia):
            nomes.append(PECAS.PECAS[id]["nome"])
        for id in JOGOS.JOGOS:
            if int(JOGOS.JOGOS[id].get("lancamento",0)) == dia:
                nomes.append(JOGOS.JOGOS[id]["nome"])
        _texto_painel("Dia %d: %s" % [dia,", ".join(nomes)])
    _texto_painel("Acessorios opcionais em camadas nativas; sprites aprovados intactos. Nao substituem arte modular final.")
    for estilo in range(9):
        _button("Sem acessorios" if estilo == 0 else "Acessorio %d" % estilo,_preferencia.bind("aparencia",estilo),shop_list)
    if indoors:
        _button("Editar piso e setores",_abrir_acabamentos,shop_list)
    _texto_painel("Diagnostico local: %s | %.0f FPS | memoria estatica %.1f MB. Nao equivale a homologacao Android." % [OS.get_name(),Performance.get_monitor(Performance.TIME_FPS),Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0])
    popup.popup_centered(Vector2i(390,540))

func _preferencia(campo: String, valor: int) -> bool:
    if save_bloqueado or transitioning or selecionado != null or not campo in ["tutorial","aparencia"]:
        info.text = "Preferencia indisponivel ou desconhecida."
        return false
    var anterior := evolucao.duplicate(true)
    evolucao[campo] = valor
    if not EVOLUCAO.validar(evolucao) or not _save():
        evolucao = anterior
        info.text = "Nao foi possivel salvar a preferencia; estado anterior preservado."
        return false
    player.personalizar(int(evolucao["aparencia"]))
    _abrir_progresso()
    return true

func _abrir_acabamentos() -> void:
    if not indoors or selecionado != null or save_bloqueado:
        info.text = "Entre na loja e conclua a edicao para reformar."
        return
    _limpar_painel("Pisos e setores")
    _texto_painel("Coordenadas do piso: U/V. Trocar a variante de madeira custa R$ 20 por modulo; setor e gratuito. Sem alterar colisoes, moveis ou PNGs.")
    var u := SpinBox.new()
    u.min_value = 0
    u.max_value = cadastro["modulos"].x-1
    u.step = 1
    shop_list.add_child(u)
    var v := SpinBox.new()
    v.min_value = 0
    v.max_value = cadastro["modulos"].y-1
    v.step = 1
    shop_list.add_child(v)
    var piso := OptionButton.new()
    for nome in ["Madeira A","Madeira B","Madeira C"]:
        piso.add_item(nome)
    shop_list.add_child(piso)
    var setor := OptionButton.new()
    for nome in REFORMA.SETORES:
        setor.add_item("Sem setor" if nome.is_empty() else nome)
    shop_list.add_child(setor)
    _button("Aplicar e salvar",func() -> void: _reformar(int(u.value),int(v.value),piso.selected,REFORMA.SETORES[setor.selected]),shop_list)
    popup.popup_centered(Vector2i(390,460))

func _reformar(u: int, v: int, piso: int, setor: String) -> bool:
    if not indoors or selecionado != null or save_bloqueado or transitioning:
        info.text = "Reforma indisponivel; conclua edicao/transicao."
        return false
    var candidato := acabamentos.duplicate(true)
    candidato["%d,%d" % [u,v]] = {"piso":piso,"setor":setor}
    if not REFORMA.validar(candidato,cadastro["modulos"]):
        info.text = "Celula, piso ou setor invalido."
        return false
    var custo := 20 if REFORMA.celula(acabamentos,u,v)["piso"] != piso else 0
    if money < custo:
        info.text = "Caixa insuficiente para trocar o piso."
        return false
    var anterior := acabamentos.duplicate(true)
    var estados := gestor_imoveis.estados.duplicate(true)
    acabamentos = candidato
    money -= custo
    if not _save():
        acabamentos = anterior
        gestor_imoveis.estados = estados
        money += custo
        return false
    sala.aplicar_acabamentos(acabamentos)
    info.text = "Piso/setor salvo; custo R$ %d." % custo
    _refresh()
    return true
