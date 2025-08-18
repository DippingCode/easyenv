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