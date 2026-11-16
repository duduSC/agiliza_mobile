import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = ConfigApp.lerDartDefines();
  runApp(
    ProviderScope(
      overrides: [configProvider.overrideWithValue(config)],
      child: const AgilizaApp(),
    ),
  );
}
