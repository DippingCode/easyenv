package appbar

import (
	"github.com/DippingCode/easyenv/pkg/core/adapters/tui"
	"github.com/charmbracelet/lipgloss"
)

// Ensure Model implements the tui.Model interface.
var _ tui.Model = (*Model)(nil)

// Option is a functional option for configuring the AppBar.
type Option func(*Model)

// Model represents the AppBar component.
type Model struct {
	width  int
	height int

	// Components
	leading tui.Model
	title   tui.Model
	actions []tui.Model

	// Styling
	style lipgloss.Style
}

// New creates a new AppBar model with the given options.
func New(opts ...Option) Model {
	m := Model{
		style: lipgloss.NewStyle(),
	}

	for _, opt := range opts {
		opt(&m)
	}

	return m
}

// --- OPTIONS ---

func WithLeading(component tui.Model) Option {
	return func(m *Model) {
		m.leading = component
	}
}

func WithTitle(component tui.Model) Option {
	return func(m *Model) {
		m.title = component
	}
}

func WithActions(components ...tui.Model) Option {
	return func(m *Model) {
		m.actions = components
	}
}

func WithHeight(h int) Option {
	return func(m *Model) {
		m.height = h
		m.style = m.style.Height(h)
	}
}

func WithBackgroundColor(color string) Option {
	return func(m *Model) {
		m.style = m.style.Background(lipgloss.Color(color))
	}
}

func WithStyle(style lipgloss.Style) Option {
	return func(m *Model) {
		m.style = style
	}
}

func (m Model) Init() tui.Cmd {
	// This is a placeholder. A real implementation would batch commands from children.
	return nil
}

func (m Model) Update(msg tui.Msg) (tui.Model, tui.Cmd) {
	switch msg := msg.(type) {
	case tui.WindowSizeMsg:
		m.width = msg.Width
	}

	// A real implementation would propagate updates to children and batch commands.
	return m, nil
}

func (m Model) View() string {
	var leadingView, titleView string
	var actionsView []string

	leadingWidth := 0
	if m.leading != nil {
		leadingView = m.leading.View()
		leadingWidth = lipgloss.Width(leadingView)
	}

	if m.title != nil {
		titleView = m.title.View()
	}

	actionsWidth := 0
	for _, action := range m.actions {
		view := action.View()
		actionsWidth += lipgloss.Width(view)
		actionsView = append(actionsView, view)
	}
	actionsCombined := lipgloss.JoinHorizontal(lipgloss.Center, actionsView...)

	hPadding, _ := m.style.GetFrameSize()
	remainingWidth := m.width - leadingWidth - actionsWidth - hPadding

	spacer := lipgloss.NewStyle().Width(remainingWidth).Render("")

	content := lipgloss.JoinHorizontal(
		lipgloss.Center,
		leadingView,
		titleView,
		spacer,
		actionsCombined,
	)

	return m.style.Width(m.width).Render(content)
}
