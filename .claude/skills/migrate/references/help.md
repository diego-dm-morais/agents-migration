# Ajuda do /migrate

Texto exibido por `/migrate help` e na primeira resposta de uma sessão sem migração em andamento. Exiba tal qual, sem resumir.

## Comandos

| Comando | O que faz |
|---|---|
| `/migrate init` | Prepara o projeto. Pergunta só o que falta em `MIGRATION.md` (origem, destino, tipo de unidade, idiomas). Cria o snapshot da origem, confere o pin (`pin OK`), lista as unidades candidatas e grava no backlog só as que você confirmar. |
| `/migrate` ou `/migrate status` | Mostra o estado de cada etapa de cada unidade e o prazo. Não altera arquivos. |
| `/migrate <unidade>` | Roda as etapas em ordem (extract, spec, plan, tasks) até a unidade ficar READY ou até uma parada. O build só roda se você pedir. |
| `/migrate <unidade> <etapa>` | Roda só uma etapa. As etapas anteriores precisam estar OK. |
| `/migrate ask` ou `/migrate ask <unidade>` | Responde às decisões pendentes, ou seja, as escolhas que o código legado não decide. |
| `/migrate help` | Mostra esta ajuda. |

## Etapas (valores de `<etapa>`) e agente dono

1. `extract`: behavior-extractor (Eduardo).
2. `spec`: spec-writer (Sofia).
3. `plan`: migration-planner (Paula).
4. `tasks`: task-decomposer (Tiago).
5. `build`: implementer (Isabela).
6. `review`: parity-reviewer (Rafael). Faz rodadas de revisão e correção.
7. `doc`: doc-writer (Daniela).

## Regras

- O id da unidade precisa casar com `^[a-z0-9]+(-[a-z0-9]+)*$`.
- Depois de `/clear`, rode `/migrate` de novo para retomar. O estado fica nos artefatos.
- Os limites `limit_dispatch`, `limit_review_rounds` e `limit_fix_rounds` e o `deadline` ficam em `docs/migration/MIGRATION.md`.
- Para uma execução sem segundo plano, use `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`.
- Commit, push e PR ficam fora do `/migrate`. Só saem se você pedir.

## Como informar as unidades

Cada unidade tem uma plataforma: `backend`, `web` ou `mobile`.

- Backend, direto: método e caminho da operação, por exemplo `POST /v1/users`. O id da unidade vira `post-v1-users`. O Eduardo acha a rota e o handler no código da origem.
- Web ou mobile, direto: a rota ou o arquivo da tela, por exemplo `src/app/checkout/payment/page.tsx` ou `lib/screens/checkout_payment.dart`. O id vira `checkout-payment`. O Eduardo acha a tela, o roteador e os estados no código da origem.
- Por collection ou design: export do Postman, OpenAPI ou Apidog (backend), ou Figma e storyboard (frontend). Serve só para listar operações, telas e nomes. Os exemplos nunca são fonte de comportamento (o código no pin é). Tokens e credenciais viram `<redacted>`.

## Estados de cada etapa

MISSING, DRAFT, BLOCKED, INVALID, STALE e OK.

Você também pode chamar um agente direto, pelo nome ou apelido, mas o caminho normal é pelo `/migrate`.

A documentação completa está em `.claude/docs/` (`fluxo.md` tem as receitas e os limites).
