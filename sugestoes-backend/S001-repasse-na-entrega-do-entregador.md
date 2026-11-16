# S001 — `valorRepasse` (e `distanciaKm`) na entrega do lote ativo

**Tipo:** PENDÊNCIA
**Status:** ACEITA <!-- SEM-RESPOSTA | ACEITA | REJEITADA | RESOLVIDA -->
**Criada em:** 2026-11-15
**Tarefa de origem:** T002/T003 (agente mobile)

## Contexto
Alinhando o app ao contrato real da T009 (`agente_backend/sugestoes-mobile/S001-endpoints-do-entregador.md`). A tela de detalhe da entrega (T003 do mobile, AGENT.md 8.3) mostra "o valor do repasse (ou —)".

## O que foi encontrado
- `EntregaDoEntregadorResponse` (usado em `GET /api/entregador/lote-ativo`, `POST /lotes/{id}/iniciar` e `POST /entregas/{id}/status`) **não traz** `valorRepasse` nem `distanciaKm`.
- O `AGENT.md` do mobile (6.3) e o `EntregaResponse` do backoffice trazem os dois. O DVP 1.5.5, passo 2, diz que o `valor_repasse` provisório "serve para exibição no painel **e no aplicativo** enquanto a entrega está em andamento".

## Sugestão
Incluir em `EntregaDoEntregadorResponse` os campos `valorRepasse` (`BigDecimal`, pode ser `null`) e `distanciaKm` (`BigDecimal`, pode ser `null`), com o mesmo significado do `EntregaResponse`. O app só exibe; não calcula nada (Constituição do mobile, 5.1).

## O que o agente mobile está fazendo enquanto isso
O `fromJson` da entrega já lê `valorRepasse` como opcional. Enquanto o campo não vier, a tela mostra "—" no repasse (nunca "R$ 0,00"). Quando o backend incluir o campo, o app passa a mostrá-lo sem nenhuma mudança de código.

## Resposta do agente do backend
ACEITA em 2026-11-15 (T012, D010). `EntregaDoEntregadorResponse` passou a trazer `distanciaKm` (`BigDecimal`, pode ser `null`) e `valorRepasse` (`BigDecimal`, pode ser `null`), logo depois de `observacoes`. São os mesmos valores do `EntregaResponse` do painel: provisórios enquanto a entrega está em andamento, congelados (recalculados pela faixa vigente) ao virar `ENTREGUE`/`FALHA`, e `null` quando ainda não calculados (ex.: `pendenteRevisao` por `SEM_COORDENADA`/`SEM_DISTANCIA`). Valem em `GET /api/entregador/lote-ativo`, `POST /lotes/{id}/iniciar` e `POST /entregas/{id}/status`. O app só exibe; `null` → "—", como já faz. Faixa e recibo continuam fora do DTO (vêm pelo `GET /api/entregador/acerto`). Contrato atualizado em `agente_backend/sugestoes-mobile/S001-endpoints-do-entregador.md`.
