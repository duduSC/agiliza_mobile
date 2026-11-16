/// Guarda de `token` e `refreshToken` (Constituição 6.1).
///
/// Só estes dois valores são persistidos, e só no `flutter_secure_storage`
/// (Keystore do Android). Nunca em `SharedPreferences`, arquivo, log ou URL.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Tokens {
  const Tokens({required this.token, required this.refreshToken});

  final String token;
  final String refreshToken;

  /// Nunca imprime os valores (Constituição 6.4).
  @override
  String toString() => 'Tokens(***)';
}

abstract interface class ArmazenamentoTokens {
  Future<Tokens?> ler();
  Future<void> salvar(Tokens tokens);
  Future<void> apagar();
}

class ArmazenamentoTokensSeguro implements ArmazenamentoTokens {
  ArmazenamentoTokensSeguro([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _chaveToken = 'agiliza.token';
  static const _chaveRefresh = 'agiliza.refreshToken';

  final FlutterSecureStorage _storage;

  /// Cópia em memória para não ler o Keystore a cada requisição.
  Tokens? _cache;
  bool _carregado = false;

  @override
  Future<Tokens?> ler() async {
    if (_carregado) return _cache;
    final token = await _storage.read(key: _chaveToken);
    final refresh = await _storage.read(key: _chaveRefresh);
    _carregado = true;
    _cache = (token == null || refresh == null)
        ? null
        : Tokens(token: token, refreshToken: refresh);
    return _cache;
  }

  @override
  Future<void> salvar(Tokens tokens) async {
    await _storage.write(key: _chaveToken, value: tokens.token);
    await _storage.write(key: _chaveRefresh, value: tokens.refreshToken);
    _cache = tokens;
    _carregado = true;
  }

  @override
  Future<void> apagar() async {
    _cache = null;
    _carregado = true;
    await _storage.delete(key: _chaveToken);
    await _storage.delete(key: _chaveRefresh);
  }
}

/// Implementação em memória, usada nos testes.
class ArmazenamentoTokensMemoria implements ArmazenamentoTokens {
  ArmazenamentoTokensMemoria([this.tokens]);

  Tokens? tokens;

  @override
  Future<Tokens?> ler() async => tokens;

  @override
  Future<void> salvar(Tokens tokens) async => this.tokens = tokens;

  @override
  Future<void> apagar() async => tokens = null;
}
