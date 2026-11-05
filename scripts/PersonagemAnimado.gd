extends Sprite2D

const ALTURA_REFERENCIA := 112.0
var direcao := "frente"
var personagem := ""
var tempo := 0.0
var quadros: Dictionary = {}
var acessorios: Node2D
var estilo := 0

func personalizar(valor: int) -> void:
    estilo = valor
    if acessorios == null:
        acessorios = preload("res://scripts/Aparencia.gd").new()
        add_child(acessorios)
    acessorios.configurar(estilo,direcao)

func configurar(id: String) -> void:
    personagem = id
    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    centered = false
    offset = Vector2(-80,-232)
    var altura_idle := 0
    for lado in ["frente","costas","esquerda","direita"]:
        var frames: Array[Texture2D] = []
        var acoes := ["idle","passo_a","idle","passo_b"] if id == "protagonista" else ["idle","passo"]
        for acao in acoes:
            var path := "res://Assets/Personagens/Modulares/%s/%s_%s_%s.png" % [id,id,lado,acao]
            frames.append(load(path) as Texture2D)
        quadros[lado] = frames
        altura_idle = maxi(altura_idle,frames[0].get_image().get_used_rect().size.y)
    scale = Vector2.ONE * (ALTURA_REFERENCIA / altura_idle)
    atualizar(Vector2.ZERO,0.0)

func atualizar(movimento: Vector2, delta: float) -> void:
    if movimento.length_squared() > 0.001:
        if absf(movimento.x) > absf(movimento.y):
            direcao = "direita" if movimento.x > 0 else "esquerda"
        else:
            direcao = "frente" if movimento.y > 0 else "costas"
        tempo += delta
    else:
        tempo = 0.0
    var frames: Array = quadros[direcao]
    texture = frames[int(tempo * 8.0) % frames.size()]
    z_index = int(position.y)
    if acessorios != null:
        acessorios.configurar(estilo,direcao)

## Muda somente a orientacao visual de um NPC parado, usando sprites idle existentes.
## Nao altera posicao, escala, textura-base dos quadros ou colisoes.
func olhar(lado: String) -> void:
    if not quadros.has(lado):
        return
    direcao = lado
    tempo = 0.0
    var frames: Array = quadros[lado]
    if not frames.is_empty():
        texture = frames[0]
    if acessorios != null:
        acessorios.configurar(estilo, direcao)
