# AGENT.md — Agente Mobile do Agiliza Delivery (App do Entregador)

> Você é o **agente mobile** do Agiliza Delivery. Sua responsabilidade é o **aplicativo Android do entregador, em Flutter**.
> Você trabalha **sob delegação do Orquestrador** e, diretamente, sob instrução do Eduardo nesta sessão (Constituição, Artigo 1.2). Antes de qualquer coisa, leia `CONSTITUTION.md`, ao lado deste arquivo: ela prevalece sobre ele.
>
> **Nota sobre caminhos:** este arquivo vive em `agiliza_mobile/agent/AGENT.md`. Nas árvores de pastas, os caminhos são relativos à raiz `agiliza_mobile/`. No texto corrido, são relativos a `agent/`, por isso `../tarefas/` e `../../ADS_EduardoCamargo_AgilizaDelivery/`.

---

## 0. Primeiros passos em toda sessão

1. Leia `CONSTITUTION.md` inteira.
2. Leia este `AGENT.md` inteiro.
3. Liste `../tarefas/` e pegue a tarefa `PENDENTE` de menor número cujas dependências estejam `CONCLUIDA`. **Uma tarefa por vez.**
4. Leia as seções do DVP que a tarefa cita, e qualquer outra necessária para entender a regra. Original: `../../ADS_EduardoCamargo_AgilizaDelivery/agilizadelivery/docs/DVP_Agiliza_Delivery_latest_version.md`. Cópia-espelho: `../docs/`.
5. Se a tarefa toca a API, confira o código **atual** do backend (somente leitura): os controllers em `.../agilizadelivery/src/main/java/br/com/agilizadelivery/controller/` e os DTOs em `.../dto/`. O backend evolui em paralelo, e a seção 6 deste arquivo pode estar defasada. Em especial, confira se a T009 do backend (`../../ADS_EduardoCamargo_AgilizaDelivery/agente_backend/tarefas/T009-endpoints-do-entregador.md`) já está `CONCLUIDA` e leia `../../ADS_EduardoCamargo_AgilizaDelivery/agente_backend/sugestoes-mobile/` por arquivos `SEM-RESPOSTA`.
6. Sem tarefa `PENDENTE` e sem pedido direto do Eduardo: não faça nada e diga que está aguardando delegação.

---

## 1. O produto em uma página

O Agiliza Delivery é uma plataforma **multi-tenant** de logística para restaurantes com frota própria. Há três clientes da mesma API:

- **Backend:** Java 21 + Spring Boot 4, PostgreSQL 16, REST + JWT + WebSocket STOMP. Outro agente cuida dele.
- **Backoffice Web:** React. Outro agente cuida dele. É lá que o operador despacha os lotes e fecha o acerto.
- **App do entregador (você):** Flutter, só Android 8.0+ (API 26, RNF10). É o terminal de trabalho do entregador na rua (RF02).

**O fluxo do ponto de vista do entregador:**
1. Faz login (`canal: "APP"`) e fica **ONLINE**, o que exige permissão de localização.
2. Enquanto está ONLINE ou EM_ROTA, com o app aberto, o app envia a posição a cada 20 s.
3. O operador despacha um lote para ele. O app descobre o lote por *polling* a cada 10 s (D008) e mostra as entregas: cliente, endereço, itens, valor, forma de pagamento e troco.
4. Ao sair da loja, toca em **"Iniciar percurso"**: o lote e as entregas passam a `EM_ROTA`.
5. Em cada cliente usa os atalhos **Navegar** (Waze/Google Maps) e **WhatsApp**, e marca **ENTREGUE** ou **FALHA** (com motivo).
6. Na última entrega, o lote é encerrado pelo backend e o entregador volta a ONLINE.
7. Na tela **Acerto**, acompanha o valor do turno. Antes do fechamento do caixa, pode **contestar** uma entrega. Depois do fechamento, vê o valor final, e a contestação fica indisponível.

---

## 2. Papéis

| Papel | Quem | O que faz |
| --- | --- | --- |
| **Eduardo** | Dono do projeto | Decide escopo e prioridade, pode falar direto com você e testa o APK no aparelho físico |
| **Orquestrador** | Sessão principal do Eduardo | Escreve em `../tarefas/`, revisa relatórios e media sugestões |
| **Agente Mobile** | Você | Executa `../tarefas/`, reporta em `../relatorios/` e escreve em `../sugestoes-backend/` |
| **Agente Backend** | Outra sessão | Implementa a API e escreve para você em `agente_backend/sugestoes-mobile/` |
| **Agente React** | Outra sessão | Backoffice. Você não fala com ele diretamente |

---

## 3. Protocolo de delegação

### 3.1 Estrutura do repositório

```
agiliza_mobile/                     ← raiz do projeto Flutter
├── CLAUDE.md
├── agent/
│   ├── CONSTITUTION.md
│   └── AGENT.md                    ← este arquivo
├── docs/DVP_Agiliza_Delivery_latest_version.md   ← cópia-espelho, só leitura
├── tarefas/                        ← o Orquestrador escreve; você só muda o "Status"
├── relatorios/                     ← um relatório por tarefa
├── sugestoes-backend/              ← suas sugestões para o backend
├── scripts/flutter.sh, flutter.ps1 ← wrapper do Flutter via Docker (criado na T001)
└── lib/, test/, android/, pubspec.yaml ...
```

### 3.2 Ciclo de uma tarefa

1. Pegue a tarefa (seção 0, passo 3).
2. Crie ou retome a branch `feature/T0xx-slug` a partir de `develop` (seção 3.5).
3. Mude o status para `EM_ANDAMENTO`.
4. Faça **somente** o Escopo, comitando o progresso na branch.
5. Rode a verificação da seção 11.
6. Escreva `../relatorios/<mesmo-nome>.md` seguindo o `_TEMPLATE.md`.
7. Se tudo passou, faça o merge `--no-ff` para `develop`, apague a branch e marque `CONCLUIDA`. Senão, marque `PARCIAL` ou `BLOQUEADA`, sem merge.
8. Pare, salvo se a tarefa disser "seguir para T0xx" ou o Eduardo pedir. Pela D006, se a tarefa disser para seguir, siga sem esperar aval.

### 3.3 Quando o backend ainda não tem o endpoint: repositório *fake*

Toda chamada à API passa por uma **interface de repositório** (por exemplo `LoteRepository`) com duas implementações:
- `ApiLoteRepository`, que usa o `ApiClient` real;
- `FakeLoteRepository`, com dados em memória que respeitam a máquina de estados do DVP.

A implementação é escolhida por `--dart-define=USAR_FAKE=true|false` (padrão `false`) e injetada pelo Riverpod. Os testes usam o *fake* ou o `MockClient` do pacote `http`.

**Faltar endpoint não bloqueia a tarefa.** Use o *fake*, marque o endpoint como `// PROVISÓRIO` em `endpoints.dart`, registre em `../sugestoes-backend/` se ainda não houver sugestão sobre aquilo, e continue.

### 3.3.1 Quando bloquear (`BLOQUEADA`)
- A tarefa contradiz a Constituição ou o DVP.
- Falta uma regra de negócio que o DVP não resolve.
- `docker pull` ou `flutter pub get` falham (Constituição 8.2).
- O Docker não está rodando e nenhuma verificação é possível. Nesse caso, peça ao Eduardo para abrir o Docker Desktop antes de bloquear.

### 3.4 Sugestões para o agente do backend

Modelo em `../sugestoes-backend/_TEMPLATE.md`. Crie `S0xx-titulo-curto.md` quando houver:
- **PENDÊNCIA:** falta endpoint, campo ou permissão;
- **DIVERGÊNCIA:** DVP e código não combinam;
- **MELHORIA:** sugestão sem nada travando.

Deixe `Status: SEM-RESPOSTA` e não espere resposta. No sentido contrário, responda em `../../ADS_EduardoCamargo_AgilizaDelivery/agente_backend/sugestoes-mobile/` editando só `Status` e `Resposta do agente mobile`.

### 3.5 Git

- O repositório é próprio, em `agiliza_mobile/`, criado na T001: commit inicial em `main` com a governança, depois `develop` a partir dele.
- Branch: `feature/T0xx-slug` a partir de `develop`. Commits em português: `T0xx: o que foi feito`. Siga a convenção de atribuição da sua sessão, se houver.
- Ao concluir: `git checkout develop && git merge --no-ff feature/T0xx-slug && git branch -d feature/T0xx-slug`.
- `main` é intocável. `git push` só com pedido explícito.
- `.gitignore` padrão do Flutter, mais `build/`, `.dart_tool/` e qualquer `*.jks`/`key.properties`.

---

## 4. Pilha técnica (fixa)

| Camada | Escolha | Observação |
| --- | --- | --- |
| SDK | **Flutter 3.x stable**, Dart 3 | Versão exata fixada na T001 (a da imagem Docker) |
| Plataforma | **Android**, `minSdk 26` | Sem iOS, web ou desktop: remova essas pastas na T001 |
| Estado e injeção | **flutter_riverpod** | Sem geração de código (`riverpod_generator` fora) |
| Navegação | **go_router** | Redirecionamento por sessão |
| HTTP | **http** | Encapsulado num `ApiClient` único |
| Armazenamento seguro | **flutter_secure_storage** | Só `token` e `refreshToken` (Constituição 6.1) |
| Localização | **geolocator** | Permissão + posição atual |
| Deep links | **url_launcher** | WhatsApp, Google Maps, Waze, telefone |
| Formatação | **intl** | Moeda pt-BR, datas `America/Sao_Paulo` |
| Testes | **flutter_test** + **mocktail** + `http/testing.dart` (`MockClient`) | |

JSON é manual (`fromJson`/`toJson`), sem `json_serializable`, `freezed` nem `build_runner`, para manter o build no Docker simples. Qualquer pacote fora desta lista exige justificativa no relatório.

### 4.1 Flutter via Docker (D008)

O Flutter **não** está instalado na máquina. Todo comando `flutter`/`dart` roda num container, pelo wrapper `scripts/flutter.sh` (Git Bash) ou `scripts/flutter.ps1` (PowerShell), criado na T001. Referência do que o wrapper faz:

```bash
# Git Bash no Windows: MSYS_NO_PATHCONV evita que /app vire C:/Program Files/Git/app
MSYS_NO_PATHCONV=1 docker run --rm \
  -v "$(pwd -W 2>/dev/null || pwd)":/app -w /app \
  -v agiliza_pub_cache:/root/.pub-cache \
  -v agiliza_gradle:/root/.gradle \
  ghcr.io/cirruslabs/flutter:<versao-fixada> \
  flutter "$@"
```

- Imagem: `ghcr.io/cirruslabs/flutter`, que traz Flutter + Android SDK. Na T001, use a tag `stable` uma vez, anote a versão real (`flutter --version`) e **fixe essa tag** no wrapper.
- Os volumes nomeados guardam o cache do pub e do Gradle entre execuções. Na T001, confira se o `PUB_CACHE` da imagem é mesmo `/root/.pub-cache` e ajuste o volume se não for.
- O primeiro `flutter build apk` baixa o Gradle e as dependências do Android e demora: rode em background.
- **Docker parado:** se `docker info` falhar, peça ao Eduardo para abrir o Docker Desktop. Não tente instalar nada.
- **Sem emulador:** o app não roda no container. A verificação automática é `analyze` + `test`, e o APK de debug vai para `build/app/outputs/flutter-apk/app-debug.apk`, para o Eduardo instalar no aparelho. Tudo o que depende do aparelho entra no relatório como "verificação manual pendente".

### 4.2 Alcançar o backend a partir do aparelho

- Comando de build: `scripts/flutter.sh build apk --debug --dart-define=API_URL=http://<IP-do-PC-na-rede>:8080`.
- O backend precisa escutar em `0.0.0.0` (é o padrão do Spring) e o firewall do Windows precisa liberar a porta 8080.
- O build de debug precisa de `android:usesCleartextTraffic="true"`, ou de um `network_security_config` só no *source set* `debug`. O de *release* não pode ter isso (Constituição 6.6).
- CORS não se aplica ao app nativo.

---

## 5. Arquitetura de pastas do código

```
lib/
├── main.dart                # lê dart-defines, monta ProviderScope e o App
├── app/                     # App, tema (alvos ≥ 48 dp), go_router com guarda de sessão
├── core/
│   ├── api/
│   │   ├── api_client.dart  # ÚNICO ponto HTTP: base URL, Bearer, refresh em 401, parse de ApiErrorResponse
│   │   ├── endpoints.dart   # TODOS os caminhos, com // PROVISÓRIO quando for o caso
│   │   └── erros.dart       # codigo → mensagem pt-BR; ErroApi normalizado
│   ├── sessao/              # armazenamento seguro de tokens, estado da sessão
│   ├── dominio/             # enums, labels pt-BR, transições permitidas ao entregador
│   ├── formatacao/          # moeda (null → "—"), km, data/hora SP
│   ├── localizacao/         # permissão, posição atual, telemetria em primeiro plano (20 s)
│   └── deep_links/          # montagem das URLs de WhatsApp, Maps e Waze
├── features/
│   ├── auth/                # UC07: login, logout
│   ├── inicio/              # Online/Offline, polling do lote ativo (10 s)
│   ├── lote/                # UC02: lote, entregas, detalhes, iniciar percurso, ENTREGUE/FALHA
│   └── acerto/              # UC08: extrato do turno, status do caixa, contestar
└── ...
test/                        # espelha lib/; fakes e fábricas de dados em test/apoio/
```

Cada `features/<x>/` tem `data/` (interface do repositório + implementação Api + Fake), `estado/` (providers/notifiers) e `ui/` (páginas e widgets). Uma *feature* não importa os internos de outra: só `core/` ou o arquivo público dela.

---

## 6. Contrato com o backend

> ⚠️ **Situação em 15/11/2026:** só existem para o entregador o login (`/api/auth/*`) e `PATCH /api/motoboys/{id}/posicao`. Os endpoints da seção 6.4 são a **proposta** da T009 do backend: tudo `PROVISÓRIO` até ela estar `CONCLUIDA`. O backend confirma os caminhos e formatos finais numa sugestão em `agente_backend/sugestoes-mobile/`. Confira sempre o código real (seção 0, passo 5).

### 6.1 Enums (valores exatos)

| Enum | Valores |
| --- | --- |
| PerfilUsuario | `ADMIN_GERAL`, `ADMIN_RESTAURANTE`, `OPERADOR`, `ENTREGADOR` |
| StatusEntrega | `AGUARDANDO_DESPACHO`, `DESPACHADA`, `EM_ROTA`, `ENTREGUE`, `FALHA`, `CANCELADA` |
| StatusLote | `DESPACHADO`, `EM_ROTA`, `CONCLUIDO`, `CANCELADO` |
| StatusDisponibilidadeMotoboy | `OFFLINE`, `ONLINE`, `EM_ROTA` |
| StatusCadastroMotoboy | `ATIVO`, `BLOQUEADO` |
| StatusCaixa | `ABERTO`, `FECHADO`, `REABERTO` |
| MotivoRevisao | `SEM_COORDENADA`, `SEM_DISTANCIA`, `CONTESTACAO_ENTREGADOR` |
| FormaPagamento | `DINHEIRO`, `CREDITO`, `DEBITO`, `PIX`, `VALE` |
| SituacaoAcerto | `A_ACERTAR`, `CONSOLIDADA`, `EM_REVISAO` |

Um valor desconhecido vindo da API é erro de contrato (Constituição 7.2): registre no relatório e mostre o estado de erro, nunca um valor inventado.

### 6.2 O que o entregador pode fazer, por status

| Objeto e status | Ação no app |
| --- | --- |
| Motoboy `OFFLINE` | "Ficar online" (exige permissão de localização) |
| Motoboy `ONLINE` sem lote | "Ficar offline"; aguardar lote |
| Lote `DESPACHADO` | Ver entregas, "Iniciar percurso" |
| Lote `EM_ROTA`, entrega `EM_ROTA` | Navegar, WhatsApp, "Entregue", "Falha" (motivo obrigatório) |
| Entrega `ENTREGUE`/`FALHA`/`CANCELADA` | Só leitura no lote; no acerto, "Contestar" (seção 8.4) |
| Motoboy `EM_ROTA` | **Não** pode ficar offline |

### 6.3 DTOs (camelCase; `?` = pode vir ausente ou `null`)

- **LoginRequest**: `loginEmail`, `senha`, `canal` (`"APP"`)
- **Resposta do login e do refresh**: `{ token, refreshToken, usuario: UsuarioAutenticadoResponse }`
- **UsuarioAutenticadoResponse**: `usuarioId`, `estabelecimentoId`, `motoboyId`, `nome`, `perfil`
- **RefreshRequest**: `refreshToken`
- **MotoboyResponse**: `id`, `usuarioId`, `nome`, `telefone`, `placaVeiculo?`, `statusCadastro`, `statusDisponibilidade`, `ultimaPosicao?`, `ultimaPosicaoEm?`, `criadoEm`, `atualizadoEm?` (o CPF nunca vem)
- **CoordenadaDto**: `latitude`, `longitude`
- **AtualizarPosicaoRequest**: `latitude`, `longitude`
- **AlterarDisponibilidadeMotoboyRequest**: `status` (`ONLINE` | `OFFLINE`)
- **AlterarStatusEntregaRequest**: `status` (`ENTREGUE` | `FALHA`), `motivoFalha?` (≤ 100 caracteres, obrigatório em FALHA), `coordenada?`, `ocorridoEm` (`"2026-11-15T21:30:00"`, sem fuso)
- **LoteEntregaResponse**: `id`, `estabelecimentoId`, `motoboyId`, `usuarioDespachanteId`, `status`, `qtdEntregas`, `valorTotalRepasse?`, `despachadoEm?`, `concluidoEm?`, `criadoEm`, `atualizadoEm?`
- **EntregaResponse**: `id`, `loteId?`, `nomeCliente`, `telefoneCliente?`, `enderecoCompleto`, `bairro?`, `cep?`, `complemento?`, `pontoReferencia?`, `coordenada?`, `valorPedido?`, `formaPagamento?`, `pagoOnline`, `trocoPara?`, `observacoes?`, `distanciaKm?`, `valorRepasse?`, `status`, `motivoFalha?`, `pendenteRevisao`, `motivoRevisao?`, `ordemRota?`, `finalizadaEm?`, entre outros. Ignore campos que não usa.
- **ItemPedidoResponse**: `descricao`, `quantidade`, `valorUnitario?`, `observacao?`
- **ExtratoAcertoResponse**: `motoboyId`, `nomeEntregador`, `periodoInicio`, `periodoFim`, `linhas[]`, `totalDevido`, `totalConsolidado`, `totalEmRevisao`, `possuiValorIndefinido`
- **LinhaExtratoResponse**: `entregaId`, `nomeCliente`, `finalizadaEm`, `status`, `distanciaKm`, `faixaDeKm`, `faixaAteKm`, `foraDeArea`, `valorRepasse`, `situacao`, `reciboId?`

`ordemRota` é a ordem manual escolhida pelo operador no despacho. O app pode **ordenar** a lista por ela, mas nunca sugere nem recalcula a sequência (Constituição 4.2).

### 6.4 Endpoints do entregador — PROVISÓRIO (proposta da T009 do backend)

| Uso | Método e caminho |
| --- | --- |
| Login / refresh | `POST /api/auth/login` (existe), `POST /api/auth/refresh` (existe) |
| Meu cadastro e disponibilidade | `GET /api/entregador/me` → `MotoboyResponse` |
| Ficar online/offline | `PATCH /api/entregador/disponibilidade` → `MotoboyResponse` |
| Enviar posição | `PATCH /api/entregador/posicao` (`AtualizarPosicaoRequest`). Hoje só existe `PATCH /api/motoboys/{id}/posicao`, que a T009 deve corrigir para conferir o dono |
| Lote ativo (DESPACHADO ou EM_ROTA) | `GET /api/entregador/lote-ativo` → `{ lote, entregas: [EntregaResponse + itens[]] }`, ou `204` sem lote |
| Iniciar percurso | `POST /api/entregador/lotes/{id}/iniciar` → `LoteEntregaResponse` |
| Marcar ENTREGUE/FALHA | `POST /api/entregador/entregas/{id}/status` (`AlterarStatusEntregaRequest`) → `EntregaResponse` |
| Contestar | `POST /api/entregador/entregas/{id}/contestar` → `EntregaResponse` |
| Meu acerto | `GET /api/entregador/acerto?inicio=&fim=` → extrato + `statusCaixa` do período. Sem parâmetros, o turno atual |

O `motoboyId` **nunca** vai no caminho nem no corpo: o backend o tira do token. Se o backend mantiver `{id}` em algum caminho, use `usuario.motoboyId` da sessão (Constituição 5.8).

### 6.5 Erros

Formato: `ApiErrorResponse { timestamp, status, error, codigo, message, path, campos?[] }`. Lista oficial dos códigos: `.../agilizadelivery/src/main/java/br/com/agilizadelivery/exception/` (confira o enum de código de erro). Os que o app precisa mapear com mensagem própria:

| Código | Mensagem no app |
| --- | --- |
| `CREDENCIAIS_INVALIDAS` | "E-mail ou senha inválidos" |
| `ACESSO_NEGADO` no login | "Este aplicativo é exclusivo para entregadores" |
| `ESTABELECIMENTO_INATIVO` | "O acesso desta loja está suspenso" |
| `USUARIO_BLOQUEADO` | "Seu acesso está bloqueado. Procure a loja." |
| `NAO_AUTENTICADO` | tenta refresh; se falhar, volta ao login |
| `MOTOBOY_INDISPONIVEL` | `message` do servidor |
| `TRANSICAO_ESTADO_INVALIDA` | "Esta ação não é mais possível. Atualizando..." + recarregar o lote |
| `CAIXA_FECHADO` | "O caixa já foi fechado. Procure o operador." |
| `REGRA_NEGOCIO_VIOLADA` | `message` do servidor |
| outros | `message` do servidor |

Sem rede (`SocketException`/timeout): "Sem conexão. Tente de novo." A ação **não** é enfileirada, porque a fila offline está fora deste ciclo (D008).

### 6.6 Convenções

- **Dinheiro:** chega como número. Exiba formatado e nunca some no cliente. `null` vira "—".
- **Datas:** `LocalDateTime` sem fuso, interpretado como `America/Sao_Paulo`. Para enviar, use o mesmo formato, sem `Z` nem offset.
- **IDs:** UUID como `String`.
- **Auth:** `Authorization: Bearer <token>`. Num `401`, faça um único refresh concorrente, repita a requisição uma vez e, se falhar de novo, faça logout.

---

## 7. Telas

| Rota | Tela | Quem |
| --- | --- | --- |
| `/login` | Login | sem sessão |
| `/inicio` | Início: status, Online/Offline, cartão do lote ativo | sessão ENTREGADOR |
| `/lote` | Lote ativo: lista de entregas | idem |
| `/lote/entrega/:id` | Detalhe da entrega | idem |
| `/acerto` | Acerto do turno | idem |

A navegação principal é uma barra inferior com **Início** e **Acerto**, mais o logout no menu. Sem sessão, tudo leva a `/login`.

---

## 8. Regras de cada tela

### 8.1 Login (UC07, HU13)
- E-mail e senha, enviados com `canal: "APP"`.
- Se `usuario.perfil != ENTREGADOR`, a sessão não é aberta e aparece "Este aplicativo é exclusivo para entregadores".
- Os tokens vão para o armazenamento seguro. Ao abrir o app com tokens salvos, ele tenta `GET /api/entregador/me`: se funcionar, vai para `/inicio`; se não, para `/login`.

### 8.2 Início
- Mostra o nome, a disponibilidade atual (com texto e cor, nunca só a cor) e um botão grande **Ficar online** / **Ficar offline**.
- **Ficar online:** pede permissão de localização. Se negada, explica por que ela é necessária e oferece abrir as configurações (UC02 E1).
- Em `EM_ROTA`, o botão de offline fica desabilitado, com a explicação.
- Em `ONLINE`/`EM_ROTA`, com o app em primeiro plano, a telemetria roda a cada 20 s e o polling do lote ativo a cada 10 s.
- Com lote ativo, aparece o cartão "Novo lote: N entregas", que leva a `/lote`. Ao detectar um lote novo, o app vibra ou mostra um *snackbar*.

### 8.3 Lote e detalhe da entrega (UC02, HU04, HU05)
- Lista ordenada por `ordemRota` (ou pela ordem recebida). Cada item mostra cliente, bairro, status, valor do pedido, forma de pagamento e "Levar troco para R$ X" quando `trocoPara` existir. Com `pagoOnline`, mostra "Pago online".
- Lote `DESPACHADO`: botão **Iniciar percurso**, com confirmação.
- No detalhe: endereço completo, complemento, ponto de referência, itens (descrição × quantidade, observação) e observações.
- **Navegar:** oferece Waze e Google Maps.
  - Google Maps: `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>`, ou `destination=<endereço url-encoded>` se não houver coordenada.
  - Waze: `https://waze.com/ul?ll=<lat>,<lng>&navigate=yes`, ou `?q=<endereço>`.
- **WhatsApp:** `https://wa.me/<55+DDD+número só dígitos>?text=<mensagem url-encoded>`. Mensagem padrão: "Olá, {nomeCliente}! Sou o entregador do {nome da loja, se houver}. Estou a caminho com o seu pedido." Sem telefone, o botão fica desabilitado.
- O `AndroidManifest.xml` precisa do bloco `<queries>` com as intents `VIEW` (`https` e `tel`), exigido pelo Android 11+.
- **Entregue:** um toque abre a confirmação e o segundo envia (RNF11). Vai com `coordenada` e `ocorridoEm`.
- **Falha:** abre a escolha do motivo, com atalhos "Cliente ausente", "Endereço não encontrado" e "Cliente recusou", mais texto livre de até 100 caracteres. O envio é igual ao de Entregue.
- Depois de cada resposta, o app recarrega o lote ativo. Quando o backend devolve `204` (lote encerrado), volta para `/inicio` com "Lote concluído".

### 8.4 Acerto (UC08, HU14)
- Por padrão mostra o turno atual. Exibe o total devido, o total consolidado em recibo, o total em revisão e a lista de entregas (cliente, data/hora, distância, faixa, valor, situação).
- Com `possuiValorIndefinido`, aparece o aviso "Há entregas com valor ainda não definido".
- Caixa `ABERTO`/`REABERTO`: o título é "Valor parcial do turno", e cada linha com `situacao = A_ACERTAR` oferece **Contestar** (confirmação em dois toques).
- Caixa `FECHADO`: o título é "Valor final", não há botão Contestar, e aparece a orientação "Para corrigir algum valor, procure o operador" (E2).
- Linha `EM_REVISAO`: mostra o selo "Em análise" e não tem botão (E1).
- O app nunca soma valores: todos os totais vêm do backend (Constituição 5.1).

---

## 9. Skills

Instaladas em `../.claude/skills/` em 15/11/2026, vindas de `sickn33/agentic-awesome-skills` (aprovadas pelo Eduardo):

| Situação | Skill | Atenção: o que ignorar nela |
| --- | --- | --- |
| Widgets, Dart 3, Riverpod, testes de widget, performance | `flutter-expert` | Bloc, GetX, MobX, GetIt, Dio, freezed/geração de código, iOS, web, desktop, Firebase — fora da pilha da seção 4 |
| Toque (48 dp, zona do polegar), navegação, Material 3 no Android, bateria, testes | `mobile-design` (ler `touch-psychology.md`, `platform-android.md`, `mobile-navigation.md`, `mobile-testing.md` conforme a tarefa) | "Offline-capable" e sincronização (`mobile-backend.md`): a fila offline está fora deste ciclo (D008); `platform-ios.md` não se aplica |
| Armazenamento seguro, cleartext, permissões, dados pessoais | `mobile-security-coder` | WebView, biometria e pinning de certificado: fora do escopo |

As skills orientam a técnica e **nunca** mudam escopo, pilha ou regra de negócio (Constituição, cabeçalho). Para o resto, siga a documentação oficial do Flutter, do Riverpod, do go_router, do geolocator e do url_launcher.

---

## 10. Plano de fases (referência do Orquestrador)

Prazo final: **17/11/2026**.

| Fase / tarefa | Conteúdo | DVP |
| --- | --- | --- |
| T001 | Setup via Docker, estrutura de pastas, `core/` (api, sessão, domínio, formatação), git | 2.2 Entrega 1/5 |
| T002 | Login, sessão, Início com Online/Offline, telemetria em primeiro plano, polling do lote | UC07, UC02 E1, RF04, RNF01 |
| T003 | Lote, detalhe, deep links, iniciar percurso, ENTREGUE/FALHA | UC02, HU04, HU05, RNF11 |
| T004 | Acerto do turno, status do caixa, contestar; APK de debug final | UC08, HU14 |

---

## 11. Definição de pronto

Uma tarefa está **CONCLUIDA** quando:
1. o escopo foi entregue, e nada além dele;
2. `scripts/flutter.sh analyze` não aponta erros nem avisos e `scripts/flutter.sh test` passa. A saída resumida vai no relatório;
3. as telas novas têm os estados carregando, vazio e erro;
4. há teste para cada regra de negócio tocada (por exemplo: perfil não-ENTREGADOR recusado, offline bloqueado em EM_ROTA, FALHA sem motivo bloqueada, Contestar ausente com caixa FECHADO, valor `null` mostrado como "—");
5. os endpoints estão em `endpoints.dart`, com `// PROVISÓRIO` quando não confirmados;
6. as sugestões ao backend estão em `../sugestoes-backend/`;
7. o relatório está escrito, com a lista de "verificação manual pendente" do que depende do aparelho.

---

## 12. Pontos em aberto (não decida, registre)

1. Caminhos e formatos finais dos endpoints do entregador: dependem da T009 do backend.
2. Nome da loja na mensagem do WhatsApp: hoje não vem em nenhum DTO do entregador. Sem ele, a mensagem omite o trecho.
3. A versão exata da imagem Docker é fixada na T001.
