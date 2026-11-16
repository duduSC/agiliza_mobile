import 'package:agiliza_mobile/app/app.dart';
import 'package:agiliza_mobile/core/api/erros.dart';
import 'package:agiliza_mobile/core/deep_links/deep_links.dart';
import 'package:agiliza_mobile/core/dominio/enums.dart';
import 'package:agiliza_mobile/core/fake/fake_backend.dart';
import 'package:agiliza_mobile/core/ui/mensageiro.dart';
import 'package:agiliza_mobile/features/auth/auth.dart';
import 'package:agiliza_mobile/features/lote/lote.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio/apoio.dart';

/// Entregador logado, com um lote DESPACHADO de 2 entregas já carregado.
Future<ProviderContainer> comLote(Ambiente amb, {bool iniciar = false}) async {
  final c = amb.criarContainer();
  c.read(sessaoProvider);
  await esperarAssincrono();
  await c
      .read(sessaoProvider.notifier)
      .entrar(FakeBackend.emailEntregador, FakeBackend.senhaPadrao);
  amb.backend.despacharLoteDeExemplo();
  await c.read(loteAtivoProvider.notifier).recarregar();
  if (iniciar) await c.read(loteAtivoProvider.notifier).iniciarPercurso();
  return c;
}

Widget app(ProviderContainer c, Widget tela) =>
    UncontrolledProviderScope(container: c, child: MaterialApp(home: tela));

String entrega1(ProviderContainer c) => c.read(loteAtivoProvider).lote!.entregas[0].id;
String entrega2(ProviderContainer c) => c.read(loteAtivoProvider).lote!.entregas[1].id;

void main() {
  group('máquina de estados (notifier)', () {
    test('iniciar, ENTREGUE e FALHA ("Cliente ausente") concluem o lote', () async {
      final amb = Ambiente();
      final c = await comLote(amb);
      addTearDown(c.dispose);
      final n = c.read(loteAtivoProvider.notifier);
      expect(c.read(loteAtivoProvider).lote!.status, StatusLote.DESPACHADO);

      expect((await n.iniciarPercurso()).sucesso, isTrue);
      final lote = c.read(loteAtivoProvider).lote!;
      expect(lote.status, StatusLote.EM_ROTA);
      expect(lote.entregas.map((e) => e.status), everyElement(StatusEntrega.EM_ROTA));

      final r1 = await n.marcarEntregue(entrega1(c));
      expect(r1.sucesso, isTrue);
      expect(r1.loteConcluido, isFalse);

      final r2 = await n.marcarFalha(entrega2(c), 'Cliente ausente');
      expect(r2.sucesso, isTrue);
      expect(r2.loteConcluido, isTrue);
      expect(c.read(loteAtivoProvider).lote, isNull);
      expect(amb.backend.motoboy.statusDisponibilidade, StatusDisponibilidadeMotoboy.ONLINE);
    });

    test('envio vai com coordenada e ocorridoEm sem fuso', () async {
      final amb = Ambiente();
      final c = await comLote(amb, iniciar: true);
      addTearDown(c.dispose);

      await c.read(loteAtivoProvider.notifier).marcarEntregue(entrega1(c));

      final corpo = amb.backend.ultimoCorpoStatus!;
      expect(corpo['status'], 'ENTREGUE');
      expect(corpo['coordenada'], {'latitude': -23.56, 'longitude': -46.64});
      expect(corpo['ocorridoEm'] as String,
          matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$')));
    });

    test('FALHA sem motivo não envia nada', () async {
      final amb = Ambiente();
      final c = await comLote(amb, iniciar: true);
      addTearDown(c.dispose);

      await c.read(loteAtivoProvider.notifier).marcarFalha(entrega1(c), '   ');

      expect(amb.backend.ultimoCorpoStatus, isNull);
      expect(c.read(loteAtivoProvider).lote!.entregas[0].status, StatusEntrega.EM_ROTA);
    });

    test('ENTREGUE numa entrega ainda DESPACHADA não é enviado', () async {
      final amb = Ambiente();
      final c = await comLote(amb);
      addTearDown(c.dispose);

      await c.read(loteAtivoProvider.notifier).marcarEntregue(entrega1(c));

      expect(amb.backend.ultimoCorpoStatus, isNull);
    });

    test('TRANSICAO_ESTADO_INVALIDA recarrega o lote', () async {
      final amb = Ambiente();
      final c = await comLote(amb, iniciar: true);
      addTearDown(c.dispose);
      // O operador cancelou a entrega no servidor; o app ainda a vê EM_ROTA.
      final entregas = (amb.backend.loteAtivo!['entregas']! as List<Object?>)
          .cast<Map<String, Object?>>();
      entregas[0]['status'] = 'CANCELADA';

      final r = await c.read(loteAtivoProvider.notifier).marcarEntregue(entrega1(c));

      expect(r.erro!.codigo, CodigosErro.transicaoEstadoInvalida);
      expect(r.erro!.mensagem(), 'Esta ação não é mais possível. Atualizando...');
      expect(c.read(loteAtivoProvider).lote!.entregas[0].status, StatusEntrega.CANCELADA);
    });
  });

  group('telas', () {
    testWidgets('Iniciar percurso só aparece em DESPACHADO e pede confirmação',
        (tester) async {
      final amb = Ambiente();
      late ProviderContainer c;
      await tester.runAsync(() async => c = await comLote(amb));
      addTearDown(c.dispose);
      await tester.pumpWidget(app(c, const LotePage()));

      expect(find.byKey(const Key('botao-iniciar-percurso')), findsOneWidget);
      expect(find.text('Levar troco para R\$ 100,00'), findsOneWidget);
      expect(find.text('Pago online'), findsOneWidget);

      await tester.tap(find.byKey(const Key('botao-iniciar-percurso')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('confirmar-iniciar')), findsOneWidget);
      expect(amb.backend.loteAtivo!['status'], 'DESPACHADO', reason: 'só no 2º toque');

      await tester.tap(find.byKey(const Key('confirmar-iniciar')));
      await tester.runAsync(() => esperarAssincrono());
      await tester.pumpAndSettle();
      expect(amb.backend.loteAtivo!['status'], 'EM_ROTA');
      expect(find.byKey(const Key('botao-iniciar-percurso')), findsNothing);
    });

    testWidgets('Entregue/Falha só aparecem em EM_ROTA', (tester) async {
      final amb = Ambiente();
      late ProviderContainer c;
      await tester.runAsync(() async => c = await comLote(amb));
      addTearDown(c.dispose);
      await tester.pumpWidget(app(c, EntregaPage(entregaId: entrega1(c))));
      expect(find.byKey(const Key('botao-entregue')), findsNothing);
      expect(find.byKey(const Key('botao-falha')), findsNothing);

      await tester.runAsync(() => c.read(loteAtivoProvider.notifier).iniciarPercurso());
      await tester.pump();
      await tester.scrollUntilVisible(find.byKey(const Key('botao-falha')), 200);
      expect(find.byKey(const Key('botao-entregue')), findsOneWidget);
      expect(find.byKey(const Key('botao-falha')), findsOneWidget);
    });

    testWidgets('repasse null aparece como "—" e WhatsApp sem telefone fica desabilitado',
        (tester) async {
      final amb = Ambiente();
      late ProviderContainer c;
      await tester.runAsync(() async => c = await comLote(amb));
      addTearDown(c.dispose);
      // A segunda entrega do exemplo não tem telefone nem coordenada.
      await tester.pumpWidget(app(c, EntregaPage(entregaId: entrega2(c))));

      expect(find.text('Seu repasse: —'), findsOneWidget);
      final whatsapp = tester.widget<ButtonStyleButton>(find.byKey(const Key('botao-whatsapp')));
      expect(whatsapp.onPressed, isNull);
      expect(find.text('Cliente sem telefone cadastrado.'), findsOneWidget);
    });

    testWidgets('WhatsApp usa o nome da loja; repasse do backend; falha ao abrir avisa',
        (tester) async {
      final amb = Ambiente();
      final abertas = <Uri>[];
      var abre = true;
      final c = ProviderContainer(overrides: [
        ...amb.overrides,
        abrirLinkProvider.overrideWithValue((url) async {
          abertas.add(url);
          return abre;
        }),
      ]);
      await tester.runAsync(() async {
        c.read(sessaoProvider);
        await esperarAssincrono();
        await c
            .read(sessaoProvider.notifier)
            .entrar(FakeBackend.emailEntregador, FakeBackend.senhaPadrao);
        amb.backend.despacharLoteDeExemplo();
        await c.read(loteAtivoProvider.notifier).recarregar();
      });
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          scaffoldMessengerKey: c.read(mensageiroProvider),
          home: EntregaPage(entregaId: entrega1(c)),
        ),
      ));

      expect(find.text('Seu repasse: R\$\u00A09,00'), findsOneWidget);
      expect(find.text('Distância: 2,1 km'), findsOneWidget);

      await tester.tap(find.byKey(const Key('botao-whatsapp')));
      await tester.pump();
      expect(abertas.single.host, 'wa.me');
      expect(abertas.single.queryParameters['text'],
          'Olá, Maria Souza! Sou o entregador do Pizzaria Agiliza. '
          'Estou a caminho com o seu pedido.');

      abre = false;
      await tester.tap(find.byKey(const Key('botao-navegar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('navegar-waze')));
      await tester.pumpAndSettle();
      expect(abertas.last.host, 'waze.com');
      expect(find.text('Não foi possível abrir o aplicativo'), findsOneWidget);
    });

    testWidgets('Falha: sem motivo o botão de confirmar fica desabilitado', (tester) async {
      final amb = Ambiente();
      late ProviderContainer c;
      await tester.runAsync(() async => c = await comLote(amb, iniciar: true));
      addTearDown(c.dispose);
      await tester.pumpWidget(app(c, EntregaPage(entregaId: entrega1(c))));
      await tester.scrollUntilVisible(find.byKey(const Key('botao-falha')), 200);
      await tester.tap(find.byKey(const Key('botao-falha')));
      await tester.pumpAndSettle();

      final confirmar =
          tester.widget<ButtonStyleButton>(find.byKey(const Key('confirmar-falha')));
      expect(confirmar.onPressed, isNull);
      expect(amb.backend.ultimoCorpoStatus, isNull);
    });

    testWidgets('lote concluído volta ao início com "Lote concluído"', (tester) async {
      final amb = Ambiente();
      late ProviderContainer c;
      await tester.runAsync(() async => c = await comLote(amb, iniciar: true));
      addTearDown(c.dispose);
      await tester.runAsync(() => c.read(loteAtivoProvider.notifier).marcarEntregue(entrega1(c)));
      final ultima = entrega2(c);

      await tester.pumpWidget(
          UncontrolledProviderScope(container: c, child: const AgilizaApp()));
      await tester.runAsync(() => esperarAssincrono());
      await tester.pumpAndSettle();
      expect(find.text('Lote em rota: 2 entregas'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cartao-lote')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('entrega-$ultima')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(const Key('botao-falha')), 200);
      await tester.tap(find.byKey(const Key('botao-falha')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('motivo-Cliente ausente')));
      await tester.runAsync(() => esperarAssincrono(10));
      await tester.pumpAndSettle();

      expect(find.text('Lote concluído'), findsOneWidget);
      expect(find.byKey(const Key('cartao-lote')), findsNothing);
      expect(find.text('Aguardando lote'), findsOneWidget);
    });
  });
}
