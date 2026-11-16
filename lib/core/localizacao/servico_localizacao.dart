/// Permissão e posição atual (UC02 E1, Constituição 5.3).
/// Só primeiro plano: nada de localização em segundo plano neste ciclo (D008).
library;

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../dominio/modelos.dart';

enum SituacaoPermissao {
  concedida,

  /// Negada nesta vez: pode pedir de novo.
  negada,

  /// Negada para sempre: só pelas configurações do Android.
  negadaPermanentemente,

  /// GPS do aparelho desligado.
  servicoDesligado,
}

abstract interface class ServicoLocalizacao {
  /// Verifica e, se ainda não decidida, pede a permissão.
  Future<SituacaoPermissao> garantirPermissao();

  /// Só verifica, sem abrir diálogo.
  Future<SituacaoPermissao> verificarPermissao();

  /// Posição atual, ou `null` se indisponível (sem permissão, GPS desligado, timeout).
  Future<Coordenada?> posicaoAtual();

  Future<void> abrirConfiguracoesDoApp();

  Future<void> abrirConfiguracoesDeLocalizacao();
}

class ServicoLocalizacaoGeolocator implements ServicoLocalizacao {
  const ServicoLocalizacaoGeolocator();

  @override
  Future<SituacaoPermissao> verificarPermissao() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return SituacaoPermissao.servicoDesligado;
    }
    return _converter(await Geolocator.checkPermission());
  }

  @override
  Future<SituacaoPermissao> garantirPermissao() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return SituacaoPermissao.servicoDesligado;
    }
    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    return _converter(permissao);
  }

  SituacaoPermissao _converter(LocationPermission p) => switch (p) {
        LocationPermission.always ||
        LocationPermission.whileInUse =>
          SituacaoPermissao.concedida,
        LocationPermission.deniedForever =>
          SituacaoPermissao.negadaPermanentemente,
        _ => SituacaoPermissao.negada,
      };

  @override
  Future<Coordenada?> posicaoAtual() async {
    try {
      if (await verificarPermissao() != SituacaoPermissao.concedida) return null;
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return Coordenada(latitude: p.latitude, longitude: p.longitude);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> abrirConfiguracoesDoApp() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<void> abrirConfiguracoesDeLocalizacao() async {
    await Geolocator.openLocationSettings();
  }
}
