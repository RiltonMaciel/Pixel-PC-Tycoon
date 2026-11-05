extends Node
## Efeito opt-in para vegetacao existente. Nao modifica PNG, pivô, colisao ou cena.
## Adicionar como filho de Sprite2D apenas apos validar visualmente no Godot.
## Usa deslocamento horizontal subpixel na copa, com base do tronco imovel.
## A textura e filtrada pelo Sprite2D existente (preferencialmente NEAREST).

@export var amplitude_pixels: float = 1.0
@export var ciclos_por_segundo: float = 0.28
@export_range(0.0, 1.0, 0.01) var inicio_copa: float = 0.58
@export var fase: float = 0.0

var _sprite: Sprite2D
var _tempo := 0.0
var _material_original: Material

const SHADER := """
shader_type canvas_item;
render_mode unshaded;
uniform float amplitude_px = 1.0;
uniform float fase = 0.0;
uniform float inicio_copa = 0.58;
void fragment() {
    vec2 uv = UV;
    // A parte inferior do sprite (base/solo) permanece intacta.
    float peso = 1.0 - smoothstep(0.0, max(1.0 - inicio_copa, 0.001), uv.y);
    float deslocamento = sin(fase + uv.y * 3.0) * amplitude_px * peso;
    vec2 amostra = uv + vec2(deslocamento * TEXTURE_PIXEL_SIZE.x, 0.0);
    if (amostra.x < 0.0 || amostra.x > 1.0) {
        COLOR = vec4(0.0);
    } else {
        COLOR = texture(TEXTURE, amostra);
    }
}
"""

func _ready() -> void:
    _sprite = get_parent() as Sprite2D
    if _sprite == null:
        push_warning("VentoCopa requer Sprite2D como pai.")
        set_process(false)
        return
    _material_original = _sprite.material
    var shader := Shader.new()
    shader.code = SHADER
    var material := ShaderMaterial.new()
    material.shader = shader
    _sprite.material = material
    _tempo = fase
    _aplicar()
    set_process(true)

func _process(delta: float) -> void:
    if delta <= 0.0 or not is_finite(delta):
        return
    _tempo = fposmod(_tempo + delta * TAU * maxf(ciclos_por_segundo, 0.0), TAU)
    _aplicar()

func _aplicar() -> void:
    if _sprite == null or not (_sprite.material is ShaderMaterial):
        return
    var material := _sprite.material as ShaderMaterial
    material.set_shader_parameter("amplitude_px", clampf(amplitude_pixels, 0.0, 2.0))
    material.set_shader_parameter("inicio_copa", clampf(inicio_copa, 0.0, 1.0))
    material.set_shader_parameter("fase", _tempo)

func _exit_tree() -> void:
    if is_instance_valid(_sprite):
        _sprite.material = _material_original
