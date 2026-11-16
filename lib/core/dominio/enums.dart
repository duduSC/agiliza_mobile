/// Enums do contrato (AGENT.md 6.1). Os nomes Dart são idênticos aos do backend
/// (SCREAMING_CASE) para que a conversão seja exata e sem tabela intermediária.
/// Valor desconhecido é erro de contrato ([enumPorNome]).
library;

// Os nomes seguem exatamente o contrato do backend, por isso não usam lowerCamelCase.
// ignore_for_file: constant_identifier_names

import 'json_estrito.dart';

enum PerfilUsuario {
  ADMIN_GERAL('Administrador geral'),
  ADMIN_RESTAURANTE('Administrador do restaurante'),
  OPERADOR('Operador'),
  ENTREGADOR('Entregador');

  const PerfilUsuario(this.rotulo);
  final String rotulo;

  static PerfilUsuario fromJson(String valor) =>
      enumPorNome(valor, values, 'PerfilUsuario');
}

enum StatusEntrega {
  AGUARDANDO_DESPACHO('Aguardando despacho'),
  DESPACHADA('Despachada'),
  EM_ROTA('Em rota'),
  ENTREGUE('Entregue'),
  FALHA('Falha'),
  CANCELADA('Cancelada');

  const StatusEntrega(this.rotulo);
  final String rotulo;

  bool get finalizada => this == ENTREGUE || this == FALHA || this == CANCELADA;

  static StatusEntrega fromJson(String valor) =>
      enumPorNome(valor, values, 'StatusEntrega');
}

enum StatusLote {
  DESPACHADO('Despachado'),
  EM_ROTA('Em rota'),
  CONCLUIDO('Concluído'),
  CANCELADO('Cancelado');

  const StatusLote(this.rotulo);
  final String rotulo;

  static StatusLote fromJson(String valor) =>
      enumPorNome(valor, values, 'StatusLote');
}

enum StatusDisponibilidadeMotoboy {
  OFFLINE('Offline'),
  ONLINE('Online'),
  EM_ROTA('Em rota');

  const StatusDisponibilidadeMotoboy(this.rotulo);
  final String rotulo;

  /// Telemetria e polling só rodam nestes estados (RNF07, Constituição 5.6).
  bool get emTurno => this == ONLINE || this == EM_ROTA;

  static StatusDisponibilidadeMotoboy fromJson(String valor) =>
      enumPorNome(valor, values, 'StatusDisponibilidadeMotoboy');
}

enum StatusCadastroMotoboy {
  ATIVO('Ativo'),
  BLOQUEADO('Bloqueado');

  const StatusCadastroMotoboy(this.rotulo);
  final String rotulo;

  static StatusCadastroMotoboy fromJson(String valor) =>
      enumPorNome(valor, values, 'StatusCadastroMotoboy');
}

enum StatusCaixa {
  ABERTO('Aberto'),
  FECHADO('Fechado'),
  REABERTO('Reaberto');

  const StatusCaixa(this.rotulo);
  final String rotulo;

  /// Com o caixa ABERTO ou REABERTO os valores ainda aceitam correção (DVP 1.4.4).
  bool get aceitaCorrecao => this == ABERTO || this == REABERTO;

  static StatusCaixa fromJson(String valor) =>
      enumPorNome(valor, values, 'StatusCaixa');
}

enum MotivoRevisao {
  SEM_COORDENADA('Sem coordenada'),
  SEM_DISTANCIA('Sem distância'),
  CONTESTACAO_ENTREGADOR('Contestação do entregador');

  const MotivoRevisao(this.rotulo);
  final String rotulo;

  static MotivoRevisao fromJson(String valor) =>
      enumPorNome(valor, values, 'MotivoRevisao');
}

enum FormaPagamento {
  DINHEIRO('Dinheiro'),
  CREDITO('Cartão de crédito'),
  DEBITO('Cartão de débito'),
  PIX('Pix'),
  VALE('Vale-refeição');

  const FormaPagamento(this.rotulo);
  final String rotulo;

  static FormaPagamento fromJson(String valor) =>
      enumPorNome(valor, values, 'FormaPagamento');
}

enum SituacaoAcerto {
  A_ACERTAR('A acertar'),
  CONSOLIDADA('Consolidada em recibo'),
  EM_REVISAO('Em análise');

  const SituacaoAcerto(this.rotulo);
  final String rotulo;

  static SituacaoAcerto fromJson(String valor) =>
      enumPorNome(valor, values, 'SituacaoAcerto');
}
