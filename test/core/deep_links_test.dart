import 'package:agiliza_mobile/core/deep_links/deep_links.dart';
import 'package:agiliza_mobile/core/dominio/modelos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const coord = Coordenada(latitude: -23.5614, longitude: -46.6559);
  const endereco = 'Av. Paulista, 1000 - São Paulo';

  group('Google Maps', () {
    test('com coordenada', () {
      expect(urlGoogleMaps(coordenada: coord, endereco: endereco).toString(),
          'https://www.google.com/maps/dir/?api=1&destination=-23.5614,-46.6559');
    });

    test('sem coordenada usa o endereço url-encoded', () {
      final url = urlGoogleMaps(endereco: endereco);
      expect(url.toString(), startsWith('https://www.google.com/maps/dir/?api=1&destination='));
      expect(url.queryParameters['destination'], endereco);
    });
  });

  group('Waze', () {
    test('com coordenada', () {
      expect(urlWaze(coordenada: coord, endereco: endereco).toString(),
          'https://waze.com/ul?ll=-23.5614,-46.6559&navigate=yes');
    });

    test('sem coordenada usa q=<endereço>', () {
      final url = urlWaze(endereco: endereco);
      expect(url.queryParameters['q'], endereco);
    });
  });

  group('WhatsApp', () {
    test('telefone de 11 dígitos ganha o 55', () {
      expect(normalizarTelefone('(11) 98888-7777'), '5511988887777');
    });

    test('telefone de 10 dígitos ganha o 55', () {
      expect(normalizarTelefone('11 3333-4444'), '551133334444');
    });

    test('telefone que já tem 55 é mantido', () {
      expect(normalizarTelefone('+55 11 98888-7777'), '5511988887777');
      expect(normalizarTelefone('551133334444'), '551133334444');
    });

    test('sem telefone ou inválido: sem link (botão desabilitado)', () {
      expect(urlWhatsApp(telefone: null, nomeCliente: 'Maria'), isNull);
      expect(urlWhatsApp(telefone: '123', nomeCliente: 'Maria'), isNull);
    });

    test('mensagem padrão url-encoded, sem o trecho da loja se não houver nome', () {
      final url = urlWhatsApp(telefone: '11988887777', nomeCliente: 'Maria')!;
      expect(url.toString(), startsWith('https://wa.me/5511988887777?text='));
      expect(url.queryParameters['text'],
          'Olá, Maria! Sou o entregador. Estou a caminho com o seu pedido.');
      expect(mensagemWhatsApp(nomeCliente: 'Maria', nomeLoja: 'Pizzaria XYZ'),
          'Olá, Maria! Sou o entregador do Pizzaria XYZ. Estou a caminho com o seu pedido.');
    });
  });
}
