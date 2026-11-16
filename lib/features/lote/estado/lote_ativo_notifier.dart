import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/erros.dart';
import '../../auth/auth.dart';
import '../data/lote_repository.dart';
import '../data/modelos_lote.dart';

class EstadoLoteAtivo {
  const EstadoLoteAtivo({
    this.carregado = false,
    this.lote,
    this.erro,
  });

  /// Já houve pelo menos uma resposta (com ou sem lote).
  final bool carregado;
  final LoteAtivo? lote;

  /// Erro da última consulta. O último lote conhecido continua na tela.
  final ErroApi? erro;

  bool get carregando => !carregado && erro == null;
}

/// Lote ativo do entregador, atualizado pelo polling de 10 s (D008) e depois
/// de cada ação. Descartado no logout (observa a sessão).
class LoteAtivoNotifier extends Notifier<EstadoLoteAtivo> {
  @override
  EstadoLoteAtivo build() {
    ref.watch(sessaoAtualProvider);
    return const EstadoLoteAtivo();
  }

  Future<void> recarregar() async {
    try {
      final lote = await ref.read(loteRepositoryProvider).buscarLoteAtivo();
      if (!ref.mounted) return;
      state = EstadoLoteAtivo(carregado: true, lote: lote);
    } on ErroApi catch (e) {
      if (!ref.mounted) return;
      state = EstadoLoteAtivo(carregado: state.carregado, lote: state.lote, erro: e);
    }
  }
}

final loteAtivoProvider =
    NotifierProvider<LoteAtivoNotifier, EstadoLoteAtivo>(LoteAtivoNotifier.new);
