package scaffold

import (
	"github.com/DippingCode/easyenv/pkg/core/adapters/tui"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/appbar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/bottombar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/containerbox"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/navbar"
)

var _ tui.Model = (*Model)(nil)

type Option func(*Model)

type Model struct {
	width, height int

	AppBar       *appbar.Model
	NavBar       *navbar.Model
	BottomBar    *bottombar.Model
	ContainerBox *containerbox.Model

	marginStyle       tui.Style
	containerStyle    tui.Style
	appBarStyle       tui.Style
	navBarStyle       tui.Style
	bottomBarStyle    tui.Style
	containerboxStyle tui.Style
	appBarHeight      int
	navBarWidth       int
	bottomBarHeight   int
}

func New(opts ...Option) Model {
	m := Model{
		marginStyle:       tui.NewStyle(),
		containerStyle:    tui.NewStyle(),
		appBarStyle:       tui.NewStyle(),
		navBarStyle:       tui.NewStyle(),
		bottomBarStyle:    tui.NewStyle(),
		containerboxStyle: tui.NewStyle(),
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

// --- STYLING & SIZING OPTIONS ---

func WithMargin(m ...int) Option {
	return func(model *Model) { model.marginStyle.Margin(m...) }
}

func WithPadding(p ...int) Option {
	return func(model *Model) { model.containerStyle.Padding(p...) }
}

func WithBackgroundColor(c string) Option {
	return func(m *Model) { m.containerStyle.Background(c) }
}

func WithAppBarBackgroundColor(c string) Option {
	return func(m *Model) { m.appBarStyle.Background(c) }
}

func WithNavBarBackgroundColor(c string) Option {
	return func(m *Model) { m.navBarStyle.Background(c) }
}

func WithBottomBarBackgroundColor(c string) Option {
	return func(m *Model) { m.bottomBarStyle.Background(c) }
}

func WithContainerBoxBackgroundColor(c string) Option {
	return func(m *Model) { m.containerboxStyle.Background(c) }
}

func WithAppBarHeight(h int) Option {
	return func(m *Model) { m.appBarHeight = h }
}

func WithNavBarWidth(w int) Option {
	return func(m *Model) { m.navBarWidth = w }
}

func WithBottomBarHeight(h int) Option {
	return func(m *Model) { m.bottomBarHeight = h }
}

// --- TUI MODEL IMPLEMENTATION ---

func (m Model) Init() tui.Cmd {
	// Delegate Init to children
	var cmds []tui.Cmd
	if m.AppBar != nil {
		cmds = append(cmds, m.AppBar.Init())
	}
	if m.NavBar != nil {
		cmds = append(cmds, m.NavBar.Init())
	}
	if m.BottomBar != nil {
		cmds = append(cmds, m.BottomBar.Init())
	}
	if m.ContainerBox != nil {
		cmds = append(cmds, m.ContainerBox.Init())
	}
	return tui.Batch(cmds...)
}

func (m Model) Update(msg tui.Msg) (tui.Model, tui.Cmd) {
	var cmds []tui.Cmd

	switch msg := msg.(type) {
	case tui.WindowSizeMsg:
		hMargin, vMargin := m.marginStyle.GetFrameSize()
		hPadding, vPadding := m.containerStyle.GetFrameSize()
		m.width = msg.Width - hMargin - hPadding
		m.height = msg.Height - vMargin - vPadding
	}

	// Delegate updates to children
	if m.AppBar != nil {
		newAppBar, cmd := m.AppBar.Update(msg)
		*m.AppBar = newAppBar.(appbar.Model)
		cmds = append(cmds, cmd)
	}
	if m.NavBar != nil {
		newNavBar, cmd := m.NavBar.Update(msg)
		*m.NavBar = newNavBar.(navbar.Model)
		cmds = append(cmds, cmd)
	}
	if m.BottomBar != nil {
		newBottomBar, cmd := m.BottomBar.Update(msg)
		*m.BottomBar = newBottomBar.(bottombar.Model)
		cmds = append(cmds, cmd)
	}
	if m.ContainerBox != nil {
		newContainerBox, cmd := m.ContainerBox.Update(msg)
		*m.ContainerBox = newContainerBox.(containerbox.Model)
		cmds = append(cmds, cmd)
	}

	return m, tui.Batch(cmds...)
}

func (m Model) View() string {
	if m.width <= 0 || m.height <= 0 {
		return "Initializing scaffold..."
	}

	appBarHeight := 0
	if m.AppBar != nil {
		appBarHeight = m.appBarHeight
		if appBarHeight == 0 {
			appBarHeight = 3
		}
	}

	bottomBarHeight := 0
	if m.BottomBar != nil {
		bottomBarHeight = m.bottomBarHeight
		if bottomBarHeight == 0 {
			bottomBarHeight = 3
		}
	}

	navBarWidth := 0
	if m.NavBar != nil {
		navBarWidth = m.navBarWidth
		if navBarWidth == 0 {
			navBarWidth = 20
		}
	}

	containerBoxHeight := m.height - appBarHeight - bottomBarHeight
	containerBoxWidth := m.width - navBarWidth

	var appBarView, navBarView, bottomBarView, containerBoxView string

	if m.AppBar != nil {
		viewStyle := m.appBarStyle.Width(m.width).Height(appBarHeight).Align(tui.Center)
		appBarView = viewStyle.Render(m.AppBar.View())
	}

	if m.NavBar != nil {
		viewStyle := m.navBarStyle.Width(navBarWidth).Height(containerBoxHeight).Align(tui.Center)
		navBarView = viewStyle.Render(m.NavBar.View())
	}

	if m.BottomBar != nil {
		viewStyle := m.bottomBarStyle.Width(m.width).Height(bottomBarHeight).Align(tui.Center)
		bottomBarView = viewStyle.Render(m.BottomBar.View())
	}

	if m.ContainerBox != nil {
		viewStyle := m.containerboxStyle.Width(containerBoxWidth).Height(containerBoxHeight).Align(tui.Center)
		containerBoxView = viewStyle.Render(m.ContainerBox.View())
	}

	maincontainerbox := tui.JoinHorizontal(tui.Top, navBarView, containerBoxView)

	finalView := tui.JoinVertical(tui.Left, appBarView, maincontainerbox, bottomBarView)

	container := m.containerStyle.Width(m.width).Height(m.height).Render(finalView)

	return m.marginStyle.Render(container)
}