// Package layout provides a layout component for arranging other components.
package layout

import (
	"strings"

	"github.com/DippingCode/easyenv/pkg/core/ui/design_system/interfaces"
)

// Direction defines the layout direction.
type Direction int

const (
	// Row arranges components horizontally.
	Row Direction = iota // Horizontal layout
	// Col arranges components vertically.
	Col                  // Vertical layout
)

// Layout represents a container component that arranges its children.
type Layout struct {
	Children  []interfaces.Component
	Direction Direction
}

// NewLayout creates a new Layout component.
func NewLayout(direction Direction, children ...interfaces.Component) *Layout {
	return &Layout{
		Children:  children,
		Direction: direction,
	}
}

// AddChild adds a component to the layout.
func (l *Layout) AddChild(child interfaces.Component) {
	l.Children = append(l.Children, child)
}

// Render returns the string representation of the Layout component.
func (l *Layout) Render() string {
	var renderedChildren []string
	for _, child := range l.Children {
		renderedChildren = append(renderedChildren, child.Render())
	}

	if l.Direction == Row {
		return strings.Join(renderedChildren, " ") // Join with space for horizontal
	} else if l.Direction == Col {
		return strings.Join(renderedChildren, "\n") // Join with newline for vertical
	}
	return ""
}

// Ensure Layout implements the interfaces.Component interface.
var _ interfaces.Component = (*Layout)(nil)
