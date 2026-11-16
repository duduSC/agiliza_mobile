/// Backend em memória para `--dart-define=USAR_FAKE=true` e para os testes
/// (AGENT.md 3.3). Simula as regras do contrato S001 e a máquina de estados do
/// DVP 1.4.4, devolvendo os mesmos códigos de erro do servidor.
///
/// Isto é uma SIMULAÇÃO DO SERVIDOR: as telas nunca calculam nada; quem
/// "calcula" aqui faz o papel do backend.
library;

import '../api/erros.dart';
import '../dominio/enums.dart';
import '../dominio/modelos.dart';
import '../sessao/armazenamento_tokens.dart';
import '../sessao/sessao.dart';

class FakeBackend {
  FakeBackend({
    this.latencia = const Duration(milliseconds: 400),
    this.consultasAteDespacho = 1,
  });

  /// Atraso artificial de cada chamada (zero nos testes).
  final Duration latencia;

  /// Quantas consultas ao lote ativo, depois de ficar ONLINE, até o "operador"
  /// despachar um lote (com o polling de 10 s, 1 = cerca de 10 s).
  final int consultasAteDespacho;

  static const emailEntregador = 'entregador@agiliza.com';
  static const emailOperador = 'operador@agiliza.com';
  static const senhaPadrao = '123456';
  static const motoboyId = 'fake-motoboy-1';

  Motoboy motoboy = const Motoboy(
    id: motoboyId,
    nome: 'Carlos Entregador',
    statusCadastro: StatusCadastroMotoboy.ATIVO,
    statusDisponibilidade: StatusDisponibilidadeMotoboy.OFFLINE,
  );

  Coordenada? ultimaPosicao;
  int posicoesRecebidas = 0;
  int _consultasOnline = 0;
  int _geracao = 0;
  int _tokens = 0;

  /// Lote ativo em JSON, no formato do `LoteDoEntregadorResponse`.
  Map<String, Object?>? loteAtivo;

  /// Último corpo recebido em `POST /entregas/{id}/status` (para os testes).
  Map<String, Object?>? ultimoCorpoStatus;

  /// Entregas finalizadas em lotes já concluídos (alimentam o acerto).
  final List<Map<String, Object?>> entregasFinalizadas = [];

  Future<void> esperarLatencia() async {
    if (latencia > Duration.zero) await Future<void>.delayed(latencia);
  }

  ErroApi _erro(int status, String codigo, String mensagem) =>
      ErroApi(status: status, codigo: codigo, mensagemServidor: mensagem);

  // ---------------------------------------------------------------- auth

  Future<Map<String, Object?>> login(String email, String senha) async {
    await esperarLatencia();
    final e = email.trim().toLowerCase();
    if (senha != senhaPadrao || (e != emailEntregador && e != emailOperador)) {
      throw _erro(401, CodigosErro.credenciaisInvalidas, 'Credenciais inválidas');
    }
    _tokens++;
    final entregador = e == emailEntregador;
    return {
      'token': 'fake-token-$_tokens',
      'refreshToken': 'fake-refresh-$_tokens',
      'usuario': {
        'usuarioId': entregador ? 'fake-usuario-1' : 'fake-usuario-2',
        'estabelecimentoId': 'fake-loja-1',
        'motoboyId': entregador ? motoboyId : null,
        'nome': entregador ? motoboy.nome : 'Olga Operadora',
        'perfil': entregador ? 'ENTREGADOR' : 'OPERADOR',
      },
    };
  }

  Future<RespostaLogin> refresh(String refreshToken) async {
    await esperarLatencia();
    if (!refreshToken.startsWith('fake-refresh-')) {
      throw _erro(401, CodigosErro.naoAutenticado, 'Sessão expirada');
    }
    _tokens++;
    return RespostaLogin(
      tokens: Tokens(token: 'fake-token-$_tokens', refreshToken: 'fake-refresh-$_tokens'),
      usuario: UsuarioAutenticado(
        usuarioId: 'fake-usuario-1',
        estabelecimentoId: 'fake-loja-1',
        motoboyId: motoboyId,
        nome: motoboy.nome,
        perfil: PerfilUsuario.ENTREGADOR,
      ),
    );
  }

  // ---------------------------------------------------------- entregador

  Future<Motoboy> me() async {
    await esperarLatencia();
    return motoboy;
  }

  Future<Motoboy> alterarDisponibilidade(StatusDisponibilidadeMotoboy status) async {
    await esperarLatencia();
    if (status == StatusDisponibilidadeMotoboy.EM_ROTA) {
      throw _erro(400, 'DADOS_INVALIDOS', 'EM_ROTA é controlado pelo lote');
    }
    if (motoboy.statusDisponibilidade == StatusDisponibilidadeMotoboy.EM_ROTA) {
      throw _erro(422, CodigosErro.transicaoEstadoInvalida,
          'Entregador em rota não pode alterar a disponibilidade');
    }
    motoboy = motoboy.copiarCom(statusDisponibilidade: status);
    if (status == StatusDisponibilidadeMotoboy.ONLINE) _consultasOnline = 0;
    return motoboy;
  }

  Future<Motoboy> enviarPosicao(Coordenada c) async {
    await esperarLatencia();
    if (motoboy.statusDisponibilidade == StatusDisponibilidadeMotoboy.OFFLINE) {
      throw _erro(422, CodigosErro.regraNegocioViolada, 'Entregador offline');
    }
    ultimaPosicao = c;
    posicoesRecebidas++;
    return motoboy;
  }

  // ---------------------------------------------------------------- lote

  /// `null` equivale ao `204` do servidor.
  Future<Map<String, Object?>?> buscarLoteAtivo() async {
    await esperarLatencia();
    if (loteAtivo == null &&
        motoboy.statusDisponibilidade == StatusDisponibilidadeMotoboy.ONLINE) {
      _consultasOnline++;
      if (_consultasOnline > consultasAteDespacho) despacharLoteDeExemplo();
    }
    return loteAtivo;
  }

  /// Todas as entregas em estado final: lote CONCLUIDO, entregador volta a
  /// ONLINE e o `lote-ativo` passa a responder 204 (UC02 passo 6).
  void concluirLoteAtivo() {
    final lote = loteAtivo;
    if (lote == null) return;
    lote['status'] = 'CONCLUIDO';
    entregasFinalizadas.addAll(
        (lote['entregas']! as List<Object?>).cast<Map<String, Object?>>());
    loteAtivo = null;
    motoboy = motoboy.copiarCom(statusDisponibilidade: StatusDisponibilidadeMotoboy.ONLINE);
    // O próximo lote de exemplo chega algumas consultas depois.
    _consultasOnline = -2;
  }

  /// Faz o papel do operador despachando um lote (ONLINE → EM_ROTA, DVP 1.4.4).
  void despacharLoteDeExemplo() {
    _geracao++;
    final g = _geracao;
    final loteId = 'fake-lote-$g';
    loteAtivo = {
      'id': loteId,
      'status': 'DESPACHADO',
      'qtdEntregas': 2,
      'despachadoEm': '2026-11-17T19:00:00',
      'concluidoEm': null,
      'nomeFantasiaEstabelecimento': 'Pizzaria Agiliza',
      'coordenadaEstabelecimento': {'latitude': -23.55052, 'longitude': -46.633308},
      'entregas': [
        {
          'id': 'fake-entrega-$g-1',
          'loteId': loteId,
          'ordemRota': 1,
          'status': 'DESPACHADA',
          'nomeCliente': 'Maria Souza',
          'telefoneCliente': '11988887777',
          'enderecoCompleto': 'Av. Paulista, 1000 - Bela Vista, São Paulo - SP',
          'bairro': 'Bela Vista',
          'cep': '01310100',
          'complemento': 'ap 12',
          'pontoReferencia': 'ao lado do banco',
          'coordenada': {'latitude': -23.5614, 'longitude': -46.6559},
          'valorPedido': 50.0,
          'formaPagamento': 'DINHEIRO',
          'pagoOnline': false,
          'trocoPara': 100.0,
          'observacoes': null,
          'distanciaKm': 2.1,
          'valorRepasse': 9.0,
          'motivoFalha': null,
          'finalizadaEm': null,
          'pendenteRevisao': false,
          'motivoRevisao': null,
          'itens': [
            {'descricao': 'Pizza calabresa', 'quantidade': 2, 'observacao': 'sem cebola'},
            {'descricao': 'Refrigerante 2 L', 'quantidade': 1, 'observacao': null},
          ],
        },
        {
          'id': 'fake-entrega-$g-2',
          'loteId': loteId,
          'ordemRota': 2,
          'status': 'DESPACHADA',
          'nomeCliente': 'João Lima',
          'telefoneCliente': null,
          'enderecoCompleto': 'Rua Augusta, 500 - Consolação, São Paulo - SP',
          'bairro': 'Consolação',
          'cep': '01304000',
          'complemento': null,
          'pontoReferencia': null,
          'coordenada': null,
          'valorPedido': 72.9,
          'formaPagamento': 'PIX',
          'pagoOnline': true,
          'trocoPara': null,
          'observacoes': 'Interfone quebrado, ligar ao chegar',
          'distanciaKm': null,
          'valorRepasse': null,
          'motivoFalha': null,
          'finalizadaEm': null,
          'pendenteRevisao': false,
          'motivoRevisao': null,
          'itens': <Object?>[],
        },
      ],
    };
    motoboy = motoboy.copiarCom(statusDisponibilidade: StatusDisponibilidadeMotoboy.EM_ROTA);
  }
}
