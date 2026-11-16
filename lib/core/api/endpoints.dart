/// TODOS os caminhos da API usados pelo app (AGENT.md 5 e 6.4).
///
/// Contrato confirmado pela T009 do backend (CONCLUIDA em 15/11/2026), descrito
/// em `agente_backend/sugestoes-mobile/S001-endpoints-do-entregador.md` e
/// conferido no `EntregadorController`. Nenhum caminho é `PROVISÓRIO` hoje; um
/// caminho novo, ainda não confirmado, deve ser marcado com `// PROVISÓRIO`.
///
/// O `motoboyId` nunca vai no caminho nem no corpo: o backend o tira do token.
library;

abstract final class Endpoints {
  // Autenticação.
  static const login = '/api/auth/login';
  static const refresh = '/api/auth/refresh';

  // Entregador (perfil ENTREGADOR + canal APP).
  static const me = '/api/entregador/me';
  static const disponibilidade = '/api/entregador/disponibilidade';
  static const posicao = '/api/entregador/posicao';

  /// `200` com o lote, ou `204` sem lote.
  static const loteAtivo = '/api/entregador/lote-ativo';
  static String iniciarLote(String loteId) =>
      '/api/entregador/lotes/${Uri.encodeComponent(loteId)}/iniciar';
  static String statusEntrega(String entregaId) =>
      '/api/entregador/entregas/${Uri.encodeComponent(entregaId)}/status';
  static String contestarEntrega(String entregaId) =>
      '/api/entregador/entregas/${Uri.encodeComponent(entregaId)}/contestar';

  /// Sem parâmetros: o dia atual.
  static const acerto = '/api/entregador/acerto';
}
