//Package scaffold
package scaffold

import (
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/appbar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/bottombar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/containerbox"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/navbar"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Option is a functional option for configuring the Scaffold.
type Option func(*Model)

// Model is the scaffold for the entire application UI.
type Model struct {
	width, height int

	// Components are now pointers, so they can be nil (optional).
	AppBar    *appbar.Model
	NavBar    *navbar.Model
	BottomBar *bottombar.Model
	ContainerBox  *containerbox.Model

	// Styling & Sizing
	marginStyle      lipgloss.Style
	containerStyle   lipgloss.Style
	appBarStyle      lipgloss.Style
	navBarStyle      lipgloss.Style
	bottomBarStyle   lipgloss.Style
	containerboxStyle     lipgloss.Style
	appBarHeight     int
	navBarWidth      int
	bottomBarHeight  int
}

// New creates a new scaffold model with the given options.
func New(opts ...Option) Model {
	m := Model{
		marginStyle:     lipgloss.NewStyle(),
		containerStyle:  lipgloss.NewStyle(),
		appBarStyle:     lipgloss.NewStyle(),
		navBarStyle:     lipgloss.NewStyle(),
		bottomBarStyle:  lipgloss.NewStyle(),
		containerboxStyle:    lipgloss.NewStyle(),
	}

	for _, opt := range opts {
		opt(&m)
	}

	return m
}

// --- COMPONENT OPTIONS ---

func WithAppBar(appBar appbar.Model) Option {
	return func(m *Model) { m.AppBar = &appBar }
}

func WithNavBar(navBar navbar.Model) Option {
	return func(m *Model) { m.NavBar = &navBar }
}

func WithBottomBar(bottomBar bottombar.Model) Option {
	return func(m *Model) { m.BottomBar = &bottomBar }
}

func WithContainerBox(containerbox containerbox.Model) Option {
	return func(m *Model) { m.ContainerBox = &containerbox }
}

// --- STYLING OPTIONS ---

func WithMargin(m ...int) Option {
	return func(model *Model) {
		switch len(m) {
		case 1: model.marginStyle = model.marginStyle.Margin(m[0])
		case 2: model.marginStyle = model.marginStyle.Margin(m[0], m[1])
		case 3: model.marginStyle = model.marginStyle.Margin(m[0], m[1], m[2])
		case 4: model.marginStyle = model.marginStyle.Margin(m[0], m[1], m[2], m[3])
		}
	}
}

func WithPadding(p ...int) Option {
	return func(model *Model) {
		switch len(p) {
		case 1: model.containerStyle = model.containerStyle.Padding(p[0])
		case 2: model.containerStyle = model.containerStyle.Padding(p[0], p[1])
		case 3: model.containerStyle = model.containerStyle.Padding(p[0], p[1], p[2])
		case 4: model.containerStyle = model.containerStyle.Padding(p[0], p[1], p[2], p[3])
		}
	}
}

func WithBackgroundColor(c string) Option {
	return func(m *Model) { m.containerStyle = m.containerStyle.Background(lipgloss.Color(c)) }
}

func WithAppBarBackgroundColor(c string) Option {
	return func(m *Model) { m.appBarStyle = m.appBarStyle.Background(lipgloss.Color(c)) }
}

func WithNavBarBackgroundColor(c string) Option {
	return func(m *Model) { m.navBarStyle = m.navBarStyle.Background(lipgloss.Color(c)) }
}

func WithBottomBarBackgroundColor(c string) Option {
	return func(m *Model) { m.bottomBarStyle = m.bottomBarStyle.Background(lipgloss.Color(c)) }
}

func WithContainerBoxBackgroundColor(c string) Option {
	return func(m *Model) { m.containerboxStyle = m.containerboxStyle.Background(lipgloss.Color(c)) }
}

// --- SIZING OPTIONS ---

func WithAppBarHeight(h int) Option {
	return func(m *Model) { m.appBarHeight = h }
}

func WithNavBarWidth(w int) Option {
	return func(m *Model) { m.navBarWidth = w }
}

func WithBottomBarHeight(h int) Option {
	return func(m *Model) { m.bottomBarHeight = h }
}

func (m *Model) Init() tea.Cmd {
	return nil
}

func (m *Model) Update(msg tea.Msg) (Model, tea.Cmd) {
	var (
		cmd  tea.Cmd
		cmds []tea.Cmd
	)

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		hMargin, vMargin := m.marginStyle.GetFrameSize()
		hPadding, vPadding := m.containerStyle.GetFrameSize()
		m.width = msg.Width - hMargin - hPadding
		m.height = msg.Height - vMargin - vPadding
	}

	if m.AppBar != nil {
		var updatedAppBar appbar.Model
		updatedAppBar, cmd = m.AppBar.Update(msg)
		*m.AppBar = updatedAppBar
		cmds = append(cmds, cmd)
	}
	if m.NavBar != nil {
		var updatedNavBar navbar.Model
		updatedNavBar, cmd = m.NavBar.Update(msg)
		*m.NavBar = updatedNavBar
		cmds = append(cmds, cmd)
	}
	if m.BottomBar != nil {
		var updatedBottomBar bottombar.Model
		updatedBottomBar, cmd = m.BottomBar.Update(msg)
		*m.BottomBar = updatedBottomBar
		cmds = append(cmds, cmd)
	}

	return *m, tea.Batch(cmds...)
}

func (m *Model) View() string {
	if m.width <= 0 || m.height <= 0 {
		return "Initializing scaffold..."
	}

	appBarHeight := 0
	if m.AppBar != nil {
		appBarHeight = m.appBarHeight
		if appBarHeight == 0 { appBarHeight = 3 }
	}

	bottomBarHeight := 0
	if m.BottomBar != nil {
		bottomBarHeight = m.bottomBarHeight
		if bottomBarHeight == 0 { bottomBarHeight = 3 }
	}

	navBarWidth := 0
	if m.NavBar != nil {
		navBarWidth = m.navBarWidth
		if navBarWidth == 0 { navBarWidth = 20 }
	}

	containerBoxHeight := m.height - appBarHeight - bottomBarHeight
	containerBoxWidth := m.width - navBarWidth

	var appBarView, navBarView, bottomBarView, containerBoxView string

	if m.AppBar != nil {
		style := m.appBarStyle.Width(m.width).Height(appBarHeight).Align(lipgloss.Center)
		appBarView = style.Render(m.AppBar.View())
	}

	if m.NavBar != nil {
		style := m.navBarStyle.Width(navBarWidth).Height(containerBoxHeight).Align(lipgloss.Center)
		navBarView = style.Render(m.NavBar.View())
	}

	if m.BottomBar != nil {
		style := m.bottomBarStyle.Width(m.width).Height(bottomBarHeight).Align(lipgloss.Center)
		bottomBarView = style.Render(m.BottomBar.View())
	}

	if(m.ContainerBox != nil){
		style := m.containerboxStyle.Width(containerBoxWidth).Height(containerBoxHeight).Align(lipgloss.Center)
		containerBoxView = style.Render(m.ContainerBox.View())
	}

	maincontainerbox := lipgloss.JoinHorizontal(lipgloss.Top, navBarView, containerBoxView)

	finalView := lipgloss.JoinVertical(lipgloss.Left, appBarView, maincontainerbox, bottomBarView)

	container := m.containerStyle.Width(m.width).Height(m.height).Render(finalView)

	return m.marginStyle.Render(container)
}
