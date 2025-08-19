
# Documento de Definições — Lib TUI em Go para o projeto

## 1. Visão Geral

Esta biblioteca tem como objetivo fornecer uma **camada declarativa para construção de interfaces ricas em terminal (TUI)** utilizando Go.  
O escopo é **apenas telas e widgets**, abstraindo a complexidade do terminal (ANSI, ncurses, etc.), mas **sem incluir navegação, gerenciamento de estado ou modularidade de alto nível**.

Ela deve ser minimalista, mas expressiva o suficiente para permitir que qualquer CLI possa desenhar componentes visuais bem estruturados, como painéis, listas, inputs e botões.

---

## 2. Stack e Tecnologias

- **Linguagem:** Go (>= 1.22)
    
- **Renderização:** ANSI + escape sequences, sobre abstração (possível backend em [tcell](https://github.com/gdamore/tcell) ou similar)
    
- **Layout:** Sistema baseado em **Box** (row, column, grid)
    
- **Configuração:** YAML opcional para declarar a UI, mas API em Go também disponível
    

---

## 3. Diretrizes da Biblioteca

- **Declarativo**: telas são descritas como árvores de widgets.
    
- **Widgets são caixas**: todo widget é um `Box`, com atributos básicos (`h, w, border, bg, padding`).
    
- **Layout flexível**: cada `Box` pode ser row, column ou grid.
    
- **Hierarquia clara**: filhos dentro de pais; sem rotas ou navegação, apenas containers.
    
- **Independente de estado**: a responsabilidade de atualizar/redesenhar é do app que usa a lib.
    
- **Reatividade opcional**: redraw acontece apenas quando solicitado.
    

---

## 4. Famílias de Componentes

### **Layout**

- `BoardBox`: raiz da tela (define altura/largura total, geralmente terminal full screen).
    
- `Box`: container genérico, com `layout: row|column|grid`.
    

### **Texto**

- `TextBox`: container para `Text`.
    
- `Text`: unidade de texto, com estilo (`bold, italic, underline`) e tipo (`label, body, title`).
    

### **Inputs**

- `Input`: campo de texto editável.
    
- `Checkbox`: selecionável.
    
- `RadioGroup`: opções exclusivas.
    

### **Botões**

- `Button`: executa callback ao pressionar.
    
- `ToggleButton`: on/off.
    

### **Listas**

- `List`: coleção rolável de itens.
    
- `ListItem`: item básico de lista.
    

### **Estruturais**

- `CardBox`: container com borda e título opcional.
    
- `Divider`: linha horizontal/vertical.
    
- `Spacer`: espaço em branco ajustável.
    

### **Decoração**

- `PolygonBox`: ASCII shapes (retângulo, triângulo, círculo).
    
- `ImageBox`: ASCII-art ou imagens convertidas para terminal.
    

---

## 5. Estrutura Hierárquica

```
BoardBox
 └── Box (layout=row)
      ├── TextBox
      │    └── Text ("Título")
      ├── CardBox
      │    ├── Input
      │    └── Button
      └── List
           ├── ListItem
           ├── ListItem
           └── ListItem
```

---

## 6. API Básica (Go)

### Exemplo em Go:

```go
board := tui.NewBoardBox()

header := tui.NewTextBox().AddText("Meu CLI", tui.Title)
input := tui.NewInput("Digite seu nome...")
btn := tui.NewButton("Enviar", func() {
    fmt.Println("Enviado!")
})

card := tui.NewCardBox().
    AddChild(input).
    AddChild(btn)

layout := tui.NewBox(tui.Row).
    AddChild(header).
    AddChild(card)

board.SetChild(layout)
board.Render()
```

### Exemplo em YAML:

```yaml
board:
  box:
    layout: row
    children:
      - textbox:
          texts:
            - value: "Meu CLI"
              type: title
      - cardbox:
          children:
            - input:
                placeholder: "Digite seu nome..."
            - button:
                text: "Enviar"
                action: onSubmit
```

---

## 7. Estilo e Propriedades Comuns

Todo widget compartilha algumas propriedades:

- `width`, `height`
    
- `padding`, `margin`
    
- `border` (simple, double, none)
    
- `background` (ANSI colors ou themes)
    
- `align` (start, center, end)
    

---

## 8. Ciclo de Vida e Redraw

- O **app** é responsável por chamar `board.Render()` quando necessário.
    
- Widgets apenas desenham a si mesmos, sem lógica de diffs ou dirty rect.
    
- O objetivo é simplicidade: cada redraw redesenha a árvore inteira.
    

---

## 9. Regras de tema e estilo

- local de origem dos temas: easyenv/assets/themes/

- Na pasta themes, os temas podem ser acessados via /nome do tema/

- dentro da pasta do tema, tem o arquivo <NOME DO TEMA>.dark.yml e <NOME DO TEMA>.light.yml

- o tema deve ser carregado na inicialização do aplicativo e salvo em contexto da aplicação

- todos os componentes visuais devem respeitar o tema carregado

- caso o usuário não tenha selecionado e tema e não esteja nas preferencias de usuário o tema a ser carregado sempre será o template.yml que fica localizado em easyenv/assets/themes/template.yml

- o local do design system será easyenv/pkg/core/ui/designsystem/

- o design system deve ter compatibilidade total com o template.yml e todas as especificações contidas no template.yml devem ser respeitadas e aplicadas aos componentes de forma criteriosa.

- esse documento deve ser respeitado de forma criteriosa

---

## 10. Backlog de Desenvolvimento

-  Motor de carregamento de tema

-  Validador de tema, para identificar quando um tema inserido faltar token ou ter tokens incorretos

-  Motor de renderização baseado em tcell (ANSI)
    
-  BoardBox + Box (row/column)
    
-  TextBox + Text
    
-  Button básico com callback
    
-  CardBox
    
-  Input + foco/edição de texto
    
-  List + scroll
    
-  Divider, Spacer
    
-  Temas e cores customizáveis
    
-  Checkbox, RadioGroup, ToggleButton
    
-  PolygonBox + ASCII shapes
    
-  ImageBox (ASCII-art)
    
-  Grid layout
    
-  YAML parser completo com actions
    

---

📌 Esse documento define a **lib TUI pura**, enxuta, modular, sem gestão de estado ou navegação.  
Serve como base para enriquecer suas interfaces.

---
