/// Fakes e fábricas de dados compartilhados pelos testes.
library;

import 'dart:async';

import 'package:agiliza_mobile/app/config.dart';
import 'package:agiliza_mobile/core/dominio/modelos.dart';
import 'package:agiliza_mobile/core/fake/fake_backend.dart';
import 'package:agiliza_mobile/core/localizacao/servico_localizacao.dart';
import 'package:agiliza_mobile/core/localizacao/tarefa_periodica.dart';
import 'package:agiliza_mobile/core/providers_core.dart';
import 'package:agiliza_mobile/core/sessao/armazenamento_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

class ServicoLocalizacaoFalso implements ServicoLocalizacao {
  ServicoLocalizacaoFalso({
    this.permissao = SituacaoPermissao.concedida,
    this.posicao = const Coordenada(latitude: -23.56, longitude: -46.64),
  });

  SituacaoPermissao permissao;
  Coordenada? posicao;
  int pedidosDePermissao = 0;
  int aberturasDeConfiguracao = 0;

  @override
  Future<SituacaoPermissao> garantirPermissao() async {
    pedidosDePermissao++;
    return permissao;
  }

  @override
  Future<SituacaoPermissao> verificarPermissao() async => permissao;

  @override
  Future<Coordenada?> posicaoAtual() async =>
      permissao == SituacaoPermissao.concedida ? posicao : null;

  @override
  Future<void> abrirConfiguracoesDoApp() async => aberturasDeConfiguracao++;

  @override
  Future<void> abrirConfiguracoesDeLocalizacao() async => aberturasDeConfiguracao++;
}

class TimerFalso implements Timer {
  TimerFalso(this.intervalo, this._callback);

  final Duration intervalo;
  final void Function(Timer) _callback;
  bool cancelado = false;
  int _tiques = 0;

  /// Simula a passagem de um [intervalo].
  void disparar() {
    if (cancelado) return;
    _tiques++;
    _callback(this);
  }

  @override
  void cancel() => cancelado = true;

  @override
  bool get isActive => !cancelado;

  @override
  int get tick => _tiques;
}

/// Substitui o `Timer.periodic` para os testes controlarem o tempo.
class TimersControlados {
  final List<TimerFalso> criados = [];

  Timer criar(Duration intervalo, void Function(Timer) callback) {
    final t = TimerFalso(intervalo, callback);
    criados.add(t);
    return t;
  }

  List<TimerFalso> ativos(Duration intervalo) =>
      criados.where((t) => !t.cancelado && t.intervalo == intervalo).toList();
}

/// FakeBackend instrumentado: conta as chamadas recebidas.
class FakeBackendContador extends FakeBackend {
  FakeBackendContador({super.consultasAteDespacho = 0})
      : super(latencia: Duration.zero);

  int chamadasDisponibilidade = 0;

  @override
  Future<Motoboy> alterarDisponibilidade(status) {
    chamadasDisponibilidade++;
    return super.alterarDisponibilidade(status);
  }
}

class Ambiente {
  Ambiente({
    FakeBackendContador? backend,
    ServicoLocalizacaoFalso? localizacao,
    ArmazenamentoTokensMemoria? tokens,
  })  : backend = backend ?? FakeBackendContador(),
        localizacao = localizacao ?? ServicoLocalizacaoFalso(),
        tokens = tokens ?? ArmazenamentoTokensMemoria(),
        timers = TimersControlados();

  final FakeBackendContador backend;
  final ServicoLocalizacaoFalso localizacao;
  final ArmazenamentoTokensMemoria tokens;
  final TimersControlados timers;

  List<Override> get overrides => [
        configProvider.overrideWithValue(
          ConfigApp(apiUrl: Uri.parse('http://teste'), usarFake: true),
        ),
        fakeBackendProvider.overrideWithValue(backend),
        servicoLocalizacaoProvider.overrideWithValue(localizacao),
        armazenamentoTokensProvider.overrideWithValue(tokens),
        criarTimerPeriodicoProvider.overrideWithValue(timers.criar),
      ];

  ProviderContainer criarContainer() => ProviderContainer(overrides: overrides);
}

/// Deixa as microtarefas e futuros pendentes terminarem.
Future<void> esperarAssincrono([int voltas = 5]) async {
  for (var i = 0; i < voltas; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}
