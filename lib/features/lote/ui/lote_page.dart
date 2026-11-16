import 'package:flutter/material.dart';

/// Placeholder da T002. A tela real do lote é a T003.
class LotePage extends StatelessWidget {
  const LotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lote')),
      body: const Center(child: Text('As entregas do lote aparecem aqui.')),
    );
  }
}
