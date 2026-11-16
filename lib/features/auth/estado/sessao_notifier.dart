import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/erros.dart';
import '../../../core/dominio/enums.dart';
import '../../../core/localizacao/ultima_posicao.dart';
import '../../../core/providers_core.dart';
import '../../../core/sessao/sessao.dart';
import '../data/auth_repository.dart';

/// Sessão do entregador (UC07, Constituição 4.3, 6.1 e 6.2).
class SessaoNotifier extends Notifier<EstadoSessao> {
  @override
  EstadoSessao build() {
    ref.listen(eventoSessaoExpiradaProvider, (_, _) => unawaited(_expirar()));
    unawaited(Future.microtask(_restaurar));
    return const SessaoVerificando();
  }

  /// Abertura do app: com tokens salvos, confirma com `GET /api/entregador/me`.
  Future<void> _restaurar() async {
    final armazenamento = ref.read(armazenamentoTokensProvider);
    try {
      final tokens = await armazenamento.ler();
      if (!ref.mounted) return;
      if (tokens == null) {
        state = const SemSessao();
        return;
      }
      final motoboy = await ref.read(authRepositoryProvider).buscarEntregadorDaSessao();
      if (!ref.mounted) return;
      state = SessaoAtiva(Sessao(motoboyId: motoboy.id, nome: motoboy.nome));
    } catch (_) {
      // Qualquer falha (inclusive sem rede) leva ao login, sem sessão aberta.
      await armazenamento.apagar();
      if (!ref.mounted) return;
      if (state is! SemSessao) state = const SemSessao();
    }
  }

  /// Lança [ErroApi] em falha. Perfil diferente de ENTREGADOR não abre sessão,
  /// mesmo que o backend aceite (Constituição 4.3).
  Future<void> entrar(String email, String senha) async {
    final resposta = await ref.read(authRepositoryProvider).entrar(email, senha);
    final usuario = resposta.usuario;
    final motoboyId = usuario.motoboyId;
    if (usuario.perfil != PerfilUsuario.ENTREGADOR || motoboyId == null) {
      throw const ErroApi(
        status: 403,
        codigo: CodigosErro.acessoNegado,
        mensagemServidor: MensagensErro.exclusivoEntregadores,
      );
    }
    await ref.read(armazenamentoTokensProvider).salvar(resposta.tokens);
    if (!ref.mounted) return;
    state = SessaoAtiva(Sessao(motoboyId: motoboyId, nome: usuario.nome));
  }

  /// Logout: apaga os tokens e todo o estado em memória (Constituição 6.1).
  Future<void> sair({String? aviso}) async {
    await ref.read(armazenamentoTokensProvider).apagar();
    if (!ref.mounted) return;
    ref.read(ultimaPosicaoProvider.notifier).limpar();
    state = SemSessao(aviso: aviso);
  }

  Future<void> _expirar() async {
    if (state is SemSessao) return;
    await sair(aviso: MensagensErro.sessaoExpirada);
  }
}

final sessaoProvider =
    NotifierProvider<SessaoNotifier, EstadoSessao>(SessaoNotifier.new);

/// Sessão aberta, ou `null`. Os estados das features observam este provider,
/// e por isso são descartados no logout.
final sessaoAtualProvider = Provider<Sessao?>((ref) {
  final estado = ref.watch(sessaoProvider);
  return estado is SessaoAtiva ? estado.sessao : null;
});
