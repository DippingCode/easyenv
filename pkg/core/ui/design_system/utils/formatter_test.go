// Package utils provides utility functions for the design system, such as text formatting.
package utils

import (
	"testing"
)

func TestBold(t *testing.T) {
	text := "bold text"
	expected := "\033[1mbold text\033[0m"
	if Bold(text) != expected {
		t.Errorf("Bold failed: got %q, want %q", Bold(text), expected)
	}
}

func TestItalic(t *testing.T) {
	text := "italic text"
	expected := "\033[3mitalic text\033[0m"
	if Italic(text) != expected {
		t.Errorf("Italic failed: got %q, want %q", Italic(text), expected)
	}
}

func TestUnderline(t *testing.T) {
	text := "underlined text"
	expected := "\033[4munderlined text\033[0m"
	if Underline(text) != expected {
		t.Errorf("Underline failed: got %q, want %q", Underline(text), expected)
	}
}

func TestPadRight(t *testing.T) {
	tests := []struct {
		input    string
		length   int
		expected string
	}{
		{"hello", 10, "hello     "},
		{"hello", 5, "hello"},
		{"hello", 3, "hello"},
		{"", 5, "     "},
	}

	for _, tt := range tests {
		result := PadRight(tt.input, tt.length)
		if result != tt.expected {
			t.Errorf("PadRight(%q, %d): got %q, want %q", tt.input, tt.length, result, tt.expected)
		}
	}
}

func TestPadLeft(t *testing.T) {
	tests := []struct {
		input    string
		length   int
		expected string
	}{
		{"hello", 10, "     hello"},
		{"hello", 5, "hello"},
		{"hello", 3, "hello"},
		{"", 5, "     "},
	}

	for _, tt := range tests {
		result := PadLeft(tt.input, tt.length)
		if result != tt.expected {
			t.Errorf("PadLeft(%q, %d): got %q, want %q", tt.input, tt.length, result, tt.expected)
		}
	}
}
