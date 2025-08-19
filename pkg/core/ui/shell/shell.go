package shell

import (
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/scaffold"
	tea "github.com/charmbracelet/bubbletea"
)

// Shell is the root model of the application.
type Shell struct {
	scaffold       scaffold.Model
	escPressedOnce bool
}

// New creates a new shell.
func New() Shell {
	return Shell{
		scaffold:       scaffold.New(),
		escPressedOnce: false,
	}
}

func (s Shell) Init() tea.Cmd {
	return s.scaffold.Init()
}

func (s Shell) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.Type {
		case tea.KeyCtrlC:
			return s, tea.Quit

		case tea.KeyEsc:
			if s.escPressedOnce {
				return s, tea.Quit
			}
			s.escPressedOnce = true
			// We don't pass the Esc message down, but we don't quit yet.
			return s, nil
		}
	}

	// If we received any other message, reset the esc counter.
	s.escPressedOnce = false

	// Delegate the message to the scaffold.
	var cmd tea.Cmd
	newScaffold, cmd := s.scaffold.Update(msg)
	s.scaffold = newScaffold
	return s, cmd
}

func (s Shell) View() string {
	return s.scaffold.View()
}