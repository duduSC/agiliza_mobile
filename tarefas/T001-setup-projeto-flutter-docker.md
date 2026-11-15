# T001 — Setup do projeto Flutter via Docker

**Status:** PENDENTE
**Depende de:** —
**Referências no DVP:** 1.5.1, 1.5.2 (Flutter 3.x), 1.2.5 (só Android), RNF10 (API 26+), 2.2 (Entrega 1/5)

## Objetivo
Ter o projeto Flutter criado em `agiliza_mobile/`, rodando `analyze` e `test` via Docker, com a base de `core/` pronta para as telas e o git inicializado.

## Escopo
- [ ] Conferir se o Docker responde (`docker info`). Se não responder, pedir ao Eduardo para abrir o Docker Desktop (AGENT.md 3.3.1).
- [ ] **Git primeiro**, antes de qualquer scaffold: `git init` em `agiliza_mobile/`, commit inicial em `main` com a governança que já existe (`CLAUDE.md`, `agent/`, `docs/`, `tarefas/`, `relatorios/`, `sugestoes-backend/`), depois `git checkout -b develop` e, a partir dela, `feature/T001-setup-projeto-flutter-docker`.
- [ ] Criar `scripts/flutter.sh` (Git Bash) e `scripts/flutter.ps1` (PowerShell), wrappers do `docker run` descritos no AGENT.md 4.1.
  - Rodar uma vez com a tag `stable` de `ghcr.io/cirruslabs/flutter`, registrar `flutter --version` no relatório e **fixar a tag** exata nos dois scripts.
  - Confirmar onde fica o `PUB_CACHE` dentro da imagem e ajustar o volume se preciso.
- [ ] Gerar o projeto **numa pasta temporária** (`flutter create --org br.com.agilizadelivery --project-name agiliza_mobile --platforms android ...`) e mover para a raiz só o que é do Flutter (`lib/`, `test/`, `android/`, `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `.metadata`), sem tocar na governança (Constituição 3.5).
- [ ] `android/app/build.gradle(.kts)`: `minSdk = 26`, `applicationId br.com.agilizadelivery.entregador`, nome do app "Agiliza Entregador".
- [ ] Manifest:
  - permissões `INTERNET`, `ACCESS_FINE_LOCATION` e `ACCESS_COARSE_LOCATION`;
  - bloco `<queries>` para as intents `VIEW` `https` e `tel`;
  - `usesCleartextTraffic` (ou `network_security_config`) **só no source set `debug`** (AGENT.md 4.2).
- [ ] Dependências da pilha (AGENT.md 4): `flutter_riverpod`, `go_router`, `http`, `flutter_secure_storage`, `geolocator`, `url_launcher`, `intl`; e, em dev, `mocktail`. `analysis_options.yaml` com `flutter_lints`.
- [ ] Estrutura de `lib/` da seção 5, com o essencial de `core/`:
  - `core/api/api_client.dart`: base URL de `--dart-define=API_URL` (padrão `http://10.0.2.2:8080` só em debug), header Bearer, parse de `ApiErrorResponse` para `ErroApi`, tratamento de `SocketException`/timeout. O refresh em 401 fica como gancho, implementado na T002.
  - `core/api/endpoints.dart`: todos os caminhos da seção 6.4, marcados `// PROVISÓRIO`, exceto os de `/api/auth`.
  - `core/api/erros.dart`: o mapa de códigos da seção 6.5.
  - `core/dominio/`: enums da seção 6.1 com `fromJson` estrito, labels pt-BR e as transições permitidas ao entregador (seção 6.2).
  - `core/formatacao/`: moeda pt-BR (`null` → "—"), km, e data/hora `LocalDateTime` sem fuso ↔ `DateTime` de São Paulo.
  - `main.dart` lendo os `dart-define`s `API_URL` e `USAR_FAKE`, e um `App` com tema Material 3 (alvos ≥ 48 dp) e uma tela placeholder "Agiliza Entregador".
- [ ] Testes unitários de `core/`: formatação de moeda (incluindo `null`), datas sem fuso (ida e volta), parse de `ApiErrorResponse`, enum desconhecido rejeitado e transições permitidas.
- [ ] `scripts/flutter.sh analyze` limpo, `scripts/flutter.sh test` verde e um `scripts/flutter.sh build apk --debug` bem-sucedido. O primeiro build é lento: rode em background.
- [ ] Um `README.md` curto: como rodar via Docker, como gerar o APK apontando para o IP do PC e como instalar no aparelho.

## Fora do escopo
- Telas de login, início, lote ou acerto (T002 a T004).
- iOS, web e desktop: não gerar essas plataformas.
- CI, assinatura de release e ícone definitivo.

## Regras de negócio envolvidas
- Constituição 3.4 (git), 3.5 (scaffold), 5.1 (dinheiro), 6.6 (URL por dart-define, cleartext só em debug), 7.1, 7.2, 8.

## Critérios de aceite
- `git log` mostra o commit inicial em `main`, `develop` existe e o merge da T001 está em `develop`.
- `scripts/flutter.sh analyze`: "No issues found".
- `scripts/flutter.sh test`: todos passando.
- `build/app/outputs/flutter-apk/app-debug.apk` gerado.
- Nenhum arquivo de governança foi apagado ou sobrescrito.

## Backend / fakes
Nenhuma chamada real ainda. `endpoints.dart` nasce com os caminhos PROVISÓRIOS da seção 6.4.

## Ao terminar
Escreva `../relatorios/T001-setup-projeto-flutter-docker.md`, faça o merge para `develop` e **siga para a T002** sem esperar aval (D006).
