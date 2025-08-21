//Package tui
package tui

import (
	lg "github.com/charmbracelet/lipgloss"
)

// Position corresponds to lipgloss.Position.
type Position float64

const (
	Left   Position = 0.0
	Center Position = 0.5
	Right  Position = 1.0
	Top    Position = 0.0
	Bottom Position = 1.0
)

// Border corresponds to lipgloss.Border
type Border struct {
	Top         string
	Bottom      string
	Left        string
	Right       string
	TopLeft     string
	TopRight    string
	BottomLeft  string
	BottomRight string
}

// Pre-defined borders, converted manually.
var (
	NormalBorder  = fromLipglossBorder(lg.NormalBorder())
	RoundedBorder = fromLipglossBorder(lg.RoundedBorder())
	DoubleBorder  = fromLipglossBorder(lg.DoubleBorder())
	ThickBorder   = fromLipglossBorder(lg.ThickBorder())
	HiddenBorder  = fromLipglossBorder(lg.HiddenBorder())
)

// Style is an interface that abstracts the lipgloss.Style.
// It allows for setting styling rules and rendering strings.
type Style interface {
	// Manipulation
	Width(int) Style
	Height(int) Style
	Padding(...int) Style
	Margin(...int) Style
	Align(Position) Style

	// Colors
	Foreground(string) Style
	Background(string) Style

	// Text Properties
	Bold(bool) Style
	Italic(bool) Style
	Underline(bool) Style

	// Border
	Border(Border, ...bool) Style
	BorderForeground(string) Style

	// Rendering & Introspection
	Render(string) string
	GetFrameSize() (horizontal int, vertical int)

	// Get the underlying lipgloss style, for advanced use cases or compatibility.
	GetLipglossStyle() lg.Style
}

// lipglossAdapter implements the Style interface using a lipgloss.Style.
// Ensure it implements the interface.
var _ Style = (*lipglossAdapter)(nil)

type lipglossAdapter struct {
	style lg.Style
}

// NewStyle creates a new style adapter.
func NewStyle() Style {
	return &lipglossAdapter{
		style: lg.NewStyle(),
	}
}

// --- Implementation ---

func (s *lipglossAdapter) Width(i int) Style {
	s.style = s.style.Width(i)
	return s
}

func (s *lipglossAdapter) Height(i int) Style {
	s.style = s.style.Height(i)
	return s
}

func (s *lipglossAdapter) Padding(p ...int) Style {
	s.style = s.style.Padding(p...)
	return s
}

func (s *lipglossAdapter) Margin(m ...int) Style {
	s.style = s.style.Margin(m...)
	return s
}

func (s *lipglossAdapter) Align(p Position) Style {
	s.style = s.style.Align(lg.Position(p))
	return s
}

func (s *lipglossAdapter) Foreground(str string) Style {
	s.style = s.style.Foreground(lg.Color(str))
	return s
}

func (s *lipglossAdapter) Background(str string) Style {
	s.style = s.style.Background(lg.Color(str))
	return s
}

func (s *lipglossAdapter) Bold(b bool) Style {
	s.style = s.style.Bold(b)
	return s
}

func (s *lipglossAdapter) Italic(b bool) Style {
	s.style = s.style.Italic(b)
	return s
}

func (s *lipglossAdapter) Underline(b bool) Style {
	s.style = s.style.Underline(b)
	return s
}

func (s *lipglossAdapter) Border(b Border, v ...bool) Style {
	lgBorder := toLipglossBorder(b)
	s.style = s.style.Border(lgBorder, v...)
	return s
}

func (s *lipglossAdapter) BorderForeground(str string) Style {
	s.style = s.style.BorderForeground(lg.Color(str))
	return s
}

func (s *lipglossAdapter) Render(str string) string {
	return s.style.Render(str)
}

func (s *lipglossAdapter) GetFrameSize() (int, int) {
	return s.style.GetFrameSize()
}

func (s *lipglossAdapter) GetLipglossStyle() lg.Style {
	return s.style
}

// --- Conversion Helpers ---

// fromLipglossBorder converts a lipgloss.Border to a style.Border.
func fromLipglossBorder(b lg.Border) Border {
	return Border{
		Top:         b.Top,
		Bottom:      b.Bottom,
		Left:        b.Left,
		Right:       b.Right,
		TopLeft:     b.TopLeft,
		TopRight:    b.TopRight,
		BottomLeft:  b.BottomLeft,
		BottomRight: b.BottomRight,
	}
}

// toLipglossBorder converts a style.Border to a lipgloss.Border.
func toLipglossBorder(b Border) lg.Border {
	return lg.Border{
		Top:         b.Top,
		Bottom:      b.Bottom,
		Left:        b.Left,
		Right:       b.Right,
		TopLeft:     b.TopLeft,
		TopRight:    b.TopRight,
		BottomLeft:  b.BottomLeft,
		BottomRight: b.BottomRight,
	}
}

// --- Join Functions ---

// JoinHorizontal joins strings horizontally.
func JoinHorizontal(pos Position, ss ...string) string {
	return lg.JoinHorizontal(lg.Position(pos), ss...)
}

// JoinVertical joins strings vertically.
func JoinVertical(pos Position, ss ...string) string {
	return lg.JoinVertical(lg.Position(pos), ss...)
}

