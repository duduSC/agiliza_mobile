/// Leitura estrita de JSON (Constituição 7.2).
///
/// Toda conversão de resposta da API passa por estas funções. Campo obrigatório
/// ausente, tipo errado ou valor de enum desconhecido viram [ErroContrato], que o
/// `ApiClient` converte em `ErroApi` de contrato, nunca numa exceção solta na tela.
library;

import '../formatacao/data_hora.dart';

/// Resposta da API fora do contrato esperado.
class ErroContrato implements Exception {
  const ErroContrato(this.descricao);

  final String descricao;

  @override
  String toString() => 'ErroContrato: $descricao';
}

typedef Json = Map<String, dynamic>;

Json comoObjeto(Object? valor, [String contexto = 'resposta']) {
  if (valor is Map<String, dynamic>) return valor;
  if (valor is Map) return valor.map((k, v) => MapEntry(k.toString(), v));
  throw ErroContrato('$contexto: esperado objeto JSON');
}

List<Object?> comoLista(Object? valor, [String contexto = 'resposta']) {
  if (valor is List) return valor;
  throw ErroContrato('$contexto: esperada lista JSON');
}

/// Lista opcional: ausente ou `null` vira lista vazia.
List<Object?> lerListaOuVazia(Json json, String campo) {
  final valor = json[campo];
  if (valor == null) return const [];
  return comoLista(valor, campo);
}

String lerString(Json json, String campo) {
  final valor = json[campo];
  if (valor is String) return valor;
  throw ErroContrato('campo "$campo" obrigatório (texto)');
}

String? lerStringOpcional(Json json, String campo) {
  final valor = json[campo];
  if (valor == null) return null;
  if (valor is String) return valor;
  throw ErroContrato('campo "$campo" deveria ser texto');
}

num lerNumero(Json json, String campo) {
  final valor = json[campo];
  if (valor is num) return valor;
  throw ErroContrato('campo "$campo" obrigatório (número)');
}

num? lerNumeroOpcional(Json json, String campo) {
  final valor = json[campo];
  if (valor == null) return null;
  if (valor is num) return valor;
  throw ErroContrato('campo "$campo" deveria ser número');
}

int lerInteiro(Json json, String campo) => lerNumero(json, campo).toInt();

int? lerInteiroOpcional(Json json, String campo) =>
    lerNumeroOpcional(json, campo)?.toInt();

bool lerBool(Json json, String campo) {
  final valor = json[campo];
  if (valor is bool) return valor;
  throw ErroContrato('campo "$campo" obrigatório (booleano)');
}

/// Booleano que o backend serializa como `Boolean` (pode vir `null`).
bool lerBoolOuFalso(Json json, String campo) {
  final valor = json[campo];
  if (valor == null) return false;
  if (valor is bool) return valor;
  throw ErroContrato('campo "$campo" deveria ser booleano');
}

DateTime lerDataHora(Json json, String campo) {
  final texto = lerString(json, campo);
  return _converterData(texto, campo);
}

DateTime? lerDataHoraOpcional(Json json, String campo) {
  final texto = lerStringOpcional(json, campo);
  if (texto == null) return null;
  return _converterData(texto, campo);
}

DateTime _converterData(String texto, String campo) {
  try {
    return lerLocalDateTime(texto);
  } on FormatException {
    throw ErroContrato('campo "$campo" com data inválida');
  }
}

T lerEnum<T extends Enum>(Json json, String campo, List<T> valores) {
  final texto = lerString(json, campo);
  return enumPorNome(texto, valores, campo);
}

T? lerEnumOpcional<T extends Enum>(Json json, String campo, List<T> valores) {
  final texto = lerStringOpcional(json, campo);
  if (texto == null) return null;
  return enumPorNome(texto, valores, campo);
}

/// Converte o nome exato do enum do backend. Valor desconhecido é erro de contrato
/// (AGENT.md 6.1): nunca se inventa um valor substituto.
T enumPorNome<T extends Enum>(String texto, List<T> valores, String contexto) {
  for (final valor in valores) {
    if (valor.name == texto) return valor;
  }
  throw ErroContrato('valor desconhecido "$texto" em "$contexto"');
}
