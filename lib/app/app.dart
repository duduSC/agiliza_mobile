import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tema.dart';

class AgilizaApp extends ConsumerWidget {
  const AgilizaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Agiliza Entregador',
      debugShowCheckedModeBanner: false,
      theme: criarTema(),
      home: const _Placeholder(),
    );
  }
}

/// Tela provisória da T001. As telas reais chegam na T002.
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agiliza Entregador')),
      body: const Center(child: Text('Agiliza Entregador')),
    );
  }
}
