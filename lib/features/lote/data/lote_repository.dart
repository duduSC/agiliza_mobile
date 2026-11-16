import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/dominio/enums.dart';
import '../../../core/dominio/modelos.dart';
import '../../../core/dominio/transicoes.dart';
import '../../../core/fake/fake_backend.dart';
import '../../../core/fake/fake_backend_lote.dart';
import '../../../core/formatacao/data_hora.dart';
import '../../../core/providers_core.dart';
import 'modelos_lote.dart';

/// Pedido de ENTREGUE/FALHA (`AlterarStatusEntregaRequest`).
class PedidoStatusEntrega {
  const PedidoStatusEntrega({
    required this.status,
    required this.ocorridoEm,
    this.motivoFalha,
    this.coordenada,
  });

  /// Só `ENTREGUE` ou `FALHA` (AGENT.md 6.2).
  final StatusEntrega status;

  /// Horário do toque, relógio de São Paulo, sem fuso (Constituição 5.4).
  final DateTime ocorridoEm;
  final String? motivoFalha;
  final Coordenada? coordenada;

  Map<String, Object?> toJson() {
    assert(statusFinaisDoEntregador.contains(status));
    return {
      'status': status.name,
      'motivoFalha': status == StatusEntrega.FALHA ? motivoFalha : null,
      'coordenada': coordenada?.toJson(),
      'ocorridoEm': escreverLocalDateTime(ocorridoEm),
    };
  }
}

/// Lote do entregador (UC02).
abstract interface class LoteRepository {
  /// `GET /api/entregador/lote-ativo`. `null` quando o servidor responde `204`.
  Future<LoteAtivo?> buscarLoteAtivo();

  /// `POST /api/entregador/lotes/{id}/iniciar`: DESPACHADO → EM_ROTA.
  Future<LoteAtivo> iniciarPercurso(String loteId);

  /// `POST /api/entregador/entregas/{id}/status`.
  Future<Entrega> alterarStatus(String entregaId, PedidoStatusEntrega pedido);
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

  @override
  Future<LoteAtivo> iniciarPercurso(String loteId) async {
    final resposta = await _api.post(Endpoints.iniciarLote(loteId));
    return ApiClient.converter(resposta, LoteAtivo.fromJson);
  }

  @override
  Future<Entrega> alterarStatus(String entregaId, PedidoStatusEntrega pedido) async {
    final resposta =
        await _api.post(Endpoints.statusEntrega(entregaId), corpo: pedido.toJson());
    return ApiClient.converter(resposta, Entrega.fromJson);
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

  @override
  Future<LoteAtivo> iniciarPercurso(String loteId) async =>
      ApiClient.converterCorpo(await _fake.iniciarLote(loteId), LoteAtivo.fromJson);

  @override
  Future<Entrega> alterarStatus(String entregaId, PedidoStatusEntrega pedido) async =>
      ApiClient.converterCorpo(
        await _fake.alterarStatusEntrega(entregaId, pedido.toJson()),
        Entrega.fromJson,
      );
}

final loteRepositoryProvider = Provider<LoteRepository>((ref) {
  final config = ref.watch(configProvider);
  if (config.usarFake) return FakeLoteRepository(ref.watch(fakeBackendProvider));
  return ApiLoteRepository(ref.watch(apiClientProvider));
});
