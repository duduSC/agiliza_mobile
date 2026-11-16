/// Execução periódica com timer injetável, para que os testes controlem o
/// tempo (telemetria a cada 20 s e polling do lote a cada 10 s).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef CriarTimerPeriodico = Timer Function(
  Duration intervalo,
  void Function(Timer timer) callback,
);

final criarTimerPeriodicoProvider = Provider<CriarTimerPeriodico>(
  (ref) => Timer.periodic,
);

/// Roda [acao] a cada [intervalo] até [parar]. Uma execução nunca se sobrepõe
/// à anterior: se a anterior ainda não terminou, o tique é ignorado.
class TarefaPeriodica {
  TarefaPeriodica({
    required this.intervalo,
    required this.acao,
    required this.criarTimer,
  });

  final Duration intervalo;
  final Future<void> Function() acao;
  final CriarTimerPeriodico criarTimer;

  Timer? _timer;
  bool _executando = false;

  bool get ativa => _timer != null;

  void iniciar({bool executarAgora = false}) {
    if (_timer != null) return;
    _timer = criarTimer(intervalo, (_) => _tique());
    if (executarAgora) _tique();
  }

  void parar() {
    _timer?.cancel();
    _timer = null;
  }

  void _tique() {
    if (_executando || _timer == null) return;
    _executando = true;
    unawaited(_executar());
  }

  Future<void> _executar() async {
    try {
      await acao();
    } catch (_) {
      // A ação trata os próprios erros; aqui só impede exceção solta.
    } finally {
      _executando = false;
    }
  }
}
