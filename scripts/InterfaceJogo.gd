extends RefCounted

const PASSOS := [
    "Entre na PC Store pelo botao A. O jogo livre continua disponivel.",
    "Estoque: escolha fornecedor, compre pecas e receba a entrega.",
    "Cliente: aceite uma venda, pedido de PC ou ordem de servico.",
    "Montagem: instale gabinete, placa e componentes; conecte e teste.",
    "Entregue no balcao para receber. Financas mostra despesas e dividas.",
    "Contrate equipe, reforme a loja e consulte objetivos opcionais."
]

static func area_util(viewport: Vector2, tela: Vector2, segura: Rect2) -> Rect2:
    if tela.x <= 0 or tela.y <= 0 or segura.size.x <= 0 or segura.size.y <= 0:
        return Rect2(Vector2.ZERO,viewport)
    var fator := viewport / tela
    return Rect2(segura.position*fator,segura.size*fator).intersection(Rect2(Vector2.ZERO,viewport))
