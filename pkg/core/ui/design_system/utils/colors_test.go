// Package utils provides utility functions for the design system, such as color manipulation.
package utils

import (
	"testing"
)

func TestColorize(t *testing.T) {
	text := "Hello"
	color := Red
	expected := Red + text + Reset

	if Colorize(text, color) != expected {
		t.Errorf("Colorize failed: got %q, want %q", Colorize(text, color), expected)
	}
}

func TestBackgroundColorize(t *testing.T) {
	text := "World"
	bgColor := BgBlue
	expected := BgBlue + text + Reset

	if BackgroundColorize(text, bgColor) != expected {
		t.Errorf("BackgroundColorize failed: got %q, want %q", BackgroundColorize(text, bgColor), expected)
	}
}
