// Package table fornece um componente reutilizável para renderizar tabelas no terminal.
package table

import (
	"fmt"
	"os"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/evertras/bubble-table/table"

	//"github.com/charmbracelet/lipgloss"
	themetemplate "github.com/DippingCode/easyenv/pkg/core/ui/themes/temetemplate"
)

// ColumnData define a estrutura para a coluna da tabela.
type ColumnData struct {
	Key   string
	Title string
	Width int
}

// Model representa o modelo do componente Bubble Tea para a tabela.
type Model struct {
	table table.Model
	theme themetemplate.ThemeTemplate
}

// NewModel cria uma nova instância do componente de tabela.
func NewModel(columns []ColumnData, rows []table.Row, theme themetemplate.ThemeTemplate) Model {
	// Converte os dados de coluna para o formato da biblioteca bubble-table.
	cols := []table.Column{}
	for _, c := range columns {
		cols = append(cols, table.NewColumn(c.Key, c.Title, c.Width))
	}

	// Cria o modelo da tabela e aplica os estilos do tema.
	t := table.New(cols).
		WithRows(rows).
		WithBaseStyle(theme.BaseStyle).
		// WithAllRowsDeselected().BorderDefault().Focused(false).
		BorderDefault().Focused(false).
		// WithFocused(false).
		// WithBorderStyle(theme.Border).
		// WithBorder(theme.Border).
		WithFooterVisibility(false).
		WithPageSize(len(rows))

	return Model{
		table: t,
		theme: theme,
	}
}

// Init é a função de inicialização do modelo.
func (m Model) Init() tea.Cmd {
	return nil
}

// Update lida com as mensagens.
func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	// A tabela não é interativa, então não precisamos de uma lógica complexa de atualização.
	var cmd tea.Cmd
	m.table, cmd = m.table.Update(msg)
	return m, cmd
}

// View renderiza a tabela.
func (m Model) View() string {
	return m.table.View()
}

// RenderTable é uma função utilitária para exibir a tabela.
func RenderTable(columns []ColumnData, rows []table.Row, theme themetemplate.ThemeTemplate) {
	p := tea.NewProgram(NewModel(columns, rows, theme))
	if _, err := p.Run(); err != nil {
		fmt.Printf("Ocorreu um erro ao exibir a tabela: %v", err)
		os.Exit(1)
	}
}
