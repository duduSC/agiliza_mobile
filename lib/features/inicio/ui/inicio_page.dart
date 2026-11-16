import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/tema.dart';
import '../../../core/dominio/enums.dart';
import '../../../core/localizacao/servico_localizacao.dart';
import '../../../core/providers_core.dart';
import '../../../core/ui/estados.dart';
import '../../../core/ui/mensageiro.dart';
import '../../../core/ui/status_visual.dart';
import '../../lote/lote.dart';
import '../estado/disponibilidade_notifier.dart';
import 'monitor_turno.dart';

/// Início (AGENT.md 8.2): disponibilidade, Online/Offline e o lote ativo.
class InicioPage extends ConsumerWidget {
  const InicioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(disponibilidadeProvider);
    ref.listen(disponibilidadeProvider.select((e) => e.erroAcao), (_, erro) {
      if (erro != null) mostrarMensagem(ref, erro.mensagem());
    });

    final Widget corpo;
    if (estado.carregando) {
      corpo = const EstadoCarregando();
    } else if (estado.motoboy == null) {
      corpo = EstadoErro(
        mensagem: estado.erroCarga?.mensagem() ?? 'Não foi possível carregar.',
        aoTentarDeNovo: () => ref.read(disponibilidadeProvider.notifier).carregar(),
      );
    } else {
      corpo = RefreshIndicator(
        onRefresh: () async {
          await ref.read(disponibilidadeProvider.notifier).carregar();
          await ref.read(loteAtivoProvider.notifier).recarregar();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _CartaoDisponibilidade(estado: estado),
            if (estado.permissaoNegada != null) ...[
              const SizedBox(height: 16),
              _AvisoPermissao(situacao: estado.permissaoNegada!),
            ],
            const SizedBox(height: 16),
            _CartaoLote(status: estado.status!),
          ],
        ),
      );
    }
    return corpo;
  }
}

class _CartaoDisponibilidade extends ConsumerWidget {
  const _CartaoDisponibilidade({required this.estado});

  final EstadoDisponibilidade estado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final motoboy = estado.motoboy!;
    final status = motoboy.statusDisponibilidade;
    final notifier = ref.read(disponibilidadeProvider.notifier);
    final emRota = status == StatusDisponibilidadeMotoboy.EM_ROTA;
    final offline = status == StatusDisponibilidadeMotoboy.OFFLINE;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Olá, ${motoboy.nome}', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Sua situação: '),
                SeloDisponibilidade(status: status),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: alturaBotaoAcao,
              child: offline
                  ? FilledButton.icon(
                      key: const Key('botao-ficar-online'),
                      onPressed: estado.enviando ? null : notifier.ficarOnline,
                      icon: const Icon(Icons.power_settings_new),
                      label: Text(estado.enviando ? 'Enviando...' : 'Ficar online'),
                    )
                  : OutlinedButton.icon(
                      key: const Key('botao-ficar-offline'),
                      onPressed: (estado.enviando || emRota) ? null : notifier.ficarOffline,
                      icon: const Icon(Icons.power_off),
                      label: Text(estado.enviando ? 'Enviando...' : 'Ficar offline'),
                    ),
            ),
            if (emRota) ...[
              const SizedBox(height: 8),
              const Text(
                'Você está em rota. Finalize as entregas do lote para poder ficar offline.',
                key: Key('aviso-offline-em-rota'),
              ),
            ],
            if (!offline) ...[
              const SizedBox(height: 8),
              Text(
                'Com o app aberto, sua localização é enviada à loja a cada 20 segundos.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AvisoPermissao extends ConsumerWidget {
  const _AvisoPermissao({required this.situacao});

  final SituacaoPermissao situacao;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizacao = ref.read(servicoLocalizacaoProvider);
    final (texto, rotulo, acao) = switch (situacao) {
      SituacaoPermissao.servicoDesligado => (
          'O GPS do aparelho está desligado. Ligue a localização para ficar online.',
          'Abrir configurações de localização',
          localizacao.abrirConfiguracoesDeLocalizacao,
        ),
      SituacaoPermissao.negadaPermanentemente => (
          'Para ficar online, a loja precisa acompanhar a sua localização durante o '
              'turno. Permita o acesso à localização nas configurações do aplicativo.',
          'Abrir configurações do app',
          localizacao.abrirConfiguracoesDoApp,
        ),
      _ => (
          'Para ficar online, a loja precisa acompanhar a sua localização durante o '
              'turno. Toque em "Ficar online" de novo e permita o acesso.',
          'Abrir configurações do app',
          localizacao.abrirConfiguracoesDoApp,
        ),
    };
    return Card(
      key: const Key('aviso-permissao'),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              const Icon(Icons.location_off),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Localização necessária',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ]),
            const SizedBox(height: 8),
            Text(texto),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => unawaited(acao()), child: Text(rotulo)),
          ],
        ),
      ),
    );
  }
}

class _CartaoLote extends ConsumerWidget {
  const _CartaoLote({required this.status});

  final StatusDisponibilidadeMotoboy status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (status == StatusDisponibilidadeMotoboy.OFFLINE) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.info_outline),
          title: Text('Fique online para receber lotes.'),
        ),
      );
    }
    final estado = ref.watch(loteAtivoProvider);
    final lote = estado.lote;
    if (lote == null) {
      if (estado.carregando) {
        return const Card(
          child: ListTile(
            leading: SizedBox.square(
                dimension: 24, child: CircularProgressIndicator(strokeWidth: 3)),
            title: Text('Procurando lote...'),
          ),
        );
      }
      return Card(
        child: ListTile(
          leading: const Icon(Icons.hourglass_empty),
          title: const Text('Aguardando lote'),
          subtitle: estado.erro != null
              ? Text(estado.erro!.mensagem())
              : const Text('Quando a loja despachar um lote para você, ele aparece aqui.'),
        ),
      );
    }
    final titulo = lote.status == StatusLote.DESPACHADO
        ? 'Novo lote: ${textoEntregas(lote.qtdEntregas)}'
        : 'Lote em rota: ${textoEntregas(lote.qtdEntregas)}';
    return Card(
      key: const Key('cartao-lote'),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: ListTile(
        minTileHeight: alturaBotaoAcao,
        leading: const Icon(Icons.inventory_2),
        title: Text(titulo),
        subtitle: Text('Situação do lote: ${lote.status.rotulo}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/lote'),
      ),
    );
  }
}
