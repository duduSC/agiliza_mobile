import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../core/api/erros.dart';
import '../../../core/dominio/enums.dart';
import '../../../core/dominio/transicoes.dart';
import '../../../core/formatacao/data_hora.dart';
import '../../../core/formatacao/distancia.dart';
import '../../../core/formatacao/moeda.dart';
import '../../../core/ui/estados.dart';
import '../../../core/ui/mensageiro.dart';
import '../../../core/ui/status_visual.dart';
import '../data/modelos_acerto.dart';
import '../estado/acerto_notifier.dart';

const tituloValorParcial = 'Valor parcial do turno';
const tituloValorFinal = 'Valor final';
const orientacaoProcureOperador = 'Para corrigir algum valor, procure o operador';
const avisoValorIndefinido = 'Há entregas com valor ainda não definido';
const textoEmAnalise = 'Esta entrega já está em análise';

/// Acerto do turno (AGENT.md 8.4, UC08, HU14). Todos os valores e totais vêm
/// do backend: esta tela só formata (Constituição 5.1).
class AcertoPage extends ConsumerWidget {
  const AcertoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(acertoProvider);
    final acerto = estado.acerto;
    if (acerto == null && estado.carregando) {
      return const EstadoCarregando(mensagem: 'Carregando acerto...');
    }
    if (acerto == null) {
      return EstadoErro(
        mensagem: estado.erro?.mensagem() ?? MensagensErro.desconhecido,
        aoTentarDeNovo: () => ref.read(acertoProvider.notifier).recarregar(),
      );
    }
    final extrato = acerto.extrato;
    return RefreshIndicator(
      onRefresh: () => ref.read(acertoProvider.notifier).recarregar(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _Totais(acerto: acerto),
          if (extrato.possuiValorIndefinido) ...[
            const SizedBox(height: 8),
            const Card(
              key: Key('aviso-valor-indefinido'),
              child: ListTile(
                leading: Icon(Icons.warning_amber),
                title: Text(avisoValorIndefinido),
              ),
            ),
          ],
          if (!acerto.contestacaoPermitida) ...[
            const SizedBox(height: 8),
            Card(
              key: const Key('orientacao-operador'),
              child: ListTile(
                leading: const Icon(Icons.support_agent),
                title: const Text(orientacaoProcureOperador),
                subtitle: acerto.statusCaixa == null
                    ? const Text('O caixa do dia ainda não foi aberto pela loja.')
                    : null,
              ),
            ),
          ],
          if (estado.erro != null) ...[
            const SizedBox(height: 8),
            Text(estado.erro!.mensagem(),
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          Text('Entregas do turno', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (extrato.linhas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EstadoVazio(
                mensagem: 'Nenhuma entrega finalizada neste turno.',
                icone: Icons.receipt_long,
              ),
            ),
          for (final linha in extrato.linhas)
            _Linha(
              linha: linha,
              acerto: acerto,
              contestando: estado.contestando == linha.entregaId,
              bloqueado: estado.contestando != null,
            ),
        ],
      ),
    );
  }
}

class _Totais extends StatelessWidget {
  const _Totais({required this.acerto});

  final AcertoDoEntregador acerto;

  @override
  Widget build(BuildContext context) {
    final extrato = acerto.extrato;
    final tema = Theme.of(context);
    final titulo = acerto.caixaFechado ? tituloValorFinal : tituloValorParcial;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, key: const Key('titulo-acerto'), style: tema.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(formatarMoeda(extrato.totalDevido),
                key: const Key('total-devido'), style: tema.textTheme.headlineMedium),
            const Text('Total devido'),
            const Divider(height: 24),
            _ValorRotulado(
              rotulo: 'Consolidado em recibo',
              valor: formatarMoeda(extrato.totalConsolidado),
              chave: const Key('total-consolidado'),
            ),
            _ValorRotulado(
              rotulo: 'Em análise',
              valor: formatarMoeda(extrato.totalEmRevisao),
              chave: const Key('total-em-revisao'),
            ),
            if (acerto.statusCaixa != null)
              _ValorRotulado(rotulo: 'Caixa do dia', valor: acerto.statusCaixa!.rotulo),
          ],
        ),
      ),
    );
  }
}

class _ValorRotulado extends StatelessWidget {
  const _ValorRotulado({required this.rotulo, required this.valor, this.chave});

  final String rotulo;
  final String valor;
  final Key? chave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Expanded(child: Text(rotulo)),
        Text(valor, key: chave, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

String textoFaixa(LinhaExtrato l) {
  if (l.foraDeArea) return 'Fora da área';
  if (l.faixaDeKm == null || l.faixaAteKm == null) return '—';
  return '${formatarNumeroKm(l.faixaDeKm)}–${formatarNumeroKm(l.faixaAteKm)} km';
}

class _Linha extends ConsumerWidget {
  const _Linha({
    required this.linha,
    required this.acerto,
    required this.contestando,
    required this.bloqueado,
  });

  final LinhaExtrato linha;
  final AcertoDoEntregador acerto;
  final bool contestando;
  final bool bloqueado;

  Future<void> _contestar(BuildContext context, WidgetRef ref) async {
    // Toque 1: "Contestar"; toque 2: "Confirmar contestação" (RNF11).
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contestar o valor?'),
        content: Text(
            'A entrega de ${linha.nomeCliente} vai para análise do operador e sai do '
            'total devido até ser revisada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            key: const Key('confirmar-contestar'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar contestação'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final erro = await ref.read(acertoProvider.notifier).contestar(linha.entregaId);
    mostrarMensagem(ref, erro?.mensagem() ?? 'Contestação registrada');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mostrarContestar = podeContestar(
      situacao: linha.situacao,
      statusCaixa: acerto.statusCaixa,
      contestacaoPermitida: acerto.contestacaoPermitida,
    );
    return Card(
      key: Key('linha-${linha.entregaId}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(linha.nomeCliente,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Text(formatarMoeda(linha.valorRepasse),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 4),
            Text('${formatarDataHora(linha.finalizadaEm)} · ${linha.status.rotulo}'),
            Text('Distância: ${formatarKm(linha.distanciaKm)} · Faixa: ${textoFaixa(linha)}'),
            const SizedBox(height: 8),
            Row(children: [
              _SeloSituacao(situacao: linha.situacao),
              const Spacer(),
              if (mostrarContestar)
                SizedBox(
                  height: alvoMinimo,
                  child: OutlinedButton(
                    key: Key('contestar-${linha.entregaId}'),
                    onPressed: bloqueado ? null : () => _contestar(context, ref),
                    child: Text(contestando ? 'Enviando...' : 'Contestar'),
                  ),
                ),
            ]),
            if (linha.situacao == SituacaoAcerto.EM_REVISAO)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(textoEmAnalise),
              ),
          ],
        ),
      ),
    );
  }
}

class _SeloSituacao extends StatelessWidget {
  const _SeloSituacao({required this.situacao});

  final SituacaoAcerto situacao;

  @override
  Widget build(BuildContext context) {
    final (icone, cor) = switch (situacao) {
      SituacaoAcerto.A_ACERTAR => (Icons.schedule, Colors.orange.shade800),
      SituacaoAcerto.CONSOLIDADA => (Icons.receipt_long, Colors.green.shade700),
      SituacaoAcerto.EM_REVISAO => (Icons.manage_search, Colors.purple.shade700),
    };
    return Selo(texto: situacao.rotulo, icone: icone, cor: cor);
  }
}
