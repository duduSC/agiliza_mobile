import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/dominio/modelos.dart';
import '../../../core/fake/fake_backend.dart';
import '../../../core/providers_core.dart';
import '../../../core/sessao/sessao.dart';

/// UC07: login pelo canal do app e validação da sessão salva.
abstract interface class AuthRepository {
  /// `POST /api/auth/login` com `canal: "APP"`.
  Future<RespostaLogin> entrar(String email, String senha);

  /// `GET /api/entregador/me`: confirma que os tokens salvos ainda valem.
  Future<Motoboy> buscarEntregadorDaSessao();
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api);

  final ApiClient _api;

  @override
  Future<RespostaLogin> entrar(String email, String senha) async {
    final resposta = await _api.post(
      Endpoints.login,
      corpo: {'loginEmail': email.trim(), 'senha': senha, 'canal': 'APP'},
      autenticado: false,
    );
    return ApiClient.converter(resposta, RespostaLogin.fromJson);
  }

  @override
  Future<Motoboy> buscarEntregadorDaSessao() async {
    final resposta = await _api.get(Endpoints.me);
    return ApiClient.converter(resposta, Motoboy.fromJson);
  }
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._fake);

  final FakeBackend _fake;

  @override
  Future<RespostaLogin> entrar(String email, String senha) async {
    final json = await _fake.login(email, senha);
    return ApiClient.converterCorpo(json, RespostaLogin.fromJson);
  }

  @override
  Future<Motoboy> buscarEntregadorDaSessao() => _fake.me();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(configProvider);
  if (config.usarFake) return FakeAuthRepository(ref.watch(fakeBackendProvider));
  return ApiAuthRepository(ref.watch(apiClientProvider));
});
