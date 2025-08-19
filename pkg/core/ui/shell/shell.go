package shell

import (
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/viewbox"
	"github.com/DippingCode/easyenv/pkg/modules/home/presenter"
	tea "github.com/charmbracelet/bubbletea"
)

// Shell is the root model of the application.
// It holds the active screen (ViewBox) and handles global commands.
type Shell struct {
	activeViewBox  viewbox.ViewBox
	escPressedOnce bool
}

// New creates a new shell, initializing the home screen as the active view.
func New() Shell {
	return Shell{
		activeViewBox:  presenter.New(),
		escPressedOnce: false,
	}
}

func (s Shell) Init() tea.Cmd {
	return s.activeViewBox.Init()
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
			return s, nil
		}
	}

	s.escPressedOnce = false

	// Delegate the message to the active screen.
	var cmd tea.Cmd
	newViewBox, cmd := s.activeViewBox.Update(msg)
	s.activeViewBox = newViewBox.(viewbox.ViewBox)
	return s, cmd
}

func (s Shell) View() string {
	// The shell's view is simply the view of the active screen.
	return s.activeViewBox.View()
}
