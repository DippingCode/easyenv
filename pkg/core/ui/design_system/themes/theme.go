// Package themes defines interfaces and implementations for managing UI themes.
package themes

// Theme defines the interface for a UI theme, providing color and style information.
type Theme interface {
	PrimaryColor() string
	SecondaryColor() string
	BackgroundColor() string
	TextColor() string
	// Add more theme-specific methods as needed (e.g., for borders, highlights, etc.)
}
