# Relatório — T004 Acerto do turno, contestação e APK final

**Status final:** CONCLUIDA
**Data:** 2026-11-15

## O que foi feito
- **Contrato real** (S001 do backend, item 8): `GET /api/entregador/acerto`, sem parâmetros (dia atual), devolve `{ extrato, dataReferenciaCaixa, statusCaixa, contestacaoPermitida }`. `POST /api/entregador/entregas/{id}/contestar` não tem corpo. `fromJson` estrito para `AcertoDoEntregador`, `ExtratoAcerto` e `LinhaExtrato`. Nenhum endpoint `PROVISÓRIO`.
- `features/acerto/` com a tela `/acerto` e a **barra inferior Início | Acerto** (`NavigationBar`, com *tooltips*); o logout continua no menu.
  - Totais **só do backend**: total devido, consolidado em recibo e em análise. O app não soma nada (Constituição 5.1); valor `null` → "—".
  - Linhas: cliente, data/hora, status, distância, faixa (`0,0–3,0 km` ou "Fora da área"), valor e selo de situação (ícone + texto).
  - Aviso "Há entregas com valor ainda não definido" quando `possuiValorIndefinido`.
  - Puxar para atualizar; estados carregando, vazio ("Nenhuma entrega finalizada neste turno.") e erro com "Tentar de novo".
- **Caixa ABERTO/REABERTO:** título "Valor parcial do turno" e **Contestar** em linhas `A_ACERTAR`, com dois toques ("Contestar" e depois "Confirmar contestação"). Depois da resposta, o extrato é recarregado e a linha passa a "Em análise" conforme o backend devolve.
- **Caixa FECHADO:** título "Valor final", nenhum Contestar e "Para corrigir algum valor, procure o operador" (E2).
- **Linha EM_REVISAO:** selo "Em análise", sem botão, e o texto "Esta entrega já está em análise" (E1).
- `CAIXA_FECHADO` vindo do servidor mostra "O caixa já foi fechado. Procure o operador." e recarrega o extrato. `REGRA_NEGOCIO_VIOLADA` (já em revisão ou não finalizada) mostra a `message` do servidor e recarrega.
- O botão aparece só quando valem as três condições: `contestacaoPermitida` (do backend), caixa ABERTO/REABERTO e linha `A_ACERTAR` (`podeContestar` em `core/dominio/transicoes.dart`).
- `AcertoRepository` (Api + Fake). O `FakeBackendAcerto` simula o servidor, inclusive os totais (papel do backend), e tem os dois cenários: caixa aberto (padrão) e caixa fechado (`--dart-define=FAKE_CAIXA_FECHADO=true`). As entregas finalizadas no lote do fake entram no extrato.
- `README.md`: credenciais de demonstração do backend (S002 do backend) e passo a passo para gerar o APK com o IP real. A S002 do backend foi respondida como **ACEITA** (só `Status` e `Resposta do agente mobile`).
- **APK de debug final** gerado com `--dart-define=API_URL=http://192.168.0.10:8080` (endereço de exemplo; ver abaixo como gerar com o IP real).

## O que NÃO foi feito (e por quê)
- Trilha completa de contestação (justificativa, histórico), recibo em PDF e pagamento: fora do escopo.
- Escolha de período: só o dia atual, como a tarefa pede. O backend aceita `inicio`/`fim`, mas nenhuma tela usa.

## Arquivos criados/alterados
- `lib/features/acerto/{acerto.dart,data/modelos_acerto.dart,data/acerto_repository.dart,estado/acerto_notifier.dart,ui/acerto_page.dart}`
- `lib/core/fake/fake_backend.dart`, `lib/core/fake/fake_backend_acerto.dart` (novo), `lib/core/providers_core.dart`
- `lib/core/dominio/transicoes.dart` (`podeContestar` com `contestacaoPermitida`)
- `lib/app/rotas.dart` (`/acerto` e a barra inferior)
- `test/features/acerto_test.dart`, `test/core/dominio_test.dart`
- `README.md`

## Verificação
| Comando | Resultado |
| --- | --- |
| `scripts/flutter.sh analyze` | ✅ "No issues found! (ran in 76.1s)" |
| `scripts/flutter.sh test` | ✅ 72 testes, 72 passaram ("All tests passed!"): 66 anteriores e 6 novos. Na primeira rodada, 2 testes falharam porque as últimas linhas do extrato ficavam fora da tela de teste (800×600) e o `ListView` não as montava; o teste passou a usar uma tela mais alta |
| `scripts/flutter.sh build apk --debug --dart-define=API_URL=http://192.168.0.10:8080` | ✅ "Built build/app/outputs/flutter-apk/app-debug.apk" (Gradle 891,1 s; 168 MB). Foi o primeiro build com o volume `agiliza_android_sdk`: NDK e CMake foram instalados uma última vez e passam a ficar guardados no volume |

Testes de regra desta tarefa:
- Contestar só aparece com caixa aberto e linha `A_ACERTAR`; com `contestacaoPermitida=false`, não aparece.
- Caixa FECHADO: "Valor final", nenhum "Contestar" na tela e a orientação.
- Caixa `null` (não aberto): sem Contestar, com orientação.
- EM_REVISAO: "Em análise" e "Esta entrega já está em análise".
- **Nenhuma soma no cliente:** o JSON do teste tem totais que de propósito não batem com a soma das linhas (R$ 123,45 / 67,89 / 4,56), e a tela mostra exatamente esses.
- `null` → "—".
- Contestação em dois toques, com a linha passando a EM_REVISAO.
- `CAIXA_FECHADO` do servidor: mensagem e recarga.

## Como gerar o APK com o IP real
1. `ipconfig` → "Endereço IPv4" do PC na Wi-Fi (ex.: `192.168.0.25`).
2. Backend: `./mvnw spring-boot:run` em `ADS_EduardoCamargo_AgilizaDelivery/agilizadelivery/` (perfil `h2`, porta 8080). Liberar a TCP 8080 no Firewall do Windows (rede privada).
3. `scripts/flutter.sh build apk --debug --dart-define=API_URL=http://192.168.0.25:8080`. Com o volume do SDK já preenchido, os builds seguintes são bem mais rápidos que o primeiro.
4. Instalar `build/app/outputs/flutter-apk/app-debug.apk` (cabo com `adb install -r ...`, ou copiando o arquivo para o celular). PC e celular na mesma Wi-Fi.

## Roteiro de teste manual de ponta a ponta (backend + backoffice + app no aparelho)
Pré-requisitos: backend no perfil `h2` (passo 2 acima); Postman com `agilizadelivery/postman/agiliza-delivery.postman_collection.json` e o environment `agiliza-dev.postman_environment.json` (`baseUrl` = `http://localhost:8080`); Backoffice React aberto (opcional: tudo do operador também pode ser feito pelo Postman); APK instalado com o IP real.

1. **Login.** No app, entrar com `entregador1@agiliza.dev` / `agiliza123`: abre o Início com "Olá, …" e "Offline". Para conferir a recusa de perfil, entrar com `operador@agiliza.dev` / `agiliza123` deve mostrar "Este aplicativo é exclusivo para entregadores". Uma senha errada deve mostrar "E-mail ou senha inválidos".
2. **Online.** Tocar "Ficar online". Na primeira vez, negar a permissão de localização: deve aparecer a explicação e o atalho para as configurações, e o status não muda. Tocar de novo e permitir: o status vira "Online". No Backoffice, o entregador aparece online e a posição se atualiza a cada ~20 s.
3. **Pedidos.** No Postman, pasta **Loja**: "Ligar o simulador de pedidos" (login da loja na pasta Autenticação antes). Novos pedidos surgem a cada ~30 s. Alternativa: pasta **Operação** → "Criar entrega avulsa" + "Marcar pronta para despacho".
4. **Despacho.** No Backoffice (ou Postman, **Operação** → "Despachar lote", com o `motoboyId` do entregador1 e 2 entregas), despachar um lote para o entregador1. Em até ~10 s, o app vibra, mostra "Novo lote: 2 entregas" e o cartão do lote. O status vira "Em rota" e "Ficar offline" fica desabilitado com a explicação.
5. **Lote.** Abrir o cartão: lista na ordem do operador, com valor, forma de pagamento, troco/"Pago online". Abrir uma entrega: endereço, itens, observações, distância e "Seu repasse" (ou "—").
6. **Atalhos.** Na entrega: "Navegar" → Waze e Google Maps abrem com a rota. "WhatsApp" abre a conversa com "Olá, {cliente}! Sou o entregador do {loja}. Estou a caminho com o seu pedido.". Numa entrega sem telefone, o botão fica desabilitado.
7. **Iniciar.** No lote, "Iniciar percurso" → "Confirmar saída": o lote e as entregas viram "Em rota" no app e no Backoffice.
8. **Entregue/Falha.** Entrega 1: "Entregue" → "Confirmar entrega". Entrega 2: "Falha" → "Cliente ausente". Depois da última, o app volta ao Início com "Lote concluído", e o status volta a "Online". No Backoffice, as duas aparecem finalizadas em até 5 s, com a coordenada no histórico.
9. **Acerto.** Aba "Acerto": "Valor parcial do turno", totais do backend e as duas entregas com distância, faixa, valor e "A acertar". (O caixa do dia precisa estar aberto: no Postman, **Operação** → "Abrir caixa", se "Caixa do dia" não existir.)
10. **Contestar.** Na entrega 2: "Contestar" → "Confirmar contestação": a linha passa a "Em análise", sai do total devido e entra em "Em análise". No Backoffice, aparece na fila de revisão. Tentar contestar de novo não é possível (sem botão).
11. **Fechamento.** No Backoffice ou no Postman (**Operação**: "Gerar recibo", "Pagar recibo" e "Fechar caixa"), fechar o caixa do dia.
12. **Valor final.** No app, puxar para atualizar o Acerto: o título vira "Valor final", nenhum botão "Contestar" aparece e surge "Para corrigir algum valor, procure o operador".
13. **Segundo plano e logout.** Com o entregador online, ir para outra app: no Backoffice, a posição para de se atualizar. Voltar: retoma. Menu → "Sair": volta ao login; reabrir o app pede login de novo.

A pasta **Fluxo ponta a ponta** da coleção (passos 01 a 15) faz a mesma sequência só pela API e serve de referência para o que o app deve mostrar a cada passo.

## Verificação manual pendente (aparelho físico)
- O roteiro acima inteiro, em especial: GPS real e permissão; telemetria no painel; vibração do lote novo; links do Waze, do Maps e do WhatsApp; acerto parcial → contestação → "Valor final" depois do fechamento do caixa.
- A instalação do APK de debug no Android 8.0+.

## Desvios conscientes do DVP tocados (D008)
- Nenhum novo nesta tarefa. O acerto é atualizado ao abrir a tela e ao puxar para atualizar (sem push).

## Decisões tomadas (dentro do escopo)
- Caixa `null` (a loja ainda não abriu o caixa do dia): título "Valor parcial do turno", **sem** Contestar e com a orientação ao operador, mais "O caixa do dia ainda não foi aberto pela loja." É o padrão mais restritivo, coerente com o `CAIXA_FECHADO` que o backend devolve nesse caso (S001, item 7).
- O botão Contestar exige `contestacaoPermitida` **e** caixa ABERTO/REABERTO **e** linha `A_ACERTAR`. Na dúvida, mais restritivo.
- Ao contestar, a tela recarrega o extrato em vez de ajustar a linha localmente (sem atualização otimista e sem cálculo no cliente).

## Sugestões/pendências registradas para o backend
- Nenhuma nova. A S002 do backend (credenciais de desenvolvimento) foi respondida como ACEITA.

## Proposta de mudança no DVP (Constituição, Artigo 2.4)
- Nenhuma.

## Dúvidas / bloqueios
- Nenhum.

## Sugestões (não implementadas)
- Botão "Ligar para o cliente" (`tel:`), já citado na T003.
- O APK de debug tem ~167 MB, porque traz as três ABIs e o modo debug. Para distribuir, um build de release (`--split-per-abi`) ficaria bem menor. A assinatura de release está fora deste ciclo.
