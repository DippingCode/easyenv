// Package themes defines interfaces and implementations for managing UI themes.
package themes

import (
	"testing"
)

func TestLightTheme_PrimaryColor(t *testing.T) {
	lt := &LightTheme{}
	expected := "#007bff"
	if lt.PrimaryColor() != expected {
		t.Errorf("LightTheme PrimaryColor was incorrect, got: %s, want: %s.", lt.PrimaryColor(), expected)
	}
}

func TestLightTheme_SecondaryColor(t *testing.T) {
	lt := &LightTheme{}
	expected := "#6c757d"
	if lt.SecondaryColor() != expected {
		t.Errorf("LightTheme SecondaryColor was incorrect, got: %s, want: %s.", lt.SecondaryColor(), expected)
	}
}

func TestLightTheme_BackgroundColor(t *testing.T) {
	lt := &LightTheme{}
	expected := "#ffffff"
	if lt.BackgroundColor() != expected {
		t.Errorf("LightTheme BackgroundColor was incorrect, got: %s, want: %s.", lt.BackgroundColor(), expected)
	}
}

func TestLightTheme_TextColor(t *testing.T) {
	lt := &LightTheme{}
	expected := "#212529"
	if lt.TextColor() != expected {
		t.Errorf("LightTheme TextColor was incorrect, got: %s, want: %s.", lt.TextColor(), expected)
	}
}
