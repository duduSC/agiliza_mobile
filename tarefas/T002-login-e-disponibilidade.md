# T002 — Login, sessão, Online/Offline e telemetria

**Status:** PENDENTE
**Depende de:** T001. Do backend: `../../ADS_EduardoCamargo_AgilizaDelivery/agente_backend/tarefas/T009-endpoints-do-entregador.md` (não bloqueia: use fake até ela terminar).
**Referências no DVP:** UC07 (1.4.2.7, E1–E4), HU13, UC02 E1, RF04, RNF01, RNF07, RNF11

## Objetivo
O entregador faz login pelo app, a sessão sobrevive ao fechamento do app, e ele consegue ficar online/offline. Enquanto está online, com o app aberto, a posição é enviada a cada 20 s e o lote ativo é consultado a cada 10 s.

## Escopo
- [ ] `core/sessao/`: armazenamento seguro de `token` e `refreshToken` (`flutter_secure_storage`) e estado da sessão com o `UsuarioAutenticadoResponse`.
- [ ] `ApiClient`: num 401 `NAO_AUTENTICADO`, um único refresh concorrente (`POST /api/auth/refresh`), repete a requisição uma vez e, se falhar, faz logout (Constituição 6.2).
- [ ] `features/auth/`:
  - tela de login (e-mail, senha, botão com estado de envio e duplo toque bloqueado);
  - `POST /api/auth/login` com `canal: "APP"`;
  - mensagens da seção 6.5;
  - perfil diferente de ENTREGADOR recusado (Constituição 4.3);
  - logout no menu, apagando os tokens e todo o estado.
- [ ] Na abertura do app com tokens salvos: `GET /api/entregador/me`. Se funcionar, vai para `/inicio`; se não, para `/login`.
- [ ] `go_router` com guarda: sem sessão, tudo vai para `/login`.
- [ ] `features/inicio/` (AGENT.md 8.2):
  - nome e disponibilidade (texto e cor);
  - botão grande Ficar online / Ficar offline (`PATCH /api/entregador/disponibilidade`), sem atualização otimista;
  - permissão de localização antes de ficar online, com explicação e atalho para as configurações se for negada (UC02 E1);
  - offline desabilitado em `EM_ROTA`.
- [ ] `core/localizacao/`: em `ONLINE`/`EM_ROTA` e com o app em primeiro plano (`WidgetsBindingObserver`), envia a posição a cada 20 s (`PATCH /api/entregador/posicao`). Para ao ficar offline, ao ir para segundo plano e no logout. Falha de envio é ignorada silenciosamente (sem fila, D008) e registrada só em contador interno para debug, sem dados pessoais.
- [ ] Polling do lote ativo (`GET /api/entregador/lote-ativo`) a cada 10 s nas mesmas condições.
  - Quando chega um lote novo: cartão "Novo lote: N entregas", vibração ou *snackbar*.
  - O cartão leva a `/lote`, que nesta tarefa pode ser um placeholder: a tela real é a T003.
- [ ] Repositórios `AuthRepository`, `EntregadorRepository` e `LoteRepository` (só `buscarLoteAtivo` por ora), cada um com implementação Api e Fake (AGENT.md 3.3). O fake de login aceita um entregador de teste e recusa os outros perfis.
- [ ] Testes:
  - login com sucesso;
  - credenciais inválidas com a mensagem genérica;
  - perfil OPERADOR recusado;
  - refresh automático depois de um 401;
  - logout limpando os tokens;
  - online sem permissão não chama a API;
  - offline desabilitado em EM_ROTA;
  - telemetria para ao ficar offline (com o timer controlado no teste).

## Fora do escopo
- GPS em segundo plano, fila offline e envio em lote (D008).
- "Esqueci minha senha".
- Telas de lote e acerto.

## Regras de negócio envolvidas
- Constituição 4.3, 5.3, 5.6, 5.7, 5.8, 6.1–6.4.

## Critérios de aceite
- Dado um entregador válido, quando ele faz login, então chega a `/inicio` e os tokens estão no armazenamento seguro.
- Dado um usuário OPERADOR, quando ele faz login no app, então vê "Este aplicativo é exclusivo para entregadores" e nenhuma sessão é aberta.
- Dado o entregador ONLINE com o app aberto, quando passam 20 s, então uma posição é enviada. Indo para segundo plano, o envio para.
- Dado o entregador EM_ROTA, então o botão Ficar offline está desabilitado com a explicação.
- `analyze` limpo e `test` verde.

## Backend / fakes
`/api/auth/login` e `/api/auth/refresh` são reais. `/api/entregador/*` é PROVISÓRIO até a T009 do backend estar CONCLUIDA. Se estiver, confira `../../ADS_EduardoCamargo_AgilizaDelivery/agente_backend/sugestoes-mobile/` e ajuste `endpoints.dart` ao contrato real.

## Ao terminar
Escreva `../relatorios/T002-login-e-disponibilidade.md`, faça o merge para `develop` e **siga para a T003** (D006).
