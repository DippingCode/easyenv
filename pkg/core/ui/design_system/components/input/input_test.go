// Package input provides an input component for the design system.
package input

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

func TestNewInput(t *testing.T) {
	placeholder := "Enter text"
	mockTheme := &MockTheme{}
	input := NewInput(placeholder, mockTheme)
	if input == nil {
		t.Fatal("NewInput returned nil")
	}
	if input.Placeholder != placeholder {
		t.Errorf("NewInput placeholder mismatch: got %s, want %s", input.Placeholder, placeholder)
	}
	if input.Theme != mockTheme {
		t.Error("NewInput theme mismatch")
	}
	if input.Value != "" {
		t.Errorf("NewInput initial value mismatch: got %s, want empty string", input.Value)
	}
}

func TestInput_SetValue(t *testing.T) {
	placeholder := "Enter text"
	mockTheme := &MockTheme{}
	input := NewInput(placeholder, mockTheme)

	newValue := "Hello"
	input.SetValue(newValue)

	if input.Value != newValue {
		t.Errorf("SetValue failed: got %s, want %s", input.Value, newValue)
	}
}

func TestInput_Render(t *testing.T) {
	placeholder := "Enter text"
	mockTheme := &MockTheme{}
	input := NewInput(placeholder, mockTheme)

	// Test with empty value (should show placeholder)
	expected := "[[BACKGROUND]Enter text[TEXT]]"
	if input.Render() != expected {
		t.Errorf("Input Render (placeholder) mismatch: got %s, want %s", input.Render(), expected)
	}

	// Test with a value
	input.SetValue("My input")
	expected = "[[BACKGROUND]My input[TEXT]]"
	if input.Render() != expected {
		t.Errorf("Input Render (value) mismatch: got %s, want %s", input.Render(), expected)
	}
}

func ExampleInput_Render() {
	// A real theme would be used here
	mockTheme := &MockTheme{}
	input := NewInput("Username", mockTheme)
	fmt.Println(input.Render())

	input.SetValue("john.doe")
	fmt.Println(input.Render())
	// Output:
	// [[BACKGROUND]Username[TEXT]]
	// [[BACKGROUND]john.doe[TEXT]]
}
