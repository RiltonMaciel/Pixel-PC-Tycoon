extends SceneTree
## Godot --headless --path . --script res://tests/test_vento_copa.gd
## Testa estrutura e preservacao de geometria; inspeção visual requer renderer.
const VIZINHANCA = preload("res://scripts/VizinhancaComercial.gd")
const VENTO = preload("res://scripts/Neighborhood/VentoCopa.gd")

func _initialize() -> void:
    call_deferred("_executar")

func _executar() -> void:
    var sprite := Sprite2D.new()
    sprite.name = "ArvoreTeste"
    sprite.texture = ImageTexture.create_from_image(_imagem())
    sprite.offset = Vector2(-10, -20)
    sprite.position = Vector2(100, 150)
    root.add_child(sprite)
    var original := sprite.texture
    var offset_original := sprite.offset
    var posicao_original := sprite.position
    var vento := VENTO.new()
    sprite.add_child(vento)
    await process_frame
    var ok := true
    ok = _check(sprite.texture == original, "textura original preservada") and ok
    ok = _check(sprite.offset == offset_original, "pivo original preservado") and ok
    ok = _check(sprite.position == posicao_original, "posicao original preservada") and ok
    ok = _check(sprite.material is ShaderMaterial, "material de vento instalado") and ok
    ok = _check(VIZINHANCA.new().arvores_animadas, "animacao habilitada por padrao") and ok
    sprite.queue_free()
    await process_frame
    print("BV-02 estrutural: ", "OK" if ok else "FALHOU")
    quit(0 if ok else 1)

func _imagem() -> Image:
    var imagem := Image.create(32, 48, false, Image.FORMAT_RGBA8)
    imagem.fill(Color(0, 0, 0, 0))
    imagem.set_pixel(16, 10, Color.GREEN)
    return imagem

func _check(condicao: bool, descricao: String) -> bool:
    if not condicao:
        push_error(descricao)
    return condicao
