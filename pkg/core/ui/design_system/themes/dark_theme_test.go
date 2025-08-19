// Package themes defines interfaces and implementations for managing UI themes.
package themes

import (
	"testing"
)

func TestDarkTheme_PrimaryColor(t *testing.T) {
	dt := &DarkTheme{}
	expected := "#6610f2"
	if dt.PrimaryColor() != expected {
		t.Errorf("DarkTheme PrimaryColor was incorrect, got: %s, want: %s.", dt.PrimaryColor(), expected)
	}
}

func TestDarkTheme_SecondaryColor(t *testing.T) {
	dt := &DarkTheme{}
	expected := "#6c757d"
	if dt.SecondaryColor() != expected {
		t.Errorf("DarkTheme SecondaryColor was incorrect, got: %s, want: %s.", dt.SecondaryColor(), expected)
	}
}

func TestDarkTheme_BackgroundColor(t *testing.T) {
	dt := &DarkTheme{}
	expected := "#212529"
	if dt.BackgroundColor() != expected {
		t.Errorf("DarkTheme BackgroundColor was incorrect, got: %s, want: %s.", dt.BackgroundColor(), expected)
	}
}

func TestDarkTheme_TextColor(t *testing.T) {
	dt := &DarkTheme{}
	expected := "#f8f9fa"
	if dt.TextColor() != expected {
		t.Errorf("DarkTheme TextColor was incorrect, got: %s, want: %s.", dt.TextColor(), expected)
	}
}
