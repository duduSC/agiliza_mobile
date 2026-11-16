import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/dominio/enums.dart';
import '../../../core/dominio/modelos.dart';
import '../../../core/dominio/transicoes.dart';
import '../../../core/fake/fake_backend.dart';
import '../../../core/providers_core.dart';

/// Cadastro, disponibilidade e posição do próprio entregador. O `motoboyId`
/// nunca vai na requisição: o backend o tira do token (Constituição 5.8).
abstract interface class EntregadorRepository {
  Future<Motoboy> buscarMe();

  /// Só `ONLINE` ou `OFFLINE` (AGENT.md 6.2).
  Future<Motoboy> alterarDisponibilidade(StatusDisponibilidadeMotoboy status);

  Future<void> enviarPosicao(Coordenada coordenada);
}

class ApiEntregadorRepository implements EntregadorRepository {
  ApiEntregadorRepository(this._api);

  final ApiClient _api;

  @override
  Future<Motoboy> buscarMe() async =>
      ApiClient.converter(await _api.get(Endpoints.me), Motoboy.fromJson);

  @override
  Future<Motoboy> alterarDisponibilidade(StatusDisponibilidadeMotoboy status) async {
    assert(disponibilidadesPedidasPeloEntregador.contains(status));
    final resposta = await _api.patch(
      Endpoints.disponibilidade,
      corpo: {'status': status.name},
    );
    return ApiClient.converter(resposta, Motoboy.fromJson);
  }

  @override
  Future<void> enviarPosicao(Coordenada coordenada) async {
    await _api.patch(Endpoints.posicao, corpo: coordenada.toJson());
  }
}

class FakeEntregadorRepository implements EntregadorRepository {
  FakeEntregadorRepository(this._fake);

  final FakeBackend _fake;

  @override
  Future<Motoboy> buscarMe() => _fake.me();

  @override
  Future<Motoboy> alterarDisponibilidade(StatusDisponibilidadeMotoboy status) =>
      _fake.alterarDisponibilidade(status);

  @override
  Future<void> enviarPosicao(Coordenada coordenada) => _fake.enviarPosicao(coordenada);
}

final entregadorRepositoryProvider = Provider<EntregadorRepository>((ref) {
  final config = ref.watch(configProvider);
  if (config.usarFake) return FakeEntregadorRepository(ref.watch(fakeBackendProvider));
  return ApiEntregadorRepository(ref.watch(apiClientProvider));
});
