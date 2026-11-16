import 'package:agiliza_mobile/core/dominio/enums.dart';
import 'package:agiliza_mobile/core/dominio/json_estrito.dart';
import 'package:agiliza_mobile/core/dominio/transicoes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('enums estritos', () {
    test('converte o nome exato do backend', () {
      expect(StatusEntrega.fromJson('EM_ROTA'), StatusEntrega.EM_ROTA);
      expect(PerfilUsuario.fromJson('ENTREGADOR'), PerfilUsuario.ENTREGADOR);
      expect(SituacaoAcerto.fromJson('EM_REVISAO'), SituacaoAcerto.EM_REVISAO);
      expect(StatusCaixa.fromJson('REABERTO'), StatusCaixa.REABERTO);
    });

    test('valor desconhecido é rejeitado, nunca substituído', () {
      expect(() => StatusEntrega.fromJson('EM_TRANSITO'), throwsA(isA<ErroContrato>()));
      expect(() => StatusLote.fromJson('em_rota'), throwsA(isA<ErroContrato>()));
      expect(
        () => lerEnum({'status': 'X'}, 'status', StatusLote.values),
        throwsA(isA<ErroContrato>()),
      );
    });

    test('cobre exatamente os valores do contrato', () {
      expect(StatusEntrega.values.map((e) => e.name), [
        'AGUARDANDO_DESPACHO', 'DESPACHADA', 'EM_ROTA', 'ENTREGUE', 'FALHA', 'CANCELADA',
      ]);
      expect(StatusLote.values.map((e) => e.name), ['DESPACHADO', 'EM_ROTA', 'CONCLUIDO', 'CANCELADO']);
      expect(StatusDisponibilidadeMotoboy.values.map((e) => e.name), ['OFFLINE', 'ONLINE', 'EM_ROTA']);
      expect(FormaPagamento.values.map((e) => e.name), ['DINHEIRO', 'CREDITO', 'DEBITO', 'PIX', 'VALE']);
      expect(MotivoRevisao.values.map((e) => e.name),
          ['SEM_COORDENADA', 'SEM_DISTANCIA', 'CONTESTACAO_ENTREGADOR']);
    });
  });

  group('json estrito', () {
    test('campo obrigatório ausente é erro de contrato', () {
      expect(() => lerString({}, 'id'), throwsA(isA<ErroContrato>()));
      expect(() => lerNumero({'v': '10'}, 'v'), throwsA(isA<ErroContrato>()));
      expect(lerNumeroOpcional({'v': null}, 'v'), isNull);
      expect(lerBoolOuFalso({}, 'pagoOnline'), isFalse);
    });
  });

  group('transições permitidas ao entregador', () {
    test('online/offline', () {
      expect(podeFicarOnline(StatusDisponibilidadeMotoboy.OFFLINE), isTrue);
      expect(podeFicarOnline(StatusDisponibilidadeMotoboy.ONLINE), isFalse);
      expect(podeFicarOffline(StatusDisponibilidadeMotoboy.ONLINE), isTrue);
      expect(podeFicarOffline(StatusDisponibilidadeMotoboy.EM_ROTA), isFalse,
          reason: 'EM_ROTA não pode ficar offline');
    });

    test('iniciar percurso só em DESPACHADO', () {
      for (final s in StatusLote.values) {
        expect(podeIniciarPercurso(s), s == StatusLote.DESPACHADO);
      }
    });

    test('ENTREGUE/FALHA só a partir de EM_ROTA', () {
      for (final s in StatusEntrega.values) {
        expect(podeFinalizarEntrega(s), s == StatusEntrega.EM_ROTA);
      }
      expect(transicaoEntregaPermitida(StatusEntrega.EM_ROTA, StatusEntrega.FALHA), isTrue);
      expect(transicaoEntregaPermitida(StatusEntrega.EM_ROTA, StatusEntrega.CANCELADA), isFalse);
      expect(transicaoEntregaPermitida(StatusEntrega.DESPACHADA, StatusEntrega.ENTREGUE), isFalse);
    });

    test('contestar só com caixa aberto/reaberto e linha A_ACERTAR', () {
      expect(podeContestar(situacao: SituacaoAcerto.A_ACERTAR, statusCaixa: StatusCaixa.ABERTO, contestacaoPermitida: true), isTrue);
      expect(podeContestar(situacao: SituacaoAcerto.A_ACERTAR, statusCaixa: StatusCaixa.REABERTO, contestacaoPermitida: true), isTrue);
      expect(podeContestar(situacao: SituacaoAcerto.A_ACERTAR, statusCaixa: StatusCaixa.FECHADO, contestacaoPermitida: false), isFalse);
      expect(podeContestar(situacao: SituacaoAcerto.A_ACERTAR, statusCaixa: null, contestacaoPermitida: false), isFalse);
      expect(podeContestar(situacao: SituacaoAcerto.EM_REVISAO, statusCaixa: StatusCaixa.ABERTO, contestacaoPermitida: true), isFalse);
      expect(podeContestar(situacao: SituacaoAcerto.A_ACERTAR, statusCaixa: StatusCaixa.ABERTO, contestacaoPermitida: false), isFalse,
          reason: 'o backend tem a palavra final');
      expect(podeContestar(situacao: SituacaoAcerto.CONSOLIDADA, statusCaixa: StatusCaixa.ABERTO, contestacaoPermitida: true), isFalse);
    });
  });
}
