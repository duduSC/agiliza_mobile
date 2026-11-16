import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ui/mensageiro.dart';
import '../../lote/lote.dart';
import '../estado/disponibilidade_notifier.dart';
import '../estado/turno.dart';

/// Mantém vivos a telemetria e o polling enquanto há sessão, e reage às
/// mudanças do lote ativo (lote novo: vibração + *snackbar*; AGENT.md 8.2).
class MonitorTurno extends ConsumerWidget {
  const MonitorTurno({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(telemetriaProvider);
    ref.watch(pollingLoteProvider);
    ref.listen(loteAtivoProvider, (anterior, atual) {
      final idAnterior = anterior?.lote?.id;
      final idAtual = atual.lote?.id;
      if (!atual.carregado || idAnterior == idAtual) return;
      // Lote novo ou encerrado: o backend muda a disponibilidade
      // (ONLINE ⇄ EM_ROTA, DVP 1.4.4). Recarrega o estado confirmado.
      unawaited(ref.read(disponibilidadeProvider.notifier).carregar());
      // Na primeira consulta (abertura do app) não há "novidade" a avisar.
      final primeiraConsulta = anterior == null || !anterior.carregado;
      final lote = atual.lote;
      if (lote != null && !primeiraConsulta) {
        unawaited(HapticFeedback.vibrate());
        mostrarMensagem(ref, 'Novo lote: ${textoEntregas(lote.qtdEntregas)}');
      }
    });
    return child;
  }
}

String textoEntregas(int qtd) => qtd == 1 ? '1 entrega' : '$qtd entregas';
