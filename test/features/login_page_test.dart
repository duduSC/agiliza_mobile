import 'package:agiliza_mobile/core/fake/fake_backend.dart';
import 'package:agiliza_mobile/core/sessao/sessao.dart';
import 'package:agiliza_mobile/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio/apoio.dart';

Future<ProviderContainer> abrirLogin(WidgetTester tester, Ambiente amb) async {
  final c = amb.criarContainer();
  c.read(sessaoProvider);
  await tester.runAsync(() => esperarAssincrono());
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: const MaterialApp(home: LoginPage()),
  ));
  return c;
}

Future<void> entrar(WidgetTester tester, String email, String senha) async {
  await tester.enterText(find.byKey(const Key('login-email')), email);
  await tester.enterText(find.byKey(const Key('login-senha')), senha);
  await tester.tap(find.byKey(const Key('login-entrar')));
  await tester.runAsync(() => esperarAssincrono());
  await tester.pump();
}

void main() {
  testWidgets('OPERADOR vê "exclusivo para entregadores" e não abre sessão', (tester) async {
    final amb = Ambiente();
    final c = await abrirLogin(tester, amb);
    addTearDown(c.dispose);

    await entrar(tester, FakeBackend.emailOperador, FakeBackend.senhaPadrao);

    expect(find.text('Este aplicativo é exclusivo para entregadores'), findsOneWidget);
    expect(c.read(sessaoProvider), isA<SemSessao>());
    expect(amb.tokens.tokens, isNull);
  });

  testWidgets('credenciais inválidas mostram a mensagem genérica', (tester) async {
    final amb = Ambiente();
    final c = await abrirLogin(tester, amb);
    addTearDown(c.dispose);

    await entrar(tester, FakeBackend.emailEntregador, 'errada');

    expect(find.text('E-mail ou senha inválidos'), findsOneWidget);
  });

  testWidgets('entregador válido abre a sessão', (tester) async {
    final amb = Ambiente();
    final c = await abrirLogin(tester, amb);
    addTearDown(c.dispose);

    await entrar(tester, FakeBackend.emailEntregador, FakeBackend.senhaPadrao);

    expect(c.read(sessaoProvider), isA<SessaoAtiva>());
    expect(amb.tokens.tokens, isNotNull);
  });
}
