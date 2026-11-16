/// Modelos compartilhados por mais de uma feature, com `fromJson` estrito
/// (Constituição 7.2). Campos que o app não usa são ignorados.
library;

import 'enums.dart';
import 'json_estrito.dart';

/// `CoordenadaDto { latitude, longitude }`.
class Coordenada {
  const Coordenada({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  factory Coordenada.fromJson(Object? json) {
    final m = comoObjeto(json, 'coordenada');
    return Coordenada(
      latitude: lerNumero(m, 'latitude').toDouble(),
      longitude: lerNumero(m, 'longitude').toDouble(),
    );
  }

  static Coordenada? opcional(Json json, String campo) {
    final valor = json[campo];
    if (valor == null) return null;
    final m = comoObjeto(valor, campo);
    // Coordenada parcial (um dos dois nulos) é tratada como ausente.
    if (m['latitude'] == null || m['longitude'] == null) return null;
    return Coordenada.fromJson(m);
  }

  Map<String, Object> toJson() => {'latitude': latitude, 'longitude': longitude};

  /// Nunca expõe a posição em log (Constituição 6.4).
  @override
  String toString() => 'Coordenada(***)';
}

/// `MotoboyResponse` (o CPF nunca vem). Só o que o app usa.
class Motoboy {
  const Motoboy({
    required this.id,
    required this.nome,
    required this.statusCadastro,
    required this.statusDisponibilidade,
  });

  final String id;
  final String nome;
  final StatusCadastroMotoboy statusCadastro;
  final StatusDisponibilidadeMotoboy statusDisponibilidade;

  factory Motoboy.fromJson(Object? json) {
    final m = comoObjeto(json, 'motoboy');
    return Motoboy(
      id: lerString(m, 'id'),
      nome: lerString(m, 'nome'),
      statusCadastro: lerEnum(m, 'statusCadastro', StatusCadastroMotoboy.values),
      statusDisponibilidade: lerEnum(
        m,
        'statusDisponibilidade',
        StatusDisponibilidadeMotoboy.values,
      ),
    );
  }

  Motoboy copiarCom({StatusDisponibilidadeMotoboy? statusDisponibilidade}) =>
      Motoboy(
        id: id,
        nome: nome,
        statusCadastro: statusCadastro,
        statusDisponibilidade:
            statusDisponibilidade ?? this.statusDisponibilidade,
      );
}
