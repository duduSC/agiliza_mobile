/// Deep links de navegação e contato (HU04, AGENT.md 8.3). Sem mapa no app e
/// sem chave de API: os links abrem o Waze, o Google Maps e o WhatsApp.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../dominio/modelos.dart';

String _coordenadaTexto(Coordenada c) => '${c.latitude},${c.longitude}';

/// `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>`, ou o
/// endereço *url-encoded* quando não há coordenada.
Uri urlGoogleMaps({Coordenada? coordenada, required String endereco}) {
  final destino = coordenada != null
      ? _coordenadaTexto(coordenada)
      : Uri.encodeQueryComponent(endereco);
  return Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$destino');
}

/// `https://waze.com/ul?ll=<lat>,<lng>&navigate=yes`, ou `?q=<endereço>`.
Uri urlWaze({Coordenada? coordenada, required String endereco}) {
  if (coordenada != null) {
    return Uri.parse(
        'https://waze.com/ul?ll=${_coordenadaTexto(coordenada)}&navigate=yes');
  }
  return Uri.parse('https://waze.com/ul?q=${Uri.encodeQueryComponent(endereco)}');
}

/// Só dígitos, com o prefixo 55 quando falta (número nacional de 10 ou 11
/// dígitos). `null` se não sobrar um número utilizável.
String? normalizarTelefone(String? telefone) {
  if (telefone == null) return null;
  var digitos = telefone.replaceAll(RegExp(r'\D'), '');
  if (digitos.startsWith('0')) digitos = digitos.replaceFirst(RegExp(r'^0+'), '');
  if (digitos.length == 10 || digitos.length == 11) return '55$digitos';
  if (digitos.startsWith('55') && (digitos.length == 12 || digitos.length == 13)) {
    return digitos;
  }
  return null;
}

String mensagemWhatsApp({required String nomeCliente, String? nomeLoja}) {
  final loja = (nomeLoja == null || nomeLoja.trim().isEmpty)
      ? 'Sou o entregador.'
      : 'Sou o entregador do ${nomeLoja.trim()}.';
  return 'Olá, $nomeCliente! $loja Estou a caminho com o seu pedido.';
}

/// `https://wa.me/<55+DDD+número>?text=<mensagem>`. `null` sem telefone
/// válido (o botão fica desabilitado).
Uri? urlWhatsApp({
  required String? telefone,
  required String nomeCliente,
  String? nomeLoja,
}) {
  final numero = normalizarTelefone(telefone);
  if (numero == null) return null;
  final texto = Uri.encodeComponent(
      mensagemWhatsApp(nomeCliente: nomeCliente, nomeLoja: nomeLoja));
  return Uri.parse('https://wa.me/$numero?text=$texto');
}

const mensagemFalhaAbrirApp = 'Não foi possível abrir o aplicativo';

/// Abre a URL fora do app. Devolve `false` se não conseguiu.
typedef AbrirLink = Future<bool> Function(Uri url);

Future<bool> _abrirComUrlLauncher(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

final abrirLinkProvider = Provider<AbrirLink>((ref) => _abrirComUrlLauncher);
