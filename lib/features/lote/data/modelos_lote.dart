/// Lote ativo do entregador, no contrato real da T009 do backend
/// (`LoteDoEntregadorResponse`, `EntregaDoEntregadorResponse`,
/// `ItemDoEntregadorResponse`; S001 em `agente_backend/sugestoes-mobile/`).
library;

import '../../../core/dominio/enums.dart';
import '../../../core/dominio/json_estrito.dart';
import '../../../core/dominio/modelos.dart';

class ItemEntrega {
  const ItemEntrega({
    required this.descricao,
    required this.quantidade,
    this.observacao,
  });

  final String descricao;
  final int quantidade;
  final String? observacao;

  factory ItemEntrega.fromJson(Object? json) {
    final m = comoObjeto(json, 'item');
    return ItemEntrega(
      descricao: lerString(m, 'descricao'),
      quantidade: lerInteiroOpcional(m, 'quantidade') ?? 1,
      observacao: lerStringOpcional(m, 'observacao'),
    );
  }
}

class Entrega {
  const Entrega({
    required this.id,
    required this.status,
    required this.nomeCliente,
    required this.enderecoCompleto,
    this.loteId,
    this.ordemRota,
    this.telefoneCliente,
    this.bairro,
    this.cep,
    this.complemento,
    this.pontoReferencia,
    this.coordenada,
    this.valorPedido,
    this.formaPagamento,
    this.pagoOnline = false,
    this.trocoPara,
    this.observacoes,
    this.motivoFalha,
    this.finalizadaEm,
    this.pendenteRevisao = false,
    this.motivoRevisao,
    this.distanciaKm,
    this.valorRepasse,
    this.itens = const [],
  });

  final String id;
  final String? loteId;
  final int? ordemRota;
  final StatusEntrega status;
  final String nomeCliente;
  final String? telefoneCliente;
  final String enderecoCompleto;
  final String? bairro;
  final String? cep;
  final String? complemento;
  final String? pontoReferencia;
  final Coordenada? coordenada;
  final num? valorPedido;
  final FormaPagamento? formaPagamento;
  final bool pagoOnline;
  final num? trocoPara;
  final String? observacoes;
  final String? motivoFalha;
  final DateTime? finalizadaEm;
  final bool pendenteRevisao;
  final MotivoRevisao? motivoRevisao;

  /// Distância de rota loja → cliente (pode vir `null`).
  final num? distanciaKm;

  /// Repasse provisório (ou congelado, se finalizada) calculado pelo backend.
  /// `null` aparece como "—" (Constituição 5.1).
  final num? valorRepasse;
  final List<ItemEntrega> itens;

  factory Entrega.fromJson(Object? json) {
    final m = comoObjeto(json, 'entrega');
    return Entrega(
      id: lerString(m, 'id'),
      loteId: lerStringOpcional(m, 'loteId'),
      ordemRota: lerInteiroOpcional(m, 'ordemRota'),
      status: lerEnum(m, 'status', StatusEntrega.values),
      nomeCliente: lerString(m, 'nomeCliente'),
      telefoneCliente: lerStringOpcional(m, 'telefoneCliente'),
      enderecoCompleto: lerString(m, 'enderecoCompleto'),
      bairro: lerStringOpcional(m, 'bairro'),
      cep: lerStringOpcional(m, 'cep'),
      complemento: lerStringOpcional(m, 'complemento'),
      pontoReferencia: lerStringOpcional(m, 'pontoReferencia'),
      coordenada: Coordenada.opcional(m, 'coordenada'),
      valorPedido: lerNumeroOpcional(m, 'valorPedido'),
      formaPagamento:
          lerEnumOpcional(m, 'formaPagamento', FormaPagamento.values),
      pagoOnline: lerBoolOuFalso(m, 'pagoOnline'),
      trocoPara: lerNumeroOpcional(m, 'trocoPara'),
      observacoes: lerStringOpcional(m, 'observacoes'),
      motivoFalha: lerStringOpcional(m, 'motivoFalha'),
      finalizadaEm: lerDataHoraOpcional(m, 'finalizadaEm'),
      pendenteRevisao: lerBoolOuFalso(m, 'pendenteRevisao'),
      motivoRevisao: lerEnumOpcional(m, 'motivoRevisao', MotivoRevisao.values),
      distanciaKm: lerNumeroOpcional(m, 'distanciaKm'),
      valorRepasse: lerNumeroOpcional(m, 'valorRepasse'),
      itens: lerListaOuVazia(m, 'itens').map(ItemEntrega.fromJson).toList(),
    );
  }
}

class LoteAtivo {
  const LoteAtivo({
    required this.id,
    required this.status,
    required this.qtdEntregas,
    required this.entregas,
    this.despachadoEm,
    this.concluidoEm,
    this.coordenadaEstabelecimento,
    this.nomeFantasiaEstabelecimento,
  });

  final String id;
  final StatusLote status;
  final int qtdEntregas;
  final DateTime? despachadoEm;
  final DateTime? concluidoEm;
  final Coordenada? coordenadaEstabelecimento;

  /// Nome da loja do lote, usado na mensagem do WhatsApp.
  final String? nomeFantasiaEstabelecimento;

  /// Na ordem de `ordemRota` escolhida pelo operador; o app nunca reordena
  /// por conta própria (Constituição 4.2).
  final List<Entrega> entregas;

  factory LoteAtivo.fromJson(Object? json) {
    final m = comoObjeto(json, 'lote');
    final entregas =
        lerListaOuVazia(m, 'entregas').map(Entrega.fromJson).toList();
    return LoteAtivo(
      id: lerString(m, 'id'),
      status: lerEnum(m, 'status', StatusLote.values),
      qtdEntregas: lerInteiroOpcional(m, 'qtdEntregas') ?? entregas.length,
      despachadoEm: lerDataHoraOpcional(m, 'despachadoEm'),
      concluidoEm: lerDataHoraOpcional(m, 'concluidoEm'),
      coordenadaEstabelecimento:
          Coordenada.opcional(m, 'coordenadaEstabelecimento'),
      nomeFantasiaEstabelecimento: lerStringOpcional(m, 'nomeFantasiaEstabelecimento'),
      entregas: ordenarPorOrdemRota(entregas),
    );
  }

  Entrega? entregaPorId(String id) {
    for (final e in entregas) {
      if (e.id == id) return e;
    }
    return null;
  }
}

/// Ordena por `ordemRota`; sem ordem, mantém a ordem recebida, no fim.
List<Entrega> ordenarPorOrdemRota(List<Entrega> entregas) {
  final indexadas = entregas.asMap().entries.toList();
  indexadas.sort((a, b) {
    final oa = a.value.ordemRota;
    final ob = b.value.ordemRota;
    if (oa != null && ob != null && oa != ob) return oa.compareTo(ob);
    if (oa != null && ob == null) return -1;
    if (oa == null && ob != null) return 1;
    return a.key.compareTo(b.key);
  });
  return [for (final e in indexadas) e.value];
}
