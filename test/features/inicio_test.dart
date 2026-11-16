import 'package:agiliza_mobile/core/dominio/enums.dart';
import 'package:agiliza_mobile/core/fake/fake_backend.dart';
import 'package:agiliza_mobile/core/localizacao/primeiro_plano.dart';
import 'package:agiliza_mobile/core/localizacao/servico_localizacao.dart';
import 'package:agiliza_mobile/features/auth/auth.dart';
import 'package:agiliza_mobile/features/inicio/estado/turno.dart';
import 'package:agiliza_mobile/features/inicio/inicio.dart';
import 'package:agiliza_mobile/features/lote/lote.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio/apoio.dart';

Future<ProviderContainer> logado(Ambiente amb) async {
  final c = amb.criarContainer();
  c.read(sessaoProvider);
  await esperarAssincrono();
  await c
      .read(sessaoProvider.notifier)
      .entrar(FakeBackend.emailEntregador, FakeBackend.senhaPadrao);
  c.listen(telemetriaProvider, (_, _) {});
  c.listen(pollingLoteProvider, (_, _) {});
  await esperarAssincrono();
  return c;
}

void main() {
  group('Online/Offline', () {
    test('ficar online sem permissão de localização NÃO chama a API (UC02 E1)', () async {
      final amb = Ambiente(
          localizacao: ServicoLocalizacaoFalso(permissao: SituacaoPermissao.negada));
      final c = await logado(amb);
      addTearDown(c.dispose);
      expect(c.read(disponibilidadeProvider).status, StatusDisponibilidadeMotoboy.OFFLINE);

      await c.read(disponibilidadeProvider.notifier).ficarOnline();

      expect(amb.localizacao.pedidosDePermissao, 1);
      expect(amb.backend.chamadasDisponibilidade, 0);
      expect(c.read(disponibilidadeProvider).permissaoNegada, SituacaoPermissao.negada);
      expect(c.read(disponibilidadeProvider).status, StatusDisponibilidadeMotoboy.OFFLINE);
    });

    test('com permissão fica online com o estado confirmado pelo servidor', () async {
      final amb = Ambiente();
      final c = await logado(amb);
      addTearDown(c.dispose);

      await c.read(disponibilidadeProvider.notifier).ficarOnline();

      expect(amb.backend.chamadasDisponibilidade, 1);
      expect(c.read(disponibilidadeProvider).status, StatusDisponibilidadeMotoboy.ONLINE);
    });

    test('em EM_ROTA, ficar offline não chama a API', () async {
      final amb = Ambiente();
      amb.backend.motoboy = amb.backend.motoboy
          .copiarCom(statusDisponibilidade: StatusDisponibilidadeMotoboy.EM_ROTA);
      final c = await logado(amb);
      addTearDown(c.dispose);

      await c.read(disponibilidadeProvider.notifier).ficarOffline();

      expect(amb.backend.chamadasDisponibilidade, 0);
      expect(c.read(disponibilidadeProvider).status, StatusDisponibilidadeMotoboy.EM_ROTA);
    });
  });

  group('telemetria (20 s) e polling (10 s)', () {
    test('envia a posição a cada 20 s e para ao ficar offline', () async {
      // Sem lote despachado: ONLINE pode voltar a OFFLINE.
      final amb = Ambiente(backend: FakeBackendContador(consultasAteDespacho: 99));
      final c = await logado(amb);
      addTearDown(c.dispose);
      expect(amb.timers.ativos(intervaloTelemetria), isEmpty, reason: 'offline');

      await c.read(disponibilidadeProvider.notifier).ficarOnline();
      await esperarAssincrono();
      final timer = amb.timers.ativos(intervaloTelemetria).single;
      expect(amb.backend.posicoesRecebidas, 0);

      timer.disparar();
      await esperarAssincrono();
      expect(amb.backend.posicoesRecebidas, 1);

      await c.read(disponibilidadeProvider.notifier).ficarOffline();
      await esperarAssincrono();
      expect(timer.cancelado, isTrue);
      expect(amb.timers.ativos(intervaloTelemetria), isEmpty);
      timer.disparar();
      await esperarAssincrono();
      expect(amb.backend.posicoesRecebidas, 1, reason: 'nada é enviado offline');
    });

    test('para em segundo plano e volta ao retornar', () async {
      final amb = Ambiente();
      final c = await logado(amb);
      addTearDown(c.dispose);
      await c.read(disponibilidadeProvider.notifier).ficarOnline();
      await esperarAssincrono();
      expect(amb.timers.ativos(intervaloTelemetria), hasLength(1));
      expect(amb.timers.ativos(intervaloPollingLote), hasLength(1));

      c.read(primeiroPlanoProvider.notifier).aoMudarCicloDeVida(AppLifecycleState.paused);
      await esperarAssincrono();
      expect(amb.timers.ativos(intervaloTelemetria), isEmpty);
      expect(amb.timers.ativos(intervaloPollingLote), isEmpty);

      c.read(primeiroPlanoProvider.notifier).aoMudarCicloDeVida(AppLifecycleState.resumed);
      await esperarAssincrono();
      expect(amb.timers.ativos(intervaloTelemetria), hasLength(1));
    });

    test('logout para a telemetria', () async {
      final amb = Ambiente();
      final c = await logado(amb);
      addTearDown(c.dispose);
      await c.read(disponibilidadeProvider.notifier).ficarOnline();
      await esperarAssincrono();
      expect(amb.timers.ativos(intervaloTelemetria), hasLength(1));

      await c.read(sessaoProvider.notifier).sair();
      await esperarAssincrono();
      expect(amb.timers.ativos(intervaloTelemetria), isEmpty);
    });

    test('polling encontra o lote despachado', () async {
      final amb = Ambiente();
      final c = await logado(amb);
      addTearDown(c.dispose);
      await c.read(disponibilidadeProvider.notifier).ficarOnline();
      await esperarAssincrono();
      amb.timers.ativos(intervaloPollingLote).single.disparar();
      await esperarAssincrono();
      final lote = c.read(loteAtivoProvider).lote;
      expect(lote, isNotNull);
      expect(lote!.status, StatusLote.DESPACHADO);
    });
  });

  testWidgets('EM_ROTA: botão Ficar offline desabilitado e com explicação', (tester) async {
    final amb = Ambiente();
    amb.backend.motoboy = amb.backend.motoboy
        .copiarCom(statusDisponibilidade: StatusDisponibilidadeMotoboy.EM_ROTA);
    late ProviderContainer c;
    await tester.runAsync(() async => c = await logado(amb));
    addTearDown(c.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: Scaffold(body: InicioPage())),
    ));
    await tester.pump();

    final botao = tester.widget<ButtonStyleButton>(
        find.byKey(const Key('botao-ficar-offline')));
    expect(botao.onPressed, isNull);
    expect(find.byKey(const Key('aviso-offline-em-rota')), findsOneWidget);
    expect(find.text('Em rota'), findsOneWidget);
  });

  testWidgets('sem permissão mostra a explicação e o atalho para as configurações',
      (tester) async {
    final amb = Ambiente(
        localizacao:
            ServicoLocalizacaoFalso(permissao: SituacaoPermissao.negadaPermanentemente));
    late ProviderContainer c;
    await tester.runAsync(() async => c = await logado(amb));
    addTearDown(c.dispose);

    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: Scaffold(body: InicioPage())),
    ));
    await tester.pump();
    await tester.tap(find.byKey(const Key('botao-ficar-online')));
    await tester.runAsync(() => esperarAssincrono());
    await tester.pump();

    expect(find.byKey(const Key('aviso-permissao')), findsOneWidget);
    await tester.tap(find.text('Abrir configurações do app'));
    expect(amb.localizacao.aberturasDeConfiguracao, 1);
    expect(amb.backend.chamadasDisponibilidade, 0);
  });
}
