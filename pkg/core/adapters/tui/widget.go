//Package tui
package tui


// Widget is the base interface for all UI elements.
// It embeds tui.Model, providing Init, Update, and View methods.
type Widget interface {
	Model
}
