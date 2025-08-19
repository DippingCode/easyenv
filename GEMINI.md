# Prompt Inicial

Gemini, fale comigo em português. Para começarmos, analise o projeto e traga um resumo do que você entendeu, depois crie um GEMINI.md, que você deverá adicionaro o prompt que eu enviar e o resumo do que foi feito.

# Resumo do Projeto (Análise Inicial)

O projeto **EasyEnv.io** é uma ferramenta de linha de comando (CLI) desenvolvida em Go, projetada para automatizar e simplificar a configuração de ambientes de desenvolvimento. O executável principal é chamado `eye`.

**Principais pontos:**

*   **Objetivo:** Permitir que desenvolvedores configurem, gerenciem, façam backup e restaurem seus ambientes de trabalho de forma rápida e consistente através de arquivos de configuração YAML.
*   **Tecnologia:** Escrito em Go. Utiliza uma abordagem "YAML-driven" para definir as configurações, como evidenciado pela dependência `gopkg.in/yaml.v3` no `go.mod`.
*   **Funcionalidades:** O `README.md` descreve funcionalidades como inicialização de ambiente (`eye init`), instalação de stacks de desenvolvimento (ex: React Native), verificação de status e instalação de ferramentas individuais.
*   **Arquitetura:** O projeto segue uma arquitetura modular, o que facilita a manutenção e a extensão com novos plugins e funcionalidades.

**Regra de Incremento de Build:** Apenas o número do build deve ser incrementado em todas as entradas do CHANGELOG.md, a menos que explicitamente instruído de outra forma.

# Resumo da Arquitetura da TUI (Interface de Usuário de Terminal)

Após uma série de discussões técnicas, a seguinte arquitetura foi definida para a construção da interface interativa do `eye`.

## 1. Paradigma Principal: TUI Interativa
A aplicação `eye` funcionará como uma TUI (Terminal User Interface) interativa e rica, em vez de um CLI simples com comandos discretos. O objetivo é fornecer uma experiência de usuário mais guiada e visualmente agradável, semelhante a um aplicativo de desktop.

## 2. Padrão de Gerenciamento de Estado: The Elm Architecture (TEA)
O padrão de gerenciamento de estado adotado é a **Arquitetura Elm (TEA)**, que é o padrão fundamental da biblioteca `bubbletea`.
*   **Fluxo de Dados Unidirecional:** O estado da aplicação segue um ciclo previsível: `Model -> View -> Update -> Model`.
*   **Escalabilidade:** Para gerenciar a complexidade, usaremos uma abordagem de **composição de componentes com modelos aninhados**. Cada componente de UI (`Scaffold`, `AppBar`, `Button`, etc.) é uma mini-aplicação TEA autônoma, com seu próprio estado (`Model`), lógica (`Update`) e apresentação (`View`).

## 3. Arquitetura da UI: Componentes Componíveis
A UI será construída com base em uma hierarquia de componentes reutilizáveis e componíveis.
*   **Hierarquia Principal:** `Shell` -> `Scaffold` -> `Slots`
    *   **`Shell`**: O componente raiz da aplicação, o processo `tea.Program` principal. Sua principal função é hospedar o `Scaffold`.
    *   **`Scaffold`**: O principal componente de layout da tela. Ele ocupa toda a área disponível e possui "slots" para outros componentes. Sua margem externa funciona como uma área de segurança visual.
    *   **`Slots`**: O `Scaffold` possui slots nomeados para componentes como `AppBar`, `Drawer`, `NavBar`, `BottomBar` e `ViewBox`. Com exceção do `ViewBox`, todos são opcionais.
*   **`ViewBox`**: Este é o slot de conteúdo principal e obrigatório. Ele **é** a tela ativa carregada pelo roteador. Toda tela de módulo (ex: `home`, `version`) é uma implementação de um `ViewBox`.
*   **Filosofia de Caixa (Box Model)**: Todos os componentes são construídos como caixas, utilizando a biblioteca `lipgloss` para gerenciar propriedades como `padding`, `margin`, `border`, `width` e `height`, semelhante ao modelo do Flutter ou CSS.

## 4. Tela Inicial: Dashboard Dinâmico
A tela inicial da aplicação (`home`) será um dashboard dinâmico e sensível ao contexto.
*   **Novo Projeto:** Para um diretório sem um projeto `eye` configurado, a tela mostrará uma mensagem de boas-vindas e um menu de primeiros passos (ex: `init`, `doctor`).
*   **Projeto Existente:** Para um diretório com um projeto `eye`, a tela mostrará um dashboard com o status do ambiente (dependências, pacotes) e ações rápidas relevantes.

---

# Discussões Técnicas

Esta seção contém a transcrição da conversa que levou à definição da arquitetura acima.

**P: O app terá um "palco" unico e as coisas serão desenhadas nele, ou será baseado em rotas e navegação entre telas?**

**R:** Ambos. Teremos um **palco único** (`Shell`) gerenciado por um **sistema de rotas e navegação**. O `Shell` atua como um contêiner principal, e o roteador troca a tela ativa (o `ViewBox`) que é exibida dentro do layout do `Shell`.

**P: É possivel criar uma estrutura em que alguns componentes sempre estejam visiveis, por exemplo um campo input, e apenas o conteúdo do meio vai mudando?**

**R:** Sim, através de um componente de **gerenciamento de layout**. Propusemos o `Scaffold`, que desenha um "esqueleto" persistente (com `Header`, `Footer`, `Input`, etc.) e tem uma área de conteúdo principal que muda dinamicamente.

**P: O shell não deve ser confundido com o esqueleto da tela, ele deve ser o "palco" ou canvas. Dentro dele posso incluir templates de telas, como scaffold. O próximo objeto dentro dele pode ser um objeto de layout de tela, que tal?**

**R:** Perfeito. A hierarquia foi refinada para: `Shell` (o canvas/raiz) -> `Scaffold` (o template de layout principal). O `Shell` hospeda o `Scaffold`.

**P: A estrutura deve ser a seguinte: Shell -> Scaffold (Layout) -> [AppBar, Drawer, NavBar, BottomBar, Content]. O scaffold tem slots para encaixar esses componentes, que também serão templates reutilizáveis. O que vc acha disso?**

**R:** É uma ideia fantástica, que aplica padrões de UI modernos (como Flutter/React) a uma TUI. O `Scaffold` se torna um componente de layout de alto nível com slots nomeados. Isso exige um gerenciamento de **foco** para saber qual componente está ativo.

**P: Os componentes do scaffold são todos opcionais com excessão do content, que sempre deve ter 1 filho. Você falou sobre gerenciar o foco, seria a mesma coisa que gerenciamento de estado?**

**R:** Não, eles não são a mesma coisa, mas estão relacionados. O **gerenciamento de foco é uma parte especializada do gerenciamento de estado**.
*   **Gerenciamento de Estado (O "O Quê?"):** Refere-se a todos os dados que descrevem a aplicação.
*   **Gerenciamento de Foco (O "Onde?"):** É a parte do estado que define para qual componente a entrada do usuário é direcionada.

**P: O ViewBox é o componente de tela propriamente dita. Vamos mudar o nome de content para viewBox. O viewBox é como se fosse um webview para a tela que está carregada. Faz sentido? Outro detalhe é que os componentes devem ser construido com a filosofia de caixa (padding, margin...).**

**R:** Sim, faz todo o sentido. A analogia com `WebView` é perfeita. A nomenclatura `ViewBox` é mais clara. A filosofia de caixa (Box Model) implementada com `lipgloss` é a base para o nosso `design_system`. O `Scaffold` ocupará a tela inteira e sua margem funcionará como uma área de segurança.

**P: Agora, refinando mais a ideia de gerenciamento de estado, estamos utilizando algum padrão? Qual padrão vc sugere?**

**R:** Sim, ao usar `bubbletea`, já estamos usando a **Arquitetura Elm (TEA)**. Sugiro abraçar formalmente este padrão e escalá-lo com uma **abordagem de componentes aninhados**. Cada componente de UI é uma mini-aplicação TEA autônoma, e os componentes pais gerenciam e delegam lógica para seus filhos.

**P: O app abrirá com uma home, uma tela de boas vindas, um dashboard ou outra coisa? Qual é a sua sugestão?**

**R:** Sugiro uma **tela "Home" que funciona como um dashboard dinâmico**. O conteúdo se adapta ao contexto: se é um novo projeto, mostra os primeiros passos; se é um projeto existente, mostra um dashboard com o status do ambiente e ações rápidas. Isso torna a ferramenta imediatamente útil e inteligente.
