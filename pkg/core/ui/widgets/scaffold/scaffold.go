package scaffold

import (
	"github.com/DippingCode/easyenv/pkg/core/adapters/tui"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/appbar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/bottombar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/containerbox"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/sidemenu"
)

// Ensure Model implements the tui.Model and tui.Layout interfaces.
var _ tui.Model = (*Model)(nil)
var _ tui.Layout = (*Model)(nil)

// Option is a functional option for configuring the Scaffold.
type Option func(*Model)

type Model struct {
	width, height int
	desiredWidth, desiredHeight int // 0 means not explicitly set

	AppBar       *appbar.Model
	sidemenu       *sidemenu.Model
	BottomBar    *bottombar.Model
	ContainerBox *containerbox.Model

	marginStyle       tui.Style
	containerStyle    tui.Style
	appBarStyle       tui.Style
	sidemenuStyle       tui.Style
	bottomBarStyle    tui.Style
	containerboxStyle tui.Style
	appBarHeight      int
	sidemenuWidth       int
	bottomBarHeight   int
}

// New creates a new Scaffold model with the given options.
func New(opts ...Option) *Model {
	m := &Model{
		marginStyle:       tui.NewStyle(),
		containerStyle:    tui.NewStyle(),
		appBarStyle:       tui.NewStyle(),
		sidemenuStyle:       tui.NewStyle(),
		bottomBarStyle:    tui.NewStyle(),
		containerboxStyle: tui.NewStyle(),
	}

	for _, opt := range opts {
		opt(m)
	}

	return m
}

// --- Functional Options ---

func WithAppBar(appBar *appbar.Model) Option {
	return func(m *Model) { m.AppBar = appBar }
}

func Withsidemenu(sidemenu *sidemenu.Model) Option {
	return func(m *Model) { m.sidemenu = sidemenu }
}

func WithBottomBar(bottomBar *bottombar.Model) Option {
	return func(m *Model) { m.BottomBar = bottomBar }
}

func WithContainerBox(containerbox *containerbox.Model) Option {
	return func(m *Model) { m.ContainerBox = containerbox }
}

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

func WithsidemenuBackgroundColor(c string) Option {
	return func(m *Model) { m.sidemenuStyle.Background(c) }
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

func WithsidemenuWidth(w int) Option {
	return func(m *Model) { m.sidemenuWidth = w }
}

func WithBottomBarHeight(h int) Option {
	return func(m *Model) { m.bottomBarHeight = h }
}

func WithWidth(width int) Option {
	return func(m *Model) { m.Width(width) }
}

func WithHeight(height int) Option {
	return func(m *Model) { m.Height(height) }
}

func WithAlign(pos tui.Position) Option {
	return func(m *Model) { m.Align(pos) }
}

// --- TUI MODEL IMPLEMENTATION ---

func (m *Model) Init() tui.Cmd {
	// Delegate Init to children
	var cmds []tui.Cmd
	if m.AppBar != nil {
		cmds = append(cmds, m.AppBar.Init())
	}
	if m.sidemenu != nil {
		cmds = append(cmds, m.sidemenu.Init())
	}
	if m.BottomBar != nil {
		cmds = append(cmds, m.BottomBar.Init())
	}
	if m.ContainerBox != nil {
		cmds = append(cmds, m.ContainerBox.Init())
	}
	return tui.Batch(cmds...)
}

func (m *Model) Update(msg tui.Msg) (tui.Model, tui.Cmd) {
	var cmds []tui.Cmd

	// Handle WindowSizeMsg for the Scaffold itself
	if wsMsg, ok := msg.(tui.WindowSizeMsg); ok {
		// Calculate available space from parent
		availableWidth := wsMsg.Width
		availableHeight := wsMsg.Height

		// Apply desired dimensions if set, otherwise use available space
		if m.desiredWidth > 0 {
			m.width = m.desiredWidth
		} else {
			m.width = availableWidth
		}

		if m.desiredHeight > 0 {
			m.height = m.desiredHeight
		} else {
			m.height = availableHeight
		}

		// Now, calculate slot dimensions for children based on Scaffold's new size
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

		sidemenuWidth := 0
		if m.sidemenu != nil {
			sidemenuWidth = m.sidemenuWidth
			if sidemenuWidth == 0 {
				sidemenuWidth = 20
			}
		}

		mainContentHeight := m.height - appBarHeight - bottomBarHeight
		mainContentWidth := m.width

		// Delegate updates to children, passing their specific slot dimensions
		if m.AppBar != nil {
			appBarSlotMsg := tui.WindowSizeMsg{Width: m.width, Height: appBarHeight}
			newAppBar, cmd := m.AppBar.Update(appBarSlotMsg)
			newAppBarModel := newAppBar.(*appbar.Model)
			*m.AppBar = *newAppBarModel
			cmds = append(cmds, cmd)
		}

		if m.sidemenu != nil {
			sidemenuSlotMsg := tui.WindowSizeMsg{Width: sidemenuWidth, Height: mainContentHeight}
			newsidemenu, cmd := m.sidemenu.Update(sidemenuSlotMsg)
			newsidemenuModel := newsidemenu.(*sidemenu.Model)
			*m.sidemenu = *newsidemenuModel
			cmds = append(cmds, cmd)
		}

		if m.BottomBar != nil {
			bottomBarSlotMsg := tui.WindowSizeMsg{Width: m.width, Height: bottomBarHeight}
			newBottomBar, cmd := m.BottomBar.Update(bottomBarSlotMsg)
			newBottomBarModel := newBottomBar.(*bottombar.Model)
			*m.BottomBar = *newBottomBarModel
			cmds = append(cmds, cmd)
		}

		if m.ContainerBox != nil {
			containerBoxSlotWidth := mainContentWidth - sidemenuWidth
			containerBoxSlotMsg := tui.WindowSizeMsg{Width: containerBoxSlotWidth, Height: mainContentHeight}
			newContainerBox, cmd := m.ContainerBox.Update(containerBoxSlotMsg)
			newContainerBoxModel := newContainerBox.(*containerbox.Model)
			*m.ContainerBox = *newContainerBoxModel
			cmds = append(cmds, cmd)
		}
	} else {
		// If it's not a WindowSizeMsg, propagate the original message to all children
		if m.AppBar != nil {
			newAppBar, cmd := m.AppBar.Update(msg)
			newAppBarModel := newAppBar.(*appbar.Model)
			*m.AppBar = *newAppBarModel
			cmds = append(cmds, cmd)
		}
		if m.sidemenu != nil {
			newsidemenu, cmd := m.sidemenu.Update(msg)
			newsidemenuModel := newsidemenu.(*sidemenu.Model)
			*m.sidemenu = *newsidemenuModel
			cmds = append(cmds, cmd)
		}
		if m.BottomBar != nil {
			newBottomBar, cmd := m.BottomBar.Update(msg)
			newBottomBarModel := newBottomBar.(*bottombar.Model)
			*m.BottomBar = *newBottomBarModel
			cmds = append(cmds, cmd)
		}
		if m.ContainerBox != nil {
			newContainerBox, cmd := m.ContainerBox.Update(msg)
			newContainerBoxModel := newContainerBox.(*containerbox.Model)
			*m.ContainerBox = *newContainerBoxModel
			cmds = append(cmds, cmd)
		}
	}

	return m, tui.Batch(cmds...)
}

func (m *Model) View() string {
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

	sidemenuWidth := 0
	if m.sidemenu != nil {
		sidemenuWidth = m.sidemenuWidth
		if sidemenuWidth == 0 {
			sidemenuWidth = 20
		}
	}

	containerBoxHeight := m.height - appBarHeight - bottomBarHeight
	containerBoxWidth := m.width - sidemenuWidth

	var appBarView, sidemenuView, bottomBarView, containerBoxView string

	if m.AppBar != nil {
		viewStyle := m.appBarStyle.Width(m.width).Height(appBarHeight).Align(tui.Center)
		appBarView = viewStyle.Render(m.AppBar.View())
	}

	if m.sidemenu != nil {
		viewStyle := m.sidemenuStyle.Width(sidemenuWidth).Height(containerBoxHeight).Align(tui.Center)
		sidemenuView = viewStyle.Render(m.sidemenu.View())
	}

	if m.BottomBar != nil {
		viewStyle := m.bottomBarStyle.Width(m.width).Height(bottomBarHeight).Align(tui.Center)
		bottomBarView = viewStyle.Render(m.BottomBar.View())
	}

	if m.ContainerBox != nil {
		viewStyle := m.containerboxStyle.Width(containerBoxWidth).Height(containerBoxHeight).Align(tui.Center)
		containerBoxView = viewStyle.Render(m.ContainerBox.View())
	}

	maincontainerbox := tui.JoinHorizontal(tui.Top, sidemenuView, containerBoxView)

	finalView := tui.JoinVertical(tui.Left, appBarView, maincontainerbox, bottomBarView)

	container := m.containerStyle.Width(m.width).Height(m.height).Render(finalView)

	return m.marginStyle.Render(container)
}

// --- layout.Layout Implementation ---

func (m *Model) BackgroundColor(color string) tui.Layout {
	m.containerStyle.Background(color)
	return m
}

func (m *Model) Border(border tui.Border, sides ...bool) tui.Layout {
	m.containerStyle.Border(border, sides...)
	return m
}

func (m *Model) BorderForeground(color string) tui.Layout {
	m.containerStyle.BorderForeground(color)
	return m
}

func (m *Model) Padding(p ...int) tui.Layout {
	m.containerStyle.Padding(p...)
	return m
}

func (m *Model) Width(width int) tui.Layout {
	m.desiredWidth = width
	m.containerStyle.Width(width) // Apply to style immediately for GetFrameSize
	return m
}

func (m *Model) Height(height int) tui.Layout {
	m.desiredHeight = height
	m.containerStyle.Height(height) // Apply to style immediately for GetFrameSize
	return m
}

func (m *Model) Align(pos tui.Position) tui.Layout {
	m.containerStyle.Align(pos)
	return m
}