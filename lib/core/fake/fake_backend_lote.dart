/// Ações do lote no backend em memória (contrato S001, itens 5 e 6), com a
/// máquina de estados do DVP 1.4.4. Simulação do servidor, não do app.
library;

import '../api/erros.dart';
import '../dominio/enums.dart';
import 'fake_backend.dart';

extension FakeBackendLote on FakeBackend {
  ErroApi _erroLote(int status, String codigo, String mensagem) =>
      ErroApi(status: status, codigo: codigo, mensagemServidor: mensagem);

  List<Map<String, Object?>> get _entregas =>
      (loteAtivo?['entregas'] as List<Object?>? ?? const [])
          .cast<Map<String, Object?>>();

  /// `POST /api/entregador/lotes/{id}/iniciar`.
  Future<Map<String, Object?>> iniciarLote(String loteId) async {
    await esperarLatencia();
    final lote = loteAtivo;
    if (lote == null || lote['id'] != loteId) {
      throw _erroLote(404, 'RECURSO_NAO_ENCONTRADO', 'Recurso não encontrado');
    }
    if (lote['status'] != StatusLote.DESPACHADO.name) {
      throw _erroLote(422, CodigosErro.transicaoEstadoInvalida,
          'Transição de estado inválida para Lote');
    }
    lote['status'] = StatusLote.EM_ROTA.name;
    for (final e in _entregas) {
      if (e['status'] == StatusEntrega.DESPACHADA.name) {
        e['status'] = StatusEntrega.EM_ROTA.name;
      }
    }
    return lote;
  }

  /// `POST /api/entregador/entregas/{id}/status`.
  Future<Map<String, Object?>> alterarStatusEntrega(
    String entregaId,
    Map<String, Object?> corpo,
  ) async {
    await esperarLatencia();
    ultimoCorpoStatus = corpo;
    Map<String, Object?>? entrega;
    for (final e in _entregas) {
      if (e['id'] == entregaId) entrega = e;
    }
    if (entrega == null) {
      throw _erroLote(404, 'RECURSO_NAO_ENCONTRADO', 'Recurso não encontrado');
    }
    final status = corpo['status'];
    final motivo = (corpo['motivoFalha'] as String?)?.trim() ?? '';
    if (corpo['ocorridoEm'] == null || status == null) {
      throw _erroLote(400, 'DADOS_INVALIDOS', 'status e ocorridoEm são obrigatórios');
    }
    if ((status != StatusEntrega.ENTREGUE.name && status != StatusEntrega.FALHA.name) ||
        entrega['status'] != StatusEntrega.EM_ROTA.name) {
      throw _erroLote(422, CodigosErro.transicaoEstadoInvalida,
          'Transição de estado inválida para Entrega');
    }
    if (status == StatusEntrega.FALHA.name && motivo.isEmpty) {
      throw _erroLote(422, CodigosErro.regraNegocioViolada, 'FALHA exige motivo');
    }
    if (motivo.length > 100) {
      throw _erroLote(400, 'DADOS_INVALIDOS', 'motivoFalha com mais de 100 caracteres');
    }
    entrega['status'] = status;
    entrega['motivoFalha'] = status == StatusEntrega.FALHA.name ? motivo : null;
    entrega['finalizadaEm'] = corpo['ocorridoEm'];

    final todasFinais = _entregas.every((e) =>
        StatusEntrega.fromJson(e['status']! as String).finalizada);
    if (todasFinais) concluirLoteAtivo();
    return entrega;
  }
}
