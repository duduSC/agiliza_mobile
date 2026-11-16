import 'package:flutter/material.dart';

import '../dominio/enums.dart';

/// Selo de status com ícone + texto + cor: a cor nunca é o único indicador
/// (Constituição 7.6).
class Selo extends StatelessWidget {
  const Selo({super.key, required this.texto, required this.icone, required this.cor});

  final String texto;
  final IconData icone;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: texto,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: cor.withValues(alpha: 0.12),
          border: Border.all(color: cor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 16, color: cor),
            const SizedBox(width: 4),
            Text(texto, style: TextStyle(color: cor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class SeloDisponibilidade extends StatelessWidget {
  const SeloDisponibilidade({super.key, required this.status});

  final StatusDisponibilidadeMotoboy status;

  @override
  Widget build(BuildContext context) {
    final (icone, cor) = switch (status) {
      StatusDisponibilidadeMotoboy.OFFLINE => (Icons.cloud_off, Colors.grey.shade700),
      StatusDisponibilidadeMotoboy.ONLINE => (Icons.check_circle, Colors.green.shade700),
      StatusDisponibilidadeMotoboy.EM_ROTA => (Icons.two_wheeler, Colors.blue.shade700),
    };
    return Selo(texto: status.rotulo, icone: icone, cor: cor);
  }
}

class SeloStatusEntrega extends StatelessWidget {
  const SeloStatusEntrega({super.key, required this.status});

  final StatusEntrega status;

  @override
  Widget build(BuildContext context) {
    final (icone, cor) = switch (status) {
      StatusEntrega.AGUARDANDO_DESPACHO => (Icons.schedule, Colors.grey.shade700),
      StatusEntrega.DESPACHADA => (Icons.inventory_2, Colors.orange.shade800),
      StatusEntrega.EM_ROTA => (Icons.two_wheeler, Colors.blue.shade700),
      StatusEntrega.ENTREGUE => (Icons.check_circle, Colors.green.shade700),
      StatusEntrega.FALHA => (Icons.report, Colors.red.shade700),
      StatusEntrega.CANCELADA => (Icons.block, Colors.grey.shade800),
    };
    return Selo(texto: status.rotulo, icone: icone, cor: cor);
  }
}
