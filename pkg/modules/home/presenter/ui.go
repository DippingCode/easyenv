package presenter

import (
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/viewbox"
	tea "github.com/charmbracelet/bubbletea"
)

// Ensure HomeView implements the ViewBox interface.
var _ viewbox.ViewBox = (*HomeView)(nil)

// HomeView is the ViewBox for the home screen.
type HomeView struct {
	model viewbox.Model
}

func New() *HomeView {
	return &HomeView{
		model: viewbox.New(),
	}
}

func (hv *HomeView) Init() tea.Cmd {
	return hv.model.Init()
}

func (hv *HomeView) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	return hv.model.Update(msg)
}

func (hv *HomeView) View() string {
	return "Home Screen ViewBox"
}
