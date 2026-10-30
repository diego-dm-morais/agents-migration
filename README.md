# Toolkit de Migração de Código

Este toolkit troca um sistema antigo por um novo, em outra linguagem ou framework, **sem mudar o que o sistema faz**.

Ele não migra tudo de uma vez. Divide o trabalho em partes pequenas, chamadas **unidades**. Um exemplo de unidade é um endpoint da API. Cada unidade passa por etapas, e um agente de IA faz cada etapa.

Ele roda dentro do [Claude Code](https://claude.com/claude-code).

## Antes de começar

Você precisa de:

- **Claude Code**.
- **Git**. No Windows, use o **Git Bash**.
- **GitHub CLI (`gh`)**, só se o código antigo estiver num repositório remoto. A skill `gh-check` confere se ele está instalado e logado.

## Como usar, em 5 passos

1. **Copie** a pasta `.claude/` para a raiz do seu projeto novo.
2. **Abra** o projeto no Claude Code.
3. **Digite `/migrate init`.** O comando pergunta o que falta:
   - onde está o código antigo (caminho local ou URL);
   - qual versão migrar (tag, branch ou commit);
   - quais unidades migrar.
4. **Digite `/migrate status`** para ver o andamento. Esse comando só lê os arquivos. Ele não muda nada.
5. **Digite `/migrate <unidade>`** para avançar uma unidade. Exemplo: `/migrate post-v1-users`. O comando roda as etapas em ordem. Se ele parar com uma pergunta, responda com `/migrate ask`.

## As etapas

Cada unidade passa por estas etapas, nesta ordem. Cada uma grava um arquivo e tem um agente responsável.

| Etapa | Agente | O que faz, em palavras simples |
|---|---|---|
| extract | `behavior-extractor` (Eduardo) | Lê o código antigo e descreve o que ele faz. Cada frase aponta a linha do código. |
| spec | `spec-writer` (Sofia) | Escreve o que o código novo precisa fazer. |
| plan | `migration-planner` (Paula) | Decide como cada parte do código antigo vira código novo. |
| tasks | `task-decomposer` (Tiago) | Quebra o plano em tarefas pequenas, na ordem certa. |
| build | `implementer` (Isabela) | Escreve o código novo e os testes. Os testes vêm primeiro. |
| review | `parity-reviewer` (Rafael) | Compara o código novo com o antigo e lista as diferenças. |
| doc | `doc-writer` (Daniela) | Documenta a unidade, em português e em linguagem simples. |

**Importante:** o `build` só roda quando você pede. Commit, push e pull request também só saem com o seu pedido.

**Paridade** é o objetivo: o código novo aceita as mesmas entradas, recusa as mesmas entradas e devolve as mesmas saídas e os mesmos erros.

## Como informar as unidades

Você pode descrever uma unidade de duas formas:

- **Pelo caminho da operação.** `POST /v1/users` vira a unidade `post-v1-users`. O agente encontra a rota no código antigo.
- **Por uma collection.** Você envia um arquivo exportado do Postman, OpenAPI ou Apidog. Ela serve só para listar as operações. O comportamento vem sempre do código, nunca dos exemplos da collection. Senhas e tokens viram `<redacted>`.

O nome da unidade usa só letras minúsculas, números e hífens. Exemplo: `post-v1-users`.

## Comandos

| Comando | Quando usar |
|---|---|
| `/migrate init` | No começo, para preparar o projeto. |
| `/migrate` ou `/migrate status` | Para ver o andamento. Não altera arquivos. |
| `/migrate <unidade>` | Para avançar a unidade até ela ficar pronta para o build (READY). |
| `/migrate <unidade> <etapa>` | Para rodar uma etapa só. As etapas anteriores precisam estar prontas. |
| `/migrate ask [unidade]` | Para responder às perguntas pendentes. |
| `/migrate help` | Para ver a ajuda completa. |

## Os estados de uma etapa

`/migrate status` mostra o estado de cada etapa:

| Estado | O que significa | O que fazer |
|---|---|---|
| `MISSING` | O arquivo ainda não existe. | Rode `/migrate <unidade>`. |
| `DRAFT` | Foi escrito, mas não terminou. | Rode de novo, ou responda às pendências. |
| `BLOCKED` | Falta uma decisão sua. | Rode `/migrate ask`. |
| `INVALID` | Falhou numa checagem de formato ou de citação. | Rode a etapa de novo. |
| `STALE` | O código ou uma etapa anterior mudou depois. | Rode a etapa de novo. |
| `OK` | Válido e atualizado. | Nada. |

Uma unidade fica **READY** quando extract, spec, plan e tasks estão `OK`.

## Quando o agente pergunta

O agente não chuta. Antes de perguntar, ele lê o código antigo e as bibliotecas. Só pergunta o que o código não responde. A pergunta aparece em `/migrate ask`.

## Se você der `/clear`

Rode `/migrate` de novo. O progresso fica nos arquivos, não na conversa.

## As regras de ouro

1. **Sem chute.** Cada frase sobre o código antigo traz a linha que a comprova.
2. **Sem regra inventada.** A regra de negócio é o que o código faz de verdade.
3. **Bug fica como bug.** Um erro do código antigo é mantido e marcado como `known-issue`. Ninguém corrige em silêncio.
4. **O código é a fonte.** Specs e docs antigos servem só de apoio.
5. **Documento em dia.** Se o código mudar, o documento vira `STALE` e é gerado de novo.
6. **Decisão antiga é preservada.** Se o código antigo faz algo que contraria a boa prática, isso fica igual e vira um ADR, um registro curto com o motivo.

As regras completas estão em `.claude/skills/migration-conduct/SKILL.md`.

## Glossário

| Termo | O que é |
|---|---|
| **Unidade** | A menor parte do código que funciona sozinha. Exemplo: um endpoint. |
| **Snapshot** | Cópia fixa do código antigo. Ninguém altera. |
| **Pin** | O commit exato do código antigo que serve de referência. |
| **Artefato** | O arquivo que uma etapa grava, em `docs/migration/<unidade>/`. |
| **Backlog** | A lista de unidades a migrar, em `docs/migration/MIGRATION.md`. |
| **ADR** | Registro de uma decisão antiga mantida de propósito, com o motivo. |
| **`known-issue`** | Marca um bug do código antigo que o código novo mantém de propósito. |

O glossário completo está em [.claude/docs/README.md](.claude/docs/README.md).

## O que o `init` cria no seu projeto

```
docs/migration/
├── MIGRATION.md        # origem, versão fixada, destino, idiomas e lista de unidades
├── adr/                # decisões antigas mantidas de propósito
└── <unidade>/
    ├── extraction.md   # extract
    ├── spec.md         # spec
    ├── plan.md         # plan
    ├── tasks.md        # tasks
    └── review.md       # review
```

O formato de cada arquivo está em `.claude/skills/migrate/references/templates.md`.

## Para reutilizar em outra migração

1. Copie `.claude/` para o novo projeto.
2. Rode `/migrate init` com a nova origem e o novo destino.
3. Se a sua dupla de linguagens não existir, crie uma skill em `.claude/skills/<linguagem>/`. Copie uma skill existente. O guia está em `.claude/docs/manutencao.md`.

Só `docs/migration/` e o snapshot são específicos de cada projeto. Ambos são gerados na execução.

## Para quem mantém o toolkit

Rode a suíte completa a partir da raiz do repositório:

```sh
sh .claude/tests/run-tests.sh
```

A última linha mostra `run-tests exit=<código>`. Código `0` quer dizer que tudo passou. A suíte precisa de Python.

Depois de mudar um agente, uma skill ou o `check.sh`, atualize a documentação correspondente em `.claude/docs/` e rode a suíte de novo.

## Mais documentação

A documentação em português está em `.claude/docs/`:

- [README.md](.claude/docs/README.md): visão geral, início rápido e glossário.
- [arquitetura.md](.claude/docs/arquitetura.md): como agentes e skills se encaixam.
- [agentes.md](.claude/docs/agentes.md): os sete agentes, um a um.
- [skills.md](.claude/docs/skills.md): skills de fluxo, de conduta e de linguagem.
- [fluxo.md](.claude/docs/fluxo.md): etapas, arquivos, estados e receitas.
- [convencoes.md](.claude/docs/convencoes.md): nomes, marcadores e ids.
- [manutencao.md](.claude/docs/manutencao.md): como manter o toolkit.

## Idioma

- Respostas ao usuário e documentos gerados pela migração: português (pt-BR).
- Código, comentários, mensagens de commit e prompts dos agentes: inglês.
- Nomes de arquivos, caminhos, comandos, SQL e mensagens de erro nunca são traduzidos.
