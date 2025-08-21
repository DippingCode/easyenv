package containerbox

import (
	"github.com/DippingCode/easyenv/pkg/core/adapters/tui"
)

// Ensure Model implements the ContainerBox and tui.Layout interfaces.
var _ ContainerBox = (*Model)(nil)
var _ tui.Layout = (*Model)(nil)

// ContainerBox is the interface for a screen that can be loaded into the Scaffold.
// It is an alias for tui.Model.
type ContainerBox interface {
	tui.Model
	tui.Layout // Embed tui.Layout for styling methods
}

// Option is a functional option for configuring the ContainerBox.
type Option func(*Model)

// Model is a basic implementation of a ContainerBox.
type Model struct {
	width, height int
	desiredWidth, desiredHeight int // 0 means not explicitly set
	style tui.Style
}

// New creates a new ContainerBox with the given options.
func New(opts ...Option) *Model {
	m := &Model{
		style: tui.NewStyle(),
	}

	for _, opt := range opts {
		opt(m)
	}

	return m
}

// --- Functional Options ---

func WithBackgroundColor(color string) Option {
	return func(m *Model) { m.BackgroundColor(color) }
}

func WithBorder(border tui.Border, sides ...bool) Option {
	return func(m *Model) { m.Border(border, sides...) }
}

func WithBorderForeground(color string) Option {
	return func(m *Model) { m.BorderForeground(color) }
}

func WithPadding(p ...int) Option {
	return func(m *Model) { m.Padding(p...) }
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

// --- tui.Model Implementation ---

func (m *Model) Init() tui.Cmd {
	return nil
}

func (m *Model) Update(msg tui.Msg) (tui.Model, tui.Cmd) {
	switch msg := msg.(type) {
	case tui.WindowSizeMsg:
		// Calculate available space from parent
		availableWidth := msg.Width
		availableHeight := msg.Height

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

		// No longer subtracting GetFrameSize here. The style's Width/Height will handle it.
	}
	return m, nil
}

func (m *Model) View() string {
	// Calculate content dimensions based on total width/height and frame size
	hFrame, vFrame := m.style.GetFrameSize()
	contentWidth := m.width - hFrame
	contentHeight := m.height - vFrame

	// Render the content with the calculated content dimensions
	return m.style.Width(contentWidth).Height(contentHeight).Render("Default ContainerBox")
}

// --- tui.Layout Implementation ---

func (m *Model) BackgroundColor(color string) tui.Layout {
	m.style.Background(color)
	return m
}

func (m *Model) Border(border tui.Border, sides ...bool) tui.Layout {
	m.style.Border(border, sides...)
	return m
}

func (m *Model) BorderForeground(color string) tui.Layout {
	m.style.BorderForeground(color)
	return m
}

func (m *Model) Padding(p ...int) tui.Layout {
	m.style.Padding(p...)
	return m
}

func (m *Model) Width(width int) tui.Layout {
	m.desiredWidth = width
	// m.style.Width(width) // REMOVED: This is now handled in View()
	return m
}

func (m *Model) Height(height int) tui.Layout {
	m.desiredHeight = height
	// m.style.Height(height) // REMOVED: This is now handled in View()
	return m
}

func (m *Model) Align(pos tui.Position) tui.Layout {
	m.style.Align(pos)
	return m
}
