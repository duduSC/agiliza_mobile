/// Estado da sessão do entregador.
library;

import '../dominio/enums.dart';
import '../dominio/json_estrito.dart';
import 'armazenamento_tokens.dart';

/// `UsuarioAutenticadoResponse`.
class UsuarioAutenticado {
  const UsuarioAutenticado({
    required this.usuarioId,
    required this.estabelecimentoId,
    required this.motoboyId,
    required this.nome,
    required this.perfil,
  });

  final String usuarioId;
  final String? estabelecimentoId;
  final String? motoboyId;
  final String nome;
  final PerfilUsuario perfil;

  factory UsuarioAutenticado.fromJson(Object? json) {
    final m = comoObjeto(json, 'usuario');
    return UsuarioAutenticado(
      usuarioId: lerString(m, 'usuarioId'),
      estabelecimentoId: lerStringOpcional(m, 'estabelecimentoId'),
      motoboyId: lerStringOpcional(m, 'motoboyId'),
      nome: lerString(m, 'nome'),
      perfil: lerEnum(m, 'perfil', PerfilUsuario.values),
    );
  }
}

/// Resposta do login e do refresh: `{ token, refreshToken, usuario }`.
class RespostaLogin {
  const RespostaLogin({required this.tokens, required this.usuario});

  final Tokens tokens;
  final UsuarioAutenticado usuario;

  factory RespostaLogin.fromJson(Object? json) {
    final m = comoObjeto(json, 'login');
    return RespostaLogin(
      tokens: Tokens(
        token: lerString(m, 'token'),
        refreshToken: lerString(m, 'refreshToken'),
      ),
      usuario: UsuarioAutenticado.fromJson(m['usuario']),
    );
  }
}

/// Sessão aberta. O `motoboyId` vem sempre do backend (login ou `/me`),
/// nunca de entrada do usuário (Constituição 5.8).
class Sessao {
  const Sessao({required this.motoboyId, required this.nome});

  final String motoboyId;
  final String nome;
}

sealed class EstadoSessao {
  const EstadoSessao();
}

/// Abrindo o app: verificando os tokens salvos.
class SessaoVerificando extends EstadoSessao {
  const SessaoVerificando();
}

class SemSessao extends EstadoSessao {
  const SemSessao({this.aviso});

  /// Mensagem para a tela de login (ex.: sessão expirada).
  final String? aviso;
}

class SessaoAtiva extends EstadoSessao {
  const SessaoAtiva(this.sessao);

  final Sessao sessao;
}
