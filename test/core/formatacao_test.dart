import 'package:agiliza_mobile/core/formatacao/data_hora.dart';
import 'package:agiliza_mobile/core/formatacao/distancia.dart';
import 'package:agiliza_mobile/core/formatacao/moeda.dart';
import 'package:flutter_test/flutter_test.dart';

/// NumberFormat pt_BR usa espaço não separável entre "R$" e o valor.
String semNbsp(String s) => s.replaceAll(' ', ' ');

void main() {
  group('formatarMoeda', () {
    test('formata em pt-BR', () {
      expect(semNbsp(formatarMoeda(12.5)), r'R$ 12,50');
      expect(semNbsp(formatarMoeda(1234.56)), r'R$ 1.234,56');
      expect(semNbsp(formatarMoeda(0)), r'R$ 0,00');
    });

    test('null vira "—", nunca R\$ 0,00', () {
      expect(formatarMoeda(null), '—');
    });
  });

  group('formatarKm', () {
    test('formata com vírgula', () {
      expect(formatarKm(4.7), '4,7 km');
      expect(formatarKm(3), '3,0 km');
      expect(formatarKm(2.25), '2,25 km');
    });

    test('null vira "—"', () => expect(formatarKm(null), '—'));
  });

  group('LocalDateTime sem fuso', () {
    test('ida e volta preserva o relógio de parede', () {
      const texto = '2026-11-15T21:30:00';
      final data = lerLocalDateTime(texto);
      expect(data.year, 2026);
      expect(data.month, 11);
      expect(data.day, 15);
      expect(data.hour, 21);
      expect(data.minute, 30);
      expect(escreverLocalDateTime(data), texto);
    });

    test('aceita frações (inclusive nanossegundos do Java) e sem segundos', () {
      expect(
        escreverLocalDateTime(lerLocalDateTime('2026-11-15T21:30:05.123456789')),
        '2026-11-15T21:30:05',
      );
      expect(
        escreverLocalDateTime(lerLocalDateTime('2026-11-15T21:30')),
        '2026-11-15T21:30:00',
      );
    });

    test('rejeita texto com fuso', () {
      expect(() => lerLocalDateTime('2026-11-15T21:30:00Z'), throwsFormatException);
      expect(
        () => lerLocalDateTime('2026-11-15T21:30:00-03:00'),
        throwsFormatException,
      );
      expect(() => lerLocalDateTime('ontem'), throwsFormatException);
    });

    test('agoraSaoPaulo converte o instante para UTC-3, sem fuso no texto', () {
      final instante = DateTime.utc(2026, 11, 16, 0, 30, 15);
      final sp = agoraSaoPaulo(() => instante);
      expect(escreverLocalDateTime(sp), '2026-11-15T21:30:15');
    });

    test('formatarDataHora e null', () {
      expect(formatarDataHora(lerLocalDateTime('2026-01-05T08:07:00')), '05/01/2026 08:07');
      expect(formatarDataHora(null), '—');
      expect(formatarHora(null), '—');
    });
  });
}
