---
name: iniciar-demanda
description: "Conduz uma nova demanda de desenvolvimento na InngageSDK desde a análise e proposta de branch até testes, commits, push e Pull Request no GitHub, sempre com aprovação humana explícita entre as fases. Use quando o usuário apresentar uma história, tarefa, bug, correção, melhoria, implementação ou pedir para começar/planejar uma demanda, mesmo sem citar a skill."
---

# Iniciar demanda

Conduza a demanda como um fluxo controlado. A prioridade é obter entendimento
correto, preservar o repositório e impedir mudanças locais ou remotas sem a
aprovação correspondente.

Antes de começar, leia:

- `.claude/agents/approval-gates.md`, para a ordem e os limites das aprovações;
- `.claude/agents/output-templates.md`, para o formato das entregas de cada fase;
- o `CLAUDE.md` na raiz do package (escopo, arquitetura, comandos e regras).

## Princípios obrigatórios

- Trate a mensagem inicial como autorização apenas para análise local e comandos
  de leitura.
- Informe sempre `Fase atual`, `Concluído` e `Aguardando aprovação`.
- Faça perguntas somente quando a resposta puder alterar comportamento, escopo,
  contrato, segurança, dados, testes ou estratégia de publicação.
- Não avance enquanto houver dúvida material aberta.
- Uma aprovação libera somente a próxima ação descrita, nunca ações em lote.
- Uma resposta ambígua como "ok" vale apenas quando existe uma única ação
  pendente, claramente identificada.
- Antes de qualquer comando mutável, mostre o que será feito e os comandos
  relevantes.
- Ao descobrir mudança material de escopo, pare, explique o impacto e retorne ao
  gate adequado.
- Preserve alterações preexistentes. Nunca faça stash, reset, descarte, amend,
  rebase ou force push por conta própria.

## Fase 1 — Analisar e revisar a demanda

Faça apenas inspeção local e Git de leitura:

1. Verifique branch, status e histórico local (`git status --short --branch`,
   `git log --oneline -10`, `git remote -v`, `git branch -a`).
2. Localize os módulos, contratos, fluxos e testes relacionados em
   `Sources/InngageSDK/` e `Tests/InngageSDKTests/`.
3. Compare o pedido com o comportamento atual do código.
4. Identifique dependências, integrações, riscos e possíveis efeitos colaterais —
   em especial sobre a API pública (`InngageSDK.shared`, `InngageInApp`,
   `InngageError`, `InngageLogger`), os payloads enviados ao backend e o app de
   exemplo `InngageSwift`, que consome este package localmente.
5. Produza a revisão usando o template indicado.
6. Proponha um nome de branch no padrão `feat/<slug>`, `fix/<slug>` ou
   `chore/<slug>`; não crie a branch.

Se existirem dúvidas materiais, liste-as e aguarde respostas. Depois de
resolvidas, reapresente a revisão consolidada e peça aprovação explícita dela.

## Fases seguintes

Depois da aprovação da revisão, siga exatamente
`.claude/agents/approval-gates.md`. Não pule gates, inclusive quando a alteração
parecer pequena.

Para o plano técnico, baseie-se nos arquivos e padrões existentes do projeto
(camadas `Core/`, `Models/`, `Services/`, `Utils/`, `View/`; injeção via
protocolos em `Abstractions`/`Providers`; rede só pelo `ApiManager`), não em
uma arquitetura hipotética. Para o plano de commits, use o diff real após
implementação e testes; nunca prometa antecipadamente uma divisão que o
conteúdo final não sustente.

## Regras específicas de Git e GitHub

- A origem da branch é sempre `release` sincronizada com `origin/release`. Se
  `release` ou o remote ainda não existirem, siga o procedimento do Estado 2 dos
  gates — cada passo de criação exige aprovação própria.
- Atualizar referências remotas, atualizar a branch local e criar a branch de
  trabalho requerem os gates descritos na referência.
- Use caminhos explícitos ao preparar commits; nunca `git add .`.
- Nunca inclua em commit: `.build/`, `.swiftpm/xcode/xcuserdata/`, `xcuserdata/`,
  `.DS_Store`, `_to_delete/`, credenciais ou tokens reais.
- Use Conventional Commits e mantenha cada commit coerente e verificável.
- Se não houver divisão honesta em pelo menos dois commits, explique e peça uma
  exceção; não fragmente código e testes de modo a deixar commits inválidos.
- Faça push somente da branch aprovada, sem `--force`.
- Prepare PR de `<branch>` para `release` no GitHub com resumo, mudanças,
  testes, riscos e checklist.
- Use o `gh` CLI apenas se já estiver instalado e autenticado. Não instale, não
  autentique e não altere defaults sem aprovação.
- Criar o PR não autoriza aprová-lo, fazer merge ou apagar branch.

## Encerramento

Ao final de cada fase, registre evidências objetivas: arquivos analisados ou
alterados, comandos executados, resultados, riscos remanescentes e a única
aprovação necessária para continuar.
