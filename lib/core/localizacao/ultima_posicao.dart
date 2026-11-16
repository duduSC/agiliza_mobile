/// Última posição obtida pelo app, guardada só em memória. Usada como
/// coordenada de reserva nas mudanças de status (Constituição 5.4).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../dominio/modelos.dart';

class UltimaPosicao extends Notifier<Coordenada?> {
  @override
  Coordenada? build() => null;

  void registrar(Coordenada? c) {
    if (c != null) state = c;
  }

  void limpar() => state = null;
}

final ultimaPosicaoProvider =
    NotifierProvider<UltimaPosicao, Coordenada?>(UltimaPosicao.new);
