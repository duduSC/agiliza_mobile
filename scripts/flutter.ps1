# Wrapper do Flutter via Docker (AGENT.md 4.1, D008).
# Uso (PowerShell):
#   .\scripts\flutter.ps1 analyze
#   .\scripts\flutter.ps1 test
#   .\scripts\flutter.ps1 build apk --debug --dart-define=API_URL=http://192.168.0.10:8080
# Para rodar o dart: $env:FLUTTER_BIN = 'dart'; .\scripts\flutter.ps1 format lib
$ErrorActionPreference = 'Stop'

$Imagem = 'ghcr.io/cirruslabs/flutter:3.44.0'
$Raiz = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$Bin = if ($env:FLUTTER_BIN) { $env:FLUTTER_BIN } else { 'flutter' }

$argumentos = @(
  'run', '--rm',
  '-v', "${Raiz}:/app", '-w', '/app',
  '-v', 'agiliza_pub_cache:/root/.pub-cache',
  '-v', 'agiliza_gradle:/root/.gradle',
  # O Gradle instala NDK, CMake e plataformas no SDK; o volume evita baixar de novo.
  '-v', 'agiliza_android_sdk:/opt/android-sdk-linux',
  $Imagem,
  $Bin
) + $args

& docker @argumentos
exit $LASTEXITCODE
