/// Injeção (Riverpod) da infraestrutura compartilhada.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../app/config.dart';
import 'api/api_client.dart';
import 'api/endpoints.dart';
import 'fake/fake_backend.dart';
import 'localizacao/servico_localizacao.dart';
import 'sessao/armazenamento_tokens.dart';
import 'sessao/renovador_sessao.dart';
import 'sessao/sessao.dart';

final armazenamentoTokensProvider = Provider<ArmazenamentoTokens>(
  (ref) => ArmazenamentoTokensSeguro(),
);

final servicoLocalizacaoProvider = Provider<ServicoLocalizacao>(
  (ref) => const ServicoLocalizacaoGeolocator(),
);

final fakeBackendProvider = Provider<FakeBackend>((ref) => FakeBackend());

/// Contador de "sessão expirada": incrementado quando o refresh falha. A
/// sessão escuta este evento e faz o logout (Constituição 6.2).
class EventoSessaoExpirada extends Notifier<int> {
  @override
  int build() => 0;

  void disparar() => state++;
}

final eventoSessaoExpiradaProvider =
    NotifierProvider<EventoSessaoExpirada, int>(EventoSessaoExpirada.new);

/// Cliente HTTP de baixo nível (trocado por `MockClient` nos testes).
final httpClientProvider = Provider<http.Client>((ref) {
  final cliente = http.Client();
  ref.onDispose(cliente.close);
  return cliente;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(configProvider);
  final armazenamento = ref.watch(armazenamentoTokensProvider);
  final cliente = ApiClient(
    cliente: ref.watch(httpClientProvider),
    // Sem API_URL no release, o App mostra a tela de configuração ausente e
    // nenhuma chamada é feita; este endereço nunca é usado.
    baseUrl: config.apiUrl ?? Uri.parse('http://api-url-nao-configurada.invalid'),
    obterToken: () async => (await armazenamento.ler())?.token,
  );
  final renovador = RenovadorSessao(
    armazenamento: armazenamento,
    chamarRefresh: (refreshToken) async {
      final resposta = await cliente.post(
        Endpoints.refresh,
        corpo: {'refreshToken': refreshToken},
        autenticado: false,
      );
      return ApiClient.converter(resposta, RespostaLogin.fromJson);
    },
  );
  cliente.renovarSessao = () async {
    final renovou = await renovador.renovar();
    if (!renovou) ref.read(eventoSessaoExpiradaProvider.notifier).disparar();
    return renovou;
  };
  return cliente;
});
