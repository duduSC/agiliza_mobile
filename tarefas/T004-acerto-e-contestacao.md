# T004 — Acerto do turno, contestação e APK final

**Status:** CONCLUIDA
**Depende de:** T003. Do backend: `../../ADS_EduardoCamargo_AgilizaDelivery/agente_backend/tarefas/T009-endpoints-do-entregador.md` (não bloqueia: use fake).
**Referências no DVP:** UC08 (1.4.2.8, A1, E1, E2), HU14, 1.5.5, RF03

## Objetivo
O entregador acompanha o valor do turno: parcial antes do fechamento do caixa e final depois. Com o caixa aberto, consegue contestar o valor de uma entrega. A tarefa termina com o APK de debug pronto para a apresentação.

## Escopo
- [ ] `features/acerto/` com a tela `/acerto` e a barra inferior Início | Acerto (AGENT.md 7 e 8.4):
  - totais vindos do backend (`totalDevido`, `totalConsolidado`, `totalEmRevisao`);
  - lista de linhas com cliente, data/hora, distância, faixa (`faixaDeKm`–`faixaAteKm`, ou "Fora da área" se `foraDeArea`), valor e situação;
  - aviso quando `possuiValorIndefinido`;
  - puxar para atualizar;
  - estados carregando, vazio e erro.
- [ ] Caixa `ABERTO`/`REABERTO`: título "Valor parcial do turno" e **Contestar** (`POST /api/entregador/entregas/{id}/contestar`) em linhas `A_ACERTAR`, com confirmação em dois toques. Depois da resposta, recarrega o extrato e a linha passa a "Em análise".
- [ ] Caixa `FECHADO`: título "Valor final", sem Contestar, com "Para corrigir algum valor, procure o operador" (E2).
- [ ] Linha `EM_REVISAO`: selo "Em análise", sem botão (E1). `CAIXA_FECHADO` vindo do servidor mostra a mensagem da seção 6.5 e recarrega.
- [ ] `AcertoRepository` (Api + Fake). O fake tem um cenário com caixa aberto e outro com caixa fechado.
- [ ] Testes:
  - Contestar só aparece com caixa aberto e linha A_ACERTAR;
  - com caixa FECHADO não há Contestar e aparece a orientação;
  - linha EM_REVISAO mostra "Em análise";
  - os totais exibidos são os do backend (o teste garante que nenhuma soma acontece no cliente);
  - valor `null` mostrado como "—".
- [ ] **Fechamento do ciclo:**
  - `scripts/flutter.sh build apk --debug --dart-define=API_URL=<placeholder>`, com o passo a passo no README para o Eduardo gerar com o IP real;
  - no relatório, um roteiro de teste manual de ponta a ponta (backend + backoffice + app no aparelho): login, online, despacho pelo backoffice, lote aparecendo, iniciar, entregue/falha, acerto, contestar, fechamento do caixa no backoffice e o app mostrando "Valor final".

## Fora do escopo
- Trilha completa de contestação (justificativa, histórico), recibo em PDF e pagamento.
- Escolher período arbitrário: só o turno atual, a menos que o backend já ofereça `inicio`/`fim` de forma trivial.

## Regras de negócio envolvidas
- Constituição 5.1, 5.5, 7.3.

## Critérios de aceite
- Dado o caixa ABERTO e uma entrega A_ACERTAR, quando o entregador contesta, então a linha passa a "Em análise" e sai do total devido, conforme o backend devolver.
- Dado o caixa FECHADO, então o título é "Valor final" e não existe nenhum botão Contestar.
- `analyze` limpo, `test` verde e APK de debug gerado.

## Backend / fakes
`/api/entregador/acerto` e `/entregas/{id}/contestar` são PROVISÓRIOS até a T009 do backend. Se o backend entregar o status do caixa em outro formato, siga o real e registre.

## Ao terminar
Escreva `../relatorios/T004-acerto-e-contestacao.md`, faça o merge para `develop` e pare.
