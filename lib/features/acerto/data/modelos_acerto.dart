/// Acerto do turno no contrato real da T009 (`AcertoDoEntregadorResponse`,
/// `ExtratoAcertoResponse`, `LinhaExtratoResponse`; S001, item 8).
///
/// Todos os totais vêm do backend. O app nunca soma valores (Constituição 5.1).
library;

import '../../../core/dominio/enums.dart';
import '../../../core/dominio/json_estrito.dart';

class LinhaExtrato {
  const LinhaExtrato({
    required this.entregaId,
    required this.nomeCliente,
    required this.status,
    required this.situacao,
    required this.foraDeArea,
    this.finalizadaEm,
    this.distanciaKm,
    this.faixaDeKm,
    this.faixaAteKm,
    this.valorRepasse,
    this.reciboId,
  });

  final String entregaId;
  final String nomeCliente;
  final DateTime? finalizadaEm;
  final StatusEntrega status;
  final num? distanciaKm;
  final num? faixaDeKm;
  final num? faixaAteKm;
  final bool foraDeArea;
  final num? valorRepasse;
  final SituacaoAcerto situacao;
  final String? reciboId;

  factory LinhaExtrato.fromJson(Object? json) {
    final m = comoObjeto(json, 'linha');
    return LinhaExtrato(
      entregaId: lerString(m, 'entregaId'),
      nomeCliente: lerString(m, 'nomeCliente'),
      finalizadaEm: lerDataHoraOpcional(m, 'finalizadaEm'),
      status: lerEnum(m, 'status', StatusEntrega.values),
      distanciaKm: lerNumeroOpcional(m, 'distanciaKm'),
      faixaDeKm: lerNumeroOpcional(m, 'faixaDeKm'),
      faixaAteKm: lerNumeroOpcional(m, 'faixaAteKm'),
      foraDeArea: lerBoolOuFalso(m, 'foraDeArea'),
      valorRepasse: lerNumeroOpcional(m, 'valorRepasse'),
      situacao: lerEnum(m, 'situacao', SituacaoAcerto.values),
      reciboId: lerStringOpcional(m, 'reciboId'),
    );
  }
}

class ExtratoAcerto {
  const ExtratoAcerto({
    required this.linhas,
    required this.totalDevido,
    required this.totalConsolidado,
    required this.totalEmRevisao,
    required this.possuiValorIndefinido,
    this.periodoInicio,
    this.periodoFim,
  });

  final DateTime? periodoInicio;
  final DateTime? periodoFim;
  final List<LinhaExtrato> linhas;
  final num? totalDevido;
  final num? totalConsolidado;
  final num? totalEmRevisao;
  final bool possuiValorIndefinido;

  factory ExtratoAcerto.fromJson(Object? json) {
    final m = comoObjeto(json, 'extrato');
    return ExtratoAcerto(
      periodoInicio: lerDataHoraOpcional(m, 'periodoInicio'),
      periodoFim: lerDataHoraOpcional(m, 'periodoFim'),
      linhas: lerListaOuVazia(m, 'linhas').map(LinhaExtrato.fromJson).toList(),
      totalDevido: lerNumeroOpcional(m, 'totalDevido'),
      totalConsolidado: lerNumeroOpcional(m, 'totalConsolidado'),
      totalEmRevisao: lerNumeroOpcional(m, 'totalEmRevisao'),
      possuiValorIndefinido: lerBoolOuFalso(m, 'possuiValorIndefinido'),
    );
  }
}

class AcertoDoEntregador {
  const AcertoDoEntregador({
    required this.extrato,
    required this.contestacaoPermitida,
    this.statusCaixa,
    this.dataReferenciaCaixa,
  });

  final ExtratoAcerto extrato;

  /// `LocalDate` (`2026-11-15`), só para exibição.
  final String? dataReferenciaCaixa;

  /// `null` quando a loja ainda não abriu o caixa do dia.
  final StatusCaixa? statusCaixa;

  /// `true` só com o caixa ABERTO/REABERTO (decidido pelo backend).
  final bool contestacaoPermitida;

  factory AcertoDoEntregador.fromJson(Object? json) {
    final m = comoObjeto(json, 'acerto');
    return AcertoDoEntregador(
      extrato: ExtratoAcerto.fromJson(m['extrato']),
      dataReferenciaCaixa: lerStringOpcional(m, 'dataReferenciaCaixa'),
      statusCaixa: lerEnumOpcional(m, 'statusCaixa', StatusCaixa.values),
      contestacaoPermitida: lerBool(m, 'contestacaoPermitida'),
    );
  }

  bool get caixaFechado => statusCaixa == StatusCaixa.FECHADO;
}
