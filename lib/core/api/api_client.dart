/// ÚNICO ponto HTTP do app (AGENT.md 5).
///
/// - base URL vinda de `--dart-define=API_URL`;
/// - header `Authorization: Bearer <token>`;
/// - `ApiErrorResponse` convertido em [ErroApi];
/// - sem rede ou timeout viram [ErroApi.semConexao] (sem fila: D008);
/// - num 401, aciona o gancho [renovarSessao] e repete a requisição uma vez.
///
/// Nunca registra em log token, corpo de requisição ou de resposta
/// (Constituição 6.4).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../dominio/json_estrito.dart';
import 'erros.dart';

/// Lê o token de acesso atual (ou `null` sem sessão).
typedef ObterToken = Future<String?> Function();

/// Tenta renovar a sessão. Devolve `true` se um novo token foi obtido.
typedef RenovarSessao = Future<bool> Function();

class RespostaApi {
  const RespostaApi(this.status, this.corpo);

  final int status;

  /// JSON já decodificado, ou `null` em `204`/corpo vazio.
  final Object? corpo;

  bool get semConteudo => status == 204 || corpo == null;
}

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? cliente,
    this.obterToken,
    this.renovarSessao,
    this.timeout = const Duration(seconds: 15),
  }) : _cliente = cliente ?? http.Client();

  final Uri baseUrl;
  final http.Client _cliente;
  final Duration timeout;

  ObterToken? obterToken;
  RenovarSessao? renovarSessao;

  Uri montarUri(String caminho, [Map<String, String>? query]) {
    final base = baseUrl.toString().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base$caminho');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  Future<RespostaApi> get(
    String caminho, {
    Map<String, String>? query,
    bool autenticado = true,
  }) =>
      _enviar('GET', caminho, query: query, autenticado: autenticado);

  Future<RespostaApi> post(
    String caminho, {
    Object? corpo,
    bool autenticado = true,
  }) =>
      _enviar('POST', caminho, corpo: corpo, autenticado: autenticado);

  Future<RespostaApi> patch(
    String caminho, {
    Object? corpo,
    bool autenticado = true,
  }) =>
      _enviar('PATCH', caminho, corpo: corpo, autenticado: autenticado);

  /// Converte o corpo com um `fromJson` estrito. Resposta fora do contrato
  /// vira [ErroApi.contrato] (Constituição 7.2).
  static T converter<T>(RespostaApi resposta, T Function(Object? corpo) fromJson) =>
      converterCorpo(resposta.corpo, fromJson);

  /// Igual a [converter], para um JSON já decodificado (usado pelos fakes,
  /// que assim passam pelo mesmo `fromJson` estrito da API real).
  static T converterCorpo<T>(Object? corpo, T Function(Object? corpo) fromJson) {
    try {
      return fromJson(corpo);
    } on ErroContrato {
      throw const ErroApi.contrato();
    } on TypeError {
      throw const ErroApi.contrato();
    } on FormatException {
      throw const ErroApi.contrato();
    }
  }

  Future<RespostaApi> _enviar(
    String metodo,
    String caminho, {
    Map<String, String>? query,
    Object? corpo,
    required bool autenticado,
  }) async {
    final primeira = await _requisitar(metodo, caminho, query, corpo, autenticado);
    if (primeira.statusCode == 401 && autenticado && renovarSessao != null) {
      final renovou = await renovarSessao!();
      if (renovou) {
        final segunda =
            await _requisitar(metodo, caminho, query, corpo, autenticado);
        return _interpretar(segunda);
      }
    }
    return _interpretar(primeira);
  }

  Future<http.Response> _requisitar(
    String metodo,
    String caminho,
    Map<String, String>? query,
    Object? corpo,
    bool autenticado,
  ) async {
    final requisicao = http.Request(metodo, montarUri(caminho, query));
    requisicao.headers['Accept'] = 'application/json';
    if (corpo != null) {
      requisicao.headers['Content-Type'] = 'application/json; charset=utf-8';
      requisicao.body = jsonEncode(corpo);
    }
    if (autenticado && obterToken != null) {
      final token = await obterToken!();
      if (token != null && token.isNotEmpty) {
        requisicao.headers['Authorization'] = 'Bearer $token';
      }
    }
    try {
      final enviada = await _cliente.send(requisicao).timeout(timeout);
      return await http.Response.fromStream(enviada).timeout(timeout);
    } on SocketException {
      throw const ErroApi.semConexao();
    } on TimeoutException {
      throw const ErroApi.semConexao();
    } on http.ClientException {
      throw const ErroApi.semConexao();
    } on HandshakeException {
      throw const ErroApi.semConexao();
    }
  }

  RespostaApi _interpretar(http.Response resposta) {
    final texto = utf8.decode(resposta.bodyBytes, allowMalformed: true);
    Object? json;
    if (texto.trim().isNotEmpty) {
      try {
        json = jsonDecode(texto);
      } on FormatException {
        json = null;
        if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
          throw const ErroApi.contrato();
        }
      }
    }
    if (resposta.statusCode >= 200 && resposta.statusCode < 300) {
      return RespostaApi(resposta.statusCode, json);
    }
    throw ErroApi.daResposta(resposta.statusCode, json);
  }

  void fechar() => _cliente.close();
}
