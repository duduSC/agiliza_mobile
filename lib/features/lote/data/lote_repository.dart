import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/fake/fake_backend.dart';
import '../../../core/providers_core.dart';
import 'modelos_lote.dart';

/// Lote do entregador (UC02).
abstract interface class LoteRepository {
  /// `GET /api/entregador/lote-ativo`. `null` quando o servidor responde `204`.
  Future<LoteAtivo?> buscarLoteAtivo();
}

class ApiLoteRepository implements LoteRepository {
  ApiLoteRepository(this._api);

  final ApiClient _api;

  @override
  Future<LoteAtivo?> buscarLoteAtivo() async {
    final resposta = await _api.get(Endpoints.loteAtivo);
    if (resposta.semConteudo) return null;
    return ApiClient.converter(resposta, LoteAtivo.fromJson);
  }
}

class FakeLoteRepository implements LoteRepository {
  FakeLoteRepository(this._fake);

  final FakeBackend _fake;

  @override
  Future<LoteAtivo?> buscarLoteAtivo() async {
    final json = await _fake.buscarLoteAtivo();
    if (json == null) return null;
    return ApiClient.converterCorpo(json, LoteAtivo.fromJson);
  }
}

final loteRepositoryProvider = Provider<LoteRepository>((ref) {
  final config = ref.watch(configProvider);
  if (config.usarFake) return FakeLoteRepository(ref.watch(fakeBackendProvider));
  return ApiLoteRepository(ref.watch(apiClientProvider));
});
