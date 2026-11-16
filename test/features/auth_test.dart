import 'dart:convert';

import 'package:agiliza_mobile/app/config.dart';
import 'package:agiliza_mobile/core/api/endpoints.dart';
import 'package:agiliza_mobile/core/api/erros.dart';
import 'package:agiliza_mobile/core/fake/fake_backend.dart';
import 'package:agiliza_mobile/core/providers_core.dart';
import 'package:agiliza_mobile/core/sessao/armazenamento_tokens.dart';
import 'package:agiliza_mobile/core/sessao/sessao.dart';
import 'package:agiliza_mobile/features/auth/auth.dart';
import 'package:agiliza_mobile/features/auth/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../apoio/apoio.dart';

http.Response json(Object corpo, int status) => http.Response.bytes(
      utf8.encode(jsonEncode(corpo)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

Map<String, Object?> erro(int status, String codigo) => {
      'timestamp': '2026-11-15T12:00:00Z',
      'status': status,
      'error': 'x',
      'codigo': codigo,
      'message': 'mensagem do servidor',
      'path': '/x',
    };

Map<String, Object?> loginOk({String perfil = 'ENTREGADOR', String token = 't1'}) => {
      'token': token,
      'refreshToken': 'r-$token',
      'usuario': {
        'usuarioId': 'u1',
        'estabelecimentoId': 'e1',
        'motoboyId': perfil == 'ENTREGADOR' ? 'm1' : null,
        'nome': 'Carlos',
        'perfil': perfil,
      },
    };

const meJson = {
  'id': 'm1',
  'usuarioId': 'u1',
  'nome': 'Carlos',
  'telefone': '11999990000',
  'statusCadastro': 'ATIVO',
  'statusDisponibilidade': 'OFFLINE',
  'criadoEm': '2026-11-01T09:00:00',
};

/// Container com o cabeamento REAL (ApiClient + RenovadorSessao), trocando
/// só o http.Client por um MockClient.
ProviderContainer containerApi(http.Client cliente, ArmazenamentoTokens tokens) {
  return ProviderContainer(overrides: [
    configProvider.overrideWithValue(
        ConfigApp(apiUrl: Uri.parse('http://api.teste'), usarFake: false)),
    armazenamentoTokensProvider.overrideWithValue(tokens),
    httpClientProvider.overrideWithValue(cliente),
  ]);
}

void main() {
  group('login (UC07)', () {
    test('entregador válido: sessão aberta e tokens no armazenamento seguro', () async {
      final amb = Ambiente();
      final c = amb.criarContainer();
      addTearDown(c.dispose);
      c.read(sessaoProvider);
      await esperarAssincrono();
      expect(c.read(sessaoProvider), isA<SemSessao>());

      await c.read(sessaoProvider.notifier)
          .entrar(FakeBackend.emailEntregador, FakeBackend.senhaPadrao);

      final estado = c.read(sessaoProvider);
      expect(estado, isA<SessaoAtiva>());
      expect((estado as SessaoAtiva).sessao.motoboyId, FakeBackend.motoboyId);
      expect(amb.tokens.tokens, isNotNull);
    });

    test('envia canal APP e credenciais inválidas dão a mensagem genérica', () async {
      late Map<String, dynamic> corpo;
      final cliente = MockClient((req) async {
        corpo = jsonDecode(req.body) as Map<String, dynamic>;
        return json(erro(401, 'CREDENCIAIS_INVALIDAS'), 401);
      });
      final tokens = ArmazenamentoTokensMemoria();
      final c = containerApi(cliente, tokens);
      addTearDown(c.dispose);

      await expectLater(
        c.read(authRepositoryProvider).entrar('a@b.com', 'errada'),
        throwsA(isA<ErroApi>().having(
            (e) => e.mensagem(noLogin: true), 'mensagem', 'E-mail ou senha inválidos')),
      );
      expect(corpo['canal'], 'APP');
      expect(corpo['loginEmail'], 'a@b.com');
      expect(tokens.tokens, isNull);
    });

    test('perfil OPERADOR é recusado e nenhuma sessão é aberta', () async {
      final cliente = MockClient((req) async => json(loginOk(perfil: 'OPERADOR'), 200));
      final tokens = ArmazenamentoTokensMemoria();
      final c = containerApi(cliente, tokens);
      addTearDown(c.dispose);
      c.read(sessaoProvider);
      await esperarAssincrono();

      try {
        await c.read(sessaoProvider.notifier).entrar('op@loja.com', '123');
        fail('deveria recusar');
      } on ErroApi catch (e) {
        expect(e.mensagem(noLogin: true), 'Este aplicativo é exclusivo para entregadores');
      }
      expect(c.read(sessaoProvider), isA<SemSessao>());
      expect(tokens.tokens, isNull);
    });

    test('ACESSO_NEGADO do backend no login também vira a mensagem do app', () {
      const e = ErroApi(codigo: 'ACESSO_NEGADO', mensagemServidor: 'x');
      expect(e.mensagem(noLogin: true), 'Este aplicativo é exclusivo para entregadores');
    });

    test('abertura com tokens salvos e /me válido vai direto para a sessão', () async {
      final tokens = ArmazenamentoTokensMemoria(
          const Tokens(token: 't1', refreshToken: 'r1'));
      final cliente = MockClient((req) async => json(meJson, 200));
      final c = containerApi(cliente, tokens);
      addTearDown(c.dispose);
      c.read(sessaoProvider);
      await esperarAssincrono();
      expect(c.read(sessaoProvider), isA<SessaoAtiva>());
    });
  });

  group('refresh em 401 (Constituição 6.2)', () {
    test('renova uma única vez para requisições concorrentes e repete', () async {
      var refreshes = 0;
      final cliente = MockClient((req) async {
        if (req.url.path == Endpoints.refresh) {
          refreshes++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return json(loginOk(token: 'novo'), 200);
        }
        if (req.headers['Authorization'] == 'Bearer novo') return json(meJson, 200);
        return json(erro(401, 'NAO_AUTENTICADO'), 401);
      });
      final tokens = ArmazenamentoTokensMemoria(
          const Tokens(token: 'velho', refreshToken: 'r-velho'));
      final c = containerApi(cliente, tokens);
      addTearDown(c.dispose);
      final api = c.read(apiClientProvider);

      final r = await Future.wait([api.get(Endpoints.me), api.get(Endpoints.me)]);
      expect(r.map((e) => e.status), [200, 200]);
      expect(refreshes, 1);
      expect(tokens.tokens!.token, 'novo');
    });

    test('refresh que falha encerra a sessão', () async {
      final cliente = MockClient((req) async => json(erro(401, 'NAO_AUTENTICADO'), 401));
      final tokens = ArmazenamentoTokensMemoria(
          const Tokens(token: 't', refreshToken: 'r'));
      final c = containerApi(cliente, tokens);
      addTearDown(c.dispose);
      c.read(sessaoProvider);
      await esperarAssincrono(10);
      final estado = c.read(sessaoProvider);
      expect(estado, isA<SemSessao>());
      expect(tokens.tokens, isNull);
    });
  });

  test('logout apaga os tokens e fecha a sessão', () async {
    final amb = Ambiente();
    final c = amb.criarContainer();
    addTearDown(c.dispose);
    c.read(sessaoProvider);
    await esperarAssincrono();
    await c.read(sessaoProvider.notifier)
        .entrar(FakeBackend.emailEntregador, FakeBackend.senhaPadrao);
    expect(amb.tokens.tokens, isNotNull);

    await c.read(sessaoProvider.notifier).sair();

    expect(amb.tokens.tokens, isNull);
    expect(c.read(sessaoProvider), isA<SemSessao>());
    expect(c.read(sessaoAtualProvider), isNull);
  });
}
