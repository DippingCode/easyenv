// Package themes defines interfaces and implementations for managing UI themes.
package themes

// LightTheme implements the Theme interface for a light color scheme.
type LightTheme struct{}

// PrimaryColor returns the primary color for the light theme.
func (lt *LightTheme) PrimaryColor() string {
	return "#007bff" // Blue
}

// SecondaryColor returns the secondary color for the light theme.
func (lt *LightTheme) SecondaryColor() string {
	return "#6c757d" // Gray
}

// BackgroundColor returns the background color for the light theme.
func (lt *LightTheme) BackgroundColor() string {
	return "#ffffff" // White
}

// TextColor returns the text color for the light theme.
func (lt *LightTheme) TextColor() string {
	return "#212529" // Dark Gray/Black
}
