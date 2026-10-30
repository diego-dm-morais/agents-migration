# Toolkit de Migração de Código

Toolkit reutilizável para o [Claude Code](https://claude.com/claude-code) que migra código de uma linguagem ou framework para outro, uma unidade por vez, preservando o comportamento do sistema original.

Ele não é amarrado a nenhuma base de código. Copie a pasta `.claude/` para o projeto de destino, aponte para um repositório de origem e rode `/migrate`.

## Sumário

- [O que é](#o-que-é)
- [Princípios](#princípios)
- [Como funciona](#como-funciona)
- [Requisitos](#requisitos)
- [Início rápido](#início-rápido)
- [Comandos](#comandos)
- [Agentes](#agentes)
- [Skills de linguagem](#skills-de-linguagem)
- [Estrutura do projeto](#estrutura-do-projeto)
- [Artefatos gerados no projeto de destino](#artefatos-gerados-no-projeto-de-destino)
- [Estados das etapas](#estados-das-etapas)
- [Usando em qualquer migração](#usando-em-qualquer-migração)
- [Desenvolvimento](#desenvolvimento)
- [Documentação](#documentação)
- [Convenções de idioma](#convenções-de-idioma)

## O que é

Um conjunto de agentes, skills e um script de verificação que ficam em `.claude/`. O Claude Code lê esses arquivos e executa a migração como um pipeline em etapas:

- a unidade de trabalho é a **unidade de migração**: a menor parte da origem que se comporta sozinha (um endpoint, um módulo, um serviço);
- cada unidade passa por sete etapas, cada uma com um agente dono;
- cada etapa grava um artefato, e um script shell (`check.sh`) calcula o estado de cada etapa a partir desses artefatos. Não há estado escondido: depois de um `/clear`, rodar `/migrate` de novo retoma de onde o trabalho parou.

O objetivo é a paridade funcional: mesmas entradas aceitas e recusadas, mesmas saídas, mesmos erros.

## Princípios

O texto completo está em `.claude/skills/migration-conduct/SKILL.md` (seção 0).

1. **Sem alucinação.** Toda afirmação sobre o comportamento da origem cita `path:line @sha7`, aberto na execução atual.
2. **Sem regra de negócio inventada.** Uma regra é o que o código faz. Um `BR-` sem citação, ou um `FR-` sem `Source: BR-`, é rejeitado pelo `check.sh`.
3. **Documentação fiel.** Bugs são documentados como `known-issue`, nunca corrigidos em silêncio.
4. **O código implementado é a fonte da verdade.** Specs e docs antigos são só contexto.
5. **Docs sempre em dia.** Os artefatos guardam o hash das suas fontes. Se o código ou um artefato anterior mudar, o artefato fica `STALE` e precisa ser gerado de novo.
6. **Investigar antes de perguntar.** Primeiro o código, depois o código-fonte das dependências, depois a documentação oficial. Só se pergunta ao usuário o que muda o resultado e não se encontra em nenhuma dessas fontes.
7. **Fidelidade ao legado.** Decisões legadas que contrariam boas práticas são preservadas e registradas em um ADR, com o motivo.

## Como funciona

```
  /migrate init            intake: origem, tag/commit, destino, unidades -> snapshot + backlog
        |
        v
  extract -> spec -> plan -> tasks -> build -> review -> doc
  Eduardo    Sofia   Paula   Tiago    Isabela  Rafael   Daniela
```

- `/migrate <unidade>` roda `extract`, `spec`, `plan` e `tasks` até a unidade ficar **READY**, ou até uma parada. O `build` só roda quando você pedir.
- Os agentes nunca perguntam direto ao usuário. Uma pergunta bloqueante encerra a etapa com `NEEDS: user: <pergunta>`, e o `/migrate ask` a apresenta.
- A origem é lida de um **snapshot**: uma cópia do repositório de origem fixada em um commit exato (`source_sha`), guardada fora do projeto de destino e nunca alterada.

## Requisitos

- Claude Code com suporte a subagentes e skills.
- Um `sh` POSIX: Linux, macOS ou Git Bash no Windows.
- `git`, e acesso de leitura ao repositório de origem na tag, branch ou commit escolhido.
- Utilitários comuns usados pelo `check.sh`: `awk`, `cksum`, `cut`, `grep`, `head`, `sed`, `sort`, `tr`, `uniq`, `wc`.
- Python (só para rodar a suíte de testes do toolkit).
- GitHub CLI (`gh`) autenticado, quando a origem é um repositório remoto. A skill `gh-check` confere isso.

## Início rápido

1. Copie a pasta `.claude/` para a raiz do projeto de destino.
2. Abra o projeto no Claude Code.
3. Rode `/migrate init` e responda ao intake: repositório de origem, tag (ou branch/commit), endpoints ou unidades a migrar. Só se pergunta o que ainda não está em `docs/migration/MIGRATION.md`.
4. Rode `/migrate status` para ver todas as unidades e etapas.
5. Rode `/migrate <unidade>` para avançar uma unidade até READY.
6. Quando uma etapa parar com uma pergunta, rode `/migrate ask`.

## Comandos

| Comando | O que faz |
|---|---|
| `/migrate init` | Intake: cria o snapshot, confere o pin, lista as unidades candidatas e grava no backlog as que você confirmar. |
| `/migrate` ou `/migrate status` | Mostra o estado de cada etapa de cada unidade e o prazo. Só leitura. |
| `/migrate <unidade>` | Roda as etapas em ordem até READY ou uma parada. |
| `/migrate <unidade> <etapa>` | Roda uma única etapa. As etapas anteriores precisam estar `OK`. |
| `/migrate ask [unidade]` | Responde às decisões pendentes que o código legado não resolve. |
| `/migrate help` | Mostra a ajuda. |

O id da unidade precisa casar com `^[a-z0-9]+(-[a-z0-9]+)*$`. Commit, push e PR ficam fora do `/migrate` e só acontecem se você pedir.

## Agentes

Despachados pelo `/migrate`. Chame um direto só quando precisar, pelo nome ou apelido.

| Etapa | Agente | Apelido | Saída |
|---|---|---|---|
| extract | `behavior-extractor` | Eduardo | `extraction.md`: comportamentos e regras de negócio (`BR-`) com citações |
| spec | `spec-writer` | Sofia | `spec.md`: requisitos funcionais (`FR-`), requisitos do destino (`TS-`), não objetivos, decisões pendentes |
| plan | `migration-planner` | Paula | `plan.md`: mapeamento origem-destino, dependências fixadas, decisões |
| tasks | `task-decomposer` | Tiago | `tasks.md`: tarefas ordenadas (capture, setup, test, impl, verify) |
| build | `implementer` | Isabela | código do destino e testes, teste primeiro |
| review | `parity-reviewer` | Rafael | `review.md`: achados (`RV-`) contra a origem |
| doc | `doc-writer` | Daniela | documentação da unidade em linguagem simples |

## Skills de linguagem

Carregadas para a linguagem de origem e para a de destino:

`golang`, `java`, `python`, `nodejs`, `typescript`, `javascript`, `dotnet`, `rust`, `flutter`.

Cada uma tem um `as-source.md` (o que observar ao ler essa linguagem) e um `as-target.md` (como escrevê-la de forma idiomática sem mudar o comportamento). Skills de apoio: `migration-conduct`, `migration-patterns`, `tdd`, `doc-writing`, `gh-check`.

## Estrutura do projeto

```
.
├── .claude/
│   ├── CLAUDE.md                  # instruções do toolkit, valem mais que as globais
│   ├── settings.local.json        # hook SessionStart que imprime `check.sh status`
│   ├── agents/                    # os sete agentes de etapa
│   ├── skills/
│   │   ├── migrate/               # orquestrador: SKILL.md, references/, scripts/check.sh
│   │   ├── migration-conduct/     # as regras obrigatórias
│   │   ├── migration-patterns/    # mapa de idiomas entre linguagens
│   │   ├── tdd/  doc-writing/  gh-check/
│   │   └── <linguagem>/           # golang, java, python, nodejs, ...
│   ├── docs/                      # documentação humana (pt-BR)
│   ├── tests/                     # suíte de testes do toolkit
│   └── memory/                    # memória local do Claude (fora do git)
└── README.md
```

## Artefatos gerados no projeto de destino

```
docs/migration/
├── MIGRATION.md        # origem, pin (source_sha), destino, idiomas, limites, prazo, backlog
├── adr/
│   └── ADR-NNN-<slug>.md
└── <unidade>/
    ├── extraction.md
    ├── spec.md
    ├── plan.md
    ├── tasks.md
    └── review.md
```

Todo artefato começa com `status: draft`. Os formatos e os ids (`BR`, `FR`, `TS`, `NG`, `AG`, `PEND`, `ID`, `T`, `RV`, `DEC`, `ADR`) estão em `.claude/skills/migrate/references/templates.md`.

## Estados das etapas

O `check.sh` calcula um destes estados para cada etapa:

| Estado | Significado |
|---|---|
| `MISSING` | O artefato não existe. |
| `DRAFT` | Escrito, mas não finalizado. |
| `BLOCKED` | Aguardando uma decisão bloqueante. |
| `INVALID` | Reprovado em uma verificação de formato ou de citação. |
| `STALE` | Um artefato anterior ou o código mudou depois. Gere de novo. |
| `OK` | Válido e atual. |

Uma unidade fica **READY** quando extract, spec, plan e tasks estão `OK`.

## Usando em qualquer migração

Nada no toolkit é específico de um projeto. Para reutilizá-lo:

1. Copie `.claude/` para o novo projeto de destino.
2. Rode `/migrate init` com a nova origem e o novo destino.
3. Se o seu par de linguagens não estiver coberto, crie uma skill em `.claude/skills/<linguagem>/` seguindo uma existente (veja `.claude/docs/manutencao.md`).

Os únicos arquivos específicos do projeto são gerados na execução: `docs/migration/` e o snapshot da origem.

## Desenvolvimento

Rode a suíte completa de testes do toolkit a partir da raiz do repositório:

```sh
sh .claude/tests/run-tests.sh
```

Ela roda o gate de formato, o linter de vocabulário, as verificações de consistência e de regras e os cenários do `check.sh`. A última linha imprime `run-tests exit=<código>`.

Comandos úteis ao trabalhar no toolkit:

```sh
sh .claude/skills/migrate/scripts/check.sh status        # estado de cada unidade
sh .claude/skills/migrate/scripts/check.sh pin           # o HEAD do snapshot é o source_sha
sh .claude/skills/migrate/scripts/check.sh cites <file>  # as citações resolvem no snapshot
sh .claude/skills/migrate/scripts/check.sh ids [unit]    # ids duplicados e cobertura
```

Ao mudar um agente, uma skill ou o `check.sh`, atualize o arquivo correspondente em `.claude/docs/` e rode a suíte de novo. Como adicionar, atualizar e aposentar agentes e skills está em `.claude/docs/manutencao.md`.

## Documentação

A documentação humana (pt-BR) está em `.claude/docs/`:

- [README.md](.claude/docs/README.md): visão geral, início rápido e glossário.
- [arquitetura.md](.claude/docs/arquitetura.md): como agentes e skills se encaixam.
- [agentes.md](.claude/docs/agentes.md): os sete agentes.
- [skills.md](.claude/docs/skills.md): skills de fluxo, de conduta e de linguagem.
- [fluxo.md](.claude/docs/fluxo.md): etapas, artefatos, estados, limites e receitas.
- [convencoes.md](.claude/docs/convencoes.md): nomes, frontmatter, marcadores e ids.
- [manutencao.md](.claude/docs/manutencao.md): manutenção do toolkit.

## Convenções de idioma

- Respostas ao usuário e docs de migração gerados: pt-BR.
- Código, comentários, mensagens de commit e prompts de agentes e skills: inglês.
- Identificadores, literais, caminhos, SQL e mensagens de erro nunca são traduzidos.
