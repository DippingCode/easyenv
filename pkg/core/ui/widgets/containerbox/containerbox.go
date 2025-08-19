package containerbox

import tea "github.com/charmbracelet/bubbletea"

// ContainerBox is the interface for a screen that can be loaded into the Scaffold.
type ContainerBox interface {
	tea.Model
}

// Model is a basic implementation of a ContainerBox.
type Model struct{}

func New() Model {
	return Model{}
}

func (m Model) Init() tea.Cmd {
	return nil
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	return m, nil
}

func (m Model) View() string {
	return "Default ContainerBox"
}
