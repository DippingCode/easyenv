package tui

// Clickable is an interface for components that respond to click events.
// It embeds the base Component interface.
type Clickable interface {
	Component
	// SetOnClick sets a function to be called when the component is clicked.
	// The function should return a Cmd to be processed by the TUI runtime.
	SetOnClick(onClick func() Cmd)
}
