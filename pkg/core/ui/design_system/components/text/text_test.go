// Package text provides a basic text component for the design system.
package text

import (
	"fmt"
	"testing"
)

func TestNewText(t *testing.T) {
	content := "Hello, World!"
	txt := NewText(content)

	if txt == nil {
		t.Error("NewText returned nil")
	}
	if txt.Content != content {
		t.Errorf("NewText content mismatch: got %s, want %s", txt.Content, content)
	}
}

func TestText_Render(t *testing.T) {
	content := "Test Render"
	txt := NewText(content)
	expected := content

	if txt.Render() != expected {
		t.Errorf("Text Render mismatch: got %s, want %s", txt.Render(), expected)
	}
}

func ExampleText_Render() {
	txt := NewText("Hello, GoDoc!")
	fmt.Println(txt.Render())
	// Output:
	// Hello, GoDoc!
}
