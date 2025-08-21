//Package shell
package shell

import (
	"github.com/DippingCode/easyenv/pkg/core/adapters/tui"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/viewbox"
	"github.com/DippingCode/easyenv/pkg/modules/home/presenter"
)

// Ensure Shell implements the tui.Model interface.
var _ tui.Model = (*Shell)(nil)

// Shell is the root model of the application.
// It holds the active screen (ViewBox) and handles global commands.
type Shell struct {
	activeViewBox  viewbox.ViewBox
	escPressedOnce bool
}

// New creates a new shell, initializing the home screen as the active view.
func New() *Shell {
	return &Shell{
		activeViewBox:  presenter.New(),
		escPressedOnce: false,
	}
}

func (s *Shell) Init() tui.Cmd {
	// This will cause a compile error until viewbox.ViewBox is updated.
	return s.activeViewBox.Init()
}

func (s *Shell) Update(msg tui.Msg) (tui.Model, tui.Cmd) {
	switch msg := msg.(type) {
	case tui.KeyMsg:
		switch msg.Type {
		case tui.KeyCtrlC:
			return s, tui.Quit

		case tui.KeyEsc:
			if s.escPressedOnce {
				return s, tui.Quit
			}
			s.escPressedOnce = true
			// We don't return a command here, just wait for the next message.
			return s, nil
		}
	}

	s.escPressedOnce = false

	// Delegate the message to the active screen.
	// This will also cause a compile error until viewbox.ViewBox is updated.
	newViewBox, cmd := s.activeViewBox.Update(msg)
	s.activeViewBox = newViewBox.(viewbox.ViewBox)
	return s, cmd
}

func (s *Shell) View() string {
	// The shell's view is simply the view of the active screen.
	return s.activeViewBox.View()
}