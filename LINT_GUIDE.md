# Guia de Lint e Qualidade para Go — 2025

## 1. Objetivo e escopo

Este documento define um padrão unificado de lint, formatação e verificações estáticas para projetos em Go. As regras foram escolhidas para maximizar legibilidade, segurança, performance e consistência entre serviços. Aplica-se a todo repositório Go mantido pela equipe, incluindo binários, bibliotecas e ferramentas de suporte.

## 2. Versão e ferramentas de base

A base mínima suportada é Go 1.22+. A suíte de análise obrigatória utiliza `golangci-lint` como orquestrador, complementada por `gofumpt` para formatação, `gci` para ordenação de imports e `go vet`/`staticcheck` para diagnósticos avançados. A execução local é mandatória via `make lint` e a execução em CI é bloqueante para merge.

## 3. Formatação e estilo

A formatação do código é inteiramente automática. Utilize `gofumpt` sobre `gofmt` para regras estritas e previsíveis. Não são aceitas formatações manuais divergentes. Arquivos devem respeitar `editorconfig` com indentação por tabs, largura de linha alvo 100 colunas e quebra automática quando aplicável por ferramentas.

## 4. Organização de imports

Os imports são organizados em três grupos, nessa ordem: padrão (`std`), terceiros (`external`), e locais do módulo (`internal/local`). Cada grupo é separado por uma linha em branco. É proibido alias redundante, exceto colisão de nomes ou para pacotes com nomes genéricos.

## 5. Convenções de nomenclatura

Nomes exportados usam `CamelCase` e exigem comentário com frase completa iniciando com o nome do item. Nomes não exportados usam `camelCase`. É proibido `snake_case` em identificadores. Evite gagueira de pacote: o nome do tipo ou função não repete o nome do pacote.

## 6. Erros

Erros são valores, propagados com wrapping usando `%w` em `fmt.Errorf`. A comparação de erros usa `errors.Is`/`errors.As`. Mensagens de erro iniciam em minúsculas, sem pontuação final, e não incluem o nome do pacote. Não utilizar `panic` para fluxo normal; `panic` é restrito a inicialização fatal incontornável. Erros sentinela exportados seguem padrão `var ErrX = errors.New("...")`.

## 7. Contexto e cancelamento

Funções públicas que executam I/O, chamadas remotas, acesso a banco ou operações potencialmente bloqueantes recebem `ctx context.Context` como primeiro parâmetro. Não armazene `Context` em estruturas. Respeite prazos; derive `context.WithTimeout` no limite mais próximo do consumidor.

## 8. Concorrência

Evite `goroutine leaks`: toda goroutine deve ter caminho de término. Prefira canais com buffer explícito quando aplicável. Use `sync/atomic` para contadores concorrentes simples. Proteja mapas compartilhados com `sync.Mutex` ou `sync.Map`. Testes sensíveis à concorrência devem rodar com `-race` no CI.

## 9. Logging

Use a biblioteca de logging aprovada do repositório. Logs estruturados em nível `info`, `warn`, `error`. Não logue dados sensíveis. Mensagens curtas, campos semânticos, e correlação por `trace_id`/`request_id` quando presente no contexto.

## 10. Comentários e documentação

Todo item exportado deve ter comentário em forma de sentença. Comentários de pacote em `doc.go` descrevem responsabilidades, contratos e invariantes. Comentários não repetem o óbvio nem se tornam desatualizados por explicar “como” em vez de “porquê”.

## 11. Testes

Testes usam `testing`, com subtests e `t.Helper()` para utilidades. Nomes de teste descrevem comportamento. Utilize `-race` e cobertura mínima definida pelo repositório. Para código com relógio, injete `time.Now` via dependência. Para I/O externo, prefira testes de integração isolados por build tags.

## 12. Segurança

Ative regras de `gosec` adequadas ao contexto. Valide entradas externas. Evite `md5`/`sha1`. Zere segredos em memória quando pertinente. Não use `exec.Command` com concatenação de entradas externas. Use `net/http` com `Timeouts` definidos e `TLS` forte.

## 13. Performance e alocação

Evite alocações desnecessárias em loops quentes. Prefira `bytes.Buffer` ou `strings.Builder` para concatenação repetida. Para slices, prealocar capacidade quando previsível. Não otimize prematuramente; inclua benchmarks quando justificar micro-otimizações.

## 14. Layout de pacotes

Pacotes pequenos, coesos e com APIs claras. Evite pastas por camada genérica; favoreça pacotes por domínio. O pacote não exporta detalhes acidentais. `internal/` para detalhes que não devem ser importáveis fora do módulo.

## 15. Exceções e supressões

Supressões de lints só são permitidas quando houver justificativa em comentário acima da linha, contendo a regra suprimida e o motivo. Proíba supressões globais sem acordo prévio. Revisões de código devem questionar supressões.

## 16. Configuração de linters (golangci-lint)

A configuração a seguir é a referência para novos repositórios. Ajustes locais exigem aprovação.

```yaml
# .golangci.yml
run:
  go: "1.22"
  timeout: 5m
  tests: true
  skip-dirs:
    - vendor
    - dist
output:
  sort-results: true
  uniq-by-line: true
linters-settings:
  gofumpt:
    extra-rules: true
  gci:
    sections:
      - standard
      - default
      - prefix(github.com/SEU_ORG/SEU_MODULO)
    skip-generated: true
  revive:
    severity: warning
    rules:
      - name: exported
        arguments: ["checkPrivateReceivers" ]
      - name: var-naming
      - name: receiver-naming
      - name: package-comments
      - name: if-return
      - name: range-val-address
      - name: early-return
      - name: errorf
      - name: unexported-return
  depguard:
    list-type: denylist
    packages:
      - log
    packages-with-error-message:
      - log: use the repository logging package
  errcheck:
    check-type-assertions: true
    check-blank: true
  gocritic:
    enabled-checks:
      - appendAssign
      - boolExprSimplify
      - dupImport
      - ifElseChain
      - offBy1
      - rangeExprCopy
      - sloppyReassign
      - typeAssertChain
  misspell:
    locale: US
  nolintlint:
    require-explanation: true
    require-specific: true
linters:
  enable:
    - govet
    - staticcheck
    - gofumpt
    - gci
    - revive
    - gosimple
    - ineffassign
    - typecheck
    - errcheck
    - goconst
    - gocritic
    - misspell
    - gosec
    - nolintlint
  disable:
    - dupl
    - funlen
    - gocyclo
    - wsl
issues:
  exclude-use-default: false
  exclude-rules:
    - path: _test\.go
      linters:
        - gocritic
        - gosec
    - linters:
        - gosec
      text: "G115"   # conversões int para string seguras, avalie caso a caso
    - linters:
        - revive
      text: "stutters"
```

## 17. Formatação automática e ordenação de imports

Aplique `gofumpt` e `gci` no pre-commit. Não aceite PRs que modifiquem somente formatação sem propósito claro. As ferramentas determinam a forma; as revisões focam conteúdo.

### 17.1. EditorConfig de referência

```ini
# .editorconfig
root = true

[*]
charset = utf-8
indent_style = tab
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
max_line_length = 100
```

## 18. Makefile e alvos padronizados

Forneça os alvos `fmt`, `lint`, `test` e `ci` para padronizar a experiência.

```makefile
fmt:
	gofumpt -l -w .
	gci write -s standard -s default -s prefix(github.com/SEU_ORG/SEU_MODULO) .

lint:
	golangci-lint run

test:
	go test ./... -race -cover

ci: fmt lint test
```

## 19. Pre-commit

Habilite validações locais com `pre-commit` para garantir feedback imediato.

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/mvdan/gofumpt
    rev: v0.6.0
    hooks:
      - id: gofumpt-rewrite
  - repo: https://github.com/daixiang0/gci
    rev: v0.13.5
    hooks:
      - id: gci
        args: ["write", "-s", "standard", "-s", "default", "-s", "prefix(github.com/SEU_ORG/SEU_MODULO)", "."]
  - repo: https://github.com/golangci/golangci-lint
    rev: v1.60.0
    hooks:
      - id: golangci-lint
```

## 20. Regras práticas por exemplo

Erros compostos: `fmt.Errorf("reading user %s: %w", id, err)`. Comparações: `if errors.Is(err, context.DeadlineExceeded) { ... }`. Receivers: tipos pequenos por valor; tipos com mutex ou grandes por ponteiro. Strings vs bytes: prefira `[]byte` em I/O binário.

## 21. Política de evolução

As versões das ferramentas serão revisadas trimestralmente. Novas regras entram em modo aviso por um ciclo completo antes de se tornarem bloqueantes. Alterações que quebram histórico exigem migração automatizada documentada em `tools/`.

## 22. Checklist para PR

O autor confirma formatação aplicada, imports organizados, `golangci-lint` sem falhas, testes rodados com `-race`, e ausência de supressões sem justificativa. Revisores verificam mensagens de commit claras e cobertura adequada.

## 23. Anexos

Arquivos de exemplo devem ser copiados para a raiz do repositório: `.golangci.yml`, `.editorconfig`, `.pre-commit-config.yaml`, `Makefile`. Ajuste o prefixo do módulo em `gci` conforme o `go.mod`.
