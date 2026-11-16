import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../core/deep_links/deep_links.dart';
import '../../../core/dominio/transicoes.dart';
import '../../../core/formatacao/distancia.dart';
import '../../../core/formatacao/moeda.dart';
import '../../../core/ui/estados.dart';
import '../../../core/ui/mensageiro.dart';
import '../../../core/ui/status_visual.dart';
import '../data/modelos_lote.dart';
import '../estado/lote_ativo_notifier.dart';
import 'acoes_lote.dart';

/// Detalhe da entrega (AGENT.md 8.3, HU04, HU05).
class EntregaPage extends ConsumerWidget {
  const EntregaPage({super.key, required this.entregaId});

  final String entregaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(loteAtivoProvider);
    final entrega = estado.lote?.entregaPorId(entregaId);

    final Widget corpo;
    if (entrega == null && estado.carregando) {
      corpo = const EstadoCarregando();
    } else if (entrega == null) {
      corpo = const EstadoVazio(mensagem: 'Esta entrega não está mais no seu lote.');
    } else {
      corpo = _Detalhe(
        entrega: entrega,
        enviando: estado.enviando,
        nomeLoja: estado.lote?.nomeFantasiaEstabelecimento,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(entrega?.nomeCliente ?? 'Entrega')),
      body: corpo,
    );
  }
}

class _Detalhe extends ConsumerWidget {
  const _Detalhe({required this.entrega, required this.enviando, this.nomeLoja});

  final Entrega entrega;
  final bool enviando;
  final String? nomeLoja;

  Future<void> _abrir(WidgetRef ref, Uri url) async {
    final abriu = await ref.read(abrirLinkProvider)(url);
    if (!abriu) mostrarMensagem(ref, mensagemFalhaAbrirApp);
  }

  Future<void> _navegar(BuildContext context, WidgetRef ref) async {
    final destino = await showModalBottomSheet<Uri>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('navegar-waze'),
              minTileHeight: alturaBotaoAcao,
              leading: const Icon(Icons.navigation),
              title: const Text('Waze'),
              onTap: () => Navigator.of(context).pop(urlWaze(
                  coordenada: entrega.coordenada, endereco: entrega.enderecoCompleto)),
            ),
            ListTile(
              key: const Key('navegar-maps'),
              minTileHeight: alturaBotaoAcao,
              leading: const Icon(Icons.map),
              title: const Text('Google Maps'),
              onTap: () => Navigator.of(context).pop(urlGoogleMaps(
                  coordenada: entrega.coordenada, endereco: entrega.enderecoCompleto)),
            ),
          ],
        ),
      ),
    );
    if (destino != null) await _abrir(ref, destino);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final whatsapp = urlWhatsApp(
        telefone: entrega.telefoneCliente,
        nomeCliente: entrega.nomeCliente,
        nomeLoja: nomeLoja);
    final podeFinalizar = podeFinalizarEntrega(entrega.status);
    final tema = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Row(children: [
          SeloStatusEntrega(status: entrega.status),
          const Spacer(),
          if (entrega.ordemRota != null) Text('Parada ${entrega.ordemRota}'),
        ]),
        const SizedBox(height: 16),
        _Secao(titulo: 'Endereço', linhas: [
          entrega.enderecoCompleto,
          if (entrega.complemento != null) 'Complemento: ${entrega.complemento}',
          if (entrega.pontoReferencia != null) 'Referência: ${entrega.pontoReferencia}',
          if (entrega.bairro != null) 'Bairro: ${entrega.bairro}',
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: SizedBox(
              height: alturaBotaoAcao,
              child: OutlinedButton.icon(
                key: const Key('botao-navegar'),
                onPressed: () => _navegar(context, ref),
                icon: const Icon(Icons.directions),
                label: const Text('Navegar'),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Tooltip(
              message: whatsapp == null ? 'Cliente sem telefone' : 'Abrir WhatsApp',
              child: SizedBox(
                height: alturaBotaoAcao,
                child: OutlinedButton.icon(
                  key: const Key('botao-whatsapp'),
                  onPressed: whatsapp == null ? null : () => unawaited(_abrir(ref, whatsapp)),
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                ),
              ),
            ),
          ),
        ]),
        if (whatsapp == null)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text('Cliente sem telefone cadastrado.'),
          ),
        const SizedBox(height: 16),
        _Secao(titulo: 'Pagamento', linhas: [
          'Valor do pedido: ${formatarMoeda(entrega.valorPedido)}',
          'Forma de pagamento: ${entrega.formaPagamento?.rotulo ?? '—'}',
          if (entrega.pagoOnline) 'Pago online',
          if (!entrega.pagoOnline && entrega.trocoPara != null)
            'Levar troco para ${formatarMoeda(entrega.trocoPara)}',
          'Distância: ${formatarKm(entrega.distanciaKm)}',
          'Seu repasse: ${formatarMoeda(entrega.valorRepasse)}',
        ]),
        const SizedBox(height: 16),
        Text('Itens', style: tema.textTheme.titleMedium),
        const SizedBox(height: 4),
        if (entrega.itens.isEmpty) const Text('Sem itens informados.'),
        for (final item in entrega.itens)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('${item.quantidade} × ${item.descricao}'),
            subtitle: item.observacao == null ? null : Text(item.observacao!),
          ),
        if (entrega.observacoes != null) ...[
          const SizedBox(height: 8),
          _Secao(titulo: 'Observações', linhas: [entrega.observacoes!]),
        ],
        if (entrega.motivoFalha != null) ...[
          const SizedBox(height: 8),
          _Secao(titulo: 'Motivo da falha', linhas: [entrega.motivoFalha!]),
        ],
        if (podeFinalizar) ...[
          const SizedBox(height: 24),
          SizedBox(
            height: alturaBotaoAcao,
            child: FilledButton.icon(
              key: const Key('botao-entregue'),
              onPressed: enviando
                  ? null
                  : () => confirmarEntregue(context, ref, entrega.id, entrega.nomeCliente),
              icon: const Icon(Icons.check_circle),
              label: const Text('Entregue'),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: alturaBotaoAcao,
            child: OutlinedButton.icon(
              key: const Key('botao-falha'),
              style: OutlinedButton.styleFrom(foregroundColor: tema.colorScheme.error),
              onPressed: enviando ? null : () => escolherFalha(context, ref, entrega.id),
              icon: const Icon(Icons.report),
              label: const Text('Falha'),
            ),
          ),
          if (enviando)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(child: Text('Enviando...')),
            ),
        ],
      ],
    );
  }
}

class _Secao extends StatelessWidget {
  const _Secao({required this.titulo, required this.linhas});

  final String titulo;
  final List<String> linhas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        for (final l in linhas) Text(l),
      ],
    );
  }
}
