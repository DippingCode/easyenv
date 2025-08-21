package presenter

import (
	"github.com/DippingCode/easyenv/pkg/core/adapters/tui"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/appbar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/bottombar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/containerbox"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/navbar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/scaffold"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/viewbox"
)

// Ensure HomeView implements the ViewBox interface (which is tui.Model).
var _ viewbox.ViewBox = (*HomeView)(nil)

// HomeView is the ViewBox for the home screen.
type HomeView struct {
	scaffold *scaffold.Model // Changed to pointer
}

// New creates a new HomeView instance.
func New() *HomeView {
	// NOTE: The components below (navbar, bottombar, etc.) will also need to be
	// refactored to use the tui.Model interface. This is a temporary state.
	navBar := navbar.New(
		navbar.WithBackgroundColor("#0000FF"), // Azul
		navbar.WithBorder(tui.NormalBorder, true, true, true, true), // Borda normal em todos os lados
		navbar.WithBorderForeground("#FF0000"), // Vermelho
		navbar.WithAlign(tui.Top),
	)
	bottomBar := bottombar.New(
		bottombar.WithBackgroundColor("#FF0000"), // Vermelho
		bottombar.WithBorder(tui.NormalBorder, true, true, true, true), // Borda normal em todos os lados
		bottombar.WithBorderForeground("#0000FF"), // Azul
		bottombar.WithAlign(tui.Top),
	)
	containerBox := containerbox.New()
	appBar := appbar.New()

	scaffold := scaffold.New(
		scaffold.WithAppBar(appBar),
		scaffold.WithNavBar(navBar),
		scaffold.WithBottomBar(bottomBar),
		scaffold.WithContainerBox(containerBox),
		scaffold.WithBackgroundColor("#0F0F0F"),
	)

	return &HomeView{
		scaffold: scaffold,
	}
}

// Init initializes the HomeView.
func (hv *HomeView) Init() tui.Cmd {
	return hv.scaffold.Init()
}

// Update handles messages for the HomeView.
func (hv *HomeView) Update(msg tui.Msg) (tui.Model, tui.Cmd) {
	newScaffold, cmd := hv.scaffold.Update(msg)
	hv.scaffold = newScaffold.(*scaffold.Model) // Changed type assertion
	return hv, cmd
}

// View renders the HomeView.
func (hv *HomeView) View() string {
	return hv.scaffold.View()
}