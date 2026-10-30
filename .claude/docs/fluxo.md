# Fluxo de migração

Este documento descreve o fluxo do toolkit de migração de código: as etapas, o dono de cada uma, os estados, a política de decisões, a escada de evidência de paridade, as estratégias, as receitas e os limites.

Cada fato cita o arquivo onde está. Os caminhos são relativos a `.claude/`.

## Idioma

Regras de `CLAUDE.md`, seção `Language`:

- Respostas ao usuário: pt-BR, 100%.
- Documentos gerados no projeto (`doc_language` em `docs/migration/MIGRATION.md`): pt-BR, 100%.
- Comentários de código: inglês. Comentários dentro de um achado de revisão, de um documento ou de outro artefato: pt-BR.
- Mensagens de commit, prompts de agentes e skills, e o próprio `CLAUDE.md`: inglês.
- Artefatos de migração: idioma de `artifact_language` (pt-BR neste projeto).
- Identificadores, literais, caminhos, `path:line`, SQL, valores de enum e mensagens de erro não são traduzidos.

## Etapas e estados

### Ordem e comandos

A ordem é `extract`, `spec`, `plan`, `tasks`, `build`, `review` e `doc` (`skills/migrate/references/stages.md`, seção `Order and states`).

Formas do comando `/migrate` (`skills/migrate/SKILL.md`, seção `Arguments`):

- `/migrate` ou `/migrate status`: mostra o estado de todas as unidades.
- `/migrate init`: prepara o projeto.
- `/migrate ask [unidade]`: responde às decisões pendentes.
- `/migrate <unidade>`: roda as etapas até READY, ou até uma parada.
- `/migrate <unidade> <etapa>`: roda só essa etapa, depois que as etapas anteriores estão OK.

READY quer dizer que `extract`, `spec`, `plan` e `tasks` estão OK. `build`, `review` e `doc` vêm depois de READY. Depois de READY, `build` só roda se o usuário pediu (`skills/migrate/SKILL.md`, passo 2 e seção `Stage loop`; `stages.md`).

Quem decide o estado é o `check.sh` (`skills/migrate/scripts/check.sh`). Subcomandos: `status [unidade]`, `pin`, `cites <arquivo>`, `ids [unidade]`, `adr [unidade]`, `hash <arquivo>` e `scope <unidade>` (cabeçalho do script). O orquestrador roda `status` antes de cada decisão e depois de cada agente (`skills/migrate/SKILL.md`, seção `Commands`).

### Donos por etapa

Fonte: `skills/migrate/references/stages.md`, seção `Stage criteria`. Os nomes entre parênteses são os apelidos de `CLAUDE.md`, seção `Toolkit`.

| Etapa | Dono | Saída | OK quando (resumo) |
|---|---|---|---|
| `extract` | behavior-extractor (Eduardo) | `<unidade>/extraction.md` | cada ponto de entrada rastreado; cada `BR-` com citação; gaps listados; nenhuma citação inválida; seção de DEC com citação, ou `none found` |
| `spec` | spec-writer (Sofia) | `<unidade>/spec.md` | cada `BR-` coberto por um `FR-`; `TS-` e `NG-` escritos; nenhum `PEND-` bloqueante aberto |
| `plan` | migration-planner (Paula) | `<unidade>/plan.md` e um ADR por DEC em `docs/migration/adr/` | desenho-alvo; mapeamento de construções; versões de dependências com fonte; `ID-`; cada `FR-` no `Trace`; `check.sh adr <unidade>` OK |
| `tasks` | task-decomposer (Tiago) | `<unidade>/tasks.md` | `T-` em ordem de dependência, cada um com tipo, dependências, arquivos, referências e comando de validação; cada `FR-` coberto |
| `build` | implementer (Isabela) | código, testes, status e evidência das tarefas | cada tarefa `done` com `evidence:`; cada arquivo listado existe |
| `review` | parity-reviewer (Rafael) | `<unidade>/review.md` | `status: ok` só sem `RV-` aberto ou bloqueado; `scope_hash` igual ao escopo atual do código |
| `doc` | doc-writer (Daniela) | `<doc_root>/<unidade>.md` | tabela de fontes igual aos artefatos, aos ADR e ao escopo atuais |

Os tipos de tarefa são `capture`, `setup`, `test`, `impl` e `verify`. O formato de cada artefato está em `skills/migrate/references/templates.md`.

Cada etapa grava só o próprio artefato. Código é escrito só pelo `build` (`stages.md`, seção `Rules that apply to every stage`).

### Artefatos e MIGRATION.md

Os artefatos ficam em `docs/migration/<unidade>/`: `extraction.md`, `spec.md`, `plan.md`, `tasks.md` e `review.md`. Os ADR ficam em `docs/migration/adr/`, um arquivo por DEC. O doc da unidade vai para `doc_root` (por padrão, `docs`). O código e os testes ficam em `target_root`, e só o build os escreve. Cada artefato começa com `status: draft`, com as chaves `unit` e `stage` (`skills/migrate/references/templates.md`).

`docs/migration/MIGRATION.md` guarda os parâmetros do projeto: a origem (`source_language`, `source_version`, `source_repo`, `source_ref`, `source_sha`, `source_snapshot`, `source_root`), o destino (`target_language`, `target_version`, `target_root`), `doc_root`, `unit_kind`, os idiomas (`artifact_language`, `doc_language`) e os três limites, além do prazo (`deadline`: `none` ou `AAAA-MM-DD`). Traz também as convenções do alvo, com as bibliotecas permitidas e proibidas, e o `## Backlog`. O modelo está em `skills/migrate/references/templates.md`.

Os campos `upstream_*` e `scope_hash` guardam hashes calculados por `check.sh hash` e `check.sh scope`. Ninguém os digita à mão (`skills/migrate/references/templates.md`).

### Estados

Fonte: `stages.md`, seção `Order and states`. O `check.sh` calcula o estado (funções `check_artifact`, `build_line`, `review_line` e `doc_line`).

| Estado | Significado |
|---|---|
| MISSING | o arquivo não existe |
| DRAFT | `status: draft`, ou trabalho pendente |
| BLOCKED | `status: blocked`, `PEND-` bloqueante aberto ou tarefa bloqueada |
| INVALID | falhou uma checagem estrutural (ids, cobertura, citações, chaves, seção de DEC ou ADR) |
| STALE | o upstream ou o código mudou depois da escrita do artefato |
| OK | `status: ok` e todas as checagens passaram |

Prioridade quando mais de um vale: INVALID, STALE, BLOCKED, DRAFT, OK.

### Despacho e roteamento

Dono por estado (`skills/migrate/references/routing.md`, seção `Owner by state`):

- `extract` MISSING, DRAFT ou INVALID: behavior-extractor. INVALID costuma ser citação ruim, id duplicado ou seção de DEC ausente.
- `spec` MISSING, DRAFT, INVALID ou STALE: spec-writer. `spec` BLOCKED: nenhum dono; roda o fluxo de perguntas.
- `plan` MISSING, DRAFT, INVALID ou STALE: migration-planner. INVALID também quando `check.sh adr` acusa DEC sem ADR.
- `tasks` MISSING, DRAFT, INVALID ou STALE: task-decomposer.
- `build` DRAFT ou INVALID: implementer. `build` BLOCKED: nenhum dono; o relatório traz os ids e o motivo.
- `review` MISSING, STALE ou INVALID: parity-reviewer. `review` BLOCKED: nenhum dono; o usuário decide.
- `doc` MISSING, DRAFT, INVALID ou STALE: doc-writer.

Como o orquestrador despacha (`skills/migrate/SKILL.md`, passos 4 a 6): usa a ferramenta Agent com `subagent_type` igual ao nome do dono. O prompt traz o id da unidade, a etapa, o caminho do artefato, o caminho de `docs/migration/MIGRATION.md`, a linha de estado que causou o despacho e a frase que pede a mensagem final no contrato de conduta. Espera o agente terminar, roda `status` de novo e lê a linha `NEEDS`.

Quem um agente pode pedir em `NEEDS` (`routing.md`, seção `Allowed NEEDS owners by worker`):

| Agente | Pode pedir |
|---|---|
| behavior-extractor | user |
| spec-writer | behavior-extractor (fato técnico faltante), user |
| migration-planner | spec-writer, behavior-extractor, user |
| task-decomposer | migration-planner, spec-writer, user |
| implementer | task-decomposer, migration-planner, spec-writer (só enquanto nenhuma tarefa começou), user |
| parity-reviewer | implementer (rodada de correção) |
| doc-writer | user |

Outro dono é reportado e a unidade para (`routing.md`). Um `NEEDS: user` cujo `verified:` não cita caminho e linha do legado volta ao behavior-extractor, e não chega ao usuário (`routing.md`).

`NEEDS` é a última linha da mensagem final de cada agente (`skills/migration-conduct/SKILL.md`, seção 12). O orquestrador a trata assim (`skills/migrate/SKILL.md`, passo 6): `none` segue para o próximo passo; `<dono>: <fato>`, com dono permitido, despacha esse dono uma vez; `user: <pergunta>` para a unidade e leva a pergunta ao `ask`; qualquer outro texto para e relata.

Congelamento: se alguma tarefa de `tasks.md` saiu de `pending`, o build começou. Então `spec-writer`, `migration-planner` e `task-decomposer` não são despachados. O orquestrador reporta e para (`SKILL.md`, passo 3; `stages.md`, seção `Rules that apply to every stage`).

Chamada direta de um agente só acontece quando o usuário pede pelo nome ou apelido (`CLAUDE.md`, seção `Toolkit`).

## Política de decisões

Toda pergunta aberta cai em um de três tipos. Classifique antes de qualquer outra ação (`skills/migrate/references/ask.md`, seção 2). Antes de classificar, veja se o código legado responde: se responde, é fato (`ask.md`).

- **Fato.** O que o código, a biblioteca ou o runtime faz, inclusive o comportamento legado. Responda lendo ou executando a fonte no pin. Registro: `fact: <evidência>`. Fato nunca vai ao usuário.
- **Padrão de conduta.** Ponto que a conduta já decide: manter o comportamento da origem (regra 3), manter bug da origem como `known-issue` (`skills/migration-conduct/SKILL.md`, seção 5), copiar mensagens de erro observáveis (seção 1). Registro: `default by conduct rule <n>, reversible, <data>`, com a regra, a evidência e a nota de que o usuário pode mudar. Nunca pergunte ao usuário por ele.
- **Escolha do usuário.** Tudo que a conduta não decide: outro tipo ou formato de entrada, outra classe ou categoria de erro, correção de bug da origem, remoção de comportamento, nova dependência. Só esses são perguntados. Registro: `resolved by user, <data>`.

Ordem para responder um fato (`ask.md`, seção 3). Pare na primeira resposta encontrada:

1. Código implementado: a fonte no commit do pin (`path:line @sha7`) e o código-alvo já escrito.
2. Fonte da dependência na versão fixada: lockfile, código vendorizado ou cache local. Cite `path:line`.
3. Documentação oficial. Cite a URL.
4. `MIGRATION.md` e os artefatos já escritos.

Rodar a fonte para responder a um fato só é permitido a partir de uma cópia fora do snapshot, ou com flags que impedem a escrita de cache no snapshot (ex.: `PYTHONDONTWRITEBYTECODE=1`). A cópia que roda a fonte fica fora do snapshot, não dentro dele. Registre o comando e a saída. Fonte: `skills/migrate/references/ask.md`, seção 3; também `skills/migration-conduct/SKILL.md`, seção 6, e `skills/tdd/references/source-parity.md`, passo 2.

Perguntas (`ask.md`, seções 4 e 5):

- Pergunte só escolhas que mudam o que é construído. Escolha sem efeito no resultado vira `PEND` com `blocking: no`.
- Cada pergunta traz `verified:` (caminhos, linhas, URLs e saídas conferidos) e `why not in the sources:`. Pergunta sem `verified:` não é enviada.
- Pergunta sobre comportamento que o código legado implementa não é feita. A resposta é o `path:line @sha7` que o mostra (`ask.md`).
- Até 4 perguntas por chamada de AskUserQuestion. A recomendada vem primeiro, marcada `(Recommended)`.
- O orquestrador não grava artefato e não decide escolha do usuário. Ele entrega cada resolução ao dono: spec-writer para `PEND`, migration-planner para `ID`. O dono grava com o tipo da resolução.

Lacunas e conflitos (`skills/migration-conduct/SKILL.md`, seção 4):

- Fato técnico faltante (campo, tipo, ordem de declaração, status de resposta): reabre a extração. Não para a cadeia.
- Regra de negócio que a fonte não resolve: `NEEDS: user: <pergunta, entre aspas>`. Não invente a regra.
- Escolha técnica que a fonte não define: use boa prática, marque como `deviation`, com motivo e fonte. Não apresente como regra da origem.
- Conflito entre duas fontes, na ordem:
 1. decisão do usuário datada em `MIGRATION.md` ou na spec: segue;
 2. a fonte no commit do pin resolve: constrói o que a fonte faz, cita e rotula `Legacy-derived`;
 3. senão: tarefa `blocked`, com os dois lados citados.

Regras obrigatórias de conduta (`skills/migration-conduct/SKILL.md`, seção 0). Números mantidos:

1. Sem alucinação. Toda afirmação sobre o comportamento da origem cita `path:line @sha7`, aberto nesta execução. Fato de biblioteca cita a URL oficial ou o código da dependência na versão fixada.
2. Sem regra de negócio inventada. Regra é o que o código implementado faz. `BR-` sem citação, ou `FR-` sem `Source: BR-`, é defeito. `check.sh` rejeita os dois.
3. Documentação fiel. Documente o comportamento como o código faz, com os bugs. Não mude o comportamento para seguir boa prática.
4. A fonte primária é o código implementado. Spec e docs existentes são contexto.
5. Docs sincronizados. O documento da unidade guarda os hashes das fontes. Mudança no código ou num artefato-fonte deixa o documento STALE.
6. Investigar antes de perguntar, nesta ordem: código; fonte da dependência; documentação oficial.
7. Nenhuma pergunta irrelevante. Padrão que não muda o resultado vira registro com `blocking: no`.
8. Cada pergunta diz o que foi checado e por que a resposta não está nas fontes.
9. Pergunta bloqueante sem resposta para a unidade com `NEEDS: user: <pergunta, entre aspas>`. Nunca escolha o comportamento sozinho.
10. Fidelidade ao legado. O código legado é a fonte da verdade: seu comportamento e suas decisões são preservados, mesmo quando contrariam boa prática ou padrões recomendados do alvo. Não se muda o legado para seguir boa prática por iniciativa própria. Cada decisão legada que contraria boa prática vira um ADR, com a razão de manter o comportamento (seção 13).

## Escada de evidência de paridade

Fonte: `skills/migration-conduct/SKILL.md`, seção 3.

| Nível | Evidência | Uso |
|---|---|---|
| L0 | trecho da fonte `path:line`, lido nesta execução | cada regra extraída |
| L1 | casos derivados: cada ramo, limite e caminho de erro tem uma entrada de teste | testes do alvo |
| L2 | golden: saída registrada ao rodar a fonte com as mesmas entradas | testes de caracterização |
| L3 | execução diferencial: fonte e alvo recebem as mesmas entradas e os resultados são comparados | alegação de paridade |

Regras:

- Relate o maior nível atingido por unidade.
- L1 escrito pelo mesmo agente que escreveu o código-alvo não prova paridade sozinho.
- Paridade só se afirma com evidência desta execução. Sem ela, escreva `parity not proven` e nomeie o gap aberto (`skills/migration-conduct/SKILL.md`, seção 1).
- Cada armadilha encontrada se fixa com teste no nível indicado (`skills/migration-patterns/SKILL.md`, seção 1). Fluxo golden: `skills/tdd/references/source-parity.md`.

## Estratégias de migração

Fonte: `skills/migration-patterns/SKILL.md`, seção 2. A skill lista só estas três formas. A forma é escolhida por unidade, na seção `Target design` do `plan.md`. A evidência de paridade é a mesma nas três.

- **Strangler fig** (figueira estranguladora): o alvo substitui a unidade da origem aos poucos, com os dois sistemas convivendo, nas costuras do sistema legado. Use quando as unidades são independentes e cada uma pode ser trocada e revertida sozinha. Origem citada: martinfowler.com/bliki/StranglerFigApplication.html. O roteador, o proxy e a reversão unitária são desenho da skill, não da página.
- **Branch by abstraction** (abstração por ramificação): põe uma abstração na frente do comportamento da origem, move os chamadores para ela, constrói a implementação-alvo atrás dela e troca os chamadores aos poucos. Use quando os chamadores não podem mudar todos de uma vez. Origem citada: martinfowler.com/bliki/BranchByAbstraction.html.
- **Parallel run** (execução paralela; o termo *shadow* não aparece na skill): origem e alvo recebem a mesma entrada. A resposta da origem é devolvida, a do alvo é comparada e as diferenças são registradas. Use quando resposta errada é cara e os efeitos colaterais do alvo podem ser suprimidos. A skill define essa forma sem citação. Alegar paridade com ela exige L3.

## Receitas

### Uma unidade de ponta a ponta

1. Rode `/migrate status`. Sem `docs/migration/MIGRATION.md`, o `check.sh` mostra `project MISSING`. Nesse caso, rode `/migrate init`.
2. `/migrate init` (`skills/migrate/references/intake.md`): pede só o que falta, inclusive o prazo (opcional). Cria o snapshot fora do repositório-alvo, por padrão em `../<nome-do-alvo>-source`, com `git checkout --detach` no ref. Grava `source_sha` e `source_snapshot`. Roda `check.sh pin` até sair `pin OK`. Monta o backlog com behavior-extractor em modo `survey` e grava as unidades confirmadas em `## Backlog`.
3. `/migrate <unidade>`: roda `extract`, `spec`, `plan` e `tasks`, nessa ordem. Em cada etapa: `status`, despacha o dono, espera, roda `status` e lê a linha `NEEDS` (`skills/migrate/SKILL.md`, seção `Stage loop`).
4. Se a etapa para em `NEEDS: user` ou spec BLOCKED, rode `/migrate ask <unidade>`. O fluxo junta os `PEND` sem `resolution` em `spec.md` e os `ID` com `status: proposed` em `plan.md` (`ask.md`, seção 1). Depois rode `/migrate <unidade>` de novo (`ask.md`, seção 6).
5. Com READY, rode `/migrate <unidade> build` só se o usuário pediu. Depois, `/migrate <unidade> review`: o parity-reviewer escreve a rodada. Se a linha for `NEEDS: implementer: <RV abertos>`, o implementer corrige, o `review` vira STALE e começa nova rodada. `/migrate <unidade> doc` só roda com review OK.
6. Reporte a unidade, as etapas rodadas, os estados finais, os itens abertos e cada linha `NEEDS` (`skills/migrate/SKILL.md`, seção `Rules`). Não diga que a unidade está pronta enquanto o doc estiver STALE.
7. Depois de `/clear`, rode `/migrate` de novo para retomar (`skills/migrate/SKILL.md`).

### Mesma linguagem (upgrade de versão ou troca de framework)

Não há receita no toolkit para esse caso. O item está em `Pendências`.

### Lote de unidades com orquestração dinâmica

Não há receita no toolkit para lote. O item está em `Pendências`. Hoje o despacho usa `subagent_type` com o nome do dono (`skills/migrate/SKILL.md`, passo 4), e o termo `agentType` não aparece no toolkit.

### Unidades em paralelo

Hoje as unidades rodam uma de cada vez: o orquestrador despacha um agente e espera o resultado antes do próximo passo (`skills/migrate/SKILL.md`, passo 5). Unidades em paralelo só são seguras se não dividem manifestos: o `## Backlog` de `docs/migration/MIGRATION.md`, o manifesto de dependências do alvo (por exemplo `package.json`, `go.mod`, `pom.xml`, `Cargo.toml`, `pyproject.toml`, `pubspec.yaml` ou `.csproj`, citados nas descrições das skills de linguagem) e os arquivos listados em `files:` das tarefas. Esse é um critério de desenho. O paralelismo não existe no toolkit (ver `Pendências`).

### Quando a fonte muda: pin, snapshot e STALE

Estados do pin (`check.sh pin`, função `pin_line`):

- `pin OK <sha7>`: o HEAD do snapshot é o `source_sha`.
- `pin INVALID head=<sha7> source_sha=<sha7>`: o HEAD é diferente do `source_sha`.
- `pin MISSING snapshot=<caminho>`, `pin INVALID source_sha-absent` ou `pin INVALID snapshot-not-a-git-checkout`: snapshot ou `source_sha` ausente.

Com pin diferente de `pin OK`:

- A linha de pin abre toda saída de `status` (`check.sh`).
- O migration-planner para com `NEEDS: user: <saída do pin, entre aspas>` (`agents/migration-planner.md`).
- Toda afirmação que depende da fonte fica bloqueada até o pin bater (`skills/migration-conduct/SKILL.md`, seções 2 e 11).

Para trocar o snapshot, repita a criação de `skills/migrate/references/intake.md` (clone sem checkout, `checkout --detach` do novo ref, `rev-parse HEAD`). Grave o novo `source_sha` e rode `check.sh pin` até `pin OK`.

Efeitos da mudança no estado dos artefatos (`check.sh`):

- Extração: citação com sha7 diferente do `source_sha` deixa a extração INVALID (`sha-mismatch`, função `cites_bad`). Dono: behavior-extractor (`routing.md`).
- Spec, plan e tasks: STALE quando o hash do upstream muda (`check_artifact`). Donos: spec-writer, migration-planner e task-decomposer.
- ADR: a plan fica INVALID quando `check.sh adr` acusa problema (`adr_issues`). A doc fica STALE quando o hash de um ADR muda (`doc_line`).
- Review: STALE quando o `scope_hash` muda, ou seja, quando os arquivos das tarefas `done` mudam (função `scope_hash`). Trocar só o sha não muda esse hash.
- Doc: STALE quando o hash de um artefato-fonte, de um ADR ou o `scope_hash` muda (`doc_line`). Dono: doc-writer.

Se uma tarefa já saiu de `pending`, spec, plan e tasks não rodam de novo. O orquestrador reporta e para (`skills/migrate/SKILL.md`, passo 3; `stages.md`, seção `Rules that apply to every stage`).

### Pendências

- Mesma linguagem (upgrade de versão ou troca de framework): não existe no toolkit. O que existe: `MIGRATION.md` tem `source_version` e `target_version` como chaves separadas, e não há chave de framework (`skills/migrate/references/templates.md`). A skill da linguagem é carregada pelo nome, a da origem para ler e a do alvo para escrever, e o toolkit não diz o que fazer quando as duas são a mesma (`skills/migration-conduct/SKILL.md`, seção 10). Falta definir a chave de framework, a regra para a skill repetida e as evidências desse caso. Paridade, níveis de evidência e formas de migração valem sem mudança (`skills/migration-conduct/SKILL.md`, seções 1 e 3; `skills/migration-patterns/SKILL.md`, seção 2).
- Lote de unidades com orquestração dinâmica (workflow com `agentType`): não existe no toolkit. A regra de um agente por vez (`skills/migrate/SKILL.md`, passo 5) precisa mudar antes de qualquer lote paralelo. Nenhum agente tem a ferramenta `Agent` em `tools`: um agente não despacha outro, ele devolve `NEEDS` e quem despacha é o orquestrador (`skills/migrate/references/routing.md`, seção `Allowed NEEDS owners by worker`). Em execução por script, `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1` faz cada agente terminar antes do próximo passo (`skills/migrate/SKILL.md`, seção `Rules`). Os limites valem por unidade e por etapa (`skills/migrate/references/routing.md`, seção `Dispatch limits`), e um lote não os altera.
- Unidades em paralelo: não existe no toolkit. Depende da mudança acima e do critério de manifestos da seção `Unidades em paralelo`.
- Aprovação da troca de `source_sha` e destino das unidades já migradas quando o pin muda: o toolkit não define.
- Fluxo para marcar um ADR como `superseded`: não existe no toolkit. A conduta diz que só o usuário muda o status, com `superseded_by` e data (`skills/migration-conduct/SKILL.md`, seção 13), mas nenhum comando ou agente faz isso.

## Limites e parâmetros

Os três limites são chaves do frontmatter de `docs/migration/MIGRATION.md` (`skills/migrate/references/templates.md`). Os valores padrão vêm de `skills/migrate/references/intake.md`. O usuário muda os valores só se pedir (`intake.md`).

| Parâmetro | Padrão | Limita |
|---|---|---|
| `limit_dispatch` | 2 | despachos do mesmo dono numa etapa, contando a primeira execução e cada execução após um `NEEDS` (`routing.md`) |
| `limit_review_rounds` | 3 | rodadas do parity-reviewer por unidade (`routing.md`) |
| `limit_fix_rounds` | 2 | despachos de correção do implementer por unidade (`routing.md`) |

### Prazo do projeto

`deadline` no frontmatter de `docs/migration/MIGRATION.md` guarda o prazo do projeto: `none`, quando não há prazo, ou `AAAA-MM-DD`. O `/migrate init` pergunta uma vez, com "Sem prazo" como opção recomendada (`skills/migrate/references/intake.md`, item 5). Com prazo, os agentes o tratam como prioridade: o planner registra a data-alvo e o caminho crítico em `## Deadline`, o task-decomposer ordena esse caminho primeiro, o implementer segue essa ordem e o parity-reviewer mantém a severidade dos achados. Prazo nenhum autoriza pular teste, rodar o gate com atalho ou mudar comportamento legado (`skills/migration-conduct/SKILL.md`, seção 4).

Se o prazo não cabe no escopo da unidade, o agente para com `NEEDS: user` e três opções: reduzir o escopo, estender o prazo ou manter os dois. Prazo vencido aparece como `OVERDUE` no `status` e no relatório, e não bloqueia a unidade (`skills/migrate/references/routing.md`, seção Deadline).

`check.sh deadline` imprime uma linha: `deadline none days=-`, `deadline <data> days=<n>` ou `deadline <data> days=<n> OVERDUE`. Data inválida dá `deadline INVALID value=<valor>`.

Regras de uso:

- Ao atingir um limite, pare e reporte o estado e os itens abertos. Não aumente o limite (`routing.md`).
- Parada por limite: estado BLOCKED sem dono, ou INVALID ou STALE depois do limite (`skills/migrate/SKILL.md`, passo 7).
- Rodada de revisão no limite: o parity-reviewer não escreve nada e reporta os `RV` abertos (`agents/parity-reviewer.md`).
- Build: o implementer roda de novo, uma vez, quando sobram tarefas `pending` e não há `NEEDS`, dentro de `limit_dispatch` (`skills/migrate/SKILL.md`, seção `Build`).
- Tarefa `blocked` não para as tarefas que não dependem dela (`skills/migrate/SKILL.md`, seção `Build`; `skills/migration-conduct/SKILL.md`, seção 11).
