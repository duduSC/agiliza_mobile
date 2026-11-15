# T003 — Lote, detalhe da entrega, deep links e ENTREGUE/FALHA

**Status:** PENDENTE
**Depende de:** T002. Do backend: `../../ADS_EduardoCamargo_AgilizaDelivery/agente_backend/tarefas/T009-endpoints-do-entregador.md` (não bloqueia: use fake).
**Referências no DVP:** UC02 (1.4.2.2, fluxo principal, A1), HU04, HU05, RF02, RNF11, 1.4.4 (máquina de estados), 1.5.5 (FALHA com repasse integral)

## Objetivo
O entregador vê o lote despachado, abre cada entrega com todos os detalhes, navega e chama o cliente por deep link, inicia o percurso e marca cada entrega como ENTREGUE ou FALHA, até o lote encerrar.

## Escopo
- [ ] `features/lote/` com a tela `/lote` (AGENT.md 8.3):
  - lista ordenada por `ordemRota`;
  - cada entrega com cliente, bairro, status, valor do pedido, forma de pagamento, "Levar troco para R$ X" e "Pago online";
  - estados carregando, vazio ("Nenhum lote no momento") e erro.
- [ ] **Iniciar percurso** (`POST /api/entregador/lotes/{id}/iniciar`) para lote `DESPACHADO`, com confirmação.
- [ ] Tela `/lote/entrega/:id` com endereço, complemento, ponto de referência, itens, observações e valor do repasse (ou "—").
- [ ] `core/deep_links/` com URLs de Google Maps, Waze e WhatsApp exatamente como no AGENT.md 8.3.
  - Telefone normalizado: só dígitos e prefixo 55 se faltar.
  - Sem coordenada, a navegação usa o endereço.
  - Sem telefone, o botão de WhatsApp fica desabilitado.
  - Se o `launchUrl` falhar: "Não foi possível abrir o aplicativo".
- [ ] **Entregue** e **Falha** (`POST /api/entregador/entregas/{id}/status`):
  - só em entrega `EM_ROTA`;
  - confirmação em dois toques (RNF11);
  - Falha exige motivo (atalhos + texto livre ≤ 100);
  - envio com `coordenada` (última posição disponível, ou nenhuma) e `ocorridoEm`;
  - sem atualização otimista, botão bloqueado durante o envio;
  - depois da resposta, recarrega o lote ativo;
  - com `204` volta para `/inicio` com "Lote concluído";
  - `TRANSICAO_ESTADO_INVALIDA` recarrega o lote com o aviso da seção 6.5.
- [ ] Completar o `LoteRepository` (Api + Fake). O fake simula a máquina de estados: `DESPACHADO` → `EM_ROTA` ao iniciar, e fim do lote quando todas as entregas estão finalizadas.
- [ ] Testes:
  - montagem das URLs (Maps com e sem coordenada, Waze, WhatsApp com telefone de 10 e 11 dígitos e com 55);
  - Iniciar só aparece em DESPACHADO;
  - Entregue/Falha só aparecem em EM_ROTA;
  - Falha sem motivo não envia;
  - valor `null` mostrado como "—";
  - lote concluído volta ao início.

## Fora do escopo
- Mapa dentro do app, sugestão de ordem e reordenação (Constituição 4.2).
- Alerta de cancelamento durante o percurso (UC02 A3) e fila offline (UC02 A2): desvios da D008. Sem rede, mostra "Sem conexão. Tente de novo." e não enfileira.

## Regras de negócio envolvidas
- Constituição 5.1, 5.2, 5.4, 5.7, 6.4, 7.3, 7.6.

## Critérios de aceite
- Dado um lote DESPACHADO com 2 entregas, quando o entregador inicia o percurso e marca uma como ENTREGUE e a outra como FALHA ("Cliente ausente"), então o lote some e o app volta ao início com "Lote concluído".
- Dado uma entrega sem telefone, então o botão WhatsApp está desabilitado.
- `analyze` limpo e `test` verde.
- Verificação manual pendente: os deep links abrindo Waze, Maps e WhatsApp num aparelho real.

## Backend / fakes
`/api/entregador/lote-ativo`, `/lotes/{id}/iniciar` e `/entregas/{id}/status` são PROVISÓRIOS até a T009 do backend. Se o formato real dos itens do pedido diferir da proposta, siga o real e registre.

## Ao terminar
Escreva `../relatorios/T003-lote-entregas-e-status.md`, faça o merge para `develop` e **siga para a T004** (D006).
