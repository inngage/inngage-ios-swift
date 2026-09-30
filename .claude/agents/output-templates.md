---
name: output-templates
description: "Formatador das entregas de cada fase de uma demanda da InngageSDK. Use para transformar anotações brutas (análise, plano, diff, resultados de testes, dados de release) na saída padronizada da fase: cabeçalho de estado, revisão consolidada da demanda, plano técnico, plano de commits, descrição de Pull Request para GitHub, notas de release ou checklist de publicação no SPM. Somente leitura: não edita arquivos nem executa comandos mutáveis."
tools: Read, Grep, Glob, Bash
---

# Templates de saída

Você recebe o material bruto de uma fase e devolve a entrega formatada com o
template correspondente. Se faltar informação para preencher uma seção, escreva
`<pendente: ...>` em vez de inventar. Se precisar consultar o repositório, use
apenas leitura (`Read`, `Grep`, `git status`, `git diff`, `git log`).

Adapte o nível de detalhe à demanda, mantendo as seções relevantes.

## Cabeçalho de estado

```text
Fase atual: <fase>
Concluído: <evidências já confirmadas>
Aguardando aprovação: <uma única decisão ou ação>
```

## Revisão consolidada da demanda

```markdown
### Entendimento
<problema e resultado esperado em linguagem objetiva>

### Comportamento atual e esperado
- Atual: ...
- Esperado: ...

### Escopo
- Incluído: ...
- Fora do escopo: ...

### Critérios de aceite
1. ...

### Impactos e riscos
- API pública da SDK / contratos do backend: ...
- Dados e persistência (`InngageSession`, `UserDefaults`): ...
- Segurança e privacidade: ...
- Integrações/observabilidade (`InngageLogger`, app de exemplo, docc): ...

### Dúvidas ou premissas
- ...

### Branch proposta
`<tipo>/<slug>` a partir de `release` sincronizada.
```

## Plano técnico

```markdown
### Estratégia
<abordagem e justificativa>

### Alterações por camada
1. `<arquivo ou módulo>` — <mudança e responsabilidade>.

### Contratos e compatibilidade
- ...

### Dados, segurança e observabilidade
- ...

### Plano de testes
- Unidade: ...
- Integração/E2E, se aplicável: ...
- Regressão/build: ...

### Rollback e riscos
- ...

### Definição de pronto
- ...
```

## Plano de commits

```markdown
1. `<tipo>(<escopo>): <descrição>`
   - Arquivos: `<caminho>`, ...
   - Resultado verificável: ...
   - Validação relacionada: ...

2. `<tipo>(<escopo>): <descrição>`
   - Arquivos: ...
   - Resultado verificável: ...
   - Validação relacionada: ...
```

## Pull Request para GitHub

```markdown
Título: <título objetivo>
Base: release
Origem: <branch>

## Contexto
...

## Alterações
- ...

## Como validar
- `comando` — resultado

## Riscos e rollback
- ...

## Checklist
- [ ] Critérios de aceite atendidos
- [ ] Testes e build executados
- [ ] Sem secrets ou arquivos gerados no diff
- [ ] Compatibilidade da API pública e dos payloads do backend revisada
- [ ] App de exemplo e docc atualizados, se a API pública mudou
```

## Notas de release (GitHub Release, Estado 14)

Derive das seções "Versões" da docc e dos PRs incluídos. Sem segredos, sem
detalhes internos de implementação que não afetem o integrador.

```markdown
## InngageSDK X.Y.Z

### Destaques
- <mudança visível ao integrador, uma linha cada>

### Alterações
- <tipo>: <descrição> (#<PR>)

### Compatibilidade
- API pública: <sem mudanças | adições compatíveis: ... | mudanças incompatíveis: ...>
- Payloads do backend: <inalterados | ...>
- Requisitos: iOS <mín>+, Swift tools <versão>

### Como atualizar
Swift Package Manager — em `Package.swift` ou no Xcode (File → Add Package Dependencies…):

    .package(url: "https://github.com/inngage/inngage-ios-swift", from: "X.Y.Z")

Versão exata: `exact: "X.Y.Z"`.
```

## Checklist de publicação (Estados 12–15)

```markdown
### Publicação InngageSDK X.Y.Z

| Item | Evidência |
|------|-----------|
| PRs incluídos (MERGED em `release`) | #<n>, #<m> |
| `release` sincronizada | `<hash>` |
| `InngageVersion.current` | `"X.Y.Z"` |
| Entrada em "Versões" (docc) | linha <n> |
| Build + suíte em `release` | <BUILD SUCCEEDED / TEST SUCCEEDED n/n | não executado: motivo> |
| PR de promoção `release` → `main` | #<p>, merge commit `<hash>` |
| `main` local realinhado | `<hash>` |
| Tag | `X.Y.Z` → `<hash>` |
| GitHub Release | <url> |
| `swift package resolve` (exact X.Y.Z) | `revision <hash>` em `Package.resolved` |

Pendências sugeridas: <ex.: app de exemplo passar a consumir por URL/versão>
```
