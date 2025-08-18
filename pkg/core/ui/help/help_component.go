//Package help
package help

import (
	"fmt"
	"os"
	"strings"
	"text/tabwriter"

	"github.com/DippingCode/easyenv/pkg/core/ui/themes"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// HelpData é a estrutura de dados para popular o componente de ajuda.
type HelpData struct {
	Command      string
	ShortDescription string
	Flags        [][]string
}

// Model representa o modelo do componente Bubble Tea.
type Model struct {
	data HelpData
	theme themes.Theme
}

// NewModel cria um novo modelo de ajuda.
func NewModel(data HelpData, theme themes.Theme) Model {
	return Model{
		data: data,
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

	// Título do comando
	title := m.theme.TitleStyle.Render(fmt.Sprintf("Comando %s", m.data.Command))
	fmt.Fprintln(&b, title)
	fmt.Fprintln(&b, m.theme.BaseStyle.Render(m.data.ShortDescription))
	fmt.Fprintln(&b, "")

	// Tabela de flags
	flagsHeader := m.theme.HeaderStyle.Render("Flags")
	fmt.Fprintln(&b, flagsHeader)

	// Usa um tabwriter para alinhar as colunas da tabela
	tw := tabwriter.NewWriter(&b, 0, 0, 2, ' ', 0)
	
	// Corrigido: usando lipgloss.NewStyle().Foreground() para renderizar a linha.
	separatorStyle := lipgloss.NewStyle().Foreground(m.theme.BorderColor)
	fmt.Fprintln(tw, m.theme.BaseStyle.Render("Flag\tDescrição"))
	fmt.Fprintln(tw, separatorStyle.Render("---\t---"))

	for _, flag := range m.data.Flags {
		fmt.Fprintf(tw, "%s\t%s\n", m.theme.ListItemStyle.Render(flag[0]), m.theme.BaseStyle.Render(flag[1]))
	}

	tw.Flush()

	return b.String()
}

// RenderHelp é uma função utilitária para rodar o componente de ajuda.
func RenderHelp(data HelpData, theme themes.Theme) {
	p := tea.NewProgram(NewModel(data, theme))
	if _, err := p.Run(); err != nil {
		fmt.Printf("Ocorreu um erro: %v", err)
		os.Exit(1)
	}
}