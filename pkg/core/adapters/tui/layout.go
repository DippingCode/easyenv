//Package tui
package tui


// Layout is an interface for widgets that primarily arrange other widgets.
// It embeds the base Widget interface and provides methods for layout-specific styling.
type Layout interface {
	Widget
	// Styling methods
	BackgroundColor(color string) Layout
	Border(border Border, sides ...bool) Layout
	BorderForeground(color string) Layout
	Padding(p ...int) Layout
	Width(width int) Layout
	Height(height int) Layout
	Align(pos Position) Layout
}