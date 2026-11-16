import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/tema.dart';
import '../../../core/dominio/transicoes.dart';
import '../../../core/formatacao/moeda.dart';
import '../../../core/ui/estados.dart';
import '../../../core/ui/status_visual.dart';
import '../data/modelos_lote.dart';
import '../estado/lote_ativo_notifier.dart';
import 'acoes_lote.dart';

/// Lote ativo: lista de entregas (AGENT.md 8.3, UC02, HU05).
class LotePage extends ConsumerWidget {
  const LotePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(loteAtivoProvider);
    final lote = estado.lote;

    final Widget corpo;
    if (lote == null && estado.carregando) {
      corpo = const EstadoCarregando(mensagem: 'Carregando lote...');
    } else if (lote == null && estado.erro != null) {
      corpo = EstadoErro(
        mensagem: estado.erro!.mensagem(),
        aoTentarDeNovo: () => ref.read(loteAtivoProvider.notifier).recarregar(),
      );
    } else if (lote == null) {
      corpo = const EstadoVazio(
          mensagem: 'Nenhum lote no momento', icone: Icons.inventory_2_outlined);
    } else {
      corpo = RefreshIndicator(
        onRefresh: () => ref.read(loteAtivoProvider.notifier).recarregar(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _CabecalhoLote(lote: lote, enviando: estado.enviando),
            const SizedBox(height: 8),
            for (final entrega in lote.entregas) _ItemEntrega(entrega: entrega),
          ],
        ),
      );
    }
    return Scaffold(appBar: AppBar(title: const Text('Lote')), body: corpo);
  }
}

class _CabecalhoLote extends ConsumerWidget {
  const _CabecalhoLote({required this.lote, required this.enviando});

  final LoteAtivo lote;
  final bool enviando;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qtd = lote.qtdEntregas;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(qtd == 1 ? '1 entrega' : '$qtd entregas',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text('Situação do lote: ${lote.status.rotulo}'),
            if (podeIniciarPercurso(lote.status)) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: alturaBotaoAcao,
                child: FilledButton.icon(
                  key: const Key('botao-iniciar-percurso'),
                  onPressed: enviando ? null : () => confirmarIniciarPercurso(context, ref),
                  icon: const Icon(Icons.two_wheeler),
                  label: const Text('Iniciar percurso'),
                ),
              ),
              const SizedBox(height: 4),
              const Text('Toque ao sair da loja com os pedidos.'),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemEntrega extends StatelessWidget {
  const _ItemEntrega({required this.entrega});

  final Entrega entrega;

  @override
  Widget build(BuildContext context) {
    final linhas = <String>[
      if (entrega.bairro != null) entrega.bairro!,
      'Pedido: ${formatarMoeda(entrega.valorPedido)}'
          '${entrega.formaPagamento != null ? ' · ${entrega.formaPagamento!.rotulo}' : ''}',
      if (entrega.pagoOnline) 'Pago online',
      if (!entrega.pagoOnline && entrega.trocoPara != null)
        'Levar troco para ${formatarMoeda(entrega.trocoPara)}',
    ];
    return Card(
      child: InkWell(
        key: Key('entrega-${entrega.id}'),
        onTap: () => context.push('/lote/entrega/${Uri.encodeComponent(entrega.id)}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Text('${entrega.ordemRota ?? '-'}')),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entrega.nomeCliente,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    for (final l in linhas) Text(l),
                    const SizedBox(height: 8),
                    SeloStatusEntrega(status: entrega.status),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
