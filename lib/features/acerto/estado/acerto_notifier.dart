import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/erros.dart';
import '../../../core/dominio/transicoes.dart';
import '../../auth/auth.dart';
import '../data/acerto_repository.dart';
import '../data/modelos_acerto.dart';

class EstadoAcerto {
  const EstadoAcerto({this.acerto, this.erro, this.contestando});

  final AcertoDoEntregador? acerto;
  final ErroApi? erro;

  /// Entrega com contestação em envio (o botão fica bloqueado).
  final String? contestando;

  bool get carregando => acerto == null && erro == null;
}

/// Acerto do turno (UC08). Descartado no logout.
class AcertoNotifier extends Notifier<EstadoAcerto> {
  @override
  EstadoAcerto build() {
    final sessao = ref.watch(sessaoAtualProvider);
    if (sessao != null) unawaited(Future.microtask(recarregar));
    return const EstadoAcerto();
  }

  Future<void> recarregar() async {
    try {
      final acerto = await ref.read(acertoRepositoryProvider).buscarAcerto();
      if (!ref.mounted) return;
      state = EstadoAcerto(acerto: acerto);
    } on ErroApi catch (e) {
      if (!ref.mounted) return;
      // Mantém o último extrato conhecido, se houver.
      state = EstadoAcerto(acerto: state.acerto, erro: e);
    }
  }

  /// Devolve o erro, ou `null` em sucesso. Em qualquer caso recarrega o
  /// extrato: os totais e a situação da linha vêm sempre do backend.
  Future<ErroApi?> contestar(String entregaId) async {
    final acerto = state.acerto;
    if (acerto == null || state.contestando != null) return null;
    final linha = acerto.extrato.linhas.where((l) => l.entregaId == entregaId).firstOrNull;
    if (linha == null ||
        !podeContestar(
          situacao: linha.situacao,
          statusCaixa: acerto.statusCaixa,
          contestacaoPermitida: acerto.contestacaoPermitida,
        )) {
      return null;
    }
    state = EstadoAcerto(acerto: acerto, contestando: entregaId);
    ErroApi? erro;
    try {
      await ref.read(acertoRepositoryProvider).contestar(entregaId);
    } on ErroApi catch (e) {
      erro = e;
    }
    if (!ref.mounted) return erro;
    await recarregar();
    return erro;
  }
}

final acertoProvider = NotifierProvider<AcertoNotifier, EstadoAcerto>(AcertoNotifier.new);
