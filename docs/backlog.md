perfeito — vamos organizar o backlog por versões (semver pré-1.0), já alinhado à nova arquitetura e às features pedidas. cada versão tem objetivo, escopo, tarefas, critérios de aceite e smoke tests.

⸻

0.0.1 — Bootstrap DDD (fundação)

Objetivo: criar a espinha dorsal DDD, portar comandos mínimos e deixar rodando.

Escopo
	•	Estrutura de pastas final (src/, presenter/, domain/, data/, core/, var/, config/, docs/).
	•	src/main.sh + core/router.sh + core/config.sh + core/utils.sh + core/logging.sh + core/guards.sh.
	•	presenter/cli: help.sh, version.sh, status.sh (básico), home.sh (banner simples).
	•	presenter/templates: formatters.sh (cores/humanize), table.sh (render básico), prompts.sh (confirm/select com fallback).
	•	data/datasources: yaml_repo.sh, zshrc_repo.sh, filesystem_repo.sh, brew_repo.sh (stubs funcionais).
	•	config/default.zshrc, config/user_preferences.yml, config/.env.
	•	docs/INSTALL.md, docs/STACKS.md (esqueleto), docs/CONTRIBUTING.md (esqueleto).
	•	Release version: adicionar seção “Release version” no README.md e função em core/config.sh para ler a versão dali (ex.: primeira linha Release: 0.0.1).

Critérios de aceite
	•	./src/main.sh help|version|status executam sem erro.
	•	status mostra HOME/CFG/SNAPSHOT + checagem dos prelúdios (sem detalhar ferramentas ainda).
	•	router despacha comandos e lida com “unknown-command”.

Smoke tests

./src/main.sh help
./src/main.sh version
./src/main.sh status


⸻

0.0.2 — Init & Stacks (MVP de instalação)

Objetivo: entregar uma instalação guiada útil desde o dia 1.

Escopo
	•	presenter/cli/init.sh com 3 caminhos:
	1.	Do zero: cria ~/.zshrc a partir de config/default.zshrc + prelúdios.
	2.	Default: instala “CLI Tools” (oh-my-zsh, git, fzf).
	3.	Stack: wizard para flutter, web/react, dotnet (primeiro corte).
	•	domain/usecases/stack_wizard_uc.sh.
	•	Stacks:
	•	data/stacks/react/stack.sh (node + @latest react-cli + react-native cli via npm global; env mínimo).
	•	data/stacks/flutter/stack.sh (flutter via fvm + android sdk básico; iOS placeholder com instruções).
	•	data/stacks/dotnet/stack.sh (placeholder com instalação via brew e global.json).
	•	i18n seed: presenter/environment/i18n/pt/pt.json e en/en.json + data/services/i18n_service.sh.

Critérios de aceite
	•	easyenv init exibe menu e executa cada caminho com sucesso.
	•	Após “Default” ou “Stack”, status --detailed começa a mostrar algo (mesmo que parcial).

Smoke

easyenv init
easyenv status --detailed


⸻

0.0.3 — Plugins essenciais + Versions/Switch/Doctor

Objetivo: gerenciamento real de ferramentas.

Escopo
	•	Contrato de plugin (funções): tool_install, tool_uninstall, tool_update, tool_versions, tool_switch, tool_origin, doctor_tool.
	•	Plugins: oh-my-zsh, git, fzf, node (nvm), flutter (fvm), android (sdkmanager).
	•	presenter/cli/versions.sh e switch.sh.
	•	presenter/cli/doctor.sh (global e por tool).
	•	presenter/cli/sync.sh + domain/usecases/detect_env_uc.sh (espelhar ambiente real → var/snapshot/.zshrc-tools.yml).
	•	presenter/viewmodels/status_vm.sh e tools_vm.sh (corrigir status --detailed para ler snapshot e plugins).

Critérios de aceite
	•	easyenv versions node|flutter lista e marca versão ativa.
	•	easyenv switch node lts / switch flutter <ver> funcionam.
	•	easyenv doctor mostra diagnóstico por ferramenta; doctor node detalha.
	•	easyenv sync faz status --detailed refletir o ambiente real.

Smoke

easyenv versions node
easyenv switch node lts
easyenv doctor
easyenv sync && easyenv status --detailed


⸻

0.0.4 — Backup/Restore + Clean/Update robustos + Theme

Objetivo: manutenção do ambiente.

Escopo
	•	presenter/cli/backup.sh: -list, -restore, -restore -latest, -delete, -purge N (com fzf e fallback numérico).
	•	presenter/cli/restore.sh → usa usecase restore_from_backup_uc.sh.
	•	presenter/cli/clean.sh: -soft|-all, -section, --dry-run, por tool (usa plugins antes do fallback).
	•	presenter/cli/update.sh: --outdated, --dry-run, all/section/tools.
	•	presenter/cli/theme.sh + data/services/theme_service.sh (list/install/set/apply/wizard).
	•	presenter/viewmodels/backups_vm.sh (formatar tamanho/data e seleção interativa).

Critérios de aceite
	•	Backup ZIPs em var/backups/ e listagem amigável.
	•	Clean -soft não remove tools; -all remove conforme catálogo/plug-ins.
	•	Update com --outdated e --dry-run operando.
	•	theme instala p10k/spaceship e aplica no .zshrc.

Smoke

easyenv backup -list
easyenv backup -restore -latest
easyenv clean -soft
easyenv update --outdated
easyenv theme list && easyenv theme install powerlevel10k && easyenv theme apply


⸻

0.0.5 — Apps & Processos

Objetivo: produtividade do dia a dia.

Escopo
	•	presenter/cli/apps.sh: instalar apps via brew cask (Postman, VSCode, iTerm).
	•	presenter/cli/ps.sh: listar processos (filtros comuns).
	•	presenter/cli/kill.sh: encerrar por PID/por nome (com confirmação).
	•	status do sistema: comando sysinfo (CPU/Mem/Disk; usa fastfetch/neofetch se disponíveis).

Critérios de aceite
	•	easyenv apps install vscode postman iterm funciona.
	•	easyenv ps lista; easyenv kill --pid 1234 pede confirmação.

Smoke

easyenv apps install iterm
easyenv ps
easyenv kill --pid <algum PID seu com segurança>


⸻

0.0.6 — Ferramentas de IA & Helpers

Objetivo: utilitários inteligentes.

Escopo
	•	Instalar CLI do Google Gemini (presenter/cli/ai.sh com subcomandos install, auth, chat placeholder).
	•	Gerador de curl: easyenv curlgen (prompt interativo ou YAML → comando curl).
	•	Gerador de CPF (válido) e validador: easyenv cpf gen|check.
	•	Criador de API (scaffolder): easyenv api new (templates em presenter/environment/assets).
	•	Prompts: presenter/environment/prompts/ catálogo (para futura integração).

Critérios de aceite
	•	easyenv cpf gen gera e cpf check <num> valida.
	•	easyenv curlgen produz comando funcional.
	•	easyenv ai install instala o binário/SDK necessário e orienta auth.

Smoke

easyenv cpf gen
easyenv curlgen
easyenv ai install


⸻

0.0.7 — i18n, Preferências & Docs

Objetivo: polimento final do MVP.

Escopo
	•	data/services/user_preference_service.sh (ler/gravar config/user_preferences.yml).
	•	Seleção de idioma easyenv lang set pt|en (i18n service).
	•	Revisão dos textos (pt/en) em presenter/environment/i18n.
	•	README.md completo (inclui Release version consultada pela tool).
	•	STACKS.md e CONTRIBUTING.md finalizados.

Critérios de aceite
	•	easyenv lang set en troca idioma das mensagens.
	•	easyenv status reflete i18n e preferências.

Smoke

easyenv lang set en
easyenv help


⸻

Patches (manutenção contínua)
	•	0.0.x correções de bugs de plugins/stack, melhorias de UX (fzf, mensagens), compatibilidade macOS.

⸻

Qualidade & Portas de entrada
	•	Shellcheck em core/, presenter/cli/, domain/, data/.
	•	Bats (smoke tests) para help/version/status/init/backup/clean/update.
	•	Logs em var/logs/easyenv.log com níveis e timestamps.

⸻

Migração do legado
	1.	Mover arquivos existentes para as novas pastas (sem alterar funções).
	2.	Ajustar paths: CFG_FILE → config/tools.yml, SNAP_FILE → var/snapshot/.zshrc-tools.yml, backups → var/backups/.
	3.	Substituir antigo easyenv.sh por src/main.sh + core/router.sh.
	4.	Plugins e stacks: começar pelos essenciais (node/flutter/android/oh-my-zsh/git/fzf) e evoluir.

⸻

Definição de pronto (DoD) por item
	•	Código com set -euo pipefail.
	•	Mensagens i18n via service (quando aplicável).
	•	Idempotência e --dry-run para operações destrutivas.
	•	Documentado em README/STACKS.
	•	Smoke tests passando.

⸻

se curtir esse plano, eu já te escrevo os esqueletos de src/main.sh, core/router.sh, presenter/cli/help.sh|version.sh|status.sh (0.0.1) prontos pra colar e rodar.