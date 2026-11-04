extends SceneTree

const GAME = preload("res://scripts/RuaComercial.gd")
const POSICAO := Vector2(700,400)
var falhas := 0
var verificacoes := 0
var temporario := "user://medicao_balcao_" + str(Time.get_ticks_usec())

class Contornos extends Node2D:
    var colisao := PackedVector2Array()
    var caixa := Rect2()
    var origem := Vector2.ZERO
    var tamanho := Vector2i.ZERO

    func _draw() -> void:
        for u in range(tamanho.x + 1):
            var inicio := origem + GAME.INTERIOR.U * u
            draw_line(inicio,inicio + GAME.INTERIOR.V * tamanho.y,Color(0.3,0.7,1,0.25),1)
        for v in range(tamanho.y + 1):
            var inicio := origem + GAME.INTERIOR.V * v
            draw_line(inicio,inicio + GAME.INTERIOR.U * tamanho.x,Color(0.3,0.7,1,0.25),1)
        if colisao.is_empty():
            return
        draw_colored_polygon(colisao,Color(1,0.2,0.2,0.15))
        var fechado := colisao.duplicate()
        fechado.append(colisao[0])
        draw_polyline(fechado,Color.YELLOW,2)
        draw_rect(caixa,Color.CYAN,false,1)
        draw_line(POSICAO - Vector2(8,0),POSICAO + Vector2(8,0),Color.RED,2)
        draw_line(POSICAO - Vector2(0,8),POSICAO + Vector2(0,8),Color.RED,2)

func _initialize() -> void:
    root.size = Vector2i(864,1536)
    root.content_scale_size = Vector2i(432,768)
    root.gui_embed_subwindows = true
    call_deferred("_run")

func verificar(condicao: bool, mensagem: String) -> void:
    verificacoes += 1
    if not condicao:
        falhas += 1
    print("PASS: " if condicao else "FAIL: ",mensagem)

func coordenadas(pontos: PackedVector2Array) -> Array:
    var resultado: Array = []
    for ponto in pontos:
        resultado.append([ponto.x,ponto.y])
    return resultado

func acompanha_grid(poligono: PackedVector2Array) -> bool:
    if poligono.size() != 4:
        return false
    for indice in range(poligono.size()):
        var aresta := poligono[(indice + 1) % poligono.size()] - poligono[indice]
        if aresta.is_zero_approx() or not is_equal_approx(absf(aresta.x),2.0 * absf(aresta.y)):
            return false
    return true

func _run() -> void:
    var destino := OS.get_environment("PIXEL_BALCAO_OUTPUT_DIR")
    if destino.is_empty() or not DirAccess.dir_exists_absolute(destino):
        push_error("Defina PIXEL_BALCAO_OUTPUT_DIR para uma pasta existente de evidencias.")
        quit(1)
        return
    if DisplayServer.get_name() == "headless":
        push_error("A medicao exige renderizacao para produzir as quatro capturas.")
        quit(1)
        return
    if DirAccess.make_dir_absolute(temporario) != OK:
        push_error("Nao foi possivel criar a pasta isolada de saves.")
        quit(1)
        return
    create_timer(45).timeout.connect(func() -> void:
        push_error("Medicao excedeu 45 segundos; verifique os logs e a pasta temporaria.")
        quit(1))
    var cena := load(str(ProjectSettings.get_setting("application/run/main_scene"))) as PackedScene
    var game: GAME = cena.instantiate()
    game.save_path = temporario.path_join("save.json")
    game.legacy_path = temporario.path_join("legacy.save")
    root.add_child(game)
    game.set_physics_process(false)
    await game._change_area(true)
    for movel in game.moveis:
        movel.queue_free()
    game.moveis.clear()
    await process_frame
    var contornos := Contornos.new()
    contornos.z_index = 3900
    contornos.origem = game.cadastro["origem"]
    contornos.tamanho = game.cadastro["modulos"]
    game.add_child(contornos)
    var medidas: Array = []
    var geometria_valida := true
    for angulo in [0,90,180,270]:
        var movel := game._create_furniture("balcao_pc_store",POSICAO,angulo)
        var textura_inicial: Texture2D = movel.visual.texture
        verificar(game._can_place(movel),"Posicao aceita no piso: %d" % angulo)
        game.selecionado = movel
        for volta in range(4):
            game._edit_action("Girar")
        verificar(movel.ANGULOS[movel.orientacao] == angulo and movel.visual.texture == textura_inicial,
            "Quatro giros retornam a mesma vista: %d" % angulo)
        game._cancel_edit()
        game.selecionado = movel
        game._edit_action("Mover")
        movel.position += Vector2(16,8)
        game._edit_action("Girar")
        game._cancel_edit()
        verificar(movel.position == POSICAO and movel.ANGULOS[movel.orientacao] == angulo
            and movel.visual.texture == textura_inicial,"Cancelar restaura posicao e vista: %d" % angulo)
        verificar(game._save(),"Gravacao isolada: %d" % angulo)
        var leitor := GAME.GERENCIADOR.new()
        var dados := leitor.ler(game.save_path,game.legacy_path)
        if dados.is_empty():
            verificar(false,"Leitura isolada: %d" % angulo)
            break
        game.gestor_imoveis.estados = leitor.estados.duplicate(true)
        game._restore_furniture()
        await process_frame
        movel = game.moveis[0]
        verificar(movel.position == POSICAO and movel.ANGULOS[movel.orientacao] == angulo
            and movel.visual.texture == textura_inicial,"Reload preserva posicao e vista: %d" % angulo)
        var poligono := movel.poligono_colisao(POSICAO)
        var centro := Vector2.ZERO
        for ponto in poligono:
            centro += ponto / float(poligono.size())
        verificar(not game._walkable(centro),"Centro da colisao bloqueia caminhada: %d" % angulo)
        verificar(game._walkable(POSICAO + Vector2(200,0)),"Piso afastado permanece livre: %d" % angulo)
        var bbox := movel.visual.texture.get_image().get_used_rect()
        var escala := movel.visual.scale
        var posicao_opaca := movel.visual.to_global(movel.visual.offset + Vector2(bbox.position))
        var alinhado := acompanha_grid(poligono)
        geometria_valida = geometria_valida and alinhado
        var dimensoes := movel.dimensoes_colisao()
        var canvas := movel.visual.texture.get_size()
        medidas.append({
            "angulo":angulo,
            "canvas":[canvas.x,canvas.y],
            "bbox_alfa":[bbox.position.x,bbox.position.y,bbox.end.x,bbox.end.y],
            "escala":[escala.x,escala.y],
            "pivo_canvas":[-movel.visual.offset.x,-movel.visual.offset.y],
            "posicao_mundo":[POSICAO.x,POSICAO.y],
            "tamanho_opaco_mundo":[bbox.size.x * escala.x,bbox.size.y * escala.y],
            "dimensoes_colisao":[dimensoes.x,dimensoes.y],
            "colisao_local":coordenadas(movel.poligono_colisao(Vector2.ZERO)),
            "colisao_sem_margem_alinha_grid_2_1":alinhado,
            "pivo_fisico_aprovado":false,
        })
        contornos.colisao = poligono
        contornos.caixa = Rect2(posicao_opaca,Vector2(bbox.size) * escala)
        contornos.queue_redraw()
        game.top_label.text = "BASELINE BALCAO | %d graus" % angulo
        game.info.text = "Amarelo: colisao | Ciano: alfa\nVermelho: pivo | Azul: grid 128x64"
        await process_frame
        await RenderingServer.frame_post_draw
        var erro := root.get_texture().get_image().save_png(destino.path_join("balcao_%03d.png" % angulo))
        verificar(erro == OK,"Captura renderizada: %d" % angulo)
        movel.queue_free()
        game.moveis.clear()
        await process_frame
    game.queue_free()
    await process_frame
    for nome in DirAccess.get_files_at(temporario):
        verificar(DirAccess.remove_absolute(temporario.path_join(nome)) == OK,"Limpeza de " + nome)
    verificar(DirAccess.remove_absolute(temporario) == OK,"Limpeza da pasta isolada")
    var relatorio := {
        "engine":Engine.get_version_info()["string"],
        "item":"balcao_pc_store",
        "escala_do_pr_9_aplicada":false,
        "verificacoes":verificacoes,
        "falhas_de_comportamento":falhas,
        "geometria_colisao_2_1":"APROVADA" if geometria_valida and medidas.size() == 4 else "REPROVADA",
        "arte_e_pivo_fisico":"NAO APROVADOS; requerem referencia e decisao artistica",
        "medidas":medidas,
    }
    var arquivo := FileAccess.open(destino.path_join("medidas.json"),FileAccess.WRITE)
    if arquivo == null:
        push_error("Falha ao abrir relatorio: " + error_string(FileAccess.get_open_error()))
        quit(1)
        return
    arquivo.store_string(JSON.stringify(relatorio,"  "))
    arquivo.flush()
    var erro := arquivo.get_error()
    arquivo.close()
    if erro != OK:
        push_error("Falha ao escrever relatorio: " + error_string(erro))
        quit(1)
        return
    print("RESULT: %d passed, %d failed" % [verificacoes - falhas,falhas])
    print("GEOMETRIA_COLISAO_2_1: ",relatorio["geometria_colisao_2_1"])
    quit(1 if falhas > 0 else (0 if geometria_valida and medidas.size() == 4 else 2))
