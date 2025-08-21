package presenter

import (
	"github.com/DippingCode/easyenv/pkg/core/adapters/tui"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/appbar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/bottombar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/containerbox"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/sidemenu"
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
	// NOTE: The components below (sidemenu, bottombar, etc.) will also need to be
	// refactored to use the tui.Model interface. This is a temporary state.
	sidemenu := sidemenu.New(
		sidemenu.WithBackgroundColor("#0000FF"), // Azul
		sidemenu.WithBorder(tui.NormalBorder, true, true, true, true), // Borda normal em todos os lados
		sidemenu.WithBorderForeground("#FF0000"), // Vermelho
		sidemenu.WithAlign(tui.Top),
	)
	bottomBar := bottombar.New(
		bottombar.WithBackgroundColor("#FF0000"), // Vermelho
		bottombar.WithBorder(tui.NormalBorder, true, true, true, true), // Borda normal em todos os lados
		bottombar.WithBorderForeground("#0000FF"), // Azul
		bottombar.WithAlign(tui.Top),
	)
	containerBox := containerbox.New(
		containerbox.WithBackgroundColor("#00FF00"), // Verde
		containerbox.WithBorder(tui.NormalBorder, true, true, true, true), // Borda normal em todos os lados
		containerbox.WithBorderForeground("#0000FF"), // Azul
		containerbox.WithAlign(tui.Top),
		
	)
	appBar := appbar.New(
		appbar.WithBackgroundColor("#FF0000"), // Vermelho
		appbar.WithBorder(tui.NormalBorder, true, true, true, true), // Borda normal em todos os lados
		appbar.WithBorderForeground("#0000FF"), // Azul
		appbar.WithAlign(tui.Top),
	)

	scaffold := scaffold.New(
		scaffold.WithAppBar(appBar),
		scaffold.Withsidemenu(sidemenu),
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