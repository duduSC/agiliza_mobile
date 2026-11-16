/// TODOS os caminhos da API usados pelo app (AGENT.md 5 e 6.4).
///
/// `// PROVISÓRIO`: caminho proposto pela T009 do backend e ainda não confirmado
/// pelo contrato final (`agente_backend/sugestoes-mobile/S001-...`).
/// O `motoboyId` nunca vai no caminho nem no corpo: o backend o tira do token.
library;

abstract final class Endpoints {
  // Autenticação (existem no backend).
  static const login = '/api/auth/login';
  static const refresh = '/api/auth/refresh';

  // Entregador.
  static const me = '/api/entregador/me'; // PROVISÓRIO
  static const disponibilidade = '/api/entregador/disponibilidade'; // PROVISÓRIO
  static const posicao = '/api/entregador/posicao'; // PROVISÓRIO
  static const loteAtivo = '/api/entregador/lote-ativo'; // PROVISÓRIO
  static String iniciarLote(String loteId) =>
      '/api/entregador/lotes/${Uri.encodeComponent(loteId)}/iniciar'; // PROVISÓRIO
  static String statusEntrega(String entregaId) =>
      '/api/entregador/entregas/${Uri.encodeComponent(entregaId)}/status'; // PROVISÓRIO
  static String contestarEntrega(String entregaId) =>
      '/api/entregador/entregas/${Uri.encodeComponent(entregaId)}/contestar'; // PROVISÓRIO
  static const acerto = '/api/entregador/acerto'; // PROVISÓRIO
}
