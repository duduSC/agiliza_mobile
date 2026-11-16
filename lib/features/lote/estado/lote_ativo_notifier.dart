import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/erros.dart';
import '../../../core/dominio/enums.dart';
import '../../../core/dominio/modelos.dart';
import '../../../core/dominio/transicoes.dart';
import '../../../core/formatacao/data_hora.dart';
import '../../../core/localizacao/ultima_posicao.dart';
import '../../../core/providers_core.dart';
import '../../auth/auth.dart';
import '../data/lote_repository.dart';
import '../data/modelos_lote.dart';

class EstadoLoteAtivo {
  const EstadoLoteAtivo({
    this.carregado = false,
    this.lote,
    this.erro,
    this.enviando = false,
  });

  /// Já houve pelo menos uma resposta (com ou sem lote).
  final bool carregado;
  final LoteAtivo? lote;

  /// Erro da última consulta. O último lote conhecido continua na tela.
  final ErroApi? erro;

  /// Uma ação (iniciar, entregue, falha) está em envio: os botões ficam
  /// bloqueados (sem duplo envio e sem atualização otimista).
  final bool enviando;

  bool get carregando => !carregado && erro == null;

  EstadoLoteAtivo comEnvio(bool enviando) =>
      EstadoLoteAtivo(carregado: carregado, lote: lote, erro: erro, enviando: enviando);
}

/// Resultado de uma ação do entregador, para a tela decidir o que mostrar.
class ResultadoAcao {
  const ResultadoAcao._({this.erro, this.loteConcluido = false});

  const ResultadoAcao.ok({bool loteConcluido = false})
      : this._(loteConcluido: loteConcluido);

  const ResultadoAcao.falhou(ErroApi erro) : this._(erro: erro);

  final ErroApi? erro;

  /// Depois da ação o servidor respondeu `204`: o lote foi encerrado.
  final bool loteConcluido;

  bool get sucesso => erro == null;
}

const tempoMaximoCoordenada = Duration(seconds: 3);

/// Lote ativo do entregador, atualizado pelo polling de 10 s (D008) e depois
/// de cada ação. Descartado no logout (observa a sessão).
class LoteAtivoNotifier extends Notifier<EstadoLoteAtivo> {
  @override
  EstadoLoteAtivo build() {
    ref.watch(sessaoAtualProvider);
    return const EstadoLoteAtivo();
  }

  Future<void> recarregar() async {
    try {
      final lote = await ref.read(loteRepositoryProvider).buscarLoteAtivo();
      if (!ref.mounted) return;
      state = EstadoLoteAtivo(carregado: true, lote: lote, enviando: state.enviando);
    } on ErroApi catch (e) {
      if (!ref.mounted) return;
      state = EstadoLoteAtivo(
          carregado: state.carregado, lote: state.lote, erro: e, enviando: state.enviando);
    }
  }

  /// Saída da loja (UC02 passo 4). Só para lote DESPACHADO.
  Future<ResultadoAcao> iniciarPercurso() async {
    final lote = state.lote;
    if (state.enviando || lote == null || !podeIniciarPercurso(lote.status)) {
      return const ResultadoAcao.ok();
    }
    state = state.comEnvio(true);
    try {
      final atualizado = await ref.read(loteRepositoryProvider).iniciarPercurso(lote.id);
      if (!ref.mounted) return const ResultadoAcao.ok();
      state = EstadoLoteAtivo(carregado: true, lote: atualizado);
      return const ResultadoAcao.ok();
    } on ErroApi catch (e) {
      return _aposErro(e);
    }
  }

  Future<ResultadoAcao> marcarEntregue(String entregaId) =>
      _finalizar(entregaId, StatusEntrega.ENTREGUE, null);

  /// FALHA exige motivo (até 100 caracteres). Sem motivo, nada é enviado.
  Future<ResultadoAcao> marcarFalha(String entregaId, String motivo) {
    final texto = motivo.trim();
    if (texto.isEmpty || texto.length > limiteMotivoFalha) {
      return Future.value(const ResultadoAcao.ok());
    }
    return _finalizar(entregaId, StatusEntrega.FALHA, texto);
  }

  Future<ResultadoAcao> _finalizar(
      String entregaId, StatusEntrega status, String? motivo) async {
    // ocorridoEm é o horário do toque, antes de qualquer espera (Constituição 5.4).
    final ocorridoEm = agoraSaoPaulo(ref.read(relogioProvider));
    final entrega = state.lote?.entregaPorId(entregaId);
    if (state.enviando || entrega == null || !podeFinalizarEntrega(entrega.status)) {
      return const ResultadoAcao.ok();
    }
    state = state.comEnvio(true);
    final coordenada = await _coordenadaAtual();
    try {
      await ref.read(loteRepositoryProvider).alterarStatus(
            entregaId,
            PedidoStatusEntrega(
              status: status,
              ocorridoEm: ocorridoEm,
              motivoFalha: motivo,
              coordenada: coordenada,
            ),
          );
      if (!ref.mounted) return const ResultadoAcao.ok();
      await recarregar();
      if (!ref.mounted) return const ResultadoAcao.ok();
      state = state.comEnvio(false);
      return ResultadoAcao.ok(loteConcluido: state.carregado && state.lote == null);
    } on ErroApi catch (e) {
      return _aposErro(e);
    }
  }

  /// Posição atual (no máximo 3 s de espera) ou a última conhecida, ou nenhuma.
  Future<Coordenada?> _coordenadaAtual() async {
    final ultima = ref.read(ultimaPosicaoProvider);
    try {
      final atual = await ref
          .read(servicoLocalizacaoProvider)
          .posicaoAtual()
          .timeout(tempoMaximoCoordenada, onTimeout: () => null);
      if (atual != null && ref.mounted) {
        ref.read(ultimaPosicaoProvider.notifier).registrar(atual);
      }
      return atual ?? ultima;
    } catch (_) {
      return ultima;
    }
  }

  /// Sem atualização otimista: em erro, a tela continua com o último estado
  /// confirmado. Transição inválida ou recurso sumido (lote devolvido pelo
  /// operador) recarregam o lote (AGENT.md 6.5, S001).
  Future<ResultadoAcao> _aposErro(ErroApi e) async {
    if (!ref.mounted) return ResultadoAcao.falhou(e);
    state = state.comEnvio(false);
    if (e.codigo == CodigosErro.transicaoEstadoInvalida ||
        e.codigo == CodigosErro.recursoNaoEncontrado) {
      await recarregar();
    }
    return ResultadoAcao.falhou(e);
  }
}

const limiteMotivoFalha = 100;

/// Relógio injetável (testes).
final relogioProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final loteAtivoProvider =
    NotifierProvider<LoteAtivoNotifier, EstadoLoteAtivo>(LoteAtivoNotifier.new);
