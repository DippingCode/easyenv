# Changelog
Todas as alterações notáveis neste projeto serão documentadas aqui.

## Versions

#### [0.0.2] - 2025-08-18

###### Changed
- Polished `version` command output for both short and detailed versions.

###### Build Details
- Build: 27
- Tag: v0.0.2+27
- Commit: feat(version): polish output format and update build to 27

---


#### [0.0.2] - 2025-08-17 

###### Added
- Implementada a feature `version` com arquitetura em camadas (service, repository, viewmodel, view, route).
- Suporte a flags `-v/--version` para versão resumida e `-d/--detailed` para detalhada.
- Refatoração estrutural para padrão **per-feature**.

###### Changed
- `router.go` atualizado para rotear entre features.
- Adicionado roteador interno `version_route.go`.

###### Notes
- `version_service` ainda mockado; integração futura com build flags ou API.
- Estrutura pronta para implementação da feature `help`.

###### Next Steps
- Implementar a feature `help`.
- Evoluir `version_service` para usar dados reais de build.

###### Build Details
- Build: 26  
- Tag: v0.0.1+26  
- Commit: [feat(version): adiciona service, repository, viewmodel e view com suporte a flags -v/--version](https://github.com/DippingCode/easyenv/commit/<hash>)

---

#### [0.0.1] - 2025-08-15  

###### Added
- Estrutura inicial do projeto em Go.  
- Configuração do `go.mod` e dependência `gopkg.in/yaml.v3`.  
- Estrutura de diretórios base: `core/`, `features/`, `main.go`.  
- Primeira versão do `router.go` para roteamento básico entre features.  

###### Changed
- Migração da versão antiga em shell script para nova base em Go.  

###### Notes
- Ambiente inicial configurado para desenvolvimento no VSCode com suporte a Go.  
- Pronto para receber a primeira feature (`version`).  

###### Build Details
- Build: 25  
- Tag: v0.0.1+25  
- Commit: [chore(init): configura ambiente inicial em Go e estrutura de diretórios](https://github.com/DippingCode/easyenv/commit/<hash>)

---

#### [0.0.1] - 2025-08-17

###### Added
- `easyenv tools install`: instala pré-requisitos e utilitários do catálogo inicial.
- `easyenv tools list`: lista catálogo de ferramentas em YAML, com suporte a:
  - `--detailed`: detecta instalação/versão (`check_version_cmd`, binário, brew).
  - `--json`: imprime `.tools` em JSON.
- Sincronização automática de versões (`version_installed`, `version_latest`) no `config/tools.yml`.
- Bootstrap inicial de ferramentas (`oh-my-zsh`, `powerlevel10k`, `yq`, `fzf`, `zoxide` etc).
- `tools_ds_get_tools`: retorna lista JSON do catálogo de ferramentas.
- `tools_ds_get_tool_by_name`: retorna entidade JSON única por nome.

###### Changed
- Detecção de versões (`installed/latest`) mais robusta:
  - Ordem: `check_version_cmd` → binário (`--version`/`-v`) → `brew list`.
  - “latest” obtido via `brew info --json=v2` com fallback textual.
- `tools list` sincroniza `version_installed/version_latest` no catálogo YAML.
- Fallback seguro em caso de ausência de `yq` ou arquivo inexistente (`[]` ou `{}`).
- Comparação de nomes em `tools_ds_get_tool_by_name` é exata e case-sensitive.

###### Notes
- Para ferramentas sem binário e sem fórmula no brew (ex.: frameworks), a versão permanece “-”.
- Com `jq` instalado, leitura de `brew info --json` é preferida para maior precisão.
- Catálogo YAML corrigido (remoção de marcador `...` inválido).
- Execução segura (`set -euo pipefail`) sem abortar na falta de Homebrew.

###### Next Steps
- Adicionar coluna **Status** (OK/Outdated/Missing).
- Incluir filtros `--only`, `--type`, `--section` no `tools list`.
- Implementar `tools_ds_update_tool` (atualizar entrada no catálogo).
- Conectar `tools install` à configuração do `.zshrc` e variáveis de ambiente.
- Criar `tools doctor` para diagnóstico rápido.

###### Build Details
- Build: 19 → 24  
- Tags relacionadas: `v0.0.1+19` até `v0.0.1+24`  
- Commits principais:  
  - `feat(cli/tools): detectar installed/latest mesmo sem check_version_cmd`  
  - `fix(cli/tools): tolerar falhas de check_version_cmd com pipefail`  
  - `feat(data/datasource): tools_ds_get_tool_by_name retorna entidade JSON por nome`  

#### [0.0.1] - 2025-08-17

###### Added
- `easyenv tools install`: instala pré-requisitos e utilitários do catálogo inicial.
- `easyenv tools list`: lista catálogo de ferramentas em YAML, com suporte a:
  - `--detailed`: detecta instalação/versão (`check_version_cmd`, binário, brew).
  - `--json`: imprime `.tools` em JSON.
- Sincronização automática de versões (`version_installed`, `version_latest`) no `config/tools.yml`.
- Bootstrap inicial de ferramentas (`oh-my-zsh`, `powerlevel10k`, `yq`, `fzf`, `zoxide` etc).
- `tools_ds_get_tools`: retorna lista JSON do catálogo de ferramentas.
- `tools_ds_get_tool_by_name`: retorna entidade JSON única por nome.

###### Changed
- Detecção de versões (`installed/latest`) mais robusta:
  - Ordem: `check_version_cmd` → binário (`--version`/`-v`) → `brew list`.
  - “latest” obtido via `brew info --json=v2` com fallback textual.
- `tools list` sincroniza `version_installed/version_latest` no catálogo YAML.
- Fallback seguro em caso de ausência de `yq` ou arquivo inexistente (`[]` ou `{}`).
- Comparação de nomes em `tools_ds_get_tool_by_name` é exata e case-sensitive.

###### Notes
- Para ferramentas sem binário e sem fórmula no brew (ex.: frameworks), a versão permanece “-”.
- Com `jq` instalado, leitura de `brew info --json` é preferida para maior precisão.
- Catálogo YAML corrigido (remoção de marcador `...` inválido).
- Execução segura (`set -euo pipefail`) sem abortar na falta de Homebrew.

###### Next Steps
- Adicionar coluna **Status** (OK/Outdated/Missing).
- Incluir filtros `--only`, `--type`, `--section` no `tools list`.
- Implementar `tools_ds_update_tool` (atualizar entrada no catálogo).
- Conectar `tools install` à configuração do `.zshrc` e variáveis de ambiente.
- Criar `tools doctor` para diagnóstico rápido.

###### Build Details
- Build: 19 → 24  
- Tags relacionadas: `v0.0.1+19` até `v0.0.1+24`  
- Commits principais:  
  - `feat(cli/tools): detectar installed/latest mesmo sem check_version_cmd`  
  - `fix(cli/tools): tolerar falhas de check_version_cmd com pipefail`  
  - `feat(data/datasource): tools_ds_get_tool_by_name retorna entidade JSON por nome`  

---