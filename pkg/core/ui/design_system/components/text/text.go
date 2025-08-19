// Package text provides a basic text component for the design system.
package text

import (
	"github.com/DippingCode/easyenv/pkg/core/ui/design_system/interfaces"
)

// Text represents a simple text component.
type Text struct {
	Content string
}

// NewText creates a new Text component.
func NewText(content string) *Text {
	return &Text{Content: content}
}

// Render returns the string representation of the Text component.
func (t *Text) Render() string {
	return t.Content
}

// Ensure Text implements the interfaces.Component interface.
var _ interfaces.Component = (*Text)(nil)
