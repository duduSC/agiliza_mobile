/// O app está em primeiro plano? Telemetria e polling só rodam assim
/// (Constituição 5.6, D008). Atualizado pelo `WidgetsBindingObserver` do App.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PrimeiroPlano extends Notifier<bool> {
  @override
  bool build() => true;

  void aoMudarCicloDeVida(AppLifecycleState estado) {
    switch (estado) {
      case AppLifecycleState.resumed:
        state = true;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        state = false;
      case AppLifecycleState.inactive:
        // Transitório (ex.: puxar a barra de notificações): mantém o estado.
        break;
    }
  }
}

final primeiroPlanoProvider =
    NotifierProvider<PrimeiroPlano, bool>(PrimeiroPlano.new);
