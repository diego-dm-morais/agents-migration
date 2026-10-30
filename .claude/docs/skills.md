# Skills

Este documento descreve as skills do toolkit de migração: o que cada uma faz, quem a carrega e como ela é acionada.

Termos usados aqui:

- **Skill:** pasta com um arquivo `SKILL.md`, com instruções que o Claude Code carrega sob demanda.
- **Frontmatter:** o bloco entre as duas linhas `---` no início de cada arquivo `SKILL.md` ou de cada agente.
- **Baseline:** a versão de uma linguagem que a skill toma como referência.
- **Gate:** o conjunto de comandos de qualidade que o código precisa passar.

Os caminhos são relativos a `.claude/`.

## Skills de fluxo e de conduta

O toolkit tem cinco skills que não são de linguagem. A tabela mostra o papel de cada uma e quem a carrega.

| Skill | Papel | Carregada por | Acionamento |
|---|---|---|---|
| `migrate` | Orquestrador. Roda as etapas de uma unidade em ordem, lê o estado com `check.sh` e despacha um agente por vez. | Nenhum agente. | Só quando o usuário digita `/migrate`. Frontmatter: `disable-model-invocation: true` (`skills/migrate/SKILL.md`). |
| `migration-conduct` | Regras comuns a todos os agentes: paridade, citações, marcadores, ids, segredos, verificação, formato do relatório e decisões legadas (DEC e ADR). | Os sete agentes: `behavior-extractor`, `spec-writer`, `migration-planner`, `task-decomposer`, `implementer`, `parity-reviewer` e `doc-writer`. | Pré-carregada. `user-invocable: false` (`skills/migration-conduct/SKILL.md`). |
| `migration-patterns` | Categorias de armadilhas que quebram a paridade entre linguagens: números, texto e codificação, tempo e fusos, valores ausentes, igualdade e ordem, erros, concorrência, serialização, entrada e saída e recursos, configuração, aleatoriedade e relógios, e localidade. | `behavior-extractor`, `migration-planner` e `parity-reviewer`. | Pré-carregada. `user-invocable: false` (`skills/migration-patterns/SKILL.md`). |
| `tdd` | Método test-first do implementer: vermelho, verde e refatoração; nomes de teste com o id da spec; testes de caracterização; isolamento de dependências externas; gate de cobertura. | `task-decomposer` e `implementer`. | Pré-carregada. `user-invocable: false` (`skills/tdd/SKILL.md`). |
| `doc-writing` | Processo de escrita da documentação de uma unidade: coleta de contexto, redação seção por seção e autoteste do leitor. | `doc-writer`. | Pré-carregada. `user-invocable: false` (`skills/doc-writing/SKILL.md`). |

**Formas do comando `/migrate`**

`skills/migrate/SKILL.md`, define as formas de uso:

- `/migrate` ou `/migrate status`: mostra o estado de cada unidade.
- `/migrate init`: prepara o projeto.
- `/migrate ask` ou `/migrate ask <unit>`: responde às decisões pendentes.
- `/migrate <unit>`: leva a unidade pelas etapas até `READY` ou até uma parada.
- `/migrate <unit> <stage>`: roda só uma etapa, depois que as etapas anteriores estiverem `OK`.

Os agentes são despachados pelo `/migrate`. Chamada direta só quando o usuário pede pelo nome ou pelo apelido (`CLAUDE.md`).

**As dez regras obrigatórias**

As regras estão em `skills/migration-conduct/SKILL.md`, seção 0. Este é o resumo, com os mesmos números:

1. **Sem alucinação.** Toda afirmação sobre o comportamento cita `path:line @sha7`, aberto nesta execução.
2. **Sem regra de negócio inventada.** Um `BR-` sem citação, ou um `FR-` sem `Source: BR-`, é defeito.
3. **Documentação fiel.** O comportamento é documentado como o código o implementa, com os bugs, marcados como `known-issue`.
4. **Fonte primária é o código implementado.** Spec e docs existentes são contexto, não fonte de comportamento.
5. **Docs em sincronia.** Se o código ou um artefato-fonte muda, a doc fica `STALE` e precisa ser gerada de novo antes do fim da unidade.
6. **Investigar antes de perguntar.** A ordem é: o código; a fonte da dependência na versão fixada; a documentação oficial.
7. **Sem pergunta irrelevante.** Não se pergunta o que o código, a biblioteca ou um default responderia. O default é registrado com `blocking: no`.
8. **Toda pergunta diz o que foi verificado**, com caminhos, linhas ou URLs.
9. **Pergunta bloqueante sem resposta** para a unidade com `NEEDS: user: <question, quoted>`. O agente nunca escolhe o comportamento sozinho.
10. **Fidelidade ao legado.** Não se pergunta ao usuário o que o código legado responde. O legado é a fonte da verdade: seu comportamento e suas decisões são preservados, mesmo quando contrariam boa prática. Cada decisão legada que contraria boa prática vira um ADR (seção 13).

A seção 13 da conduta define as decisões legadas: `DEC-NNN` na extração e `ADR-NNN` em `docs/migration/adr/`. A seção 12 define o contrato da mensagem final.

## Skills de linguagem

O toolkit tem nove skills de linguagem. Cada uma descreve a prática de uma linguagem, com as armadilhas que uma migração encontra e o gate de qualidade. `CLAUDE.md`, lista as nove.

| Skill | Baseline (`metadata.baseline`) | Verificada em (`metadata.verified`) | Escopo |
|---|---|---|---|
| `golang` | `Go 1.26 line (go1.26.0 toolchain checked on 2026-10-29)` | 2026-10-29 | Código Go, `go.mod`, suítes com `go test`, goroutines e context, erros e net/http, encoding/json, layouts de tempo, paridade de arredondamento de inteiros e floats, gate de gofmt e go vet, e migrações de e para Go. |
| `java` | `Amazon Corretto 25 LTS (25.0.5 run on 2026-10-29), with the Java 11 floor (javac --release 11 run)` | 2026-10-29 | Código Java na base Amazon Corretto 25 LTS e no piso Java 11: fontes `.java`, builds Maven e Gradle, testes JUnit, `java.time` e `BigDecimal` para dinheiro, records, tipos selados, switch com padrões, virtual threads, gate de qualidade, e migrações de e para Java. |
| `python` | `Python 3.12 or later (floor 3.12; current stable 3.15.2)` | 2026-10-29 | Código Python 3.12 ou superior sobre CPython: anotações e asyncio, números decimal e float, datetime e zoneinfo, exceções e códigos de saída, gate de pytest, ruff e mypy, e migrações de e para Python. |
| `nodejs` | `Node.js 22 LTS (v22.23.x docs)` | 2026-10-29 | Código Node.js 22 ou superior (LTS) que roda em Node: ESM e CommonJS, `node:test`, fetch e AbortSignal, erros e códigos de saída, paridade numérica e gate de qualidade. |
| `typescript` | `TypeScript 7.0 (7.0.2 on npm latest, checked 2026-10-29)` | 2026-10-29 | Código TypeScript 7.0 ou superior em `.ts` e `.tsx`: tsconfig e strict mode, tipos estruturais, narrowing, enums, any e unknown, entrada JSON, números e datas, gates de tsc e de testes, e migrações de e para TypeScript. |
| `javascript` | `ECMAScript 2026 (17th edition, June 2026), as run by current browsers and Node.js 26 LTS; language only` | 2026-10-29 | A linguagem JavaScript em `.js` e `.mjs`: igualdade fraca, NaN e -0, números IEEE-754, arredondamento de toFixed e Math.round, strings UTF-16, meses de Date a partir de zero, ordenação padrão e ordem de promises e async. APIs de runtime ficam na skill `nodejs` (`skills/javascript/SKILL.md`). |
| `dotnet` | `C# 14 on.NET 10 LTS` | 2026-10-29 | Código C# 14 em.NET 10 LTS: regras da linguagem, overflow de inteiros, tipos de referência anuláveis, decimal e Math.Round, DateTime Kind, strings sensíveis à cultura, ordem do Dictionary, gate de build, teste e formatação, e migrações de e para C#. |
| `rust` | `Rust 1.99.1 stable, edition 2024 (Rust 1.85 or later)` | 2026-10-29 | Código Rust 1.85 ou superior (estável 1.99.1, edição 2024) para crates Cargo, ownership, Result e panics, aritmética de inteiros e f64, coleções, threads, gates de cargo test, clippy e rustfmt, e migrações de e para Rust. |
| `flutter` | `Flutter 3.47 stable, Dart 3.x (Dart docs reflect 3.13.3)` | 2026-10-29 | Código Dart e Flutter (Flutter 3.47 estável, Dart 3.x): null safety e late, int e double na VM e na web, DateTime e UTC, async e isolates, widgets e State, gates de flutter test, dart format e dart analyze, e migrações de e para Dart ou Flutter. |

Os valores da coluna de baseline são copiados de `metadata.baseline` de cada `SKILL.md`. A data vem de `metadata.verified`.

Nenhum agente lista uma skill de linguagem no campo `skills:` do frontmatter. Essas skills carregam pela regra de descrição, descrita na seção seguinte.

## Como uma skill é acionada

São quatro regras. Os caminhos citados estão no próprio toolkit.

1. **Pré-carga pelo agente.** O campo `skills:` do frontmatter de cada arquivo em `agents/` lista as skills que o agente carrega antes de começar. Hoje: `migration-conduct` está nos sete agentes; `migration-patterns` está em `behavior-extractor`, `migration-planner` e `parity-reviewer`; `tdd` está em `task-decomposer` e `implementer`; `doc-writing` está em `doc-writer`.
2. **Carga pela descrição.** Uma skill carrega sozinha quando o campo `description` do frontmatter combina com a tarefa. As nove skills de linguagem usam essa regra. `CLAUDE.md`, manda o agente carregar a skill da linguagem de origem ou a da linguagem de destino.
3. **Só por comando.** `migrate` tem `disable-model-invocation: true`. Ele não é carregado pelo modelo, mesmo quando a descrição combina com a tarefa. Ele roda só quando o usuário digita `/migrate`.
4. **Sem chamada pelo usuário nas skills de conduta.** `user-invocable: false` faz o usuário não chamar a skill pelo nome. `migration-conduct`, `migration-patterns`, `tdd` e `doc-writing` têm esse campo.

## Como verificar os fatos de uma skill de linguagem

Uma skill de linguagem afirma fatos com fonte. As nove têm o mesmo bloco `metadata` (campo `metadata` de cada `SKILL.md`) e a mesma seção `## Sources`.

1. **Data e fontes no topo.** O parágrafo de abertura diz quando os fatos foram verificados e contra quais fontes (`skills/nodejs/SKILL.md`). Cada skill de linguagem tem uma seção `## Sources` com as fontes. Na `nodejs`, a seção `## Sources` lista URLs.
2. **Fato com execução.** Um valor de runtime diz que foi executado, com a versão do runtime. Exemplo: `skills/typescript/SKILL.md`, cita a execução em Node v22.23.1.
3. **Fato não verificado sai ou recebe marca.** Um fato que não pôde ser checado recebe a marca `verify before use` ou sai do texto. Exemplos: `skills/typescript/SKILL.md`, sobre a tag beta 7.1, que não é a baseline; e um trecho do mesmo arquivo, sobre o texto da ECMAScript, que não foi lido.
4. **Gate não rodado é dito.** Quando um comando do gate não roda, a skill diz isso. Exemplo: `skills/flutter/SKILL.md`, diz que nenhum toolchain de Flutter ou Dart estava na máquina e que nenhum comando do gate foi rodado.
5. **Baseline fixa.** Uma versão mais nova não muda a baseline sem nova verificação. Exemplo: `skills/golang/SKILL.md`, diz que a skill não move a baseline para go1.27.3.
6. **Conferência manual.** `skills/migrate/scripts/check.sh` não tem subcomando para skills. Seus subcomandos são `status`, `pin`, `cites`, `ids`, `adr`, `hash` e `scope` (a estrutura `case` no fim de `check.sh`). Datas, versões e fontes das skills de linguagem não têm conferência automática.
