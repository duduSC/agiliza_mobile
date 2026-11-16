# Agiliza Entregador (app Android do entregador)

App Flutter do entregador do Agiliza Delivery. Só Android 8.0+ (API 26).
O Flutter **não** precisa estar instalado: tudo roda num container Docker
(`ghcr.io/cirruslabs/flutter:3.44.0`, Flutter 3.44.0 / Dart 3.12.0).

## Pré-requisitos

- Docker Desktop aberto (`docker info` precisa responder).
- Git Bash (para `scripts/flutter.sh`) ou PowerShell (para `scripts/flutter.ps1`).

Os volumes `agiliza_pub_cache` e `agiliza_gradle` guardam o cache do pub e do
Gradle entre execuções. O primeiro build demora bastante (baixa o Gradle e as
dependências do Android); os seguintes são bem mais rápidos.

## Comandos

```bash
scripts/flutter.sh pub get
scripts/flutter.sh analyze
scripts/flutter.sh test
```

No PowerShell, troque `scripts/flutter.sh` por `.\scripts\flutter.ps1`.

## Gerar o APK apontando para o backend no seu PC

1. Descubra o IP do PC na rede Wi-Fi: `ipconfig` (campo "Endereço IPv4", por exemplo `192.168.0.10`).
2. Suba o backend (porta 8080). O Spring já escuta em `0.0.0.0`. Para a demonstração,
   `./mvnw spring-boot:run` em `ADS_EduardoCamargo_AgilizaDelivery/agilizadelivery/`, sem
   variáveis, sobe no perfil `h2` (banco em memória, recriado a cada reinício) com a carga
   de demonstração:
   - entregadores: `entregador1@agiliza.dev` e `entregador2@agiliza.dev`, senha `agiliza123`
     (o app sempre envia `canal: "APP"`);
   - operador: `operador@agiliza.dev`, mesma senha (despacha os lotes pelo Backoffice ou pela
     coleção Postman em `agilizadelivery/postman/`).

   Essas credenciais são **só de desenvolvimento**.
3. Libere a porta 8080 no Firewall do Windows (regra de entrada TCP 8080, rede privada).
4. Gere o APK de debug:

   ```bash
   scripts/flutter.sh build apk --debug --dart-define=API_URL=http://192.168.0.10:8080
   ```

   Para testar sem backend, com dados em memória:

   ```bash
   scripts/flutter.sh build apk --debug --dart-define=USAR_FAKE=true
   ```

   No modo fake, entre com `entregador@agiliza.com` / `123456`
   (`operador@agiliza.com` / `123456` demonstra a recusa de perfil). Para o
   cenário de caixa fechado no acerto, some `--dart-define=FAKE_CAIXA_FECHADO=true`.

5. O APK sai em `build/app/outputs/flutter-apk/app-debug.apk`.

> O HTTP sem TLS só é liberado no build de **debug** (`android/app/src/debug/AndroidManifest.xml`).
> O build de release exige `API_URL` com HTTPS e não tem endereço fixo no código.

## Instalar no aparelho

- **Por cabo (adb):** ative "Opções do desenvolvedor" e "Depuração USB" no celular e rode
  `adb install -r build/app/outputs/flutter-apk/app-debug.apk` (o `adb` vem do Android SDK
  Platform-Tools; não precisa do Flutter instalado).
- **Sem cabo:** copie o `app-debug.apk` para o celular (Drive, WhatsApp, cabo USB como
  armazenamento), abra o arquivo e permita "instalar apps desconhecidos" para o app usado.

O celular e o PC precisam estar na mesma rede Wi-Fi.

## Governança

Este repositório é operado pelo Agente Mobile: veja `CLAUDE.md`, `agent/CONSTITUTION.md`
e `agent/AGENT.md`. Tarefas em `tarefas/`, relatórios em `relatorios/`.
