extends Node2D
# Pixel PC Tycoon V0.4.8 - rua aprovada, personagens e balcao independentes.
const BG = preload("res://Assets/Cenarios/Rua_Comercial_Aprovada.png")
const SHOP_BG = preload("res://Assets/Cenarios/Loja_Base_Aprovada.png")
const CATALOGO = preload("res://scripts/Imoveis/CatalogoImoveis.gd")
const GERENCIADOR = preload("res://scripts/Imoveis/GerenciadorImoveis.gd")
const LOJA_ID := "pc_store_001"
const PLAYER = preload("res://Assets/Personagens/jogador_temporario.png")
const CUSTOMER = preload("res://Assets/Personagens/cliente_temporario.png")
const COUNTER = preload("res://Assets/Moveis/balcao_pixel_art.png")
var INTERIOR: PackedVector2Array = PackedVector2Array([Vector2(310,334),Vector2(738,190),Vector2(1138,332),Vector2(1115,437),Vector2(910,511),Vector2(707,583),Vector2(485,500),Vector2(310,408)])
var SIDEWALK: PackedVector2Array = PackedVector2Array([Vector2(410,814),Vector2(1090,547),Vector2(1515,600),Vector2(1515,704),Vector2(465,970),Vector2(40,895)])
var DOOR: PackedVector2Array = PackedVector2Array([Vector2(792,468),Vector2(980,475),Vector2(1045,687),Vector2(838,723)])
var ROUTE: PackedVector2Array = PackedVector2Array([Vector2(1120,697),Vector2(984,638),Vector2(904,596),Vector2(877,558),Vector2(805,510),Vector2(725,535),Vector2(805,510),Vector2(877,558),Vector2(904,596),Vector2(984,638),Vector2(1120,697)])
var pos_player = Vector2(920,715)
var pos_customer = Vector2(1120,697)
var pos_counter = Vector2(670,405)
var committed_counter = Vector2(670,405)
var money = 6500
var owns_counter = false
var placing = false
var buying = false
var move = Vector2.ZERO
var finger = -1
var route_index = 0
var route_wait = 0.0
var player: Sprite2D
var customer: Sprite2D
var counter: Sprite2D
var cam: Camera2D
var layer: CanvasLayer
var top_label: Label
var info: Label
var popup: AcceptDialog
var pad_center = Vector2.ZERO
var gestor_imoveis = GERENCIADOR.new()
var indoors := false
var transitioning := false
var bg_sprite: Sprite2D
var door_sprite: Sprite2D
const DOOR_FRAMES = [preload("res://Assets/Portas/porta_loja_00.svg"),preload("res://Assets/Portas/porta_loja_01.svg"),preload("res://Assets/Portas/porta_loja_02.svg"),preload("res://Assets/Portas/porta_loja_03.svg"),preload("res://Assets/Portas/porta_loja_04.svg"),preload("res://Assets/Portas/porta_loja_05.svg"),preload("res://Assets/Portas/porta_loja_06.svg")]
var walk_phase := 0.0

func _ready() -> void:
    bg_sprite = Sprite2D.new()
    bg_sprite.texture = BG
    bg_sprite.centered = false
    bg_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    bg_sprite.z_index = -10
    add_child(bg_sprite)
    door_sprite = Sprite2D.new()
    door_sprite.texture = DOOR_FRAMES[0]
    door_sprite.position = Vector2(924,618)
    door_sprite.scale = Vector2(1.65,1.65)
    door_sprite.z_index = 12
    door_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    door_sprite.visible = false
    add_child(door_sprite)
    player = _sprite(PLAYER, pos_player, 5)
    player.name = "Jogador_Independente"
    customer = _sprite(CUSTOMER, pos_customer, 6)
    customer.name = "Cliente_Independente"
    counter = _sprite(COUNTER, pos_counter, 4)
    counter.name = "Balcao_Independente"
    counter.visible = false
    cam = Camera2D.new()
    cam.zoom = Vector2(0.57,0.57)
    cam.limit_left = 0
    cam.limit_top = 0
    cam.limit_right = 1536
    cam.limit_bottom = 1024
    cam.position = pos_player
    add_child(cam)
    layer = CanvasLayer.new()
    add_child(layer)
    _hud()
    get_viewport().size_changed.connect(_layout)
    _layout()
    _load()
    _refresh()

func _sprite(tex: Texture2D, at: Vector2, depth: int) -> Sprite2D:
    var s := Sprite2D.new()
    s.texture = tex
    s.position = at
    s.z_index = depth
    s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    if tex != COUNTER:
        s.scale = Vector2(1.6,1.6)
        s.offset = Vector2(0,-23)
    else:
        s.offset = Vector2(0,-39)
    add_child(s)
    return s

func _walkable(at: Vector2, furniture: bool = true) -> bool:
    if indoors:
        var dims := SHOP_BG.get_size()
        return at.x >= dims.x*0.19 and at.x <= dims.x*0.81 and at.y >= dims.y*0.24 and at.y <= dims.y*0.76 and (not furniture or not owns_counter or at.distance_to(committed_counter)>42)
    if at.x < 8 or at.y < 8 or at.x > 1528 or at.y > 1016:
        return false
    for offset in [Vector2.ZERO,Vector2(8,0),Vector2(-8,0),Vector2(0,8),Vector2(0,-8)]:
        var p: Vector2 = at + offset
        if not (Geometry2D.is_point_in_polygon(p,SIDEWALK) or (p.distance_to(Vector2(920,695)) < 110 and p.y >= 650)) :
            return false
    if furniture and owns_counter and not buying and at.distance_to(committed_counter) < 42:
        return false
    return true

func _physics_process(delta: float) -> void:
    var direction := (move + Input.get_vector("ui_left","ui_right","ui_up","ui_down")).limit_length(1)
    var distance := direction * 205.0 * delta
    var steps := maxi(1,ceili(distance.length()/5.0))
    for i in range(steps):
        var step := distance/float(steps)
        var next_x: Vector2 = pos_player + Vector2(step.x,0)
        if _walkable(next_x):
            pos_player = next_x
        var next_y: Vector2 = pos_player + Vector2(0,step.y)
        if _walkable(next_y):
            pos_player = next_y
    player.position = pos_player
    if direction.length() > 0.05:
        walk_phase += delta * 13.0
        player.offset.y = -23.0 + sin(walk_phase)*2.8
        player.rotation = sin(walk_phase)*0.035
    else:
        player.offset.y = lerpf(player.offset.y,-23.0,minf(1.0,delta*12.0))
        player.rotation = lerpf(player.rotation,0.0,minf(1.0,delta*12.0))
    if direction.x != 0:
        player.flip_h = direction.x < 0
    player.z_index = clampi(int(pos_player.y/100),1,9)
    if placing:
        pos_counter = pos_player + Vector2(0,-62)
        counter.position = pos_counter
        counter.modulate = Color(1,1,1,0.6) if _can_place(pos_counter) else Color(1,0.3,0.3,0.6)
    counter.z_index = clampi(int(pos_counter.y/100),1,9)
    if not indoors:
        _npc(delta)
    cam.position = cam.position.lerp(pos_player,minf(1,delta*5))

func _can_place(at: Vector2) -> bool:
    for offset in [Vector2(-38,-30),Vector2(38,-30),Vector2(-38,30),Vector2(38,30)]:
        if not _walkable(at+offset,false):
            return false
    if Geometry2D.is_point_in_polygon(at,DOOR) or at.distance_to(pos_player)<45:
        return false
    if not indoors:
        for waypoint in ROUTE:
            if at.distance_to(waypoint)<70:
                return false
    return true

func _npc(delta: float) -> void:
    if route_wait > 0:
        route_wait -= delta
        return
    var diff: Vector2 = ROUTE[route_index]-pos_customer
    if diff.length() < 5:
        route_index = (route_index+1)%ROUTE.size()
        if route_index == 6:
            route_wait = 1.5
        return
    var step := diff.normalized()*minf(68*delta,diff.length())
    if _walkable(pos_customer+step):
        pos_customer += step
        customer.position = pos_customer
        if step.x != 0:
            customer.flip_h = step.x < 0
        customer.z_index = clampi(int(pos_customer.y/100),1,9)
    else:
        route_wait = 1.5

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
    info.text = "Microloja | Rua comercial | V0.4.8"
    info.add_theme_font_size_override("font_size",12)
    v.add_child(info)
    var menu := HBoxContainer.new()
    menu.name = "Menu"
    layer.add_child(menu)
    for label in ["Loja","Cliente","Montagem","Estoque","Menu"]:
        var b := Button.new()
        b.text = label
        b.add_theme_font_size_override("font_size",11)
        b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        b.pressed.connect(_menu.bind(label))
        menu.add_child(b)
    var action := Button.new()
    action.name = "Action"
    action.text = "A"
    action.add_theme_font_size_override("font_size",24)
    action.pressed.connect(_interact)
    layer.add_child(action)
    var pad := Panel.new()
    pad.name = "Pad"
    pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
    layer.add_child(pad)
    var arrows := Label.new()
    arrows.name = "Arrows"
    arrows.text = "    ▲\n◀       ▶\n    ▼"
    arrows.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    arrows.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    pad.add_child(arrows)
    popup = AcceptDialog.new()
    popup.title = "Loja de moveis"
    popup.dialog_text = "Balcao R$ 450 | Revenda R$ 225"
    layer.add_child(popup)
    var actions := VBoxContainer.new()
    popup.add_child(actions)
    for label in ["Comprar balcao","Mover balcao","Vender balcao"]:
        var b := Button.new()
        b.text = label
        b.pressed.connect(_shop.bind(label))
        actions.add_child(b)

func _layout() -> void:
    var s := get_viewport_rect().size
    var header := layer.get_node("Header") as Control
    header.position = Vector2(6,6)
    header.size = Vector2(s.x-12,64)
    var menu := layer.get_node("Menu") as Control
    menu.position = Vector2(6,s.y-66)
    menu.size = Vector2(s.x-12,58)
    var pad := layer.get_node("Pad") as Control
    pad.position = Vector2(18,s.y-187)
    pad.size = Vector2(108,108)
    (pad.get_node("Arrows") as Control).size = pad.size
    pad_center = pad.position+pad.size*0.5
    var action := layer.get_node("Action") as Control
    action.position = Vector2(s.x-104,s.y-166)
    action.size = Vector2(75,75)

func _input(event: InputEvent) -> void:
    if popup != null and popup.visible:
        move = Vector2.ZERO
        finger = -1
        return
    if event is InputEventScreenTouch:
        var t := event as InputEventScreenTouch
        if t.pressed and t.position.distance_to(pad_center)<58:
            finger = t.index
            _direction(t.position)
            get_viewport().set_input_as_handled()
        elif not t.pressed and t.index == finger:
            finger = -1
            move = Vector2.ZERO
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag:
        var d := event as InputEventScreenDrag
        if d.index == finger:
            _direction(d.position)
            get_viewport().set_input_as_handled()

func _direction(at: Vector2) -> void:
    var diff: Vector2 = at-pad_center
    move = diff.normalized() if diff.length()>15 else Vector2.ZERO

func _interact() -> void:
    if transitioning:
        return
    var cadastro: Dictionary = CATALOGO.buscar(LOJA_ID)
    var porta: Vector2 = cadastro.get("porta_externa", Vector2(920,695))
    if not placing and indoors and pos_player.y > SHOP_BG.get_height()*0.57:
        _change_area(false)
        return
    if not placing and not indoors and pos_player.distance_to(porta) < 155:
        _change_area(true)
        return
    if placing:
        if _can_place(pos_counter):
            placing = false
            buying = false
            committed_counter = pos_counter
            counter.modulate = Color.WHITE
            info.text = "Balcao posicionado!"
            _save()
        else:
            info.text = "Posicione no piso livre da loja."
    elif not indoors and pos_player.distance_to(pos_customer)<95:
        route_wait = 1.5
        info.text = "Cliente: Ola! Procuro um computador."
    else:
        info.text = "Aproxime-se do cliente e pressione A."

func _change_area(enter: bool) -> void:
    transitioning = true
    move = Vector2.ZERO
    finger = -1
    if enter:
        await _animate_door(true)
    await _fade_transition()
    var dados: Dictionary = gestor_imoveis.entrar(LOJA_ID) if enter else gestor_imoveis.sair()
    if dados.is_empty():
        transitioning = false
        return
    indoors = enter
    var cenario_interno: Texture2D = CATALOGO.interior(LOJA_ID)
    bg_sprite.texture = cenario_interno if indoors and cenario_interno != null else BG
    var dims := SHOP_BG.get_size()
    var inicio: Vector2 = dados.get("entrada_interna_normalizada", Vector2(0.5,0.62))
    pos_player = Vector2(dims.x*inicio.x,dims.y*inicio.y) if indoors else dados.get("saida_externa", Vector2(920,715))
    player.position = pos_player
    cam.limit_right = int(dims.x) if indoors else 1536
    cam.limit_bottom = int(dims.y) if indoors else 1024
    cam.position = pos_player
    customer.visible = not indoors
    counter.visible = indoors and owns_counter
    if not enter:
        await _animate_door(false)
    info.text = "Dentro da loja | A perto da saida para sair" if indoors else "Na rua | A perto da porta para entrar"
    transitioning = false

func _animate_door(opening: bool) -> void:
    door_sprite.visible = true
    var order := [0,1,2,3] if opening else [3,4,5,6]
    for frame in order:
        door_sprite.texture = DOOR_FRAMES[frame]
        await get_tree().create_timer(0.10).timeout
    door_sprite.visible = false

func _fade_transition() -> void:
    var cover := ColorRect.new()
    cover.color = Color(0,0,0,0)
    cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
    cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    layer.add_child(cover)
    var tween := create_tween()
    tween.tween_property(cover,"color:a",1.0,0.16)
    tween.tween_property(cover,"color:a",0.0,0.20)
    await tween.finished
    cover.queue_free()

func _refresh() -> void:
    top_label.text = "PIXEL PC TYCOON | R$ "+str(money)

func _shop(action: String) -> void:
    popup.hide()
    move = Vector2.ZERO
    finger = -1
    match action:
        "Comprar balcao":
            if owns_counter:
                info.text = "Voce ja possui um balcao."
            elif money < 450:
                info.text = "Dinheiro insuficiente."
            else:
                money -= 450
                owns_counter = true
                placing = true
                buying = true
                counter.visible = true
                info.text = "Ande e pressione A para posicionar."
        "Mover balcao":
            if owns_counter:
                placing = true
                buying = false
                committed_counter = pos_counter
                info.text = "Ande e pressione A para mover."
            else:
                info.text = "Compre um balcao primeiro."
        "Vender balcao":
            if owns_counter and not placing:
                money += 225
                owns_counter = false
                counter.visible = false
                info.text = "Balcao vendido por R$ 225."
            else:
                info.text = "Nao ha balcao disponivel para venda."
    _refresh()
    if not placing:
        _save()

func _menu(label: String) -> void:
    if label == "Loja":
        if placing:
            placing = false
            if buying:
                money += 450
                owns_counter = false
                counter.visible = false
                buying = false
                _refresh()
                _save()
                info.text = "Compra cancelada."
            else:
                pos_counter = committed_counter
                counter.position = pos_counter
                counter.modulate = Color.WHITE
                info.text = "Movimentacao cancelada."
        else:
            move = Vector2.ZERO
            finger = -1
            popup.popup_centered(Vector2i(330,245))
    elif label == "Cliente":
        info.text = "Aproxime-se do cliente e pressione A."
    else:
        info.text = label+" - integracao pendente"

func _save() -> void:
    var f := FileAccess.open("user://pixel_pc_tycoon_v042.save",FileAccess.WRITE)
    if f != null:
        f.store_string(JSON.stringify({"cash":money,"owns_counter":owns_counter,"furniture_position":[committed_counter.x,committed_counter.y]}))

func _load() -> void:
    var path := "user://pixel_pc_tycoon_v042.save"
    if not FileAccess.file_exists(path):
        return
    var f := FileAccess.open(path,FileAccess.READ)
    if f == null:
        return
    var data: Variant = JSON.parse_string(f.get_as_text())
    if not (data is Dictionary):
        return
    money = maxi(0,int(data.get("cash",6500)))
    owns_counter = bool(data.get("owns_counter",false))
    counter.visible = indoors and owns_counter
    var coords: Variant = data.get("furniture_position",[670,405])
    if coords is Array and coords.size()==2:
        pos_counter = Vector2(float(coords[0]),float(coords[1]))
        committed_counter = pos_counter
        counter.position = pos_counter
