import 'package:flutter/material.dart';

/// Tamanho mínimo de alvo de toque (RNF11, Constituição 5.7).
const double alvoMinimo = 48;

/// Altura dos botões de ação de status (folga sobre o mínimo, uso com uma mão).
const double alturaBotaoAcao = 56;

ThemeData criarTema() {
  final esquema = ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0));
  const tamanhoMinimo = Size(alvoMinimo, alvoMinimo);
  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    visualDensity: VisualDensity.standard,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: tamanhoMinimo),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(minimumSize: tamanhoMinimo),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: tamanhoMinimo),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(minimumSize: tamanhoMinimo),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: tamanhoMinimo),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
  );
}
