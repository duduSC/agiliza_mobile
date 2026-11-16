/// Confirmações das ações de status, com no máximo dois toques (RNF11).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/tema.dart';
import '../../../core/ui/mensageiro.dart';
import '../estado/lote_ativo_notifier.dart';

const motivosRapidosFalha = [
  'Cliente ausente',
  'Endereço não encontrado',
  'Cliente recusou',
];

Future<bool> _confirmar(
  BuildContext context, {
  required String titulo,
  required String texto,
  required String confirmar,
  required Key chaveConfirmar,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Voltar'),
        ),
        FilledButton(
          key: chaveConfirmar,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmar),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Toque 1: "Iniciar percurso"; toque 2: "Confirmar saída".
Future<void> confirmarIniciarPercurso(BuildContext context, WidgetRef ref) async {
  final ok = await _confirmar(
    context,
    titulo: 'Iniciar percurso?',
    texto: 'Confirme que você saiu da loja com todos os pedidos do lote.',
    confirmar: 'Confirmar saída',
    chaveConfirmar: const Key('confirmar-iniciar'),
  );
  if (!ok) return;
  final resultado = await ref.read(loteAtivoProvider.notifier).iniciarPercurso();
  if (!context.mounted) return;
  tratarResultado(context, ref, resultado, sucesso: 'Percurso iniciado');
}

/// Toque 1: "Entregue"; toque 2: "Confirmar entrega".
Future<void> confirmarEntregue(
    BuildContext context, WidgetRef ref, String entregaId, String cliente) async {
  final ok = await _confirmar(
    context,
    titulo: 'Confirmar entrega?',
    texto: 'O pedido de $cliente foi entregue?',
    confirmar: 'Confirmar entrega',
    chaveConfirmar: const Key('confirmar-entregue'),
  );
  if (!ok) return;
  final resultado = await ref.read(loteAtivoProvider.notifier).marcarEntregue(entregaId);
  if (!context.mounted) return;
  tratarResultado(context, ref, resultado, sucesso: 'Entrega registrada', voltarAoLote: true);
}

/// Toque 1: "Falha"; toque 2: um dos motivos rápidos (envia). Com motivo
/// digitado, o envio é pelo botão "Confirmar falha". Sem motivo, nada é enviado.
Future<void> escolherFalha(BuildContext context, WidgetRef ref, String entregaId) async {
  final motivo = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _FolhaMotivoFalha(),
  );
  if (motivo == null || motivo.trim().isEmpty) return;
  final resultado =
      await ref.read(loteAtivoProvider.notifier).marcarFalha(entregaId, motivo);
  if (!context.mounted) return;
  tratarResultado(context, ref, resultado, sucesso: 'Falha registrada', voltarAoLote: true);
}

void tratarResultado(
  BuildContext context,
  WidgetRef ref,
  ResultadoAcao resultado, {
  required String sucesso,
  bool voltarAoLote = false,
}) {
  final erro = resultado.erro;
  if (erro != null) {
    mostrarMensagem(ref, erro.mensagem());
    return;
  }
  if (resultado.loteConcluido) {
    mostrarMensagem(ref, 'Lote concluído');
    context.go('/inicio');
    return;
  }
  mostrarMensagem(ref, sucesso);
  if (voltarAoLote && context.canPop()) context.pop();
}

class _FolhaMotivoFalha extends StatefulWidget {
  const _FolhaMotivoFalha();

  @override
  State<_FolhaMotivoFalha> createState() => _FolhaMotivoFalhaState();
}

class _FolhaMotivoFalhaState extends State<_FolhaMotivoFalha> {
  final _texto = TextEditingController();

  @override
  void initState() {
    super.initState();
    _texto.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final digitado = _texto.text.trim();
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Motivo da falha', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          const Text('Toque no motivo para registrar a falha.'),
          const SizedBox(height: 12),
          for (final m in motivosRapidosFalha) ...[
            SizedBox(
              height: alturaBotaoAcao,
              child: OutlinedButton(
                key: Key('motivo-$m'),
                onPressed: () => Navigator.of(context).pop(m),
                child: Text(m),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          TextField(
            key: const Key('motivo-texto'),
            controller: _texto,
            maxLength: limiteMotivoFalha,
            decoration: const InputDecoration(labelText: 'Outro motivo'),
          ),
          SizedBox(
            height: alturaBotaoAcao,
            child: FilledButton(
              key: const Key('confirmar-falha'),
              onPressed: digitado.isEmpty ? null : () => Navigator.of(context).pop(digitado),
              child: const Text('Confirmar falha'),
            ),
          ),
        ],
      ),
    );
  }
}
