import 'dart:convert';
import 'dart:io';

import 'package:agiliza_mobile/app/config.dart';
import 'package:agiliza_mobile/core/api/api_client.dart';
import 'package:agiliza_mobile/core/api/erros.dart';
import 'package:agiliza_mobile/core/dominio/json_estrito.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResposta(Object corpo, int status) => http.Response.bytes(
      utf8.encode(jsonEncode(corpo)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  final base = Uri.parse('http://api.teste:8080');

  group('ApiErrorResponse', () {
    test('é convertido em ErroApi com codigo, message e campos', () async {
      final cliente = ApiClient(
        baseUrl: base,
        cliente: MockClient((_) async => jsonResposta({
              'timestamp': '2026-11-15T12:00:00Z',
              'status': 422,
              'error': 'Unprocessable Entity',
              'codigo': 'MOTOBOY_INDISPONIVEL',
              'message': 'Entregador já está em rota',
              'path': '/api/entregador/disponibilidade',
              'campos': [
                {'campo': 'status', 'mensagem': 'inválido'},
              ],
            }, 422)),
      );
      try {
        await cliente.get('/x');
        fail('deveria lançar');
      } on ErroApi catch (e) {
        expect(e.status, 422);
        expect(e.codigo, CodigosErro.motoboyIndisponivel);
        expect(e.mensagem(), 'Entregador já está em rota');
        expect(e.campos.single.campo, 'status');
      }
    });

    test('mensagens próprias da tabela 6.5', () {
      ErroApi e(String c) => ErroApi(codigo: c, mensagemServidor: 'srv');
      expect(e('CREDENCIAIS_INVALIDAS').mensagem(), 'E-mail ou senha inválidos');
      expect(e('ACESSO_NEGADO').mensagem(noLogin: true),
          'Este aplicativo é exclusivo para entregadores');
      expect(e('ACESSO_NEGADO').mensagem(), 'srv');
      expect(e('ESTABELECIMENTO_INATIVO').mensagem(), 'O acesso desta loja está suspenso');
      expect(e('USUARIO_BLOQUEADO').mensagem(), 'Seu acesso está bloqueado. Procure a loja.');
      expect(e('TRANSICAO_ESTADO_INVALIDA').mensagem(),
          'Esta ação não é mais possível. Atualizando...');
      expect(e('CAIXA_FECHADO').mensagem(), 'O caixa já foi fechado. Procure o operador.');
      expect(e('REGRA_NEGOCIO_VIOLADA').mensagem(), 'srv');
      expect(e('CODIGO_NOVO_DO_BACKEND').mensagem(), 'srv');
    });

    test('corpo de erro ilegível vira erro genérico, sem exceção solta', () async {
      final cliente = ApiClient(
        baseUrl: base,
        cliente: MockClient((_) async => http.Response('<html>500</html>', 500)),
      );
      expect(
        cliente.get('/x'),
        throwsA(isA<ErroApi>().having((e) => e.status, 'status', 500)),
      );
    });
  });

  group('rede e contrato', () {
    test('SocketException vira "Sem conexão"', () async {
      final cliente = ApiClient(
        baseUrl: base,
        cliente: MockClient((_) async => throw const SocketException('sem rede')),
      );
      await expectLater(
        cliente.get('/x'),
        throwsA(isA<ErroApi>()
            .having((e) => e.semConexao, 'semConexao', isTrue)
            .having((e) => e.mensagem(), 'mensagem', 'Sem conexão. Tente de novo.')),
      );
    });

    test('204 devolve resposta sem conteúdo', () async {
      final cliente = ApiClient(
        baseUrl: base,
        cliente: MockClient((_) async => http.Response('', 204)),
      );
      final r = await cliente.get('/x');
      expect(r.semConteudo, isTrue);
    });

    test('fromJson que falha vira ErroApi de contrato', () {
      const r = RespostaApi(200, {'id': 1});
      expect(
        () => ApiClient.converter(r, (c) => lerString(comoObjeto(c), 'id')),
        throwsA(isA<ErroApi>().having((e) => e.codigo, 'codigo', CodigosErro.contratoInvalido)),
      );
    });

    test('envia Bearer, JSON e monta a URL', () async {
      late http.Request recebida;
      final cliente = ApiClient(
        baseUrl: Uri.parse('http://api.teste:8080/'),
        obterToken: () async => 'abc',
        cliente: MockClient((req) async {
          recebida = req;
          return jsonResposta({'ok': true}, 200);
        }),
      );
      await cliente.post('/api/entregador/posicao', corpo: {'latitude': 1});
      expect(recebida.url.toString(), 'http://api.teste:8080/api/entregador/posicao');
      expect(recebida.headers['Authorization'], 'Bearer abc');
      expect(jsonDecode(recebida.body), {'latitude': 1});
    });

    test('requisição não autenticada não envia token', () async {
      late http.Request recebida;
      final cliente = ApiClient(
        baseUrl: base,
        obterToken: () async => 'abc',
        cliente: MockClient((req) async {
          recebida = req;
          return jsonResposta({}, 200);
        }),
      );
      await cliente.post('/api/auth/login', corpo: {}, autenticado: false);
      expect(recebida.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('ConfigApp', () {
    test('API_URL vazia usa o padrão só em debug', () {
      expect(
        ConfigApp.resolver(apiUrl: '', usarFake: false, debug: true).apiUrl.toString(),
        'http://10.0.2.2:8080',
      );
      expect(ConfigApp.resolver(apiUrl: '', usarFake: false, debug: false).apiUrl, isNull);
      expect(
        ConfigApp.resolver(apiUrl: 'http://192.168.0.10:8080', usarFake: true, debug: false)
            .apiUrl
            .toString(),
        'http://192.168.0.10:8080',
      );
    });
  });
}
