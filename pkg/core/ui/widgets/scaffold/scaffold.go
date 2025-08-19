package scaffold

import (
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/appbar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/bottombar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/navbar"
	"github.com/DippingCode/easyenv/pkg/core/ui/widgets/viewbox"
	"github.com/DippingCode/easyenv/pkg/modules/home/presenter"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Model is the scaffold for the entire application UI.
// It manages the layout and the child components.
type Model struct {
	width, height int

	AppBar    appbar.Model
	NavBar    navbar.Model
	BottomBar bottombar.Model
	ViewBox   viewbox.ViewBox
}

// New creates a new scaffold model.
func New() Model {
	return Model{
		AppBar:    appbar.New(),
		NavBar:    navbar.New(),
		BottomBar: bottombar.New(),
		// The initial screen is the Home screen.
		ViewBox: presenter.New(),
	}
}

func (m Model) Init() tea.Cmd {
	// We can initialize child components here if needed
	return nil
}

func (m Model) Update(msg tea.Msg) (Model, tea.Cmd) {
	var ( 
		cmd  tea.Cmd
		cmds []tea.Cmd
	)

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
	}

	// Pass messages to children. Note: In a real app, we'd manage focus
	// and only send messages to the focused component.
	m.AppBar, cmd = m.AppBar.Update(msg)
	cmds = append(cmds, cmd)

	m.NavBar, cmd = m.NavBar.Update(msg)
	cmds = append(cmds, cmd)

	m.BottomBar, cmd = m.BottomBar.Update(msg)
	cmds = append(cmds, cmd)

	// The tea.Model returned from a child update is a generic tea.Model,
	// so we need to type-assert it back to its concrete type.
	newViewBoxModel, cmd := m.ViewBox.Update(msg)
	m.ViewBox = newViewBoxModel.(viewbox.ViewBox)
	cmds = append(cmds, cmd)

	return m, tea.Batch(cmds...)
}

func (m Model) View() string {
	if m.width == 0 || m.height == 0 {
		return "Initializing..."
	}

	// App bar takes up a fixed height, e.g., 3 lines.
	appBarHeight := 3
	// Bottom bar takes up a fixed height, e.g., 3 lines.
	bottomBarHeight := 3

	// The remaining height is for the main content.
	mainContentHeight := m.height - appBarHeight - bottomBarHeight

	// NavBar takes up a fixed width, e.g., 20 characters.
	navBarWidth := 20
	// The remaining width is for the ViewBox.
	viewBoxWidth := m.width - navBarWidth

	// --- STYLING --- //
	appBarStyle := lipgloss.NewStyle().
		Width(m.width).
		Height(appBarHeight).
		Background(lipgloss.Color("#511a96"))

	navBarStyle := lipgloss.NewStyle().
		Width(navBarWidth).
		Height(mainContentHeight).
		Background(lipgloss.Color("#3a136d"))

	viewBoxStyle := lipgloss.NewStyle().
		Width(viewBoxWidth).
		Height(mainContentHeight).
		Background(lipgloss.Color("#290d4e"))

	bottomBarStyle := lipgloss.NewStyle().
		Width(m.width).
		Height(bottomBarHeight).
		Background(lipgloss.Color("#511a96"))

	// --- RENDER --- //
	appBarView := appBarStyle.Render(m.AppBar.View())
	navBarView := navBarStyle.Render(m.NavBar.View())
	viewBoxView := viewBoxStyle.Render(m.ViewBox.View())
	bottomBarView := bottomBarStyle.Render(m.BottomBar.View())

	// Join NavBar and ViewBox horizontally.
	mainContent := lipgloss.JoinHorizontal(
		lipgloss.Top,
		navBarView,
		viewBoxView,
	)

	// Join all parts vertically.
	return lipgloss.JoinVertical(
		lipgloss.Left,
		appBarView,
		mainContent,
		bottomBarView,
	)
}