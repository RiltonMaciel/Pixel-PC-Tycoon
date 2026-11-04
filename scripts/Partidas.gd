extends RefCounted

var base := ""
var legado := ""
var atual := 1
var ultimo_erro := ""

func configurar(caminho: String, antigo: String) -> void:
    base = caminho
    legado = antigo

func caminho(slot: int) -> String:
    return base if slot == 1 else base + ".slot%d" % slot

func caminho_legado(slot: int) -> String:
    return legado if slot == 1 else ""

func ler_selecao() -> bool:
    var config := ConfigFile.new()
    var erro := config.load(base + ".slots.cfg")
    if erro == ERR_FILE_NOT_FOUND:
        return true
    if erro != OK:
        return _erro("Nao foi possivel ler o slot escolhido: " + error_string(erro))
    var slot: Variant = config.get_value("partida","slot",null)
    if not slot is int or slot < 1 or slot > 3:
        return _erro("Selecao de slot invalida. Escolha uma partida no Menu; saves preservados.")
    atual = slot
    return true

func selecionar(slot: int) -> bool:
    if slot < 1 or slot > 3:
        return _erro("Slot invalido: escolha de 1 a 3.")
    var destino := base + ".slots.cfg"
    var config := ConfigFile.new()
    config.set_value("partida","slot",slot)
    var erro := config.save(destino + ".tmp")
    if erro != OK:
        return _erro("Falha ao salvar selecao de slot: " + error_string(erro))
    if FileAccess.file_exists(destino):
        erro = DirAccess.rename_absolute(destino,destino + ".bak")
        if erro != OK:
            return _erro("Falha ao preservar selecao anterior: " + error_string(erro))
    erro = DirAccess.rename_absolute(destino + ".tmp",destino)
    if erro != OK:
        var mensagem := "Falha ao concluir selecao de slot: " + error_string(erro)
        if FileAccess.file_exists(destino + ".bak"):
            var restauracao := DirAccess.rename_absolute(destino + ".bak",destino)
            if restauracao != OK:
                mensagem += ". Falha ao restaurar selecao: " + error_string(restauracao)
        return _erro(mensagem)
    atual = slot
    ultimo_erro = ""
    return true

func _erro(mensagem: String) -> bool:
    ultimo_erro = mensagem
    push_error(mensagem)
    return false
