// Package layout provides a layout component for arranging other components.
package layout

import (
	"fmt"
	"testing"
)

// MockComponent for testing purposes
type MockComponent struct {
	RenderOutput string
}

func (mc *MockComponent) Render() string {
	return mc.RenderOutput
}

func TestNewLayout(t *testing.T) {
	comp1 := &MockComponent{RenderOutput: "Comp1"}
	comp2 := &MockComponent{RenderOutput: "Comp2"}

	// Test Row direction
	rowLayout := NewLayout(Row, comp1, comp2)
	if rowLayout == nil {
		t.Fatal("NewLayout (Row) returned nil")
	}
	if len(rowLayout.Children) != 2 {
		t.Errorf("NewLayout (Row) children count mismatch: got %d, want %d", len(rowLayout.Children), 2)
	}
	if rowLayout.Direction != Row {
		t.Errorf("NewLayout (Row) direction mismatch: got %d, want %d", rowLayout.Direction, Row)
	}

	// Test Col direction
	colLayout := NewLayout(Col, comp1)
	if colLayout == nil {
		t.Error("NewLayout (Col) returned nil")
	}
	if len(colLayout.Children) != 1 {
		t.Errorf("NewLayout (Col) children count mismatch: got %d, want %d", len(colLayout.Children), 1)
	}
	if colLayout.Direction != Col {
		t.Errorf("NewLayout (Col) direction mismatch: got %d, want %d", colLayout.Direction, Col)
	}
}

func TestLayout_AddChild(t *testing.T) {
	layout := NewLayout(Row)
	comp := &MockComponent{RenderOutput: "Child"}

	layout.AddChild(comp)

	if len(layout.Children) != 1 {
		t.Errorf("AddChild failed, children count mismatch: got %d, want %d", len(layout.Children), 1)
	}
}

func TestLayout_Render(t *testing.T) {
	comp1 := &MockComponent{RenderOutput: "Item1"}
	comp2 := &MockComponent{RenderOutput: "Item2"}

	// Test Row rendering
	rowLayout := NewLayout(Row, comp1, comp2)
	expectedRow := "Item1 Item2"
	if rowLayout.Render() != expectedRow {
		t.Errorf("Layout Render (Row) mismatch: got %q, want %q", rowLayout.Render(), expectedRow)
	}

	// Test Col rendering

	colLayout := NewLayout(Col, comp1, comp2)
	expectedCol := "Item1\nItem2"
	if colLayout.Render() != expectedCol {
		t.Errorf("Layout Render (Col) mismatch: got %q, want %q", colLayout.Render(), expectedCol)
	}

	// Test empty layout
	emptyLayout := NewLayout(Row)
	expectedEmpty := ""
	if emptyLayout.Render() != expectedEmpty {
		t.Errorf("Layout Render (Empty) mismatch: got %q, want %q", emptyLayout.Render(), expectedEmpty)
	}
}

func ExampleLayout_Render() {
	text1 := &MockComponent{RenderOutput: "Hello"}
	text2 := &MockComponent{RenderOutput: "World"}

	// Example of a row layout
	rowLayout := NewLayout(Row, text1, text2)
	fmt.Println(rowLayout.Render())

	// Example of a column layout

	colLayout := NewLayout(Col, text1, text2)
	fmt.Println(colLayout.Render())
	// Output:
	// Hello World
	// Hello
	// World
}
