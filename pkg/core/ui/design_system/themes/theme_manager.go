// Package themes defines interfaces and implementations for managing UI themes.
package themes

// ThemeManager manages the current active theme.
type ThemeManager struct {
	activeTheme Theme
}

// NewThemeManager creates a new ThemeManager with a default theme (e.g., LightTheme).
func NewThemeManager() *ThemeManager {
	return &ThemeManager{
		activeTheme: &LightTheme{}, // Default to light theme
	}
}

// SetTheme sets the active theme.
func (tm *ThemeManager) SetTheme(theme Theme) {
	tm.activeTheme = theme
}

// GetActiveTheme returns the currently active theme.
func (tm *ThemeManager) GetActiveTheme() Theme {
	return tm.activeTheme
}
