# Bairro Vivo 2.1 — Lote 1 / prévia isolada

Branch: `feature/bairro-vivo-2-1-jardineiras`.

A cena `addons/bairro_vivo_lote1/JardineirasVisualQA.tscn` instancia a cena original da rua e adiciona jardineiras de teste, sem substituir artes aprovadas. A prévia usa os eixos exteriores U=(64,20), V=(-64,32) e pivôs **provisórios**.

**PENDÊNCIA BLOQUEANTE:** os oito arquivos PNG do pacote local `Bairro_Vivo_2_1_Lote1_preview_godot_v9.zip` ainda precisam ser adicionados em `Assets/BairroVivo21/Vegetacao/Jardineiras/`. O script detecta recursos ausentes e não altera o jogo principal. Não declarar sprites integrados ou APK visual validado até que os binários sejam incluídos.

Para testar no Godot: abrir a cena QA e pressionar F6 para mostrar os pivôs. Conferir proporção, bases, calçada e colisões antes de integrar à cena principal.
