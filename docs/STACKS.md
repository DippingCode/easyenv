# Stacks de Desenvolvimento (EasyEnv)

Este documento descreve as **stacks** suportadas pelo EasyEnv, como instalá-las via `easyenv init`, o que cada uma inclui e como estender/ criar novas stacks.

> **Resumo rápido**
>
> * `easyenv init -mode stack -stack flutter`
> * `easyenv init -mode stack -stack dotnet`
> * `easyenv init -mode stack -stack web`

---

## Índice

* [Modos de instalação](#modos-de-instalação)
* [Stacks suportadas](#stacks-suportadas)

  * [Flutter](#flutter)
  * [.NET](#net)
  * [Web](#web)
* [Comandos úteis](#comandos-úteis)
* [Pré-requisitos e observações por stack](#pré-requisitos-e-observações-por-stack)
* [Como estender as stacks](#como-estender-as-stacks)

  * [Adicionar ferramenta no `tools.yml`](#adicionar-ferramenta-no-toolsyml)
  * [Adicionar plugin com lógica própria](#adicionar-plugin-com-lógica-própria)
* [Perguntas frequentes (FAQ)](#perguntas-frequentes-faq)

---

## Modos de instalação

O `easyenv init` oferece três modos:

* **zero**: limpa blocos EasyEnv no `~/.zshrc`, reaplica *prelúdios* e prepara o terreno.
  Não desinstala fórmulas do Homebrew. É um “reset” de configuração.
* **default**: instala **todo** o catálogo definido em `src/config/tools.yml` (por seções).
  Pode ser **interativo** com `-steps` (perguntas seção a seção e por ferramenta).
* **stack**: instala apenas ferramentas relacionadas a uma stack específica (**flutter**, **dotnet**, **web**).

### Exemplos

```bash
# Modo zero (reset de blocos no zshrc) e depois escolha do fluxo
easyenv init -mode zero

# Modo default com perguntas por seção e confirmação automática
easyenv init -mode default -steps -y

# Instalar apenas a stack Flutter e recarregar o shell ao final
easyenv init -mode stack -stack flutter -reload
```

---

## Stacks suportadas

Abaixo, a matriz do que cada stack instala, **via plugin** quando existir, **via catálogo** (`install_tool`) e por fim **fallback brew/cask**:

| Stack   | Ferramentas (núcleo)                                                                                       | Observações                                                                |
| ------- | ---------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| Flutter | `flutter`, `android`, `java`, `kotlin`, `firebase`, `supabase`                                             | `flutter` já traz `dart`. Android SDK + AVDs; Xcode manual/cask opcional.  |
| .NET    | `dotnet`                                                                                                   | Suporte a `global.json` (*switch*) e múltiplos SDKs.                       |
| Web     | **Runtimes:** `node` (via NVM) e/ou `deno` • **Frameworks:** `angular` (npm global) e/ou utilitários React | Perguntas guiadas no `init` para escolher Node/Deno e Angular/React/ambos. |

> Dica: você pode rodar `easyenv versions <tool>` para ver versões instaladas e a versão em uso (quando suportado pelo plugin da ferramenta).

### Flutter

Inclui:

* `flutter` (SDK via FVM quando aplicável)
* `android` (SDK, `platform-tools`, `emulator`, `cmdline-tools`)
* `java`, `kotlin` (JDK/JRE; troca de JDK via `use_jdk 17|21|23`)
* `firebase` (CLI)
* `supabase` (CLI)

### .NET

Inclui:

* `dotnet` (SDK), com suporte a:

  * `easyenv switch dotnet <versão> --scope here|global` (gera `global.json`)
  * `easyenv versions dotnet` (lista SDKs)
  * `easyenv doctor dotnet` (checagens rápidas)

### Web

Fluxo interativo:

* **Runtimes**: escolher `node` (NVM) e/ou `deno`
* **Frameworks**:

  * `angular` (CLI via npm global)
  * React (instala utilitário `create-vite` como exemplo prático, se `npm` presente)

---

## Comandos úteis

```bash
# Instalar stack diretamente
easyenv init -mode stack -stack flutter
easyenv init -mode stack -stack dotnet
easyenv init -mode stack -stack web

# Versões instaladas por ferramenta (quando plugin suporta)
easyenv versions flutter
easyenv versions dotnet
easyenv versions node
easyenv versions deno
easyenv versions java
easyenv versions python
# etc.

# Trocar versão (quando suportado)
easyenv switch flutter 3.13.9
easyenv switch node lts
easyenv switch dotnet 8.0.303 --scope here

# Verificar saúde do ambiente
easyenv doctor
easyenv doctor android
easyenv doctor flutter
```

---

## Pré-requisitos e observações por stack

### Android (para Flutter/Web com Android, etc.)

* **Android Studio** (recomendado para gerenciar SDK/AVDs)
* Verifique `sdkmanager`, `adb` e `emulator` no `PATH`.
* Variáveis esperadas (injetadas pelo EasyEnv quando Android está no catálogo):

  ```bash
  export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
  export ANDROID_HOME="$ANDROID_SDK_ROOT"
  export PATH="$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
  ```

### iOS/Xcode (para Flutter iOS)

* Instale **Xcode** (App Store) e aceite as licenças:

  ```bash
  sudo xcodebuild -license
  ```
* Simulador: `open -a Simulator`
* Variável usada com frequência:

  ```bash
  export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
  ```

### Node / NVM

* O plugin de `node` carrega `nvm` (Homebrew) e consegue:

  * Mostrar versões instaladas
  * Indicar se a versão em uso está “fora do NVM”
  * `easyenv switch node <versão|lts>`

### .NET

* Múltiplos SDKs podem coexistir; pinagem via `global.json` por projeto ou global.
* `easyenv switch dotnet <versão> --scope here|global`

---

## Como estender as stacks

Você pode ampliar o que cada stack instala de duas formas:

### Adicionar ferramenta no `tools.yml`

Inclua a ferramenta com sua **seção** e **instalador**:

```yaml
tools:
  - name: firebase
    section: Mobile
    manager: npm_global
    npm_global: firebase-tools
    check:
      - "firebase --version"
    zshrc_blocks:
      - id: "EASYENV:FIREBASE"
        content: |
          # (opcional) variáveis/aliases
```

Depois, adicione o nome da ferramenta no array da stack (no `cmd_init`, bloco `-stack flutter`, por exemplo).

### Adicionar plugin com lógica própria

Crie `src/plugins/<tool>/plugin.sh` com as funções (qualquer subset):

* `tool_install`
* `tool_uninstall`
* `tool_update`
* `tool_versions`
* `tool_switch`
* `doctor_tool`

Exemplo mínimo:

```bash
# src/plugins/meutool/plugin.sh
tool_install(){ brew install meutool; }
doctor_tool(){
  command -v meutool >/dev/null 2>&1 && { echo "OK: meutool encontrado"; return 0; }
  echo "FAIL: meutool não encontrado"; return 1
}
```

O `init` tentará **plugin → catálogo → brew/cask** nessa ordem.

---

## Perguntas frequentes (FAQ)

**Posso combinar stacks?**
Sim. Rode `easyenv init -mode stack -stack ...` quantas vezes quiser (ou use `-mode default` para instalar o catálogo inteiro).

**Como limpo o ambiente?**
Use `easyenv clean`:

```bash
easyenv clean -soft          # limpa blocos/logs/caches sem desinstalar fórmulas
easyenv clean -all -steps    # desinstala ferramentas do catálogo (pede confirmação)
```

**Como faço backup e restore?**

```bash
easyenv backup                # cria zip em easyenv/backups
easyenv backup -list          # lista backups
easyenv backup -restore       # menu interativo (com fzf, se instalado)
easyenv backup -restore -latest
easyenv backup -delete        # menu para remover
easyenv backup -purge 5       # mantém só os 5 mais novos
```

**E se algo “quebrar” no PATH?**
Reaplique *prelúdios* com:

```bash
easyenv init -mode zero
```

Depois execute o modo `default` ou `stack` desejado.

---

Se quiser, posso gerar uma *checklist* por stack (Android/iOS/Web/.NET) em um arquivo separado `docs/checklists.md`.
