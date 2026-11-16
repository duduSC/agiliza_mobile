/// Refresh único e concorrente (AGENT.md 6.6, Constituição 6.2): se várias
/// requisições recebem 401 ao mesmo tempo, só um `POST /api/auth/refresh` é
/// feito e todas aguardam o mesmo resultado.
library;

import 'armazenamento_tokens.dart';
import 'sessao.dart';

typedef ChamarRefresh = Future<RespostaLogin> Function(String refreshToken);

class RenovadorSessao {
  RenovadorSessao({
    required this.armazenamento,
    required this.chamarRefresh,
  });

  final ArmazenamentoTokens armazenamento;
  final ChamarRefresh chamarRefresh;

  Future<bool>? _emAndamento;

  /// `true` se novos tokens foram salvos.
  Future<bool> renovar() {
    final atual = _emAndamento;
    if (atual != null) return atual;
    final nova = _executar().whenComplete(() => _emAndamento = null);
    _emAndamento = nova;
    return nova;
  }

  Future<bool> _executar() async {
    final tokens = await armazenamento.ler();
    if (tokens == null) return false;
    try {
      final resposta = await chamarRefresh(tokens.refreshToken);
      await armazenamento.salvar(resposta.tokens);
      return true;
    } catch (_) {
      // Qualquer falha no refresh encerra a sessão (quem chamou faz o logout).
      return false;
    }
  }
}
