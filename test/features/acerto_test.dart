import 'package:agiliza_mobile/core/api/erros.dart';
import 'package:agiliza_mobile/core/fake/fake_backend.dart';
import 'package:agiliza_mobile/core/providers_core.dart';
import 'package:agiliza_mobile/features/acerto/acerto.dart';
import 'package:agiliza_mobile/features/acerto/data/acerto_repository.dart';
import 'package:agiliza_mobile/features/acerto/data/modelos_acerto.dart';
import 'package:agiliza_mobile/features/auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../apoio/apoio.dart';

String semNbsp(String s) => s.replaceAll(' ', ' ');

Map<String, Object?> linha(String id, String situacao, num? valor) => {
      'entregaId': id,
      'nomeCliente': 'Cliente $id',
      'finalizadaEm': '2026-11-17T19:00:00',
      'status': 'ENTREGUE',
      'distanciaKm': 2.1,
      'faixaDeKm': 0,
      'faixaAteKm': 3,
      'foraDeArea': false,
      'valorRepasse': valor,
      'situacao': situacao,
      'reciboId': null,
    };

/// Repositório com um JSON fixo, em que os totais de propósito NÃO batem com a
/// soma das linhas: se a tela somasse no cliente, o teste falharia.
class AcertoFixo implements AcertoRepository {
  AcertoFixo(this.json);

  final Map<String, Object?> json;
  int contestacoes = 0;

  @override
  Future<AcertoDoEntregador> buscarAcerto() async => AcertoDoEntregador.fromJson(json);

  @override
  Future<void> contestar(String entregaId) async => contestacoes++;
}

Map<String, Object?> acertoJson({
  required String? statusCaixa,
  required bool permitido,
  bool indefinido = false,
}) =>
    {
      'extrato': {
        'motoboyId': 'm1',
        'nomeEntregador': 'Carlos',
        'periodoInicio': '2026-11-17T00:00:00',
        'periodoFim': '2026-11-17T23:59:59.999999999',
        'linhas': [
          linha('a', 'A_ACERTAR', 9),
          linha('b', 'EM_REVISAO', 12),
          linha('c', 'CONSOLIDADA', 10),
          linha('d', 'A_ACERTAR', null),
        ],
        'totalDevido': 123.45,
        'totalConsolidado': 67.89,
        'totalEmRevisao': 4.56,
        'possuiValorIndefinido': indefinido,
      },
      'dataReferenciaCaixa': '2026-11-17',
      'statusCaixa': statusCaixa,
      'contestacaoPermitida': permitido,
    };

Future<ProviderContainer> logado(WidgetTester tester, Ambiente amb,
    {AcertoRepository? repo}) async {
  final c = ProviderContainer(overrides: [
    ...amb.overrides,
    if (repo != null) acertoRepositoryProvider.overrideWithValue(repo),
  ]);
  await tester.runAsync(() async {
    c.read(sessaoProvider);
    await esperarAssincrono();
    await c
        .read(sessaoProvider.notifier)
        .entrar(FakeBackend.emailEntregador, FakeBackend.senhaPadrao);
    c.read(acertoProvider);
    await esperarAssincrono();
  });
  return c;
}

Future<void> abrir(WidgetTester tester, ProviderContainer c) async {
  // Tela alta o bastante para todas as linhas do extrato ficarem visíveis.
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: const MaterialApp(home: Scaffold(body: AcertoPage())),
  ));
  await tester.pump();
}

void main() {
  testWidgets('totais exibidos são os do backend, sem soma no cliente; null vira "—"',
      (tester) async {
    final amb = Ambiente();
    final c = await logado(tester, amb,
        repo: AcertoFixo(acertoJson(statusCaixa: 'ABERTO', permitido: true, indefinido: true)));
    addTearDown(c.dispose);
    await abrir(tester, c);

    String texto(String chave) =>
        semNbsp(tester.widget<Text>(find.byKey(Key(chave))).data!);
    expect(texto('total-devido'), r'R$ 123,45');
    expect(texto('total-consolidado'), r'R$ 67,89');
    expect(texto('total-em-revisao'), r'R$ 4,56');
    expect(find.text('—'), findsOneWidget, reason: 'linha d sem valor');
    expect(find.text('Há entregas com valor ainda não definido'), findsOneWidget);
    expect(find.text('Valor parcial do turno'), findsOneWidget);
  });

  testWidgets('caixa ABERTO: Contestar só nas linhas A_ACERTAR; EM_REVISAO mostra "Em análise"',
      (tester) async {
    final amb = Ambiente();
    final c = await logado(tester, amb,
        repo: AcertoFixo(acertoJson(statusCaixa: 'ABERTO', permitido: true)));
    addTearDown(c.dispose);
    await abrir(tester, c);

    expect(find.byKey(const Key('contestar-a')), findsOneWidget);
    expect(find.byKey(const Key('contestar-d')), findsOneWidget);
    expect(find.byKey(const Key('contestar-b')), findsNothing);
    expect(find.byKey(const Key('contestar-c')), findsNothing);
    expect(find.text('Em análise'), findsWidgets);
    expect(find.text('Esta entrega já está em análise'), findsOneWidget);
    expect(find.byKey(const Key('orientacao-operador')), findsNothing);
  });

  testWidgets('caixa FECHADO: "Valor final", nenhum Contestar e a orientação', (tester) async {
    final amb = Ambiente();
    final c = await logado(tester, amb,
        repo: AcertoFixo(acertoJson(statusCaixa: 'FECHADO', permitido: false)));
    addTearDown(c.dispose);
    await abrir(tester, c);

    expect(find.text('Valor final'), findsOneWidget);
    expect(find.textContaining('Contestar'), findsNothing);
    expect(find.text('Para corrigir algum valor, procure o operador'), findsOneWidget);
  });

  testWidgets('sem caixa aberto (null): sem Contestar, com orientação', (tester) async {
    final amb = Ambiente();
    final c = await logado(tester, amb,
        repo: AcertoFixo(acertoJson(statusCaixa: null, permitido: false)));
    addTearDown(c.dispose);
    await abrir(tester, c);

    expect(find.text('Valor parcial do turno'), findsOneWidget);
    expect(find.textContaining('Contestar'), findsNothing);
    expect(find.byKey(const Key('orientacao-operador')), findsOneWidget);
  });

  testWidgets('contestar (2 toques) com o fake: a linha passa a "Em análise"', (tester) async {
    final amb = Ambiente();
    final c = await logado(tester, amb);
    addTearDown(c.dispose);
    await abrir(tester, c);
    const id = 'fake-antiga-2';
    expect(find.byKey(const Key('contestar-$id')), findsOneWidget);
    final devidoAntes = c.read(acertoProvider).acerto!.extrato.totalDevido;

    await tester.tap(find.byKey(const Key('contestar-$id')));
    await tester.pumpAndSettle();
    expect(amb.backend.contestadas, isEmpty, reason: 'só no 2º toque');
    await tester.tap(find.byKey(const Key('confirmar-contestar')));
    await tester.runAsync(() => esperarAssincrono(10));
    await tester.pumpAndSettle();

    expect(amb.backend.contestadas, contains(id));
    expect(find.byKey(const Key('contestar-$id')), findsNothing);
    final linhaAtual =
        c.read(acertoProvider).acerto!.extrato.linhas.firstWhere((l) => l.entregaId == id);
    expect(linhaAtual.situacao.name, 'EM_REVISAO');
    expect(c.read(acertoProvider).acerto!.extrato.totalDevido, isNot(devidoAntes),
        reason: 'o total muda porque o BACKEND devolveu outro total');
  });

  test('CAIXA_FECHADO vindo do servidor: mensagem da 6.5 e recarga', () async {
    final amb = Ambiente();
    final c = amb.criarContainer();
    addTearDown(c.dispose);
    c.read(sessaoProvider);
    await esperarAssincrono();
    await c
        .read(sessaoProvider.notifier)
        .entrar(FakeBackend.emailEntregador, FakeBackend.senhaPadrao);
    c.read(acertoProvider);
    await esperarAssincrono();
    // O app ainda vê o caixa aberto, mas o operador acabou de fechar.
    amb.backend.statusCaixa = 'FECHADO';

    final erro = await c.read(acertoProvider.notifier).contestar('fake-antiga-2');

    expect(erro!.codigo, CodigosErro.caixaFechado);
    expect(erro.mensagem(), 'O caixa já foi fechado. Procure o operador.');
    expect(c.read(acertoProvider).acerto!.contestacaoPermitida, isFalse);
    expect(c.read(fakeBackendProvider).contestadas, isEmpty);
  });
}
