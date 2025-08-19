// Package help provides a UI component for displaying help information.
package help

import (
	"fmt"
	"os"
	"strings"
	"text/tabwriter"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	themetemplate "github.com/DippingCode/easyenv/pkg/core/ui/themes/temetemplate"
)

// HelpData é a estrutura de dados para popular o componente de ajuda.
type HelpData struct {
	Command          string
	ShortDescription string
	Flags            [][]string
	Examples         [][]string // New field
}

// Model representa o modelo do componente Bubble Tea.
type Model struct {
	data  HelpData
	theme themetemplate.ThemeTemplate
}

// NewModel cria um novo modelo de ajuda.
func NewModel(data HelpData, theme themetemplate.ThemeTemplate) Model {
	return Model{
		data:  data,
		theme: theme,
	}
}

// Init é chamada no início do programa.
func (m Model) Init() tea.Cmd {
	return nil
}

// Update lida com as mensagens.
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	return m, nil
}

// View renderiza a visualização do componente de ajuda.
func (m Model) View() string {
	var b strings.Builder

	// Título do command
	title := m.theme.TitleStyle.Render(fmt.Sprintf("Command %s", m.data.Command))
	_, _ = fmt.Fprintln(&b, title)
	_, _ = fmt.Fprintln(&b, m.theme.BaseStyle.Render(m.data.ShortDescription))
	_, _ = fmt.Fprintln(&b, "")

	// Tabela de flags
	flagsHeader := m.theme.HeaderStyle.Render("Flags")
	_, _ = fmt.Fprintln(&b, flagsHeader)

	// Usa um tabwriter para alinhar as colunas da tabela
	tw := tabwriter.NewWriter(&b, 0, 0, 2, ' ', 0)

	// Corrigido: usando lipgloss.NewStyle().Foreground() para renderizar a linha.
	separatorStyle := lipgloss.NewStyle().Foreground(m.theme.BorderColor)
	_, _ = fmt.Fprintln(tw, m.theme.BaseStyle.Render("Flag\tDescrição"))
	_, _ = fmt.Fprintln(tw, separatorStyle.Render("---\t---"))

	for _, flag := range m.data.Flags {
		_, _ = fmt.Fprintf(tw, "%s\t%s\n", m.theme.ListItemStyle.Render(flag[0]), m.theme.BaseStyle.Render(flag[1]))
	}

	_ = tw.Flush()

	// Seções de exemplos
	if len(m.data.Examples) > 0 {
		_, _ = fmt.Fprintln(&b, "") // Add a newline for spacing
		examplesHeader := m.theme.HeaderStyle.Render("Exemplos de Uso")
		_, _ = fmt.Fprintln(&b, examplesHeader)

		examplesTw := tabwriter.NewWriter(&b, 0, 0, 2, ' ', 0)
		_, _ = fmt.Fprintln(examplesTw, separatorStyle.Render("---\t---")) // Separator for examples

		for _, example := range m.data.Examples {
			if len(example) == 2 {
				_, _ = fmt.Fprintf(examplesTw, "%s\t%s\n", m.theme.ListItemStyle.Render(example[0]), m.theme.BaseStyle.Render(example[1]))
			}
		}
		_ = examplesTw.Flush()
	}

	return b.String()
}

// RenderHelp é uma função utilitária para rodar o componente de ajuda.
func RenderHelp(data HelpData, theme themetemplate.ThemeTemplate) {
	p := tea.NewProgram(NewModel(data, theme))
	if _, err := p.Run(); err != nil {
		fmt.Printf("Ocorreu um erro: %v", err)
		os.Exit(1)
	}
}
