Pilares arquiteturais
	1.	Arquitetura por feature (DDD-lite)

	•	Cada feature possui exatamente estas camadas:
	•	entities/ → modelos de domínio puros (sem dependências externas).
	•	data/services/ → acesso a dados/bordas (arquivos, rede, env, shell, adapters).
	•	domain/repositories/ → contratos e orquestração de acesso a dados por entidade.
	•	presenter/viewmodel/ → fluxo de UI, sem I/O direto (retorna strings/estruturas).
	•	presenter/view/ → I/O de terminal (imprime, lê flags), usa a viewmodel.
	•	router.go (da feature) → compõe service → repo → viewmodel → view e expõe Route(args []string).
	•	O router global (features/router.go) apenas delega para feature.Route(args).

	2.	SOLID aplicado

	•	SRP: cada arquivo tem uma responsabilidade clara (ex.: service só lê fonte de dados).
	•	OCP: evite editar tipos estáveis para novos comportamentos; prefira novas implementações/instâncias.
	•	LSP: interfaces pequenas e coesas; substituições não quebram expectativas.
	•	ISP: divida interfaces em contratos mínimos (ex.: VersionService com apenas o que a feature precisa).
	•	DIP: viewmodel depende de repositories.* (contratos), e repositórios dependem de services.* (contratos/impl).

	3.	Separação de I/O

	•	view é o único lugar de fmt.Fprint*, flag, leitura de stdin.
	•	viewmodel transforma dados em mensagens prontas (string/structs), sem tocar em I/O.
	•	repository chama services.* para obter dados; não faz parsing além do necessário.
	•	services acessa sistema/arquivos/env/rede; isola YAML/JSON e detalhes de path.

	4.	Dependências

	•	presenter/* → pode depender de domain/* e tipos internos da própria feature.
	•	domain/* → pode depender de contratos (data/... somente via interface se necessário), mas não deve importar presenter.
	•	data/* → pode depender de libs externas (yaml, os, fs), nunca de presenter.
	•	Nunca cruze presenter com data diretamente.

Convenções de código
	1.	Comentários de package

	•	Obrigatório: 1ª linha de cada arquivo Go deve ter um comentário explicando o package:
	•	// Package view ...
	•	// Package viewmodel ...
	•	// Package repositories ...
	•	// Package services ...
	•	// Package entities ...

	2.	Naming

	•	Entidade: version → arquivo version_entity.go ou apenas version.go dentro de entities/.
	•	Service/Repo/View/ViewModel/Router: version_service.go, version_repository.go, version_view.go, version_viewmodel.go, router.go.
	•	Funções públicas autoexplicativas; privadas curtas e coesas.

	3.	Erros

	•	Use errors.New e fmt.Errorf("contexto: %w", err) para wrap.
	•	Nunca logue em service/repo; apenas retorne erro. view decide como exibir.
	•	Mensagens ao usuário: simples e úteis. Mensagens internas (wrap) com contexto.

	4.	Formatação & lint

	•	go fmt, go vet e linter (golangci-lint) locais.
	•	Comentários de package eliminam ST1000.
	•	Sem prints “de debug” no código; se necessário, temporário e removido antes do commit.

	5.	Config & paths

	•	core/config pode centralizar helpers de path/env se for cross-feature.
	•	Resolução de arquivos (ex.: dev_log.yml) deve:
	1.	Checar variável específica (EASYENV_DEV_LOG).
	2.	Checar EASYENV_HOME.
	3.	Buscar ascendente.
	4.	Usar ./dev_log.yml como fallback.
	•	Nunca hardcode caminhos fora dessas regras.

	6.	I/O & UX do CLI

	•	Flags com flag.FlagSet dentro da view.
	•	--help sempre disponível.
	•	--json quando fizer sentido (mais adiante).
	•	Mensagens padronizadas e concisas.

	7.	Módulo & imports

	•	module github.com/DippingCode/easyenv (sem /src).
	•	Imports relativos ao módulo, sem “atalhos mágicos”.

	8.	Commits e dev_log

	•	Cada incremento funcional → uma entrada no dev_log.yml (no topo), com version e build incrementais.
	•	Commits semânticos: feat(version): ..., fix(router): ....

Fluxo padrão de uma nova feature
	1.	Criar entities (estrutura de domínio).
	2.	Criar services (acesso a dados — yaml, env, rede…).
	3.	Criar repositories (contrato e impl usando o service).
	4.	Criar viewmodel (formata mensagens e fluxos).
	5.	Criar view (flags, prints, interação).
	6.	Criar router da feature (Route(args []string)).
	7.	Registrar no router global.
	8.	go mod tidy, rodar local, validar saída.
	9.	Escrever entrada no dev_log.yml.

Padrões de teste (quando adicionarmos testes)
	•	Testes de entities e viewmodel são unitários (fáceis).
	•	repositories podem usar mocks dos services.
	•	services podem ter testes de integração (com arquivos exemplo dentro de testdata/).

Performance & extensibilidade
	•	Interfaces pequenas permitem simular fontes de dados (ex.: mudar dev_log para uma API).
	•	Nenhum global state nas features; dependências entram por construtores.

Roadmap imediato (apenas para alinhar)
	1.	Version (feito): entities, service, repo, viewmodel, view, router.
	2.	Help: foco em UX mínima e roteamento.
	3.	Tools (list): começar simples (somente leitura do config/tools.yml), sem “descobrir versões”; depois incrementamos com serviço que detecta versão instalada e latest.
	4.	Evoluir com renderizações ricas (tabelas e badges) mantendo a separação de camadas (viewmodel formata dados → view renderiza).
