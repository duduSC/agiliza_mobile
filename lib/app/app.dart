import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/localizacao/primeiro_plano.dart';
import '../core/ui/mensageiro.dart';
import '../features/inicio/inicio.dart';
import 'config.dart';
import 'rotas.dart';
import 'tema.dart';

class AgilizaApp extends ConsumerStatefulWidget {
  const AgilizaApp({super.key});

  @override
  ConsumerState<AgilizaApp> createState() => _AgilizaAppState();
}

class _AgilizaAppState extends ConsumerState<AgilizaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Telemetria e polling param em segundo plano (Constituição 5.6).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    ref.read(primeiroPlanoProvider.notifier).aoMudarCicloDeVida(state);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(configProvider);
    if (config.apiUrl == null && !config.usarFake) {
      return MaterialApp(
        title: 'Agiliza Entregador',
        theme: criarTema(),
        home: const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Endereço do servidor não configurado. Gere o app com '
                '--dart-define=API_URL=<endereço do backend>.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }
    return MaterialApp.router(
      title: 'Agiliza Entregador',
      debugShowCheckedModeBanner: false,
      theme: criarTema(),
      scaffoldMessengerKey: ref.watch(mensageiroProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => MonitorTurno(child: child ?? const SizedBox.shrink()),
    );
  }
}
