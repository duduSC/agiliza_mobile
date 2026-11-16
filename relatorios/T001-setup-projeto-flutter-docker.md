# Relatório — T001 Setup do projeto Flutter via Docker

**Status final:** CONCLUIDA (retomada depois que o Eduardo reiniciou o Docker Desktop; antes estava BLOQUEADA)
**Data:** 2026-11-15

## O que foi feito
- `docker info` respondeu no início (Docker 29.8.0).
- **Git primeiro:** `git init` em `agiliza_mobile/`, commit inicial em `main` só com a governança (`9c199b1`), `develop` criada a partir dele e `feature/T001-setup-projeto-flutter-docker` a partir de `develop`.
- Imagem: `ghcr.io/cirruslabs/flutter:stable` baixada, versão anotada e **tag fixada em `3.44.0`** (mesmo digest `sha256:46691e31...`):
  `Flutter 3.44.0 • Framework 559ffa3f75 (2026-05-15) • Engine fcf463a224 • Dart 3.12.0 • DevTools 2.57.0`.
  Android SDK da imagem: platform 36, build-tools 36.0.0.
- `PUB_CACHE` não é definido na imagem; o `HOME` é `/root`, então o cache fica no padrão `/root/.pub-cache`. O volume `agiliza_pub_cache` está montado ali; `agiliza_gradle` em `/root/.gradle`.
- `scripts/flutter.sh` (Git Bash, com `MSYS_NO_PATHCONV=1` e `pwd -W`) e `scripts/flutter.ps1` (PowerShell), os dois com a tag fixa. `FLUTTER_BIN=dart` permite rodar o `dart`.
- Projeto gerado com `flutter create --org br.com.agilizadelivery --project-name agiliza_mobile --platforms android` numa pasta temporária (`_scaffold_tmp/`, apagada depois). Para a raiz foram só `android/`, `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `.metadata`. Nenhum arquivo de governança foi tocado (Constituição 3.5). Sem iOS, web nem desktop.
- `android/app/build.gradle.kts`: `applicationId = "br.com.agilizadelivery.entregador"`, `minSdk = 26`. Nome do app "Agiliza Entregador" (`android:label`).
- Manifest principal: `INTERNET`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` (nada de localização em segundo plano, D008) e `<queries>` com `VIEW` `https` e `tel` (mais o `PROCESS_TEXT` do engine). `usesCleartextTraffic="true"` **só** em `android/app/src/debug/AndroidManifest.xml`.
- Dependências via `flutter pub add` (versões resolvidas): `flutter_riverpod ^3.5.0`, `go_router ^18.1.4`, `http ^1.6.0`, `flutter_secure_storage ^11.2.0`, `geolocator ^14.1.2`, `url_launcher ^6.3.3`, `intl ^0.20.2`; dev: `mocktail ^1.0.5`, `flutter_lints ^6.0.0`. `cupertino_icons` removido (só Android).
- `analysis_options.yaml` com `flutter_lints`, `strict-casts`, `strict-raw-types`, `avoid_print`, `unawaited_futures` e outras.
- `core/`:
  - `api/api_client.dart`: base URL por `API_URL`, Bearer, `ApiErrorResponse` → `ErroApi`, `SocketException`/timeout/`ClientException` → "Sem conexão. Tente de novo.", `204` como resposta sem conteúdo, `converter()` que transforma qualquer falha de `fromJson` em erro de contrato, e o gancho `renovarSessao` para o 401 (implementado na T002).
  - `api/endpoints.dart`: os caminhos da seção 6.4, com `// PROVISÓRIO` nos de `/api/entregador`.
  - `api/erros.dart`: o mapa da seção 6.5 (`ACESSO_NEGADO` no login vira "Este aplicativo é exclusivo para entregadores"). O `codigo` é lido como texto, para que um código novo do backend caia em "outros" e mostre a `message`, em vez de quebrar.
  - `dominio/`: enums da 6.1 com `fromJson` estrito, rótulos pt-BR, `json_estrito.dart` (leitura de campos obrigatórios/opcionais e enums) e `transicoes.dart` (6.2).
  - `formatacao/`: moeda pt-BR (`null` → "—"), km, e `LocalDateTime` sem fuso ↔ relógio de São Paulo (UTC-3 fixo, sem horário de verão desde 2019).
- `app/config.dart` (`API_URL`, `USAR_FAKE`; padrão `http://10.0.2.2:8080` **só** em debug; release sem `API_URL` não tem endereço fixo), `app/tema.dart` (Material 3, alvos ≥ 48 dp), `app/app.dart` com a tela "Agiliza Entregador", `main.dart`.
- Testes de `core/`: moeda (inclusive `null`), km, datas sem fuso (ida e volta, frações, rejeição de fuso), `ApiErrorResponse`, mensagens da 6.5, sem rede, `204`, contrato inválido, Bearer, enums desconhecidos rejeitados e transições permitidas.
- `README.md`: Docker, gerar o APK com o IP do PC, firewall da porta 8080 e instalação no aparelho.
- **Correção depois da queda do Docker:** `android/gradle.properties` vinha do template com `-Xmx8G`. A máquina tem 7,7 GB de RAM e a VM do WSL2 do Docker Desktop fica com cerca de metade disso. O Gradle passou a usar `-Xmx2G`, sem daemon, com 2 workers e Kotlin em processo. É a causa mais provável da queda (ver Dúvidas).

## Histórico do bloqueio (resolvido)
- **Primeira tentativa do `build apk --debug` (bloqueio, já resolvido):** O primeiro build rodou em background. Por volta das 18h57 a VM do Docker Desktop parou de responder: o log `com.docker.backend.exe.log` mostra `connect tcp 192.168.65.7:2376: no route to host` em sequência, e todo comando `docker` devolve `500 Internal Server Error`. Mais de 40 minutos depois continuava assim. Pelo `AGENT.md` (4.1 e 3.3.1), o agente não reinicia nem reinstala o Docker: **é preciso que o Eduardo reinicie o Docker Desktop.** A tarefa ficou BLOQUEADA até o Eduardo reiniciar o Docker Desktop.
- **Retomada:** os três comandos rodaram de novo sobre o commit `f4f1cb2` da T001, num *worktree* separado (`_wt_t001/`, fora do git), para não misturar com o código da T002 que já estava no diretório de trabalho. Os três passaram (tabela abaixo). O build levou cerca de 33 min porque o Gradle instalou NDK 28.2, CMake 3.22.1 e a plataforma 35 dentro do container.
- **Depois do build:** os dois wrappers passaram a montar também `agiliza_android_sdk:/opt/android-sdk-linux`, para que o NDK, o CMake e as plataformas instalados pelo Gradle não sejam baixados de novo a cada build. O volume foi conferido (`flutter --version` e `ls` do SDK pelo volume), mas o APK desta tarefa foi gerado **antes** dessa mudança. O próximo build (T004) a exercita.

## O que NÃO foi feito (e por quê)
- Nada do escopo ficou de fora.

## Arquivos criados/alterados
- `scripts/flutter.sh`, `scripts/flutter.ps1`, `.gitattributes` (LF nos scripts; CRLF só em `.ps1`/`.bat`), `.gitignore` (+ `build/`, `*.jks`, `*.keystore`, `key.properties`), `README.md`
- `pubspec.yaml`, `pubspec.lock`, `analysis_options.yaml`, `.metadata`
- `android/` (gerado), com `app/build.gradle.kts`, `app/src/main/AndroidManifest.xml`, `app/src/debug/AndroidManifest.xml` e `gradle.properties` alterados
- `lib/main.dart`, `lib/app/{app,config,tema}.dart`
- `lib/core/api/{api_client,endpoints,erros}.dart`, `lib/core/dominio/{enums,json_estrito,transicoes}.dart`, `lib/core/formatacao/{moeda,distancia,data_hora}.dart`
- `test/core/{formatacao,dominio,api_client}_test.dart`
- Commits na branch `feature/T001-setup-projeto-flutter-docker`: `4660b77`, `0a503a8` (governança: `.claude/skills/` e a seção 9 do `AGENT.md`, que o Orquestrador alterou durante a sessão) `7e9d7f1`, `f4f1cb2` e o ajuste do volume do SDK.

## Verificação
| Comando | Resultado |
| --- | --- |
| `scripts/flutter.sh analyze` | ✅ "No issues found! (ran in 25.2s)" (commit `f4f1cb2`) |
| `scripts/flutter.sh test` | ✅ 26 testes, 26 passaram ("All tests passed!") |
| `scripts/flutter.sh build apk --debug` | ✅ "Built build/app/outputs/flutter-apk/app-debug.apk" (Gradle 1959,8 s; 167 MB), com 3 avisos de API obsoleta do `geolocator_android` |

## Verificação manual pendente (aparelho físico)
- Instalar o APK de debug no aparelho (Android 8.0+). Nesta tarefa só há a tela "Agiliza Entregador"; o APK final da apresentação sai na T004.

## Desvios conscientes do DVP tocados (D008)
- O manifest não tem `ACCESS_BACKGROUND_LOCATION` nem *foreground service*: GPS em segundo plano está fora deste ciclo.

## Decisões tomadas (dentro do escopo)
- Os enums usam os nomes exatos do backend (`EM_ROTA` etc.). Para isso, `enums.dart` tem `// ignore_for_file: constant_identifier_names`, **com justificativa no próprio arquivo** (Constituição 7.1): assim a conversão é exata e não precisa de tabela intermediária.
- O código de erro (`ApiErrorResponse.codigo`) é lido como texto, não como enum: um código novo do backend nunca derruba o parse do erro.
- Datas: um `DateTime` com a flag UTC guarda o relógio de parede de São Paulo, para que o fuso do aparelho não altere o que é exibido ou enviado.
- Gradle com memória limitada (ver acima).

## Sugestões/pendências registradas para o backend
- Nenhuma nesta tarefa.

## Proposta de mudança no DVP (Constituição, Artigo 2.4)
- Nenhuma.

## Dúvidas / bloqueios
- O bloqueio do Docker foi resolvido. Se a VM voltar a cair com pouca memória, a opção é criar `%UserProfile%.wslconfig` com `[wsl2]` e `memory=4GB`; essa decisão é do Eduardo.

## Sugestões (não implementadas)
- Nenhuma.
