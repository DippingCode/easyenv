# Checklists por Stack (EasyEnv)

Use estas listas como passo-a-passo rápido para levantar cada stack com o EasyEnv e verificar se tudo ficou funcional.

Índice
	•	Antes de começar (geral)
	•	Flutter
	•	.NET
	•	Web (Node/Deno + Angular/React)
	•	Utilidades opcionais úteis
	•	Limpeza, backup e restauração

⸻

Antes de começar (geral)
	1.	Instalação do EasyEnv

# Instalar/atualizar easyenv
curl -fsSL https://raw.githubusercontent.com/DippingCode/easyenv/main/src/install.sh | bash
easyenv --version

	2.	Checar ambiente base

easyenv status --detailed

	3.	Escolher fluxo de instalação

	•	Zero (reset de blocos do zshrc):
easyenv init -mode zero
	•	Default (catálogo completo):
easyenv init -mode default -steps -y -reload
	•	Stack (apenas a stack escolhida):
easyenv init -mode stack -stack <flutter|dotnet|web> -steps -y -reload

⸻

# Instalação dirigida por stack

# Flutter

## Instalação recomendada

```bash
easyenv init -mode stack -stack flutter -steps -y -reload
```

O que essa stack cobre
	•	Flutter/Dart (preferencialmente via FVM)
	•	Android SDK (platform-tools, emulator, cmdline-tools) e AVD
	•	Java 17 (padrão p/ Android), Kotlin
	•	Integrações: Firebase CLI, Supabase CLI
	•	(iOS) Xcode (instalação manual via App Store; a ferramenta injeta as variáveis)

Verificações rápidas

## Flutter
easyenv versions flutter
flutter --version
flutter doctor -v

## Alternância de versões via FVM

easyenv switch flutter 3.13.9
easyenv versions flutter

## iOS
xcodebuild -version
swift --version

Passos específicos iOS
	•	Instalar Xcode via App Store.
	•	Aceitar licenças: sudo xcodebuild -license
	•	Abrir simulador: open -a Simulator


## Android
adb --version
sdkmanager --version
emulator -list-avds

Passos específicos Android

## Aceitar licenças e instalar plataformas básicas
yes | sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0" "emulator"

## Criar AVD (exemplo Pixel 7 API 34)
sdkmanager "system-images;android-34;google_apis;arm64-v8a"
avdmanager create avd -n Pixel_7_API_34 -k "system-images;android-34;google_apis;arm64-v8a"
emulator -avd Pixel_7_API_34 &

⸻

.NET

Instalação recomendada

easyenv init -mode stack -stack dotnet -steps -y -reload

O que essa stack cobre
	•	.NET SDKs (múltiplas versões podem coexistir)
	•	Suporte a global.json para fixar SDK por projeto/usuário
	•	Utilitários comuns de CLI

Verificações rápidas

dotnet --info
easyenv versions dotnet

Alternância de versões (.NET SDK)

# Fixar no projeto atual (gera ./global.json)
easyenv switch dotnet 8.0.303 --scope here

# Fixar global (gera ~/global.json, não recomendado para todos os casos)
easyenv switch dotnet 6.0.428 --scope global

Workloads (opcional)

# Ex.: MAUI, Android/iOS, WebAssembly
dotnet workload list
dotnet workload install maui


⸻

Web (Node/Deno + Angular/React)

Instalação recomendada

# O init da stack perguntará:
# - Node (NVM) e/ou Deno
# - Angular e/ou React (via create-vite)
easyenv init -mode stack -stack web -steps -y -reload

O que essa stack cobre
	•	Node via NVM (instala, troca e define default)
	•	Deno (instalação padrão do projeto)
	•	Angular CLI (npm global)
	•	React scaffold via create-vite (npm global)

Verificações rápidas

# Node
easyenv versions node
node -v
npm -v

# Deno
easyenv versions deno
deno --version

# Angular
ng version

# React (vite)
create-vite --version

Alternância de versões Node (NVM)

easyenv switch node lts
easyenv switch node 20.19.4


⸻

Utilidades opcionais úteis

# Ferramentas modernas de terminal
easyenv add bat
easyenv add eza
easyenv add fd
easyenv add ripgrep
easyenv add httpie
easyenv add jq
easyenv add zoxide
easyenv add direnv
easyenv add thefuck

Verifique status/versões:

easyenv status --detailed
easyenv doctor


⸻

Limpeza, backup e restauração

Limpar

# Limpeza leve (logs, caches seguros, blocos do zshrc)
easyenv clean -soft

# Desinstalar ferramentas (plano, confirmação por etapa com -steps)
easyenv clean -all -steps
easyenv clean -steps -section "CLI Tools"
easyenv clean git fzf

Backup e Restore

# Criar backup (zip dentro de easyenv/backups)
easyenv backup
easyenv backup -list

# Restaurar
easyenv backup -restore          # menu interativo (usa fzf se disponível)
easyenv backup -restore -latest
easyenv backup -restore <nome.zip>

# Gerenciar backups
easyenv backup -delete           # interativo
easyenv backup -purge 5          # mantém só os 5 mais recentes


⸻

Dica: caso algo no PATH/tema fique estranho após instalações, execute:

easyenv init -mode zero
exec zsh -l

Em seguida, rode default ou a stack desejada novamente.