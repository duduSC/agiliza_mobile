import 'package:intl/intl.dart';

/// Formatação de dinheiro (Constituição 5.1). O app só formata: nunca soma nem
/// calcula valores. `null` aparece como "—", nunca como "R$ 0,00".
final NumberFormat _moeda = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: r'R$',
);

String formatarMoeda(num? valor) {
  if (valor == null) return '—';
  return _moeda.format(valor);
}
