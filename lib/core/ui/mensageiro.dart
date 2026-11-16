import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `ScaffoldMessenger` global, para *snackbars* que sobrevivem à troca de tela
/// (ex.: "Lote concluído" ao voltar para o início).
final mensageiroProvider = Provider<GlobalKey<ScaffoldMessengerState>>(
  (ref) => GlobalKey<ScaffoldMessengerState>(),
);

void mostrarMensagem(WidgetRef ref, String texto) {
  final mensageiro = ref.read(mensageiroProvider).currentState;
  mensageiro
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}
