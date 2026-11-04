extends SceneTree

const OBJETIVOS = preload("res://scripts/Objetivos.gd")
const CAMPANHA = preload("res://scripts/Campanha.gd")
const PECAS = preload("res://scripts/CatalogoPecas.gd")
const COMERCIO = preload("res://scripts/Comercio.gd")
const CLIENTES = preload("res://scripts/Clientes.gd")
const EQUIPE = preload("res://scripts/Equipe.gd")
const BASE := ["caixa_ninho","placa_aurora","cpu_aurora","ram_brisa","fonte_clara","ssd_trilha","gpu_pixel","cooler_neve"]
var passed := 0
var failed := 0
var saldo := 20000

func _initialize() -> void:
    _datas()
    _datas_jogos()
    _validacao()
    _progresso()
    print("RESULT: %d passed, %d failed" % [passed,failed])
    quit(1 if failed else 0)

func check(ok: bool, texto: String) -> void:
    if ok:
        passed += 1
        print("PASS: ",texto)
    else:
        failed += 1
        printerr("FAIL: ",texto)

func _json(dados: Dictionary) -> Dictionary:
    return JSON.parse_string(JSON.stringify(dados))

func _datas() -> void:
    var campanha := CAMPANHA.inicial()
    var ids := ["cpu_aurora_plus","ssd_trilha1000","ram_vento32","gpu_trovao400"]
    var dias := [8,14,21,28]
    for i in range(ids.size()):
        var id: String = ids[i]
        var dia: int = dias[i]
        var nivel := CAMPANHA.nivel_peca(id)
        check(CAMPANHA.dia_lancamento(id) == dia and CAMPANHA.lancamentos_no_dia(dia) == [id],"Data unica: " + id)
        check(not CAMPANHA.peca_liberada(id,campanha,3,dia-1),"Nao antecipa lancamento: " + id)
        check(CAMPANHA.peca_liberada(id,campanha,nivel,dia) and CAMPANHA.peca_liberada(id,campanha,nivel,365),"Disponivel no dia e permanentemente depois: " + id)
        check(not CAMPANHA.peca_liberada(id,campanha,nivel-1,dia),"Data nao ignora nivel: " + id)
        check(not CAMPANHA.peca_liberada(id,campanha,3),"API antiga nao antecipa geracao futura: " + id)
        var legado := campanha.duplicate(true)
        legado["pecas_legadas"].append(id)
        check(CAMPANHA.validar(_json(legado)) and CAMPANHA.peca_liberada(id,legado,1,1),"Acesso adquirido sobrevive a data/nivel: " + id)
        var loja := COMERCIO.new()
        loja.comprar(id,saldo)
        check(id in CAMPANHA.migrar(loja.estado)["pecas_legadas"],"Migracao preserva pedido adquirido: " + id)
    for dia in [0,1,7,9,13,15,20,22,27,29,36]:
        check(CAMPANHA.lancamentos_no_dia(dia).is_empty(),"Sem lancamento adicional no dia %d" % dia)
    check(CAMPANHA.dia_lancamento("inexistente") == 0 and not CAMPANHA.peca_liberada("inexistente",campanha,3,100),"ID desconhecido nao e liberado")
    for id in PECAS.PECAS:
        if id in CAMPANHA.LANCAMENTOS:
            continue
        var nivel := 3 if id in CAMPANHA.AVANCADAS else 2 if id in CAMPANHA.INTERMEDIARIAS else 1
        for atual in [1,2,3]:
            check(CAMPANHA.peca_liberada(id,campanha,atual) == (nivel <= atual),"Tres niveis anteriores preservados: %s/%d" % [id,atual])
    check(CAMPANHA.meta_diaria(170)["custo_pc"] == 1780 and PECAS.PRECO_PC == 2450,"Custos e preco do PC anterior preservados")
    var configuracao := {}
    for i in range(BASE.size()):
        configuracao[PECAS.CATEGORIAS[i]] = BASE[i]
    configuracao["cpu"] = ids[0]
    configuracao["ssd"] = ids[1]
    check(PECAS.incompatibilidade(configuracao).is_empty(),"CPU e SSD futuros usam plataforma A1/SATA existente")
    configuracao.merge({"gabinete":"caixa_torre","placa":"placa_nova","cpu":"cpu_nova","ram":ids[2],
        "ssd":"ssd_veloz","gpu":ids[3],"fonte":"fonte_firme","cooler":"cooler_nova"},true)
    check(PECAS.incompatibilidade(configuracao).is_empty(),"RAM e GPU futuras usam DDR5, PCIe, fonte e gabinete existentes")
    configuracao["fonte"] = "fonte_clara"
    check(not PECAS.incompatibilidade(configuracao).is_empty(),"GPU futura continua exigindo conectores corretos")

func _datas_jogos() -> void:
    var campanha := CAMPANHA.inicial()
    check(CAMPANHA.jogo_liberado("",campanha,1),"PC sem jogo continua disponivel")
    for id in CAMPANHA.JOGOS.JOGOS:
        var dia := int(CAMPANHA.JOGOS.buscar(id).get("lancamento",1))
        var nivel := CAMPANHA.nivel_jogo(id)
        check(not CAMPANHA.jogo_liberado(id,campanha,3,dia-1),"Jogo indisponivel antes do lancamento: " + id)
        check(CAMPANHA.jogo_liberado(id,campanha,nivel,dia) and CAMPANHA.jogo_liberado(id,campanha,nivel,dia+336),"Jogo liberado na data e em anos posteriores: " + id)
        check(not CAMPANHA.jogo_liberado(id,campanha,nivel-1,dia),"Lancamento nao ignora nivel do jogo: " + id)
        check(CAMPANHA.jogo_liberado(id,campanha,nivel) == (dia <= 1),"Argumento padrao preserva jogos antigos sem antecipar futuros: " + id)
        var legado := campanha.duplicate(true)
        legado["jogos_legados"].append(id)
        check(CAMPANHA.validar(_json(legado)) and CAMPANHA.jogo_liberado(id,legado,1,1),"Jogo adquirido permanece liberado independente da data/nivel: " + id)

func _validacao() -> void:
    var objetivos := OBJETIVOS.new()
    check(OBJETIVOS.validar(_json(objetivos.estado)),"Bloco inicial aceita round-trip JSON")
    check(objetivos.carregar_save({"versao":2}) and objetivos.estado == OBJETIVOS.inicial(),"Bloco ausente migra vazio sem conquistas artificiais")
    var validos := {"versao":1,"concluidos":[{"id":"primeira_venda","dia":8},{"id":"emprego","dia":14}]}
    check(objetivos.carregar(_json(validos)),"Dias/versao inteiros representados como float JSON aceitos")
    var salvo := objetivos.estado.duplicate(true)
    var invalidos: Array = [null,[],true,{},{"versao":true,"concluidos":[]},{"versao":2,"concluidos":[]},
        {"versao":1,"concluidos":{}},{"versao":1,"concluidos":[],"dinheiro":100},
        {"versao":1,"concluidos":[null]},{"versao":1,"concluidos":[{"id":"desconhecido","dia":1}]},
        {"versao":1,"concluidos":[{"id":true,"dia":1}]},
        {"versao":1,"concluidos":[{"id":"emprego"}]},
        {"versao":1,"concluidos":[{"id":"emprego","dia":1,"premio":100}]},
        {"versao":1,"concluidos":[{"id":"emprego","dia":2},{"id":"emprego","dia":2}]},
        {"versao":1,"concluidos":[{"id":"emprego","dia":2},{"id":"reputacao","dia":1}]}]
    for dia in [0,-1,1.5,true,"8",INF,NAN,9007199254740992.0]:
        invalidos.append({"versao":1,"concluidos":[{"id":"emprego","dia":dia}]})
    for dados in invalidos:
        check(not OBJETIVOS.validar(dados) and not objetivos.carregar(dados) and objetivos.estado == salvo,"Rejeita bloco invalido atomicamente")
    for bloco in [null,[],{},true]:
        check(not objetivos.carregar_save({"objetivos":bloco}) and objetivos.estado == salvo,"Bloco presente corrompido nao e migrado silenciosamente")
    validos["concluidos"].clear()
    check(objetivos.estado == salvo,"Carregamento nao compartilha referencias externas")
    check(not objetivos.concluido("desconhecido"),"Consulta desconhecida nao cria conquista")

func _comprar(loja: COMERCIO, id: String) -> void:
    saldo += loja.comprar(id,saldo)
    loja.avancar(30)
    var pedido: Dictionary = loja.estado["pedidos"].back()
    check(loja.receber(int(pedido["id"])),"Compra e entrega reais: " + id)

func _encerrar(loja: COMERCIO, clientes: CLIENTES, pc: bool, produto: String = "") -> void:
    var cliente: String = clientes.estado["atual"]
    loja.estado["cliente"]["fase"] = "aguardando"
    var receita := loja.vender()
    saldo += receita
    clientes.finalizar(cliente,2,"compra",produto,receita,int(loja.estado["montagem"]["id"]) if pc else 0)
    check(receita > 0 and COMERCIO.validar(loja.estado) and CLIENTES.validar(clientes.estado),"Venda real validada")
    loja.estado["cliente"] = {}

func _progresso() -> void:
    var objetivos := OBJETIVOS.new()
    var loja := COMERCIO.new()
    var clientes := CLIENTES.new()
    var equipe := EQUIPE.new()
    check(objetivos.atualizar(loja.estado,clientes.estado,equipe.estado).is_empty(),"Objetivos opcionais nao bloqueiam inicio nem concedem progresso")
    _comprar(loja,"ram_brisa")
    check(objetivos.atualizar(loja.estado,clientes.estado,equipe.estado).is_empty(),"Compra nao e venda")
    check(loja.criar_cliente("ram_brisa"),"Atender venda de peca")
    clientes.vincular_manual("ram_brisa",false,180)
    _encerrar(loja,clientes,false,"ram_brisa")
    check(objetivos.atualizar(loja.estado,clientes.estado,equipe.estado,2) == ["primeira_venda"],"Primeira venda depende de pagamento real")
    for repeticao in range(4):
        for id in BASE:
            _comprar(loja,id)
        check(loja.criar_cliente("",true),"Criar PC real")
        clientes.vincular_manual("",true,2450)
        for i in range(BASE.size()):
            check(loja.instalar(BASE[i],PECAS.CATEGORIAS[i]),"Instalar peca real: " + BASE[i])
        check(loja.conectar() and loja.testar(),"Conectar e testar PC")
        if repeticao == 0:
            check(not "primeiro_pc" in objetivos.atualizar(loja.estado,clientes.estado,equipe.estado,2),"PC apenas testado nao conta como entregue")
        _encerrar(loja,clientes,true)
    var novos := objetivos.atualizar(loja.estado,clientes.estado,equipe.estado,2)
    check("primeiro_pc" in novos and "reputacao" in novos and "crescimento" in novos,"PCs vendidos, satisfacao e crescimento reconhecidos de estado real")
    check(loja.abrir_os("diagnostico"),"Abrir OS real sem insumos")
    clientes.vincular_servico(120)
    loja.estado["cliente"]["fase"] = "aguardando"
    check(loja.diagnosticar_os() and loja.aprovar_os() and loja.executar_os() and loja.testar_os(),"Diagnosticar, executar e testar OS real")
    check(not objetivos.concluido("primeira_os") and objetivos.atualizar(loja.estado,clientes.estado,equipe.estado,2).is_empty(),"OS aberta/pronta nao conta antes do pagamento")
    _encerrar(loja,clientes,false)
    check(objetivos.atualizar(loja.estado,clientes.estado,equipe.estado,2) == ["primeira_os"],"OS entregue e paga reconhecida")
    check(equipe.contratar("lia") and equipe.demitir("lia"),"Historico real de emprego")
    check(objetivos.atualizar(loja.estado,clientes.estado,equipe.estado,2) == ["emprego"],"Contrato persistido reconhece emprego mesmo apos demissao")
    var comercio_antes := loja.estado.duplicate(true)
    var clientes_antes := clientes.estado.duplicate(true)
    var equipe_antes := equipe.estado.duplicate(true)
    var salvo := objetivos.estado.duplicate(true)
    check(objetivos.estado["concluidos"].size() == 6 and OBJETIVOS.validar(_json(salvo)),"Seis conquistas opcionais persistiveis")
    check(objetivos.atualizar(loja.estado,clientes.estado,equipe.estado,28).is_empty() and objetivos.estado == salvo,"Reavaliacao idempotente preserva dia original")
    var recarregado := OBJETIVOS.new()
    check(recarregado.carregar_save({"objetivos":_json(salvo)}) and recarregado.atualizar(loja.estado,clientes.estado,equipe.estado,28).is_empty(),"Reload JSON nao repete registros")
    check(objetivos.atualizar({},clientes.estado,equipe.estado,28).is_empty() and not objetivos.ultimo_erro.is_empty() and objetivos.estado == salvo,"Fonte invalida rejeitada sem perda")
    check(objetivos.atualizar(loja.estado,clientes.estado,equipe.estado,1).is_empty() and not objetivos.ultimo_erro.is_empty(),"Data retroativa rejeitada")
    check(objetivos.atualizar(loja.estado,clientes.estado,equipe.estado,0).is_empty() and not objetivos.ultimo_erro.is_empty(),"Dia zero rejeitado")
    check(objetivos.atualizar(COMERCIO.inicial(),CLIENTES.inicial(),EQUIPE.inicial(),28).is_empty() and objetivos.estado == salvo,"Queda de metricas nao retira acesso adquirido")
    check(loja.estado == comercio_antes and clientes.estado == clientes_antes and equipe.estado == equipe_antes,"Nenhuma alteracao em dinheiro, estoque, clientes ou contratos pelos objetivos")
    check(saldo > 0,"Fluxo real manteve caixa positivo, sem premio artificial")
