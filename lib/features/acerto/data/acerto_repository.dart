import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/fake/fake_backend.dart';
import '../../../core/fake/fake_backend_acerto.dart';
import '../../../core/providers_core.dart';
import 'modelos_acerto.dart';

/// Acerto do turno (UC08, HU14).
abstract interface class AcertoRepository {
  /// `GET /api/entregador/acerto`, sem parâmetros: o dia atual.
  Future<AcertoDoEntregador> buscarAcerto();

  /// `POST /api/entregador/entregas/{id}/contestar` (UC08 A1).
  Future<void> contestar(String entregaId);
}

class ApiAcertoRepository implements AcertoRepository {
  ApiAcertoRepository(this._api);

  final ApiClient _api;

  @override
  Future<AcertoDoEntregador> buscarAcerto() async =>
      ApiClient.converter(await _api.get(Endpoints.acerto), AcertoDoEntregador.fromJson);

  @override
  Future<void> contestar(String entregaId) async {
    // A resposta (a entrega com pendenteRevisao) não é usada: a tela recarrega
    // o extrato, que é a fonte dos totais.
    await _api.post(Endpoints.contestarEntrega(entregaId));
  }
}

class FakeAcertoRepository implements AcertoRepository {
  FakeAcertoRepository(this._fake);

  final FakeBackend _fake;

  @override
  Future<AcertoDoEntregador> buscarAcerto() async =>
      ApiClient.converterCorpo(await _fake.buscarAcerto(), AcertoDoEntregador.fromJson);

  @override
  Future<void> contestar(String entregaId) => _fake.contestar(entregaId);
}

final acertoRepositoryProvider = Provider<AcertoRepository>((ref) {
  final config = ref.watch(configProvider);
  if (config.usarFake) return FakeAcertoRepository(ref.watch(fakeBackendProvider));
  return ApiAcertoRepository(ref.watch(apiClientProvider));
});
