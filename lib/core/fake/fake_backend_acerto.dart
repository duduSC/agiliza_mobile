/// Acerto no backend em memória (contrato S001, itens 7 e 8).
///
/// SIMULAÇÃO DO SERVIDOR: os totais são apurados aqui, no papel do backend
/// (DVP 1.5.5, passo 8). A tela nunca soma nada: só exibe o que vier.
library;

import '../api/erros.dart';
import 'fake_backend.dart';

extension FakeBackendAcerto on FakeBackend {
  ErroApi _erroAcerto(int status, String codigo, String mensagem) =>
      ErroApi(status: status, codigo: codigo, mensagemServidor: mensagem);

  /// Valores de repasse "congelados" pelo servidor para as entregas do lote de
  /// exemplo (faixas 0–3 km = R$ 9,00 e 3–5 km = R$ 12,00).
  Map<String, Object?> _linhaDaEntrega(Map<String, Object?> e) {
    final segunda = (e['ordemRota'] as int?) == 2;
    return {
      'entregaId': e['id'],
      'nomeCliente': e['nomeCliente'],
      'finalizadaEm': e['finalizadaEm'],
      'status': e['status'],
      'distanciaKm': segunda ? 4.7 : 2.1,
      'faixaDeKm': segunda ? 3.0 : 0.0,
      'faixaAteKm': segunda ? 5.0 : 3.0,
      'foraDeArea': false,
      'valorRepasse': segunda ? 12.0 : 9.0,
      'situacao': contestadas.contains(e['id']) ? 'EM_REVISAO' : 'A_ACERTAR',
      'reciboId': null,
    };
  }

  List<Map<String, Object?>> _linhas() => [
        for (final l in linhasIniciaisAcerto)
          {
            ...l,
            if (contestadas.contains(l['entregaId'])) 'situacao': 'EM_REVISAO',
          },
        for (final e in entregasFinalizadas) _linhaDaEntrega(e),
      ];

  num _soma(List<Map<String, Object?>> linhas, String situacao) => linhas
      .where((l) => l['situacao'] == situacao)
      .fold<num>(0, (t, l) => t + ((l['valorRepasse'] as num?) ?? 0));

  /// `GET /api/entregador/acerto`.
  Future<Map<String, Object?>> buscarAcerto() async {
    await esperarLatencia();
    final linhas = _linhas();
    return {
      'extrato': {
        'motoboyId': FakeBackend.motoboyId,
        'nomeEntregador': motoboy.nome,
        'periodoInicio': '2026-11-17T00:00:00',
        'periodoFim': '2026-11-17T23:59:59.999999999',
        'linhas': linhas,
        'totalDevido': _soma(linhas, 'A_ACERTAR'),
        'totalConsolidado': _soma(linhas, 'CONSOLIDADA'),
        'totalEmRevisao': _soma(linhas, 'EM_REVISAO'),
        'possuiValorIndefinido': linhas.any((l) => l['valorRepasse'] == null),
      },
      'dataReferenciaCaixa': '2026-11-17',
      'statusCaixa': statusCaixa,
      'contestacaoPermitida': statusCaixa == 'ABERTO' || statusCaixa == 'REABERTO',
    };
  }

  /// `POST /api/entregador/entregas/{id}/contestar`.
  Future<void> contestar(String entregaId) async {
    await esperarLatencia();
    final linha = _linhas().where((l) => l['entregaId'] == entregaId).firstOrNull;
    if (linha == null) {
      throw _erroAcerto(404, CodigosErro.recursoNaoEncontrado, 'Recurso não encontrado');
    }
    if (statusCaixa != 'ABERTO' && statusCaixa != 'REABERTO') {
      throw _erroAcerto(422, CodigosErro.caixaFechado, 'O caixa do dia está fechado');
    }
    if (linha['situacao'] != 'A_ACERTAR') {
      throw _erroAcerto(422, CodigosErro.regraNegocioViolada,
          'Esta entrega já está em análise');
    }
    contestadas.add(entregaId);
  }
}
