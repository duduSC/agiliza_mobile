#!/usr/bin/env bash
# Wrapper do Flutter via Docker (AGENT.md 4.1, D008).
# Uso (Git Bash, a partir da raiz agiliza_mobile/ ou de qualquer lugar):
#   scripts/flutter.sh analyze
#   scripts/flutter.sh test
#   scripts/flutter.sh build apk --debug --dart-define=API_URL=http://192.168.0.10:8080
# Para rodar o dart: FLUTTER_BIN=dart scripts/flutter.sh format lib
set -euo pipefail

IMAGEM="ghcr.io/cirruslabs/flutter:3.44.0"
RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"
# No Git Bash, pwd -W devolve o caminho no formato do Windows (C:/...), que o Docker Desktop entende.
HOST_DIR="$(pwd -W 2>/dev/null || pwd)"
BIN="${FLUTTER_BIN:-flutter}"

TTY_ARGS=()
if [ -t 0 ] && [ -t 1 ]; then TTY_ARGS=(-it); fi

# MSYS_NO_PATHCONV evita que /app vire C:/Program Files/Git/app.
# agiliza_android_sdk guarda o NDK, o CMake e as plataformas que o Gradle instala no SDK.
MSYS_NO_PATHCONV=1 exec docker run --rm "${TTY_ARGS[@]}" \
  -v "$HOST_DIR":/app -w /app \
  -v agiliza_pub_cache:/root/.pub-cache \
  -v agiliza_gradle:/root/.gradle \
  -v agiliza_android_sdk:/opt/android-sdk-linux \
  "$IMAGEM" \
  "$BIN" "$@"
