/// Erros normalizados da API (AGENT.md 6.5, Constituição 7.3).
library;

import '../dominio/json_estrito.dart';

/// Códigos de `CodigoErro` do backend que o app trata de forma própria.
/// Ficam como texto (e não enum) para que um código novo do backend nunca
/// derrube o parse do erro: ele cai em "outros" e mostra a `message`.
abstract final class CodigosErro {
  static const credenciaisInvalidas = 'CREDENCIAIS_INVALIDAS';
  static const acessoNegado = 'ACESSO_NEGADO';
  static const estabelecimentoInativo = 'ESTABELECIMENTO_INATIVO';
  static const usuarioBloqueado = 'USUARIO_BLOQUEADO';
  static const naoAutenticado = 'NAO_AUTENTICADO';
  static const motoboyIndisponivel = 'MOTOBOY_INDISPONIVEL';
  static const transicaoEstadoInvalida = 'TRANSICAO_ESTADO_INVALIDA';
  static const caixaFechado = 'CAIXA_FECHADO';
  static const regraNegocioViolada = 'REGRA_NEGOCIO_VIOLADA';

  /// Códigos internos do app (não vêm do backend).
  static const semConexao = 'APP_SEM_CONEXAO';
  static const contratoInvalido = 'APP_CONTRATO_INVALIDO';
  static const desconhecido = 'APP_ERRO_DESCONHECIDO';
}

abstract final class MensagensErro {
  static const credenciaisInvalidas = 'E-mail ou senha inválidos';
  static const exclusivoEntregadores =
      'Este aplicativo é exclusivo para entregadores';
  static const estabelecimentoInativo = 'O acesso desta loja está suspenso';
  static const usuarioBloqueado = 'Seu acesso está bloqueado. Procure a loja.';
  static const transicaoInvalida = 'Esta ação não é mais possível. Atualizando...';
  static const caixaFechado = 'O caixa já foi fechado. Procure o operador.';
  static const semConexao = 'Sem conexão. Tente de novo.';
  static const sessaoExpirada = 'Sua sessão expirou. Entre novamente.';
  static const contratoInvalido =
      'Resposta inesperada do servidor. Tente de novo mais tarde.';
  static const desconhecido = 'Não foi possível concluir. Tente de novo.';
}

class CampoErro {
  const CampoErro({required this.campo, required this.mensagem});

  final String campo;
  final String mensagem;
}

/// Erro normalizado. Toda falha de chamada à API chega à tela como [ErroApi].
class ErroApi implements Exception {
  const ErroApi({
    required this.codigo,
    required this.mensagemServidor,
    this.status,
    this.campos = const [],
  });

  const ErroApi.semConexao()
      : codigo = CodigosErro.semConexao,
        mensagemServidor = MensagensErro.semConexao,
        status = null,
        campos = const [];

  const ErroApi.contrato()
      : codigo = CodigosErro.contratoInvalido,
        mensagemServidor = MensagensErro.contratoInvalido,
        status = null,
        campos = const [];

  /// Status HTTP, quando houve resposta.
  final int? status;

  /// `ApiErrorResponse.codigo` (ou um código interno `APP_*`).
  final String codigo;

  /// `ApiErrorResponse.message`, já pensada pelo backend para exibição.
  final String mensagemServidor;

  final List<CampoErro> campos;

  bool get semConexao => codigo == CodigosErro.semConexao;

  /// Converte o corpo de um `ApiErrorResponse`. Um corpo ilegível não derruba
  /// nada: vira um erro genérico com o status HTTP.
  factory ErroApi.daResposta(int status, Object? corpo) {
    try {
      final json = comoObjeto(corpo);
      final campos = lerListaOuVazia(json, 'campos').map((c) {
        final m = comoObjeto(c, 'campos');
        return CampoErro(
          campo: lerStringOpcional(m, 'campo') ?? '',
          mensagem: lerStringOpcional(m, 'mensagem') ?? '',
        );
      }).toList();
      return ErroApi(
        status: lerInteiroOpcional(json, 'status') ?? status,
        codigo: lerStringOpcional(json, 'codigo') ?? CodigosErro.desconhecido,
        mensagemServidor:
            lerStringOpcional(json, 'message') ?? MensagensErro.desconhecido,
        campos: campos,
      );
    } on ErroContrato {
      return ErroApi(
        status: status,
        codigo: CodigosErro.desconhecido,
        mensagemServidor: MensagensErro.desconhecido,
      );
    }
  }

  /// Mensagem pt-BR para a tela (tabela do AGENT.md 6.5).
  /// [noLogin] diferencia o `ACESSO_NEGADO` do login, que significa perfil
  /// incompatível com o aplicativo (UC07 E4).
  String mensagem({bool noLogin = false}) {
    switch (codigo) {
      case CodigosErro.credenciaisInvalidas:
        return MensagensErro.credenciaisInvalidas;
      case CodigosErro.acessoNegado:
        return noLogin ? MensagensErro.exclusivoEntregadores : mensagemServidor;
      case CodigosErro.estabelecimentoInativo:
        return MensagensErro.estabelecimentoInativo;
      case CodigosErro.usuarioBloqueado:
        return MensagensErro.usuarioBloqueado;
      case CodigosErro.naoAutenticado:
        return noLogin
            ? MensagensErro.credenciaisInvalidas
            : MensagensErro.sessaoExpirada;
      case CodigosErro.transicaoEstadoInvalida:
        return MensagensErro.transicaoInvalida;
      case CodigosErro.caixaFechado:
        return MensagensErro.caixaFechado;
      case CodigosErro.semConexao:
        return MensagensErro.semConexao;
      case CodigosErro.contratoInvalido:
        return MensagensErro.contratoInvalido;
      default:
        // MOTOBOY_INDISPONIVEL, REGRA_NEGOCIO_VIOLADA e os demais: message do servidor.
        return mensagemServidor;
    }
  }

  /// Nunca inclui dados pessoais: só status e código (Constituição 6.4).
  @override
  String toString() => 'ErroApi($status, $codigo)';
}

/// Mensagem para qualquer erro capturado numa tela.
String mensagemDeErro(Object erro, {bool noLogin = false}) {
  if (erro is ErroApi) return erro.mensagem(noLogin: noLogin);
  return MensagensErro.desconhecido;
}
