// Package themes defines interfaces and implementations for managing UI themes.
package themes

import (
	"testing"
)

func TestNewThemeManager(t *testing.T) {
	tm := NewThemeManager()
	if tm == nil {
		t.Error("NewThemeManager returned nil")
	}
	// Check if the default theme is LightTheme
	if _, ok := tm.GetActiveTheme().(*LightTheme); !ok {
		t.Errorf("Default theme is not LightTheme, got %T", tm.GetActiveTheme())
	}
}

func TestThemeManager_SetTheme(t *testing.T) {
	tm := NewThemeManager()
	dark := &DarkTheme{}
	tm.SetTheme(dark)

	if tm.GetActiveTheme() != dark {
		t.Errorf("SetTheme failed, expected dark theme, got %T", tm.GetActiveTheme())
	}
}

func TestThemeManager_GetActiveTheme(t *testing.T) {
	tm := NewThemeManager()
	activeTheme := tm.GetActiveTheme()
	if activeTheme == nil {
		t.Error("GetActiveTheme returned nil")
	}
}
