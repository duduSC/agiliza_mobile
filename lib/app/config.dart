import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Configuração lida dos `--dart-define` (Constituição 6.6).
class ConfigApp {
  const ConfigApp({required this.apiUrl, required this.usarFake});

  /// `null` quando o build de release foi gerado sem `API_URL`.
  final Uri? apiUrl;

  /// `--dart-define=USAR_FAKE=true` usa os repositórios em memória (AGENT.md 3.3).
  final bool usarFake;

  /// Padrão só para debug: o host do PC visto pelo emulador Android.
  static const String apiUrlPadraoDebug = 'http://10.0.2.2:8080';

  static ConfigApp lerDartDefines() {
    const apiUrl = String.fromEnvironment('API_URL');
    const usarFake = bool.fromEnvironment('USAR_FAKE');
    return resolver(apiUrl: apiUrl, usarFake: usarFake, debug: kDebugMode);
  }

  /// Regra separada de [lerDartDefines] para poder ser testada.
  static ConfigApp resolver({
    required String apiUrl,
    required bool usarFake,
    required bool debug,
  }) {
    var texto = apiUrl.trim();
    if (texto.isEmpty && debug) texto = apiUrlPadraoDebug;
    final uri = texto.isEmpty ? null : Uri.tryParse(texto);
    final valida = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    return ConfigApp(apiUrl: valida ? uri : null, usarFake: usarFake);
  }
}

final configProvider = Provider<ConfigApp>(
  (ref) => throw UnimplementedError('configProvider deve ser sobrescrito no main'),
);
