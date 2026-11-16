/// Ações permitidas ao entregador por status (AGENT.md 6.2, DVP 1.4.4,
/// Constituição 5.2). A tela só oferece a ação que esta tabela permite.
library;

import 'enums.dart';

/// Disponibilidades que o próprio entregador pode pedir.
const Set<StatusDisponibilidadeMotoboy> disponibilidadesPedidasPeloEntregador = {
  StatusDisponibilidadeMotoboy.ONLINE,
  StatusDisponibilidadeMotoboy.OFFLINE,
};

/// Status finais que o próprio entregador pode registrar numa entrega.
const Set<StatusEntrega> statusFinaisDoEntregador = {
  StatusEntrega.ENTREGUE,
  StatusEntrega.FALHA,
};

bool podeFicarOnline(StatusDisponibilidadeMotoboy atual) =>
    atual == StatusDisponibilidadeMotoboy.OFFLINE;

/// Em `EM_ROTA` o entregador **não** pode ficar offline.
bool podeFicarOffline(StatusDisponibilidadeMotoboy atual) =>
    atual == StatusDisponibilidadeMotoboy.ONLINE;

bool podeIniciarPercurso(StatusLote lote) => lote == StatusLote.DESPACHADO;

/// ENTREGUE e FALHA só a partir de uma entrega `EM_ROTA`.
bool podeFinalizarEntrega(StatusEntrega entrega) =>
    entrega == StatusEntrega.EM_ROTA;

/// Transição de entrega pedida pelo entregador é válida?
bool transicaoEntregaPermitida(StatusEntrega de, StatusEntrega para) =>
    podeFinalizarEntrega(de) && statusFinaisDoEntregador.contains(para);

/// Contestação (UC08 A1, E1, E2, Constituição 5.5): só numa linha ainda a
/// acertar (finalizada e sem revisão), com o caixa do período aceitando
/// correção e o backend permitindo (`contestacaoPermitida`, S001). Na dúvida,
/// vale o mais restritivo: as três condições precisam valer.
bool podeContestar({
  required SituacaoAcerto situacao,
  required StatusCaixa? statusCaixa,
  required bool contestacaoPermitida,
}) =>
    contestacaoPermitida &&
    situacao == SituacaoAcerto.A_ACERTAR &&
    statusCaixa != null &&
    statusCaixa.aceitaCorrecao;
