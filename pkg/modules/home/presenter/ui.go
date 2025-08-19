package presenter

import (
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/appbar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/bottombar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/containerbox"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/navbar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/scaffold"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/viewbox"
	tea "github.com/charmbracelet/bubbletea"
)

// Ensure HomeView implements the ViewBox interface.
var _ viewbox.ViewBox = (*HomeView)(nil)

// HomeView is the ViewBox for the home screen.
// It owns the scaffold and provides the content to be displayed.
type HomeView struct {
	scaffold scaffold.Model
}

func New() *HomeView {
	// Create the components that this screen needs.
	appBar := appbar.New()
	navBar := navbar.New()
	bottomBar := bottombar.New()
	containerBox := containerbox.New()


	// Create a new scaffold and explicitly add the desired components.
	scaffold := scaffold.New(
		// Components
		scaffold.WithAppBar(appBar),
		scaffold.WithNavBar(navBar),
		scaffold.WithBottomBar(bottomBar),
		scaffold.WithContainerBox(containerBox),

		// Styling
		//scaffold.WithMargin(1),
		scaffold.WithBackgroundColor("#0F0F0F"),
		scaffold.WithAppBarBackgroundColor("#202020"),
		scaffold.WithContainerBoxBackgroundColor("#5DD62C"),
	)

	return &HomeView{
		scaffold: scaffold,
	}
}

func (hv *HomeView) Init() tea.Cmd {
	return hv.scaffold.Init()
}

func (hv *HomeView) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	// The scaffold model is not a pointer, so we don't need to dereference it.
	// Also, its Update method returns a Model, not a pointer to one.
	newScaffold, cmd := hv.scaffold.Update(msg)
	hv.scaffold = newScaffold
	return hv, cmd
}

func (hv *HomeView) View() string {
	//homeContent := "Welcome to the Home Screen!\n\nThis is the content area managed by the HomeView.\n\nMy Scaffold is now fully optional!"

	//hv.scaffold.SetContent(homeContent)
	return hv.scaffold.View()
}