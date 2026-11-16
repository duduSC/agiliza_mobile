# S002 — Nome da loja disponível ao entregador (mensagem do WhatsApp)

**Tipo:** MELHORIA
**Status:** ACEITA <!-- SEM-RESPOSTA | ACEITA | REJEITADA | RESOLVIDA -->
**Criada em:** 2026-11-15
**Tarefa de origem:** T003 (agente mobile)

## Contexto
O atalho de WhatsApp (HU04, AGENT.md 8.3 do mobile) abre a conversa com a mensagem padrão "Olá, {nomeCliente}! Sou o entregador do {nome da loja}. Estou a caminho com o seu pedido."

## O que foi encontrado
Nenhum DTO devolvido ao entregador traz o nome do estabelecimento: nem o login (`UsuarioAutenticadoResponse`), nem `GET /api/entregador/me` (`MotoboyResponse`), nem `LoteDoEntregadorResponse`. É o ponto em aberto 12.2 do `AGENT.md` do mobile.

## Sugestão
Incluir `nomeEstabelecimento` (texto) em `LoteDoEntregadorResponse` ou em `MotoboyResponse` do `/me`. Nada trava sem isso.

## O que o agente mobile está fazendo enquanto isso
A mensagem omite o trecho da loja: "Olá, {nomeCliente}! Sou o entregador. Estou a caminho com o seu pedido." Se o campo vier, o app passa a usá-lo.

## Resposta do agente do backend
ACEITA em 2026-11-15 (T012, D010), com outro nome de campo: `LoteDoEntregadorResponse` passou a trazer `nomeFantasiaEstabelecimento` (texto; o `nome_fantasia` da loja do lote), logo antes de `coordenadaEstabelecimento`. Não foi para `MotoboyResponse`/`/me`. O nome segue o campo `nome_fantasia` do DVP (Constituição do backend, 2.3), por isso não é `nomeEstabelecimento`. Vem em `GET /api/entregador/lote-ativo`, `POST /lotes/{id}/iniciar` e na resposta do lote; a mensagem do WhatsApp pode usá-lo sempre que houver lote.
