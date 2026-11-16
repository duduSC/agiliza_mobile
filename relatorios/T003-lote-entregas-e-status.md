# Relatório — T003 Lote, detalhe da entrega, deep links e ENTREGUE/FALHA

**Status final:** CONCLUIDA
**Data:** 2026-11-15

## O que foi feito
- **Contrato real** (S001 do backend + T012): `GET /api/entregador/lote-ativo` (`204` = sem lote), `POST /lotes/{id}/iniciar` (devolve o lote) e `POST /entregas/{id}/status` (devolve a entrega). `LoteDoEntregadorResponse` traz `nomeFantasiaEstabelecimento`; `EntregaDoEntregadorResponse` traz `distanciaKm` e `valorRepasse`. Nenhum endpoint `PROVISÓRIO`.
- `features/lote/ui/lote_page.dart` (`/lote`):
  - lista na ordem de `ordemRota` do operador (o app nunca reordena por conta própria);
  - em cada entrega, cliente, bairro, selo de status (ícone + texto), valor do pedido, forma de pagamento, "Pago online" e "Levar troco para R$ X";
  - estados carregando, vazio ("Nenhum lote no momento") e erro com "Tentar de novo";
  - puxar para atualizar.
- **Iniciar percurso:** só com lote `DESPACHADO`. Toque 1 em "Iniciar percurso", toque 2 em "Confirmar saída".
- `features/lote/ui/entrega_page.dart` (`/lote/entrega/:id`):
  - endereço, complemento, referência e bairro;
  - itens (quantidade × descrição, observação; "Sem itens informados." numa entrega avulsa), observações e motivo da falha;
  - pagamento, distância e "Seu repasse", todos vindos do backend (`null` → "—").
- `core/deep_links/deep_links.dart`:
  - URLs do Google Maps e do Waze exatamente como no AGENT.md 8.3, com o endereço *url-encoded* quando não há coordenada;
  - WhatsApp `https://wa.me/55…?text=…`, com o telefone só em dígitos e o 55 acrescentado quando falta;
  - mensagem "Olá, {cliente}! Sou o entregador do {nomeFantasiaEstabelecimento}. Estou a caminho com o seu pedido.", sem o trecho da loja se o nome não vier;
  - sem telefone válido, o botão WhatsApp fica desabilitado, com *tooltip* e texto explicando;
  - se o `launchUrl` falhar: "Não foi possível abrir o aplicativo".
- **Entregue / Falha** (`acoes_lote.dart`):
  - só em entrega `EM_ROTA`;
  - Entregue: toque 1 no botão, toque 2 em "Confirmar entrega";
  - Falha: toque 1 no botão; toque 2 num motivo rápido ("Cliente ausente", "Endereço não encontrado", "Cliente recusou"), que já envia; ou texto livre de até 100 caracteres com "Confirmar falha", desabilitado sem motivo (RNF11: no máximo dois toques);
  - o envio leva `ocorridoEm`, o horário do toque no relógio de São Paulo sem fuso, capturado antes de qualquer espera, e a `coordenada`: posição atual com no máximo 3 s de espera, senão a última conhecida, senão nenhuma;
  - botões bloqueados durante o envio, sem atualização otimista. Depois da resposta, o lote é recarregado;
  - com `204` (lote encerrado), o app volta para `/inicio` com "Lote concluído";
  - `TRANSICAO_ESTADO_INVALIDA` mostra "Esta ação não é mais possível. Atualizando..." e recarrega o lote. `404 RECURSO_NAO_ENCONTRADO` (lote devolvido pelo operador) também recarrega.
- `LoteRepository` completo (Api + Fake). `FakeBackendLote` simula a máquina de estados: DESPACHADO → EM_ROTA ao iniciar e, com todas as entregas finalizadas, lote CONCLUIDO, entregador ONLINE e `204`. Recusa transições inválidas e FALHA sem motivo com os códigos da S001.

## O que NÃO foi feito (e por quê)
- Mapa dentro do app, sugestão de ordem e reordenação: proibidos (Constituição 4.2).
- Alerta de cancelamento durante o percurso (UC02 A3) e fila offline (UC02 A2): desvios da D008. Sem rede, a ação mostra "Sem conexão. Tente de novo." e não é enfileirada.
- Botão "Ligar" (`tel:`): não está no escopo da tarefa. O `<queries>` com `tel` já existe desde a T001.

## Arquivos criados/alterados
- `lib/core/deep_links/deep_links.dart` (novo)
- `lib/core/fake/fake_backend.dart`, `lib/core/fake/fake_backend_lote.dart` (novo)
- `lib/features/lote/data/lote_repository.dart`, `lib/features/lote/estado/lote_ativo_notifier.dart`, `lib/features/lote/lote.dart`
- `lib/features/lote/ui/{lote_page,entrega_page,acoes_lote}.dart`
- `lib/app/rotas.dart` (`/lote/entrega/:id`)
- `test/core/deep_links_test.dart`, `test/features/lote_test.dart`

## Verificação
| Comando | Resultado |
| --- | --- |
| `scripts/flutter.sh analyze` | ✅ "No issues found! (ran in 77.8s)" |
| `scripts/flutter.sh test` | ✅ 66 testes, 66 passaram ("All tests passed!"): 46 anteriores e 20 novos |

Testes de regra desta tarefa:
- URLs: Maps com e sem coordenada, Waze com e sem, WhatsApp com 10 e 11 dígitos e com 55, sem telefone, mensagem com e sem loja.
- Iniciar só em DESPACHADO, com o segundo toque.
- Entregue/Falha só em EM_ROTA.
- Falha sem motivo não envia (notifier e tela).
- ENTREGUE numa entrega DESPACHADA não é enviado.
- `coordenada` + `ocorridoEm` sem fuso no corpo.
- `TRANSICAO_ESTADO_INVALIDA` recarrega.
- Repasse `null` → "—".
- WhatsApp desabilitado sem telefone e com o nome da loja na mensagem.
- Falha ao abrir app avisa.
- **Critério de aceite completo:** lote DESPACHADO com 2 entregas → iniciar → ENTREGUE + FALHA ("Cliente ausente") → app volta ao início com "Lote concluído" (pelo app inteiro, com o roteador).

## Verificação manual pendente (aparelho físico)
- Os links do Waze, do Google Maps e do WhatsApp abrindo de verdade, com rota até o cliente e conversa com a mensagem pronta. Também com e sem coordenada, e com o app de destino não instalado ("Não foi possível abrir o aplicativo").
- A coordenada real gravada no histórico de status ao marcar ENTREGUE/FALHA (conferir no painel).
- A ergonomia com uma mão: botões de 56 dp, dois toques e teclado na Falha com texto livre.

## Desvios conscientes do DVP tocados (D008)
- UC02 A2 / RNF09: sem fila offline.
- UC02 A3: sem alerta de cancelamento durante o percurso. Se o operador cancelar, a próxima ação dá `TRANSICAO_ESTADO_INVALIDA` e o lote é recarregado, ou o polling de 10 s mostra a entrega CANCELADA.
- Lote novo descoberto por polling, sem push.

## Decisões tomadas (dentro do escopo)
- Na Falha, o toque no motivo rápido é a própria confirmação, para caber em dois toques (RNF11).
- Para não atrasar o toque, a coordenada espera no máximo 3 s pela posição atual. Sem ela, vai a última posição conhecida ou nenhuma (o campo é opcional no contrato).
- O "Seu repasse" e a distância só aparecem formatados. O app não soma nada, nem o total do lote.

## Sugestões/pendências registradas para o backend
- Nenhuma nova. As S001 e S002 do mobile foram atendidas pela T012 do backend e usadas aqui.

## Proposta de mudança no DVP (Constituição, Artigo 2.4)
- Nenhuma.

## Dúvidas / bloqueios
- Nenhum.

## Sugestões (não implementadas)
- Botão "Ligar para o cliente" (`tel:`) ao lado do WhatsApp, para clientes sem WhatsApp.
