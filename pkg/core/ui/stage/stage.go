//Package stage
package stage


import (
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Um Stage minimalista: tela em branco com BG do terminal.
// Teclas: q/ctrl+c para sair. Resize ajusta o "palco".

type Model struct {
	width, height int
}

func New() tea.Model { return Model{} }

func (m Model) Init() tea.Cmd { return nil }

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c", "esc":
			return m, tea.Quit
		}
	}
	return m, nil
}

func (m Model) View() string {
	if m.width <= 0 || m.height <= 0 {
		return ""
	}
	blank := strings.Repeat(" ", max(0, m.width))
	line := lipgloss.NewStyle().Render(blank)
	var b strings.Builder
	for i := 0; i < m.height; i++ {
		if i > 0 {
			b.WriteByte('\n')
		}
		b.WriteString(line)
	}
	return b.String()
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}
