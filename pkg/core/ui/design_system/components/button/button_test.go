// Package button provides a button component for the design system.
package button

import (
	"fmt"
	"testing"
)

// MockTheme for testing purposes
type MockTheme struct{}

func (mt *MockTheme) PrimaryColor() string    { return "[PRIMARY]" }
func (mt *MockTheme) SecondaryColor() string  { return "[SECONDARY]" }
func (mt *MockTheme) BackgroundColor() string { return "[BACKGROUND]" }
func (mt *MockTheme) TextColor() string       { return "[TEXT]" }

func TestNewButton(t *testing.T) {
	label := "Click Me"
	mockTheme := &MockTheme{}
	btn := NewButton(label, mockTheme)
	if btn == nil {
		t.Fatal("NewButton returned nil")
	}
	if btn.Label != label {
		t.Errorf("NewButton label mismatch: got %s, want %s", btn.Label, label)
	}
	if btn.Theme != mockTheme {
		t.Error("NewButton theme mismatch")
	}
}

func TestButton_Render(t *testing.T) {
	label := "Submit"
	mockTheme := &MockTheme{}
	btn := NewButton(label, mockTheme)
	expected := "[[PRIMARY]Submit[TEXT]]"

	if btn.Render() != expected {
		t.Errorf("Button Render mismatch: got %s, want %s", btn.Render(), expected)
	}
}

func ExampleButton_Render() {
	// A real theme would be used here, e.g., themes.NewThemeManager().GetActiveTheme()
	mockTheme := &MockTheme{}
	btn := NewButton("Click Me", mockTheme)
	fmt.Println(btn.Render())
	// Output:
	// [[PRIMARY]Click Me[TEXT]]
}
