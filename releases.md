# Releases (Changelog) — EasyEnv

> Este arquivo descreve, versão a versão, tudo que foi incluído/alterado/corrigido no EasyEnv.
> Para saber a versão atual, consulte a seção **“Release version”** no `README.md`.

---

## 0.0.7 — i18n, Preferências & Docs
**Data:** YYYY-MM-DD

### Adicionado
- Serviço de preferências do usuário (`config/user_preferences.yml`) e comandos para leitura/escrita.
- Suporte a i18n (pt/en) com arquivos em `presenter/environment/i18n`.
- Comando `easyenv lang set <pt|en>`.
- Documentação refinada: `README.md` (inclui “Release version”), `STACKS.md` e `CONTRIBUTING.md`.

### Alterado
- Mensagens dos comandos passaram a respeitar o idioma configurado.

### Corrigido
- Ajustes gerais de UX de mensagens e fallbacks.

---

## 0.0.6 — Utilitários de IA & Helpers
**Data:** YYYY-MM-DD

### Adicionado
- Instalação e bootstrap da CLI do Google Gemini (subcomando `easyenv ai ...`).
- **Gerador de `curl`**: `easyenv curlgen` (modo interativo).
- **CPF**: `easyenv cpf gen` e `easyenv cpf check <número>`.
- **Criador de API**: `easyenv api new` com templates em `presenter/environment/assets`.

### Alterado
- Melhoria nas mensagens de confirmação com uso de templates.

---

## 0.0.5 — Apps & Processos
**Data:** YYYY-MM-DD

### Adicionado
- `easyenv apps install <app...>` (ex.: vscode, postman, iterm).
- `easyenv ps` (listar processos com filtros).
- `easyenv kill --pid <PID>` / `easyenv kill --name <processo>` com confirmação.
- `easyenv sysinfo` (visão geral do sistema; integra `fastfetch`/`neofetch` se disponíveis).

---

## 0.0.4 — Backup/Restore + Clean/Update + Theme
**Data:** YYYY-MM-DD

### Adicionado
- `easyenv backup -list | -restore [ -latest | <arquivo> ] | -delete | -purge <N>`.
- Seleção interativa de backups com `fzf` e fallback numérico.
- `easyenv clean` robusto (`-soft` / `-all` / `--dry-run` / por seção / por tool).
- `easyenv update` (`--outdated`, `--dry-run`, all/section/tools).
- Gerenciador de tema (`easyenv theme list|install|set|apply|wizard`).

### Alterado
- Backups migram para `var/backups/`.
- Status detalhado agora lista últimos backups formatados (data/tamanho).

---

## 0.0.3 — Plugins essenciais + Versions/Switch/Doctor + Sync
**Data:** YYYY-MM-DD

### Adicionado
- Contrato de plugins: `tool_install`, `tool_uninstall`, `tool_update`, `tool_versions`, `tool_switch`, `tool_origin`, `doctor_tool`.
- Plugins: `oh-my-zsh`, `git`, `fzf`, `node` (nvm), `flutter` (fvm), `android` (sdkmanager).
- `easyenv versions <tool>` e `easyenv switch <tool> <versão>`.
- `easyenv doctor [<tool>]`.
- `easyenv sync` (espelha ambiente real → `var/snapshot/.zshrc-tools.yml`).
- `status --detailed` usa snapshot + plugins para detectar origem/versão.

### Corrigido
- Normalização PATH e deduplicação (`typeset -U path PATH`) nos prelúdios.

---

## 0.0.2 — Init & Stacks (MVP de instalação)
**Data:** YYYY-MM-DD

### Adicionado
- `easyenv init` com 3 caminhos:
  - **do zero** (gera `~/.zshrc` a partir de `config/default.zshrc` + prelúdios),
  - **default** (instala CLI Tools básicas),
  - **stack** (wizard para `flutter`, `web/react`, `.NET`).
- Stacks iniciais:
  - `react` (node + react + react-native),
  - `flutter` (fvm + android sdk básico),
  - `dotnet` (brew + `global.json`).
- i18n seeds (`pt.json`/`en.json`) e service de tradução.

---

## 0.0.1 — Bootstrap DDD (Fundação)
**Data:** YYYY-MM-DD

### Adicionado
- Estrutura DDD:
  - `presenter/` (cli, templates, viewmodels, environment),
  - `domain/` (entities, enums, usecases),
  - `data/` (plugins, datasources, services),
  - `core/` (config, utils, logging, guards, router),
  - `var/` (logs, backups, snapshot),
  - `config/` (`default.zshrc`, `.env`, `user_preferences.yml`),
  - `docs/` (esqueletos).
- `src/main.sh` + `core/router.sh` com dispatch básico.
- `help`, `version`, `status` (básico) funcionando.
- Prelúdios `.zprofile`/`.zshrc` idempotentes e `default.zshrc` base.

---

## Notas
- Para manter o changelog conciso, níveis de detalhe finos (commits/PRs) devem ir no **dev-log** separado.
- O `README.md` deve conter a **Release version atual** lida pela ferramenta.