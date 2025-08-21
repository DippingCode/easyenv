package tui

// Component is an interface for widgets that primarily display content.
// It embeds the base Widget interface and provides methods for component-specific styling.
type Component interface {
	Widget
	// Styling methods
	BackgroundColor(color string) Component
	Border(border Border, sides ...bool) Component
	BorderForeground(color string) Component
	Padding(p ...int) Component
	Width(width int) Component
	Height(height int) Component
	Align(pos Position) Component
}