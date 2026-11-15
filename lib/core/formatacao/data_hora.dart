/// Datas `LocalDateTime` do backend (sem fuso), interpretadas como horário de
/// `America/Sao_Paulo` (AGENT.md 6.6).
///
/// Representação no app: um [DateTime] com a flag UTC cujos componentes
/// (ano, mês, dia, hora...) são exatamente o "relógio de parede" de São Paulo.
/// Assim o fuso configurado no aparelho nunca altera o valor exibido ou enviado.
/// São Paulo não tem horário de verão desde 2019: o deslocamento é fixo em UTC-3.
library;

const Duration deslocamentoSaoPaulo = Duration(hours: -3);

final RegExp _formatoLocalDateTime = RegExp(
  r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d{1,9})?)?$',
);

/// Lê `"2026-11-15T21:30:00"` (segundos e frações opcionais). Rejeita textos
/// com `Z` ou offset, que não fazem parte do contrato.
DateTime lerLocalDateTime(String texto) {
  if (!_formatoLocalDateTime.hasMatch(texto)) {
    throw FormatException('LocalDateTime inválido', texto);
  }
  // Frações com mais de 6 dígitos (nanossegundos do Java) são truncadas.
  var normalizado = texto;
  final ponto = texto.indexOf('.');
  if (ponto >= 0 && texto.length - ponto - 1 > 6) {
    normalizado = texto.substring(0, ponto + 7);
  }
  final d = DateTime.parse(normalizado);
  return DateTime.utc(
    d.year,
    d.month,
    d.day,
    d.hour,
    d.minute,
    d.second,
    d.millisecond,
    d.microsecond,
  );
}

/// Escreve no formato do contrato, sem fuso e sem frações: `"2026-11-15T21:30:00"`.
String escreverLocalDateTime(DateTime relogioSaoPaulo) {
  String dois(int v) => v.toString().padLeft(2, '0');
  final d = relogioSaoPaulo;
  return '${d.year.toString().padLeft(4, '0')}-${dois(d.month)}-${dois(d.day)}'
      'T${dois(d.hour)}:${dois(d.minute)}:${dois(d.second)}';
}

/// Converte um instante qualquer para o relógio de parede de São Paulo.
DateTime paraSaoPaulo(DateTime instante) {
  final sp = instante.toUtc().add(deslocamentoSaoPaulo);
  return DateTime.utc(
    sp.year,
    sp.month,
    sp.day,
    sp.hour,
    sp.minute,
    sp.second,
  );
}

/// Horário atual em São Paulo (usado em `ocorridoEm`, Constituição 5.4).
DateTime agoraSaoPaulo([DateTime Function()? relogio]) =>
    paraSaoPaulo((relogio ?? DateTime.now)());

String _dois(int v) => v.toString().padLeft(2, '0');

/// `15/11/2026 21:30`. `null` vira "—".
String formatarDataHora(DateTime? data) {
  if (data == null) return '—';
  return '${_dois(data.day)}/${_dois(data.month)}/${data.year} '
      '${_dois(data.hour)}:${_dois(data.minute)}';
}

/// `21:30`. `null` vira "—".
String formatarHora(DateTime? data) {
  if (data == null) return '—';
  return '${_dois(data.hour)}:${_dois(data.minute)}';
}
