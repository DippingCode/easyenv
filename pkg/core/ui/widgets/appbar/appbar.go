//Package appbar
package appbar

import (
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Option is a functional option for configuring the AppBar.
type Option func(*Model)

// Model represents the AppBar component.
type Model struct {
	width  int
	height int

	// Components
	leading tea.Model
	title   tea.Model
	actions []tea.Model

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

// WithLeading sets the leading component of the AppBar.
func WithLeading(component tea.Model) Option {
	return func(m *Model) {
		m.leading = component
	}
}

// WithTitle sets the title component of the AppBar.
func WithTitle(component tea.Model) Option {
	return func(m *Model) {
		m.title = component
	}
}

// WithActions sets the action components of the AppBar.
func WithActions(components ...tea.Model) Option {
	return func(m *Model) {
		m.actions = components
	}
}

// WithHeight sets the height of the AppBar.
func WithHeight(h int) Option {
	return func(m *Model) {
		m.height = h
		m.style = m.style.Height(h)
	}
}

// WithBackgroundColor sets the background color of the AppBar.
func WithBackgroundColor(color string) Option {
	return func(m *Model) {
		m.style = m.style.Background(lipgloss.Color(color))
	}
}

// WithStyle allows setting a custom lipgloss style.
func WithStyle(style lipgloss.Style) Option {
	return func(m *Model) {
		m.style = style
	}
}

// Init initializes the AppBar component and its children.
func (m Model) Init() tea.Cmd {
	var cmds []tea.Cmd
	if m.leading != nil {
		cmds = append(cmds, m.leading.Init())
	}
	if m.title != nil {
		cmds = append(cmds, m.title.Init())
	}
	for _, action := range m.actions {
		cmds = append(cmds, action.Init())
	}
	return tea.Batch(cmds...)
}

// Update handles messages for the AppBar and its children.
func (m Model) Update(msg tea.Msg) (Model, tea.Cmd) {
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
	}

	// Propagate updates to children
	if m.leading != nil {
		var cmd tea.Cmd
		m.leading, cmd = m.leading.Update(msg)
		cmds = append(cmds, cmd)
	}
	if m.title != nil {
		var cmd tea.Cmd
		m.title, cmd = m.title.Update(msg)
		cmds = append(cmds, cmd)
	}
	for i, action := range m.actions {
		var cmd tea.Cmd
		m.actions[i], cmd = action.Update(msg)
		cmds = append(cmds, cmd)
	}

	return m, tea.Batch(cmds...)
}

// View renders the AppBar.
func (m Model) View() string {
	// Render children
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

	// Calculate remaining space for the title
	// The padding on the style will affect the available width
	hPadding, _ := m.style.GetFrameSize()
	remainingWidth := m.width - leadingWidth - actionsWidth - hPadding

	// Create a flexible spacer to push actions to the right
	spacer := lipgloss.NewStyle().Width(remainingWidth).Render("")

	// Assemble the final view
	content := lipgloss.JoinHorizontal(
		lipgloss.Center,
		leadingView,
		titleView,
		spacer,
		actionsCombined,
	)

	return m.style.Width(m.width).Render(content)
}