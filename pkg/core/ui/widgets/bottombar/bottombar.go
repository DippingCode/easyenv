package bottombar

import "github.com/DippingCode/easyenv/pkg/core/adapters/tui"

// Ensure Model implements the tui.Model interface.
var _ tui.Model = (*Model)(nil)

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
	return "BottomBar"
}