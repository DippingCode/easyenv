package containerbox

import "github.com/DippingCode/easyenv/pkg/core/adapters/tui"

// ContainerBox is the interface for a screen that can be loaded into the Scaffold.
// It is an alias for tui.Model.
type ContainerBox interface {
	tui.Model
}

// Model is a basic implementation of a ContainerBox.
// Ensure it implements the interface.
var _ ContainerBox = (*Model)(nil)

type Model struct{}

func New() Model {
	return Model{}
}

func (m Model) Init() tui.Cmd {
	return nil
}

func (m Model) Update(msg tui.Msg) (tui.Model, tui.Cmd) {
	return m, nil
}

func (m Model) View() string {
	return "Default ContainerBox"
}