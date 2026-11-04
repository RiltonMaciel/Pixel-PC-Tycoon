@tool
extends Control
## Inspector visual dos sprites da montagem. Use a cena correspondente no editor.
## Somente leitura: não modifica sprites ou dados do jogo.

@export_dir var sprite_root: String = "res://assets/minigames/pc_assembly"
@export var zoom_factor: int = 3

var paths: PackedStringArray = []
var current_index := 0
var sprite: TextureRect
var caption: Label

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    sprite = TextureRect.new()
    sprite.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(sprite)
    caption = Label.new()
    caption.position = Vector2(12, 12)
    caption.add_theme_color_override("font_color", Color.WHITE)
    add_child(caption)
    _collect(sprite_root)
    paths.sort()
    _show_current()

func _collect(folder: String) -> void:
    var directory := DirAccess.open(folder)
    if directory == null:
        return
    directory.list_dir_begin()
    var entry := directory.get_next()
    while entry != "":
        if directory.current_is_dir():
            if not entry.begins_with("."):
                _collect(folder.path_join(entry))
        elif entry.to_lower().ends_with(".png"):
            paths.append(folder.path_join(entry))
        entry = directory.get_next()
    directory.list_dir_end()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_RIGHT:
            current_index = mini(current_index + 1, paths.size() - 1)
            _show_current()
        elif event.keycode == KEY_LEFT:
            current_index = maxi(current_index - 1, 0)
            _show_current()

func _show_current() -> void:
    if paths.is_empty():
        caption.text = "Nenhum PNG encontrado em: " + sprite_root
        return
    var texture := load(paths[current_index]) as Texture2D
    sprite.texture = texture
    caption.text = "%d/%d — %s (%s)" % [
        current_index + 1, paths.size(), paths[current_index],
        str(texture.get_size()) if texture != null else "erro"
    ]
