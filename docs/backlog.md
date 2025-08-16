1) Fundação do projeto (repo + esqueleto)

Objetivo: repo pronto para trabalhar e instalar com 1 comando.

 Criar repositório easyenv (público) com estrutura:

easyenv/
  src/{bin,core,config,logs,tests}
  docs/
  README.md  LICENSE  .gitignore  src/install.sh


 Adicionar .gitignore completo (o que definimos).

 Colocar LICENSE MIT (com seus dados).

 README na raiz (visão geral + 1-liner de instalação placeholder).

Entregáveis: repo inicial, src/install.sh com bootstrap mínimo (clona/atualiza, instala yq, cria symlink easyenv).

Sucesso: curl .../install.sh | bash instala easyenv e easyenv help responde.

2) Núcleo do CLI (roteador + utilitários)

Objetivo: comando único com subcomandos e logging.

 src/bin/easyenv.sh (roteador): help | status | init | clean | restore | update | backup | add | configure | theme

 src/core/utils.sh: cores, log_info/ok/err, confirm, ensure_dir, append_once, require_cmd.

 src/core/workspace.sh: paths ($EASYENV_HOME=~/easyenv), arquivos (config/.zshrc-tools.yml), histórico (logs/easyenv.log), log_line.

 src/config/.zshrc-tools.yml (snapshot padrão mínimo) e src/config/tools.yml (catálogo opcional).

Entregáveis: easyenv help, easyenv status listando nada/placeholder, log funcional.

Sucesso: easyenv help mostra subcomandos; logs/easyenv.log recebe linha por execução.

3) Leitura do snapshot + catálogo

Objetivo: EasyEnv lê YAML e sabe “o que” instalar.

 Integrar yq (validar e falhar com mensagem amigável se faltar).

 Funções cfg_get, snap_get, list_sections, list_tools_by_section, tool_field.

 Preferências globais: init.steps_mode_default, skip_sections, run_interactive_configs.

Entregáveis: easyenv status lista seções e ferramentas a partir do YAML.

Sucesso: editar o YAML muda a saída do status sem tocar no código.

4) init com -steps (instalação guiada por seção)

Objetivo: instalar por seção, com confirm prompts.

 easyenv init [-steps]: itera seções; por seção, chama install_tool.

 install_tool: suporta brew formula/cask, blocos install (bash), env (append no .zshrc), aliases.

 Respeitar pins.<tool>.enabled=false no snapshot.

Entregáveis: instalação de uma seção simples (ex.: CLI Tools) funcionando.

Sucesso: easyenv init -steps instala uma seção e configura PATH/Aliases no .zshrc.

5) Gerenciador de temas (themes.sh)

Objetivo: aplicar tema do catálogo ou escolhido no snapshot.

 src/core/themes.sh: theme_catalog_list, install_theme_from_catalog, set_zsh_theme, snippets extra.

 easyenv theme list|install|apply.

 init: se workspace.theme.selected existir → aplica automaticamente; senão, oferece escolha.

Entregáveis: suporte a powerlevel10k, spaceship, starship (com notas/config).

Sucesso: trocar tema com easyenv theme install powerlevel10k + apply reflete no prompt.

6) Pós-ações por stack (pins)

Objetivo: pós-instalações automáticas baseadas no snapshot.

 post_actions_apply:

FVM: instalar versões, setar default, rodar post_switch.

NVM: instalar versões e definir default.

Android: yes | sdkmanager --licenses se habilitado.

CocoaPods: pod setup opcional.

AWS CLI: aws configure opcional.

Entregáveis: snapshot controla comportamentos após init/restore.

Sucesso: alterar pins no YAML altera comportamento sem mexer no código.

7) clean (soft/hard) e restore

Objetivo: limpeza segura + restauração parcial/total.

 easyenv clean [-soft|-hard] [-stack <sec>] [-steps] [<tool>]

 easyenv restore [-all|-backup|-section <sec>|<tool>|-steps]

 Confirmar antes de ações destrutivas.

Entregáveis: limpeza só de caches (-soft) e remoção total (-hard), restauração por seção.

Sucesso: easyenv clean -steps pergunta seção a seção; tudo logado.

8) update, status, backup

Objetivo: manutenção do ambiente.

 update [-all|-section <sec>|-outdated|-deprecated|-steps]

 status mostra versão instalada + outdated por brew (quando possível).

 backup zipa ~/.zshrc e ~/easyenv → ~/.easyenv-backup-<timestamp>.zip.

Entregáveis: operações visíveis e confiáveis.

Sucesso: cada subcomando escreve 1 linha no log com status=success|error.

9) add <ferramenta>

Objetivo: expandir workspace via CLI.

 Detectar fórmula/cask com brew info/brew search.

 Instalar, gerar bloco no YAML (tools[]), aplicar env/aliases, e logar.

 Guardrails: nome já existe, rollback em falha.

Entregáveis: easyenv add htop adiciona e instala.

Sucesso: status já enxerga a nova ferramenta sem reiniciar nada.

10) Qualidade: testes + docs + versão

Objetivo: confiabilidade e experiência de uso.

 src/tests/test_init.sh, test_clean.sh, test_restore.sh (smoke tests).

 docs/INSTALL.md, docs/ARCHITECTURE.md, docs/CONTRIBUTING.md.

 Versionamento semântico: EASYENV_VERSION em easyenv.sh.

 install.sh refinado (Apple Silicon/Intel; sem git fallback via curl).

Entregáveis: tag v0.1.0 com release notes curtas.

Sucesso: alguém novo instala e roda easyenv init -steps sem te perguntar nada.

11) Distribuição (opcional nesta rodada)

Objetivo: 1-liner e/ou Homebrew Tap.

 One-liner oficial no README:

curl -fsSL https://raw.githubusercontent.com/dippingcode/easyenv/main/src/install.sh | bash


 Tap opcional: homebrew-easyenv com fórmula easyenv.rb (instala easyenv).

Sucesso: usuários instalam pelo 1-liner ou brew tap dippingcode/easyenv && brew install easyenv.

Quickstart imediato (o que eu faria agora)

Criar repo github.com/dippingcode/easyenv.

Subir estrutura + arquivos mínimos:

src/bin/easyenv.sh com help e roteador.

src/core/{utils.sh,workspace.sh} (mínimos).

src/install.sh (bootstrap cria symlink e instala yq).

README.md, LICENSE, .gitignore.

Testar localmente:

curl -fsSL https://raw.githubusercontent.com/dippingcode/easyenv/main/src/install.sh | bash
easyenv help


Implementar Fase 4 (init -steps) em cima de um YAML pequeno (ex.: CLI Tools).

Critérios gerais de “pronto” (DoD)

Idempotência: rodar o mesmo comando 2x não quebra nada.

Reprodutibilidade: configurar máquina A e B partindo do zero deve dar o mesmo resultado.

Logs: cada execução grava uma linha clara com comando, parâmetros, status e resumo.

Não intrusivo: nunca sobrescrever .zshrc sem backup .bak e sem marcador.

Erros amigáveis: require_cmd yq → mensagem clara com como instalar.