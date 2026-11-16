/// Telemetria (20 s) e polling do lote ativo (10 s), só com sessão aberta,
/// entregador ONLINE ou EM_ROTA e app em primeiro plano (Constituição 5.6,
/// RNF07, D008). Ao ficar OFFLINE, ir para segundo plano ou sair, os
/// providers são reconstruídos e os timers, cancelados.
///
/// Desvios conscientes (D008): sem GPS em segundo plano, sem fila offline e
/// sem envio em lotes de 5 posições (RNF01): uma posição por chamada.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localizacao/primeiro_plano.dart';
import '../../../core/localizacao/tarefa_periodica.dart';
import '../../../core/localizacao/ultima_posicao.dart';
import '../../../core/providers_core.dart';
import '../../auth/auth.dart';
import '../../lote/lote.dart';
import '../data/entregador_repository.dart';
import 'disponibilidade_notifier.dart';

const Duration intervaloTelemetria = Duration(seconds: 20);
const Duration intervaloPollingLote = Duration(seconds: 10);

final turnoAtivoProvider = Provider<bool>((ref) {
  final sessao = ref.watch(sessaoAtualProvider);
  final status = ref.watch(disponibilidadeProvider.select((e) => e.status));
  final primeiroPlano = ref.watch(primeiroPlanoProvider);
  return sessao != null && status != null && status.emTurno && primeiroPlano;
});

/// Contador interno, só para depuração: sem nenhum dado pessoal
/// (nem coordenada, nem identificador).
class ContadorTelemetria {
  int enviadas = 0;
  int falhas = 0;
}

final contadorTelemetriaProvider = Provider<ContadorTelemetria>(
  (ref) => ContadorTelemetria(),
);

/// Envia a posição atual a cada 20 s enquanto o turno está ativo. Falha de
/// envio é ignorada (sem fila, D008) e só conta no [ContadorTelemetria].
final telemetriaProvider = Provider<bool>((ref) {
  if (!ref.watch(turnoAtivoProvider)) return false;
  final localizacao = ref.read(servicoLocalizacaoProvider);
  final repositorio = ref.read(entregadorRepositoryProvider);
  final ultimaPosicao = ref.read(ultimaPosicaoProvider.notifier);
  final contador = ref.read(contadorTelemetriaProvider);
  var ativa = true;

  final tarefa = TarefaPeriodica(
    intervalo: intervaloTelemetria,
    criarTimer: ref.read(criarTimerPeriodicoProvider),
    acao: () async {
      final posicao = await localizacao.posicaoAtual();
      if (!ativa) return;
      if (posicao == null) {
        contador.falhas++;
        return;
      }
      ultimaPosicao.registrar(posicao);
      try {
        await repositorio.enviarPosicao(posicao);
        contador.enviadas++;
      } catch (_) {
        contador.falhas++;
      }
    },
  );
  tarefa.iniciar();
  ref.onDispose(() {
    ativa = false;
    tarefa.parar();
  });
  return true;
});

/// Consulta o lote ativo agora e depois a cada 10 s enquanto o turno está ativo.
final pollingLoteProvider = Provider<bool>((ref) {
  if (!ref.watch(turnoAtivoProvider)) return false;
  final lote = ref.read(loteAtivoProvider.notifier);
  final tarefa = TarefaPeriodica(
    intervalo: intervaloPollingLote,
    criarTimer: ref.read(criarTimerPeriodicoProvider),
    acao: lote.recarregar,
  );
  tarefa.iniciar(executarAgora: true);
  ref.onDispose(tarefa.parar);
  return true;
});
