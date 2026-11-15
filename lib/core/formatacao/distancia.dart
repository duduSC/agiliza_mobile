import 'package:intl/intl.dart';

final NumberFormat _km = NumberFormat('#,##0.0#', 'pt_BR');

/// `4,7 km`. `null` vira "—".
String formatarKm(num? km) {
  if (km == null) return '—';
  return '${_km.format(km)} km';
}

/// Número de km sem unidade, para faixas (`0–3 km`).
String formatarNumeroKm(num? km) {
  if (km == null) return '—';
  return _km.format(km);
}
