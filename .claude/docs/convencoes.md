# Convenções

Esta página reúne as convenções do toolkit de migração: nomes, idiomas, frontmatter, estilo, tamanhos, marcadores, onde cada regra mora, e ids e estados. Ela serve para quem usa ou mantém o toolkit.

Cada fato traz, entre crases, o arquivo onde está. Não citamos número de linha, porque ele muda a cada edição. Citamos o arquivo e, quando ajuda, a função ou a seção. Os caminhos são relativos a `.claude/`, salvo quando dizem outra coisa.

## Nomes

Nomes são os rótulos fixos que o toolkit usa para agentes, skills e comandos. Use sempre o mesmo nome, em todo lugar.

### Agentes

Cada agente tem um nome técnico, sem o sufixo `agent`. Ele também tem um **alias**, um nome humano usado para conversar. O campo `description` de cada agente começa com o alias, no formato `Alias: <nome>.`

| Nome (`name`) | Alias | Etapa que despacha |
|---|---|---|
| `behavior-extractor` | Eduardo | extract |
| `spec-writer` | Sofia | spec |
| `migration-planner` | Paula | plan |
| `task-decomposer` | Tiago | tasks |
| `implementer` | Isabela | build |
| `parity-reviewer` | Rafael | review |
| `doc-writer` | Daniela | doc |

Fontes: `agents/*.md` (campos `name` e `description`); etapas e donos em `skills/migrate/references/stages.md`.

Os agentes são despachados por `/migrate`. Você chama um agente direto só quando pede, pelo nome ou pelo alias (`CLAUDE.md`).

### Skills

Uma **skill** é um pacote de instruções que o Claude carrega quando precisa de um método. O nome de cada skill fica em minúsculas e é igual ao nome da pasta em `skills/`.

| Skill | Papel | Quem a carrega |
|---|---|---|
| `migrate` | orquestrador da migração | o usuário, com `/migrate` |
| `migration-conduct` | regras compartilhadas dos agentes, decisões legadas (DEC e ADR) | os sete agentes, por pré-carga |
| `migration-patterns` | armadilhas entre linguagens | `behavior-extractor`, `migration-planner`, `parity-reviewer` |
| `tdd` | método de teste | `implementer`, `task-decomposer` |
| `doc-writing` | método de escrita da documentação | `doc-writer` |
| `golang`, `java`, `python`, `nodejs`, `typescript`, `javascript`, `dotnet`, `rust`, `flutter` | prática por linguagem | o agente, pelo nome da linguagem da fonte ou do destino |

Fontes: `skills/*/SKILL.md`; lista de skills de linguagem em `CLAUDE.md`; carga pelo nome em `skills/migration-conduct/SKILL.md`, seção 10; pré-carga em `agents/*.md`, campo `skills`.

### Comando

`/migrate` aceita estes argumentos (`skills/migrate/SKILL.md`, e campo `argument-hint`):

- vazio ou `status`: mostra o estado de todas as unidades;
- `init`: prepara o projeto;
- `ask` ou `ask <unit>`: responde às decisões pendentes;
- `<unit>`: leva a unidade pelas etapas até READY ou até uma parada;
- `<unit> <etapa>`: roda só essa etapa.

Um **id de unidade** segue a regex `^[a-z0-9]+(-[a-z0-9]+)*$` (`skills/migrate/SKILL.md`). Uma regex é um padrão de texto que a ferramenta confere. A função `valid_unit` em `skills/migrate/scripts/check.sh` não aplica essa regra por completo: ela aceita `a--b`, que a regex rejeita.

### Pendências

## Idiomas

O idioma de cada tipo de texto segue a regra de `CLAUDE.md`, na seção "Language".

| Texto | Idioma |
|---|---|
| Respostas ao usuário | pt-BR |
| Docs geradas no projeto migrado (`doc_language`, em `docs/migration/MIGRATION.md`) | pt-BR |
| Comentários no código | inglês |
| Comentários dentro de um achado de revisão, de um doc ou de qualquer artefato | pt-BR |
| Mensagens de commit | inglês |
| Prompts de agentes e skills, e o próprio `CLAUDE.md` | inglês |
| Artefatos de migração (`artifact_language`) | pt-BR neste projeto |

Nunca se traduzem: identificadores, literais, caminhos, `path:line`, SQL, valores de enum e mensagens de erro (`CLAUDE.md`). As chaves de máquina (`Result:`, `Written:`, `NEEDS:`, chaves de frontmatter e ids) também ficam como estão. A prosa que vem depois delas segue o idioma da seção.

Notas:

- `skills/migration-conduct/SKILL.md`, seção 9, repete a regra. Para comentários de achado, doc e artefato, ela usa `artifact_language`, e não pt-BR fixo. Neste projeto, os dois valem pt-BR.
- `CLAUDE.md` não define o idioma de `.claude/docs/`, a pasta deste documento. Os textos dessa pasta são em pt-BR.

## Frontmatter

**Frontmatter** é o bloco de metadados no topo de um arquivo. Ele fica entre as duas primeiras linhas `---`. As chaves abaixo são as que os arquivos usam hoje.

### Skills (`skills/<nome>/SKILL.md`)

| Chave | Onde aparece | Valor |
|---|---|---|
| `name` | 21 skills | igual ao nome da pasta |
| `description` | 21 skills | texto que diz quando usar a skill |
| `user-invocable` | 4 skills | `false`: `doc-writing`, `migration-conduct`, `migration-patterns`, `tdd` |
| `disable-model-invocation` | `migrate` | `true`: só o usuário a chama |
| `argument-hint` | `migrate` | lista de argumentos |
| `allowed-tools` | `migrate` e `gh-check` | libera só `check.sh` (`migrate`) e `check-gh.sh` (`gh-check`), por `sh` |
| `model` e `effort` | `migrate` | `claude-haiku-5-5` e `medium`, travados pelo gate (`PINNED_MODEL`, `PINNED_EFFORT`) |
| `metadata` | 9 skills de linguagem | `baseline` (versão da linguagem) e `verified` (data da checagem) |

### Agentes (`agents/<nome>.md`)

| Chave | Valor |
|---|---|
| `name` | nome técnico (7 agentes) |
| `description` | começa com `Alias: <nome>.` (7 agentes) |
| `tools` | lista separada por vírgula |
| `skills` | lista em linhas próprias; pré-carrega as skills |
| `color` | cor do agente |
| `model` | `claude-haiku-5-5` nos 7 agentes e em `migrate`. Decisão de 2026-10-30; o gate (`tests/gate_format.py`, `PINNED_MODEL`) aceita só esse valor e exige que ele esteja presente |
| `effort` | `medium` nos 7 agentes e em `migrate` (decisão de 2026-10-30, que troca o `high` do mesmo dia). O gate (`PINNED_EFFORT`) exige esse valor |

Os sete agentes pré-carregam `migration-conduct` no campo `skills`.

### ADR (`docs/migration/adr/ADR-NNN-<slug>.md`)

Um **ADR** (registro de decisão de arquitetura) guarda uma decisão legada que você mantém de propósito. As chaves do frontmatter estão no modelo de `skills/migrate/references/templates.md`:

- `id`: igual ao nome do arquivo, como `ADR-001`;
- `status`: `accepted` ou `superseded`;
- `unit`: a unidade dona do ADR;
- `candidate`: o DEC de origem, como `DEC-001`;
- `source_sha`: o commit de origem.

O corpo tem seis seções, nesta ordem (`skills/migrate/scripts/check.sh`, que verifica cada uma):

1. `## Decision`
2. `## Legacy evidence`
3. `## Reason to keep the legacy behavior`
4. `## Best practice contradicted`
5. `## Justification`
6. `## Consequences`

### Verificação

Nenhum script do toolkit confere as chaves de skill e de agente. Para isso, rode a checagem manual `claude plugin validate.claude --strict`, que cobre agentes, skills e comandos (`manutencao.md`, seção Validar o toolkit).

`skills/migrate/scripts/check.sh` lê frontmatter só dos artefatos da migração: `MIGRATION.md`, os artefatos de unidade, os ADR e o doc da unidade. A função `fm` é usada em `check_artifact`, `cites_bad`, `pin_line`, `scope_hash`, `build_line`, `review_line`, `doc_line` e `adr_file_issues`.

### Pendências

## Estilo e orçamento de prompt

Um **prompt** é o texto de instruções que o agente ou a skill recebe. Ele custa tokens a cada uso, então deve ser curto e concreto.

- **Idioma do prompt.** Prompts de agentes e de skills são em inglês (`CLAUDE.md`, seção Language). Docs e artefatos seguem `doc_language` e `artifact_language`.
- **Corpo de agente.** Os sete agentes seguem esta ordem (`agents/*.md`):
  1. título com o nome;
  2. um parágrafo com o papel;
  3. `## Inputs`, com o que o prompt de despacho traz e o que ler antes;
  4. o procedimento, em `## Procedure` ou em uma seção `## Mode <nome>` por modo;
  5. `## Final message`.

  As regras (`## Rules`), o bloco de UI e o modo de arquitetura não ficam no prompt. Moram em `skills/migrate/references/agent-rules/<agente>.md`, e o agente lê o próprio arquivo com Read antes do passo 1 (decisão de 2026-10-30). Assim o prompt do agente cabe no orçamento e as regras continuam obrigatórias.
- **Procedimento.** Passos numerados, com o comando completo do `check.sh` entre crases e o caminho exato do artefato.
- **Descrição de skill.** O campo `description` é o gatilho de carga de uma skill de linguagem. Ele diz a linguagem, o escopo e quando usar (`skills.md`, seção Como uma skill é acionada).
- **Orçamento.** Cada agente tem até 100 linhas e 7 KiB, e os sete juntos têm até 43 KiB (`tests/gate_format.py`; veja Tamanhos). Os `SKILL.md` têm limite de 500 linhas, pelo mesmo gate. O que não muda a saída de uma etapa fica de fora.
- **Mensagem final.** No máximo 12 linhas, com as chaves em inglês (`skills/migration-conduct/SKILL.md`, seção 12).

## Tamanhos

O gate `tests/gate_format.py` limita os agentes: até 100 linhas e 7 KiB cada, e 43 KiB no total. O `check.sh` não mede tamanho. Skills e referências não têm limite próprio, além das 500 linhas do `SKILL.md`.

A tabela mostra a medida do estado atual, feita em 2026-10-30. Ela não é uma regra.

| Arquivo | Medida atual |
|---|---|
| `agents/*.md` (7) | de 38 a 54 linhas; de 3.710 a 5.513 bytes; 33.165 bytes no total (maior em bytes: `agents/migration-planner.md`; maior em linhas: `agents/doc-writer.md`) |
| `skills/migrate/references/agent-rules/*.md` (7) | de 2.526 a 5.415 bytes (regras, bloco de UI e modo de arquitetura de cada agente, fora do orçamento do gate) |
| `skills/*/SKILL.md` (21) | de 17 a 190 linhas (menor: `skills/gh-check/SKILL.md`; maior: `skills/migration-conduct/SKILL.md`) |
| `skills/*/references/*.md` (81) | até 348 linhas (maior: `skills/migrate/references/templates.md`) |
| `description` | até 431 caracteres, com aspas (`skills/kotlin/SKILL.md`) |

### Pendências

- Limite de tamanho de referências não definido. Se for definido, precisa de uma regra em um arquivo do toolkit e de uma verificação no gate (`tests/gate_format.py`).

## Marcadores

Um **marcador** é um comentário no código novo que registra algo fora do padrão. Há dois, definidos em `skills/migration-conduct/SKILL.md`, seção 5:

- `deviation: <motivo e referência>`: o destino difere de um padrão ou de um padrão de estilo, de propósito. Vai como comentário na sintaxe da linguagem de destino, logo acima da linha.
- `known-issue: <referência>`: o legado tem um bug que o destino mantém. Corrigir é decisão da especificação.

Regras:

- Marcador sem motivo e sem referência é achado.
- Conflito entre um padrão e o comportamento se registra como `deviation`, com o motivo (`CLAUDE.md`).
- Para silenciar uma regra de lint, use o escopo mais estreito possível, com um `deviation` que cita a regra (`skills/migration-conduct/SKILL.md`).

Modelo:

```
// deviation: <motivo> (<referência>)
// known-issue: <referência do bug no legado>
```

### Pendências

- `check.sh` não procura marcadores. A conferência fica com a revisão: `agents/parity-reviewer.md` diz que o agente confere as regras de conduta.

## Onde cada regra mora

Cada tipo de regra tem um lugar próprio. Nenhum deles repete o conteúdo do outro.

| Lugar | Arquivo | O que guarda | Quando é lido |
|---|---|---|---|
| Regras curtas do projeto | `CLAUDE.md` (66 linhas) | idioma, comandos, agentes e aliases, skills de linguagem, configuração de execução (modelo e effort), as doze regras em resumo, memória do projeto em `.claude/memory/` | no início de cada sessão |
| Regras compartilhadas | `skills/migration-conduct/SKILL.md` (190 linhas) | paridade, evidência, escada de evidência, lacunas, marcadores, ids, segredos, verificação, idioma, mensagem final, decisões legadas e ADR | pré-carregada pelos sete agentes |
| Papel de cada agente | `agents/*.md` | entradas, procedimento ou modos, regras do papel, mensagem final | quando o agente é despachado |
| Prática | `skills/<nome>/SKILL.md` e `references/` | método, orquestração (`migrate`), armadilhas por linguagem | pelo campo `skills`, pela chamada de skill ou pelo orquestrador |
| Leitura humana | `.claude/docs/` | explicação para quem usa ou mantém o toolkit | pelas pessoas |

No projeto migrado, a documentação de cada unidade vai para `doc_root` do `MIGRATION.md` (`docs`, no modelo de `skills/migrate/references/templates.md`). Os ADR vão para `docs/migration/adr/`.

## Ids e estados

### Ids

Um **id** é o código curto que identifica cada item de um artefato, como uma regra ou um requisito. Você usa o id para citar o item em outro lugar.

| Id | Significado | Artefato | Exemplo |
|---|---|---|---|
| `BR-<SLUG>-NNN` | regra de negócio do legado, com citação | `extraction.md` | `BR-PRICING-001` |
| `DEC-NNN` | decisão legada que contraria boa prática e é preservada | `extraction.md` (seção `## Legacy decisions contrary to best practice`) | `DEC-001` |
| `FR-NNN` | requisito funcional, com `Source: BR-` | `spec.md` | `FR-001` |
| `TS-NNN` | requisito de destino, com `Source: FR-` | `spec.md` | `TS-001` |
| `NG-NNN` | não objetivo | `spec.md` | `NG-001` |
| `AG-NNN` | antiobjetivo | `spec.md` | `AG-001` |
| `PEND-NNN` | decisão pendente | `spec.md` | `PEND-001` |
| `ID-NNN` | decisão de planejamento | `plan.md` | `ID-001` |
| `ADR-NNN` | registro de uma decisão legada, com o id de seu DEC em `candidate:` | `docs/migration/adr/` | `ADR-001` |
| `T-NNN` | tarefa | `tasks.md` | `T-001` |
| `RV-NNN` | achado de revisão | `review.md` | `RV-001` |

Fontes: `skills/migration-conduct/SKILL.md`, seção 7 e seção 6; seção 13 para `DEC` e `ADR`; `skills/migrate/references/templates.md`.

- O `<SLUG>` usa só letras maiúsculas, dígitos e hífen. O padrão `BR-[A-Z0-9-]+-[0-9]{3}` aparece em `skills/migrate/scripts/check.sh`.
- Nenhum id é renumerado nem reutilizado. Para retirar um id, marque-o como `withdrawn` e não apague a linha (`skills/migration-conduct/SKILL.md`, seção 7). O valor `withdrawn` está no modelo de decisão do plano (`skills/migrate/references/templates.md`: `proposed | accepted | withdrawn`). O mesmo arquivo usa `open | fixed | dismissed | blocked` para achados.
- `check.sh ids` aponta id duplicado em BR, FR, TS, PEND, ID, T e RV (`check.sh`). NG, AG, DEC e ADR não entram nessa conferência. Os ADR têm a checagem de id repetido própria, em `check.sh adr`.

### Estados do artefato

Cada artefato tem um campo `status` no frontmatter. Os valores são `draft`, `ok` ou `blocked` (`skills/migrate/references/templates.md`; `check.sh`). Outro valor vira INVALID. Um ADR usa `accepted` ou `superseded` (`check.sh`).

O campo `deadline` do frontmatter de `MIGRATION.md` aceita dois valores:

- `none`: sem prazo;
- uma data no formato `AAAA-MM-DD`.

Outro valor vira `deadline INVALID` em `check.sh deadline` e em `status`. Uma data passada vira `OVERDUE` (`skills/migrate/scripts/check.sh`, função `deadline_line`).

Estes são os estados que `check.sh status` mostra (`skills/migrate/references/stages.md`):

| Estado | Significado |
|---|---|
| MISSING | o arquivo não existe |
| DRAFT | `status: draft`, ou trabalho pendente |
| BLOCKED | `status: blocked`, uma decisão bloqueante aberta ou uma tarefa bloqueada |
| INVALID | uma verificação estrutural falhou: ids, cobertura, citações, chaves, seção de DEC ou ADR |
| STALE | uma fonte ou o código mudou depois que o artefato foi escrito |
| OK | `status: ok`, e todas as verificações passaram |

- Prioridade, da mais forte para a mais fraca: INVALID, STALE, BLOCKED, DRAFT, OK (`stages.md`).
- READY vale quando extraction, spec, plan e tasks estão em OK (`stages.md`). `check.sh` imprime `<unit> ready YES` ou `<unit> ready NO` (`check.sh`).
- Ordem das etapas: extract, spec, plan, tasks, build, review, doc (`stages.md`).
- Congelamento: depois que uma tarefa deixa `pending`, spec, plan e tasks não rodam de novo (`stages.md`; `skills/migrate/SKILL.md`, passo 3).

### Estados de tarefa, build, revisão e documentação

- Campo `status` da tarefa: `pending`, `in_progress`, `done` ou `blocked` (`check.sh`; `templates.md`).
- Campo `kind` da tarefa: `capture`, `setup`, `test`, `impl` ou `verify` (`check.sh`; `templates.md`).
- Extração (`extract`): INVALID se a seção de DEC falta ou se um DEC não tem citação (`dec_issues`, `check.sh`).
- Plano (`plan`): INVALID se `check.sh adr` acusa problema em ADR ou em DEC (`adr_issues`, `check.sh`).
- Build (`build_line`, `check.sh`). A ordem de precedência é esta:
  1. sem tarefas, gera DRAFT;
  2. INVALID se uma tarefa `done` não tem `evidence:`, ou se um arquivo listado não existe;
  3. BLOCKED se há tarefa `blocked`;
  4. DRAFT se há `pending` ou `in_progress`;
  5. OK se todas estão `done`.
- Revisão (`review_line`, `check.sh`). O campo `status` de `review.md` aceita `draft`, `ok` ou `blocked`. Um achado `RV-` tem `status` em `open`, `fixed`, `dismissed` ou `blocked`, e `severity` em `high`, `medium` ou `low` (`templates.md`). Fica INVALID se `status: ok` convive com achado `open` ou `blocked` (`check.sh`). Fica STALE se o `scope_hash` difere do escopo atual (`check.sh`).
- Documentação (`doc_line`, `check.sh`). Fica INVALID se o `status` não é `draft` nem `ok`, se falta a linha de uma fonte na tabela `Sources`, ou se falta a linha de um ADR da unidade. Fica STALE se o cksum (soma de verificação) de uma fonte ou de um ADR mudou, ou se o `scope_hash` mudou.

### Decisões

Toda decisão aberta cai em um de três tipos. Classifique antes de agir (`skills/migrate/references/ask.md`, seção 2). Se o código legado responde, é um fato (`ask.md`).

- **Fato**: o que o código, a biblioteca ou o runtime faz, inclusive o comportamento legado. Responde-se pela fonte, com evidência. Nunca vai ao usuário.
- **Padrão de conduta**: ponto que a conduta já decide, como manter o comportamento da fonte (regra 3) ou manter um bug como `known-issue`. Registra-se com o número da regra e a nota de reversibilidade.
- **Escolha do usuário**: tudo que a conduta não decide. Só esta é perguntada.

Regras de registro (`ask.md`, seções 4 e 5):

- Pergunta sem `verified:` não é enviada (seção 4).
- Ponto sem efeito no resultado vira `PEND` com `blocking: no` (seção 4).
- Pergunta sobre comportamento que o legado implementa não é feita (seção 4).
- A resolução entra em uma destas três formas (seção 5):
  - `resolved by user, <data>`;
  - `default by conduct rule <n>, reversible, <data>`;
  - `fact: <evidência>`.

### NEEDS permitidos

`NEEDS:` é o pedido que um agente faz quando precisa de outra parte. Esta tabela mostra quem pode pedir o quê, por agente (`skills/migrate/references/routing.md`). Um pedido para outro dono é reportado, e a unidade para. Um `NEEDS: user` sem caminho e sem linha do legado em `verified:` volta ao `behavior-extractor`.

| Agente | Pode pedir |
|---|---|
| `behavior-extractor` | user |
| `spec-writer` | behavior-extractor (fato técnico ausente), user |
| `migration-planner` | spec-writer, behavior-extractor, user |
| `task-decomposer` | migration-planner, spec-writer, user |
| `implementer` | task-decomposer, migration-planner, spec-writer (só enquanto nenhuma tarefa começou), user |
| `parity-reviewer` | implementer (rodada de correção) |
| `doc-writer` | user |

### Mensagem final

A mensagem final é o resumo que o agente devolve ao fim de cada etapa. Ela segue esta ordem de chaves (`skills/migration-conduct/SKILL.md`, seção 12):

1. `Result:`
2. `Written:`
3. `Checks:`
4. `Skills:`
5. `Open:` (no máximo 3 linhas)
6. `NEEDS:`

A mensagem tem no máximo 12 linhas e não tem preâmbulo. `NEEDS:` vale `none`, ou `<dono>: <fato entre aspas>`.

### Pendências
