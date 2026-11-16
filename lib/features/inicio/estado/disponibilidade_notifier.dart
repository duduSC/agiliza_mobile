import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/erros.dart';
import '../../../core/dominio/enums.dart';
import '../../../core/dominio/modelos.dart';
import '../../../core/dominio/transicoes.dart';
import '../../../core/localizacao/servico_localizacao.dart';
import '../../../core/providers_core.dart';
import '../../auth/auth.dart';
import '../data/entregador_repository.dart';

class EstadoDisponibilidade {
  const EstadoDisponibilidade({
    this.motoboy,
    this.erroCarga,
    this.enviando = false,
    this.permissaoNegada,
    this.erroAcao,
  });

  /// Último estado confirmado pelo servidor (sem atualização otimista).
  final Motoboy? motoboy;
  final ErroApi? erroCarga;
  final bool enviando;

  /// Preenchido quando o entregador tentou ficar online sem a permissão
  /// de localização (UC02 E1).
  final SituacaoPermissao? permissaoNegada;

  /// Erro da última ação (ficar online/offline), para o *snackbar*.
  final ErroApi? erroAcao;

  bool get carregando => motoboy == null && erroCarga == null;

  StatusDisponibilidadeMotoboy? get status => motoboy?.statusDisponibilidade;

  EstadoDisponibilidade copiarCom({
    Motoboy? motoboy,
    ErroApi? erroCarga,
    bool? enviando,
    SituacaoPermissao? permissaoNegada,
    ErroApi? erroAcao,
    bool limparErros = false,
  }) =>
      EstadoDisponibilidade(
        motoboy: motoboy ?? this.motoboy,
        erroCarga: limparErros ? erroCarga : (erroCarga ?? this.erroCarga),
        enviando: enviando ?? this.enviando,
        permissaoNegada:
            limparErros ? permissaoNegada : (permissaoNegada ?? this.permissaoNegada),
        erroAcao: limparErros ? erroAcao : (erroAcao ?? this.erroAcao),
      );
}

/// Online/Offline do entregador (AGENT.md 8.2, Constituição 5.2 e 5.3).
class DisponibilidadeNotifier extends Notifier<EstadoDisponibilidade> {
  @override
  EstadoDisponibilidade build() {
    final sessao = ref.watch(sessaoAtualProvider);
    if (sessao != null) unawaited(Future.microtask(carregar));
    return const EstadoDisponibilidade();
  }

  Future<void> carregar() async {
    try {
      final motoboy = await ref.read(entregadorRepositoryProvider).buscarMe();
      if (!ref.mounted) return;
      state = state.copiarCom(motoboy: motoboy, erroCarga: null, limparErros: true);
    } on ErroApi catch (e) {
      if (!ref.mounted) return;
      state = state.motoboy == null
          ? EstadoDisponibilidade(erroCarga: e)
          : state; // mantém o último estado confirmado
    }
  }

  /// Exige permissão de localização. Sem ela, a API **não** é chamada.
  Future<void> ficarOnline() async {
    final atual = state.status;
    if (state.enviando || atual == null || !podeFicarOnline(atual)) return;
    state = state.copiarCom(enviando: true, limparErros: true);
    final permissao =
        await ref.read(servicoLocalizacaoProvider).garantirPermissao();
    if (!ref.mounted) return;
    if (permissao != SituacaoPermissao.concedida) {
      state = state.copiarCom(enviando: false, permissaoNegada: permissao);
      return;
    }
    await _alterar(StatusDisponibilidadeMotoboy.ONLINE);
  }

  /// Bloqueado em `EM_ROTA` (AGENT.md 6.2).
  Future<void> ficarOffline() async {
    final atual = state.status;
    if (state.enviando || atual == null || !podeFicarOffline(atual)) return;
    state = state.copiarCom(enviando: true, limparErros: true);
    await _alterar(StatusDisponibilidadeMotoboy.OFFLINE);
  }

  Future<void> _alterar(StatusDisponibilidadeMotoboy status) async {
    try {
      final motoboy =
          await ref.read(entregadorRepositoryProvider).alterarDisponibilidade(status);
      if (!ref.mounted) return;
      state = EstadoDisponibilidade(motoboy: motoboy);
    } on ErroApi catch (e) {
      if (!ref.mounted) return;
      state = state.copiarCom(enviando: false, erroAcao: e);
      if (e.codigo == CodigosErro.transicaoEstadoInvalida) await carregar();
    }
  }

  void dispensarAvisos() {
    state = state.copiarCom(limparErros: true);
  }
}

final disponibilidadeProvider =
    NotifierProvider<DisponibilidadeNotifier, EstadoDisponibilidade>(
  DisponibilidadeNotifier.new,
);
