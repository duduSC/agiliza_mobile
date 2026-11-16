import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../core/api/erros.dart';
import '../../../core/sessao/sessao.dart';
import '../estado/sessao_notifier.dart';

/// Login do entregador (UC07, HU13). Sem "esqueci minha senha" (Constituição 4.2).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _enviando = false;
  bool _ocultarSenha = true;
  String? _erro;

  @override
  void dispose() {
    _email.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    // Duplo toque bloqueado: o botão fica desabilitado durante o envio.
    if (_enviando) return;
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _enviando = true;
      _erro = null;
    });
    try {
      await ref.read(sessaoProvider.notifier).entrar(_email.text, _senha.text);
    } catch (e) {
      if (mounted) setState(() => _erro = mensagemDeErro(e, noLogin: true));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(sessaoProvider);
    final aviso = estado is SemSessao ? estado.aviso : null;
    final mensagem = _erro ?? aviso;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.delivery_dining,
                        size: 72, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      'Agiliza Entregador',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      key: const Key('login-email'),
                      controller: _email,
                      enabled: !_enviando,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe o e-mail' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      key: const Key('login-senha'),
                      controller: _senha,
                      enabled: !_enviando,
                      obscureText: _ocultarSenha,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _entrar(),
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        suffixIcon: IconButton(
                          tooltip: _ocultarSenha ? 'Mostrar senha' : 'Ocultar senha',
                          icon: Icon(
                              _ocultarSenha ? Icons.visibility : Icons.visibility_off),
                          onPressed: () =>
                              setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Informe a senha' : null,
                    ),
                    if (mensagem != null) ...[
                      const SizedBox(height: 16),
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          mensagem,
                          key: const Key('login-erro'),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      height: alturaBotaoAcao,
                      child: FilledButton(
                        key: const Key('login-entrar'),
                        onPressed: _enviando ? null : _entrar,
                        child: _enviando
                            ? const SizedBox.square(
                                dimension: 24,
                                child: CircularProgressIndicator(strokeWidth: 3),
                              )
                            : const Text('Entrar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
