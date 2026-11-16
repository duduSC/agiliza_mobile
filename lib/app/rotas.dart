import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/sessao/sessao.dart';
import '../core/ui/estados.dart';
import '../features/auth/auth.dart';
import '../features/inicio/inicio.dart';
import '../features/lote/lote.dart';

abstract final class Rotas {
  static const carregando = '/carregando';
  static const login = '/login';
  static const inicio = '/inicio';
  static const lote = '/lote';
}

/// Guarda de sessão (AGENT.md 7): sem sessão, tudo leva a `/login`.
String? redirecionar(EstadoSessao sessao, String local) {
  return switch (sessao) {
    SessaoVerificando() => local == Rotas.carregando ? null : Rotas.carregando,
    SemSessao() => local == Rotas.login ? null : Rotas.login,
    SessaoAtiva() =>
      (local == Rotas.login || local == Rotas.carregando) ? Rotas.inicio : null,
  };
}

final routerProvider = Provider<GoRouter>((ref) {
  final sessao = ValueNotifier<EstadoSessao>(ref.read(sessaoProvider));
  ref.listen(sessaoProvider, (_, novo) => sessao.value = novo);

  final router = GoRouter(
    initialLocation: Rotas.carregando,
    refreshListenable: sessao,
    redirect: (context, state) => redirecionar(sessao.value, state.matchedLocation),
    routes: [
      GoRoute(
        path: Rotas.carregando,
        builder: (context, state) =>
            const Scaffold(body: EstadoCarregando(mensagem: 'Abrindo...')),
      ),
      GoRoute(path: Rotas.login, builder: (context, state) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) => ShellEntregador(child: child),
        routes: [
          GoRoute(path: Rotas.inicio, builder: (context, state) => const InicioPage()),
        ],
      ),
      GoRoute(
        path: Rotas.lote,
        builder: (context, state) => const LotePage(),
        routes: [
          GoRoute(
            path: 'entrega/:id',
            builder: (context, state) =>
                EntregaPage(entregaId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    sessao.dispose();
  });
  return router;
});

/// Moldura das telas principais: título e menu com o logout.
class ShellEntregador extends ConsumerWidget {
  const ShellEntregador({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agiliza Entregador'),
        actions: [
          PopupMenuButton<String>(
            key: const Key('menu-principal'),
            tooltip: 'Menu',
            onSelected: (opcao) {
              if (opcao == 'sair') unawaited(ref.read(sessaoProvider.notifier).sair());
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'sair',
                child: ListTile(leading: Icon(Icons.logout), title: Text('Sair')),
              ),
            ],
          ),
        ],
      ),
      body: child,
    );
  }
}
