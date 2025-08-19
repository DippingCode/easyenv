// Package themes defines interfaces and implementations for managing UI themes.
package themes

// DarkTheme implements the Theme interface for a dark color scheme.
type DarkTheme struct{}

// PrimaryColor returns the primary color for the dark theme.
func (dt *DarkTheme) PrimaryColor() string {
	return "#6610f2" // Indigo
}

// SecondaryColor returns the secondary color for the dark theme.
func (dt *DarkTheme) SecondaryColor() string {
	return "#6c757d" // Gray
}

// BackgroundColor returns the background color for the dark theme.
func (dt *DarkTheme) BackgroundColor() string {
	return "#212529" // Dark Gray
}

// TextColor returns the text color for the dark theme.
func (dt *DarkTheme) TextColor() string {
	return "#f8f9fa" // Light Gray/White
}
