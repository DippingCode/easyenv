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
	Col
)

// Layout holds children and a direction to render them.
type Layout struct {
	Direction Direction
	Children  []interfaces.Component
}

// New creates a new Layout.
func New(dir Direction) *Layout {
	return &Layout{Direction: dir, Children: make([]interfaces.Component, 0, 4)}
}

// AddChild appends a component.
func (l *Layout) AddChild(c interfaces.Component) *Layout {
	l.Children = append(l.Children, c)
	return l
}

// Render renders children joined by space (row) or newline (col).
func (l *Layout) Render() string {
	if len(l.Children) == 0 {
		return ""
	}

	renderedChildren := make([]string, 0, len(l.Children))
	for _, child := range l.Children {
		renderedChildren = append(renderedChildren, child.Render())
	}

	if l.Direction == Row {
		return strings.Join(renderedChildren, " ")
	}
	// default: Col
	return strings.Join(renderedChildren, "\n")
}

// Ensure Layout implements the interfaces.Component interface.
var _ interfaces.Component = (*Layout)(nil)
