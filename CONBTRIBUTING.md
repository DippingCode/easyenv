# Diretrizes de Contribuição - EasyEnv.io

Este guia detalha as diretrizes de desenvolvimento para o CLI **EasyEnv.io** (comando `eye`), uma ferramenta para gerenciamento de ambientes e stacks de desenvolvimento. O projeto está sendo construído em **Go** com uma arquitetura modular inspirada em Domain-Driven Design (DDD).

**É uma obrigação ler este documento na íntegra antes de iniciar qualquer alteração no código.**

---

### **1. Visão Geral do Projeto**

O **EasyEnv.io** é um CLI (Command-Line Interface) e TUI (Text-based User Interface) que visa simplificar o gerenciamento de ambientes de desenvolvimento. Suas principais funcionalidades incluem:
* Instalação e desinstalação de stacks e ferramentas.
* Gerenciamento de versões de SDKs e linguagens.
* Backup e restauração de ambientes.
* Utilitários de terminal.
* Configuração e aplicação de temas para o terminal.

**Nome do Projeto:** EasyEnv.io
**Comando Principal:** `eye`
**Linguagem de Desenvolvimento:** Go (Golang)

---

### **2. Estrutura de Arquivos e Arquitetura (DDD "lite")**

A arquitetura do projeto é baseada em módulos independentes, onde cada módulo (`feature`) segue um padrão de camadas DDD para garantir a separação de responsabilidades.

```

.
├── cmd/eye             \# Ponto de entrada e configuração global do CLI.
├── docs                \# Documentação técnica e de design.
├── pkg
│   ├── core            \# Pacotes de baixo nível, abstrações e interfaces globais.
│   │   ├── config      \# Interface para gerenciamento de configurações (ex: `i_config.go`).
│   │   ├── installer   \# Interface para instaladores genéricos (ex: `i_installer.go`).
│   │   ├── ui          \# Lógica e componentes da TUI (Bubble Tea).
│   │   └── utils       \# Funções utilitárias (YAML parser, string helpers, etc.).
│   ├── modules         \# Módulos do CLI (features).
│   │   └── [módulo]    \# Cada pasta representa um comando/feature.
│   │       ├── data        \# Camada de comunicação com fontes de dados externas.
│   │       │   └── services  \# Implementações concretas de serviços de dados.
│   │       ├── domain      \# Lógica de negócio e o "coração" da feature.
│   │       │   ├── entities  \# Entidades (structs) que representam a lógica de negócio.
│   │       │   ├── enums     \# Enums específicos da feature.
│   │       │   ├── services  \# Interfaces de serviços que a camada de `usecases` utiliza.
│   │       │   └── usecases  \# A orquestração da lógica de negócio.
│   │       └── presenter   \# Camada de apresentação e interação com o usuário.
│   │           ├── command.go \# Definição do comando Cobra.
│   │           └── ui.go      \# Lógica de exibição da UI.
│   └── plugins         \# Implementações concretas de ferramentas externas.
│       └── [plugin]    \# Cada pasta é um plugin (ex: `homebrew`, `docker`).

```

**Regras de Comunicação entre Camadas:**
* **`presenter` -> `domain/usecases`**: O `presenter` chama um `usecase` para iniciar a lógica.
* **`usecases` -> `domain/services`**: A lógica do `usecase` chama os serviços abstratos do `domain`.
* **`domain/services` -> `data/services`**: A interface no `domain` é implementada na camada de `data`.
* **`data` -> `pkg/core`**: A camada de `data` pode utilizar pacotes do `core` para funções de baixo nível (ex: `yaml_reader`).
* **`domain` -> `entities`**: A entidade (`entity`) é a única forma de dados que transita entre todas as camadas do módulo.
* **Toda comunicação entre as camadas deve ser feita através de uma única entidade.**

---

### **3. Princípios de Design (SOLID)**

O código deve seguir rigorosamente os princípios SOLID:
* **S (SRP)**: Cada pacote e struct deve ter uma única responsabilidade.
* **O (OCP)**: Código aberto para extensão (novos módulos/plugins), mas fechado para modificação (não altere o core para adicionar uma feature).
* **L (LSP)**: Os plugins devem ser substituíveis uns pelos outros, desde que implementem a mesma interface.
* **I (ISP)**: Use interfaces pequenas e focadas.
* **D (DIP)**: Módulos de alto nível (modules) devem depender de abstrações (core), não de implementações concretas (plugins).

---

### **4. Padrões de Implementação**

* **Comandos do CLI:** Utilize **Cobra** para definir os comandos. A função `RunE` deve invocar a camada de `presenter`.
* **UI/TUI:** Utilize **Bubble Tea** para a UI interativa.
* **Logs e Saída:** Mantenha os logs de debug separados da saída normal.

---

### **5. Como Adicionar uma Nova Funcionalidade**

Para adicionar um novo comando (ex: `eye install`), siga estes passos:
1.  **Crie o Módulo:** Crie uma nova pasta em `pkg/modules/[nome_do_módulo]`.
2.  **Defina a Entidade:** Crie a entidade principal em `domain/entities`.
3.  **Implemente as Camadas:** Crie as pastas `data`, `domain` e `presenter`, e implemente os arquivos seguindo a estrutura de DDD.
4.  **Registre o Módulo:** No `cmd/eye/main.go`, importe o novo módulo e chame sua função de registro.

---

### **6. Considerações Adicionais**

  * **Testes:** Cada pacote (módulo, core, plugin) deve ter testes unitários e de integração.
  * **Documentação:** Mantenha a documentação do código (comentários Go) e os arquivos READMEs atualizados.
  * **Compatibilidade:** A ferramenta deve ser funcional em **macOS, Linux e Windows**. A lógica de execução de scripts nos plugins (`.yml`) deve considerar as diferenças entre os sistemas operacionais.

-----

### **7. Manutenção do `CHANGELOG.md`**

O arquivo `CHANGELOG.md` documenta todas as alterações notáveis no projeto para cada nova versão ou build. É crucial manter este arquivo atualizado para que a comunidade e a equipe possam rastrear o progresso e as alterações.

**Diretrizes:**

  * **Adição de Entradas:** Ao finalizar uma tarefa ou um conjunto de alterações, adicione uma nova entrada no topo da lista, logo abaixo da seção `## Versions`.
  * **Padrão de Entrada:** A nova entrada deve seguir exatamente o padrão abaixo. **Não altere os cabeçalhos (`Added`, `Changed`, `Notes`, etc.)**.

<!-- end list -->

#### [0.0.x] - AAAA-MM-DD

###### Added
- [Descrição do que foi adicionado ou de uma nova funcionalidade.]

###### Changed
- [Descrição de uma alteração em funcionalidades existentes.]

###### Notes
- [Informações adicionais, como ressalvas, avisos de compatibilidade ou detalhes técnicos não visíveis ao usuário.]

###### Next Steps
- [Lista de tarefas relacionadas a esta feature que serão abordadas em seguida.]

###### Build Details
- Build: [Número do build]
- Tag: [Tag do Git, ex: v0.0.1+26]
- Commit: Mensagem de commit
```

  * **Campos da Entrada:**
      * **`#### [Versão]`**: Use o número da versão para identificar a entrada.
      * **`Added`**: Para novas funcionalidades, features, ou arquivos adicionados.
      * **`Changed`**: Para alterações em funcionalidades já existentes.
      * **`Notes`**: Para informações importantes que não são nem "adicionadas" nem "alteradas".
      * **`Next Steps`**: Para indicar o que virá a seguir, mantendo a equipe alinhada.
      * **`Build Details`**: Informações de compilação e o link para o commit principal.

**Exemplo de Entrada:**

```markdown
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
- Commit: feat(version): adiciona service, repository, viewmodel e view com suporte a flags -v/--version

---
```

**Lembre-se:** A manutenção do `CHANGELOG.md` é uma responsabilidade compartilhada por todos os contribuidores e garante a transparência e a organização do histórico do projeto.

-----

**Comandos úteis para o Gemini CLI:**

  * **` gemini code "Crie a lógica para o comando  `eye version`  em Go, seguindo a arquitetura do projeto EasyEnv.io" `**
  * **` gemini code "Implemente a interface  `Installer`para o plugin Docker, usando um arquivo`configs.yml`"`**
  * **`gemini code "Escreva um componente Bubble Tea para um dashboard com o status de todas as ferramentas instaladas"`**
  * **` gemini refactor "Refatore o pacote  `pkg/core/utils/yaml\_reader.go`  para ser mais seguro contra injeção de comandos" `**