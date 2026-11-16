# Relatório — T002 Login, sessão, Online/Offline e telemetria

**Status final:** CONCLUIDA
**Data:** 2026-11-15

## O que foi feito
- **Contrato real:** a T009 do backend está CONCLUIDA. `core/api/endpoints.dart` passou a usar o contrato de `agente_backend/sugestoes-mobile/S001-endpoints-do-entregador.md`, conferido no `EntregadorController` e nos DTOs, e nenhum caminho ficou `PROVISÓRIO`. A S001 do backend foi respondida como **ACEITA** (só os campos `Status` e `Resposta do agente mobile`).
- **T012 do backend:** o modelo do lote já lê `nomeFantasiaEstabelecimento` (lote) e `distanciaKm`/`valorRepasse` (entrega). Os três são opcionais.
- `core/sessao/`:
  - `ArmazenamentoTokensSeguro` usa `flutter_secure_storage` (Keystore) e guarda só `token` e `refreshToken`, com cópia em memória. O `toString()` mascara os valores.
  - `Sessao` / `EstadoSessao`: verificando, sem sessão ou ativa.
  - `RenovadorSessao`: um único refresh para várias requisições concorrentes.
- `ApiClient` + `apiClientProvider`: num 401, `POST /api/auth/refresh`, uma nova tentativa da requisição e, se o refresh falhar, o evento de sessão expirada, que faz o logout. Login e refresh vão sem token e nunca disparam o refresh. O `http.Client` é injetável (`httpClientProvider`).
- `features/auth/`:
  - tela de login: e-mail, senha, mostrar/ocultar senha, botão bloqueado durante o envio (sem duplo toque);
  - `POST /api/auth/login` com `canal: "APP"`;
  - mensagens da seção 6.5;
  - perfil diferente de `ENTREGADOR` (ou sem `motoboyId`) recusado com "Este aplicativo é exclusivo para entregadores", sem gravar tokens nem abrir sessão (Constituição 4.3);
  - logout no menu, que apaga os tokens e a última posição. Os estados das features observam a sessão e são descartados.
- Abertura do app: com tokens salvos, `GET /api/entregador/me`. Se funcionar, vai para `/inicio`; qualquer falha leva a `/login` e apaga os tokens.
- `go_router` com guarda: `/carregando` → `/login` ou `/inicio`. Sem sessão, tudo leva a `/login`.
- `features/inicio/`:
  - nome e disponibilidade com selo (ícone + texto + cor);
  - botão grande "Ficar online" / "Ficar offline" (56 dp), sem atualização otimista;
  - permissão de localização pedida antes de ficar online. Negada, aparece a explicação e o atalho para as configurações do app ou da localização, e a API **não** é chamada (UC02 E1);
  - em `EM_ROTA`, "Ficar offline" desabilitado com a explicação;
  - cartão do lote ativo ("Novo lote: N entregas" / "Lote em rota: N entregas"), que leva a `/lote` (placeholder nesta tarefa).
- `core/localizacao/` + `features/inicio/estado/turno.dart`:
  - telemetria a cada 20 s e polling do lote a cada 10 s, só com sessão ativa, entregador `ONLINE`/`EM_ROTA` e app em primeiro plano (`WidgetsBindingObserver`);
  - ao ficar offline, ir para segundo plano ou sair, os providers são reconstruídos e os timers, cancelados;
  - falha de envio é ignorada (sem fila) e só conta num contador interno, sem dados pessoais.
- Lote novo: vibração (`HapticFeedback`) e *snackbar* "Novo lote: N entregas". Na primeira consulta, ao abrir o app, não há aviso.
- Repositórios `AuthRepository`, `EntregadorRepository` e `LoteRepository` (`buscarLoteAtivo`), cada um com implementação Api e Fake, escolhida por `USAR_FAKE`. O `FakeBackend` simula o contrato S001 com os mesmos códigos de erro. O fake aceita `entregador@agiliza.com` / `123456`; `operador@agiliza.com` é recusado pelo app.
- `analysis_options.yaml` exclui as pastas locais de trabalho do agente (`_rascunhos/`, `_wt_*/`), que estão fora do git.

## O que NÃO foi feito (e por quê)
- GPS em segundo plano, fila offline e envio de posições em lote: desvios da D008.
- "Esqueci minha senha": fora do escopo (Constituição 4.2).
- Tela real do lote: é a T003.

## Arquivos criados/alterados
- `lib/core/sessao/{armazenamento_tokens,sessao,renovador_sessao}.dart`
- `lib/core/localizacao/{servico_localizacao,tarefa_periodica,primeiro_plano,ultima_posicao}.dart`
- `lib/core/providers_core.dart`, `lib/core/dominio/modelos.dart`, `lib/core/fake/fake_backend.dart`
- `lib/core/ui/{estados,status_visual,mensageiro}.dart`
- `lib/core/api/{endpoints,erros}.dart` (contrato real; `RECURSO_NAO_ENCONTRADO`)
- `lib/app/{app,rotas}.dart`
- `lib/features/auth/**`, `lib/features/inicio/**`, `lib/features/lote/{lote.dart,data/*,estado/*,ui/lote_page.dart}`
- `test/apoio/apoio.dart`, `test/features/{auth,inicio,login_page}_test.dart`
- `sugestoes-backend/S001-repasse-na-entrega-do-entregador.md`, `sugestoes-backend/S002-nome-da-loja-para-o-whatsapp.md`
- `analysis_options.yaml`

### Testes de regra de negócio
- `auth_test.dart`: login com sucesso (tokens salvos); `canal: "APP"` no corpo; credenciais inválidas → "E-mail ou senha inválidos"; OPERADOR recusado sem tokens; `ACESSO_NEGADO` no login; abertura com tokens + `/me`; **um único refresh** para dois 401 concorrentes, com nova tentativa; refresh que falha → sem sessão e sem tokens; logout apaga tokens.
- `login_page_test.dart` (widget): OPERADOR vê "Este aplicativo é exclusivo para entregadores"; credenciais inválidas; entregador válido abre a sessão.
- `inicio_test.dart`: online sem permissão **não chama a API**; online com permissão; EM_ROTA não chama offline; telemetria de 20 s envia e **para ao ficar offline** (timer controlado); para em segundo plano e volta; logout para a telemetria; polling encontra o lote; widget com "Ficar offline" desabilitado em EM_ROTA e explicação; widget de permissão negada com atalho para as configurações.

## Verificação
| Comando | Resultado |
| --- | --- |
| `scripts/flutter.sh analyze` | ✅ "No issues found! (ran in 72.1s)". Na primeira rodada vieram 3 infos `prefer_initializing_formals` e 1 erro no teste (`Override` em Riverpod 3 vem de `flutter_riverpod/misc.dart`), todos corrigidos |
| `scripts/flutter.sh test` | ✅ 46 testes, 46 passaram ("All tests passed!"): 26 de `core` (T001) e 20 novos. Um teste de telemetria falhou na primeira rodada por erro do cenário: o fake despachava um lote na hora, e EM_ROTA não pode ficar offline. O cenário foi corrigido; a regra estava certa |

## Verificação manual pendente (aparelho físico)
- Diálogo real de permissão de localização: permitir, negar e "não perguntar de novo", com o atalho para as configurações.
- GPS desligado → atalho para as configurações de localização.
- Telemetria chegando ao painel a cada 20 s com o app aberto e parando ao ir para segundo plano ou ao ficar offline.
- Vibração ao chegar um lote novo.
- Sessão que sobrevive ao fechar e reabrir o app (Keystore).
- Login real contra o backend (`entregador1@agiliza.dev` / `agiliza123`) pelo IP da rede local.

## Desvios conscientes do DVP tocados (D008)
- RF04 / R02: sem GPS em segundo plano nem *foreground service*. A telemetria roda só com o app em primeiro plano.
- RNF01: uma posição a cada 20 s, uma por chamada, sem lotes de 5.
- RNF09: sem fila offline. Falha de envio é descartada; a ação de status mostra "Sem conexão. Tente de novo.".
- Polling de 10 s no lugar de notificação push.

## Decisões tomadas (dentro do escopo)
- Na abertura do app, qualquer falha do `/me` (inclusive sem rede) leva ao login e apaga os tokens. É o padrão mais restritivo.
- Refresh que falha por qualquer motivo encerra a sessão com o aviso "Sua sessão expirou. Entre novamente.".
- Um login com perfil ENTREGADOR mas sem `motoboyId` também é recusado (sem `motoboyId` da sessão o app não opera; Constituição 5.8).
- A posição usada no envio fica só em memória (`ultimaPosicaoProvider`) e é apagada no logout.

## Sugestões/pendências registradas para o backend
- `sugestoes-backend/S001-repasse-na-entrega-do-entregador.md`: `valorRepasse`/`distanciaKm` na entrega do lote. **ACEITA** pelo backend (T012).
- `sugestoes-backend/S002-nome-da-loja-para-o-whatsapp.md`: nome da loja. **ACEITA** como `nomeFantasiaEstabelecimento` (T012).

## Proposta de mudança no DVP (Constituição, Artigo 2.4)
- Nenhuma.

## Dúvidas / bloqueios
- Nenhum.

## Sugestões (não implementadas)
- Nenhuma.
